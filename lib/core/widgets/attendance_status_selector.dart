import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// The five marks a teacher can give a student for a day (PRD attendance).
enum AttendanceMark {
  present(AppColors.present),
  absent(AppColors.absent),
  late(AppColors.late),
  halfDay(AppColors.halfDay),
  leave(AppColors.leave);

  new(this.colour);

  final Color colour;
}

/// What a mark says: `short` is drawn on the button (P, A, L, HD, LV) and
/// `full` is what a screen reader speaks.
class AttendanceMarkLabel {
  const new({required this.short, required this.full});

  final String short;
  final String full;
}

/// One tap to mark a student. The chosen mark fills with its colour and shows
/// a tick; the letters stay on every button, so colour is never the only cue.
/// Five buttons share one row while the letters fit. When they would not (a
/// narrow phone, or large text) they wrap to rows of three, two or one at the full
/// text size instead of shrinking the letters.
class AttendanceStatusSelector extends StatelessWidget {
  const new({required this.labels, required this.selected, required this.onChanged, super.key})
    : assert(labels.length == 5, 'Give a label for every AttendanceMark');

  final Map<AttendanceMark, AttendanceMarkLabel> labels;
  final AttendanceMark? selected;
  final ValueChanged<AttendanceMark> onChanged;

  /// The tick, its gap, the side padding and the border.
  static const double _chrome = 16.0 + 2 + AppSpacing.xxs * 2 + 2;

  @override
  Widget build(BuildContext context) {
    // Measure the widest short label as it will be drawn (any script, any text
    // size) rather than guessing from the letter count.
    final style = Theme.of(context).textTheme.labelLarge;
    final widest = labels.values.fold<double>(0, (widest, label) {
      final width = measureText(context, label.short, style);
      return width > widest ? width : widest;
    });
    return Semantics(
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.xs;
          const marks = AttendanceMark.values;
          final rowCell = (constraints.maxWidth - gap * (marks.length - 1)) / marks.length;
          Widget button(AttendanceMark mark) => _MarkButton(
            mark: mark,
            label: labels[mark]!,
            selected: mark == selected,
            onTap: () => onChanged(mark),
          );

          if (rowCell >= widest + _chrome) {
            return Row(
              children: [
                for (final mark in marks) ...[
                  if (mark != marks.first) const SizedBox(width: gap),
                  Expanded(child: button(mark)),
                ],
              ],
            );
          }
          // Too wide for one row: three, then two, then one per row.
          var columns = 3;
          while (columns > 1 && (constraints.maxWidth - gap * (columns - 1)) / columns < widest + _chrome) {
            columns -= 1;
          }
          final wrapCell = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final mark in marks) SizedBox(width: wrapCell, child: button(mark)),
            ],
          );
        },
      ),
    );
  }
}

class _MarkButton extends StatefulWidget {
  const new({required this.mark, required this.label, required this.selected, required this.onTap});

  final AttendanceMark mark;
  final AttendanceMarkLabel label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MarkButton> createState() => _MarkButtonState();
}

class _MarkButtonState extends State<_MarkButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final foreground = selected ? Colors.white : AppColors.ink;
    final showRing = _focused && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button));
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      focusable: true,
      focused: _focused,
      label: widget.label.full,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? widget.mark.colour : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: showRing
                ? const BorderSide(color: AppColors.focusRing, width: 2)
                : BorderSide(color: selected ? widget.mark.colour : AppColors.border),
          ),
          child: InkWell(
            onTap: widget.onTap,
            customBorder: shape,
            onFocusChange: (value) => setState(() => _focused = value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
              child: Center(
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs, vertical: AppSpacing.xxs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[Icon(Icons.check, size: 16, color: foreground), const SizedBox(width: 2)],
                      Flexible(
                        child: Text(
                          widget.label.short,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
