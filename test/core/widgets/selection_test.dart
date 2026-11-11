import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_segmented_control.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/core/widgets/choice_chip_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

String _same(String value) => value;

void _ignore(String _) {}

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
    expect(find.byIcon(Icons.check), findsOneWidget, reason: 'only the chosen chip has a tick');
    expect(
      tester.getSemantics(find.text('Term 1')),
      isSemantics(label: 'Term 1', isSelected: true, isInMutuallyExclusiveGroup: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.text('Term 2')),
      isSemantics(label: 'Term 2', isSelected: false, isInMutuallyExclusiveGroup: true, isButton: true),
    );
    await tester.tap(find.text('Term 2'));
    expect(picked, 'Term 2');
    handle.dispose();
  });

  testWidgets('a chip grows to show every line of a wrapped label at 300% text', (tester) async {
    await tester.pumpAppScaled(
      const Scaffold(
        body: ChoiceChipGroup<String>(
          options: ['BravyNix Teal', 'Forest Green'],
          labelOf: _same,
          selected: 'Forest Green',
          onSelected: _ignore,
        ),
      ),
      textScale: 3,
    );
    expect(tester.takeException(), isNull);
    for (final label in ['BravyNix Teal', 'Forest Green']) {
      final text = tester.renderObject<RenderParagraph>(find.text(label));
      final needed = text.getDryLayout(BoxConstraints(maxWidth: text.size.width)).height;
      expect(text.size.height, greaterThanOrEqualTo(needed - 0.5), reason: '"$label" is not cut off');
      final chip = tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(Material)).first);
      expect(chip.height, greaterThanOrEqualTo(needed), reason: 'the chip is at least as tall as its label');
    }
  });

  testWidgets('the tick is dropped where it would leave no room for the whole word', (tester) async {
    await tester.pumpAppScaled(
      const Scaffold(
        body: ChoiceChipGroup<String>(
          options: ['Documents', 'Settings'],
          labelOf: _same,
          selected: 'Documents',
          onSelected: _ignore,
        ),
      ),
      textScale: 2,
      size: const Size(280, 640),
    );
    expect(find.byIcon(Icons.check), findsNothing);
    final word = tester.renderObject<RenderParagraph>(find.text('Documents'));
    expect(word.size.width, greaterThanOrEqualTo(word.getMinIntrinsicWidth(double.infinity)), reason: 'not broken');
    await tester.pumpAppScaled(
      const Scaffold(
        body: ChoiceChipGroup<String>(
          options: ['Documents', 'Settings'],
          labelOf: _same,
          selected: 'Documents',
          onSelected: _ignore,
        ),
      ),
      size: const Size(280, 640),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  group('ChoiceChipGroup in a row that scrolls', () {
    const labels = ['Personal', 'Access', 'Documents', 'Settings'];
    const edge = 360 - AppSpacing.md;

    /// The chosen chip follows a tap, as it does under a bloc.
    String? selected;

    setUp(() => selected = null);

    Future<void> pump(WidgetTester tester, {String initial = 'Personal', double scale = 1}) => tester.pumpAppScaled(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: StatefulBuilder(
            builder: (context, setState) {
              selected ??= initial;
              return ChoiceChipGroup<String>(
                options: labels,
                labelOf: _same,
                selected: selected,
                onSelected: (label) => setState(() => selected = label),
                scrollable: true,
              );
            },
          ),
        ),
      ),
      textScale: scale,
      size: const Size(360, 640),
    );

    Rect chipOf(WidgetTester tester, String label) =>
        tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first);

    /// Scrolls the row until [label] ends [gap] short of the edge.
    Future<void> endNear(WidgetTester tester, String label, double gap) async {
      final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
      position.jumpTo(position.pixels + chipOf(tester, label).right - (edge - gap));
      await tester.pump();
    }

    testWidgets('keeps every chip on one line and scrolls to the rest, where wrapping would use two', (tester) async {
      await pump(tester);
      expect(find.byType(Wrap), findsNothing);
      final tops = {for (final label in labels) tester.getTopLeft(find.text(label)).dy};
      expect(tops, hasLength(1), reason: 'one row');
      expect(tester.getTopLeft(find.text('Settings')).dx, greaterThan(edge), reason: 'beyond the edge');
      await tester.drag(find.byType(SingleChildScrollView), const Offset(-400, 0));
      await tester.pump();
      expect(tester.getTopLeft(find.text('Settings')).dx, lessThan(edge), reason: 'now in view');
    });

    testWidgets('brings a chip into view that its tick pushes past the edge, and one that is cut off', (tester) async {
      // The tick moves from Settings, to the right of it, so what is left of Documents does not shrink to make room.
      await pump(tester, initial: 'Settings');
      await endNear(tester, 'Documents', 10);
      expect(chipOf(tester, 'Documents').right, lessThan(edge), reason: 'whole before the tick');
      await tester.tapAt(chipOf(tester, 'Documents').topLeft + const Offset(8, 20));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(chipOf(tester, 'Documents').right, closeTo(edge, 0.5), reason: 'with the tick, moved just far enough');
      await endNear(tester, 'Settings', -30);
      expect(chipOf(tester, 'Settings').right, greaterThan(edge), reason: 'cut off at the edge');
      await tester.tapAt(chipOf(tester, 'Settings').topLeft + const Offset(8, 20));
      await tester.pumpAndSettle();
      expect(chipOf(tester, 'Settings').right, closeTo(edge, 0.5));
      expect(chipOf(tester, 'Settings').left, greaterThanOrEqualTo(AppSpacing.md));
    });

    testWidgets('brings a chip that is cut off at the start in from the start', (tester) async {
      await pump(tester, initial: 'Settings');
      await tester.drag(find.byType(SingleChildScrollView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
      position.jumpTo(position.pixels + chipOf(tester, 'Access').left + 4);
      await tester.pump();
      expect(chipOf(tester, 'Access').left, lessThan(AppSpacing.md), reason: 'cut off at the start');
      await tester.tapAt(chipOf(tester, 'Access').topRight - const Offset(8, -20));
      await tester.pumpAndSettle();
      expect(chipOf(tester, 'Access').left, closeTo(AppSpacing.md, 0.5));
    });

    testWidgets('leaves the row where it is when the chip tapped is already whole', (tester) async {
      await pump(tester);
      final before = chipOf(tester, 'Personal').left;
      await tester.tap(find.text('Access'));
      await tester.pumpAndSettle();
      expect(chipOf(tester, 'Personal').left, before, reason: 'Personal is still where it was');
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();
      expect(chipOf(tester, 'Personal').left, before);
    });

    testWidgets('moves at once, with no animation, when the person asked for less motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pump(tester);
      await endNear(tester, 'Settings', -30);
      await tester.tapAt(chipOf(tester, 'Settings').topLeft + const Offset(8, 20));
      await tester.pump();
      await tester.pump();
      expect(chipOf(tester, 'Settings').right, closeTo(edge, 0.5), reason: 'in place a frame after the tap');
    });

    testWidgets('takes its time otherwise', (tester) async {
      await pump(tester);
      await endNear(tester, 'Settings', -30);
      await tester.tapAt(chipOf(tester, 'Settings').topLeft + const Offset(8, 20));
      await tester.pump();
      await tester.pump();
      expect(chipOf(tester, 'Settings').right, greaterThan(edge + 1), reason: 'still on its way');
      await tester.pumpAndSettle();
      expect(chipOf(tester, 'Settings').right, closeTo(edge, 0.5));
    });

    testWidgets('never breaks a word, even at 300% text', (tester) async {
      await pump(tester, initial: 'Documents', scale: 3);
      expect(tester.takeException(), isNull);
      for (final label in labels) {
        final word = tester.renderObject<RenderParagraph>(find.text(label));
        expect(word.size.height, lessThan(word.size.width), reason: '"$label" is on one line');
      }
    });
  });

  testWidgets('one-letter chips (sections, blood groups) are still 48 x 48 touch targets', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(
      const Scaffold(
        body: ChoiceChipGroup<String>(options: ['A', 'B', 'O-'], labelOf: _same, selected: 'A', onSelected: _ignore),
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    final chip = tester.getSize(find.ancestor(of: find.text('B'), matching: find.byType(Material)).first);
    expect(chip.width, greaterThanOrEqualTo(48));
    expect(chip.height, greaterThanOrEqualTo(48));
    handle.dispose();
  });

  testWidgets('keyboard focus draws the 2 px ring around a chip', (tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
    await tester.pumpApp(
      const Scaffold(
        body: ChoiceChipGroup<String>(
          options: ['Term 1', 'Term 2'],
          labelOf: _same,
          selected: 'Term 1',
          onSelected: _ignore,
        ),
      ),
    );
    expect(
      tester
          .widgetList<Material>(find.ancestor(of: find.text('Term 1'), matching: find.byType(Material)))
          .where((m) => m.shape is RoundedRectangleBorder && m.borderOnForeground),
      isEmpty,
      reason: 'the chip hairline sits under the ring',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final rings = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.border is Border && (d.border! as Border).top.color == AppColors.focusRing);
    expect(rings, hasLength(1), reason: 'one chip at a time');
  });

  group('AppSegmentedControl layout', () {
    Future<void> pump(WidgetTester tester, List<String> options, {required double scale, double width = 360}) =>
        tester.pumpAppScaled(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppSegmentedControl<String>(
                options: options,
                labelOf: (v) => v,
                selected: options.first,
                onChanged: (_) {},
              ),
            ),
          ),
          textScale: scale,
          size: Size(width, 640),
        );

    testWidgets('short labels show the tick on the chosen segment', (tester) async {
      await pump(tester, const ['A', 'B', 'C'], scale: 1);
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('when only the words fit the tick is dropped', (tester) async {
      await pump(tester, const ['Day', 'Week', 'Month'], scale: 1);
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('when the words do not fit side by side the options wrap as chips, never breaking a word', (
      tester,
    ) async {
      await pump(tester, const ['Day', 'Week', 'Month'], scale: 2);
      expect(tester.takeException(), isNull);
      expect(find.byType(SegmentedButton<String>), findsNothing);
      expect(find.byType(ChoiceChipGroup<String>), findsOneWidget);
      final month = tester.getRect(find.text('Month'));
      expect(month.height, lessThan(tester.textHeight('Month') + 1), reason: 'one line');
    });

    testWidgets('tapping a chip in the fallback reports the choice', (tester) async {
      String? picked;
      await tester.pumpAppScaled(
        Scaffold(
          body: AppSegmentedControl<String>(
            options: const ['Day', 'Week', 'Month'],
            labelOf: (v) => v,
            selected: 'Day',
            onChanged: (v) => picked = v,
          ),
        ),
        textScale: 2,
      );
      await tester.tap(find.text('Week'));
      expect(picked, 'Week');
    });

    testWidgets('wraps onto more lines where the words do not fit, or scrolls in one row when asked to', (
      tester,
    ) async {
      const options = ['Personal', 'Access', 'Documents', 'Settings'];
      for (final scrollable in [false, true]) {
        await tester.pumpAppScaled(
          Scaffold(
            body: AppSegmentedControl<String>(
              options: options,
              labelOf: (v) => v,
              selected: 'Personal',
              onChanged: (_) {},
              scrollable: scrollable,
            ),
          ),
          size: const Size(360, 640),
        );
        expect(find.byType(SegmentedButton<String>), findsNothing);
        expect(find.byType(Wrap), scrollable ? findsNothing : findsOneWidget);
        expect(find.byType(SingleChildScrollView), scrollable ? findsOneWidget : findsNothing);
      }
      await tester.pumpAppScaled(
        Scaffold(
          body: AppSegmentedControl<String>(
            options: options,
            labelOf: (v) => v,
            selected: 'Personal',
            onChanged: (_) {},
            scrollable: true,
          ),
        ),
        size: const Size(900, 640),
      );
      expect(find.byType(SegmentedButton<String>), findsOneWidget, reason: 'side by side where the words fit');
    });

    testWidgets('keyboard focus marks only the focused segment', (tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      await tester.pumpApp(
        Scaffold(
          body: AppSegmentedControl<String>(
            options: const ['Day', 'Week', 'Month'],
            labelOf: (v) => v,
            selected: 'Day',
            onChanged: (_) {},
          ),
        ),
      );
      TextDecoration? decorationOf(String label) =>
          DefaultTextStyle.of(tester.element(find.text(label))).style.decoration;

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      Future<List<String>> tabAndRead() async {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump(const Duration(seconds: 1));
        return ['Day', 'Week', 'Month'].where((l) => decorationOf(l) == TextDecoration.underline).toList();
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(seconds: 1));
      expect(await tabAndRead(), ['Week'], reason: 'one segment at a time shows the ring, and it follows focus');
      expect(await tabAndRead(), ['Month']);
    });
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
          isFocusable: true,
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
          isFocusable: true,
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
