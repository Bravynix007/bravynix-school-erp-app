import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';

import 'classes.dart';

const sectionARef = NamedRef(id: 's1', code: 'A', name: 'Section A');
const sectionBRef = NamedRef(id: 's2', code: 'B', name: 'Section B');

const sectionA = Section(
  id: 'e1',
  classId: 'k1',
  predefinedSection: sectionARef,
  displayName: 'Section A',
  capacity: 40,
  version: 2,
);

const sectionB = Section(
  id: 'e2',
  classId: 'k1',
  predefinedSection: sectionBRef,
  displayName: 'Blue',
  version: 1,
);

const sectionAEntry = MasterEntry(id: 's1', name: 'Section A', code: 'A');
const sectionBEntry = MasterEntry(id: 's2', name: 'Section B', code: 'B');

Map<String, Object?> sectionJson({
  String id = 'e1',
  NamedRef predefined = sectionARef,
  String displayName = 'Section A',
  int? capacity = 40,
  int? currentStudentCount,
  int version = 2,
}) => {
  'id': id,
  'classId': 'k1',
  'institutionId': 'i1',
  'predefinedSection': refJson(predefined),
  'displayName': displayName,
  'capacity': capacity,
  'currentStudentCount': currentStudentCount,
  'classTeacher': null,
  'status': 1,
  'version': version,
  'createdBy': {'id': 'p1', 'displayName': 'A. Rao'},
};
