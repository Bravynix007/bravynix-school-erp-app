import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_segmented_control.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';
import 'package:bravynix_school_erp/features/achievements/presentation/bloc/achievements_bloc.dart';
import 'package:bravynix_school_erp/features/achievements/presentation/view/stars_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/achievements.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockAchievementsBloc extends MockBloc<AchievementsEvent, AchievementsState> implements AchievementsBloc;

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'x');

void main() {
  late _MockAchievementsBloc bloc;

  setUpAll(() {
    registerFallbackValue(const AchievementsStarted());
  });

  setUp(() => bloc = _MockAchievementsBloc());

  Future<void> pump(
    WidgetTester tester,
    AchievementsState state, {
    bool Function(Achievement achievement)? canRemove,
    double textScale = 1,
    Size size = const Size(400, 1600),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider<AchievementsBloc>.value(
            value: bloc,
            child: StarsSection(canRemove: canRemove ?? (_) => true),
          ),
        ),
      ),
      textScale: textScale,
      size: size,
    );
  }

  final ready = AchievementsReady(stars: twoStars);
  final field = find.descendant(of: find.byKey(const Key('stars.description')), matching: find.byType(TextField));

  group('before the stars are read', () {
    testWidgets('shows a placeholder while they load', (tester) async {
      await pump(tester, const AchievementsLoading());
      expect(find.byKey(const Key('stars.failed')), findsNothing);
      expect(find.text('Stars'), findsOneWidget);
    });

    testWidgets('says why they could not be read, and reads again on Try again', (tester) async {
      await pump(tester, AchievementsFailed(_failure(503, 'UNAVAILABLE')));
      expect(find.byKey(const Key('stars.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const AchievementsStarted())).called(1);
    });

    testWidgets('has no Try again for a student the teacher does not have', (tester) async {
      await pump(tester, AchievementsFailed(_failure(403, 'NOT_ASSIGNED')));
      expect(find.text('This student is not in one of your sections.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('the stars', () {
    testWidgets('shows the total, the count of each kind and each star with its words', (tester) async {
      await pump(tester, ready);
      expect(find.byKey(const Key('stars.total')), findsOneWidget);
      expect(find.text('Silver · 1'), findsOneWidget);
      expect(find.text('Gold · 1'), findsOneWidget);
      expect(find.text('Platinum · 0'), findsOneWidget);
      expect(find.text('Won the quiz'), findsOneWidget);
      expect(find.text('Helped a classmate'), findsOneWidget);
    });

    testWidgets('offers to take back only the stars the caller may', (tester) async {
      await pump(tester, ready, canRemove: (star) => star.createdBy == 't1');
      expect(find.byKey(const ValueKey('stars.remove.a1')), findsOneWidget);
      expect(find.byKey(const ValueKey('stars.remove.a2')), findsNothing);
    });

    testWidgets('takes a star back only once confirmed', (tester) async {
      await pump(tester, ready);
      await tester.tap(find.byKey(const ValueKey('stars.remove.a1')));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any(that: isA<AchievementsRemoved>())));
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Take back')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const AchievementsRemoved('a1'))).called(1);
    });

    testWidgets('keeps the star when the question is cancelled', (tester) async {
      await pump(tester, ready);
      await tester.tap(find.byKey(const ValueKey('stars.remove.a1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any(that: isA<AchievementsRemoved>())));
    });

    testWidgets('says why a star could not be taken back', (tester) async {
      await pump(tester, ready.copyWith(failure: () => _failure(403, 'FORBIDDEN')));
      expect(find.byKey(const Key('stars.error')), findsOneWidget);
    });
  });

  group('a star that is being taken back', () {
    final removing = ready.copyWith(removing: () => 'a1');

    testWidgets('shows a spinner on that star only, and offers nothing else to take back', (tester) async {
      await pump(tester, removing);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('stars.remove.a1'))).loading, isTrue);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('stars.remove.a2'))).loading, isFalse);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('stars.remove.a1'))).onPressed, isNull);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('stars.remove.a2'))).onPressed, isNull);
    });

    testWidgets('leaves the words closed, so nothing typed is lost', (tester) async {
      await pump(tester, removing);
      expect(tester.widget<TextField>(field).enabled, isFalse);
    });
  });

  group('a star of an unknown kind', () {
    testWidgets('shows its date and words, and does not call it Silver', (tester) async {
      final unknown = Achievement(
        id: 'a9',
        tier: null,
        description: 'Tidy desk',
        createdBy: 't1',
        createdAt: DateTime.utc(2026, 11, 10, 8),
      );
      await pump(
        tester,
        AchievementsReady(stars: Stars(total: 1, silver: 0, gold: 0, platinum: 0, achievements: [unknown])),
      );
      expect(find.text('Tidy desk'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const ValueKey('stars.item.a9')), matching: find.textContaining('Silver')),
        findsNothing,
      );
    });
  });

  group('giving a star', () {
    testWidgets('chooses Silver at first', (tester) async {
      await pump(tester, ready);
      expect(
        tester.widget<AppSegmentedControl<StarTier>>(find.byType(AppSegmentedControl<StarTier>)).selected,
        StarTier.silver,
      );
    });

    testWidgets('takes at most 500 characters', (tester) async {
      await pump(tester, ready);
      expect(tester.widget<TextField>(field).maxLength, 500);
    });

    testWidgets('empties the words once the star was given', (tester) async {
      final states = StreamController<AchievementsState>();
      addTearDown(states.close);
      whenListen(bloc, states.stream, initialState: ready.copyWith(description: 'Kind'));
      await pump(tester, ready.copyWith(description: 'Kind'));
      await tester.enterText(field, 'Kind');
      expect(tester.widget<TextField>(field).controller!.text, 'Kind');
      states.add(ready);
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    });

    testWidgets('leaves the words closed while the star is on its way', (tester) async {
      await pump(tester, ready.copyWith(description: 'Kind', giving: true));
      expect(tester.widget<TextField>(field).enabled, isFalse);
    });

    testWidgets('cannot be given without words', (tester) async {
      await pump(tester, ready);
      expect(tester.widget<AppButton>(find.byKey(const Key('stars.give'))).onPressed, isNull);
    });

    testWidgets('can be given once there are words', (tester) async {
      await pump(tester, ready.copyWith(description: 'Kind'));
      expect(tester.widget<AppButton>(find.byKey(const Key('stars.give'))).onPressed, isNotNull);
    });

    testWidgets('tells the bloc of the kind, the words and the give', (tester) async {
      await pump(tester, ready.copyWith(description: 'Kind'));
      await tester.tap(find.text('Platinum').last);
      verify(() => bloc.add(const AchievementsTierChosen(StarTier.platinum))).called(1);
      await tester.enterText(
        find.descendant(of: find.byKey(const Key('stars.description')), matching: find.byType(TextField)),
        'Kind!',
      );
      verify(() => bloc.add(const AchievementsDescriptionChanged('Kind!'))).called(1);
      await tester.tap(find.byKey(const Key('stars.give')));
      verify(() => bloc.add(const AchievementsGiven())).called(1);
    });

    testWidgets('cannot be given while one is on its way', (tester) async {
      await pump(tester, ready.copyWith(description: 'Kind', giving: true));
      expect(tester.widget<AppButton>(find.byKey(const Key('stars.give'))).onPressed, isNull);
    });
  });

  testWidgets('fits a narrow phone at a large text size', (tester) async {
    await pump(
      tester,
      ready.copyWith(failure: () => _failure(403, 'FORBIDDEN'), description: 'Kind'),
      textScale: 2,
      size: const Size(320, 1600),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 196), isEmpty);
  });
}
