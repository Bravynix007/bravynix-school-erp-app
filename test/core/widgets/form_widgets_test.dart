import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_filter_bar.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/form_section_card.dart';
import 'package:bravynix_school_erp/core/widgets/photo_upload_tile.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/contrast.dart';
import '../../helpers/pump_app.dart';

// A 1 x 1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, //
  0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const _scales = [1.0, 1.3, 2.0, 3.0];

void main() {
  group('AppSwitchTile', () {
    testWidgets('toggles from a tap anywhere on the row and speaks as a switch', (tester) async {
      final handle = tester.ensureSemantics();
      var value = false;
      await tester.pumpApp(
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppSwitchTile(
              title: 'Notify parents of absence',
              subtitle: 'Sent at 10 am',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Notify parents of absence')),
        isSemantics(
          label: 'Notify parents of absence\nSent at 10 am',
          hasToggledState: true,
          isToggled: false,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      await tester.tap(find.text('Sent at 10 am'));
      await tester.pump();
      expect(value, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      handle.dispose();
    });

    testWidgets('has one focus stop, 56 px tall, and rings it for the keyboard', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: AppSwitchTile(title: 'Notify', value: true, onChanged: (_) {}),
        ),
      );
      expect(tester.getSize(find.byType(AppSwitchTile)).height, greaterThanOrEqualTo(56));
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final ring = find.descendant(of: find.byType(AppSwitchTile), matching: find.byType(DecoratedBox));
      final borders = tester
          .widgetList<DecoratedBox>(ring)
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.border)
          .whereType<Border>()
          .where((b) => b.top.width == 2 && b.top.color == AppColors.focusRing);
      expect(borders, isNotEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        find.descendant(of: find.byType(AppSwitchTile), matching: find.byType(Focus)).evaluate().isNotEmpty,
        isTrue,
      );
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    });

    testWidgets('disabled does nothing and is announced as disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Scaffold(
          body: AppSwitchTile(title: 'Notify', value: false, onChanged: null),
        ),
      );
      await tester.tap(find.text('Notify'));
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Notify')),
        isSemantics(label: 'Notify', hasToggledState: true, hasEnabledState: true),
      );
      handle.dispose();
    });

    for (final accent in AppAccent.values) {
      testWidgets('${accent.label}: the off switch outline and the on track are 3:1 against the surface', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(accent: accent),
            home: const Scaffold(body: SizedBox()),
          ),
        );
        final theme = AppTheme.light(accent: accent).switchTheme;
        final off = theme.trackOutlineColor!.resolve({})!;
        final on = theme.trackColor!.resolve({WidgetState.selected})!;
        expect(contrast(off, AppColors.surface), greaterThanOrEqualTo(3));
        expect(contrast(on, AppColors.surface), greaterThanOrEqualTo(3));
        expect(contrast(theme.thumbColor!.resolve({})!, AppColors.sunken), greaterThanOrEqualTo(3));
        expect(contrast(theme.thumbColor!.resolve({WidgetState.selected})!, on), greaterThanOrEqualTo(3));
      });
    }
  });

  group('AppCheckboxTile and AppRadioTile', () {
    testWidgets('a checkbox row toggles and speaks its state', (tester) async {
      final handle = tester.ensureSemantics();
      bool? last;
      await tester.pumpApp(
        Scaffold(
          body: AppCheckboxTile(title: 'Send a copy to the office', value: false, onChanged: (v) => last = v),
        ),
      );
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Send a copy to the office')),
        isSemantics(
          label: 'Send a copy to the office',
          hasCheckedState: true,
          isChecked: false,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      await tester.tap(find.text('Send a copy to the office'));
      expect(last, isTrue);
      handle.dispose();
    });

    testWidgets('a radio group has one chosen row, named as a group, and reports a tap', (tester) async {
      final handle = tester.ensureSemantics();
      String? picked;
      await tester.pumpApp(
        Scaffold(
          body: AppRadioGroup<String>(
            label: 'Fee frequency',
            options: const ['Monthly', 'Quarterly', 'Yearly'],
            titleOf: (v) => v,
            subtitleOf: (v) => v == 'Yearly' ? 'Due in April' : null,
            value: 'Quarterly',
            onChanged: (v) => picked = v,
          ),
        ),
      );
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
      expect(
        tester.getSemantics(find.text('Quarterly')),
        isSemantics(
          label: 'Quarterly',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      expect(find.bySemanticsLabel('Fee frequency'), findsOneWidget);
      await tester.tap(find.text('Yearly'));
      expect(picked, 'Yearly');
      handle.dispose();
    });

    testWidgets('an unchecked mark is the field outline colour (3:1) and a disabled row does nothing', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          body: Column(
            children: [
              AppCheckboxTile(title: 'On', value: false, onChanged: (_) => taps += 1),
              const AppCheckboxTile(title: 'Off', value: false, onChanged: null),
            ],
          ),
        ),
      );
      final marks = tester.widgetList<Icon>(find.byIcon(Icons.check_box_outline_blank)).toList();
      expect(marks.first.color, AppColors.fieldBorder);
      expect(contrast(AppColors.fieldBorder, AppColors.canvas), greaterThanOrEqualTo(3));
      await tester.tap(find.text('Off'));
      expect(taps, 0);
    });
  });

  group('PhotoUploadTile', () {
    testWidgets('the empty tile is a 96 px button that asks to pick', (tester) async {
      final handle = tester.ensureSemantics();
      var picks = 0;
      await tester.pumpApp(
        Scaffold(
          body: PhotoUploadTile(label: 'Add photo', onPick: () => picks += 1),
        ),
      );
      final size = tester.getSize(
        find.ancestor(of: find.text('Add photo'), matching: find.byType(ConstrainedBox)).first,
      );
      expect(size.width, greaterThanOrEqualTo(96));
      expect(size.height, greaterThanOrEqualTo(96));
      expect(
        tester.getSemantics(find.text('Add photo')),
        isSemantics(label: 'Add photo', isButton: true, hasTapAction: true, isFocusable: true),
      );
      await tester.tap(find.text('Add photo'));
      expect(picks, 1);
      handle.dispose();
    });

    testWidgets('a chosen photo is described, with Change and Remove beside it', (tester) async {
      final handle = tester.ensureSemantics();
      var removed = 0;
      await tester.pumpApp(
        Scaffold(
          body: PhotoUploadTile(
            label: 'Add photo',
            onPick: () {},
            image: MemoryImage(_png),
            imageLabel: 'Photo of Kavya',
            changeLabel: 'Change photo',
            onRemove: () => removed += 1,
            removeLabel: 'Remove photo',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Photo of Kavya'), findsOneWidget);
      expect(find.text('Add photo'), findsNothing);
      await tester.tap(find.text('Remove photo'));
      expect(removed, 1);
      expect(find.text('Change photo'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an error is shown in words and outlines the tile', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: PhotoUploadTile(label: 'Add photo', onPick: () {}, errorText: 'A photo is needed'),
        ),
      );
      expect(find.text('A photo is needed'), findsOneWidget);
      final shape =
          tester
                  .widget<Material>(find.ancestor(of: find.text('Add photo'), matching: find.byType(Material)).first)
                  .shape!
              as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.error);
    });

    testWidgets('a chosen photo without words for it is a mistake', (tester) async {
      expect(
        () => PhotoUploadTile(label: 'x', onPick: () {}, image: MemoryImage(_png)),
        throwsAssertionError,
      );
    });
  });

  group('FormSectionCard', () {
    testWidgets('a numbered heading, its step tag and the fields under it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Scaffold(
          body: FormSectionCard(
            number: 2,
            title: 'Guardian details',
            subtitle: 'Who we call first',
            stepLabel: 'Step 2/5',
            child: Text('Fields'),
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Step 2/5'), findsOneWidget);
      expect(find.text('Fields'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Guardian details')),
        isSemantics(label: 'Guardian details', isHeader: true),
      );
      // The number is decoration: the title and the step tag say it.
      expect(find.bySemanticsLabel('2'), findsNothing);
      handle.dispose();
    });
  });

  group('AppFilterBar', () {
    testWidgets('an applied filter shows its value and a tick, Clear shows only then', (tester) async {
      final handle = tester.ensureSemantics();
      var cleared = 0;
      var opened = '';
      Widget bar(String? cls) => Scaffold(
        body: AppFilterBar(
          clearLabel: 'Clear filters',
          onClear: () => cleared += 1,
          filters: [
            AppFilter(label: 'Class', value: cls, onTap: () => opened = 'class'),
            AppFilter(label: 'Section', onTap: () => opened = 'section'),
          ],
        ),
      );
      await tester.pumpApp(bar(null));
      expect(find.text('Clear filters'), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
      await tester.tap(find.text('Section'));
      expect(opened, 'section');
      await tester.pumpApp(bar('7-B'));
      expect(find.text('Class: 7-B'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Class: 7-B')),
        isSemantics(
          label: 'Class: 7-B',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
          hasSelectedState: true,
        ),
      );
      await tester.tap(find.text('Clear filters'));
      expect(cleared, 1);
      handle.dispose();
    });
  });

  for (final scale in _scales) {
    testWidgets('form widgets at ${scale * 100}% text on 320 px: nothing is cut or broken mid-word', (tester) async {
      await tester.pumpAppScaled(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSwitchTile(
                title: 'Notify parents when a student is marked absent',
                subtitle: 'Sent by SMS at 10 am',
                icon: Icons.notifications_outlined,
                value: true,
                onChanged: (_) {},
              ),
              AppCheckboxTile(title: 'Send a copy to the office', subtitle: 'Optional', value: true, onChanged: (_) {}),
              AppRadioGroup<String>(
                label: 'Fee frequency',
                options: const ['Monthly', 'Quarterly', 'Yearly'],
                titleOf: (v) => v,
                value: 'Monthly',
                onChanged: (_) {},
              ),
              PhotoUploadTile(label: 'Add photo', onPick: () {}),
              const SizedBox(height: 8),
              PhotoUploadTile(
                label: 'Add photo',
                onPick: () {},
                image: MemoryImage(_png),
                imageLabel: 'Photo of Kavya',
                changeLabel: 'Change photo',
                onRemove: () {},
                removeLabel: 'Remove photo',
              ),
              const SizedBox(height: 8),
              const FormSectionCard(
                number: 3,
                title: 'Guardian details',
                subtitle: 'Who we call first',
                stepLabel: 'Step 3/5',
                child: Text('Name and phone number'),
              ),
              const SizedBox(height: 8),
              AppFilterBar(
                clearLabel: 'Clear filters',
                onClear: () {},
                filters: [
                  AppFilter(label: 'Class', value: '7-B', onTap: () {}),
                  AppFilter(label: 'Section', onTap: () {}),
                  AppFilter(label: 'Fee status', onTap: () {}),
                ],
              ),
            ],
          ),
        ),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester), isEmpty);
    });
  }
}
