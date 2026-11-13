import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';

import 'academic_years.dart';

/// Asha Rao: in Class 1 · Section A (section e1) of the current year, roll 14, with an Admission ID.
const asha = StudentSummary(
  id: 'p1',
  institutionId: 'i1',
  admissionNo: 'A-2026-014',
  firstName: 'Asha',
  lastName: 'Rao',
  placement: StudentPlacement(academicYearId: 'y1', classId: 'c1', sectionId: 'e1', rollNumber: '14'),
  isBlocked: false,
  version: 3,
);

/// A row with only what is required, in a section no longer offered, and blocked.
const bala = StudentSummary(
  id: 'p2',
  institutionId: 'i1',
  firstName: 'Bala',
  placement: StudentPlacement(academicYearId: 'y1', classId: 'c9', sectionId: 'e9', rollNumber: '2'),
  isBlocked: true,
  version: 1,
);

const ashaEntry = StudentListEntry(asha, placeName: 'Class 1 · Section A');
const balaEntry = StudentListEntry(bala);

/// The years, classes and sections the filters choose from.
const studentOptions = SectionOptions(
  years: [earlierYear, currentYear],
  classes: [
    ClassChoice(id: 'c1', name: 'Class 1'),
    ClassChoice(id: 'c2', name: 'Class 2'),
  ],
  sections: [
    SectionChoice(id: 'e1', name: 'Class 1 · Section A', classId: 'c1'),
    SectionChoice(id: 'e2', name: 'Class 1 · Blue', classId: 'c1'),
    SectionChoice(id: 'e3', name: 'Class 2 · Section A', classId: 'c2'),
  ],
);

Map<String, Object?> studentRow({
  String id = 'p1',
  String? admissionNo = 'A-2026-014',
  String firstName = 'Asha',
  String? lastName = 'Rao',
  bool isBlocked = false,
  int version = 3,
}) => {
  'id': id,
  'institutionId': 'i1',
  'admissionNo': admissionNo,
  'firstName': firstName,
  'lastName': lastName,
  'photoFileId': null,
  'placement': {
    'enrolmentId': 'n1',
    'academicYearId': 'y1',
    'classId': 'c1',
    'sectionId': 'e1',
    'rollNumber': '14',
    'enrolledDate': '2026-06-01',
    'startDate': '2026-06-01',
  },
  'isBlocked': isBlocked,
  'status': 1,
  'version': version,
};
