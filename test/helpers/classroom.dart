import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/features/classroom/domain/classroom.dart';

/// A student in Section A of Class 1 (`k1`, `e1`), as a teacher sees them.
const ashaClassroom = ClassroomStudent(
  id: 'p1',
  institutionId: 'i1',
  firstName: 'Asha',
  lastName: 'Rao',
  gender: Gender.female,
  dateOfBirth: '2015-04-12',
  bloodGroup: 'O+',
  placement: ClassroomPlacement(academicYearId: 'y1', classId: 'k1', sectionId: 'e1', rollNumber: '14'),
);

/// A student in a section the options do not offer.
const balaClassroom = ClassroomStudent(
  id: 'p2',
  institutionId: 'i1',
  firstName: 'Bala',
  placement: ClassroomPlacement(academicYearId: 'y1', classId: 'k1', sectionId: 'e9', rollNumber: '3'),
);

const ashaEntry = ClassroomEntry(ashaClassroom, placeName: 'Class 1 · Section A');
const balaEntry = ClassroomEntry(balaClassroom);

/// STU-01 and STU-03 as the API shows a student to a teacher (API design 6.4 D7): no Admission ID, version or guardians.
Map<String, Object?> classroomJson({String id = 'p1', String firstName = 'Asha'}) => {
  'id': id,
  'institutionId': 'i1',
  'firstName': firstName,
  'lastName': 'Rao',
  'photoFileId': null,
  'gender': 2,
  'dateOfBirth': '2015-04-12',
  'bloodGroup': 'O+',
  'placement': {'academicYearId': 'y1', 'classId': 'k1', 'sectionId': 'e1', 'rollNumber': '14'},
};
