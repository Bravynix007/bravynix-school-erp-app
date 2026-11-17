import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';

const firstPeriod = TimeSlot(
  id: 't1',
  institutionId: 'i1',
  academicYearId: 'y1',
  periodNo: 1,
  startTime: '09:00',
  endTime: '09:45',
  isBreak: false,
  version: 2,
);

const lunch = TimeSlot(
  id: 't2',
  institutionId: 'i1',
  academicYearId: 'y1',
  periodNo: 4,
  startTime: '12:00',
  endTime: '12:30',
  isBreak: true,
  label: 'Lunch',
  version: 1,
);

Map<String, Object?> timeSlotJson({
  String id = 't1',
  int periodNo = 1,
  String startTime = '09:00',
  String endTime = '09:45',
  bool isBreak = false,
  String? label,
  int version = 2,
}) => {
  'id': id,
  'institutionId': 'i1',
  'academicYearId': 'y1',
  'periodNo': periodNo,
  'label': label,
  'startTime': startTime,
  'endTime': endTime,
  'isBreak': isBreak,
  'status': 1,
  'version': version,
  'createdBy': {'id': 'p1', 'displayName': 'A. Rao'},
};
