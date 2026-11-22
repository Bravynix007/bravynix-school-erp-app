import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';

const asha = RosterStudent(
  enrolmentId: 'e1',
  rollNumber: '1',
  firstName: 'Asha',
  lastName: 'Rao',
  mark: AttendanceMark.present,
);
const bea = RosterStudent(
  enrolmentId: 'e2',
  rollNumber: '2',
  firstName: 'Bea',
  mark: AttendanceMark.present,
);
const cy = RosterStudent(
  enrolmentId: 'e3',
  rollNumber: '3',
  firstName: 'Cy',
  lastName: 'Nair',
  mark: AttendanceMark.present,
);

/// A day nobody has marked: everyone is Present and the caller may mark it.
const openRoll = AttendanceRoster(
  sectionId: 'sec1',
  day: '2026-11-17',
  isHoliday: false,
  canMark: true,
  students: [asha, bea, cy],
);

/// The same section on a day whose register is taken: Bea is Absent.
final takenRoll = AttendanceRoster(
  sectionId: 'sec1',
  day: '2026-11-17',
  isHoliday: false,
  canMark: false,
  taken: TakenRegister(id: 'r1', version: 2, takenBy: 'R. Nair', takenAt: DateTime.utc(2026, 11, 17, 4, 30)),
  students: const [
    asha,
    RosterStudent(
      enrolmentId: 'e2',
      rollNumber: '2',
      firstName: 'Bea',
      mark: AttendanceMark.absent,
    ),
    cy,
  ],
);

const holidayRoll = AttendanceRoster(
  sectionId: 'sec1',
  day: '2026-11-17',
  isHoliday: true,
  holidayTitle: 'Founders Day',
  canMark: false,
  students: [asha],
);

const sevenA = SectionChoice(id: 'sec1', name: '7th · A', classId: 'c7');
const sevenB = SectionChoice(id: 'sec2', name: '7th · B', classId: 'c7');
const eightA = SectionChoice(id: 'sec3', name: '8th · A', classId: 'c8');

const twoClasses = MarkingSections(
  classes: [
    ClassChoice(id: 'c7', name: '7th'),
    ClassChoice(id: 'c8', name: '8th'),
  ],
  sections: [sevenA, sevenB, eightA],
);

const oneSection = MarkingSections(
  classes: [ClassChoice(id: 'c7', name: '7th')],
  sections: [sevenA],
);

/// What ATT-02 answers for a register of the three students of the roll.
const submitted = 3;

Map<String, Object?> studentJson({
  String enrolment = 'e1',
  String student = 's1',
  String roll = '1',
  String firstName = 'Asha',
  String? lastName = 'Rao',
  int status = 1,
}) => {
  'studentId': student,
  'studentEnrolmentId': enrolment,
  'rollNumber': roll,
  'firstName': firstName,
  'lastName': lastName,
  'photoFileId': null,
  'attendanceStatus': status,
};

Map<String, Object?> rosterJson({
  List<Map<String, Object?>>? students,
  Map<String, Object?>? session,
  bool isHoliday = false,
  String? holidayTitle,
  bool canMark = true,
}) => {
  'section': {'id': 'sec1', 'displayName': 'A', 'classId': 'c7', 'className': '7th'},
  'date': '2026-11-17',
  'isHoliday': isHoliday,
  'holidayTitle': holidayTitle,
  'canMark': canMark,
  'existingSession': session,
  'students':
      students ??
      [studentJson(), studentJson(enrolment: 'e2', student: 's2', roll: '2', firstName: 'Bea', lastName: null)],
};

Map<String, Object?> countsJson({String id = 'r1', int version = 1}) => {
  'id': id,
  'version': version,
  'rosterCount': 3,
  'presentCount': 2,
  'absentCount': 1,
  'lateCount': 0,
  'halfDayCount': 0,
  'leaveCount': 0,
  'institutionId': 'i1',
  'sectionId': 'sec1',
};
