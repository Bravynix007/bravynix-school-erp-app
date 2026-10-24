import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_segmented_control.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/core/widgets/choice_chip_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/contrast.dart';
import '../../helpers/pump_app.dart';

const _labels = <AttendanceMark, AttendanceMarkLabel>{
  AttendanceMark.present: AttendanceMarkLabel(short: 'P', full: 'Present'),
  AttendanceMark.absent: AttendanceMarkLabel(short: 'A', full: 'Absent'),
  AttendanceMark.late: AttendanceMarkLabel(short: 'L', full: 'Late'),
  AttendanceMark.halfDay: AttendanceMarkLabel(short: 'HD', full: 'Half day'),
  AttendanceMark.leave: AttendanceMarkLabel(short: 'LV', full: 'On leave'),
};

void main() {
  testWidgets('ChoiceChipGroup marks the chosen chip and reports a tap', (tester) async {
    String? picked;
    final handle = tester.ensureSemantics();
    await tester.pumpApp(
      Scaffold(
        body: ChoiceChipGroup<String>(
          options: const ['Term 1', 'Term 2'],
          labelOf: (t) => t,
          selected: 'Term 1',
          onSelected: (t) => picked = t,
        ),
      ),
    );
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Term 1')).selected, isTrue);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Term 2')).selected, isFalse);
    expect(
      tester.getSemantics(find.widgetWithText(ChoiceChip, 'Term 1')),
      isSemantics(label: 'Term 1', isSelected: true, isInMutuallyExclusiveGroup: true),
    );
    await tester.tap(find.text('Term 2'));
    expect(picked, 'Term 2');
    handle.dispose();
  });

  testWidgets('AppSegmentedControl drops the tick at large text so words are not broken', (tester) async {
    Future<void> pump(double scale) => tester.pumpAppScaled(
      Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppSegmentedControl<String>(
          options: const ['Day', 'Week', 'Month'],
          labelOf: (v) => v,
          selected: 'Day',
          onChanged: (_) {},
        ),
      ),
      textScale: scale,
    );
    await pump(1);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await pump(2);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chips take their selected colour from the accent wash, not grey', (tester) async {
    await tester.pumpApp(
      Scaffold(
        body: ChoiceChipGroup<String>(options: const ['A'], labelOf: (t) => t, selected: 'A', onSelected: (_) {}),
      ),
    );
    final scheme = Theme.of(tester.element(find.byType(ChoiceChip))).colorScheme;
    expect(scheme.secondaryContainer, AppAccent.teal.tint);
    expect(scheme.onSecondaryContainer, AppAccent.teal.text);
  });

  testWidgets('AppSegmentedControl reports the tapped segment', (tester) async {
    var view = 'Day';
    await tester.pumpApp(
      Scaffold(
        body: AppSegmentedControl<String>(
          options: const ['Day', 'Week', 'Month'],
          labelOf: (v) => v,
          selected: view,
          onChanged: (v) => view = v,
        ),
      ),
    );
    await tester.tap(find.text('Week'));
    expect(view, 'Week');
  });

  group('AttendanceStatusSelector', () {
    Future<void> pump(WidgetTester tester, AttendanceMark? selected, ValueChanged<AttendanceMark> onChanged) {
      return tester.pumpApp(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AttendanceStatusSelector(labels: _labels, selected: selected, onChanged: onChanged),
          ),
        ),
      );
    }

    testWidgets('shows P A L HD LV and reports the tapped mark', (tester) async {
      AttendanceMark? tapped;
      await pump(tester, null, (m) => tapped = m);
      for (final short in ['P', 'A', 'L', 'HD', 'LV']) {
        expect(find.text(short), findsOneWidget);
      }
      await tester.tap(find.text('HD'));
      expect(tapped, AttendanceMark.halfDay);
    });

    testWidgets('the chosen mark has a tick and speaks as selected; the others do not', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, AttendanceMark.late, (_) {});
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(tester.getSize(find.ancestor(of: find.text('L'), matching: find.byType(InkWell))).height, 48);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Late')),
        matchesSemantics(
          label: 'Late',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Present')),
        matchesSemantics(
          label: 'Present',
          isButton: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('every button is at least 48 px high', (tester) async {
      await pump(tester, null, (_) {});
      for (final short in ['P', 'A', 'L', 'HD', 'LV']) {
        final button = find.ancestor(of: find.text(short), matching: find.byType(InkWell));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(AppSpacing.minTouchTarget), reason: short);
      }
    });

    testWidgets('on a 360 px phone at normal text all five share one row', (tester) async {
      await tester.pumpAppScaled(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AttendanceStatusSelector(labels: _labels, selected: AttendanceMark.halfDay, onChanged: (_) {}),
        ),
        size: const Size(360, 640),
      );
      final tops = {
        for (final s in ['P', 'A', 'L', 'HD', 'LV']) tester.getTopLeft(find.text(s)).dy,
      };
      expect(tops, hasLength(1));
    });

    testWidgets('at 200% text on a 320 px phone the letters are drawn at 200% and the buttons wrap', (tester) async {
      Future<double> heightAt(double scale) async {
        await tester.pumpAppScaled(
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AttendanceStatusSelector(labels: _labels, selected: AttendanceMark.halfDay, onChanged: (_) {}),
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        return tester.textHeight('HD');
      }

      final normal = await heightAt(1);
      final large = await heightAt(2);
      expect(large, greaterThan(normal * 1.9), reason: 'not shrunk back down');
      final tops = {
        for (final s in ['P', 'A', 'L', 'HD', 'LV']) tester.getTopLeft(find.text(s)).dy,
      };
      expect(tops, hasLength(2), reason: 'two rows');
      for (final s in ['P', 'A', 'L', 'HD', 'LV']) {
        final button = find.ancestor(of: find.text(s), matching: find.byType(InkWell));
        expect(tester.getRect(button).right, lessThanOrEqualTo(320 - AppSpacing.md + 0.5), reason: s);
      }
    });

    testWidgets('long labels in other scripts are measured, so they wrap instead of overflowing', (tester) async {
      const hindi = <AttendanceMark, AttendanceMarkLabel>{
        AttendanceMark.present: AttendanceMarkLabel(short: 'उपस्थित', full: 'उपस्थित'),
        AttendanceMark.absent: AttendanceMarkLabel(short: 'अनुपस्थित', full: 'अनुपस्थित'),
        AttendanceMark.late: AttendanceMarkLabel(short: 'देर', full: 'देर से'),
        AttendanceMark.halfDay: AttendanceMarkLabel(short: 'आधा दिन', full: 'आधा दिन'),
        AttendanceMark.leave: AttendanceMarkLabel(short: 'छुट्टी', full: 'छुट्टी'),
      };
      await tester.pumpAppScaled(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AttendanceStatusSelector(labels: hindi, selected: AttendanceMark.halfDay, onChanged: (_) {}),
        ),
        size: const Size(360, 640),
      );
      expect(tester.takeException(), isNull);
      final tops = {for (final mark in hindi.values) tester.getTopLeft(find.text(mark.short)).dy};
      expect(tops.length, greaterThan(1), reason: 'wrapped onto more rows');
    });

    test('white text on every chosen mark passes AA', () {
      for (final mark in AttendanceMark.values) {
        expect(contrast(Colors.white, mark.colour), greaterThanOrEqualTo(4.5), reason: mark.name);
      }
    });

    test('unchosen letters are ink on white', () {
      expect(contrast(AppColors.ink, AppColors.surface), greaterThanOrEqualTo(7));
    });
  });
}
