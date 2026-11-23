import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/attendance.dart';
import '../../helpers/mocks.dart';

ApiFailure refusal(String code, {int status = 409}) => ApiFailure(statusCode: status, code: code, message: code);

AttendanceReady ready({
  MarkingSections choices = twoClasses,
  String? classId,
  String? sectionId,
  String day = '2026-11-17',
  AttendanceBoard board = const BoardEmpty(),
  AttendanceOutcome? outcome,
}) => AttendanceReady(
  classes: choices.classes,
  sections: choices.sections,
  day: day,
  classId: classId,
  sectionId: sectionId,
  board: board,
  outcome: outcome,
);

void main() {
  late MockAttendanceRepository repository;
  var keys = 0;
  setUp(() {
    repository = MockAttendanceRepository();
    keys = 0;
    registerFallbackValue(const <MarkChange>[]);
    when(() => repository.sections('i1')).thenAnswer((_) async => twoClasses);
    when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => openRoll);
  });

  /// Today is the 17th of November 2026 in IST (04:00 UTC).
  AttendanceBloc build() =>
      AttendanceBloc(repository, 'i1', clock: () => DateTime.utc(2026, 11, 17, 4), newKey: () => 'key-${++keys}');

  /// Opens the screen on section A of the 7th and waits for its roll.
  Future<AttendanceBloc> open() async {
    final bloc = build()..add(const AttendanceStarted());
    await bloc.stream.firstWhere((state) => state is AttendanceReady);
    bloc
      ..add(const AttendanceClassChosen('c7'))
      ..add(const AttendanceSectionChosen('sec1'));
    await bloc.stream.firstWhere((state) => state is AttendanceReady && state.board is BoardLoaded);
    return bloc;
  }

  BoardLoaded boardOf(AttendanceBloc bloc) => (bloc.state as AttendanceReady).board as BoardLoaded;

  group('choosing', () {
    blocTest<AttendanceBloc, AttendanceState>(
      'reads the classes and shows today, with nothing chosen when there is a choice',
      build: build,
      act: (bloc) => bloc.add(const AttendanceStarted()),
      expect: () => [const AttendanceLoading(), ready()],
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'chooses the only class and its only section, and reads their roll',
      build: build,
      setUp: () => when(() => repository.sections('i1')).thenAnswer((_) async => oneSection),
      act: (bloc) => bloc.add(const AttendanceStarted()),
      expect: () => [
        const AttendanceLoading(),
        ready(choices: oneSection, classId: 'c7'),
        ready(choices: oneSection, classId: 'c7', sectionId: 'sec1'),
        ready(choices: oneSection, classId: 'c7', sectionId: 'sec1', board: const BoardLoading()),
        ready(choices: oneSection, classId: 'c7', sectionId: 'sec1', board: const BoardLoaded(openRoll, {})),
      ],
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'keeps the failure for the screen, and reads again on retry',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => repository.sections('i1')).thenAnswer((_) async {
          if (++calls == 1) throw refusal('FORBIDDEN', status: 403);
          return twoClasses;
        });
      },
      act: (bloc) async {
        bloc.add(const AttendanceStarted());
        await bloc.stream.firstWhere((state) => state is AttendanceFailed);
        bloc.add(const AttendanceStarted());
      },
      expect: () => [
        const AttendanceLoading(),
        AttendanceFailed(refusal('FORBIDDEN', status: 403)),
        const AttendanceLoading(),
        ready(),
      ],
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'reads the roll once a section is chosen in a class that has two',
      build: build,
      act: (bloc) async {
        bloc.add(const AttendanceStarted());
        await bloc.stream.firstWhere((state) => state is AttendanceReady);
        bloc
          ..add(const AttendanceClassChosen('c7'))
          ..add(const AttendanceSectionChosen('sec1'));
      },
      skip: 3,
      expect: () => [
        ready(classId: 'c7', sectionId: 'sec1'),
        ready(classId: 'c7', sectionId: 'sec1', board: const BoardLoading()),
        ready(classId: 'c7', sectionId: 'sec1', board: const BoardLoaded(openRoll, {})),
      ],
      verify: (_) => verify(() => repository.roster('sec1', '2026-11-17')).called(1),
    );

    test('puts the roll away with the class it was of, and chooses the only section of the next class', () async {
      when(() => repository.roster('sec3', '2026-11-17')).thenAnswer((_) async => holidayRoll);
      final bloc = await open();
      bloc.add(const AttendanceClassChosen('c8'));
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.board is BoardLoaded);
      expect(
        bloc.state,
        ready(classId: 'c8', sectionId: 'sec3', board: const BoardLoaded(holidayRoll, {})),
      );
      await bloc.close();
    });

    test('drops the roll being read when another class is chosen, so it never lands under the new class', () async {
      final slow = Completer<AttendanceRoster>();
      when(() => repository.roster('sec3', '2026-11-17')).thenAnswer((_) => slow.future);
      final bloc = build()..add(const AttendanceStarted());
      await bloc.stream.firstWhere((state) => state is AttendanceReady);
      bloc
        ..add(const AttendanceClassChosen('c8'))
        ..add(const AttendanceSectionChosen('sec3'));
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.board is BoardLoading);
      // The 7th has two sections, so nothing is chosen in it.
      bloc.add(const AttendanceClassChosen('c7'));
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.classId == 'c7');
      slow.complete(holidayRoll);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, ready(classId: 'c7'));
      await bloc.close();
    });

    test('reads the roll again for another day, and keeps the failure when it cannot be read', () async {
      when(() => repository.roster('sec1', '2026-11-16')).thenThrow(refusal('CURRENT_YEAR_REQUIRED', status: 422));
      final bloc = await open();
      bloc.add(const AttendanceDayChosen('2026-11-16'));
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.board is BoardFailed);
      expect(
        bloc.state,
        ready(
          classId: 'c7',
          sectionId: 'sec1',
          day: '2026-11-16',
          board: BoardFailed(refusal('CURRENT_YEAR_REQUIRED', status: 422)),
        ),
      );
      when(() => repository.roster('sec1', '2026-11-16')).thenAnswer((_) async => takenRoll);
      bloc.add(const AttendanceRollRetried());
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.board is BoardLoaded);
      expect(boardOf(bloc).roster, takenRoll);
      await bloc.close();
    });

    test('ignores the choice of the day already shown, and of nothing', () async {
      final bloc = await open();
      final shown = bloc.state;
      bloc
        ..add(const AttendanceDayChosen('2026-11-17'))
        ..add(const AttendanceSectionChosen('sec1'))
        ..add(const AttendanceSectionChosen(null))
        ..add(const AttendanceClassChosen(null))
        ..add(const AttendanceClassChosen('c7'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, shown);
      verify(() => repository.roster('sec1', '2026-11-17')).called(1);
      await bloc.close();
    });

    test('shows the answer for the day last chosen, not a slower answer for the one before', () async {
      final slow = Completer<AttendanceRoster>();
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) => slow.future);
      when(() => repository.roster('sec1', '2026-11-16')).thenAnswer((_) async => takenRoll);
      final bloc = build()..add(const AttendanceStarted());
      await bloc.stream.firstWhere((state) => state is AttendanceReady);
      bloc
        ..add(const AttendanceClassChosen('c7'))
        ..add(const AttendanceSectionChosen('sec1'));
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.board is BoardLoading);
      bloc.add(const AttendanceDayChosen('2026-11-16'));
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.board is BoardLoaded);
      slow.complete(openRoll);
      await Future<void>.delayed(Duration.zero);
      expect(boardOf(bloc).roster, takenRoll);
      await bloc.close();
    });
  });

  group('marking', () {
    test('counts the students Present as the marks stand, and names those who are not', () async {
      final bloc = await open();
      expect(boardOf(bloc).present, 3);
      bloc
        ..add(const AttendanceMarked('e2', AttendanceMark.absent))
        ..add(const AttendanceMarked('e3', AttendanceMark.late));
      await Future<void>.delayed(Duration.zero);
      final board = boardOf(bloc);
      expect(board.present, 1);
      expect(board.markOf(bea), AttendanceMark.absent);
      expect(board.exceptions, const [
        MarkChange(enrolmentId: 'e2', mark: AttendanceMark.absent),
        MarkChange(enrolmentId: 'e3', mark: AttendanceMark.late),
      ]);
      // Marking a student Present again takes them off the list.
      bloc.add(const AttendanceMarked('e2', AttendanceMark.present));
      await Future<void>.delayed(Duration.zero);
      expect(boardOf(bloc).exceptions, const [MarkChange(enrolmentId: 'e3', mark: AttendanceMark.late)]);
      await bloc.close();
    });

    test('has no change while every mark is the one the roll came with', () async {
      when(() => repository.roster('sec1', '2026-11-16')).thenAnswer((_) async => takenRoll);
      final bloc = await open();
      bloc.add(const AttendanceDayChosen('2026-11-16'));
      await bloc.stream.firstWhere(
        (state) =>
            state is AttendanceReady && state.board is BoardLoaded && (state.board as BoardLoaded).roster == takenRoll,
      );
      expect(boardOf(bloc).changes, isEmpty);
      bloc.add(const AttendanceMarked('e2', AttendanceMark.absent));
      await Future<void>.delayed(Duration.zero);
      expect(boardOf(bloc).changes, isEmpty);
      bloc.add(const AttendanceMarked('e2', AttendanceMark.present));
      await Future<void>.delayed(Duration.zero);
      expect(boardOf(bloc).changes, const [MarkChange(enrolmentId: 'e2', mark: AttendanceMark.present)]);
      await bloc.close();
    });
  });

  group('submitting', () {
    test('sends only the students who are not Present, then reads the roll again and says it once', () async {
      when(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => submitted);
      final bloc = await open();
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => takenRoll);
      bloc
        ..add(const AttendanceMarked('e2', AttendanceMark.absent))
        ..add(const AttendanceSubmitted());
      final states = <AttendanceState>[];
      final listening = bloc.stream.listen(states.add);
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.outcome != null);
      await listening.cancel();
      verify(
        () => repository.submit(
          sectionId: 'sec1',
          day: '2026-11-17',
          rosterCount: 3,
          exceptions: const [MarkChange(enrolmentId: 'e2', mark: AttendanceMark.absent)],
          idempotencyKey: 'key-1',
        ),
      ).called(1);
      final outcomes = [
        for (final state in states)
          if (state is AttendanceReady) state.outcome,
      ];
      expect(outcomes.whereType<AttendanceOutcome>(), [const AttendanceOutcome(AttendanceOutcomeKind.submitted, 3)]);
      expect((bloc.state as AttendanceReady).board, BoardLoaded(takenRoll, const {}));
      await bloc.close();
    });

    test(
      'says why a register was refused, keeps the marks, and sends the same attempt again with the same key',
      () async {
        var attempts = 0;
        when(
          () => repository.submit(
            sectionId: any(named: 'sectionId'),
            day: any(named: 'day'),
            rosterCount: any(named: 'rosterCount'),
            exceptions: any(named: 'exceptions'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer((_) async {
          if (++attempts == 1) throw refusal('DATE_IS_HOLIDAY', status: 422);
          return submitted;
        });
        final bloc = await open();
        bloc
          ..add(const AttendanceMarked('e2', AttendanceMark.absent))
          ..add(const AttendanceSubmitted());
        await bloc.stream.firstWhere(
          (state) =>
              state is AttendanceReady && state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
        );
        expect(boardOf(bloc).failure?.code, 'DATE_IS_HOLIDAY');
        expect(boardOf(bloc).saving, isFalse);
        expect(boardOf(bloc).marks, {'e2': AttendanceMark.absent});
        bloc.add(const AttendanceSubmitted());
        await bloc.stream.firstWhere((state) => state is AttendanceReady && state.outcome != null);
        final keysUsed = verify(
          () => repository.submit(
            sectionId: any(named: 'sectionId'),
            day: any(named: 'day'),
            rosterCount: any(named: 'rosterCount'),
            exceptions: any(named: 'exceptions'),
            idempotencyKey: captureAny(named: 'idempotencyKey'),
          ),
        ).captured;
        expect(keysUsed, ['key-1', 'key-1']);
        await bloc.close();
      },
    );

    test('starts a new attempt when a mark changes after a refusal', () async {
      when(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(refusal('REQUEST_TIMEOUT', status: 408));
      final bloc = await open();
      bloc.add(const AttendanceSubmitted());
      await bloc.stream.firstWhere(
        (state) =>
            state is AttendanceReady && state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
      );
      bloc
        ..add(const AttendanceMarked('e1', AttendanceMark.leave))
        ..add(const AttendanceSubmitted());
      await bloc.stream.firstWhere(
        (state) =>
            state is AttendanceReady &&
            state.board is BoardLoaded &&
            (state.board as BoardLoaded).failure != null &&
            !(state.board as BoardLoaded).saving &&
            (state.board as BoardLoaded).marks.isNotEmpty,
      );
      final keysUsed = verify(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured;
      expect(keysUsed, ['key-1', 'key-2']);
      await bloc.close();
    });

    test(
      'reads the roll again, and says why, when the register was taken meanwhile or a student joined or left',
      () async {
        for (final code in ['ATTENDANCE_ALREADY_SUBMITTED', 'ROSTER_CHANGED', 'STUDENT_NOT_IN_SECTION']) {
          when(
            () => repository.submit(
              sectionId: any(named: 'sectionId'),
              day: any(named: 'day'),
              rosterCount: any(named: 'rosterCount'),
              exceptions: any(named: 'exceptions'),
              idempotencyKey: any(named: 'idempotencyKey'),
            ),
          ).thenThrow(refusal(code));
          final bloc = await open();
          when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => takenRoll);
          bloc
            ..add(const AttendanceMarked('e2', AttendanceMark.absent))
            ..add(const AttendanceSubmitted());
          await bloc.stream.firstWhere(
            (state) =>
                state is AttendanceReady && state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
          );
          // The marks go with the roll they were made on.
          expect(boardOf(bloc), BoardLoaded(takenRoll, const {}, failure: refusal(code)));
          await bloc.close();
          when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => openRoll);
        }
      },
    );

    test('starts a new attempt when the day is taken again after a void, even with the same marks', () async {
      var taken = false;
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => taken ? takenRoll : openRoll);
      when(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async {
        taken = true;
        return submitted;
      });
      when(() => repository.voidRegister('r1', 2, any())).thenAnswer((_) async => taken = false);
      final bloc = await open()
        ..add(const AttendanceSubmitted());
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.outcome != null);
      bloc.add(const AttendanceVoided('Taken for the wrong day'));
      await bloc.stream.firstWhere(
        (state) => state is AttendanceReady && state.outcome?.kind == AttendanceOutcomeKind.voided,
      );
      bloc.add(const AttendanceSubmitted());
      await bloc.stream.firstWhere(
        (state) => state is AttendanceReady && state.outcome?.kind == AttendanceOutcomeKind.submitted && taken,
      );
      final keys = verify(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured;
      // A repeat of the first key would be answered with the register that was voided.
      expect(keys, ['key-1', 'key-2']);
      await bloc.close();
    });

    test('does nothing twice while a register is on its way', () async {
      final slow = Completer<int>();
      when(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) => slow.future);
      final bloc = await open();
      bloc
        ..add(const AttendanceSubmitted())
        ..add(const AttendanceSubmitted())
        ..add(const AttendanceMarked('e1', AttendanceMark.absent))
        ..add(const AttendanceDayChosen('2026-11-16'))
        ..add(const AttendanceClassChosen('c8'));
      await Future<void>.delayed(Duration.zero);
      expect(boardOf(bloc).saving, isTrue);
      expect(boardOf(bloc).marks, isEmpty);
      expect((bloc.state as AttendanceReady).day, '2026-11-17');
      slow.complete(submitted);
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.outcome != null);
      verify(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
      await bloc.close();
    });
  });

  group('correcting and voiding', () {
    Future<AttendanceBloc> openTaken() {
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => takenRoll);
      return open();
    }

    test('sends the marks that changed with the version the roll was read at, then reads it again', () async {
      when(() => repository.correct('r1', 2, any())).thenAnswer((_) async {});
      final bloc = await openTaken();
      bloc
        ..add(const AttendanceMarked('e2', AttendanceMark.present))
        ..add(const AttendanceMarked('e3', AttendanceMark.late))
        ..add(const AttendanceCorrected());
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.outcome != null);
      verify(
        () => repository.correct('r1', 2, const [
          MarkChange(enrolmentId: 'e2', mark: AttendanceMark.present),
          MarkChange(enrolmentId: 'e3', mark: AttendanceMark.late),
        ]),
      ).called(1);
      expect((bloc.state as AttendanceReady).outcome, const AttendanceOutcome(AttendanceOutcomeKind.corrected, 3));
      await bloc.close();
    });

    test('reads the roll again when a correction was made on an old version, or the register is void', () async {
      for (final code in ['VERSION_CONFLICT', 'SESSION_VOIDED']) {
        when(() => repository.correct('r1', 2, any())).thenThrow(refusal(code));
        final bloc = await openTaken();
        bloc
          ..add(const AttendanceMarked('e2', AttendanceMark.present))
          ..add(const AttendanceCorrected());
        await bloc.stream.firstWhere(
          (state) =>
              state is AttendanceReady && state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
        );
        expect(boardOf(bloc), BoardLoaded(takenRoll, const {}, failure: refusal(code)));
        await bloc.close();
      }
    });

    test('keeps the marks when a correction is refused for good', () async {
      when(() => repository.correct('r1', 2, any())).thenThrow(refusal('NOT_ASSIGNED', status: 403));
      final bloc = await openTaken();
      bloc
        ..add(const AttendanceMarked('e2', AttendanceMark.present))
        ..add(const AttendanceCorrected());
      await bloc.stream.firstWhere(
        (state) =>
            state is AttendanceReady && state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
      );
      expect(boardOf(bloc).marks, {'e2': AttendanceMark.present});
      expect(boardOf(bloc).failure?.code, 'NOT_ASSIGNED');
      await bloc.close();
    });

    test('voids the register with the reason and the version, and the day is free again', () async {
      when(() => repository.voidRegister('r1', 2, 'Taken for the wrong section')).thenAnswer((_) async {});
      final bloc = await openTaken();
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => openRoll);
      bloc.add(const AttendanceVoided('Taken for the wrong section'));
      await bloc.stream.firstWhere((state) => state is AttendanceReady && state.outcome != null);
      verify(() => repository.voidRegister('r1', 2, 'Taken for the wrong section')).called(1);
      expect((bloc.state as AttendanceReady).outcome, const AttendanceOutcome(AttendanceOutcomeKind.voided, 3));
      expect(boardOf(bloc).roster, openRoll);
      await bloc.close();
    });

    test('keeps the roll and says why when a void is refused', () async {
      when(() => repository.voidRegister(any(), any(), any())).thenThrow(refusal('FORBIDDEN', status: 403));
      final bloc = await openTaken();
      bloc.add(const AttendanceVoided('Taken for the wrong section'));
      await bloc.stream.firstWhere(
        (state) =>
            state is AttendanceReady && state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
      );
      expect(boardOf(bloc).failure?.code, 'FORBIDDEN');
      expect(boardOf(bloc).roster, takenRoll);
      await bloc.close();
    });
  });
}
