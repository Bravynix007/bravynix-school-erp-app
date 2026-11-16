import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:equatable/equatable.dart';

/// Where a student sits now, in the classroom view of a teacher (API design 6.4 D7): this year's placement only.
class ClassroomPlacement extends Equatable {
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

/// A student as STU-01 and STU-03 show them to a teacher: who they are and where they sit, with no Admission ID, guardian,
/// contact or identity number.
class ClassroomStudent extends Equatable {
  const new({
    required this.id,
    required this.institutionId,
    required this.firstName,
    required this.placement,
    this.lastName,
    this.photoFileId,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
  });

  final String id;
  final String institutionId;
  final String firstName;
  final String? lastName;
  final String? photoFileId;
  final Gender? gender;

  /// `YYYY-MM-DD`.
  final String? dateOfBirth;
  final String? bloodGroup;
  final ClassroomPlacement placement;

  String get fullName => [firstName, ?lastName].join(' ');

  @override
  List<Object?> get props => [
    id,
    institutionId,
    firstName,
    lastName,
    photoFileId,
    gender,
    dateOfBirth,
    bloodGroup,
    placement,
  ];
}

/// A row of the classroom list with the name of the class and section its ID stands for.
class ClassroomEntry extends Equatable {
  const new(this.student, {this.placeName});

  final ClassroomStudent student;

  /// "Class 5 · A"; null when the section is not among those offered.
  final String? placeName;

  @override
  List<Object?> get props => [student, placeName];
}

/// The students of the sections a teacher leads or teaches this year (STU-01, STU-03). Methods throw `ApiFailure`.
abstract class ClassroomRepository {
  /// STU-01: [page] (from 1) of the students in the caller's own sections, by name; [query] searches the name and the
  /// roll number and is empty for no search, else at least two letters.
  Future<ItemsPage<ClassroomStudent>> students(String institutionId, {int page = 1, String query = ''});

  /// STU-03: one student of the caller's own sections; 403 `NOT_ASSIGNED` for any other.
  Future<ClassroomStudent> student(String id);
}
