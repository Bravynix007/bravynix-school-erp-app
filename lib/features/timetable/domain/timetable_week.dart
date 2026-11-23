import 'package:equatable/equatable.dart';

/// Whose week of lessons is read (TT-01 reads exactly one view).
sealed class TimetableWeek extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The week of one section: what an Owner or an Institution Admin reads and arranges.
final class SectionWeek extends TimetableWeek {
  const new(this.sectionId);

  final String sectionId;

  @override
  List<Object?> get props => [sectionId];
}

/// A teacher's own week across the sections they teach, at one Institution.
final class OwnWeek extends TimetableWeek {
  const new(this.institutionId);

  final String institutionId;

  @override
  List<Object?> get props => [institutionId];
}

/// The week of the section a parent's child sits in now.
final class ChildWeek extends TimetableWeek {
  const new(this.studentId);

  final String studentId;

  @override
  List<Object?> get props => [studentId];
}
