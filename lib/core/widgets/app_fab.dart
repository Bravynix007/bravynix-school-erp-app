import 'dart:math' as math;

import 'package:bravynix_school_erp/core/theme/app_shadows.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// The one extended floating action button of a module screen: an accent pill
/// with an icon and a label ("Add student"), bottom right, shown only when the
/// role may add. Use it as `Scaffold.floatingActionButton`. When the label no
/// longer fits on one line (large text, a narrow phone) it becomes the icon
/// alone in a 56 px circle, like the tab bar's chosen tab; the label is then its
/// spoken name and tooltip.
///
/// The button floats over the list, so give the list's last row room to scroll
/// clear of it: `AppFab.listClearance(context, label)` as the bottom padding.
class AppFab extends StatelessWidget {
  const new({required this.icon, required this.label, required this.onPressed, super.key});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  static const double _minSize = 56;

  /// Padding and gap of the pill around its 24 px icon and label.
  static double _labelRoom(BuildContext context) =>
      MediaQuery.sizeOf(context).width - 2 * AppSpacing.screenMargin - 2 * AppSpacing.lg - 24 - AppSpacing.xs;

  static TextStyle? _labelStyle(BuildContext context) => Theme.of(context).textTheme.labelLarge;

  static bool _extended(BuildContext context, String label) =>
      measureText(context, label, _labelStyle(context)) <= _labelRoom(context);

  /// Bottom padding for a list under the button: its height at the current
  /// text size, the margin the Scaffold keeps around it (which includes the home
  /// indicator when there is no bottom bar), and a gap. Call it from inside the
  /// Scaffold's body (a `Builder`), where the Scaffold has already taken the
  /// bottom inset away if a bottom bar covers it.
  static double listClearance(BuildContext context, String label) {
    final textHeight = _extended(context, label)
        ? measureTextHeight(context, label, _labelStyle(context), _labelRoom(context)) + 2 * AppSpacing.sm
        : 0.0;
    return math.max(_minSize, textHeight) +
        kFloatingActionButtonMargin +
        MediaQuery.paddingOf(context).bottom +
        AppSpacing.md;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.full);
    final extended = _extended(context, label);
    final maxWidth = MediaQuery.sizeOf(context).width - 2 * AppSpacing.screenMargin;
    final labelStyle = _labelStyle(context)?.copyWith(color: scheme.onPrimary);
    final iconWidget = Icon(icon, size: 24, color: scheme.onPrimary, semanticLabel: extended ? null : label);
    final ink = RingInkWell(
      onTap: onPressed,
      borderRadius: radius,
      ringColor: scheme.onPrimary,
      child: extended
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(child: Text(label, style: labelStyle)),
                ],
              ),
            )
          : SizedBox.square(
              dimension: _minSize,
              child: Center(child: iconWidget),
            ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: _minSize, minHeight: _minSize, maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: AppShadows.floatingNav),
        child: Material(
          color: scheme.primary,
          borderRadius: radius,
          child: Semantics(
            button: true,
            // The label is on screen when extended; the tooltip names the bare icon.
            child: extended ? ink : Tooltip(message: label, excludeFromSemantics: true, child: ink),
          ),
        ),
      ),
    );
  }
}
