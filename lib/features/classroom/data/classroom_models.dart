import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/classroom/domain/classroom.dart';

/// JSON → domain for the classroom view of STU-01 and STU-03. Unknown fields are ignored, as /v1 only ever adds fields
/// (API design 5.2).
abstract final class ClassroomModels {
  static ClassroomPlacement _placement(Object? raw) {
    final json = jsonObject(raw);
    return ClassroomPlacement(
      academicYearId: json['academicYearId'] as String,
      classId: json['classId'] as String,
      sectionId: json['sectionId'] as String,
      rollNumber: json['rollNumber'] as String,
    );
  }

  static ClassroomStudent student(Object? raw) {
    final json = jsonObject(raw);
    return ClassroomStudent(
      id: json['id'] as String,
      institutionId: json['institutionId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      photoFileId: json['photoFileId'] as String?,
      gender: Gender.fromCode(json['gender']),
      dateOfBirth: json['dateOfBirth'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      placement: _placement(json['placement']),
    );
  }

  static List<ClassroomStudent> students(Object? raw) => [for (final item in jsonList(raw)) student(item)];
}
