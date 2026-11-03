import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';

InstitutionSummary summary({
  String id = 'i1',
  String code = 'SVHS',
  String name = 'Sri Vidya High School',
  String? place = 'Whitefield',
  Board? board = Board.cbse,
}) => InstitutionSummary(id: id, code: code, name: name, place: place, board: board);

Map<String, Object?> summaryJson({String id = 'i1', Object? boardCode = 1, String? place = 'Whitefield'}) => {
  'id': id,
  'code': 'SVHS',
  'name': 'Sri Vidya High School',
  'place': place,
  'boardCode': boardCode,
  'createdBy': {'id': 'p1', 'displayName': 'A. Rao'},
};

/// A full Institution: every optional field set, two categories offered.
const institution = Institution(
  id: 'i1',
  code: 'SVHS',
  name: 'Sri Vidya High School',
  place: 'Whitefield',
  board: Board.cbse,
  affiliationNumber: '830123',
  gstin: '29ABCDE1234F1Z5',
  email: 'office@svhs.example.org',
  phone: '+91 9876543210',
  telephone: '080 2345 6789',
  addressLine1: '12 Lake Road',
  addressLine2: 'Near the park',
  pincode: '560066',
  classesOffered: [
    OfferedCategory(id: 'c1', name: 'Lower Primary'),
    OfferedCategory(id: 'c2', name: 'Higher Primary'),
  ],
);

/// An Institution with only what is required.
const bareInstitution = Institution(id: 'i2', code: 'LVS', name: 'Lake View School', addressLine1: '3 Hill Street');

Map<String, Object?> institutionJson() => {
  'id': 'i1',
  'societyId': 's1',
  'code': 'SVHS',
  'name': 'Sri Vidya High School',
  'place': 'Whitefield',
  'boardCode': 1,
  'affiliationNumber': '830123',
  'gstin': '29ABCDE1234F1Z5',
  'email': 'office@svhs.example.org',
  'phone': {'countryCode': '91', 'number': '9876543210'},
  'telephone': '080 2345 6789',
  'address': {
    'line1': '12 Lake Road',
    'line2': 'Near the park',
    'pincode': '560066',
    'countryId': null,
    'stateId': null,
    'cityId': null,
  },
  'classesOffered': [
    {'id': 'c1', 'code': 'LOWER_PRIMARY', 'name': 'Lower Primary'},
    {'id': 'c2', 'code': 'HIGHER_PRIMARY', 'name': 'Higher Primary'},
  ],
  'location': null,
  'status': 1,
  'version': 3,
};
