import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_calendar.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';

const asha = RosterStudent(
  studentId: 's1',
  enrolmentId: 'e1',
  rollNumber: '1',
  firstName: 'Asha',
  lastName: 'Rao',
  mark: AttendanceMark.present,
);
const bea = RosterStudent(
  studentId: 's2',
  enrolmentId: 'e2',
  rollNumber: '2',
  firstName: 'Bea',
  mark: AttendanceMark.present,
);
const cy = RosterStudent(
  studentId: 's3',
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
      studentId: 's2',
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

const submitted = RegisterCounts(
  id: 'r1',
  version: 1,
  rosterCount: 3,
  presentCount: 2,
  absentCount: 1,
  lateCount: 0,
  halfDayCount: 0,
  leaveCount: 0,
);

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

Map<String, Object?> dayJson(
  String date,
  String status, {
  bool weekend = false,
  String? holiday,
}) => {'date': date, 'dayStatus': status, 'isWeekend': weekend, 'holidayTitle': holiday};

/// November 2026: the 1st is a Sunday, the 2nd to the 4th are marked, the 5th is a holiday.
Map<String, Object?> calendarJson({String month = '2026-11', double? percentage = 66.67}) => {
  'month': month,
  'summary': {
    'presentDays': 1,
    'absentDays': 1,
    'lateDays': 1,
    'halfDays': 0,
    'leaveDays': 0,
    'holidays': 1,
    'notMarkedDays': 2,
    'attendancePercentage': percentage,
  },
  'yearToDate': {'attendancePercentage': 90.5},
  'days': [
    for (var day = 1; day <= 30; day++)
      switch (day) {
        1 => dayJson('2026-11-01', 'not_marked', weekend: true),
        2 => dayJson('2026-11-02', 'present'),
        3 => dayJson('2026-11-03', 'absent'),
        4 => dayJson('2026-11-04', 'late'),
        5 => dayJson('2026-11-05', 'holiday', holiday: 'Founders Day'),
        _ => dayJson('2026-11-${day.toString().padLeft(2, '0')}', day < 8 ? 'not_enrolled' : 'not_marked'),
      },
  ],
};

final november = AttendanceCalendar(
  month: '2026-11',
  summary: const MonthSummary(
    presentDays: 1,
    absentDays: 1,
    lateDays: 1,
    halfDays: 0,
    leaveDays: 0,
    holidays: 1,
    notMarkedDays: 2,
    percentage: 66.67,
  ),
  yearToDatePercentage: 90.5,
  days: [
    for (var day = 1; day <= 30; day++)
      CalendarDay(
        day: '2026-11-${day.toString().padLeft(2, '0')}',
        status: switch (day) {
          1 => DayStatus.notMarked,
          2 => DayStatus.present,
          3 => DayStatus.absent,
          4 => DayStatus.late,
          5 => DayStatus.holiday,
          _ => day < 8 ? DayStatus.notEnrolled : DayStatus.notMarked,
        },
        isWeekend: day == 1,
        holidayTitle: day == 5 ? 'Founders Day' : null,
      ),
  ],
);

final absentOnThe3rd = DayDetail(
  day: '2026-11-03',
  status: DayStatus.absent,
  isWeekend: false,
  section: const DaySection(id: 'sec1', name: 'A', className: '7th'),
  markedBy: 'R. Nair',
  markedAt: DateTime.utc(2026, 11, 3, 4, 30),
  lastCorrectedAt: DateTime.utc(2026, 11, 3, 6),
);

Map<String, Object?> dayDetailJson() => {
  ...dayJson('2026-11-03', 'absent'),
  'section': {'id': 'sec1', 'name': 'A', 'className': '7th'},
  'markedBy': {'id': 't1', 'displayName': 'R. Nair'},
  'markedAt': '2026-11-03T04:30:00.000Z',
  'lastCorrectedAt': '2026-11-03T06:00:00.000Z',
};
