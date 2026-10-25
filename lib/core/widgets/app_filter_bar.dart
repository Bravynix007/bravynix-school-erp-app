import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:flutter/material.dart';

/// One filter of an [AppFilterBar]: a name ("Class"), and what is chosen
/// ("7-B"), or `null` when it is not applied. Tapping it opens the caller's
/// picker (a bottom sheet of options).
class AppFilter {
  const new({required this.label, required this.onTap, this.value});

  final String label;
  final String? value;
  final VoidCallback onTap;
}

/// The filters above a list, as pills that wrap onto more lines (never a
/// sideways scroll that hides some of them), and a "Clear" button once any is
/// applied. An applied pill shows its value, a tick and the accent wash; the
/// words, not the colour alone, say which are on.
class AppFilterBar extends StatelessWidget {
  const new({required this.filters, required this.clearLabel, this.onClear, super.key});

  final List<AppFilter> filters;

  /// "Clear filters".
  final String clearLabel;

  /// Called by the Clear button; the button shows only when some filter has a value.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final anyApplied = filters.any((f) => f.value != null);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final filter in filters) _FilterPill(filter: filter),
        if (anyApplied && onClear != null) TextButton(onPressed: onClear, child: Text(clearLabel)),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const new({required this.filter});

  final AppFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final applied = filter.value != null;
    final shape = BorderRadius.circular(AppRadius.chip);
    final foreground = applied ? scheme.onSecondaryContainer : scheme.onSurface;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: applied,
        child: Material(
          borderOnForeground: false,
          color: applied ? scheme.secondaryContainer : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: shape,
            side: applied ? BorderSide.none : const BorderSide(color: AppColors.border),
          ),
          child: RingInkWell(
            onTap: filter.onTap,
            borderRadius: shape,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.xs,
                  top: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (applied) ...[
                      Icon(Icons.check, size: 18, color: foreground),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        applied ? '${filter.label}: ${filter.value}' : filter.label,
                        style: theme.textTheme.labelLarge?.copyWith(color: foreground),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: foreground),
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
