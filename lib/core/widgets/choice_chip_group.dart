import 'package:bravynix_school_erp/core/a11y/reduce_motion.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// Pick one of a few options shown as chips that wrap onto more lines, or, when
/// [scrollable], in one row that scrolls sideways (a tapped chip is brought fully
/// into view, and each label keeps to one line). The chosen chip gets a tick as
/// well as the accent wash. A chip grows taller
/// when its label wraps (Material's own chip keeps one line of height, which
/// cuts a wrapped label off at large text sizes). When the tick would leave no
/// room for the longest word of the label on the line, the tick is dropped (the
/// chosen chip is still filled and marked for screen readers), so a word is
/// never broken in half.
class ChoiceChipGroup<T> extends StatelessWidget {
  const new({
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
    this.scrollable = false,
    super.key,
  });

  final List<T> options;
  final String Function(T option) labelOf;
  final T? selected;
  final ValueChanged<T> onSelected;

  /// One row that scrolls sideways instead of lines that wrap.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final option in options)
        MergeSemantics(
          child: Semantics(
            button: true,
            selected: option == selected,
            inMutuallyExclusiveGroup: true,
            child: _OptionChip(
              label: labelOf(option),
              selected: option == selected,
              scrollable: scrollable,
              onTap: () => onSelected(option),
            ),
          ),
        ),
    ];
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (index, chip) in chips.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.xs),
              chip,
            ],
          ],
        ),
      );
    }
    return Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: chips);
  }
}

class _OptionChip extends StatelessWidget {
  const new({required this.label, required this.selected, required this.scrollable, required this.onTap});

  final String label;
  final bool selected;
  final bool scrollable;
  final VoidCallback onTap;

  static const double _tickIcon = 18;

  /// The tick and its gap.
  static const double _tick = _tickIcon + AppSpacing.xs;

  /// Moves the row only as far as it takes for the whole chip to show, once the chip has grown to hold its tick. A
  /// chip that is already whole leaves the row where it is; one cut off at the start is brought in from the start, any
  /// other from the end.
  void _showWhole(BuildContext context) {
    final duration = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 200);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final viewport = Scrollable.of(context).context.findRenderObject()! as RenderBox;
      final cutAtStart =
          (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero, ancestor: viewport).dx < 0;
      Scrollable.ensureVisible(
        context,
        duration: duration,
        alignmentPolicy: cutAtStart
            ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
            : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = BorderRadius.circular(AppRadius.chip);
    final foreground = selected ? scheme.onSecondaryContainer : scheme.onSurface;
    final labelStyle = theme.textTheme.labelLarge;
    final word = longestWordWidth(context, label, labelStyle);
    return Material(
      // The hairline is painted under the focus ring, not over its outer pixel.
      borderOnForeground: false,
      color: selected ? scheme.secondaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: shape,
        side: selected ? BorderSide.none : const BorderSide(color: AppColors.border),
      ),
      child: RingInkWell(
        onTap: () {
          onTap();
          if (scrollable) _showWhole(context);
        },
        borderRadius: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSpacing.minTouchTarget, minHeight: AppSpacing.minTouchTarget),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showTick = selected && word + 2 * AppSpacing.sm + _tick <= constraints.maxWidth;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showTick) ...[
                      Icon(Icons.check, size: _tickIcon, color: foreground),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(label, style: labelStyle?.copyWith(color: foreground)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
