import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';

import 'academic_years.dart';

/// Asha Rao: in Class 1 · Section A (section e1) of the current year, roll 14, with an Admission ID.
const asha = StudentSummary(
  id: 'p1',
  institutionId: 'i1',
  admissionNo: 'A-2026-014',
  firstName: 'Asha',
  lastName: 'Rao',
  placement: StudentPlacement(
    academicYearId: 'y1',
    classId: 'c1',
    sectionId: 'e1',
    rollNumber: '14',
    startDate: '2026-06-01',
  ),
  isBlocked: false,
  version: 3,
);

/// A row with only what is required, in a section no longer offered, and blocked.
const bala = StudentSummary(
  id: 'p2',
  institutionId: 'i1',
  firstName: 'Bala',
  placement: StudentPlacement(
    academicYearId: 'y1',
    classId: 'c9',
    sectionId: 'e9',
    rollNumber: '2',
    startDate: '2026-06-01',
  ),
  isBlocked: true,
  version: 1,
);

const ashaEntry = StudentListEntry(asha, placeName: 'Class 1 · Section A');
const balaEntry = StudentListEntry(bala);

/// The years, classes and sections the filters choose from.
const studentOptions = SectionOptions(
  years: [earlierYear, currentYear],
  classes: [
    ClassChoice(id: 'c1', name: 'Class 1'),
    ClassChoice(id: 'c2', name: 'Class 2'),
  ],
  sections: [
    SectionChoice(id: 'e1', name: 'Class 1 · Section A', classId: 'c1'),
    SectionChoice(id: 'e2', name: 'Class 1 · Blue', classId: 'c1'),
    SectionChoice(id: 'e3', name: 'Class 2 · Section A', classId: 'c2'),
  ],
);

Map<String, Object?> studentRow({
  String id = 'p1',
  String? admissionNo = 'A-2026-014',
  String firstName = 'Asha',
  String? lastName = 'Rao',
  bool isBlocked = false,
  int version = 3,
}) => {
  'id': id,
  'institutionId': 'i1',
  'admissionNo': admissionNo,
  'firstName': firstName,
  'lastName': lastName,
  'photoFileId': null,
  'placement': {
    'enrolmentId': 'n1',
    'academicYearId': 'y1',
    'classId': 'c1',
    'sectionId': 'e1',
    'rollNumber': '14',
    'enrolledDate': '2026-06-01',
    'startDate': '2026-06-01',
  },
  'isBlocked': isBlocked,
  'status': 1,
  'version': version,
};

/// Asha Rao as an Owner or Admin reads her (STU-03): every field set, two guardians, the Aadhaar masked.
const ashaRecord = StudentRecord(
  id: 'p1',
  institutionId: 'i1',
  admissionNo: 'A-2026-014',
  firstName: 'Asha',
  lastName: 'Rao',
  gender: Gender.female,
  dateOfBirth: '2018-04-17',
  bloodGroup: 'O+',
  nationality: 'Indian',
  admissionDate: '2026-06-01',
  contactEmail: 'asha.rao@example.com',
  mobile: Phone(countryCode: '91', number: '9876543210'),
  alternateNumber: '9876500000',
  address: Address(
    line1: '12 Lake Road',
    line2: 'Near the park',
    countryId: 'k1',
    stateId: 's1',
    cityId: 'y1',
    pincode: '560066',
  ),
  placement: StudentPlacement(
    academicYearId: 'y1',
    classId: 'k1',
    sectionId: 'e1',
    rollNumber: '14',
    startDate: '2026-06-01',
  ),
  guardians: [
    Guardian(
      id: 'g1',
      firstName: 'Anil',
      lastName: 'Rao',
      relation: GuardianRelation.father,
      phone: Phone(countryCode: '91', number: '9876511111'),
      alternatePhone: '9876522222',
      email: 'anil.rao@example.com',
      occupation: 'Engineer',
      isPrimary: true,
      isEmergencyContact: true,
    ),
    Guardian(
      id: 'g2',
      firstName: 'Mini',
      phone: Phone(countryCode: '91', number: '9876533333'),
      isPrimary: false,
      isEmergencyContact: false,
    ),
  ],
  identity: StudentIdentity(aadhaarMasked: 'XXXX XXXX 1234', birthCertificateNumber: 'BC-2018-77'),
  isBlocked: false,
  isActive: true,
  version: 3,
);

/// A record with only what is required: no placement, number, address or identity; deactivated and blocked.
const balaRecord = StudentRecord(
  id: 'p2',
  institutionId: 'i1',
  firstName: 'Bala',
  mobile: null,
  address: Address(),
  guardians: [
    Guardian(
      id: 'g3',
      firstName: 'Devi',
      phone: Phone(countryCode: '91', number: '9876544444'),
      isPrimary: true,
      isEmergencyContact: false,
    ),
  ],
  identity: StudentIdentity(),
  isBlocked: true,
  isActive: false,
  version: 1,
);

/// [ashaRecord] as the API sends it.
Map<String, Object?> studentJson() => {
  'id': 'p1',
  'institutionId': 'i1',
  'admissionNo': 'A-2026-014',
  'firstName': 'Asha',
  'lastName': 'Rao',
  'gender': 2,
  'dateOfBirth': '2018-04-17',
  'bloodGroup': 'O+',
  'nationality': 'Indian',
  'photoFileId': null,
  'admissionDate': '2026-06-01',
  'contactEmail': 'asha.rao@example.com',
  'mobile': {'countryCode': '91', 'number': '9876543210'},
  'alternateNumber': '9876500000',
  'address': {
    'line1': '12 Lake Road',
    'line2': 'Near the park',
    'countryId': 'k1',
    'stateId': 's1',
    'cityId': 'y1',
    'pincode': '560066',
  },
  'placement': {
    'enrolmentId': 'n1',
    'academicYearId': 'y1',
    'classId': 'k1',
    'sectionId': 'e1',
    'rollNumber': '14',
    'enrolledDate': '2026-06-01',
    'startDate': '2026-06-01',
  },
  'guardians': [
    {
      'id': 'g1',
      'firstName': 'Anil',
      'lastName': 'Rao',
      'relation': 1,
      'phone': {'countryCode': '91', 'number': '9876511111'},
      'alternatePhone': '9876522222',
      'email': 'anil.rao@example.com',
      'occupation': 'Engineer',
      'isPrimary': true,
      'isEmergencyContact': true,
      'hasLogin': true,
      'version': 1,
    },
    {
      'id': 'g2',
      'firstName': 'Mini',
      'lastName': null,
      'relation': 9,
      'phone': {'countryCode': '91', 'number': '9876533333'},
      'alternatePhone': null,
      'email': null,
      'occupation': null,
      'isPrimary': false,
      'isEmergencyContact': false,
      'hasLogin': false,
      'version': 1,
    },
  ],
  'identity': {'aadhaarMasked': 'XXXX XXXX 1234', 'birthCertificateNumber': 'BC-2018-77'},
  'isBlocked': false,
  'blockedAt': null,
  'status': 1,
  'version': 3,
};
