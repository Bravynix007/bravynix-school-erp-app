import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';

/// Today is the 17th of November 2026 in IST (04:00 UTC).
final today = DateTime.utc(2026, 11, 17, 4);

/// An entry R. Nair (staff `t1`) wrote for Mathematics.
const mathsEntry = DiaryEntry(
  id: 'd1',
  version: 1,
  sectionId: 'sec1',
  subjectId: 'u1',
  subjectName: 'Mathematics',
  day: '2026-11-17',
  description: 'Exercise 4.2, questions 1 to 5.',
  teacherId: 't1',
  teacherName: 'R. Nair',
);

/// An entry another teacher (`t2`) wrote.
const artEntry = DiaryEntry(
  id: 'd2',
  version: 3,
  sectionId: 'sec1',
  subjectId: 'u2',
  subjectName: 'Art',
  day: '2026-11-17',
  description: 'Bring crayons.',
  teacherId: 't2',
  teacherName: 'S. Iyer',
);

/// An entry an Admin with no staff record wrote.
const noticeEntry = DiaryEntry(
  id: 'd3',
  version: 1,
  sectionId: 'sec1',
  subjectId: 'u1',
  subjectName: 'Mathematics',
  day: '2026-11-17',
  description: 'Tomorrow is a half day.',
);

Map<String, Object?> diaryJson({
  String id = 'd1',
  int version = 1,
  String subjectId = 'u1',
  String subject = 'Mathematics',
  String day = '2026-11-17',
  String description = 'Exercise 4.2, questions 1 to 5.',
  Map<String, Object?>? teacher = const {'id': 't1', 'displayName': 'R. Nair'},
}) => {
  'id': id,
  'version': version,
  'institutionId': 'i1',
  'academicYearId': 'y1',
  'sectionId': 'sec1',
  'sectionName': 'A',
  'className': '7th',
  'subject': {'id': subjectId, 'name': subject},
  'diaryDate': day,
  'description': description,
  'teacher': teacher,
  'status': 1,
  'createdBy': {'id': 'p1', 'displayName': 'R. Nair'},
};
