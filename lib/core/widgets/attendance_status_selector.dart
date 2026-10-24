import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
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
/// narrow phone, or large text) they wrap to rows of three at the full text
/// size instead of shrinking the letters.
class AttendanceStatusSelector extends StatelessWidget {
  const new({required this.labels, required this.selected, required this.onChanged, super.key})
    : assert(labels.length == 5, 'Give a label for every AttendanceMark');

  final Map<AttendanceMark, AttendanceMarkLabel> labels;
  final AttendanceMark? selected;
  final ValueChanged<AttendanceMark> onChanged;

  /// Room a two-letter mark with its tick needs, per 1x of text size, plus the
  /// tick, its gap and the side padding.
  static const _widthPerScale = 28.0;
  static const _fixedWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
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

          if (rowCell >= _widthPerScale * scale + _fixedWidth) {
            return Row(
              children: [
                for (final mark in marks) ...[
                  if (mark != marks.first) const SizedBox(width: gap),
                  Expanded(child: button(mark)),
                ],
              ],
            );
          }
          final wrapCell = (constraints.maxWidth - gap * 2) / 3;
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

class _MarkButton extends StatelessWidget {
  const new({required this.mark, required this.label, required this.selected, required this.onTap});

  final AttendanceMark mark;
  final AttendanceMarkLabel label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label.full,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? mark.colour : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(color: selected ? mark.colour : AppColors.border),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
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
                      Text(label.short, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground)),
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
