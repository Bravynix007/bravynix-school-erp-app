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

  test('the accent changes the header, buttons and focus ring, and nothing else', () {
    final teal = AppTheme.light();
    for (final accent in AppAccent.values) {
      final theme = AppTheme.light(accent: accent);
      expect(theme.colorScheme.primary, accent.primary);
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.inputDecorationTheme.focusedBorder?.borderSide.color, accent.primary);
      expect(theme.colorScheme.error, teal.colorScheme.error);
      expect(theme.colorScheme.surface, teal.colorScheme.surface);
      expect(theme.scaffoldBackgroundColor, teal.scaffoldBackgroundColor);
    }
  });

  test('controls follow the designs: 52 px buttons, 12/14/16 corners', () {
    final theme = AppTheme.light();
    expect(theme.filledButtonTheme.style?.minimumSize?.resolve({}), const Size.fromHeight(AppSizes.buttonLarge));
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
            child: Center(child: Text('Attendance', style: AppTextStyles.bodyLg)),
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
