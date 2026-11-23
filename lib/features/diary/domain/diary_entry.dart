import 'package:equatable/equatable.dart';

/// One diary entry (DIA-01): what a teacher wrote for a section about a subject on a day (API design 10.14a).
class DiaryEntry extends Equatable {
  const new({
    required this.id,
    required this.version,
    required this.sectionId,
    required this.subjectId,
    required this.subjectName,
    required this.day,
    required this.description,
    this.teacherId,
    this.teacherName,
  });

  final String id;
  final int version;
  final String sectionId;
  final String subjectId;
  final String subjectName;

  /// `YYYY-MM-DD`.
  final String day;
  final String description;

  /// Who wrote it; null for an entry an Owner or an Admin with no staff record wrote.
  final String? teacherId;
  final String? teacherName;

  @override
  List<Object?> get props => [id, version, sectionId, subjectId, subjectName, day, description, teacherId, teacherName];
}

/// What the form of an entry holds once it is complete: DIA-02 sends all of it, DIA-03 what changed.
class DiaryInput extends Equatable {
  const new({required this.subjectId, required this.day, required this.description});

  final String subjectId;

  /// `YYYY-MM-DD`.
  final String day;
  final String description;

  @override
  List<Object?> get props => [subjectId, day, description];
}
