import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Material 3 theme from the "Warm Campus Harmony" tokens. The `accent` is the
/// only thing the theme switch changes: header, primary buttons, the active
/// tab and the focus ring. Neutrals and status colours stay fixed.
abstract final class AppTheme {
  static ThemeData light({AppAccent accent = AppAccent.defaultAccent}) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: accent.primary,
      onPrimary: accent.onPrimary,
      primaryContainer: accent.tint,
      onPrimaryContainer: accent.pressed,
      secondary: AppColors.inkSecondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorBg,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.canvas,
      surfaceContainer: AppColors.canvas,
      surfaceContainerHigh: AppColors.sunken,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    final textTheme = TextTheme(
      displayMedium: AppTextStyles.display,
      headlineLarge: AppTextStyles.headlineLg,
      headlineMedium: AppTextStyles.headlineMd,
      headlineSmall: AppTextStyles.headlineSm,
      titleLarge: AppTextStyles.headlineSm,
      titleMedium: AppTextStyles.labelLg,
      titleSmall: AppTextStyles.labelMd,
      bodyLarge: AppTextStyles.bodyLg,
      bodyMedium: AppTextStyles.bodyMd,
      bodySmall: AppTextStyles.bodySm.copyWith(color: AppColors.inkSecondary),
      labelLarge: AppTextStyles.labelLg,
      labelMedium: AppTextStyles.labelMd,
      labelSmall: AppTextStyles.labelSm,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button));
    OutlineInputBorder fieldBorder(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: AppTextStyles.family,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineSm.copyWith(color: AppColors.ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonLarge),
          shape: buttonShape,
          textStyle: AppTextStyles.labelLg,
          disabledBackgroundColor: AppColors.sunken,
          disabledForegroundColor: AppColors.disabled,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonLarge),
          shape: buttonShape,
          textStyle: AppTextStyles.labelLg,
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.ink,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          textStyle: AppTextStyles.labelLg,
          foregroundColor: accent.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        border: fieldBorder(AppColors.border),
        enabledBorder: fieldBorder(AppColors.border),
        focusedBorder: fieldBorder(accent.primary, width: 2),
        errorBorder: fieldBorder(AppColors.error),
        focusedErrorBorder: fieldBorder(AppColors.error, width: 2),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, space: 1),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: AppColors.ink),
    );
  }
}
