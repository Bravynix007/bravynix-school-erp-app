import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Material 3 theme from the "Warm Campus Harmony" tokens. The `accent` is the
/// only thing the theme switch changes: primary buttons, accent text, tonal
/// fills, the active tab and the focus ring. The accent header belongs to the
/// module-header widget (App PR 3); the plain app bar here is white. Neutrals
/// and status colours stay fixed.
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
      secondaryContainer: accent.tint,
      onSecondaryContainer: accent.text,
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

    // apply() sets the colour on every body, title and label style, so it runs
    // first and the caption colour is set after it.
    final base = TextTheme(
      displayMedium: AppTextStyles.display,
      headlineLarge: AppTextStyles.headlineLg,
      headlineMedium: AppTextStyles.headlineMd,
      headlineSmall: AppTextStyles.headlineSm,
      titleLarge: AppTextStyles.headlineSm,
      titleMedium: AppTextStyles.labelLg,
      titleSmall: AppTextStyles.labelMd,
      bodyLarge: AppTextStyles.bodyLg,
      bodyMedium: AppTextStyles.bodyMd,
      bodySmall: AppTextStyles.bodySm,
      labelLarge: AppTextStyles.labelLg,
      labelMedium: AppTextStyles.labelMd,
      labelSmall: AppTextStyles.labelSm,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
    final textTheme = base.copyWith(bodySmall: base.bodySmall?.copyWith(color: AppColors.inkSecondary));

    const focusSide = BorderSide(color: AppColors.focusRing, width: 2);
    // A ring on keyboard focus; `rest` is the outline otherwise.
    WidgetStateProperty<BorderSide?> ringOr(BorderSide? rest) =>
        WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.focused) ? focusSide : rest);

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
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonLarge),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          disabledBackgroundColor: AppColors.sunken,
          disabledForegroundColor: AppColors.disabled,
        ).copyWith(side: ringOr(null)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonLarge),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          foregroundColor: AppColors.ink,
        ).copyWith(side: ringOr(const BorderSide(color: AppColors.border))),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          textStyle: textTheme.labelLarge,
          foregroundColor: accent.text,
        ).copyWith(side: ringOr(null)),
      ),
      iconButtonTheme: IconButtonThemeData(style: ButtonStyle(side: ringOr(null))),
      // Option pickers use ChoiceChipGroup (it draws its own chip). This keeps any other Material chip on the
      // same outline and focus ring.
      chipTheme: ChipThemeData(
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? focusSide
              : states.contains(WidgetState.selected)
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: ringOr(const BorderSide(color: AppColors.border)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        border: fieldBorder(AppColors.fieldBorder),
        enabledBorder: fieldBorder(AppColors.fieldBorder),
        disabledBorder: fieldBorder(AppColors.divider),
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
      // The row is the control (AppSwitchTile); the switch only has to be readable: its off track is outlined in
      // the field colour (3:1), the on track is the accent.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.disabled
              : states.contains(WidgetState.selected)
              ? accent.onPrimary
              : AppColors.inkSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.sunken
              : states.contains(WidgetState.selected)
              ? accent.primary
              : AppColors.sunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.divider
              : states.contains(WidgetState.selected)
              ? accent.primary
              : AppColors.fieldBorder,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: AppColors.ink),
    );
  }
}
