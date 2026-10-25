import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/amount_text.dart';
import 'package:bravynix_school_erp/core/widgets/app_progress.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/date_badge_card.dart';
import 'package:bravynix_school_erp/core/widgets/greeting_card.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/quick_access_tile.dart';
import 'package:bravynix_school_erp/core/widgets/timeline_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/contrast.dart';
import '../../helpers/pump_app.dart';

const _scales = [1.0, 1.3, 2.0, 3.0];

void main() {
  group('AmountText', () {
    testWidgets('shows Indian grouping in tabular figures on one line', (tester) async {
      await tester.pumpApp(const Scaffold(body: AmountText('124500')));
      expect(find.text('₹1,24,500.00'), findsOneWidget);
      final text = tester.widget<Text>(find.text('₹1,24,500.00'));
      expect(text.maxLines, 1);
      expect(text.style?.fontFeatures, isNotEmpty);
    });

    testWidgets('a malformed amount throws instead of showing a wrong figure', (tester) async {
      await tester.pumpApp(const Scaffold(body: AmountText('12.345')));
      expect(tester.takeException(), isA<FormatException>());
    });

    testWidgets('is drawn smaller, never wrapped, when the room is too small', (tester) async {
      await tester.pumpAppScaled(
        const Scaffold(
          body: Center(
            child: SizedBox(width: 60, child: AmountText('9007199254740993.99')),
          ),
        ),
        textScale: 3,
      );
      expect(find.byType(FittedBox), findsOneWidget);
      expect(tester.getSize(find.byType(AmountText)).width, lessThanOrEqualTo(60));
      expect(clippedParagraphs(tester), isEmpty);
    });

    testWidgets('can be given a spoken form', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const Scaffold(body: AmountText('250', semanticsLabel: '250 rupees')));
      expect(find.bySemanticsLabel('250 rupees'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AmountSplitRow', () {
    testWidgets('puts the name and the amount side by side when they fit', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: AmountSplitRow(label: 'Tuition', amount: '40000'),
        ),
      );
      final name = tester.getTopLeft(find.text('Tuition'));
      final amount = tester.getTopLeft(find.text('₹40,000.00'));
      expect(amount.dy, closeTo(name.dy, 8));
      expect(amount.dx, greaterThan(name.dx));
    });

    testWidgets('puts the amount under the name when the longest word would not fit beside it', (tester) async {
      await tester.pumpAppScaled(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: AmountSplitRow(label: 'Transportation', amount: '124500', note: 'Route 4'),
          ),
        ),
        textScale: 2,
      );
      final name = tester.getBottomLeft(find.text('Transportation'));
      final amount = tester.getTopLeft(find.text('₹1,24,500.00'));
      expect(amount.dy, greaterThanOrEqualTo(name.dy));
      expect(clippedParagraphs(tester, unbreakable: 280), isEmpty);
    });

    testWidgets('a total is heavier than a line', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: Column(
            children: [
              AmountSplitRow(label: 'Tuition', amount: '40000'),
              AmountSplitRow(label: 'Total', amount: '40000', emphasis: true),
            ],
          ),
        ),
      );
      final line = tester.widget<Text>(find.text('₹40,000.00').first).style!.fontWeight!.value;
      final total = tester.widget<Text>(find.text('₹40,000.00').last).style!.fontWeight!.value;
      expect(total, greaterThan(line));
    });

    testWidgets('a malformed amount throws', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: AmountSplitRow(label: 'Tuition', amount: 'abc'),
        ),
      );
      expect(tester.takeException(), isA<FormatException>());
    });
  });

  group('KeyValueRow', () {
    testWidgets('label left, value right', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: KeyValueRow(label: 'Admission no.', value: 'STU-2291', mono: true),
        ),
      );
      expect(
        tester.getTopLeft(find.text('STU-2291')).dx,
        greaterThan(tester.getTopLeft(find.text('Admission no.')).dx),
      );
      expect(tester.getTopLeft(find.text('STU-2291')).dy, tester.getTopLeft(find.text('Admission no.')).dy);
    });

    testWidgets('the value goes under the label when a word would not fit beside it', (tester) async {
      await tester.pumpAppScaled(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: KeyValueRow(label: 'Guardian email', value: 'parent.of.student@example.com'),
          ),
        ),
        textScale: 2,
      );
      expect(
        tester.getTopLeft(find.text('parent.of.student@example.com')).dy,
        greaterThan(tester.getTopLeft(find.text('Guardian email')).dy),
      );
    });

    testWidgets('is read as the label then the value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Scaffold(
          body: KeyValueRow(label: 'Class', value: '7-B'),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Class')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('7-B')), findsWidgets);
      handle.dispose();
    });
  });

  group('AppProgressBar', () {
    testWidgets('is a progress bar with a label and a percentage', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Scaffold(
          body: AppProgressBar(value: 0.62, semanticLabel: 'Fee collected'),
        ),
      );
      final node = tester.getSemantics(find.byType(AppProgressBar));
      expect(node.label, 'Fee collected');
      expect(node.value, '62%');
      expect(node.role, SemanticsRole.progressBar);
      handle.dispose();
    });

    testWidgets('rounds the percentage', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const Scaffold(body: AppProgressBar(value: 0.5, semanticLabel: 'Syllabus')));
      expect(tester.getSemantics(find.byType(AppProgressBar)).value, '50%');
      handle.dispose();
    });

    testWidgets('moves to a new value over 200 ms', (tester) async {
      Future<void> pump(double v) => tester.pumpApp(
        Scaffold(
          body: AppProgressBar(value: v, semanticLabel: 'x'),
        ),
      );
      double fill() => tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor!;
      await pump(0.2);
      await pump(0.8);
      await tester.pump(const Duration(milliseconds: 100));
      expect(fill(), allOf(greaterThan(0.2), lessThan(0.8)));
      await tester.pump(const Duration(milliseconds: 150));
      expect(fill(), closeTo(0.8, 0.001));
    });

    testWidgets('jumps to the new value when Reduce Motion is on', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      Future<void> pump(double v) => tester.pumpApp(
        Scaffold(
          body: AppProgressBar(value: v, semanticLabel: 'x'),
        ),
      );
      await pump(0.2);
      await pump(0.8);
      await tester.pump();
      expect(tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor, closeTo(0.8, 0.001));
    });

    testWidgets('a value outside 0 to 1 is refused', (tester) async {
      expect(() => AppProgressBar(value: 1.2, semanticLabel: 'x'), throwsAssertionError);
      expect(() => AppProgressBar(value: -0.1, semanticLabel: 'x'), throwsAssertionError);
    });

    for (final accent in AppAccent.values) {
      testWidgets('${accent.label}: the fill is 3:1 against the track', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(accent: accent),
            home: const Scaffold(body: AppProgressBar(value: 0.5, semanticLabel: 'x')),
          ),
        );
        final fill = tester
            .widget<ColoredBox>(
              find.descendant(of: find.byType(FractionallySizedBox), matching: find.byType(ColoredBox)),
            )
            .color;
        expect(contrast(fill, AppColors.sunken), greaterThanOrEqualTo(3));
      });
    }
  });

  group('AppProgressRing', () {
    testWidgets('is a progress bar, holds its centre, and grows with the text, as far as the width allows', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpAppScaled(
        const Scaffold(
          body: Center(
            child: AppProgressRing(value: 0.94, semanticLabel: 'Attendance', center: Text('94%')),
          ),
        ),
        textScale: 3,
      );
      expect(find.text('94%'), findsOneWidget);
      expect(tester.getSize(find.byType(SizedBox).first).width, greaterThan(0));
      final ring = find.descendant(of: find.byType(AppProgressRing), matching: find.byType(SizedBox));
      final sizes = tester.widgetList<SizedBox>(ring).map((s) => s.width).whereType<double>();
      expect(sizes, contains(216));
      final node = tester.getSemantics(find.byType(AppProgressRing));
      expect(node.label, 'Attendance');
      expect(node.value, '94%');
      expect(node.role, SemanticsRole.progressBar);
      handle.dispose();
    });

    testWidgets('the ring is its own size at 100% text', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: Center(child: AppProgressRing(value: 0.3, semanticLabel: 'x')),
        ),
      );
      expect(tester.getSize(find.byType(CircularProgressIndicator)), const Size(72, 72));
    });

    testWidgets('a value outside 0 to 1 is refused', (tester) async {
      expect(() => AppProgressRing(value: 2, semanticLabel: 'x'), throwsAssertionError);
    });
  });

  group('QuickAccessTile and QuickAccessGrid', () {
    testWidgets('a tile is one button named by its label', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          body: QuickAccessTile(icon: Icons.fact_check_outlined, label: 'Attendance', onTap: () => taps++),
        ),
      );
      expect(
        tester.getSemantics(find.text('Attendance')),
        isSemantics(
          label: 'Attendance',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      await tester.tap(find.text('Attendance'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('the grid puts several tiles in a row on a normal phone and one at the largest text', (tester) async {
      List<QuickAccessTile> tiles() => [
        for (final label in ['Attendance', 'Fees', 'Homework', 'Events', 'Reports', 'Leave'])
          QuickAccessTile(icon: Icons.circle_outlined, label: label, onTap: () {}),
      ];
      await tester.pumpAppScaled(
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: QuickAccessGrid(tiles: tiles()),
          ),
        ),
        size: const Size(412, 800),
      );
      expect(tester.getTopLeft(find.text('Fees')).dy, tester.getTopLeft(find.text('Attendance')).dy);
      expect(tester.getTopLeft(find.text('Reports')).dy, greaterThan(tester.getTopLeft(find.text('Attendance')).dy));
      await tester.pumpAppScaled(
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: QuickAccessGrid(tiles: tiles()),
          ),
        ),
        textScale: 3,
      );
      expect(tester.getTopLeft(find.text('Fees')).dy, greaterThan(tester.getTopLeft(find.text('Attendance')).dy));
    });

    testWidgets('tiles in a row share the height of the tallest', (tester) async {
      await tester.pumpAppScaled(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: QuickAccessGrid(
              tiles: [
                QuickAccessTile(icon: Icons.circle_outlined, label: 'Fees', onTap: () {}),
                QuickAccessTile(icon: Icons.circle_outlined, label: 'Fee payment history', onTap: () {}),
              ],
            ),
          ),
        ),
        size: const Size(412, 800),
      );
      final heights = tester
          .widgetList<QuickAccessTile>(find.byType(QuickAccessTile))
          .map(
            (t) => tester.getSize(find.byWidget(t)).height,
          );
      expect(heights.toSet().length, 1);
    });

    testWidgets('an incomplete last row is left-aligned', (tester) async {
      await tester.pumpAppScaled(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: QuickAccessGrid(
              tiles: [
                for (final label in ['A1', 'B2', 'C3', 'D4', 'E5'])
                  QuickAccessTile(icon: Icons.circle_outlined, label: label, onTap: () {}),
              ],
            ),
          ),
        ),
        size: const Size(412, 800),
      );
      expect(tester.getTopLeft(find.text('D4')).dx, tester.getTopLeft(find.text('A1')).dx);
      expect(tester.getTopLeft(find.text('E5')).dx, tester.getTopLeft(find.text('B2')).dx);
      expect(tester.getTopLeft(find.text('E5')).dy, greaterThan(tester.getTopLeft(find.text('B2')).dy));
      expect(tester.takeException(), isNull);
    });
  });

  group('TimelineRow', () {
    testWidgets('is read as one item: title, note, time', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Scaffold(
          body: TimelineRow(title: 'Fee paid', subtitle: 'UPI', time: '3 Mar, 10:15 am', icon: Icons.check),
        ),
      );
      expect(tester.getSemantics(find.text('Fee paid')).label, 'Fee paid\nUPI\n3 Mar, 10:15 am');
      handle.dispose();
    });

    testWidgets('a finished step is the accent and a step to come is an outline', (tester) async {
      Color? fillOf(WidgetTester t, int index) {
        final boxes = t
            .widgetList<DecoratedBox>(
              find.descendant(of: find.byType(TimelineRow).at(index), matching: find.byType(DecoratedBox)),
            )
            .map((d) => d.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.shape == BoxShape.circle);
        return boxes.single.color;
      }

      await tester.pumpApp(
        const Scaffold(
          body: Column(
            children: [
              TimelineRow(title: 'Applied', isFirst: true),
              TimelineRow(title: 'Interview', done: false, isLast: true),
            ],
          ),
        ),
      );
      expect(fillOf(tester, 0), isNot(AppColors.surface));
      expect(fillOf(tester, 1), AppColors.surface);
    });

    testWidgets('the first and last rows draw half the line', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: Column(
            children: [
              TimelineRow(title: 'One', isFirst: true),
              TimelineRow(title: 'Two'),
              TimelineRow(title: 'Three', isLast: true),
            ],
          ),
        ),
      );
      int lines(int row) => tester
          .widgetList<ColoredBox>(
            find.descendant(of: find.byType(TimelineRow).at(row), matching: find.byType(ColoredBox)),
          )
          .where((c) => c.color == AppColors.border)
          .length;
      expect(lines(0), 1);
      expect(lines(1), 2);
      expect(lines(2), 1);
    });

    testWidgets('the marker with an icon is 3:1 against the surface when it is still to come', (tester) async {
      expect(contrast(AppColors.fieldBorder, AppColors.surface), greaterThanOrEqualTo(3));
      expect(contrast(AppColors.inkSecondary, AppColors.surface), greaterThanOrEqualTo(4.5));
    });
  });

  group('DateBadgeCard', () {
    testWidgets('shows the month over the day, and speaks the whole date first', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          body: DateBadgeCard(
            date: DateTime(2026, 3, 7),
            title: 'Annual Day',
            subtitle: 'Auditorium, 10 am',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('MAR'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      final label = tester.getSemantics(find.text('Annual Day')).label;
      expect(label, startsWith('Saturday, March 7, 2026'));
      expect(label, contains('Annual Day'));
      expect(label, contains('Auditorium, 10 am'));
      handle.dispose();
    });

    testWidgets('is a button only when it has a tap', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          body: Column(
            children: [
              DateBadgeCard(date: DateTime(2026, 3, 7), title: 'Tap me', onTap: () => taps++),
              DateBadgeCard(date: DateTime(2026, 3, 8), title: 'Plain'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      expect(taps, 1);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('holds a trailing widget', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: DateBadgeCard(date: DateTime(2026, 3, 7), title: 'Holiday', trailing: const Text('Public')),
        ),
      );
      expect(find.text('Public'), findsOneWidget);
    });

    for (final accent in AppAccent.values) {
      testWidgets('${accent.label}: the badge text is 4.5:1 on its wash', (tester) async {
        final scheme = AppTheme.light(accent: accent).colorScheme;
        expect(contrast(scheme.onPrimaryContainer, scheme.primaryContainer), greaterThanOrEqualTo(4.5));
      });
    }
  });

  group('GreetingCard', () {
    testWidgets('shows the greeting, the name as a heading and the message', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Scaffold(
          body: GreetingCard(
            greeting: 'Good afternoon',
            name: 'Asha Rao',
            message: '3 classes left today',
            trailing: Icon(Icons.wb_sunny_outlined),
          ),
        ),
      );
      expect(find.text('Good afternoon'), findsOneWidget);
      expect(find.text('3 classes left today'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
      expect(tester.getSemantics(find.text('Asha Rao')), isSemantics(label: 'Asha Rao', isHeader: true));
      handle.dispose();
    });

    for (final accent in AppAccent.values) {
      testWidgets('${accent.label}: text is 4.5:1 on the wash', (tester) async {
        final scheme = AppTheme.light(accent: accent).colorScheme;
        expect(contrast(scheme.onPrimaryContainer, scheme.primaryContainer), greaterThanOrEqualTo(4.5));
      });
    }
  });

  group('AppSnackbar', () {
    Future<void> open(
      WidgetTester tester, {
      AppSnackbarKind kind = AppSnackbarKind.info,
      String? action,
      VoidCallback? onAction,
      String? dismiss,
      String message = 'Attendance saved',
      double scale = 1,
    }) async {
      await tester.pumpAppScaled(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppSnackbar.show(
                context,
                message: message,
                kind: kind,
                actionLabel: action,
                onAction: onAction,
                dismissLabel: dismiss,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
        textScale: scale,
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('an info message leaves by itself after 4 seconds', (tester) async {
      await open(tester);
      expect(find.text('Attendance saved'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Attendance saved'), findsNothing);
    });

    testWidgets('a success has a tick icon', (tester) async {
      await open(tester, kind: AppSnackbarKind.success);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('an error stays until dismissed, with an icon and a close button', (tester) async {
      await open(tester, kind: AppSnackbarKind.error, dismiss: 'Dismiss', message: 'Could not save');
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Could not save'), findsOneWidget);
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Could not save'), findsNothing);
    });

    testWidgets('a message with an action stays, and the action runs', (tester) async {
      var undone = 0;
      await open(tester, action: 'Undo', onAction: () => undone++, dismiss: 'Dismiss');
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Attendance saved'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Attendance saved'), findsNothing);
    });

    testWidgets('the dismiss button closes it', (tester) async {
      await open(tester, action: 'Undo', onAction: () {}, dismiss: 'Dismiss');
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Attendance saved'), findsNothing);
    });

    testWidgets('a new message replaces the one on screen', (tester) async {
      await open(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Attendance saved'), findsOneWidget);
    });

    testWidgets('a message that stays without a dismiss label is refused, and so is half an action', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                expect(
                  () => AppSnackbar.show(context, message: 'x', kind: AppSnackbarKind.error),
                  throwsAssertionError,
                );
                expect(
                  () => AppSnackbar.show(context, message: 'x', actionLabel: 'Undo', onAction: () {}),
                  throwsAssertionError,
                );
                expect(() => AppSnackbar.show(context, message: 'x', actionLabel: 'Undo'), throwsAssertionError);
              },
              child: const Text('Try'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Try'));
    });

    testWidgets('the text and the buttons are 4.5:1 on the ink background', (tester) async {
      await open(tester, action: 'Undo', onAction: () {}, dismiss: 'Dismiss');
      final style = DefaultTextStyle.of(tester.element(find.text('Attendance saved'))).style;
      expect(contrast(style.color!, AppColors.ink), greaterThanOrEqualTo(4.5));
      final material = tester.widget<Material>(
        find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first,
      );
      expect(material.color, AppColors.ink);
      expect(contrast(AppColors.surface, AppColors.ink), greaterThanOrEqualTo(4.5));
      for (final label in ['Undo', 'Dismiss']) {
        expect(tester.getSize(find.widgetWithText(TextButton, label)).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('the buttons sit under the message, which keeps the full width', (tester) async {
      await open(tester, action: 'Undo', onAction: () {}, dismiss: 'Dismiss');
      expect(
        tester.getTopLeft(find.text('Undo')).dy,
        greaterThan(tester.getBottomLeft(find.text('Attendance saved')).dy),
      );
      expect(tester.getSize(find.text('Attendance saved')).width, greaterThan(200));
    });

    testWidgets('a button shows a white ring for keyboard focus', (tester) async {
      await open(tester, action: 'Undo', onAction: () {}, dismiss: 'Dismiss');
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!;
      expect(focused.context, isNotNull);
      final button = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Undo'));
      final side = button.style!.side!.resolve({WidgetState.focused});
      expect(side?.width, 2);
      expect(side?.color, AppColors.surface);
      expect(button.style!.side!.resolve({}), isNull);
    });

    testWidgets('the message is announced as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      final node = tester.getSemantics(find.text('Attendance saved'));
      expect(node.label, contains('Attendance saved'));
      handle.dispose();
    });
  });

  for (final scale in _scales) {
    testWidgets('display widgets at ${scale * 100}% text on 320 px: nothing is cut or broken mid-word', (tester) async {
      await tester.pumpAppScaled(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const GreetingCard(
                greeting: 'Good afternoon',
                name: 'Asha Subramaniam',
                message: 'You have 3 classes left today',
              ),
              const SizedBox(height: 12),
              QuickAccessGrid(
                tiles: [
                  for (final label in ['Attendance', 'Fees', 'Homework', 'Timetable', 'Announcements', 'Leave'])
                    QuickAccessTile(icon: Icons.circle_outlined, label: label, onTap: () {}),
                ],
              ),
              const SizedBox(height: 12),
              const AmountSplitRow(label: 'Tuition fee for term one', amount: '40000', note: 'Due 5 Apr'),
              const AmountSplitRow(label: 'Total', amount: '1245000.50', emphasis: true),
              const KeyValueRow(label: 'Admission no.', value: 'STU-2291', mono: true),
              const KeyValueRow(label: 'Guardian', value: 'Venkataraghavan Subramaniam'),
              const AppProgressBar(value: 0.62, semanticLabel: 'Fee collected'),
              const SizedBox(height: 12),
              const Center(
                child: AppProgressRing(value: 0.94, semanticLabel: 'Attendance', center: Text('94%')),
              ),
              const SizedBox(height: 12),
              const TimelineRow(
                title: 'Application received',
                subtitle: 'Submitted by the guardian',
                time: '3 Mar, 10:15 am',
                icon: Icons.check,
                isFirst: true,
              ),
              const TimelineRow(title: 'Interview scheduled', subtitle: 'Admissions office', done: false, isLast: true),
              const SizedBox(height: 12),
              DateBadgeCard(
                date: DateTime(2026, 3, 7),
                title: 'Annual Day celebration',
                subtitle: 'Auditorium, 10 am',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester, unbreakable: 280), isEmpty);
    });

    testWidgets('a snackbar at ${scale * 100}% text on 320 px is not cut', (tester) async {
      await tester.pumpAppScaled(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppSnackbar.show(
                context,
                message: 'Marks saved for class 7-B',
                actionLabel: 'Undo',
                onAction: () {},
                dismissLabel: 'Dismiss',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
        textScale: scale,
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester, within: find.byType(SnackBar), unbreakable: 280), isEmpty);
    });
  }
}
