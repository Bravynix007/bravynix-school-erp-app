import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';

const mathsMonday = TimetableEntry(
  id: 'x1',
  sectionId: 'sec1',
  sectionName: 'A',
  className: '7th',
  dayOfWeek: 1,
  slot: EntrySlot(id: 't1', periodNo: 1, startTime: '09:00', endTime: '09:45'),
  isBreak: false,
  subject: EntryRef(id: 'u1', name: 'Mathematics'),
  teacher: EntryRef(id: 'f1', name: 'Asha Rao'),
  version: 1,
);

const lunchMonday = TimetableEntry(
  id: 'x2',
  sectionId: 'sec1',
  sectionName: 'A',
  className: '7th',
  dayOfWeek: 1,
  slot: EntrySlot(id: 't2', periodNo: 4, startTime: '12:00', endTime: '12:30', label: 'Lunch'),
  isBreak: true,
  version: 3,
);

const scienceTuesday = TimetableEntry(
  id: 'x3',
  sectionId: 'sec1',
  dayOfWeek: 2,
  slot: EntrySlot(id: 't1', periodNo: 1, startTime: '09:00', endTime: '09:45'),
  isBreak: false,
  subject: EntryRef(id: 'u2', name: 'Science'),
  teacher: EntryRef(id: 'f2', name: 'Ben Iyer'),
  version: 2,
);

Map<String, Object?> entryJson({
  String id = 'x1',
  int dayOfWeek = 1,
  bool isBreak = false,
  bool named = true,
  Map<String, Object?>? subject = const {'id': 'u1', 'name': 'Mathematics'},
  Map<String, Object?>? teacher = const {'id': 'f1', 'displayName': 'Asha Rao'},
  Map<String, Object?> timeSlot = const {
    'id': 't1',
    'periodNo': 1,
    'label': null,
    'startTime': '09:00',
    'endTime': '09:45',
  },
  int version = 1,
}) => {
  'id': id,
  'institutionId': 'i1',
  'academicYearId': 'y1',
  'sectionId': 'sec1',
  'sectionName': named ? 'A' : null,
  'className': named ? '7th' : null,
  'dayOfWeek': dayOfWeek,
  'timeSlot': timeSlot,
  'isBreak': isBreak,
  'subject': subject,
  'teacher': teacher,
  'status': 1,
  'version': version,
  'createdBy': {'id': 'p1', 'displayName': 'A. Rao'},
};
