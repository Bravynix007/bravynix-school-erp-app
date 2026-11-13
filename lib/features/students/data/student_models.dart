import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';

/// JSON → domain for STU-01. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class StudentModels {
  static StudentPlacement _placement(Object? raw) {
    final json = jsonObject(raw);
    return StudentPlacement(
      academicYearId: json['academicYearId'] as String,
      classId: json['classId'] as String,
      sectionId: json['sectionId'] as String,
      rollNumber: json['rollNumber'] as String,
    );
  }

  static StudentSummary summary(Object? raw) {
    final json = jsonObject(raw);
    return StudentSummary(
      id: json['id'] as String,
      institutionId: json['institutionId'] as String,
      admissionNo: json['admissionNo'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      photoFileId: json['photoFileId'] as String?,
      placement: _placement(json['placement']),
      isBlocked: json['isBlocked'] as bool,
      version: (json['version'] as num).toInt(),
    );
  }

  static List<StudentSummary> summaries(Object? raw) => [for (final item in jsonList(raw)) summary(item)];
}
