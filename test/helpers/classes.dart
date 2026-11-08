import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';

const lowerPrimaryCategory = NamedRef(id: 'c1', code: 'LOWER_PRIMARY', name: 'Lower Primary');
const preUniversityCategory = NamedRef(id: 'c4', code: 'PRE_UNIVERSITY', name: 'Pre-University');
const class1Ref = NamedRef(id: 'p1', code: 'C1', name: 'Class 1');
const class2Ref = NamedRef(id: 'p2', code: 'C2', name: 'Class 2');
const puc1Ref = NamedRef(id: 'p9', code: 'PUC1', name: 'PUC 1st Year');

const class1 = SchoolClass(
  id: 'k1',
  institutionId: 'i1',
  predefinedClass: class1Ref,
  category: lowerPrimaryCategory,
  displayName: 'Class 1',
  code: 'ONE',
  sectionCount: 2,
  version: 3,
);

const pucClass = SchoolClass(
  id: 'k9',
  institutionId: 'i1',
  predefinedClass: puc1Ref,
  category: preUniversityCategory,
  streamName: 'PCMC',
  displayName: 'PUC 1st Year PCMC',
  sectionCount: 0,
  version: 1,
);

const class1Choice = ClassChoice(predefinedClass: class1Ref, category: lowerPrimaryCategory);
const class2Choice = ClassChoice(predefinedClass: class2Ref, category: lowerPrimaryCategory);
const pucChoice = ClassChoice(predefinedClass: puc1Ref, category: preUniversityCategory);

Map<String, Object?> refJson(NamedRef ref) => {'id': ref.id, 'code': ref.code, 'name': ref.name};

Map<String, Object?> classJson({
  String id = 'k1',
  NamedRef predefined = class1Ref,
  NamedRef category = lowerPrimaryCategory,
  String? streamName,
  String displayName = 'Class 1',
  String? code = 'ONE',
  int sectionCount = 2,
  int version = 3,
}) => {
  'id': id,
  'institutionId': 'i1',
  'predefinedClass': refJson(predefined),
  'category': refJson(category),
  'streamName': streamName,
  'displayName': displayName,
  'code': code,
  'sectionCount': sectionCount,
  'status': 1,
  'version': version,
  'createdBy': {'id': 'p1', 'displayName': 'A. Rao'},
};
