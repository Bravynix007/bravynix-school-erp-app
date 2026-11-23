import 'package:equatable/equatable.dart';

/// One period of an Institution's school day in an academic year (API design 9.7): a number, its times, and whether it
/// is a break. Times are `HH:MM`, 24 hours, in the Institution's time zone.
class TimeSlot extends Equatable {
  const new({
    required this.id,
    required this.institutionId,
    required this.academicYearId,
    required this.periodNo,
    required this.startTime,
    required this.endTime,
    required this.isBreak,
    required this.version,
    this.label,
  });

  final String id;
  final String institutionId;
  final String academicYearId;

  /// 1 to 30; unique among the year's active periods, and fixed once the period is added.
  final int periodNo;
  final String startTime;
  final String endTime;

  /// A break such as lunch, which no lesson is given in.
  final bool isBreak;

  /// What the school calls it ("Lunch"), when it has a name beyond its number.
  final String? label;

  /// What a change must send back, so one made meanwhile is told apart (409 VERSION_CONFLICT).
  final int version;

  @override
  List<Object?> get props => [id, institutionId, academicYearId, periodNo, startTime, endTime, isBreak, label, version];
}
