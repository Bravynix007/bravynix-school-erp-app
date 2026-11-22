import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// How one day is drawn on a [MonthCalendarGrid]: its fill, the short [mark] under the number (colour is never the only
/// cue), and what a screen reader says for it.
class CalendarCell {
  const new({
    required this.semanticLabel,
    this.fill,
    this.onFill = AppColors.ink,
    this.mark,
    this.muted = false,
  });

  final String semanticLabel;

  /// The colour of the day, or null for a day with nothing to say.
  final Color? fill;

  /// The colour of the number and the mark on [fill].
  final Color onFill;
  final String? mark;

  /// A day that does not count (a weekly off, or before the student joined): drawn in a lighter ink.
  final bool muted;
}

/// A month as a grid of days, Monday first, for the days of one month. [cellOf] draws day 1 to the last day of [month]
/// and [onDay] answers the day tapped. Every day is a 48 px target that grows with the text, so it reads whole at a
/// large text size.
class MonthCalendarGrid extends StatelessWidget {
  const new({required this.month, required this.cellOf, required this.onDay, super.key});

  /// Any day of the month shown.
  final DateTime month;
  final CalendarCell Function(int day) cellOf;
  final ValueChanged<int> onDay;

  static const double _gap = AppSpacing.xxs;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final lead = DateTime(month.year, month.month).weekday - DateTime.monday;
    final length = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((lead + length) / DateTime.daysPerWeek).ceil();
    final text = Theme.of(context).textTheme;
    // Any Monday, to draw the names of the week from.
    final monday = DateTime(2024);
    return Column(
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 0; i < DateTime.daysPerWeek; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat.E(locale).format(monday.add(Duration(days: i))).characters.first,
                      style: text.labelMedium?.copyWith(color: AppColors.inkSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: _gap),
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) const SizedBox(height: _gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var column = 0; column < DateTime.daysPerWeek; column++) ...[
                  if (column > 0) const SizedBox(width: _gap),
                  Expanded(child: _cellAt(context, row * DateTime.daysPerWeek + column - lead + 1, length)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _cellAt(BuildContext context, int day, int length) {
    if (day < 1 || day > length) return const SizedBox.shrink();
    final cell = cellOf(day);
    final text = Theme.of(context).textTheme;
    final ink = cell.fill == null ? (cell.muted ? AppColors.disabled : AppColors.ink) : cell.onFill;
    return Semantics(
      button: true,
      label: cell.semanticLabel,
      onTap: () => onDay(day),
      child: ExcludeSemantics(
        child: Material(
          key: ValueKey('calendar.day.$day'),
          color: cell.fill ?? AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            side: cell.fill == null ? const BorderSide(color: AppColors.border) : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => onDay(day),
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$day', style: text.titleSmall?.copyWith(color: ink)),
                        if (cell.mark case final mark?) Text(mark, style: text.labelSmall?.copyWith(color: ink)),
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

/// One line of a legend: what a colour of the calendar means, with the days of the month under it written in.
class CalendarLegendEntry {
  const new({required this.label, required this.fill});

  final String label;
  final Color? fill;
}

/// The colours of a [MonthCalendarGrid] with their names.
class CalendarLegend extends StatelessWidget {
  const new({required this.entries, super.key});

  final List<CalendarLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: entry.fill ?? AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: entry.fill == null ? Border.all(color: AppColors.fieldBorder) : null,
                  ),
                  child: const SizedBox.square(dimension: 14),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(entry.label, style: text.bodySmall),
            ],
          ),
      ],
    );
  }
}
