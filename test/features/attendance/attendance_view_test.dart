import 'dart:async';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/attendance.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

ApiFailure refusal(String code, {int status = 409}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late MockAttendanceRepository repository;
  setUpAll(() => registerFallbackValue(const <MarkChange>[]));
  setUp(() {
    repository = MockAttendanceRepository();
    when(() => repository.sections('i1')).thenAnswer((_) async => oneSection);
    when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => openRoll);
  });

  /// Today is the 17th of November 2026 in IST (04:00 UTC).
  DateTime clock() => DateTime.utc(2026, 11, 17, 4);

  Future<void> pump(
    WidgetTester tester, {
    bool mayMark = true,
    bool mayVoid = false,
    double textScale = 1,
    Size size = const Size(400, 1400),
  }) async {
    await tester.pumpAppScaled(
      BlocProvider(
        create: (_) =>
            AttendanceBloc(repository, 'i1', clock: clock, newKey: () => 'key-1')..add(const AttendanceStarted()),
        child: Scaffold(
          body: AttendanceView(mayMark: mayMark, mayVoid: mayVoid, today: '2026-11-17'),
        ),
      ),
      textScale: textScale,
      size: size,
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String field, String text) async {
    await tester.tap(find.byKey(Key(field)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> mark(WidgetTester tester, String enrolment, String label) async {
    final card = find.byKey(ValueKey('attendance.student.$enrolment'));
    await tester.tap(find.descendant(of: card, matching: find.bySemanticsLabel(label)));
    await tester.pumpAndSettle();
  }

  group('reading the classes', () {
    testWidgets('shows a placeholder while it reads', (tester) async {
      await tester.pumpAppScaled(
        BlocProvider(
          create: (_) => AttendanceBloc(repository, 'i1', clock: clock),
          child: const Scaffold(body: AttendanceView(mayMark: true, mayVoid: false, today: '2026-11-17')),
        ),
      );
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byKey(const Key('attendance.class')), findsNothing);
    });

    testWidgets('says plainly when the person may not see it', (tester) async {
      when(() => repository.sections('i1')).thenThrow(refusal('FORBIDDEN', status: 403));
      await pump(tester);
      expect(find.byKey(const Key('attendance.forbidden')), findsOneWidget);
    });

    testWidgets('says why it could not read, and reads again on Try again', (tester) async {
      var calls = 0;
      when(() => repository.sections('i1')).thenAnswer((_) async {
        if (++calls == 1) throw refusal('SERVER_ERROR', status: 500);
        return oneSection;
      });
      await pump(tester);
      expect(find.byKey(const Key('attendance.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attendance.class')), findsOneWidget);
    });

    testWidgets('with no classes, says so', (tester) async {
      when(() => repository.sections('i1')).thenAnswer((_) async => const MarkingSections(classes: [], sections: []));
      await pump(tester);
      expect(find.byKey(const Key('attendance.noSections')), findsOneWidget);
    });

    testWidgets('with a choice, asks for the class and the section first', (tester) async {
      when(() => repository.sections('i1')).thenAnswer((_) async => twoClasses);
      await pump(tester);
      expect(find.byKey(const Key('attendance.pick')), findsOneWidget);
      await choose(tester, 'attendance.class', '7th');
      await choose(tester, 'attendance.section', '7th · A');
      expect(find.byKey(const Key('attendance.pick')), findsNothing);
      expect(find.byKey(const ValueKey('attendance.student.e1')), findsOneWidget);
      verify(() => repository.roster('sec1', '2026-11-17')).called(1);
    });
  });

  group('taking a register', () {
    testWidgets('lists everyone Present, counts them, and sends only the exceptions on Submit', (tester) async {
      when(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => submitted);
      await pump(tester);
      expect(find.text('Asha Rao, roll 1'), findsOneWidget);
      expect(find.text('Present: 3 / 3'), findsOneWidget);

      await mark(tester, 'e2', 'Absent');
      expect(find.text('Present: 2 / 3'), findsOneWidget);

      await tester.tap(find.text('Confirm & Submit Attendance'));
      await tester.pumpAndSettle();
      final sent =
          verify(
                () => repository.submit(
                  sectionId: 'sec1',
                  day: '2026-11-17',
                  rosterCount: 3,
                  exceptions: captureAny(named: 'exceptions'),
                  idempotencyKey: 'key-1',
                ),
              ).captured.single
              as List<MarkChange>;
      expect(sent.map((c) => c.enrolmentId), ['e2']);
      expect(find.text('Attendance submitted for 3 students'), findsOneWidget);
      verify(() => repository.roster('sec1', '2026-11-17')).called(greaterThan(0));
    });

    testWidgets('says a refusal above the buttons, in the app words', (tester) async {
      when(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(refusal('ROSTER_CHANGED'));
      await pump(tester);
      await tester.tap(find.text('Confirm & Submit Attendance'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attendance.error')), findsOneWidget);
      expect(find.textContaining('A student joined or left'), findsOneWidget);
    });

    testWidgets('a section with no students shows why, and Submit does nothing', (tester) async {
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer(
        (_) async => const AttendanceRoster(
          sectionId: 'sec1',
          day: '2026-11-17',
          isHoliday: false,
          canMark: true,
          students: [],
        ),
      );
      await pump(tester);
      expect(find.byKey(const Key('attendance.noStudents')), findsOneWidget);
      await tester.tap(find.text('Confirm & Submit Attendance'));
      await tester.pumpAndSettle();
      verifyNever(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
    });

    testWidgets('a holiday shows its title and no roll', (tester) async {
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => holidayRoll);
      await pump(tester);
      expect(find.text('Holiday: Founders Day'), findsOneWidget);
      expect(find.byKey(const ValueKey('attendance.student.e1')), findsNothing);
      expect(find.text('Confirm & Submit Attendance'), findsNothing);
    });

    testWidgets('a day that cannot be marked says so, and shows no roll that would read as all Present', (
      tester,
    ) async {
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer(
        (_) async => const AttendanceRoster(
          sectionId: 'sec1',
          day: '2026-11-17',
          isHoliday: false,
          canMark: false,
          students: [asha],
        ),
      );
      await pump(tester);
      expect(find.byKey(const Key('attendance.closed')), findsOneWidget);
      expect(find.byKey(const ValueKey('attendance.student.e1')), findsNothing);
    });

    testWidgets('says why a roll could not be read, and reads it again on Try again', (tester) async {
      var calls = 0;
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async {
        if (++calls == 1) throw refusal('SERVER_ERROR', status: 500);
        return openRoll;
      });
      await pump(tester);
      expect(find.byKey(const Key('attendance.rollFailed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('attendance.student.e1')), findsOneWidget);
    });

    testWidgets('while a register is on its way, the marks cannot be changed', (
      tester,
    ) async {
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
      await pump(tester);
      await tester.tap(find.text('Confirm & Submit Attendance'));
      await tester.pump();
      // The marks are shown as they are, and no button changes them.
      final card = find.byKey(const ValueKey('attendance.student.e2'));
      expect(find.descendant(of: card, matching: find.bySemanticsLabel('Absent')), findsNothing);
      expect(find.text('Confirm & Submit Attendance'), findsNothing);
      verify(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
      slow.complete(submitted);
      await tester.pumpAndSettle();
    });

    testWidgets('says why a roll was read again over a day that cannot be marked', (tester) async {
      var read = 0;
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => ++read == 1 ? openRoll : holidayRoll);
      when(
        () => repository.submit(
          sectionId: any(named: 'sectionId'),
          day: any(named: 'day'),
          rosterCount: any(named: 'rosterCount'),
          exceptions: any(named: 'exceptions'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(refusal('ROSTER_CHANGED'));
      await pump(tester);
      await tester.tap(find.text('Confirm & Submit Attendance'));
      await tester.pumpAndSettle();
      expect(find.text('Holiday: Founders Day'), findsOneWidget);
      expect(find.byKey(const Key('attendance.error')), findsOneWidget);
      expect(find.textContaining('A student joined or left'), findsOneWidget);
    });

    testWidgets('keeps the class and the section when a roll is read again after it failed', (tester) async {
      var calls = 0;
      when(() => repository.sections('i1')).thenAnswer((_) async => twoClasses);
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async {
        if (++calls == 1) throw refusal('SERVER_ERROR', status: 500);
        return openRoll;
      });
      await pump(tester);
      await choose(tester, 'attendance.class', '7th');
      await choose(tester, 'attendance.section', '7th · A');
      expect(find.byKey(const Key('attendance.rollFailed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('attendance.student.e1')), findsOneWidget);
      verify(() => repository.sections('i1')).called(1);
    });

    testWidgets('offers the days from a year ago to today and no later', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('attendance.day')));
      await tester.pumpAndSettle();
      final calendar = tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker));
      expect([calendar.firstDate, calendar.lastDate], [DateTime(2025, 11, 17), DateTime(2026, 11, 17)]);
      expect(find.text('17-11-2026'), findsOneWidget);
    });

    testWidgets('a person who may not mark is told so on a day with no register to take', (tester) async {
      when(() => repository.roster('sec1', '2026-11-17')).thenAnswer(
        (_) async => const AttendanceRoster(
          sectionId: 'sec1',
          day: '2026-11-17',
          isHoliday: false,
          canMark: false,
          students: [asha],
        ),
      );
      await pump(tester, mayMark: false);
      expect(find.text('You mark attendance only at your own Institution.'), findsOneWidget);
    });

    testWidgets('a teacher away from their own Institution reads the roll and cannot change it', (tester) async {
      await pump(tester, mayMark: false);
      expect(find.byKey(const ValueKey('attendance.student.e1')), findsOneWidget);
      expect(find.text('Confirm & Submit Attendance'), findsNothing);
    });
  });

  group('a register already taken', () {
    setUp(() => when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => takenRoll));

    testWidgets('says who took it, and opens it for correction, with Save only once something changed', (tester) async {
      when(() => repository.correct(any(), any(), any())).thenAnswer((_) async {});
      await pump(tester);
      expect(find.byKey(const Key('attendance.taken')), findsOneWidget);
      expect(find.textContaining('Taken by R. Nair'), findsOneWidget);
      expect(find.text('Present: 2 / 3'), findsOneWidget);
      expect(find.text('Void this register'), findsNothing);

      await tester.tap(find.text('Save corrections'));
      await tester.pumpAndSettle();
      verifyNever(() => repository.correct(any(), any(), any()));

      await mark(tester, 'e2', 'Present');
      await tester.tap(find.text('Save corrections'));
      await tester.pumpAndSettle();
      verify(() => repository.correct('r1', 2, const [MarkChange(enrolmentId: 'e2', mark: AttendanceMark.present)]))
          .called(1);
      expect(find.text('Attendance corrected'), findsOneWidget);
    });

    testWidgets('an Owner or an Admin can void it, once a reason of five characters is given', (tester) async {
      when(() => repository.voidRegister(any(), any(), any())).thenAnswer((_) async {});
      await pump(tester, mayVoid: true);
      await tester.tap(find.text('Void this register'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('attendanceVoid.reason')), 'Marked the wrong section');
      await tester.tap(find.byKey(const Key('attendanceVoid.confirm')));
      await tester.pumpAndSettle();
      verify(() => repository.voidRegister('r1', 2, 'Marked the wrong section')).called(1);
    });

    testWidgets('a reason of spaces is no reason, and one is cut at 500 characters', (tester) async {
      when(() => repository.voidRegister(any(), any(), any())).thenAnswer((_) async {});
      await pump(tester, mayVoid: true);
      await tester.tap(find.text('Void this register'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('attendanceVoid.reason')), '        ');
      await tester.tap(find.byKey(const Key('attendanceVoid.confirm')));
      await tester.pumpAndSettle();
      expect(find.text('At least 5 characters.'), findsOneWidget);
      verifyNever(() => repository.voidRegister(any(), any(), any()));
      await tester.enterText(find.byKey(const Key('attendanceVoid.reason')), 'x' * 600);
      await tester.tap(find.byKey(const Key('attendanceVoid.confirm')));
      await tester.pumpAndSettle();
      verify(() => repository.voidRegister('r1', 2, 'x' * 500)).called(1);
    });

    testWidgets('asks for a reason before voiding, and cancel voids nothing', (tester) async {
      await pump(tester, mayVoid: true);
      await tester.tap(find.text('Void this register'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('attendanceVoid.reason')), 'no');
      await tester.tap(find.byKey(const Key('attendanceVoid.confirm')));
      await tester.pumpAndSettle();
      expect(find.text('At least 5 characters.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('attendanceVoid.cancel')));
      await tester.pumpAndSettle();
      verifyNever(() => repository.voidRegister(any(), any(), any()));
    });

    testWidgets('a teacher away from their own Institution sees the marks as chips, with no buttons', (tester) async {
      await pump(tester, mayMark: false);
      expect(find.byKey(const Key('attendance.viewOnly')), findsOneWidget);
      expect(find.text('Save corrections'), findsNothing);
      expect(find.text('Absent'), findsOneWidget);
    });

    testWidgets('says that the register changed meanwhile, over the roll', (tester) async {
      when(() => repository.correct(any(), any(), any())).thenThrow(refusal('VERSION_CONFLICT'));
      await pump(tester);
      await mark(tester, 'e2', 'Present');
      await tester.tap(find.text('Save corrections'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Someone else changed this register'), findsOneWidget);
    });
  });

  group('large text', () {
    for (final (name, roll) in [('an open roll', openRoll), ('a taken register', takenRoll)]) {
      testWidgets('$name fits at a large text scale on a small phone', (tester) async {
        when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => roll);
        await pump(tester, mayVoid: true, textScale: 2, size: const Size(320, 640));
        expect(tester.takeException(), isNull);
        expect(clippedParagraphs(tester, unbreakable: 320 - 6 * 16), isEmpty);
      });
    }
  });
}
