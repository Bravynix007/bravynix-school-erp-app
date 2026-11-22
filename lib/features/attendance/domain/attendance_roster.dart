import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:equatable/equatable.dart';

/// The numbers the API gives the five marks (API design 10.10): 1 Present to 5 Leave.
extension AttendanceMarkCode on AttendanceMark {
  int get code => index + 1;

  /// The mark with this number; null for one the app does not know.
  static AttendanceMark? fromCode(int code) =>
      code >= 1 && code <= AttendanceMark.values.length ? AttendanceMark.values[code - 1] : null;
}

/// One student on a section's roll for a day, with the mark they have: Present until a register says otherwise.
class RosterStudent extends Equatable {
  const new({
    required this.studentId,
    required this.enrolmentId,
    required this.rollNumber,
    required this.firstName,
    required this.mark,
    this.lastName,
  });

  final String studentId;

  /// What a register names a student by (ATT-02).
  final String enrolmentId;
  final String rollNumber;
  final String firstName;
  final String? lastName;
  final AttendanceMark mark;

  String get fullName => [firstName, ?lastName].join(' ');

  @override
  List<Object?> get props => [studentId, enrolmentId, rollNumber, firstName, lastName, mark];
}

/// The register already taken for the day: who took it, and when. Its [version] is what a correction sends back.
class TakenRegister extends Equatable {
  const new({required this.id, required this.version, required this.takenBy, required this.takenAt});

  final String id;
  final int version;
  final String takenBy;
  final DateTime takenAt;

  @override
  List<Object?> get props => [id, version, takenBy, takenAt];
}

/// ATT-01: a section's students on a day, and what may be done with the day.
class AttendanceRoster extends Equatable {
  const new({
    required this.sectionId,
    required this.day,
    required this.isHoliday,
    required this.canMark,
    required this.students,
    this.holidayTitle,
    this.taken,
  });

  final String sectionId;

  /// `YYYY-MM-DD`.
  final String day;
  final bool isHoliday;
  final String? holidayTitle;

  /// True for a caller who may take the register now: the day has come, is in the year, is no holiday, none is taken.
  final bool canMark;
  final TakenRegister? taken;
  final List<RosterStudent> students;

  @override
  List<Object?> get props => [sectionId, day, isHoliday, holidayTitle, canMark, taken, students];
}

/// A register as the server counted it, after it was taken (ATT-02) or corrected (ATT-05).
class RegisterCounts extends Equatable {
  const new({
    required this.id,
    required this.version,
    required this.rosterCount,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.halfDayCount,
    required this.leaveCount,
  });

  final String id;
  final int version;
  final int rosterCount;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int halfDayCount;
  final int leaveCount;

  @override
  List<Object?> get props => [
    id,
    version,
    rosterCount,
    presentCount,
    absentCount,
    lateCount,
    halfDayCount,
    leaveCount,
  ];
}
