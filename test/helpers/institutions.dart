import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';

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
  phone: Phone(countryCode: '91', number: '9876543210'),
  telephone: '080 2345 6789',
  addressLine1: '12 Lake Road',
  addressLine2: 'Near the park',
  pincode: '560066',
  version: 3,
  countryId: 'k1',
  stateId: 's1',
  cityId: 'y1',
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
    'countryId': 'k1',
    'stateId': 's1',
    'cityId': 'y1',
  },
  'classesOffered': [
    {'id': 'c1', 'code': 'LOWER_PRIMARY', 'name': 'Lower Primary'},
    {'id': 'c2', 'code': 'HIGHER_PRIMARY', 'name': 'Higher Primary'},
  ],
  'location': null,
  'status': 1,
  'version': 3,
};

// The shared lists the form picks from.
const lowerPrimary = MasterEntry(id: 'c1', name: 'Lower Primary', code: 'LOWER_PRIMARY');
const higherPrimary = MasterEntry(id: 'c2', name: 'Higher Primary', code: 'HIGHER_PRIMARY');
const seniorSecondary = MasterEntry(id: 'c3', name: 'Senior Secondary', code: 'SENIOR_SECONDARY');
const india = MasterEntry(id: 'k1', name: 'India');
const karnataka = MasterEntry(id: 's1', name: 'Karnataka', parentId: 'k1');
const kerala = MasterEntry(id: 's2', name: 'Kerala', parentId: 'k1');
const bengaluru = MasterEntry(id: 'y1', name: 'Bengaluru', parentId: 's1');
const mysuru = MasterEntry(id: 'y2', name: 'Mysuru', parentId: 's1');
const kochi = MasterEntry(id: 'y3', name: 'Kochi', parentId: 's2');
