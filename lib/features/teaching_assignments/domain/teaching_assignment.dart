import 'package:equatable/equatable.dart';

/// A teacher's place in a section for a subject in an academic year (ASG-01): who teaches what, where.
class TeachingAssignment extends Equatable {
  const new({
    required this.id,
    required this.academicYearId,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
  });

  final String id;
  final String academicYearId;
  final String sectionId;

  /// The class and the section, such as "Class 5 · A".
  final String sectionName;
  final String subjectId;
  final String subjectName;

  @override
  List<Object?> get props => [id, academicYearId, sectionId, sectionName, subjectId, subjectName];
}
