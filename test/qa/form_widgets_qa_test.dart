// QA for app PR 4 (form and selection widgets): what a screen reader gets for
// each row (one node, its state, its words), keyboard use (one stop per row,
// Space and Enter), the bundled font and Indic labels at 300% on a 320 px
// phone, right-to-left, the photo tile's error and disabled states, and the
// filter pills wrapping.
import 'dart:io';
import 'dart:ui' show CheckedState, Tristate;

import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_filter_bar.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/form_section_card.dart';
import 'package:bravynix_school_erp/core/widgets/photo_upload_tile.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:flutter/material.dart';

import 'package:flutter/semantics.dart';
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

/// A form as a screen will build one, with every widget of the PR.
class _Form extends StatefulWidget {
  const new({this.titles = _english, this.photoEnabled = true});

  final _Titles titles;
  final bool photoEnabled;

  @override
  State<_Form> createState() => _FormState();
}

class _Titles {
  const new({
    required this.section,
    required this.photo,
    required this.photoError,
    required this.notify,
    required this.notifyNote,
    required this.copy,
    required this.group,
    required this.options,
    required this.filters,
    required this.clear,
  });

  final String section;
  final String photo;
  final String photoError;
  final String notify;
  final String notifyNote;
  final String copy;
  final String group;
  final List<String> options;
  final List<String> filters;
  final String clear;
}

const _english = _Titles(
  section: 'Student details',
  photo: 'Add photo',
  photoError: 'A photo is needed for the ID card',
  notify: 'Notify parents when marked absent',
  notifyNote: 'Sent by SMS at 10 am',
  copy: 'Send a copy to the office',
  group: 'Fee frequency',
  options: ['Monthly', 'Quarterly', 'Yearly'],
  filters: ['Class', 'Section', 'Fee status'],
  clear: 'Clear filters',
);

const _indicTitles = _Titles(
  section: 'ವಿದ್ಯಾರ್ಥಿಯ ವಿವರಗಳು',
  photo: 'फ़ोटो जोड़ें',
  photoError: 'அடையாள அட்டைக்கு புகைப்படம் தேவை',
  notify: 'अनुपस्थित होने पर अभिभावकों को सूचित करें',
  notifyNote: 'ಬೆಳಿಗ್ಗೆ 10 ಗಂಟೆಗೆ ಎಸ್‌ಎಂಎಸ್',
  copy: 'அலுவலகத்திற்கு ஒரு நகலை அனுப்பவும்',
  group: 'शुल्क की आवृत्ति',
  options: ['ಮಾಸಿಕ', 'காலாண்டு', 'वार्षिक'],
  filters: ['ತರಗತಿ', 'பிரிவு', 'शुल्क स्थिति'],
  clear: 'फ़िल्टर हटाएँ',
);

class _FormState extends State<_Form> {
  bool notify = true;
  bool copy = false;
  late String frequency = widget.titles.options.first;
  String? filter = '7-B';
  int picks = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.titles;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FormSectionCard(
            number: 1,
            title: t.section,
            stepLabel: 'Step 1/5',
            stepSpokenLabel: 'Step 1 of 5',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PhotoUploadTile(
                  label: t.photo,
                  onPick: widget.photoEnabled ? () => setState(() => picks++) : null,
                  errorText: t.photoError,
                ),
                AppSwitchTile(
                  title: t.notify,
                  subtitle: t.notifyNote,
                  icon: Icons.notifications_outlined,
                  value: notify,
                  onChanged: (v) => setState(() => notify = v),
                ),
                AppCheckboxTile(title: t.copy, value: copy, onChanged: (v) => setState(() => copy = v)),
                AppRadioGroup<String>(
                  label: t.group,
                  options: t.options,
                  titleOf: (o) => o,
                  value: frequency,
                  onChanged: (o) => setState(() => frequency = o),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppFilterBar(
            clearLabel: t.clear,
            onClear: () => setState(() => filter = null),
            filters: [
              AppFilter(label: t.filters[0], value: filter, onTap: () {}),
              AppFilter(label: t.filters[1], onTap: () {}),
              AppFilter(label: t.filters[2], onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
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

void main() {
  setUpAll(() async {
    await _loadFont(AppTextStyles.family, [
      for (final w in [400, 500, 600, 700]) 'assets/fonts/plus_jakarta_sans/PlusJakartaSans-$w.ttf',
    ]);
    await _loadFont('MaterialIcons', [
      '${Platform.environment['FLUTTER_ROOT'] ?? '/home/claude/flutter-sdk'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
    const noto = 'test/fixtures/fonts/noto';
    await _loadFont('QaDeva', ['$noto/NotoSans-devanagari.ttf']);
    await _loadFont('QaTamil', ['$noto/NotoSans-tamil.ttf']);
    await _loadFont('QaKannada', ['$noto/NotoSans-kannada.ttf']);
  });

  testWidgets('screen reader: each row is one node with its words and state, in reading order', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppScaled(const _Form(), size: const Size(390, 1400));
    final nodes = tester.semantics.simulatedAccessibilityTraversal().map((n) => n.getSemanticsData()).toList();
    String describe(SemanticsData d) {
      final f = d.flagsCollection;
      final parts = <String>[
        d.label.replaceAll('\n', ' / '),
        if (f.isButton) 'button',
        if (f.isHeader) 'heading',
        if (f.isToggled == Tristate.isTrue) 'switch on',
        if (f.isToggled == Tristate.isFalse) 'switch off',
        if (f.isChecked == CheckedState.isTrue) 'checked',
        if (f.isChecked == CheckedState.isFalse) 'unchecked',
        if (f.isInMutuallyExclusiveGroup) 'radio',
        if (f.isSelected == Tristate.isTrue) 'selected',
        if (d.hasAction(SemanticsAction.tap)) 'tap',
        if (f.isEnabled == Tristate.isFalse) 'disabled',
      ];
      return parts.join(', ');
    }

    final spoken = nodes.map(describe).where((s) => s.isNotEmpty).toList();
    // The spoken order goes into the run log for the report.
    // ignore: avoid_print
    print(spoken.join('\n'));
    // The section heading and its step tag come first, each on its own; then the photo tile is its own button
    // (named "Add photo"; the error may be part of it, see the next test), then one node per row.
    // Nothing is read before the section heading, and the step tag is read with it or right after it.
    final photo = spoken.indexWhere((s) => s.startsWith('Add photo'));
    expect(photo, greaterThan(0), reason: 'the photo button is named "Add photo" on its own');
    expect(spoken.first, allOf(startsWith('Student details'), endsWith('heading')));
    expect(spoken.take(photo).join(' '), contains('Step 1 of 5'));
    expect(spoken[photo], endsWith('button, tap'));
    expect(spoken.skip(photo + 1).where((s) => s != 'A photo is needed for the ID card'), [
      'Notify parents when marked absent / Sent by SMS at 10 am, switch on, tap',
      'Send a copy to the office, unchecked, tap',
      'Fee frequency',
      'Monthly, checked, radio, tap',
      'Quarterly, unchecked, radio, tap',
      'Yearly, unchecked, radio, tap',
      'Class: 7-B, button, selected, tap',
      'Section, button, tap',
      'Fee status, button, tap',
      'Clear filters, button, tap',
    ]);
    handle.dispose();
  });

  testWidgets('the photo tile with no onPick is announced as disabled, not as a working button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppScaled(const _Form(photoEnabled: false), size: const Size(390, 1400));
    final data = tester.getSemantics(find.bySemanticsLabel(RegExp('^Add photo'))).getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isFalse, reason: '$data');
    handle.dispose();
  });

  testWidgets('keyboard: one Tab stop per row, Space and Enter work, and the switch is not a second stop', (
    tester,
  ) async {
    await tester.pumpAppScaled(const _Form(), size: const Size(390, 1400));
    final state = tester.state<_FormState>(find.byType(_Form));
    final stops = <String>[];
    for (var i = 0; i < 14; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      var name = '?';
      FocusManager.instance.primaryFocus!.context!.visitAncestorElements((e) {
        final w = e.widget;
        final found = switch (w) {
          final AppRadioTile<String> r => 'radio ${r.title}',
          final AppSwitchTile s => 'switch ${s.title}',
          final AppCheckboxTile c => 'checkbox ${c.title}',
          final PhotoUploadTile _ => 'photo',
          final AppFilterBar _ => 'filter',
          _ => null,
        };
        if (found != null) name = found;
        return found == null;
      });
      if (stops.isNotEmpty && stops.first == name) break;
      stops.add(name);
    }
    expect(stops.take(6).toList(), [
      'photo',
      'switch Notify parents when marked absent',
      'checkbox Send a copy to the office',
      'radio Monthly',
      'radio Quarterly',
      'radio Yearly',
    ]);
    // Space on the switch row, Enter on the checkbox row, Space on a radio row.
    // Tab back to each row from the top and press a key on it.
    Future<void> pressOn(int stop, LogicalKeyboardKey key) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      for (var i = 0; i <= stop; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    await pressOn(1, LogicalKeyboardKey.space);
    expect(state.notify, isFalse, reason: 'Space on the switch row');
    await pressOn(2, LogicalKeyboardKey.enter);
    expect(state.copy, isTrue, reason: 'Enter on the checkbox row');
    await pressOn(5, LogicalKeyboardKey.space);
    expect(state.frequency, 'Yearly', reason: 'Space on the Yearly row');
    await pressOn(0, LogicalKeyboardKey.enter);
    expect(state.picks, 1, reason: 'Enter on the photo tile');
  });

  for (final scale in [1.0, 2.0, 3.0]) {
    for (final indic in [false, true]) {
      final what = indic ? 'Hindi, Tamil and Kannada' : 'English';
      testWidgets('$what at ${scale * 100}% on a 320 px phone with the bundled font: nothing cut or overflowing', (
        tester,
      ) async {
        await tester.pumpAppScaled(
          _withIndicFallback(_Form(titles: indic ? _indicTitles : _english)),
          textScale: scale,
        );
        final problems = <String>{};
        final list = find.byType(Scrollable).first;
        for (var i = 0; i < 40; i++) {
          expect(tester.takeException(), isNull);
          problems.addAll(clippedParagraphs(tester, within: find.byType(_Form)));
          final position = tester.state<ScrollableState>(list).position;
          if (position.pixels >= position.maxScrollExtent) break;
          await tester.drag(list, const Offset(0, -200));
          await tester.pump();
        }
        // Every row and pill is at least a 48 px target, and nothing runs past the 320 px screen.
        for (final f in [
          find.byType(AppSwitchTile),
          find.byType(AppCheckboxTile),
          find.byType(AppRadioTile<String>),
        ]) {
          for (final e in f.evaluate()) {
            final box = e.renderObject! as RenderBox;
            if (!box.attached || !box.hasSize) continue;
            if (box.size.height < 48) problems.add('${e.widget.runtimeType} is ${box.size.height} px tall');
          }
        }
        expect(problems, isEmpty);
      });
    }
  }

  testWidgets('filter pills wrap at 300% on 320 px: every pill is on screen and 48 px tall', (tester) async {
    await tester.pumpAppScaled(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AppFilterBar(
            clearLabel: 'Clear filters',
            onClear: () {},
            filters: [
              AppFilter(label: 'Class', value: '7-B', onTap: () {}),
              AppFilter(label: 'Section', value: 'All sections except the evening batch', onTap: () {}),
              AppFilter(label: 'Fee status', onTap: () {}),
              AppFilter(label: 'Transport route', onTap: () {}),
            ],
          ),
        ),
      ),
      textScale: 3,
    );
    expect(tester.takeException(), isNull);
    final pills = find.descendant(of: find.byType(AppFilterBar), matching: find.byType(InkWell));
    final problems = <String>[];
    for (final e in pills.evaluate()) {
      final r = tester.getRect(find.byElementPredicate((x) => x == e));
      if (r.left < 0 || r.right > 320) problems.add('pill at $r runs off the screen');
      if (r.height < 48) problems.add('pill at $r is under 48 px');
    }
    problems.addAll(clippedParagraphs(tester));
    expect(problems, isEmpty);
  });

  testWidgets('right-to-left at 100% and 300%: the switch sits at the start edge and nothing overflows', (
    tester,
  ) async {
    for (final scale in [1.0, 3.0]) {
      await tester.pumpAppScaled(
        const Directionality(textDirection: TextDirection.rtl, child: _Form()),
        textScale: scale,
        size: const Size(320, 1600),
      );
      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(AppSwitchTile));
      final control = tester.getRect(find.byType(Switch));
      expect(control.center.dx, lessThan(row.center.dx), reason: 'at $scale the switch should be on the left in RTL');
    }
  });

  testWidgets('a long list of radio rows keeps one group and each row its own state', (tester) async {
    final handle = tester.ensureSemantics();
    final options = [for (var i = 1; i <= 12; i++) 'Route $i'];
    await tester.pumpAppScaled(
      Scaffold(
        body: ListView(
          children: [
            AppRadioGroup<String>(
              label: 'Bus route',
              options: options,
              titleOf: (o) => o,
              value: 'Route 7',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
      size: const Size(390, 1200),
    );
    final checked = tester.semantics
        .simulatedAccessibilityTraversal()
        .map((n) => n.getSemanticsData())
        .where(
          (d) => d.flagsCollection.isInMutuallyExclusiveGroup && d.flagsCollection.isChecked == CheckedState.isTrue,
        )
        .map((d) => d.label)
        .toList();
    expect(checked, ['Route 7']);
    handle.dispose();
  });
}
