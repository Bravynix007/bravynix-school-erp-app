// QA for app PR 5 (display widgets): money edge cases, what a screen reader
// gets (progress value, the date badge, key-value rows), the bundled font with
// long Indian names and Hindi, Tamil and Kannada at 200% and 300% on a 320 px
// phone, right-to-left, Reduce Motion, and the snackbar by keyboard.
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:bravynix_school_erp/core/format/money.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/amount_text.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_progress.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/date_badge_card.dart';
import 'package:bravynix_school_erp/core/widgets/greeting_card.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/quick_access_tile.dart';
import 'package:bravynix_school_erp/core/widgets/timeline_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clipped_text.dart';
import '../helpers/pump_app.dart';

const _indic = ['QaDeva', 'QaTamil', 'QaKannada'];

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(Future.value(ByteData.view(File(path).readAsBytesSync().buffer)));
  }
  await loader.load();
}

Widget _withIndicFallback(Widget child) => Builder(
  builder: (context) {
    final theme = AppTheme.light();
    return Theme(
      data: theme.copyWith(textTheme: theme.textTheme.apply(fontFamilyFallback: _indic)),
      child: child,
    );
  },
);

/// The text drawn smaller than the phone's text size, as "text: effective scale".
Map<String, double> _shrunk(WidgetTester tester) {
  final out = <String, double>{};
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    if (!paragraph.attached || !paragraph.hasSize) continue;
    if (element.findAncestorWidgetOfExactType<Icon>() != null) continue;
    var scale = paragraph.textScaler.scale(100) / 100;
    // A FittedBox above the text draws it smaller still.
    element.visitAncestorElements((a) {
      final box = a.renderObject;
      if (a.widget is FittedBox && box is RenderBox && box.hasSize && paragraph.size.width > 0) {
        final drawn = box.size.width / paragraph.size.width;
        if (drawn < 1) scale *= drawn;
        return false;
      }
      return true;
    });
    out[paragraph.text.toPlainText()] = scale;
  }
  return out;
}

class _Screen extends StatelessWidget {
  const new({required this.indic});

  final bool indic;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GreetingCard(
          greeting: indic ? 'शुभ दोपहर' : 'Good afternoon',
          name: indic ? 'ಲಕ್ಷ್ಮೀನಾರಾಯಣ ವೆಂಕಟರಮಣನ್' : 'Lakshminarayanan Venkataramanan',
          message: indic ? 'இன்று மூன்று வகுப்புகள் மீதமுள்ளன' : '3 classes left today',
        ),
        const SizedBox(height: 12),
        QuickAccessGrid(
          tiles: [
            QuickAccessTile(icon: Icons.fact_check_outlined, label: indic ? 'उपस्थिति' : 'Attendance', onTap: () {}),
            QuickAccessTile(icon: Icons.payments_outlined, label: indic ? 'ಶುಲ್ಕ' : 'Fees', onTap: () {}),
            QuickAccessTile(icon: Icons.menu_book_outlined, label: indic ? 'வீட்டுப்பாடம்' : 'Homework', onTap: () {}),
          ],
        ),
        AmountSplitRow(
          label: indic ? 'शिक्षण शुल्क' : 'Tuition fee',
          amount: '40000',
          note: indic ? 'ಏಪ್ರಿಲ್ 5' : 'Due 5 Apr',
        ),
        AmountSplitRow(label: indic ? 'போக்குவரத்து' : 'Transport', amount: '-250.00'),
        AmountSplitRow(label: indic ? 'कुल' : 'Total', amount: '1234567.50', emphasis: true),
        AppProgressBar(value: 0.62, semanticLabel: indic ? 'शुल्क जमा' : 'Fee collected'),
        KeyValueRow(label: indic ? 'प्रवेश संख्या' : 'Admission no.', value: 'STU-2291', mono: true),
        const KeyValueRow(label: 'Email', value: 'lakshmi.venkat@example.test'),
        const AppProgressRing(value: 0.94, semanticLabel: 'Attendance', center: Text('94%')),
        TimelineRow(
          title: indic ? 'ಅರ್ಜಿ ಸ್ವೀಕರಿಸಲಾಗಿದೆ' : 'Application received',
          subtitle: indic ? 'அபிபாவகர் சமர்ப்பித்தார்' : 'Submitted by the guardian',
          time: '3 Mar, 10:15 am',
          isFirst: true,
        ),
        DateBadgeCard(
          date: DateTime(2026, 3, 7),
          title: indic ? 'वार्षिकोत्सव' : 'Annual Day',
          subtitle: indic ? 'ಸಭಾಂಗಣ, ಬೆಳಿಗ್ಗೆ 10' : 'Auditorium, 10 am',
          onTap: () {},
        ),
      ],
    ),
  );
}

void main() {
  setUpAll(() async {
    await _loadFont(AppTextStyles.family, [
      for (final w in [400, 500, 600, 700]) 'assets/fonts/plus_jakarta_sans/PlusJakartaSans-$w.ttf',
    ]);
    const noto = 'test/fixtures/fonts/noto';
    await _loadFont('QaDeva', ['$noto/NotoSans-devanagari.ttf']);
    await _loadFont('QaTamil', ['$noto/NotoSans-tamil.ttf']);
    await _loadFont('QaKannada', ['$noto/NotoSans-kannada.ttf']);
  });

  group('money edge cases', () {
    final cases = {
      '0': '₹0.00',
      '-0.00': '₹0.00',
      '007.5': '₹7.50',
      '  250 ': '₹250.00',
      '-250': '-₹250.00',
      '999': '₹999.00',
      '1000': '₹1,000.00',
      '100000': '₹1,00,000.00',
      '9999999.99': '₹99,99,999.99',
      '12345678901.50': '₹12,34,56,78,901.50',
      '123456789012345678901234567890.01': '₹1,23,45,67,89,01,23,45,67,89,01,23,45,67,890.01',
    };
    for (final MapEntry(key: input, value: expected) in cases.entries) {
      test('"$input" is $expected', () => expect(formatRupees(input), expected));
    }
    for (final bad in ['', '-', '.5', '5.', '1,250', '12.345', '1e5', '+5', '--5', 'NaN', '₹250', '٢٥٠', '२५०']) {
      test('"$bad" is refused', () => expect(() => formatRupees(bad), throwsFormatException));
    }
  });

  testWidgets('screen reader: progress has a numeric value, the date card says the whole date, rows read whole', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppScaled(const _Screen(indic: false), size: const Size(390, 2400));
    final nodes = tester.semantics.simulatedAccessibilityTraversal().map((n) => n.getSemanticsData()).toList();
    final spoken = [
      for (final d in nodes)
        if (d.label.isNotEmpty || d.value.isNotEmpty)
          [
            d.label.replaceAll('\n', ' / '),
            if (d.value.isNotEmpty) 'value ${d.value}',
            if (d.flagsCollection.isButton) 'button',
            if (d.flagsCollection.isHeader) 'heading',
          ].join(', '),
    ];
    // The spoken order goes into the run log for the report.
    // ignore: avoid_print
    print(spoken.join('\n'));
    expect(spoken, contains('Fee collected, value 62%'));
    expect(spoken, contains('Attendance, value 94%'));
    expect(spoken.where((s) => s.startsWith('Saturday, March 7, 2026') || s.contains('7 March 2026')), hasLength(1));
    expect(spoken, contains('Admission no. / STU-2291'), reason: 'label and value read as one item');
    expect(spoken, contains('Email / lakshmi.venkat@example.test'), reason: 'label and value read as one item');
    handle.dispose();
  });

  testWidgets('screen reader: the tappable date card is one named button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppScaled(const _Screen(indic: false), size: const Size(390, 2400));
    final nodes = tester.semantics.simulatedAccessibilityTraversal().map((n) => n.getSemanticsData()).toList();
    final nameless = nodes.where((d) => d.flagsCollection.isButton && d.label.isEmpty);
    expect(nameless, isEmpty, reason: 'a button with no name');
    final card = nodes.singleWhere((d) => d.label.contains('Annual Day'));
    expect(card.flagsCollection.isButton, isTrue, reason: '"${card.label}" should be the button');
    expect(card.hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('screen reader: in a list, the greeting heading is the name alone', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppScaled(const _Screen(indic: false), size: const Size(390, 2400));
    final headings = tester.semantics
        .simulatedAccessibilityTraversal()
        .map((n) => n.getSemanticsData())
        .where((d) => d.flagsCollection.isHeader)
        .map((d) => d.label.replaceAll('\n', ' / '));
    expect(headings, ['Lakshminarayanan Venkataramanan']);
    handle.dispose();
  });

  testWidgets('screen reader: a progress bar inside a card is its own node, named only by its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppScaled(
      Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AmountSplitRow(label: 'Tuition fee', amount: '40000', note: 'Due 5 Apr'),
                  AmountSplitRow(label: 'Transport', amount: '6500.5'),
                  Divider(),
                  AmountSplitRow(label: 'Total', amount: '46500.50', emphasis: true),
                  SizedBox(height: 8),
                  AppProgressBar(value: 0.62, semanticLabel: 'Fee collected'),
                  KeyValueRow(label: 'Class', value: '7-B'),
                ],
              ),
            ),
            Center(
              child: AppProgressRing(value: 0.94, semanticLabel: 'Attendance', center: Text('94%')),
            ),
          ],
        ),
      ),
    );
    final progress = tester.semantics
        .simulatedAccessibilityTraversal()
        .map((n) => n.getSemanticsData())
        .where((d) => d.role == SemanticsRole.progressBar)
        .map((d) => '${d.label.replaceAll('\n', ' / ')}: ${d.value}')
        .toList();
    expect(progress, ['Fee collected: 62%', 'Attendance: 94%']);
    handle.dispose();
  });

  testWidgets("Flutter's own check: every tappable node has a name", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppScaled(const _Screen(indic: false), size: const Size(390, 2400));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  for (final scale in [1.0, 2.0, 3.0]) {
    for (final indic in [false, true]) {
      final what = indic ? 'Hindi, Tamil and Kannada' : 'English with long names';
      testWidgets('$what at ${scale * 100}% on 320 px: nothing cut, broken mid-word, or shrunk below normal size', (
        tester,
      ) async {
        await tester.pumpAppScaled(_withIndicFallback(_Screen(indic: indic)), textScale: scale);
        final problems = <String>{};
        final list = find.byType(Scrollable).first;
        for (var i = 0; i < 60; i++) {
          final error = tester.takeException();
          if (error != null) problems.add('$error');
          problems.addAll(clippedParagraphs(tester, within: find.byType(_Screen)));
          for (final MapEntry(key: text, value: drawn) in _shrunk(tester).entries) {
            if (drawn < (scale * 0.66).clamp(0, 1)) problems.add('"$text" drawn at ${drawn.toStringAsFixed(2)}x');
          }
          final position = tester.state<ScrollableState>(list).position;
          if (position.pixels >= position.maxScrollExtent) break;
          await tester.drag(list, const Offset(0, -250));
          await tester.pump();
        }
        expect(problems, isEmpty);
      });
    }
  }

  for (final crossAxis in [CrossAxisAlignment.center, CrossAxisAlignment.start]) {
    testWidgets('a progress bar in a Column (${crossAxis.name}) keeps a full-width track behind a 25% fill', (
      tester,
    ) async {
      await tester.pumpAppScaled(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: crossAxis,
              children: const [
                Text('Fee collected'),
                AppProgressBar(value: 0.25, semanticLabel: 'Fee collected'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final track = tester.getRect(find.byType(AppProgressBar));
      final fill = tester.getRect(find.byType(FractionallySizedBox));
      expect(track.width, moreOrLessEquals(288, epsilon: 0.5), reason: 'track $track');
      expect(fill.width / track.width, moreOrLessEquals(0.25, epsilon: 0.01), reason: 'fill $fill, track $track');
    });
  }

  testWidgets('right-to-left: the progress fill starts at the right edge and amounts sit at the left', (tester) async {
    await tester.pumpAppScaled(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppProgressBar(value: 0.25, semanticLabel: 'Fee collected'),
                AmountSplitRow(label: 'Tuition fee', amount: '40000'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final track = tester.getRect(find.byType(AppProgressBar));
    final fill = tester.getRect(find.byType(FractionallySizedBox));
    expect(fill.right, moreOrLessEquals(track.right, epsilon: 0.5), reason: 'fill $fill, track $track');
    expect(fill.width, moreOrLessEquals(track.width * 0.25, epsilon: 1));
    final amount = tester.getRect(find.text('₹40,000.00'));
    final label = tester.getRect(find.text('Tuition fee'));
    expect(amount.center.dx, lessThan(label.center.dx));
  });

  testWidgets('Reduce Motion set while the screen is open: the next change lands at once', (tester) async {
    var value = 0.2;
    late StateSetter set;
    await tester.pumpAppScaled(
      StatefulBuilder(
        builder: (context, setState) {
          set = setState;
          return Scaffold(
            body: SizedBox(
              width: 300,
              child: AppProgressBar(value: value, semanticLabel: 'Fee collected'),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    set(() => value = 0.8);
    await tester.pump();
    final track = tester.getRect(find.byType(AppProgressBar));
    final fill = tester.getRect(find.byType(FractionallySizedBox));
    expect(fill.width / track.width, moreOrLessEquals(0.8, epsilon: 0.01));
  });

  testWidgets('snackbar by keyboard: Tab reaches Retry and Dismiss, each with a ring, and Enter works', (tester) async {
    var retried = 0;
    await tester.pumpAppScaled(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => AppSnackbar.show(
                context,
                message: 'Could not save. Try again.',
                kind: AppSnackbarKind.error,
                actionLabel: 'Retry',
                onAction: () => retried++,
                dismissLabel: 'Dismiss',
              ),
              child: const Text('Save'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final reached = <String>[];
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final ctx = FocusManager.instance.primaryFocus?.context;
      final text = ctx == null ? null : find.descendant(of: find.byWidget(ctx.widget), matching: find.byType(Text));
      final label = text == null || text.evaluate().isEmpty ? '?' : (text.evaluate().first.widget as Text).data;
      reached.add(label ?? '?');
    }
    expect(reached, containsAll(['Retry', 'Dismiss']));
    // Nothing timed it out while we tabbed.
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Could not save. Try again.'), findsOneWidget);
    // Tab on until Retry has focus, then press Enter.
    String? focused() {
      final ctx = FocusManager.instance.primaryFocus?.context;
      if (ctx == null) return null;
      final text = find.descendant(of: find.byWidget(ctx.widget), matching: find.byType(Text)).evaluate();
      return text.isEmpty ? null : (text.first.widget as Text).data;
    }

    for (var i = 0; i < 6 && focused() != 'Retry'; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(focused(), 'Retry');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(retried, 1);
    expect(find.text('Could not save. Try again.'), findsNothing);
  });

  testWidgets('a disabled-looking state is not claimed: progress and tiles are enabled or have no state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppScaled(const _Screen(indic: false), size: const Size(390, 2400));
    final disabled = tester.semantics
        .simulatedAccessibilityTraversal()
        .map((n) => n.getSemanticsData())
        .where((d) => d.flagsCollection.isEnabled == Tristate.isFalse)
        .map((d) => d.label)
        .toList();
    expect(disabled, isEmpty);
    handle.dispose();
  });

  snackbarEscapeTests();
}

/// A page with a Save button that shows an error snackbar that stays, plus a
/// dialog and a sheet to open, inside the app's [SnackbarEscape].
class _SnackbarPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => SnackbarEscape(
    child: Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            ElevatedButton(
              onPressed: () => AppSnackbar.show(
                context,
                message: 'Could not save. Try again.',
                kind: AppSnackbarKind.error,
                actionLabel: 'Retry',
                onAction: () {},
                dismissLabel: 'Dismiss',
              ),
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(content: Text('A dialog')),
              ),
              child: const Text('Open dialog'),
            ),
            ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const SizedBox(height: 200, child: Center(child: Text('A sheet'))),
              ),
              child: const Text('Open sheet'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _focusAndPress(WidgetTester tester, String label) async {
  Focus.of(tester.element(find.text(label))).requestFocus();
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

void snackbarEscapeTests() {
  for (final (open, shown) in [('Open dialog', 'A dialog'), ('Open sheet', 'A sheet')]) {
    testWidgets('Escape with a snackbar on screen and "$shown" open closes only the $shown', (tester) async {
      await tester.pumpAppScaled(const _SnackbarPage(), size: const Size(390, 844));
      await _focusAndPress(tester, 'Save');
      await _focusAndPress(tester, open);
      expect(find.text(shown), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(shown), findsNothing, reason: 'Escape closes the $shown first');
      expect(find.text('Could not save. Try again.'), findsOneWidget, reason: 'the snackbar is still there');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Could not save. Try again.'), findsNothing, reason: 'a second Escape closes the snackbar');
    });
  }

  testWidgets('Escape while Retry has focus closes the snackbar and focus goes back to Save', (tester) async {
    await tester.pumpAppScaled(const _SnackbarPage(), size: const Size(390, 844));
    await _focusAndPress(tester, 'Save');
    Focus.of(tester.element(find.text('Retry'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Could not save. Try again.'), findsNothing);
    expect(Focus.of(tester.element(find.text('Save'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      Focus.of(tester.element(find.text('Open dialog'))).hasPrimaryFocus,
      isTrue,
      reason: 'Tab carries on from Save',
    );
  });

  testWidgets('screen reader: a step still to come says its status after the title', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppScaled(
      Scaffold(
        body: ListView(
          children: const [
            TimelineRow(title: 'Application received', time: '3 Mar', isFirst: true),
            TimelineRow(title: 'Interview scheduled', subtitle: 'Admissions office', done: false, statusLabel: 'Next'),
            TimelineRow(title: 'Decision', done: false, statusLabel: 'Waiting', isLast: true),
          ],
        ),
      ),
    );
    final spoken = tester.semantics
        .simulatedAccessibilityTraversal()
        .map((n) => n.getSemanticsData().label.replaceAll('\n', ' / '))
        .where((l) => l.isNotEmpty)
        .toList();
    expect(spoken, [
      'Application received / 3 Mar',
      'Interview scheduled / Next / Admissions office',
      'Decision / Waiting',
    ]);
    handle.dispose();
  });
}
