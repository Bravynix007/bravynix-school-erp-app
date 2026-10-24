import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Pick one of a few options shown as chips that wrap onto more lines. The
/// chosen chip gets a tick as well as the accent wash.
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
              inMutuallyExclusiveGroup: true,
              child: ChoiceChip(
                label: Text(labelOf(option)),
                selected: option == selected,
                showCheckmark: true,
                onSelected: (_) => onSelected(option),
              ),
            ),
          ),
      ],
    );
  }
}
