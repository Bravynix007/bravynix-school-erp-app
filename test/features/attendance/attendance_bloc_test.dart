import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_day.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/attendance.dart';
import '../../helpers/mocks.dart';

ApiFailure refusal(String code, {int status = 409}) => ApiFailure(statusCode: status, code: code, message: code);

void main() {
  late MockAttendanceRepository repository;
  var keys = 0;
  setUp(() {
    repository = MockAttendanceRepository();
    keys = 0;
    registerFallbackValue(const <MarkChange>[]);
    when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => openRoll);
  });

  AttendanceBloc build() => AttendanceBloc(repository, newKey: () => 'key-${++keys}');

  const section1 = SectionDay(sectionId: 'sec1', day: '2026-11-17');

  /// Opens the screen on section A of the 7th and waits for its roll.
  Future<AttendanceBloc> open() async {
    final bloc = build()..add(const AttendanceSelected(section1));
    await bloc.stream.firstWhere((state) => state.board is BoardLoaded);
    return bloc;
  }

  BoardLoaded boardOf(AttendanceBloc bloc) => bloc.state.board as BoardLoaded;

  group('choosing', () {
    blocTest<AttendanceBloc, AttendanceState>(
      'has nothing on the roll until a section is selected',
      build: build,
      expect: () => const <AttendanceState>[],
      verify: (bloc) {
        expect(bloc.state, const AttendanceState());
        verifyNever(() => repository.roster(any(), any()));
      },
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'reads the roll of the section and day selected',
      build: build,
      act: (bloc) => bloc.add(const AttendanceSelected(section1)),
      expect: () => [
        const AttendanceState(board: BoardLoading()),
        const AttendanceState(board: BoardLoaded(openRoll, {})),
      ],
      verify: (_) => verify(() => repository.roster('sec1', '2026-11-17')).called(1),
    );

    test('puts the roll away when no section is selected any more', () async {
      final bloc = await open();
      bloc.add(const AttendanceSelected(null));
      await bloc.stream.firstWhere((state) => state.board is BoardEmpty);
      expect(bloc.state, const AttendanceState());
      await bloc.close();
    });

    test('drops the roll being read when the section is left, so it never lands under the next choice', () async {
      final slow = Completer<AttendanceRoster>();
      when(() => repository.roster('sec3', '2026-11-17')).thenAnswer((_) => slow.future);
      final bloc = build()..add(const AttendanceSelected(SectionDay(sectionId: 'sec3', day: '2026-11-17')));
      await bloc.stream.firstWhere((state) => state.board is BoardLoading);
      bloc.add(const AttendanceSelected(null));
      await bloc.stream.firstWhere((state) => state.board is BoardEmpty);
      slow.complete(holidayRoll);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const AttendanceState());
      await bloc.close();
    });

    test('reads the roll again for another day, and keeps the failure when it cannot be read', () async {
      when(() => repository.roster('sec1', '2026-11-16')).thenThrow(refusal('CURRENT_YEAR_REQUIRED', status: 422));
      final bloc = await open();
      bloc.add(const AttendanceSelected(SectionDay(sectionId: 'sec1', day: '2026-11-16')));
      await bloc.stream.firstWhere((state) => state.board is BoardFailed);
      expect(bloc.state, AttendanceState(board: BoardFailed(refusal('CURRENT_YEAR_REQUIRED', status: 422))));
      when(() => repository.roster('sec1', '2026-11-16')).thenAnswer((_) async => takenRoll);
      bloc.add(const AttendanceRollRetried());
      await bloc.stream.firstWhere((state) => state.board is BoardLoaded);
      expect(boardOf(bloc).roster, takenRoll);
      await bloc.close();
    });

    test('shows the answer for the day last selected, not a slower answer for the one before', () async {
      final slow = Completer<AttendanceRoster>();
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) => slow.future);
      when(() => repository.roster('sec1', '2026-11-16')).thenAnswer((_) async => takenRoll);
      final bloc = build()..add(const AttendanceSelected(section1));
      await bloc.stream.firstWhere((state) => state.board is BoardLoading);
      bloc.add(const AttendanceSelected(SectionDay(sectionId: 'sec1', day: '2026-11-16')));
      await bloc.stream.firstWhere((state) => state.board is BoardLoaded);
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
      bloc.add(const AttendanceSelected(SectionDay(sectionId: 'sec1', day: '2026-11-16')));
      await bloc.stream.firstWhere(
        (state) => state.board is BoardLoaded && (state.board as BoardLoaded).roster == takenRoll,
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
      await bloc.stream.firstWhere((state) => state.outcome != null);
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
      final outcomes = [for (final state in states) state.outcome];
      expect(outcomes.whereType<AttendanceOutcome>(), [const AttendanceOutcome(AttendanceOutcomeKind.submitted, 3)]);
      expect(bloc.state.board, BoardLoaded(takenRoll, const {}));
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
          (state) => state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
        );
        expect(boardOf(bloc).failure?.code, 'DATE_IS_HOLIDAY');
        expect(boardOf(bloc).saving, isFalse);
        expect(boardOf(bloc).marks, {'e2': AttendanceMark.absent});
        bloc.add(const AttendanceSubmitted());
        await bloc.stream.firstWhere((state) => state.outcome != null);
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
        (state) => state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
      );
      bloc
        ..add(const AttendanceMarked('e1', AttendanceMark.leave))
        ..add(const AttendanceSubmitted());
      await bloc.stream.firstWhere(
        (state) =>
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
            (state) => state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
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
      await bloc.stream.firstWhere((state) => state.outcome != null);
      bloc.add(const AttendanceVoided('Taken for the wrong day'));
      await bloc.stream.firstWhere(
        (state) => state.outcome?.kind == AttendanceOutcomeKind.voided,
      );
      bloc.add(const AttendanceSubmitted());
      await bloc.stream.firstWhere(
        (state) => state.outcome?.kind == AttendanceOutcomeKind.submitted && taken,
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
        ..add(const AttendanceMarked('e1', AttendanceMark.absent));
      await Future<void>.delayed(Duration.zero);
      expect(boardOf(bloc).saving, isTrue);
      expect(boardOf(bloc).marks, isEmpty);
      slow.complete(submitted);
      await bloc.stream.firstWhere((state) => state.outcome != null);
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
      await bloc.stream.firstWhere((state) => state.outcome != null);
      verify(
        () => repository.correct('r1', 2, const [
          MarkChange(enrolmentId: 'e2', mark: AttendanceMark.present),
          MarkChange(enrolmentId: 'e3', mark: AttendanceMark.late),
        ]),
      ).called(1);
      expect(bloc.state.outcome, const AttendanceOutcome(AttendanceOutcomeKind.corrected, 3));
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
          (state) => state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
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
        (state) => state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
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
      await bloc.stream.firstWhere((state) => state.outcome != null);
      verify(() => repository.voidRegister('r1', 2, 'Taken for the wrong section')).called(1);
      expect(bloc.state.outcome, const AttendanceOutcome(AttendanceOutcomeKind.voided, 3));
      expect(boardOf(bloc).roster, openRoll);
      await bloc.close();
    });

    test('keeps the roll and says why when a void is refused', () async {
      when(() => repository.voidRegister(any(), any(), any())).thenThrow(refusal('FORBIDDEN', status: 403));
      final bloc = await openTaken();
      bloc.add(const AttendanceVoided('Taken for the wrong section'));
      await bloc.stream.firstWhere(
        (state) => state.board is BoardLoaded && (state.board as BoardLoaded).failure != null,
      );
      expect(boardOf(bloc).failure?.code, 'FORBIDDEN');
      expect(boardOf(bloc).roster, takenRoll);
      await bloc.close();
    });
  });
}
