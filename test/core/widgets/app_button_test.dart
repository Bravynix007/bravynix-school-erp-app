import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Color? _fill(WidgetTester tester, Type button) {
  final material = find.descendant(of: find.byType(button), matching: find.byType(Material)).first;
  return tester.widget<Material>(material).color;
}

void main() {
  group('AppButton', () {
    testWidgets('shows its label and calls onPressed', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: AppButton(label: 'Save', onPressed: () => taps += 1),
        ),
      );
      await tester.tap(find.text('Save'));
      expect(taps, 1);
    });

    testWidgets('a disabled button does nothing', (tester) async {
      await tester.pumpApp(const Center(child: AppButton(label: 'Save', onPressed: null)));
      await tester.tap(find.text('Save'), warnIfMissed: false);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    });

    testWidgets('while loading it shows a spinner, hides the label and ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: AppButton(label: 'Save', loading: true, onPressed: () => taps += 1),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('heights follow the sizes: 52, 44 and 36 px, with a 48 px hit area', (tester) async {
      for (final (size, height) in [
        (AppButtonSize.large, AppSizes.buttonLarge),
        (AppButtonSize.medium, AppSizes.buttonMedium),
        (AppButtonSize.small, AppSizes.buttonSmall),
      ]) {
        await tester.pumpApp(
          Center(
            child: AppButton(label: 'Go', size: size, onPressed: () {}),
          ),
        );
        final padded = tester.getSize(find.byType(FilledButton)).height;
        expect(padded, greaterThanOrEqualTo(AppSpacing.minTouchTarget), reason: '$size hit area');
        final surface = find.descendant(of: find.byType(FilledButton), matching: find.byType(Material)).first;
        expect(tester.getSize(surface).height, height, reason: '$size');
      }
    });

    testWidgets('large fills the width, medium and small hug the label', (tester) async {
      await tester.pumpApp(
        Center(
          child: AppButton(label: 'Go', onPressed: () {}),
        ),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, 800);
      await tester.pumpApp(
        Center(
          child: AppButton(label: 'Go', size: AppButtonSize.medium, onPressed: () {}),
        ),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, lessThan(200));
    });

    testWidgets('each variant draws the button the designs show', (tester) async {
      await tester.pumpApp(
        Column(
          children: [
            AppButton(label: 'Primary', onPressed: () {}),
            AppButton(label: 'Danger', variant: AppButtonVariant.danger, onPressed: () {}),
            AppButton(label: 'Secondary', variant: AppButtonVariant.secondary, onPressed: () {}),
            AppButton(label: 'Tonal', variant: AppButtonVariant.tonal, onPressed: () {}),
            AppButton(label: 'Text', variant: AppButtonVariant.text, onPressed: () {}),
          ],
        ),
      );
      Color? fillOf(String label) {
        final material = find
            .descendant(of: find.widgetWithText(FilledButton, label), matching: find.byType(Material))
            .first;
        return tester.widget<Material>(material).color;
      }

      expect(fillOf('Primary'), AppAccent.teal.primary);
      expect(fillOf('Danger'), AppColors.error);
      expect(fillOf('Tonal'), AppAccent.teal.tint);
      expect(find.widgetWithText(OutlinedButton, 'Secondary'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Text'), findsOneWidget);
    });

    testWidgets('follows the accent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(accent: AppAccent.rosePink),
          home: Center(
            child: AppButton(label: 'Go', onPressed: () {}),
          ),
        ),
      );
      expect(_fill(tester, FilledButton), AppAccent.rosePink.primary);
    });

    testWidgets('an icon sits beside the label', (tester) async {
      await tester.pumpApp(
        Center(
          child: AppButton(label: 'Add', icon: Icons.add, onPressed: () {}),
        ),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('a long label wraps at 200% text on a narrow phone instead of overflowing', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(label: 'Mark all students present', icon: Icons.check, onPressed: () {}),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppIconButton', () {
    testWidgets('has a tooltip as its spoken name and a 48 px target', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: AppIconButton(icon: Icons.edit, tooltip: 'Edit', onPressed: () => taps += 1),
        ),
      );
      expect(find.byTooltip('Edit'), findsOneWidget);
      expect(tester.getSize(find.byType(IconButton)).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(find.byType(IconButton));
      expect(taps, 1);
    });
  });
}
