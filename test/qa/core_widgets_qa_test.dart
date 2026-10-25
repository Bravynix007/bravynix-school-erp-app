// QA for app PR #2 (core widgets): the gallery at four text sizes on a 320 px
// phone with the bundled font, the attendance selector with Hindi, Tamil and
// Kannada labels, the overlays at large text, and the semantics of fields.
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/gallery/presentation/component_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

const _scales = [1.0, 1.3, 2.0, 3.0];
const _indicFamilies = ['QaDeva', 'QaTamil', 'QaKannada'];

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// Text drawn narrower than it needs on one line, cut by maxLines, or broken
/// mid-word. A word wider than [unbreakable] cannot fit any box on the phone and
/// is left out of the mid-word check.
List<String> _clippedParagraphs(WidgetTester tester, {Finder? within, double unbreakable = double.infinity}) {
  final clipped = <String>[];
  final texts = within == null ? find.byType(RichText) : find.descendant(of: within, matching: find.byType(RichText));
  for (final element in texts.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    if (!paragraph.hasSize) continue;
    final text = paragraph.text.toPlainText();
    if (paragraph.didExceedMaxLines) clipped.add('"$text" exceeds maxLines');
    // Wrapped text squeezed into a box shorter than its lines (a parent that
    // caps the height) loses its last lines without any ellipsis.
    final needed = paragraph.getDryLayout(BoxConstraints(maxWidth: paragraph.size.width)).height;
    if (needed > paragraph.size.height + 0.5) {
      clipped.add(
        '"$text" needs ${needed.toStringAsFixed(1)} px of height but has ${paragraph.size.height.toStringAsFixed(1)}',
      );
    }
    final noWrap = !paragraph.softWrap || paragraph.maxLines == 1;
    if (noWrap && paragraph.getMaxIntrinsicWidth(double.infinity) > paragraph.size.width + 0.5) {
      clipped.add(
        '"$text" is ${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)} wide in ${paragraph.size.width.toStringAsFixed(1)}',
      );
    }
    // A word wider than its box is broken across lines mid-word ("We" / "ek").
    for (final word in text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: paragraph.text.style),
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
      )..layout();
      final wordWidth = painter.width;
      painter.dispose();
      if (wordWidth > paragraph.size.width + 0.5 && wordWidth <= unbreakable) {
        clipped.add(
          '"$word" in "$text" is broken mid-word (${wordWidth.toStringAsFixed(1)} in ${paragraph.size.width.toStringAsFixed(1)})',
        );
      }
    }
  }
  return clipped;
}

/// Scrolls the gallery top to bottom, collecting layout errors and clipped text.
Future<({List<String> errors, Set<String> clipped, Set<String> seen})> _walkGallery(
  WidgetTester tester, {
  double unbreakable = double.infinity,
}) async {
  final errors = <String>[];
  final clipped = <String>{};
  final seen = <String>{};
  void collect() {
    for (Object? e = tester.takeException(); e != null; e = tester.takeException()) {
      errors.add(e.toString().split('\n').first);
    }
    clipped.addAll(_clippedParagraphs(tester, unbreakable: unbreakable));
    for (final element in find.byType(RichText).evaluate()) {
      seen.add((element.renderObject! as RenderParagraph).text.toPlainText());
    }
  }

  collect();
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 200; i++) {
    final position = tester.state<ScrollableState>(list).position;
    if (position.pixels >= position.maxScrollExtent) break;
    await tester.drag(list, const Offset(0, -250));
    await _settle(tester);
    collect();
  }
  return (errors: errors, clipped: clipped, seen: seen);
}

Map<AttendanceMark, AttendanceMarkLabel> _labels(List<(String, String)> pairs) => {
  for (final (i, mark) in AttendanceMark.values.indexed)
    mark: AttendanceMarkLabel(short: pairs[i].$1, full: pairs[i].$2),
};

final Map<AttendanceMark, AttendanceMarkLabel> _hindi = _labels([
  ('उपस्थित', 'उपस्थित'),
  ('अनुपस्थित', 'अनुपस्थित'),
  ('देर से', 'देर से'),
  ('आधा दिन', 'आधा दिन'),
  ('छुट्टी', 'छुट्टी पर'),
]);
final Map<AttendanceMark, AttendanceMarkLabel> _tamil = _labels([
  ('வருகை', 'வருகை'),
  ('வரவில்லை', 'வரவில்லை'),
  ('தாமதம்', 'தாமதம்'),
  ('அரை நாள்', 'அரை நாள்'),
  ('விடுப்பு', 'விடுப்பில்'),
]);
final Map<AttendanceMark, AttendanceMarkLabel> _kannada = _labels([
  ('ಹಾಜರು', 'ಹಾಜರು'),
  ('ಗೈರುಹಾಜರು', 'ಗೈರುಹಾಜರು'),
  ('ತಡ', 'ತಡವಾಗಿ'),
  ('ಅರ್ಧ ದಿನ', 'ಅರ್ಧ ದಿನ'),
  ('ರಜೆ', 'ರಜೆಯಲ್ಲಿ'),
]);
// The short letters a real Hindi build would most likely ship.
final Map<AttendanceMark, AttendanceMarkLabel> _hindiShort = _labels([
  ('उ', 'उपस्थित'),
  ('अ', 'अनुपस्थित'),
  ('दे', 'देर से'),
  ('आधा', 'आधा दिन'),
  ('छु', 'छुट्टी पर'),
]);

/// The gallery has a spinning loading button, so pumpAndSettle never settles.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
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

  group('gallery on a 320 x 640 phone', () {
    final heights = <double, double>{};
    for (final scale in _scales) {
      testWidgets('text scale $scale: no layout errors, no clipped text', (tester) async {
        await tester.pumpAppScaled(const ComponentGalleryPage(), textScale: scale);
        await _settle(tester);
        // The app bar title is capped by Material, so measure a section header.
        heights[scale] = tester.textHeight('Accent');
        // At 3.0 a long word can be wider than any card on a 320 px phone (320 less
        // the screen margins and a card's padding); only those may break.
        final walk = await _walkGallery(tester, unbreakable: scale >= 3 ? 320 - 4 * 16 : double.infinity);
        expect(walk.errors, isEmpty);
        expect(walk.clipped, isEmpty);
        expect(
          walk.seen,
          containsAll(<String>['Save changes', 'Date of birth', 'Present today', 'Open confirm dialog']),
        );
      });
    }
    test('the title really grows with the text scale', () {
      expect(heights[1.3]! / heights[1.0]!, closeTo(1.3, 0.1));
      expect(heights[2.0]! / heights[1.0]!, closeTo(2.0, 0.15));
      expect(heights[3.0]! / heights[1.0]!, closeTo(3.0, 0.2));
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('text scale $scale: tap targets and labels meet the guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpAppScaled(const ComponentGalleryPage(), textScale: scale);
        await _settle(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });

  group('overlays at large text', () {
    for (final scale in [2.0, 3.0]) {
      testWidgets('scale $scale: the sheet and the dialog open without errors and close', (tester) async {
        await tester.pumpAppScaled(const ComponentGalleryPage(), textScale: scale, bottomPadding: 34);
        await _settle(tester);
        // The gallery grows with every widget group; at 300% text it is many screens long.
        await tester.scrollUntilVisible(
          find.text('Open bottom sheet'),
          200,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 400,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await _settle(tester);
        await tester.tap(find.text('Open bottom sheet'));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Add a note'), findsOneWidget);
        expect(_clippedParagraphs(tester, within: find.byType(BottomSheet)), isEmpty);
        // The sheet's Save button sits above the home indicator.
        final save = tester.getRect(find.widgetWithText(FilledButton, 'Save').last);
        expect(save.bottom, lessThanOrEqualTo(640 - 34));
        await tester.tapAt(const Offset(160, 5));
        await _settle(tester);
        expect(find.text('Add a note'), findsNothing);

        await tester.scrollUntilVisible(
          find.text('Open confirm dialog'),
          200,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 400,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await _settle(tester);
        await tester.tap(find.text('Open confirm dialog'));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Delete this class?'), findsOneWidget);
        expect(_clippedParagraphs(tester, within: find.byType(Dialog)), isEmpty);
        await tester.tap(find.text('Cancel').last);
        await _settle(tester);
        expect(find.text('Delete this class?'), findsNothing);
      });
    }
  });

  group('attendance selector with Indic labels', () {
    final cases = {
      'Hindi (long)': _hindi,
      'Tamil (long)': _tamil,
      'Kannada (long)': _kannada,
      'Hindi (short)': _hindiShort,
    };
    for (final MapEntry(key: name, value: labels) in cases.entries) {
      for (final scale in _scales) {
        for (final width in [320.0, 412.0]) {
          testWidgets('$name at scale $scale, width $width: every label whole and tappable', (tester) async {
            final handle = tester.ensureSemantics();
            AttendanceMark? picked;
            await tester.pumpAppScaled(
              Builder(
                builder: (context) {
                  final theme = AppTheme.light();
                  return Theme(
                    data: theme.copyWith(
                      textTheme: theme.textTheme.apply(fontFamilyFallback: _indicFamilies),
                    ),
                    child: Scaffold(
                      body: Padding(
                        padding: const EdgeInsets.all(16),
                        child: StatefulBuilder(
                          builder: (context, setState) => AttendanceStatusSelector(
                            labels: labels,
                            selected: picked,
                            onChanged: (mark) => setState(() => picked = mark),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              textScale: scale,
              size: Size(width, 800),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(_clippedParagraphs(tester), isEmpty);
            for (final mark in AttendanceMark.values) {
              final label = labels[mark]!;
              final text = find.text(label.short);
              expect(text, findsOneWidget);
              final paragraph = tester.renderObject<RenderParagraph>(text);
              // Every label stays on one line: the selector wraps buttons, not letters.
              expect(paragraph.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(paragraph.size.width + 0.5));
              final button = find.bySemanticsLabel(label.full);
              expect(button, findsOneWidget);
              expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
              await tester.tap(button);
              await tester.pumpAndSettle();
              expect(picked, mark);
              expect(
                tester.getSemantics(button),
                matchesSemantics(
                  label: label.full,
                  isButton: true,
                  isSelected: true,
                  hasSelectedState: true,
                  isInMutuallyExclusiveGroup: true,
                  isFocusable: true,
                  hasTapAction: true,
                ),
              );
              // The tick appears and still nothing clips.
              expect(_clippedParagraphs(tester), isEmpty);
              expect(tester.takeException(), isNull);
            }
            handle.dispose();
          });
        }
      }
    }
  });

  group('semantics of fields', () {
    testWidgets('required text field, dropdown and date field speak their label and state', (tester) async {
      final handle = tester.ensureSemantics();
      var tapped = 0;
      await tester.pumpAppScaled(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppTextField(label: 'Student name', required: true, requiredLabel: 'Required'),
              const AppTextField(label: 'Mobile', error: 'Enter a 10-digit number.'),
              AppDropdownField<String>(
                label: 'Class',
                value: '7-B',
                required: true,
                requiredLabel: 'Required',
                items: const [DropdownMenuItem(value: '7-B', child: Text('7-B'))],
                onChanged: (_) {},
              ),
              AppDateField(
                label: 'Date of birth',
                valueText: '12 Mar 2013',
                required: true,
                requiredLabel: 'Required',
                onTap: () => tapped++,
              ),
              const AppDateField(label: 'Leaving date', valueText: '', hint: 'Pick a date', onTap: null),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      String dump(Finder f) {
        final node = tester.getSemantics(f);
        return node.toString().replaceAll('\n', ' / ');
      }

      final dumps = <String, String>{
        for (final label in ['Student name', 'Mobile', 'Class', 'Date of birth', 'Leaving date'])
          label: dump(find.bySemanticsLabel(RegExp('^$label')).last),
      };
      expect(dumps['Student name'], contains('Required'));
      expect(dumps['Class'], contains('Required'));
      expect(dumps['Mobile'], contains('Enter a 10-digit number.'));
      expect(dumps['Date of birth'], allOf(contains('Date of birth'), contains('12 Mar 2013'), contains('Required')));
      expect(dumps['Date of birth'], allOf(contains('isButton'), contains('isFocusable'), contains('tap')));
      expect(dumps['Leaving date'], allOf(contains('Pick a date'), isNot(contains('tap'))));
      await tester.tap(find.byType(AppDateField).first);
      expect(tapped, 1);
      handle.dispose();
    });
  });

  group('keyboard', () {
    setUp(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional);
    tearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);

    Future<void> tabTo(WidgetTester tester, bool Function(FocusNode node) found) async {
      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final node = FocusManager.instance.primaryFocus;
        if (node != null && found(node)) return;
      }
      fail('Tab never reached the target');
    }

    testWidgets('date field: Tab reaches it, Enter and Space open the picker, a screen reader hears focus', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await tester.pumpAppScaled(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AppDateField(label: 'Date of birth', valueText: '12 Mar 2013', onTap: () => opened++),
          ),
        ),
      );
      final field = find.bySemanticsLabel('Date of birth');
      await tabTo(
        tester,
        (_) => tester.getSemantics(field).getSemanticsData().flagsCollection.isFocused == Tristate.isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(opened, 2);
      handle.dispose();
    });

    testWidgets('attendance selector: Tab, Enter and Space mark, and a screen reader hears focus', (tester) async {
      final handle = tester.ensureSemantics();
      AttendanceMark? picked;
      await tester.pumpAppScaled(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => AttendanceStatusSelector(
                labels: _hindiShort,
                selected: picked,
                onChanged: (mark) => setState(() => picked = mark),
              ),
            ),
          ),
        ),
        size: const Size(412, 800),
      );
      final present = find.bySemanticsLabel('उपस्थित');
      final presentRect = tester.getRect(present);
      // Tab until keyboard focus sits on the first button.
      await tabTo(tester, (node) => presentRect.overlaps(node.rect.deflate(1)));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, AttendanceMark.present);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(picked, AttendanceMark.absent);
      // The focused button must be the focused node for TalkBack, VoiceOver and
      // the web's DOM focus, not only for the Flutter focus system.
      final absent = tester.getSemantics(find.bySemanticsLabel('अनुपस्थित')).getSemanticsData();
      expect(
        absent.flagsCollection.isFocused,
        Tristate.isTrue,
        reason: 'keyboard focus is not exposed to assistive tech',
      );
      handle.dispose();
    });
  });
}
