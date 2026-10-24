import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, tonal, text, danger }

enum AppButtonSize {
  large(AppSizes.buttonLarge),
  medium(AppSizes.buttonMedium),
  small(AppSizes.buttonSmall);

  new(this.height);

  final double height;
}

/// The one button. Variants follow the designs: primary (accent fill),
/// secondary (outline), tonal (accent wash), text, and danger (red fill).
/// Large buttons fill the width; medium and small hug their label. While
/// `loading` the label is replaced by a spinner and taps do nothing, so a
/// double tap cannot send twice. The hit area stays at least 48 px.
class AppButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.loading = false,
    this.expand,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;

  /// Fill the available width. Defaults to true for large buttons only.
  final bool? expand;

  @override
  Widget build(BuildContext context) {
    final fill = expand ?? size == AppButtonSize.large;
    final minimumSize = fill ? Size.fromHeight(size.height) : Size(AppSpacing.minTouchTarget, size.height);
    final textStyle = size == AppButtonSize.small
        ? Theme.of(context).textTheme.labelMedium
        : Theme.of(context).textTheme.labelLarge;
    final padding = EdgeInsets.symmetric(horizontal: size == AppButtonSize.small ? AppSpacing.sm : AppSpacing.md);
    // While loading a live button stays enabled (so it keeps its colour) but
    // does nothing; a button that was disabled stays disabled.
    final callback = loading && onPressed != null ? () {} : onPressed;
    final child = loading
        ? Semantics(label: label, excludeSemantics: true, child: const _Spinner())
        : _Label(label: label, icon: icon);

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: callback,
        style: FilledButton.styleFrom(minimumSize: minimumSize, textStyle: textStyle, padding: padding),
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: callback,
        style: FilledButton.styleFrom(
          minimumSize: minimumSize,
          textStyle: textStyle,
          padding: padding,
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.sunken,
          disabledForegroundColor: AppColors.disabled,
        ),
        child: child,
      ),
      AppButtonVariant.tonal => FilledButton.tonal(
        onPressed: callback,
        style: FilledButton.styleFrom(minimumSize: minimumSize, textStyle: textStyle, padding: padding),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        style: OutlinedButton.styleFrom(minimumSize: minimumSize, textStyle: textStyle, padding: padding),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: callback,
        style: TextButton.styleFrom(minimumSize: minimumSize, textStyle: textStyle, padding: padding),
        child: child,
      ),
    };
  }
}

class _Label extends StatelessWidget {
  const new({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: text),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: DefaultTextStyle.of(context).style.color),
    );
  }
}
