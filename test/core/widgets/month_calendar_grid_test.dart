import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/widgets/month_calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

void main() {
  CalendarCell cell(int day) => CalendarCell(
    semanticLabel: 'day $day',
    fill: day == 2 ? AppColors.absent : null,
    onFill: Colors.white,
    mark: day == 2 ? 'A' : null,
    muted: day == 1,
  );

  Future<List<int>> pump(WidgetTester tester, {DateTime? month, double textScale = 1}) async {
    final tapped = <int>[];
    await tester.pumpAppScaled(
      Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MonthCalendarGrid(month: month ?? DateTime(2026, 11, 20), cellOf: cell, onDay: tapped.add),
          ),
        ),
      ),
      textScale: textScale,
    );
    return tapped;
  }

  testWidgets('draws every day of the month once, and none outside it', (tester) async {
    await pump(tester);
    for (var day = 1; day <= 30; day++) {
      expect(find.byKey(ValueKey('calendar.day.$day')), findsOneWidget, reason: 'day $day');
    }
    expect(find.byKey(const ValueKey('calendar.day.31')), findsNothing);
    expect(find.byKey(const ValueKey('calendar.day.0')), findsNothing);
  });

  testWidgets('starts the week on Monday: a month that begins on a Sunday has its 1st in the last column', (
    tester,
  ) async {
    await pump(tester);
    final first = tester.getTopLeft(find.byKey(const ValueKey('calendar.day.1')));
    final second = tester.getTopLeft(find.byKey(const ValueKey('calendar.day.2')));
    // The 1st ends the first row and the 2nd begins the next, at the left edge.
    expect(second.dx, lessThan(first.dx));
    expect(second.dy, greaterThan(first.dy));
    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('a month that begins on a Monday starts at the left of its first row', (tester) async {
    // June 2026 begins on a Monday.
    await pump(tester, month: DateTime(2026, 6));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('calendar.day.1'))).dy,
      tester.getTopLeft(find.byKey(const ValueKey('calendar.day.7'))).dy,
    );
    expect(find.byKey(const ValueKey('calendar.day.30')), findsOneWidget);
  });

  testWidgets('shows the letters under a marked day, and answers the day tapped', (tester) async {
    final tapped = await pump(tester);
    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar.day.2')));
    await tester.tap(find.byKey(const ValueKey('calendar.day.17')));
    expect(tapped, [2, 17]);
  });

  testWidgets('says each day to a screen reader as a button, and not the week letters', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(tester.getSemantics(find.bySemanticsLabel('day 2')).flagsCollection.isButton, isTrue);
    expect(find.bySemanticsLabel('M'), findsNothing);
    handle.dispose();
  });

  testWidgets('every day is a 48 px target at least', (tester) async {
    await pump(tester);
    for (var day = 1; day <= 30; day++) {
      final size = tester.getSize(find.byKey(ValueKey('calendar.day.$day')));
      expect(size.height, greaterThanOrEqualTo(48), reason: 'day $day');
    }
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    for (final scale in [1.0, 2.0, 3.0]) {
      await pump(tester, textScale: scale);
      expect(tester.takeException(), isNull, reason: 'scale $scale');
      expect(clippedParagraphs(tester), isEmpty, reason: 'scale $scale');
    }
  });

  testWidgets('a legend names each colour, with a border round one that has none', (tester) async {
    await tester.pumpAppScaled(
      const Scaffold(
        body: CalendarLegend(
          entries: [
            CalendarLegendEntry(label: 'Absent: 1 day', fill: AppColors.absent),
            CalendarLegendEntry(label: 'Not marked: 2 days', fill: null),
          ],
        ),
      ),
    );
    expect(find.text('Absent: 1 day'), findsOneWidget);
    expect(find.text('Not marked: 2 days'), findsOneWidget);
  });
}
