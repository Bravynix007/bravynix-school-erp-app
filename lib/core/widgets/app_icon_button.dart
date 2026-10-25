import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// An icon-only button. The tooltip is required: it is the spoken name for
/// screen readers and the long-press hint for everyone else.
class AppIconButton extends StatelessWidget {
  const new({required this.icon, required this.tooltip, required this.onPressed, this.tonal = false, super.key});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// An accent wash behind the icon.
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    const size = Size.square(AppSpacing.minTouchTarget);
    return tonal
        ? IconButton.filledTonal(
            icon: Icon(icon),
            tooltip: tooltip,
            onPressed: onPressed,
            style: IconButton.styleFrom(minimumSize: size),
          )
        : IconButton(
            icon: Icon(icon),
            tooltip: tooltip,
            onPressed: onPressed,
            style: IconButton.styleFrom(minimumSize: size),
          );
  }
}
