import 'package:equatable/equatable.dart';

/// Where a student sits: the section they were last placed in, or the one of the year asked for (STU-01).
class StudentPlacement extends Equatable {
  const new({
    required this.academicYearId,
    required this.classId,
    required this.sectionId,
    required this.rollNumber,
  });

  final String academicYearId;
  final String classId;
  final String sectionId;
  final String rollNumber;

  @override
  List<Object?> get props => [academicYearId, classId, sectionId, rollNumber];
}

/// One row of the students list (STU-01); the profile has the rest. The class and section are IDs: the Institution's
/// sections give the names.
class StudentSummary extends Equatable {
  const new({
    required this.id,
    required this.institutionId,
    required this.firstName,
    required this.placement,
    required this.isBlocked,
    required this.version,
    this.lastName,
    this.admissionNo,
    this.photoFileId,
  });

  final String id;
  final String institutionId;
  final String? admissionNo;
  final String firstName;
  final String? lastName;
  final String? photoFileId;
  final StudentPlacement placement;

  /// The guardians' access to this child is blocked (STU-06).
  final bool isBlocked;
  final int version;

  String get fullName => [firstName, ?lastName].join(' ');

  @override
  List<Object?> get props => [
    id,
    institutionId,
    admissionNo,
    firstName,
    lastName,
    photoFileId,
    placement,
    isBlocked,
    version,
  ];
}

/// A row of the list with the name of the class and section its IDs stand for.
class StudentListEntry extends Equatable {
  const new(this.summary, {this.placeName});

  final StudentSummary summary;

  /// "Class 5 · A"; null when the section is no longer offered (it was deactivated).
  final String? placeName;

  @override
  List<Object?> get props => [summary, placeName];
}

/// What the list is narrowed to: a year, a class, a section; each null for no narrowing (STU-01).
class StudentFilter extends Equatable {
  const new({this.academicYearId, this.classId, this.sectionId});

  final String? academicYearId;
  final String? classId;
  final String? sectionId;

  bool get isEmpty => academicYearId == null && classId == null && sectionId == null;

  @override
  List<Object?> get props => [academicYearId, classId, sectionId];
}

/// Why a student is deactivated (STU-05): 1 left the Institution, 2 the record was made by mistake, 3 other.
enum LeavingReason {
  left(1),
  mistake(2),
  other(3);

  new(this.code);

  final int code;
}
