import 'package:equatable/equatable.dart';

/// What a day of a student's month is (API design 10.13). Strings in the API, because it is a view worked out from the
/// registers, not a stored code.
enum DayStatus {
  present('present'),
  absent('absent'),
  late('late'),
  halfDay('half_day'),
  leave('leave'),
  holiday('holiday'),
  notMarked('not_marked'),
  notEnrolled('not_enrolled');

  new(this.code);

  final String code;

  /// The status the API names, or null for one the app does not know.
  static DayStatus? fromCode(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    return null;
  }
}

class CalendarDay extends Equatable {
  const new({required this.day, required this.status, required this.isWeekend, this.holidayTitle});

  /// `YYYY-MM-DD`.
  final String day;
  final DayStatus status;
  final bool isWeekend;
  final String? holidayTitle;

  @override
  List<Object?> get props => [day, status, isWeekend, holidayTitle];
}

/// The days of each status in a month. [percentage] is null when no day was marked.
class MonthSummary extends Equatable {
  const new({
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.halfDays,
    required this.leaveDays,
    required this.holidays,
    required this.notMarkedDays,
    this.percentage,
  });

  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int halfDays;
  final int leaveDays;
  final int holidays;
  final int notMarkedDays;
  final double? percentage;

  /// The days counted under [status], which is none for a day the student was not on the roll.
  int count(DayStatus status) => switch (status) {
    DayStatus.present => presentDays,
    DayStatus.absent => absentDays,
    DayStatus.late => lateDays,
    DayStatus.halfDay => halfDays,
    DayStatus.leave => leaveDays,
    DayStatus.holiday => holidays,
    DayStatus.notMarked => notMarkedDays,
    DayStatus.notEnrolled => 0,
  };

  @override
  List<Object?> get props => [
    presentDays,
    absentDays,
    lateDays,
    halfDays,
    leaveDays,
    holidays,
    notMarkedDays,
    percentage,
  ];
}

/// ATT-07: a month of one student.
class AttendanceCalendar extends Equatable {
  const new({required this.month, required this.summary, required this.days, this.yearToDatePercentage});

  /// `YYYY-MM`.
  final String month;
  final MonthSummary summary;

  /// The share attended from the year's first day to today; null when no day was marked.
  final double? yearToDatePercentage;
  final List<CalendarDay> days;

  @override
  List<Object?> get props => [month, summary, yearToDatePercentage, days];
}

/// Where a student sat on a day. A parent is not told the names ([name], [className] are null).
class DaySection extends Equatable {
  const new({required this.id, this.name, this.className});

  final String id;
  final String? name;
  final String? className;

  @override
  List<Object?> get props => [id, name, className];
}

/// ATT-08: one day of one student, and who marked it.
class DayDetail extends Equatable {
  const new({
    required this.day,
    required this.status,
    required this.isWeekend,
    this.holidayTitle,
    this.section,
    this.markedBy,
    this.markedAt,
    this.lastCorrectedAt,
  });

  final String day;
  final DayStatus status;
  final bool isWeekend;
  final String? holidayTitle;
  final DaySection? section;

  /// The name of whoever took the register, and when; null when none was taken.
  final String? markedBy;
  final DateTime? markedAt;
  final DateTime? lastCorrectedAt;

  @override
  List<Object?> get props => [day, status, isWeekend, holidayTitle, section, markedBy, markedAt, lastCorrectedAt];
}
