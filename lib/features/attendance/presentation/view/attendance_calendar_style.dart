import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_calendar.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// How each status of a day is drawn and worded, on the calendar, its legend and the day's sheet.
extension DayStatusStyle on DayStatus {
  /// What a screen reader and the legend say. Half day is "Partially present" here (API design decision D3).
  String label(AppLocalizations l10n) => switch (this) {
    DayStatus.present => l10n.attendanceMarkPresent,
    DayStatus.absent => l10n.attendanceMarkAbsent,
    DayStatus.late => l10n.attendanceMarkLate,
    DayStatus.halfDay => l10n.attendanceCalendarPartial,
    DayStatus.leave => l10n.attendanceMarkLeave,
    DayStatus.holiday => l10n.attendanceHolidayUntitled,
    DayStatus.notMarked => l10n.attendanceCalendarNotMarked,
    DayStatus.notEnrolled => l10n.attendanceCalendarNotEnrolled,
  };

  /// The letters under the day number, as on the marking buttons; null for a day with no mark.
  String? mark(AppLocalizations l10n) => switch (this) {
    DayStatus.present => l10n.attendanceMarkPresentShort,
    DayStatus.absent => l10n.attendanceMarkAbsentShort,
    DayStatus.late => l10n.attendanceMarkLateShort,
    DayStatus.halfDay => l10n.attendanceMarkHalfDayShort,
    DayStatus.leave => l10n.attendanceMarkLeaveShort,
    DayStatus.holiday => l10n.attendanceCalendarHolidayShort,
    DayStatus.notMarked || DayStatus.notEnrolled => null,
  };

  /// The colour of the day; null for a day with nothing to say.
  Color? get fill => switch (this) {
    DayStatus.present => AppColors.present,
    DayStatus.absent => AppColors.absent,
    DayStatus.late => AppColors.late,
    DayStatus.halfDay => AppColors.halfDay,
    DayStatus.leave => AppColors.leave,
    DayStatus.holiday => AppColors.holiday,
    DayStatus.notMarked || DayStatus.notEnrolled => null,
  };

  /// The colour of the number on [fill].
  Color get onFill => this == DayStatus.holiday ? AppColors.onHoliday : Colors.white;

  /// The chip that names the status.
  StatusTone get tone => switch (this) {
    DayStatus.present => StatusTone.success,
    DayStatus.absent => StatusTone.error,
    DayStatus.late || DayStatus.halfDay || DayStatus.holiday => StatusTone.warning,
    DayStatus.leave => StatusTone.info,
    DayStatus.notMarked || DayStatus.notEnrolled => StatusTone.neutral,
  };
}
