import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_calendar.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/attendance_calendar_bloc.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_calendar_page.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_calendar_view.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/attendance.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockActiveChildBloc extends MockBloc<ActiveChildEvent, ActiveChildState> implements ActiveChildBloc;

ApiFailure refusal(String code, {int status = 422}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late MockAttendanceRepository repository;
  setUp(() {
    repository = MockAttendanceRepository();
    getIt.registerSingleton<AttendanceRepository>(repository);
    when(() => repository.calendar('s1', '2026-11')).thenAnswer((_) async => november);
    when(() => repository.dayDetail('s1', '2026-11-03')).thenAnswer((_) async => absentOnThe3rd);
  });
  tearDown(getIt.reset);

  /// Today is the 17th of November 2026 in IST (04:00 UTC).
  DateTime clock() => DateTime.utc(2026, 11, 17, 4);

  Future<List<AttendanceFocus>> pump(
    WidgetTester tester, {
    bool canCorrect = false,
    double textScale = 1,
    Size size = const Size(400, 1400),
  }) async {
    final corrected = <AttendanceFocus>[];
    await tester.pumpAppScaled(
      BlocProvider(
        create: (_) => AttendanceCalendarBloc(repository, 's1', clock: clock)..add(const AttendanceCalendarStarted()),
        child: Scaffold(
          body: AttendanceCalendarView(studentId: 's1', onCorrect: canCorrect ? corrected.add : null),
        ),
      ),
      textScale: textScale,
      size: size,
    );
    await tester.pumpAndSettle();
    return corrected;
  }

  group('the month', () {
    testWidgets('shows the month, both percentages, the days with their letters and the counts under each colour', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('November 2026'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('attendanceCalendar.month')), matching: find.text('66.67%')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(const Key('attendanceCalendar.year')), matching: find.text('90.5%')),
        findsOneWidget,
      );
      expect(find.text('Present: 1 day'), findsOneWidget);
      expect(find.text('Absent: 1 day'), findsOneWidget);
      expect(find.text('Partially present: 0 days'), findsOneWidget);
      expect(find.text('Not marked: 2 days'), findsOneWidget);
      // The letters of the days that were marked: P, A, L and H, and the days between carry none.
      for (final letter in ['P', 'A', 'L', 'H']) {
        expect(find.text(letter), findsWidgets, reason: letter);
      }
    });

    testWidgets('says a day to a screen reader with its date and status, a weekly off and a holiday by name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      expect(find.bySemanticsLabel('03-11-2026, Absent'), findsOneWidget);
      expect(find.bySemanticsLabel('01-11-2026, Weekly off'), findsOneWidget);
      expect(find.bySemanticsLabel('05-11-2026, Holiday: Founders Day'), findsOneWidget);
      expect(find.bySemanticsLabel('06-11-2026, Not enrolled'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('with no day marked, says so instead of a percentage', (tester) async {
      when(() => repository.calendar('s1', '2026-11')).thenAnswer(
        (_) async => AttendanceCalendar(
          month: '2026-11',
          summary: const MonthSummary(
            presentDays: 0,
            absentDays: 0,
            lateDays: 0,
            halfDays: 0,
            leaveDays: 0,
            holidays: 0,
            notMarkedDays: 0,
          ),
          days: november.days,
        ),
      );
      await pump(tester);
      expect(find.text('No day marked yet'), findsNWidgets(2));
    });

    testWidgets('steps to another month and reads it', (tester) async {
      when(() => repository.calendar('s1', '2026-10')).thenAnswer((_) async => november);
      await pump(tester);
      await tester.tap(find.byKey(const Key('monthStepper.previous')));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      verify(() => repository.calendar('s1', '2026-10')).called(1);
    });

    testWidgets('says a month outside the academic year, and the stepper still leads back', (tester) async {
      when(() => repository.calendar('s1', any())).thenAnswer((_) async => november);
      when(() => repository.calendar('s1', '2027-04')).thenThrow(refusal('OUTSIDE_ACADEMIC_YEAR'));
      await pump(tester);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('monthStepper.next')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('attendanceCalendar.outsideYear')), findsOneWidget);
      expect(find.text('No academic year covers this month.'), findsOneWidget);
      expect(find.byKey(const Key('monthStepper.previous')), findsOneWidget);
    });

    testWidgets('says why it could not be read, and reads again on Try again', (tester) async {
      var calls = 0;
      when(() => repository.calendar('s1', '2026-11')).thenAnswer((_) async {
        if (++calls == 1) throw refusal('SERVER_ERROR', status: 500);
        return november;
      });
      await pump(tester);
      expect(find.byKey(const Key('attendanceCalendar.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Present: 1 day'), findsOneWidget);
    });

    testWidgets('says plainly when the person may not see it', (tester) async {
      when(() => repository.calendar('s1', '2026-11')).thenThrow(refusal('FORBIDDEN', status: 403));
      await pump(tester);
      expect(find.byKey(const Key('attendanceCalendar.forbidden')), findsOneWidget);
    });

    testWidgets('says a teacher may read only the students of their sections', (tester) async {
      when(() => repository.calendar('s1', '2026-11')).thenThrow(refusal('NOT_ASSIGNED', status: 403));
      await pump(tester);
      expect(find.textContaining('sections you lead or teach'), findsOneWidget);
    });

    testWidgets('says a blocked child in its own words', (tester) async {
      when(() => repository.calendar('s1', '2026-11')).thenThrow(refusal('CHILD_ACCESS_BLOCKED', status: 403));
      await pump(tester);
      expect(find.text("Access to this child's information is blocked. Contact the school."), findsOneWidget);
    });

    testWidgets('says a student that is not found in its own words', (tester) async {
      when(() => repository.calendar('s1', '2026-11')).thenThrow(refusal('NOT_FOUND', status: 404));
      await pump(tester);
      expect(find.text('This student could not be found.'), findsOneWidget);
    });

    testWidgets('reads whole at a large text scale on a small phone', (tester) async {
      await pump(tester, textScale: 2, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester), isEmpty);
    });
  });

  group('a day', () {
    testWidgets('opens who marked it, and when it was corrected last', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('calendar.day.3')));
      await tester.pumpAndSettle();
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('03-11-2026'), findsOneWidget);
      expect(find.byKey(const Key('dayDetail.status')), findsOneWidget);
      expect(find.text('R. Nair'), findsOneWidget);
      expect(find.text('03-11-2026 10:00'), findsOneWidget);
      expect(find.text('03-11-2026 11:30'), findsOneWidget);
      expect(find.text('7th · A'), findsOneWidget);
      expect(find.byKey(const Key('dayDetail.correct')), findsNothing);
    });

    testWidgets('offers Correct to staff, and answers the register to open', (tester) async {
      final corrected = await pump(tester, canCorrect: true);
      await tester.tap(find.byKey(const ValueKey('calendar.day.3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dayDetail.correct')));
      await tester.pumpAndSettle();
      expect(corrected, [const AttendanceFocus(sectionId: 'sec1', day: '2026-11-03')]);
    });

    testWidgets('says that no register was taken, and offers no Correct', (tester) async {
      when(() => repository.dayDetail('s1', '2026-11-10')).thenAnswer(
        (_) async => const DayDetail(day: '2026-11-10', status: DayStatus.notMarked, isWeekend: false),
      );
      await pump(tester, canCorrect: true);
      await tester.tap(find.byKey(const ValueKey('calendar.day.10')));
      await tester.pumpAndSettle();
      expect(find.text('No register was taken for this day.'), findsOneWidget);
      expect(find.byKey(const Key('dayDetail.correct')), findsNothing);
    });

    testWidgets('names the holiday, and a weekly off', (tester) async {
      when(() => repository.dayDetail('s1', '2026-11-01')).thenAnswer(
        (_) async => const DayDetail(day: '2026-11-01', status: DayStatus.notMarked, isWeekend: true),
      );
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('calendar.day.1')));
      await tester.pumpAndSettle();
      expect(find.text('Weekly off'), findsOneWidget);
    });

    testWidgets('says why a day could not be read, and reads it again on Try again', (tester) async {
      var calls = 0;
      when(() => repository.dayDetail('s1', '2026-11-03')).thenAnswer((_) async {
        if (++calls == 1) throw refusal('SERVER_ERROR', status: 500);
        return absentOnThe3rd;
      });
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('calendar.day.3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dayDetail.failed')), findsOneWidget);
      await tester.tap(
        find.descendant(of: find.byKey(const Key('dayDetail.failed')), matching: find.text('Try again')),
      );
      await tester.pumpAndSettle();
      expect(find.text('R. Nair'), findsOneWidget);
    });

    testWidgets('reads whole at a large text scale on a small phone', (tester) async {
      await pump(tester, canCorrect: true, textScale: 2, size: const Size(320, 640));
      await tester.tap(find.byKey(const ValueKey('calendar.day.3')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester), isEmpty);
    });
  });

  group('the screens', () {
    const diya = LinkedChild(
      studentId: 's1',
      firstName: 'Diya',
      institutionName: 'Green Valley School',
      isBlocked: false,
    );

    Future<void> pumpParent(WidgetTester tester, ActiveChildState state) {
      final children = _MockActiveChildBloc();
      when(() => children.state).thenReturn(state);
      return tester.pumpAppScaled(
        BlocProvider<ActiveChildBloc>.value(
          value: children,
          child: AttendanceCalendarPage(clock: clock),
        ),
        size: const Size(400, 1400),
      );
    }

    testWidgets("a parent's says there is no child to show when there is none", (tester) async {
      await pumpParent(tester, const ActiveChildNone());
      expect(find.byKey(const Key('attendanceCalendar.noChild')), findsOneWidget);
    });

    testWidgets("a parent's reads the month of the child shown, and a day offers no Correct", (tester) async {
      await pumpParent(tester, const ActiveChildReady(children: [diya], selected: diya));
      await tester.pumpAndSettle();
      expect(find.text('Present: 1 day'), findsOneWidget);
      verify(() => repository.calendar('s1', '2026-11')).called(1);
      await tester.tap(find.byKey(const ValueKey('calendar.day.3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dayDetail.correct')), findsNothing);
    });

    testWidgets("a student's for staff names them, and Correct opens that register", (tester) async {
      Object? opened;
      final router = GoRouter(
        initialLocation: '/student',
        routes: [
          GoRoute(
            path: '/student',
            builder: (_, _) => StudentAttendancePage(
              args: const StudentAttendanceArgs(studentId: 's1', name: 'Diya Shetty'),
              clock: clock,
            ),
          ),
          GoRoute(
            path: '/attendance',
            builder: (_, state) {
              opened = state.extra;
              return const Scaffold(body: Text('register'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Diya Shetty'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar.day.3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dayDetail.correct')));
      await tester.pumpAndSettle();
      expect(find.text('register'), findsOneWidget);
      expect(opened, const AttendanceFocus(sectionId: 'sec1', day: '2026-11-03'));
    });
  });
}
