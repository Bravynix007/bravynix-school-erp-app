import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';

const maths = Subject(id: 'u1', name: 'Mathematics', code: 'MATH', version: 2);
const art = Subject(id: 'u2', name: 'Art', version: 1);

Map<String, Object?> subjectJson({
  String id = 'u1',
  String name = 'Mathematics',
  String? code = 'MATH',
  int version = 2,
}) => {
  'id': id,
  'name': name,
  'code': code,
  'status': 1,
  'version': version,
  'createdBy': {'id': 'p1', 'displayName': 'A. Rao'},
};
