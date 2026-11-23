import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_day.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/section_day_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance.dart';

ApiFailure refusal(String code, {int status = 403}) => ApiFailure(statusCode: status, code: code, message: code);

SectionDayReady ready({
  SectionChoices? choices,
  String? classId,
  String? sectionId,
  String day = '2026-11-17',
}) => SectionDayReady(
  classes: (choices ?? _twoClasses).classes,
  sections: (choices ?? _twoClasses).sections,
  today: '2026-11-17',
  day: day,
  classId: classId,
  sectionId: sectionId,
);

final SectionChoices _twoClasses = twoClasses.choices;
final SectionChoices _oneSection = oneSection.choices;

void main() {
  /// Today is the 17th of November 2026 in IST (04:00 UTC).
  DateTime clock() => DateTime.utc(2026, 11, 17, 4);

  SectionDayBloc build({SectionChoices? choices, SectionDay? focus}) =>
      SectionDayBloc(() async => choices ?? _twoClasses, clock: clock, focus: focus);

  /// Opened on the Institution's classes, with nothing chosen.
  Future<SectionDayBloc> open({SectionChoices? choices, SectionDay? focus}) async {
    final bloc = build(choices: choices, focus: focus)..add(const SectionDayStarted());
    await bloc.stream.firstWhere((state) => state is SectionDayReady);
    return bloc;
  }

  group('opening', () {
    blocTest<SectionDayBloc, SectionDayState>(
      'reads the classes and shows today, with nothing chosen when there is a choice',
      build: build,
      act: (bloc) => bloc.add(const SectionDayStarted()),
      expect: () => [const SectionDayLoading(), ready()],
      verify: (bloc) => expect((bloc.state as SectionDayReady).selection, isNull),
    );

    blocTest<SectionDayBloc, SectionDayState>(
      'takes the day of today in IST, not in UTC',
      build: () => SectionDayBloc(() async => _twoClasses, clock: () => DateTime.utc(2026, 12, 31, 20)),
      act: (bloc) => bloc.add(const SectionDayStarted()),
      verify: (bloc) => expect((bloc.state as SectionDayReady).day, '2027-01-01'),
    );

    blocTest<SectionDayBloc, SectionDayState>(
      'chooses the only class and its only section',
      build: () => build(choices: _oneSection),
      act: (bloc) => bloc.add(const SectionDayStarted()),
      expect: () => [const SectionDayLoading(), ready(choices: _oneSection, classId: 'c7', sectionId: 'sec1')],
      verify: (bloc) =>
          expect((bloc.state as SectionDayReady).selection, const SectionDay(sectionId: 'sec1', day: '2026-11-17')),
    );

    blocTest<SectionDayBloc, SectionDayState>(
      'keeps the failure for the screen, and reads again on retry',
      build: () {
        var calls = 0;
        return SectionDayBloc(() async {
          if (++calls == 1) throw refusal('FORBIDDEN');
          return _twoClasses;
        }, clock: clock);
      },
      act: (bloc) async {
        bloc.add(const SectionDayStarted());
        await bloc.stream.firstWhere((state) => state is SectionDayFailed);
        bloc.add(const SectionDayStarted());
      },
      expect: () => [
        const SectionDayLoading(),
        SectionDayFailed(refusal('FORBIDDEN')),
        const SectionDayLoading(),
        ready(),
      ],
    );

    blocTest<SectionDayBloc, SectionDayState>(
      'with the day only to choose, has no class or section and no selection',
      build: () => SectionDayBloc.dayOnly(clock: clock),
      act: (bloc) => bloc.add(const SectionDayStarted()),
      expect: () => [
        const SectionDayLoading(),
        const SectionDayReady(classes: [], sections: [], today: '2026-11-17', day: '2026-11-17'),
      ],
    );
  });

  group('a diary opened from a notice', () {
    blocTest<SectionDayBloc, SectionDayState>(
      'opens on the day the notice names',
      build: () => SectionDayBloc.dayOnly(clock: clock, day: '2026-11-12'),
      act: (bloc) => bloc.add(const SectionDayStarted()),
      expect: () => [
        const SectionDayLoading(),
        const SectionDayReady(classes: [], sections: [], today: '2026-11-17', day: '2026-11-12'),
      ],
    );

    for (final (why, day) in [
      ('has not come yet, which cannot be chosen', '2026-11-18'),
      ('is no day', '1'),
      ('is a day that does not exist', '2026-13-45'),
      ('is a day that rolls over to another', '2026-02-30'),
      ('is written another way', '10-11-2026'),
    ]) {
      blocTest<SectionDayBloc, SectionDayState>(
        'opens on today when the day named $why',
        build: () => SectionDayBloc.dayOnly(clock: clock, day: day),
        act: (bloc) => bloc.add(const SectionDayStarted()),
        expect: () => [
          const SectionDayLoading(),
          const SectionDayReady(classes: [], sections: [], today: '2026-11-17', day: '2026-11-17'),
        ],
      );
    }
  });

  group("opened on a register from a student's calendar", () {
    blocTest<SectionDayBloc, SectionDayState>(
      'chooses its class, section and day at once',
      build: () => build(
        focus: const SectionDay(sectionId: 'sec3', day: '2026-11-10'),
      ),
      act: (bloc) => bloc.add(const SectionDayStarted()),
      expect: () => [
        const SectionDayLoading(),
        ready(classId: 'c8', sectionId: 'sec3', day: '2026-11-10'),
      ],
    );

    blocTest<SectionDayBloc, SectionDayState>(
      'with a section of a class that has two, chooses only the one named',
      build: () => build(
        focus: const SectionDay(sectionId: 'sec2', day: '2026-11-10'),
      ),
      act: (bloc) => bloc.add(const SectionDayStarted()),
      expect: () => [
        const SectionDayLoading(),
        ready(classId: 'c7', sectionId: 'sec2', day: '2026-11-10'),
      ],
    );

    blocTest<SectionDayBloc, SectionDayState>(
      'ignores a section the Institution does not have, and leaves the choice to the person',
      build: () => build(
        focus: const SectionDay(sectionId: 'elsewhere', day: '2026-11-10'),
      ),
      act: (bloc) => bloc.add(const SectionDayStarted()),
      expect: () => [const SectionDayLoading(), ready()],
    );
  });

  group('choosing', () {
    test('chooses the only section of the next class, and none in a class that has two', () async {
      final bloc = await open();
      bloc.add(const SectionDayClassChosen('c8'));
      await bloc.stream.firstWhere((state) => state is SectionDayReady && state.sectionId != null);
      expect(bloc.state, ready(classId: 'c8', sectionId: 'sec3'));
      bloc.add(const SectionDayClassChosen('c7'));
      await bloc.stream.firstWhere((state) => state is SectionDayReady && state.classId == 'c7');
      expect(bloc.state, ready(classId: 'c7'));
      await bloc.close();
    });

    test('selects the section and the day chosen', () async {
      final bloc = await open();
      bloc
        ..add(const SectionDayClassChosen('c7'))
        ..add(const SectionDaySectionChosen('sec1'))
        ..add(const SectionDayDayChosen('2026-11-16'));
      await bloc.stream.firstWhere((state) => state is SectionDayReady && state.day == '2026-11-16');
      expect(
        (bloc.state as SectionDayReady).selection,
        const SectionDay(sectionId: 'sec1', day: '2026-11-16'),
      );
      await bloc.close();
    });

    test('ignores the choice of what is already chosen, and of nothing', () async {
      final bloc = await open();
      bloc
        ..add(const SectionDayClassChosen('c7'))
        ..add(const SectionDaySectionChosen('sec1'));
      await bloc.stream.firstWhere((state) => state is SectionDayReady && state.sectionId == 'sec1');
      final shown = bloc.state;
      bloc
        ..add(const SectionDayDayChosen('2026-11-17'))
        ..add(const SectionDaySectionChosen('sec1'))
        ..add(const SectionDaySectionChosen(null))
        ..add(const SectionDayClassChosen(null))
        ..add(const SectionDayClassChosen('c7'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, same(shown));
      await bloc.close();
    });

    test('takes no choice before the classes are read', () async {
      final bloc = build()
        ..add(const SectionDayClassChosen('c7'))
        ..add(const SectionDayDayChosen('2026-11-16'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const SectionDayLoading());
      await bloc.close();
    });
  });
}
