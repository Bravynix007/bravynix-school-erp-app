import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/month_calendar_grid.dart';
import 'package:bravynix_school_erp/core/widgets/month_stepper.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/stat_tile.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_calendar.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/attendance_calendar_bloc.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_calendar_style.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_error_text.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/day_detail_sheet.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_day.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One student's month: the percentages, the days in their colours with a legend and the day counts, and a day that
/// opens who marked it. [onCorrect] is set for someone who may correct a register (an Owner, an Admin or a teacher): the
/// day's sheet then offers it, and answers with the register to open.
class AttendanceCalendarView extends StatelessWidget {
  const new({required this.studentId, this.onCorrect, super.key});

  final String studentId;
  final ValueChanged<SectionDay>? onCorrect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AttendanceCalendarBloc>();
    return BlocBuilder<AttendanceCalendarBloc, AttendanceCalendarState>(
      builder: (context, state) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: MonthStepper(
              month: state.month,
              onChanged: (month) => bloc.add(AttendanceCalendarMonthChosen(month)),
              previousTooltip: l10n.eventsPreviousMonth,
              nextTooltip: l10n.eventsNextMonth,
            ),
          ),
          Expanded(
            child: switch (state) {
              AttendanceCalendarLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [96, 280, 64]),
              AttendanceCalendarFailed(:final failure) when failure.code == 'OUTSIDE_ACADEMIC_YEAR' => StatePanel.empty(
                key: const Key('attendanceCalendar.outsideYear'),
                title: attendanceCalendarErrorText(l10n, failure),
              ),
              AttendanceCalendarFailed(:final failure) when failure.refused => StatePanel.forbidden(
                key: const Key('attendanceCalendar.forbidden'),
                title: attendanceCalendarErrorText(l10n, failure),
              ),
              AttendanceCalendarFailed(:final failure) => StatePanel.error(
                key: const Key('attendanceCalendar.failed'),
                title: attendanceCalendarErrorText(l10n, failure),
                actionLabel: l10n.retry,
                onAction: () => bloc.add(const AttendanceCalendarRetried()),
              ),
              AttendanceCalendarReady(:final calendar) => _Month(
                studentId: studentId,
                calendar: calendar,
                onCorrect: onCorrect,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Month extends StatelessWidget {
  const new({required this.studentId, required this.calendar, required this.onCorrect});

  final String studentId;
  final AttendanceCalendar calendar;
  final ValueChanged<SectionDay>? onCorrect;

  static String _percent(AppLocalizations l10n, double? value) => value == null
      ? l10n.attendanceCalendarNoRate
      : l10n.attendanceCalendarRate(value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString());

  /// The day as the grid draws it: its colour and letters, and what a screen reader says. A weekly off or a day before
  /// the student joined with no mark is greyed.
  CalendarCell _cell(AppLocalizations l10n, CalendarDay day) {
    final status = day.status;
    final date = Formatters.schoolDate(day.day);
    final spoken = status == DayStatus.holiday && (day.holidayTitle?.isNotEmpty ?? false)
        ? l10n.attendanceHoliday(day.holidayTitle!)
        : status.label(l10n);
    return CalendarCell(
      semanticLabel: l10n.attendanceCalendarDay(
        date,
        day.isWeekend && status == DayStatus.notMarked ? l10n.attendanceCalendarWeeklyOff : spoken,
      ),
      fill: status.fill,
      onFill: status.onFill,
      mark: status.mark(l10n),
      muted: status == DayStatus.notEnrolled || (day.isWeekend && status == DayStatus.notMarked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final first = Formatters.parseDay('${calendar.month}-01')!;
    final summary = calendar.summary;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        StatTileRow(
          tiles: [
            StatTile(
              key: const Key('attendanceCalendar.month'),
              label: l10n.attendanceCalendarMonthRate,
              value: _percent(l10n, summary.percentage),
            ),
            StatTile(
              key: const Key('attendanceCalendar.year'),
              label: l10n.attendanceCalendarYearRate,
              value: _percent(l10n, calendar.yearToDatePercentage),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        MonthCalendarGrid(
          month: first,
          cellOf: (day) => _cell(l10n, calendar.days[day - 1]),
          onDay: (day) async {
            final focus = await showDayDetailSheet(
              context,
              studentId: studentId,
              day: calendar.days[day - 1].day,
              canCorrect: onCorrect != null,
            );
            if (focus != null) onCorrect?.call(focus);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CalendarLegend(
          entries: [
            for (final status in DayStatus.values)
              if (status != DayStatus.notEnrolled)
                CalendarLegendEntry(
                  label: l10n.attendanceCalendarLegend(status.label(l10n), summary.count(status)),
                  fill: status.fill,
                ),
          ],
        ),
      ],
    );
  }
}
