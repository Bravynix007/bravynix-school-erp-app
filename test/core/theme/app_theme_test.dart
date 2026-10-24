import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the default theme is teal in Plus Jakarta Sans', () {
    final theme = AppTheme.light();
    expect(theme.colorScheme.primary, AppAccent.teal.primary);
    expect(theme.textTheme.bodyMedium?.fontFamily, AppTextStyles.family);
    expect(theme.scaffoldBackgroundColor, AppColors.canvas);
  });

  test('the accent changes buttons, accent text, tonal fills and the focus ring, and no neutral or status colour', () {
    final teal = AppTheme.light();
    for (final accent in AppAccent.values) {
      final theme = AppTheme.light(accent: accent);
      expect(theme.colorScheme.primary, accent.primary);
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.inputDecorationTheme.focusedBorder?.borderSide.color, accent.primary);
      expect(theme.colorScheme.primaryContainer, accent.tint);
      expect(theme.colorScheme.secondaryContainer, accent.tint);
      expect(theme.colorScheme.onSecondaryContainer, accent.text);
      expect(theme.textButtonTheme.style?.foregroundColor?.resolve({}), accent.text);
      for (final neutral in [
        (ColorScheme c) => c.error,
        (ColorScheme c) => c.onError,
        (ColorScheme c) => c.errorContainer,
        (ColorScheme c) => c.surface,
        (ColorScheme c) => c.onSurface,
        (ColorScheme c) => c.onSurfaceVariant,
        (ColorScheme c) => c.secondary,
        (ColorScheme c) => c.outline,
        (ColorScheme c) => c.outlineVariant,
        (ColorScheme c) => c.surfaceContainerHigh,
      ]) {
        expect(neutral(theme.colorScheme), neutral(teal.colorScheme), reason: accent.label);
      }
      expect(theme.colorScheme.surface, teal.colorScheme.surface);
      expect(theme.scaffoldBackgroundColor, teal.scaffoldBackgroundColor);
    }
  });

  test('captions use the secondary ink and body text the primary ink', () {
    final text = AppTheme.light().textTheme;
    expect(text.bodySmall?.color, AppColors.inkSecondary);
    expect(text.bodyMedium?.color, AppColors.ink);
    expect(text.titleLarge?.color, AppColors.ink);
    expect(text.bodySmall?.fontSize, 13);
  });

  test('headline roles keep their sizes, so screens can pick the one the design shows', () {
    final text = AppTheme.light().textTheme;
    expect(text.headlineLarge?.fontSize, 24);
    expect(text.headlineMedium?.fontSize, 20);
    expect(text.headlineSmall?.fontSize, 18);
  });

  test('tonal fills use the accent tint, not the grey secondary', () {
    final scheme = AppTheme.light(accent: AppAccent.rosePink).colorScheme;
    expect(scheme.secondaryContainer, AppAccent.rosePink.tint);
    expect(scheme.secondaryContainer, isNot(scheme.secondary));
  });

  test('a disabled field has a lighter outline than an enabled one', () {
    final theme = AppTheme.light().inputDecorationTheme;
    expect(theme.disabledBorder?.borderSide.color, AppColors.divider);
    expect(theme.enabledBorder?.borderSide.color, AppColors.fieldBorder);
  });

  test('controls follow the designs: 52 px buttons, 12/14/16 corners', () {
    final theme = AppTheme.light();
    expect(theme.filledButtonTheme.style?.minimumSize?.resolve({}), const Size.fromHeight(AppSizes.buttonLarge));
    expect(theme.outlinedButtonTheme.style?.minimumSize?.resolve({}), const Size.fromHeight(AppSizes.buttonLarge));
    final shape = theme.filledButtonTheme.style?.shape?.resolve({}) as RoundedRectangleBorder?;
    expect(shape?.borderRadius, BorderRadius.circular(AppRadius.button));
    final outlined = theme.outlinedButtonTheme.style?.shape?.resolve({}) as RoundedRectangleBorder?;
    expect(outlined?.borderRadius, BorderRadius.circular(AppRadius.button));
    final field = theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
    expect(field.borderRadius, BorderRadius.circular(AppRadius.field));
    final card = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(card.borderRadius, BorderRadius.circular(AppRadius.card));
  });

  testWidgets('text grows with the phone font setting', (tester) async {
    Future<double> heightAt(double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Builder(
              builder: (context) => Center(child: Text('Attendance', style: Theme.of(context).textTheme.bodyLarge)),
            ),
          ),
        ),
      );
      return tester.getSize(find.text('Attendance')).height;
    }

    final normal = await heightAt(1);
    final large = await heightAt(2);
    expect(large, greaterThan(normal));
  });
}
