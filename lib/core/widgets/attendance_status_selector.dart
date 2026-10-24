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
class AttendanceStatusSelector extends StatelessWidget {
  const new({required this.labels, required this.selected, required this.onChanged, super.key})
    : assert(labels.length == 5, 'Give a label for every AttendanceMark');

  final Map<AttendanceMark, AttendanceMarkLabel> labels;
  final AttendanceMark? selected;
  final ValueChanged<AttendanceMark> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final mark in AttendanceMark.values) ...[
          if (mark != AttendanceMark.present) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _MarkButton(
              mark: mark,
              label: labels[mark]!,
              selected: mark == selected,
              onTap: () => onChanged(mark),
            ),
          ),
        ],
      ],
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
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
      ),
    );
  }
}
