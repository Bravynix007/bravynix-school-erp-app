import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/bloc/timetable_bloc.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/timetable_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/timetable.dart';

class _MockTimetableBloc extends MockBloc<ListEvent, ListState<TimetableEntry>> implements TimetableBloc;

void main() {
  late _MockTimetableBloc bloc;
  setUpAll(() => registerFallbackValue(const ListRequested()));
  setUp(() => bloc = _MockTimetableBloc());

  // 2026-11-16 is a Monday and 2026-11-22 a Sunday.
  final monday = DateTime(2026, 11, 16);
  final sunday = DateTime(2026, 11, 22);

  Future<void> pump(
    WidgetTester tester,
    ListState<TimetableEntry> state, {
    TimetableWeek week = const SectionWeek('sec1'),
    DateTime? today,
    double textScale = 1,
    Size size = const Size(400, 1400),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<TimetableBloc>.value(
          value: bloc,
          child: TimetableView(week: week, today: today ?? monday),
        ),
      ),
      textScale: textScale,
      size: size,
    );
  }

  testWidgets('shows a card for each day from Monday to Saturday, with its number of periods', (tester) async {
    await pump(tester, const ListLoaded<TimetableEntry>([mathsMonday, lunchMonday, scienceTuesday]));
    for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']) {
      expect(find.text(day), findsOneWidget);
    }
    expect(find.text('Sunday'), findsNothing);
    // The lunch break is not a period.
    expect(find.text('1 period'), findsNWidgets(2));
    expect(find.text('No periods'), findsNWidgets(4));
  });

  testWidgets("opens today's day first, and opens and closes the others on a tap", (tester) async {
    await pump(tester, const ListLoaded<TimetableEntry>([mathsMonday, scienceTuesday]));
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Science'), findsNothing);
    await tester.tap(find.text('Tuesday'));
    await tester.pump();
    expect(find.text('Science'), findsOneWidget);
    await tester.tap(find.text('Monday'));
    await tester.pump();
    expect(find.text('Mathematics'), findsNothing);
  });

  testWidgets('opens the day it is in IST, whatever zone the device is in', (tester) async {
    // 20:00 UTC on Sunday 15 November is 01:30 IST on Monday the 16th.
    await pump(tester, const ListLoaded<TimetableEntry>([mathsMonday]), today: DateTime.utc(2026, 11, 15, 20));
    expect(find.text('Mathematics'), findsOneWidget);
  });

  testWidgets('opens no day on a Sunday', (tester) async {
    await pump(tester, const ListLoaded<TimetableEntry>([mathsMonday]), today: sunday);
    expect(find.text('Mathematics'), findsNothing);
  });

  testWidgets("says who teaches a lesson in a section's week, and shows a break by its label", (tester) async {
    await pump(tester, const ListLoaded<TimetableEntry>([mathsMonday, lunchMonday]));
    expect(find.text('Period 1 · 09:00 to 09:45'), findsOneWidget);
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('7th - A'), findsNothing);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Break'), findsOneWidget);
    expect(find.text('Period 4 · 12:00 to 12:30'), findsOneWidget);
  });

  testWidgets("says which section a lesson is in on a teacher's own week", (tester) async {
    await pump(tester, const ListLoaded<TimetableEntry>([mathsMonday]), week: const OwnWeek('i1'));
    expect(find.text('7th - A'), findsOneWidget);
    expect(find.text('Asha Rao'), findsNothing);
  });

  testWidgets('says so when a day has nothing planned', (tester) async {
    await pump(tester, const ListLoaded<TimetableEntry>([scienceTuesday]));
    expect(find.text('Nothing is planned for this day.'), findsOneWidget);
  });

  testWidgets('shows the skeleton while loading', (tester) async {
    await pump(tester, const ListLoading<TimetableEntry>());
    expect(find.byType(SkeletonCards), findsOneWidget);
    expect(find.text('Monday'), findsNothing);
  });

  testWidgets('says so for a week with nothing in it', (tester) async {
    await pump(tester, const ListLoaded<TimetableEntry>([]));
    expect(find.text('No timetable yet'), findsOneWidget);
    expect(find.text('Monday'), findsNothing);
  });

  testWidgets('says why it failed, and reads again on Try again', (tester) async {
    await pump(
      tester,
      const ListFailed<TimetableEntry>(ApiFailure(statusCode: 500, code: 'INTERNAL', message: 'x')),
    );
    expect(find.byKey(const Key('timetable.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const ListRequested())).called(1);
  });

  testWidgets('says plainly when the person may not see this timetable', (tester) async {
    await pump(
      tester,
      const ListFailed<TimetableEntry>(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')),
    );
    expect(find.byKey(const Key('timetable.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('has nothing cut off at 320 px wide and twice the text size, with every day open', (tester) async {
    await pump(
      tester,
      const ListLoaded<TimetableEntry>([mathsMonday, lunchMonday, scienceTuesday]),
      week: const OwnWeek('i1'),
      textScale: 2,
      size: const Size(320, 3200),
    );
    await tester.tap(find.text('Tuesday'));
    await tester.pump();
    expect(find.text('Science'), findsOneWidget);
    // A subject's name is the school's own word, wider than any box inside an open day on this phone.
    expect(clippedParagraphs(tester, unbreakable: 320 - 6 * 16), isEmpty);
  });
}
