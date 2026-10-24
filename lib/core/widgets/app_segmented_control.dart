import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/widgets/choice_chip_group.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// Two to four exclusive options side by side (Day / Week / Month). The labels
/// are measured as drawn: if the tick fits, the chosen segment shows it; if
/// only the words fit, the tick is dropped (the chosen segment is still
/// filled); if the words do not fit side by side at the current text size, the
/// options become wrapping chips instead of breaking words in half.
class AppSegmentedControl<T> extends StatelessWidget {
  const new({
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<T> options;
  final String Function(T option) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Side padding of a segment, with a little to spare.
  static const _padding = 28.0;

  /// The tick and its gap.
  static const _tick = 26.0;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    final widest = options.fold<double>(0, (widest, option) {
      final width = longestWordWidth(context, labelOf(option), style);
      return width > widest ? width : widest;
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitsPlain = options.length * (widest + _padding) <= constraints.maxWidth;
        final fitsTick = options.length * (widest + _padding + _tick) <= constraints.maxWidth;
        if (!fitsPlain) {
          return ChoiceChipGroup<T>(options: options, labelOf: labelOf, selected: selected, onSelected: onChanged);
        }
        return SegmentedButton<T>(
          segments: [
            for (final option in options) ButtonSegment<T>(value: option, label: Text(labelOf(option))),
          ],
          selected: {selected},
          showSelectedIcon: fitsTick,
          // SegmentedButton resolves the theme's `side` once for the whole control, so the segment with
          // keyboard focus is marked by its own label as well.
          style: ButtonStyle(
            textStyle: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? style?.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.focusRing,
                      decorationThickness: 2,
                    )
                  : null,
            ),
          ),
          onSelectionChanged: (values) => onChanged(values.first),
        );
      },
    );
  }
}
