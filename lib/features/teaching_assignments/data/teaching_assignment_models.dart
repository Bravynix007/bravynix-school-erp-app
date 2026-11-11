import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignment.dart';

/// JSON → domain for ASG-01 and ASG-02. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class TeachingAssignmentModels {
  static TeachingAssignment assignment(Object? raw) {
    final json = jsonObject(raw);
    final section = jsonObject(json['section']);
    final subject = jsonObject(json['subject']);
    return TeachingAssignment(
      id: json['id'] as String,
      academicYearId: json['academicYearId'] as String,
      sectionId: section['id'] as String,
      sectionName: '${section['className']} · ${section['displayName']}',
      subjectId: subject['id'] as String,
      subjectName: subject['name'] as String,
    );
  }

  static List<TeachingAssignment> assignments(Object? raw) => [for (final item in jsonList(raw)) assignment(item)];
}
