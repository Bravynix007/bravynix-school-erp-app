import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_profile.dart';

const designationEntry = MasterEntry(id: 'd1', name: 'Mathematics Teacher');
const otherDesignation = MasterEntry(id: 'd2', name: 'Principal');
const countryEntry = MasterEntry(id: 'k1', name: 'India');
const stateEntry = MasterEntry(id: 's1', name: 'Karnataka', parentId: 'k1');
const cityEntry = MasterEntry(id: 'y1', name: 'Bengaluru', parentId: 's1');

const mobile = Phone(countryCode: '91', number: '9876543210');

/// A row of the list: Kavya Nair, with a designation, an Employee ID, and not blocked.
const kavya = StaffSummary(
  id: 'f1',
  firstName: 'Kavya',
  lastName: 'Nair',
  employeeCode: 'T-014',
  designationId: 'd1',
  classCategoryId: 'c1',
  mobile: mobile,
  isBlocked: false,
);

/// A row with only what is required, and blocked.
const ravi = StaffSummary(
  id: 'f2',
  firstName: 'Ravi',
  classCategoryId: 'c1',
  mobile: mobile,
  isBlocked: true,
);

const kavyaEntry = StaffListEntry(kavya, designationName: 'Mathematics Teacher', categoryName: 'Lower Primary');
const raviEntry = StaffListEntry(ravi, categoryName: 'Lower Primary');

/// A full profile: every optional field set, one education, two contacts.
const kavyaMember = StaffMember(
  id: 'f1',
  homeInstitutionId: 'i1',
  email: 'kavya.nair@example.com',
  firstName: 'Kavya',
  lastName: 'Nair',
  employeeCode: 'T-014',
  gender: Gender.female,
  dateOfBirth: '1990-04-17',
  bloodGroup: 'O+',
  nationality: 'Indian',
  photoFileId: 'p1',
  designationId: 'd1',
  classCategoryId: 'c1',
  mobile: mobile,
  alternateNumber: '9876500000',
  address: StaffAddress(
    line1: '12 Lake Road',
    line2: 'Near the park',
    countryId: 'k1',
    stateId: 's1',
    cityId: 'y1',
    pincode: '560066',
  ),
  joiningDate: '2020-06-01',
  resignationDate: '2026-03-31',
  employmentType: EmploymentType.fullTime,
  educations: [
    Education(
      degree: 'B.Ed',
      qualification: 'Education',
      specialization: 'Mathematics',
      institutionName: 'Mysore University',
      yearOfPassing: 2014,
    ),
  ],
  emergencyContacts: [
    EmergencyContact(
      contactName: 'Anil Nair',
      relation: 'Father',
      phone: Phone(countryCode: '91', number: '9876511111'),
      alternateNumber: '9876522222',
      isPrimary: true,
    ),
    EmergencyContact(
      contactName: 'Mini Nair',
      phone: Phone(countryCode: '91', number: '9876533333'),
      isPrimary: false,
    ),
  ],
  isBlocked: false,
  version: 4,
);

/// The least a profile has: no optional field, empty lists.
const raviMember = StaffMember(
  id: 'f2',
  homeInstitutionId: 'i1',
  email: 'ravi@example.com',
  firstName: 'Ravi',
  classCategoryId: 'c1',
  mobile: mobile,
  address: StaffAddress(),
  educations: [],
  emergencyContacts: [],
  isBlocked: true,
  version: 1,
);

const kavyaProfile = StaffProfile(
  kavyaMember,
  designationName: 'Mathematics Teacher',
  categoryName: 'Lower Primary',
  countryName: 'India',
  stateName: 'Karnataka',
  cityName: 'Bengaluru',
);

const raviProfile = StaffProfile(raviMember, categoryName: 'Lower Primary');

Map<String, Object?> summaryRow({
  String id = 'f1',
  String firstName = 'Kavya',
  String? lastName = 'Nair',
  String? employeeCode = 'T-014',
  String? designationId = 'd1',
  bool isBlocked = false,
}) => {
  'id': id,
  'homeInstitutionId': 'i1',
  'person': {'id': 'u1', 'email': 'kavya.nair@example.com'},
  'employeeCode': employeeCode,
  'firstName': firstName,
  'lastName': lastName,
  'photoFileId': null,
  'designationId': designationId,
  'classCategoryId': 'c1',
  'mobile': {'countryCode': '91', 'number': '9876543210'},
  'joiningDate': '2020-06-01',
  'isBlocked': isBlocked,
  'status': 1,
  'version': 4,
};

/// STF-03 for [kavyaMember], with fields this screen does not show.
Map<String, Object?> memberJson() => {
  'id': 'f1',
  'homeInstitutionId': 'i1',
  'person': {'id': 'u1', 'email': 'kavya.nair@example.com'},
  'employeeCode': 'T-014',
  'firstName': 'Kavya',
  'lastName': 'Nair',
  'gender': 2,
  'dateOfBirth': '1990-04-17',
  'bloodGroup': 'O+',
  'nationality': 'Indian',
  'photoFileId': 'p1',
  'designationId': 'd1',
  'classCategoryId': 'c1',
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
  'joiningDate': '2020-06-01',
  'resignationDate': '2026-03-31',
  'employmentType': 1,
  'educations': [
    {
      'degree': 'B.Ed',
      'qualification': 'Education',
      'specialization': 'Mathematics',
      'institutionName': 'Mysore University',
      'yearOfPassing': 2014,
    },
  ],
  'emergencyContacts': [
    {
      'contactName': 'Anil Nair',
      'relation': 'Father',
      'phone': {'countryCode': '91', 'number': '9876511111'},
      'alternateNumber': '9876522222',
      'isPrimary': true,
    },
    {
      'contactName': 'Mini Nair',
      'relation': null,
      'phone': {'countryCode': '91', 'number': '9876533333'},
      'alternateNumber': null,
      'isPrimary': false,
    },
  ],
  'isBlocked': false,
  'blockedAt': null,
  'subjectIds': ['u1'],
  'institutionIds': [],
  'classTeachers': [],
  'aadhaarMasked': 'XXXX XXXX 1234',
  'status': 1,
  'version': 4,
  'createdAt': '2026-11-01T10:00:00.000Z',
};
