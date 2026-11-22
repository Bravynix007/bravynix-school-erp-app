import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:equatable/equatable.dart';

/// The classes and sections a marker picks from (ATT-09).
class MarkingSections extends Equatable {
  const new({required this.classes, required this.sections});

  final List<ClassChoice> classes;
  final List<SectionChoice> sections;

  @override
  List<Object?> get props => [classes, sections];
}

/// A student whose mark is not Present, or changed: what ATT-02 and ATT-05 are sent.
class MarkChange extends Equatable {
  const new({required this.enrolmentId, required this.mark});

  final String enrolmentId;
  final AttendanceMark mark;

  @override
  List<Object?> get props => [enrolmentId, mark];
}

/// Taking a section's attendance for a day, correcting it and voiding it (API design 10.10 to 10.12a).
abstract interface class AttendanceRepository {
  /// ATT-09: the open classes of the Institution and their sections, every one of them.
  Future<MarkingSections> sections(String institutionId);

  /// ATT-01: the roll of a section on a day, `YYYY-MM-DD`.
  Future<AttendanceRoster> roster(String sectionId, String day);

  /// ATT-02: the register of a section for a day. Only the students who are not Present are named; [rosterCount] is
  /// the number of students the screen showed. [idempotencyKey] makes a repeat of the same attempt, after an answer
  /// that was lost, find the first one done. Answers the number of students the register counts.
  Future<int> submit({
    required String sectionId,
    required String day,
    required int rosterCount,
    required List<MarkChange> exceptions,
    required String idempotencyKey,
  });

  /// ATT-05: changes marks of the register that [version] was read at. A change to Present is allowed.
  Future<void> correct(String registerId, int version, List<MarkChange> changes);

  /// ATT-06: voids the register, for a [reason] of 5 to 500 characters, so the day is free to be taken again.
  Future<void> voidRegister(String registerId, int version, String reason);
}
