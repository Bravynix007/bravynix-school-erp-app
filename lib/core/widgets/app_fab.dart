import 'package:bravynix_school_erp/core/theme/app_shadows.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:flutter/material.dart';

/// The one extended floating action button of a module screen: an accent pill
/// with an icon and a label ("Add student"), bottom right, shown only when the
/// role may add. Use it as `Scaffold.floatingActionButton`. The label wraps at
/// large text and the pill grows, so it is never cut.
class AppFab extends StatelessWidget {
  const new({required this.icon, required this.label, required this.onPressed, super.key});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.full);
    final maxWidth = MediaQuery.sizeOf(context).width - 2 * AppSpacing.screenMargin;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 56, minHeight: 56, maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: AppShadows.floatingNav),
        child: Material(
          color: scheme.primary,
          borderRadius: radius,
          child: Semantics(
            button: true,
            child: RingInkWell(
              onTap: onPressed,
              borderRadius: radius,
              ringColor: scheme.onPrimary,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: scheme.onPrimary),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
