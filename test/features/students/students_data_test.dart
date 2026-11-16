import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/students/data/student_models.dart';
import 'package:bravynix_school_erp/features/students/data/students_repository_impl.dart';
import 'package:bravynix_school_erp/features/students/domain/promotion.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/students.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({StudentsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: StudentsRepositoryImpl(api: api), adapter: adapter);
  }

  Map<String, Object?> meta({int page = 1, int totalPages = 3}) => {
    'page': page,
    'limit': 20,
    'totalItems': 41,
    'totalPages': totalPages,
  };

  group('models', () {
    test('read a row of the list, with and without the optional fields', () {
      expect(StudentModels.summary(studentRow()), asha);
      final plain = StudentModels.summary(
        studentRow(id: 'p2', admissionNo: null, firstName: 'Bala', lastName: null, isBlocked: true, version: 1),
      );
      expect([plain.fullName, plain.admissionNo, plain.isBlocked], ['Bala', null, true]);
      expect(asha.fullName, 'Asha Rao');
    });

    test('tell the rows of two placements apart', () {
      expect(asha, isNot(bala));
      expect(const StudentFilter(classId: 'c1'), isNot(const StudentFilter(sectionId: 'e1')));
      expect(const StudentFilter().isEmpty, isTrue);
      expect(const StudentFilter(academicYearId: 'y1').isEmpty, isFalse);
    });
  });

  group('STU-03', () {
    test('reads the record: personal fields, placement, guardians and the masked identity', () {
      // The second guardian's relation, 9, is one the app does not know: it reads as none.
      expect(StudentModels.record(studentJson()), ashaRecord);
    });

    test('reads a record with only what is required, a deactivated one', () {
      final record = StudentModels.record({
        'id': 'p2',
        'institutionId': 'i1',
        'firstName': 'Bala',
        'mobile': null,
        'address': <String, Object?>{},
        'placement': null,
        'guardians': [
          {
            'id': 'g3',
            'firstName': 'Devi',
            'phone': {'countryCode': '91', 'number': '9876544444'},
            'isPrimary': true,
            'isEmergencyContact': false,
          },
        ],
        'identity': {'aadhaarMasked': null, 'birthCertificateNumber': null},
        'isBlocked': true,
        'status': 0,
        'version': 1,
      });
      expect(record, balaRecord);
      expect(
        [record.fullName, ashaRecord.fullName, ashaRecord.guardians.first.fullName],
        ['Bala', 'Asha Rao', 'Anil Rao'],
      );
    });

    test('knows the relations by code', () {
      expect([
        for (final relation in GuardianRelation.values) GuardianRelation.fromCode(relation.code),
      ], GuardianRelation.values);
      expect(GuardianRelation.fromCode(9), isNull);
    });

    test('asks for the student by ID, encoded in the path', () async {
      final (:repository, :adapter) = build(() => okReply(studentJson()));
      expect(await repository.student('a/b'), ashaRecord);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['GET', '/v1/students/a%2Fb']);
    });

    test('throws the failure the API gives', () async {
      final (:repository, adapter: _) = build(() => errorReply(404, 'NOT_FOUND'));
      await expectLater(
        repository.student('p1'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'NOT_FOUND')),
      );
    });
  });

  group('STU-01', () {
    test('asks for a page of the Institution, with the search and the filters only when there are some', () async {
      final (:repository, :adapter) = build(() => okReply([studentRow()], meta: meta(page: 2)));
      final page = await repository.students(
        'i1',
        page: 2,
        query: 'ash',
        filter: const StudentFilter(academicYearId: 'y1', classId: 'c1', sectionId: 'e1'),
      );
      expect(page.items, [asha]);
      expect([page.page, page.totalPages, page.hasMore], [2, 3, true]);
      expect(adapter.requests.single.uri.path, '/v1/students');
      expect(adapter.requests.single.uri.queryParameters, {
        'institutionId': 'i1',
        'page': '2',
        'q': 'ash',
        'academicYearId': 'y1',
        'classId': 'c1',
        'sectionId': 'e1',
      });
      await repository.students('i1');
      expect(adapter.requests.last.uri.queryParameters, {'institutionId': 'i1', 'page': '1'});
    });

    test('has no more pages after the last, or when the answer has no page numbers', () async {
      final (:repository, adapter: _) = build(() => okReply([studentRow()], meta: meta(page: 3)));
      expect((await repository.students('i1', page: 3)).hasMore, isFalse);
      final (repository: whole, adapter: _) = build(() => okReply([studentRow()]));
      final page = await whole.students('i1');
      expect([page.page, page.hasMore], [1, false]);
    });

    test('fails with the code the server gave', () async {
      final (:repository, adapter: _) = build(() => errorReply(403, 'FORBIDDEN'));
      await expectLater(
        repository.students('i1'),
        throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'FORBIDDEN')),
      );
    });
  });

  group('STU-05', () {
    test('deactivates with DELETE and the reason in the query', () async {
      final (:repository, :adapter) = build(() => okReply({'id': 'p1', 'status': 0}));
      await repository.deactivate('p1', LeavingReason.mistake);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['DELETE', '/v1/students/p1']);
      expect(request.uri.queryParameters, {'reason': '2'});
    });

    test('encodes the ID in the path', () async {
      final (:repository, :adapter) = build(() => okReply({'id': 'a/b', 'status': 0}));
      await repository.deactivate('a/b', LeavingReason.left);
      expect(adapter.requests.single.uri.path, '/v1/students/a%2Fb');
    });

    test('sends the code of each reason', () {
      expect([for (final reason in LeavingReason.values) reason.code], [1, 2, 3]);
    });

    test('says it was refused for a student already deactivated', () async {
      final (:repository, adapter: _) = build(() => errorReply(404, 'NOT_FOUND'));
      await expectLater(
        repository.deactivate('p1', LeavingReason.left),
        throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'NOT_FOUND')),
      );
    });
  });

  group('STU-02', () {
    const mobile = Phone(countryCode: '91', number: '9876501234');
    const enrolment = EnrolmentDraft(academicYearId: 'y1', classId: 'k1', sectionId: 'e1', rollNumber: '14');
    const father = GuardianDraft(
      firstName: 'Ravi',
      relation: GuardianRelation.father,
      phone: Phone(countryCode: '91', number: '9845012345'),
      isPrimary: true,
      isEmergencyContact: true,
    );

    test('sends only what is set, with the first placement and the guardians', () async {
      final (:repository, :adapter) = build(() => okReply(studentRow(), status: 201));
      final saved = await repository.create(
        'i1',
        const StudentDraft(firstName: 'Asha', mobile: mobile),
        enrolment: enrolment,
        guardians: [father],
      );
      expect(saved.student, const Student(id: 'p1', institutionId: 'i1', firstName: 'Asha', lastName: 'Rao'));
      expect(saved.student.fullName, 'Asha Rao');
      expect(saved.warnings, isEmpty);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/students']);
      expect(bodyOf(request), {
        'institutionId': 'i1',
        'firstName': 'Asha',
        'mobile': {'countryCode': '91', 'number': '9876501234'},
        'enrolment': {'academicYearId': 'y1', 'classId': 'k1', 'sectionId': 'e1', 'rollNumber': '14'},
        'guardians': [
          {
            'firstName': 'Ravi',
            'phone': {'countryCode': '91', 'number': '9845012345'},
            'isPrimary': true,
            'isEmergencyContact': true,
            'relation': 1,
          },
        ],
      });
    });

    test('sends every field that is set, the address and the identity numbers too', () async {
      final (:repository, :adapter) = build(() => okReply(studentRow(), status: 201));
      await repository.create(
        'i1',
        const StudentDraft(
          firstName: 'Asha',
          mobile: mobile,
          lastName: 'Rao',
          gender: Gender.female,
          dateOfBirth: '2014-03-09',
          bloodGroup: 'O+',
          nationality: 'Indian',
          photoFileId: 'f1',
          admissionNo: 'A-014',
          admissionDate: '2026-06-01',
          contactEmail: 'asha@example.com',
          alternateNumber: '9876500000',
          address: Address(line1: '12 Lake Road', countryId: 'k1', stateId: 's1', cityId: 'y1', pincode: '560001'),
        ),
        enrolment: enrolment,
        guardians: [
          const GuardianDraft(
            firstName: 'Meera',
            lastName: 'Rao',
            relation: GuardianRelation.mother,
            phone: Phone(countryCode: '91', number: '9845012346'),
            alternatePhone: '9845000000',
            email: 'meera@example.com',
            occupation: 'Doctor',
            isPrimary: true,
            isEmergencyContact: false,
          ),
        ],
        identity: const IdentityDraft(aadhaarNumber: '234567890123', birthCertificateNumber: 'BC-1'),
      );
      final body = bodyOf(adapter.requests.single);
      expect(body, containsPair('lastName', 'Rao'));
      expect(body, containsPair('gender', 2));
      expect(body, containsPair('dateOfBirth', '2014-03-09'));
      expect(body, containsPair('bloodGroup', 'O+'));
      expect(body, containsPair('nationality', 'Indian'));
      expect(body, containsPair('photoFileId', 'f1'));
      expect(body, containsPair('admissionNo', 'A-014'));
      expect(body, containsPair('admissionDate', '2026-06-01'));
      expect(body, containsPair('contactEmail', 'asha@example.com'));
      expect(body, containsPair('alternateNumber', '9876500000'));
      expect(body['address'], {
        'line1': '12 Lake Road',
        'countryId': 'k1',
        'stateId': 's1',
        'cityId': 'y1',
        'pincode': '560001',
      });
      expect(body['identity'], {'aadhaarNumber': '234567890123', 'birthCertificateNumber': 'BC-1'});
      expect((body['guardians']! as List).single, {
        'firstName': 'Meera',
        'phone': {'countryCode': '91', 'number': '9845012346'},
        'isPrimary': true,
        'isEmergencyContact': false,
        'relation': 2,
        'lastName': 'Rao',
        'alternatePhone': '9845000000',
        'email': 'meera@example.com',
        'occupation': 'Doctor',
      });
    });

    test('sends one identity number alone, and leaves a relation that is not chosen to the server to name', () async {
      final (:repository, :adapter) = build(() => okReply(studentRow(), status: 201));
      await repository.create(
        'i1',
        const StudentDraft(firstName: 'Asha', mobile: mobile),
        enrolment: enrolment,
        guardians: [
          const GuardianDraft(
            firstName: 'Ravi',
            relation: null,
            phone: Phone(countryCode: '91', number: '9845012345'),
            isPrimary: true,
            isEmergencyContact: false,
          ),
        ],
        identity: const IdentityDraft(birthCertificateNumber: 'BC-1'),
      );
      final body = bodyOf(adapter.requests.single);
      expect(body['identity'], {'birthCertificateNumber': 'BC-1'});
      expect((body['guardians']! as List).single, isNot(contains('relation')));
    });

    test('hands back the warnings the server gave', () async {
      final (:repository, adapter: _) = build(
        () => okReply(
          studentRow(),
          status: 201,
          meta: {
            'warnings': ['SECTION_OVER_CAPACITY', 'AADHAAR_EXISTS_IN_SOCIETY'],
          },
        ),
      );
      final saved = await repository.create(
        'i1',
        const StudentDraft(firstName: 'Asha', mobile: mobile),
        enrolment: enrolment,
        guardians: [father],
      );
      expect(saved.warnings, ['SECTION_OVER_CAPACITY', 'AADHAAR_EXISTS_IN_SOCIETY']);
    });

    test('fails with the code and the fields the server gave', () async {
      final (:repository, adapter: _) = build(() => errorReply(409, 'ROLL_NUMBER_TAKEN'));
      await expectLater(
        repository.create(
          'i1',
          const StudentDraft(firstName: 'Asha', mobile: mobile),
          enrolment: enrolment,
          guardians: [father],
        ),
        throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'ROLL_NUMBER_TAKEN')),
      );
    });

    test('tell two drafts apart', () {
      expect(const IdentityDraft().isEmpty, isTrue);
      expect(const IdentityDraft(aadhaarNumber: '234567890123').isEmpty, isFalse);
      expect(
        const StudentDraft(firstName: 'A', mobile: mobile),
        isNot(const StudentDraft(firstName: 'B', mobile: mobile)),
      );
      expect(
        father,
        isNot(
          const GuardianDraft(
            firstName: 'Ravi',
            relation: GuardianRelation.father,
            phone: Phone(countryCode: '91', number: '9845012345'),
            isPrimary: false,
            isEmergencyContact: true,
          ),
        ),
      );
      expect([for (final relation in GuardianRelation.values) relation.code], [1, 2, 3, 4, 5, 6]);
    });
  });

  group('STU-04', () {
    const mobile = Phone(countryCode: '91', number: '9876501234');

    test('sends every personal field with the version, null for what is empty, and answers the record', () async {
      final (:repository, :adapter) = build(() => okReply(studentJson()));
      final record = await repository.update('p1', 3, const StudentDraft(firstName: 'Asha', mobile: mobile));
      expect(record, ashaRecord);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['PATCH', '/v1/students/p1']);
      expect(bodyOf(request), {
        'version': 3,
        'firstName': 'Asha',
        'mobile': {'countryCode': '91', 'number': '9876501234'},
        'lastName': null,
        'gender': null,
        'dateOfBirth': null,
        'bloodGroup': null,
        'nationality': null,
        'admissionNo': null,
        'contactEmail': null,
        'alternateNumber': null,
        'admissionDate': null,
        'address': {'line1': null, 'line2': null, 'countryId': null, 'stateId': null, 'cityId': null, 'pincode': null},
      });
    });

    test('sends what is set, and a photo only when a new one was uploaded', () async {
      final (:repository, :adapter) = build(() => okReply(studentJson()));
      await repository.update(
        'a/b',
        7,
        const StudentDraft(
          firstName: 'Asha',
          lastName: 'Rao',
          gender: Gender.female,
          dateOfBirth: '2018-04-17',
          bloodGroup: 'O+',
          nationality: 'Indian',
          photoFileId: 'f2',
          admissionNo: 'A-1',
          admissionDate: '2026-06-01',
          contactEmail: 'asha@example.com',
          mobile: mobile,
          alternateNumber: '9876500000',
          address: Address(line1: '12 Lake Road', countryId: 'k1', stateId: 's1', cityId: 'y1', pincode: '560066'),
        ),
      );
      final request = adapter.requests.single;
      expect(request.uri.path, '/v1/students/a%2Fb');
      expect(bodyOf(request), {
        'version': 7,
        'firstName': 'Asha',
        'mobile': {'countryCode': '91', 'number': '9876501234'},
        'lastName': 'Rao',
        'gender': 2,
        'dateOfBirth': '2018-04-17',
        'bloodGroup': 'O+',
        'nationality': 'Indian',
        'admissionNo': 'A-1',
        'contactEmail': 'asha@example.com',
        'alternateNumber': '9876500000',
        'photoFileId': 'f2',
        'admissionDate': '2026-06-01',
        'address': {
          'line1': '12 Lake Road',
          'line2': null,
          'countryId': 'k1',
          'stateId': 's1',
          'cityId': 'y1',
          'pincode': '560066',
        },
      });
    });

    test('throws the failure the API gives', () async {
      final (:repository, adapter: _) = build(() => errorReply(409, 'VERSION_CONFLICT'));
      await expectLater(
        repository.update('p1', 3, const StudentDraft(firstName: 'Asha', mobile: mobile)),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'VERSION_CONFLICT')),
      );
    });
  });

  group('STU-06 and STU-07', () {
    test('block posts to the student and answers the record', () async {
      final (:repository, :adapter) = build(() => okReply(studentJson()));
      expect(await repository.block('a/b'), ashaRecord);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/students/a%2Fb/block']);
    });

    test('unblock posts to the student and answers the record', () async {
      final (:repository, :adapter) = build(() => okReply(studentJson()));
      expect(await repository.unblock('p1'), ashaRecord);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/students/p1/unblock']);
    });

    test('throw the failure the API gives', () async {
      final (:repository, adapter: _) = build(() => errorReply(409, 'INVALID_STATE'));
      for (final call in [repository.block, repository.unblock]) {
        await expectLater(call('p1'), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'INVALID_STATE')));
      }
    });
  });

  group('STU-10 and STU-11', () {
    test('setting the Aadhaar sends only that key, and answers the numbers and the warnings', () async {
      final (:repository, :adapter) = build(
        () => okReply(
          {'aadhaarMasked': 'XXXX XXXX 0123', 'birthCertificateNumber': 'BC-1'},
          meta: {
            'warnings': ['AADHAAR_EXISTS_IN_SOCIETY'],
          },
        ),
      );
      final saved = await repository.setAadhaar('a/b', '234567890123');
      expect(saved.identity, const StudentIdentity(aadhaarMasked: 'XXXX XXXX 0123', birthCertificateNumber: 'BC-1'));
      expect(saved.aadhaarElsewhere, isTrue);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['PUT', '/v1/students/a%2Fb/identity']);
      expect(bodyOf(request), {'aadhaarNumber': '234567890123'});
    });

    test('clearing the Aadhaar sends null, so the key is not left out', () async {
      final (:repository, :adapter) = build(() => okReply({'aadhaarMasked': null, 'birthCertificateNumber': 'BC-1'}));
      final saved = await repository.setAadhaar('p1', null);
      expect(saved.identity.aadhaarMasked, isNull);
      expect(saved.aadhaarElsewhere, isFalse);
      expect(bodyOf(adapter.requests.single), {'aadhaarNumber': null});
    });

    test('setting and clearing the birth certificate send only that key', () async {
      final (:repository, :adapter) = build(
        () => okReply({'aadhaarMasked': 'XXXX XXXX 0123', 'birthCertificateNumber': 'BC-1'}),
      );
      expect((await repository.setBirthCertificate('p1', 'BC-1')).identity.birthCertificateNumber, 'BC-1');
      await repository.setBirthCertificate('p1', null);
      expect(adapter.requests.map(bodyOf), [
        {'birthCertificateNumber': 'BC-1'},
        {'birthCertificateNumber': null},
      ]);
      expect(adapter.requests.map((request) => request.uri.path), everyElement('/v1/students/p1/identity'));
    });

    test('revealing posts the reason and answers the whole number', () async {
      final (:repository, :adapter) = build(
        () => okReply({'field': 'aadhaar', 'value': '234567890123', 'revealedAt': '2026-11-15T10:00:00Z'}),
      );
      expect(await repository.revealAadhaar('p1', reason: 'Checking the records'), '234567890123');
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/students/p1/identity/reveal']);
      expect(bodyOf(request), {'field': 'aadhaar', 'reason': 'Checking the records'});
    });

    test('revealing encodes the id of the student in the path', () async {
      final (:repository, :adapter) = build(
        () => okReply({'field': 'aadhaar', 'value': '234567890123', 'revealedAt': '2026-11-15T10:00:00Z'}),
      );
      await repository.revealAadhaar('a/b c', reason: 'Checking the records');
      expect(adapter.requests.single.uri.path, '/v1/students/a%2Fb%20c/identity/reveal');
    });

    test('throw the failure the API gives', () async {
      final (:repository, adapter: _) = build(() => errorReply(409, 'AADHAAR_DUPLICATE_IN_INSTITUTION'));
      await expectLater(
        repository.setAadhaar('p1', '234567890123'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'AADHAAR_DUPLICATE_IN_INSTITUTION')),
      );
      await expectLater(
        repository.revealAadhaar('p1', reason: 'Checking the records'),
        throwsA(isA<ApiFailure>()),
      );
    });
  });

  group('STU-09', () {
    const target = PromotionTarget(academicYearId: 'y2', classId: 'k2', sectionId: 'e3');

    test('sends the target and a roll number when one is given, and answers the profile and the warnings', () async {
      final (:repository, :adapter) = build(
        () => okReply(
          studentJson(),
          meta: {
            'warnings': ['SECTION_OVER_CAPACITY'],
          },
        ),
      );
      final promoted = await repository.promoteStudent('a/b', target: target, rollNumber: '20');
      expect(promoted.record, ashaRecord);
      expect(promoted.warnings, ['SECTION_OVER_CAPACITY']);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/students/a%2Fb/promote']);
      expect(bodyOf(request), {
        'toAcademicYearId': 'y2',
        'toClassId': 'k2',
        'toSectionId': 'e3',
        'rollNumber': '20',
      });
      // There is no Idempotency-Key: a repeat is refused, as the open placement is already in the new year.
      expect(request.headers.containsKey('Idempotency-Key'), isFalse);
    });

    test('sends all three parts as null to complete the final class, and leaves the roll number out', () async {
      final (:repository, :adapter) = build(() => okReply(studentJson()));
      await repository.promoteStudent('p1');
      expect(bodyOf(adapter.requests.single), {'toAcademicYearId': null, 'toClassId': null, 'toSectionId': null});
    });

    test('throws the failure the API gives', () async {
      final (:repository, adapter: _) = build(() => errorReply(409, 'ALREADY_ENROLLED'));
      await expectLater(
        repository.promoteStudent('p1', target: target),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'ALREADY_ENROLLED')),
      );
    });
  });

  group('PRM-01', () {
    const target = PromotionTarget(academicYearId: 'y2', classId: 'k2', sectionId: 'e3');

    test('sends the source, the target, the roll rule and the key, and counts who was left and why', () async {
      final (:repository, :adapter) = build(
        () => okReply(
          {
            'promotedCount': 12,
            'skipped': [
              {'studentId': 's1', 'reason': 'ALREADY_ENROLLED'},
              {'studentId': 's2', 'reason': 'NOT_IN_SOURCE'},
              {'studentId': 's3', 'reason': 'SOMETHING_NEW'},
            ],
          },
          code: 'PROMOTED',
          meta: {
            'warnings': ['SECTION_OVER_CAPACITY'],
          },
        ),
      );
      final result = await repository.promote(
        institutionId: 'i1',
        fromAcademicYearId: 'y1',
        fromClassId: 'k1',
        fromSectionId: 'e1',
        target: target,
        keepRollNumbers: false,
        idempotencyKey: 'key-1',
      );
      expect(result.promotedCount, 12);
      expect(result.skipped, [SkipReason.alreadyEnrolled, SkipReason.notInSource]);
      expect(result.warnings, ['SECTION_OVER_CAPACITY']);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/promotions']);
      expect(request.headers['Idempotency-Key'], 'key-1');
      expect(bodyOf(request), {
        'institutionId': 'i1',
        'fromAcademicYearId': 'y1',
        'fromClassId': 'k1',
        'fromSectionId': 'e1',
        'toAcademicYearId': 'y2',
        'toClassId': 'k2',
        'toSectionId': 'e3',
        'keepRollNumbers': false,
      });
    });

    test('sends null for every section, and null for the target to complete the final class', () async {
      final (:repository, :adapter) = build(() => okReply({'promotedCount': 0, 'skipped': <Object?>[]}));
      final result = await repository.promote(
        institutionId: 'i1',
        fromAcademicYearId: 'y1',
        fromClassId: 'k1',
        idempotencyKey: 'key-2',
      );
      expect(result, const PromotionResult(promotedCount: 0));
      expect(bodyOf(adapter.requests.single), {
        'institutionId': 'i1',
        'fromAcademicYearId': 'y1',
        'fromClassId': 'k1',
        'fromSectionId': null,
        'toAcademicYearId': null,
        'toClassId': null,
        'toSectionId': null,
        'keepRollNumbers': true,
      });
    });

    test('throws the failure the API gives', () async {
      final (:repository, adapter: _) = build(() => errorReply(413, 'BATCH_TOO_LARGE'));
      await expectLater(
        repository.promote(institutionId: 'i1', fromAcademicYearId: 'y1', fromClassId: 'k1', idempotencyKey: 'k'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'BATCH_TOO_LARGE')),
      );
    });
  });

  group('STU-08', () {
    test('sends only what changes, to the placement of the student, and answers the warnings', () async {
      final (:repository, :adapter) = build(
        () => okReply(
          studentRow(),
          meta: {
            'warnings': ['SECTION_OVER_CAPACITY'],
          },
        ),
      );
      final warnings = await repository.move('p1', sectionId: 'e2');
      expect(warnings, ['SECTION_OVER_CAPACITY']);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['PATCH', '/v1/students/p1/placement']);
      expect(bodyOf(request), {'sectionId': 'e2'});
    });

    test('sends the roll number and the day when they are set, and answers no warnings when there are none', () async {
      final (:repository, :adapter) = build(() => okReply(studentRow()));
      expect(await repository.move('p1', rollNumber: '15', effectiveDate: '2026-07-01'), isEmpty);
      expect(bodyOf(adapter.requests.single), {'rollNumber': '15', 'effectiveDate': '2026-07-01'});
    });

    test('encodes the ID in the path', () async {
      final (:repository, :adapter) = build(() => okReply(studentRow()));
      await repository.move('a/b', rollNumber: '15');
      expect(adapter.requests.single.uri.path, '/v1/students/a%2Fb/placement');
    });

    test('throws the failure the API gives', () async {
      final (:repository, adapter: _) = build(() => errorReply(409, 'ROLL_NUMBER_TAKEN'));
      await expectLater(
        repository.move('p1', rollNumber: '15'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'ROLL_NUMBER_TAKEN')),
      );
    });
  });
  group('STU-12', () {
    test('sends the class and the section to the class of the student, and answers the warnings', () async {
      final (:repository, :adapter) = build(
        () => okReply(
          studentRow(),
          meta: {
            'warnings': ['SECTION_OVER_CAPACITY'],
          },
        ),
      );
      final warnings = await repository.correctClass('p1', classId: 'k2', sectionId: 'e3');
      expect(warnings, ['SECTION_OVER_CAPACITY']);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['PATCH', '/v1/students/p1/class']);
      expect(bodyOf(request), {'classId': 'k2', 'sectionId': 'e3'});
    });

    test('sends the roll number when it is set, and answers no warnings when there are none', () async {
      final (:repository, :adapter) = build(() => okReply(studentRow()));
      expect(await repository.correctClass('a/b', classId: 'k2', sectionId: 'e3', rollNumber: '3'), isEmpty);
      final request = adapter.requests.single;
      expect(request.uri.path, '/v1/students/a%2Fb/class');
      expect(bodyOf(request), {'classId': 'k2', 'sectionId': 'e3', 'rollNumber': '3'});
    });

    test('throws the failure the API gives', () async {
      final (:repository, adapter: _) = build(() => errorReply(422, 'TARGET_CLASS_BELOW_SOURCE'));
      await expectLater(
        repository.correctClass('p1', classId: 'k2', sectionId: 'e3'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'TARGET_CLASS_BELOW_SOURCE')),
      );
    });
  });
}
