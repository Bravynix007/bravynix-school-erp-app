import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';
import 'package:bravynix_school_erp/features/achievements/presentation/bloc/achievements_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/achievements.dart';
import '../../helpers/mocks.dart';

const _down = ApiFailure(statusCode: 503, code: 'UNAVAILABLE', message: 'x');
const _notAssigned = ApiFailure(statusCode: 403, code: 'NOT_ASSIGNED', message: 'x');

void main() {
  late MockAchievementsRepository achievements;

  setUpAll(() => registerFallbackValue(StarTier.silver));

  setUp(() {
    achievements = MockAchievementsRepository();
    when(() => achievements.stars('p1')).thenAnswer((_) async => twoStars);
  });

  AchievementsBloc build() => AchievementsBloc(achievements, 'p1');

  final ready = AchievementsReady(stars: twoStars);

  group('opening', () {
    blocTest<AchievementsBloc, AchievementsState>(
      'reads the stars',
      build: build,
      act: (bloc) => bloc.add(const AchievementsStarted()),
      expect: () => [const AchievementsLoading(), ready],
    );

    blocTest<AchievementsBloc, AchievementsState>(
      'says why they could not be read, and reads them again on Try again',
      setUp: () => when(() => achievements.stars('p1')).thenThrow(_notAssigned),
      build: build,
      act: (bloc) async {
        bloc.add(const AchievementsStarted());
        await Future<void>.delayed(Duration.zero);
        when(() => achievements.stars('p1')).thenAnswer((_) async => twoStars);
        bloc.add(const AchievementsStarted());
      },
      expect: () => [
        const AchievementsLoading(),
        const AchievementsFailed(_notAssigned),
        const AchievementsLoading(),
        ready,
      ],
    );
  });

  test('starts with Silver chosen', () async {
    final bloc = build()..add(const AchievementsStarted());
    final state = await bloc.stream.firstWhere((state) => state is AchievementsReady);
    expect((state as AchievementsReady).tier, StarTier.silver);
    await bloc.close();
  });

  group('the star being given', () {
    blocTest<AchievementsBloc, AchievementsState>(
      'takes the kind and the words, and cannot be given without words',
      seed: () => ready,
      build: build,
      act: (bloc) => bloc
        ..add(const AchievementsGiven())
        ..add(const AchievementsTierChosen(StarTier.platinum))
        ..add(const AchievementsDescriptionChanged('   '))
        ..add(const AchievementsGiven())
        ..add(const AchievementsDescriptionChanged('Led the assembly')),
      expect: () => [
        ready.copyWith(tier: StarTier.platinum),
        ready.copyWith(tier: StarTier.platinum, description: '   '),
        ready.copyWith(tier: StarTier.platinum, description: 'Led the assembly'),
      ],
      verify: (_) => verifyNever(
        () => achievements.give(
          any(),
          tier: any(named: 'tier'),
          description: any(named: 'description'),
        ),
      ),
    );

    blocTest<AchievementsBloc, AchievementsState>(
      'gives the star trimmed, empties the form, and reads the list again so the counts are the server’s',
      setUp: () {
        when(
          () => achievements.give('p1', tier: StarTier.gold, description: 'Led the assembly'),
        ).thenAnswer((_) async => goldStar);
        when(() => achievements.stars('p1')).thenAnswer((_) async => twoStars);
      },
      seed: () => ready.copyWith(tier: StarTier.gold, description: '  Led the assembly '),
      build: build,
      act: (bloc) => bloc.add(const AchievementsGiven()),
      expect: () => [
        ready.copyWith(tier: StarTier.gold, description: '  Led the assembly ', giving: true),
        ready.copyWith(tier: StarTier.gold),
      ],
    );

    blocTest<AchievementsBloc, AchievementsState>(
      'keeps the form and says why when the star is refused',
      setUp: () => when(
        () => achievements.give(
          any(),
          tier: any(named: 'tier'),
          description: any(named: 'description'),
        ),
      ).thenThrow(const ApiFailure(statusCode: 422, code: 'NO_CURRENT_PLACEMENT', message: 'x')),
      // The last refusal is gone once the next give is on its way.
      seed: () => ready.copyWith(description: 'Kind', failure: () => _down),
      build: build,
      act: (bloc) => bloc.add(const AchievementsGiven()),
      expect: () => [
        ready.copyWith(description: 'Kind', giving: true),
        ready.copyWith(
          description: 'Kind',
          failure: () => const ApiFailure(statusCode: 422, code: 'NO_CURRENT_PLACEMENT', message: 'x'),
        ),
      ],
    );

    blocTest<AchievementsBloc, AchievementsState>(
      'keeps the old list with the reason when the star went through but the list could not be read',
      setUp: () {
        when(
          () => achievements.give(
            any(),
            tier: any(named: 'tier'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => goldStar);
        when(() => achievements.stars('p1')).thenThrow(_down);
      },
      seed: () => ready.copyWith(description: 'Kind'),
      build: build,
      act: (bloc) => bloc.add(const AchievementsGiven()),
      expect: () => [
        ready.copyWith(description: 'Kind', giving: true),
        ready.copyWith(failure: () => _down),
      ],
    );

    blocTest<AchievementsBloc, AchievementsState>(
      'a change to the form clears the last refusal',
      seed: () => ready.copyWith(failure: () => _down),
      build: build,
      act: (bloc) => bloc.add(const AchievementsDescriptionChanged('x')),
      expect: () => [ready.copyWith(description: 'x')],
    );

    blocTest<AchievementsBloc, AchievementsState>(
      'does not give a second star while one is on its way',
      seed: () => ready.copyWith(description: 'Kind', giving: true),
      build: build,
      act: (bloc) => bloc
        ..add(const AchievementsGiven())
        ..add(const AchievementsTierChosen(StarTier.gold)),
      expect: () => <AchievementsState>[],
    );
  });

  group('taking a star back', () {
    blocTest<AchievementsBloc, AchievementsState>(
      'removes it and reads the list again',
      setUp: () {
        when(() => achievements.remove('a1')).thenAnswer((_) async {});
        when(() => achievements.stars('p1')).thenAnswer(
          (_) async => Stars(total: 1, silver: 0, gold: 1, platinum: 0, achievements: [goldStar]),
        );
      },
      seed: () => ready,
      build: build,
      act: (bloc) => bloc.add(const AchievementsRemoved('a1')),
      expect: () => [
        ready.copyWith(removing: () => 'a1'),
        AchievementsReady(stars: Stars(total: 1, silver: 0, gold: 1, platinum: 0, achievements: [goldStar])),
      ],
    );

    blocTest<AchievementsBloc, AchievementsState>(
      'says why when the star cannot be taken back, and keeps the list',
      setUp: () => when(() => achievements.remove('a2')).thenThrow(
        const ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x'),
      ),
      seed: () => ready,
      build: build,
      act: (bloc) => bloc.add(const AchievementsRemoved('a2')),
      expect: () => [
        ready.copyWith(removing: () => 'a2'),
        ready.copyWith(
          failure: () => const ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x'),
        ),
      ],
    );

    blocTest<AchievementsBloc, AchievementsState>(
      'waits while another change is on its way',
      seed: () => ready.copyWith(removing: () => 'a1'),
      build: build,
      act: (bloc) => bloc.add(const AchievementsRemoved('a2')),
      expect: () => <AchievementsState>[],
      verify: (_) => verifyNever(() => achievements.remove(any())),
    );
  });

  test('counts each kind of star', () {
    expect([for (final tier in StarTier.values) twoStars.countOf(tier)], [1, 1, 0]);
    expect(StarTier.fromCode(3), StarTier.platinum);
    expect(StarTier.fromCode(9), isNull);
  });
}
