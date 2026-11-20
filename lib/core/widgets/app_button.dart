import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
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
    this.iconAlignment = IconAlignment.start,
    this.loading = false,
    this.expand,
    this.labelRoom,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconAlignment iconAlignment;
  final bool loading;

  /// Fill the available width. Defaults to true for large buttons only.
  final bool? expand;

  /// The width the label has, when the caller knows it (a bar that lays two
  /// buttons out). A word wider than that is drawn smaller instead of being
  /// broken in half, as a last resort at the largest text sizes.
  final double? labelRoom;

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
        : _Label(label: label, icon: icon, iconAlignment: iconAlignment, fill: fill, style: textStyle, room: labelRoom);

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
  const new({
    required this.label,
    required this.style,
    required this.iconAlignment,
    required this.fill,
    this.icon,
    this.room,
  });

  final String label;
  final TextStyle? style;
  final IconData? icon;
  final IconAlignment iconAlignment;
  final bool fill;
  final double? room;

  @override
  Widget build(BuildContext context) {
    final trailing = icon != null && iconAlignment == IconAlignment.end;
    final text = Text(
      label,
      textAlign: trailing ? TextAlign.start : TextAlign.center,
      textScaler: room == null ? null : fitWordScaler(context, label, style, room!),
    );
    if (icon == null) return text;
    final spread = fill && trailing;
    final glyph = Padding(
      padding: trailing
          ? const EdgeInsetsDirectional.only(start: AppSpacing.xs)
          : const EdgeInsetsDirectional.only(end: AppSpacing.xs),
      child: Icon(icon, size: 20),
    );
    return Row(
      mainAxisSize: spread ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: spread ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      children: [
        if (!trailing) glyph,
        Flexible(child: text),
        if (trailing) glyph,
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
