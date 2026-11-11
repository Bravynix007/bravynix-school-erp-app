import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignment.dart';

/// Kavya's teaching of Mathematics in Section A of Class 1, in the current year y1.
const mathsInClass1A = TeachingAssignment(
  id: 'g1',
  academicYearId: 'y1',
  sectionId: 'e1',
  sectionName: 'Class 1 · Section A',
  subjectId: 'u1',
  subjectName: 'Mathematics',
);

/// The same subject in the other section of the class.
const mathsInClass1Blue = TeachingAssignment(
  id: 'g2',
  academicYearId: 'y1',
  sectionId: 'e2',
  sectionName: 'Class 1 · Blue',
  subjectId: 'u1',
  subjectName: 'Mathematics',
);

/// An item of ASG-01 and ASG-02, as the API sends it.
Map<String, Object?> assignmentJson({
  String id = 'g1',
  String academicYearId = 'y1',
  String sectionId = 'e1',
  String className = 'Class 1',
  String sectionName = 'Section A',
  String subjectId = 'u1',
  String subjectName = 'Mathematics',
}) => {
  'id': id,
  'institutionId': 'i1',
  'academicYearId': academicYearId,
  'section': {'id': sectionId, 'displayName': sectionName, 'classId': 'k1', 'className': className},
  'subject': {'id': subjectId, 'name': subjectName},
  'staffMember': {'id': 'f1', 'firstName': 'Kavya', 'lastName': 'Nair'},
  'createdAt': '2026-11-01T10:00:00.000Z',
};
