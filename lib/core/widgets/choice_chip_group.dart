import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:flutter/material.dart';

/// Pick one of a few options shown as chips that wrap onto more lines. The
/// chosen chip gets a tick as well as the accent wash. A chip grows taller
/// when its label wraps (Material's own chip keeps one line of height, which
/// cuts a wrapped label off at large text sizes).
class ChoiceChipGroup<T> extends StatelessWidget {
  const new({
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<T> options;
  final String Function(T option) labelOf;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final option in options)
          MergeSemantics(
            child: Semantics(
              button: true,
              selected: option == selected,
              inMutuallyExclusiveGroup: true,
              child: _OptionChip(
                label: labelOf(option),
                selected: option == selected,
                onTap: () => onSelected(option),
              ),
            ),
          ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = BorderRadius.circular(AppRadius.chip);
    final foreground = selected ? scheme.onSecondaryContainer : scheme.onSurface;
    return Material(
      // The hairline is painted under the focus ring, not over its outer pixel.
      borderOnForeground: false,
      color: selected ? scheme.secondaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: shape,
        side: selected ? BorderSide.none : const BorderSide(color: AppColors.border),
      ),
      child: RingInkWell(
        onTap: onTap,
        borderRadius: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSpacing.minTouchTarget, minHeight: AppSpacing.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Icon(Icons.check, size: 18, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
