import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio of two opaque colours.
double contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) / (darker.computeLuminance() + 0.05);
}

void main() {
  group('accents (UI alignment spec, Theme switch)', () {
    test('there are seven, with teal the default', () {
      expect(AppAccent.values, hasLength(7));
      expect(AppAccent.defaultAccent, AppAccent.teal);
      expect(AppAccent.teal.primary, const Color(0xFF0E5E5A));
    });

    test('hold the values from the spec', () {
      expect(
        {for (final a in AppAccent.values) a.label: a.primary.toARGB32()},
        {
          'BravyNix Teal': 0xFF0E5E5A,
          'Forest Green': 0xFF3A8163,
          'Royal Purple': 0xFF8465B7,
          'Steel Blue': 0xFF3A79AD,
          'Rose Pink': 0xFFC84277,
          'Sunset Orange': 0xFFB15F1F,
          'Dark Cyan': 0xFF327F7F,
        },
      );
    });

    test('keep white text on the accent at WCAG AA (4.5:1)', () {
      for (final accent in AppAccent.values) {
        expect(contrast(accent.primary, accent.onPrimary), greaterThanOrEqualTo(4.5), reason: accent.label);
      }
    });

    test('derive a darker pressed state and a light tint', () {
      expect(AppAccent.teal.pressed.toARGB32(), 0xFF0B4B48);
      for (final accent in AppAccent.values) {
        expect(accent.pressed.computeLuminance(), lessThan(accent.primary.computeLuminance()));
        expect(accent.tint.computeLuminance(), greaterThan(0.8));
      }
    });
  });

  group('colours', () {
    test('status and attendance colours have one value each', () {
      expect(AppColors.success, const Color(0xFF1E7347));
      expect(AppColors.error, const Color(0xFFB3261E));
      expect(AppColors.warning, const Color(0xFF9A5407));
      expect(AppColors.info, const Color(0xFF2B5A94));
      expect(AppColors.halfDay, const Color(0xFF6B4FA0));
      expect(AppColors.holiday, const Color(0xFFFBA86F));
      expect(AppColors.present, AppColors.success);
      expect(AppColors.absent, AppColors.error);
      expect(AppColors.late, AppColors.warning);
      expect(AppColors.leave, AppColors.info);
    });

    test('body text is readable on every surface', () {
      for (final surface in [AppColors.canvas, AppColors.surface, AppColors.sunken]) {
        expect(contrast(AppColors.ink, surface), greaterThanOrEqualTo(7));
        expect(contrast(AppColors.inkSecondary, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(AppColors.inkTertiary, surface), greaterThanOrEqualTo(4.5));
      }
    });

    test('status text is readable on its tint', () {
      final pairs = {
        AppColors.success: AppColors.successBg,
        AppColors.warning: AppColors.warningBg,
        AppColors.error: AppColors.errorBg,
        AppColors.info: AppColors.infoBg,
      };
      for (final MapEntry(key: foreground, value: background) in pairs.entries) {
        expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('text styles', () {
    test('hold the sizes and line heights from the designs', () {
      double size(TextStyle s) => s.fontSize!;
      double line(TextStyle s) => s.fontSize! * s.height!;
      final sizes = {
        AppTextStyles.display: (32, 40),
        AppTextStyles.headlineLg: (24, 32),
        AppTextStyles.headlineMd: (20, 28),
        AppTextStyles.headlineSm: (18, 24),
        AppTextStyles.bodyLg: (16, 24),
        AppTextStyles.bodyMd: (14, 20),
        AppTextStyles.bodySm: (13, 18),
        AppTextStyles.labelLg: (14, 20),
        AppTextStyles.labelMd: (12, 16),
        AppTextStyles.labelSm: (11, 14),
      };
      for (final MapEntry(key: style, value: expected) in sizes.entries) {
        expect(size(style), expected.$1.toDouble());
        expect(line(style), closeTo(expected.$2.toDouble(), 0.001));
      }
    });

    test('use Plus Jakarta Sans, with the weight set on the variable axis too', () {
      expect(AppTextStyles.headlineMd.fontFamily, 'PlusJakartaSans');
      expect(AppTextStyles.headlineMd.fontWeight, FontWeight.w600);
      expect(AppTextStyles.headlineMd.fontVariations, [const FontVariation('wght', 600)]);
    });

    test('carry no colour, so the theme decides', () {
      for (final style in [AppTextStyles.display, AppTextStyles.bodyMd, AppTextStyles.labelSm]) {
        expect(style.color, isNull);
      }
    });

    test('align figures in amounts and IDs', () {
      for (final style in [AppTextStyles.number, AppTextStyles.code]) {
        expect(style.fontFeatures, [const FontFeature.tabularFigures()]);
      }
    });
  });

  test('spacing is on a 4 px grid and touch targets are 48 px', () {
    for (final step in [
      AppSpacing.xxs,
      AppSpacing.xs,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.xxl,
    ]) {
      expect(step % 4, 0);
    }
    expect(AppSpacing.minTouchTarget, 48);
    expect(AppSizes.buttonLarge, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
  });
}
