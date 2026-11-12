import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/staff/data/staff_models.dart';
import 'package:bravynix_school_erp/features/staff/data/staff_repository_impl.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/staff.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({StaffRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: StaffRepositoryImpl(api: api), adapter: adapter);
  }

  Map<String, Object?> meta({int page = 1, int totalPages = 3}) => {
    'page': page,
    'limit': 20,
    'totalItems': 41,
    'totalPages': totalPages,
  };

  group('models', () {
    test('tell two staff members apart by the section they lead', () {
      final leads = kavyaWith(
        classTeachers: [
          {'academicYearId': 'y1', 'sectionId': 'e1'},
        ],
      );
      expect(leads, isNot(kavyaWith()));
    });

    test('tell two staff members apart by the Aadhaar number they hold', () {
      final holds = StaffModels.member({...memberJson(), 'aadhaarMasked': 'XXXX XXXX 1234'});
      final none = StaffModels.member({...memberJson(), 'aadhaarMasked': null});
      expect(holds.aadhaarMasked, 'XXXX XXXX 1234');
      expect(none.aadhaarMasked, isNull);
      expect(holds, isNot(none));
    });

    test('read a row of the list, with and without the optional fields', () {
      expect(StaffModels.summary(summaryRow()), kavya);
      expect(
        StaffModels.summary(
          summaryRow(
            id: 'f2',
            firstName: 'Ravi',
            lastName: null,
            employeeCode: null,
            designationId: null,
            isBlocked: true,
          ),
        ),
        ravi,
      );
      expect(StaffModels.summaries([summaryRow()]), [kavya]);
    });

    test('read the profile, ignoring what the screen does not show', () {
      expect(StaffModels.member(memberJson()), kavyaMember);
    });

    test('read a profile with nothing optional set', () {
      final json = {
        ...memberJson(),
        'lastName': null,
        'employeeCode': null,
        'gender': null,
        'dateOfBirth': null,
        'bloodGroup': null,
        'nationality': null,
        'photoFileId': null,
        'designationId': null,
        'alternateNumber': null,
        'address': {'line1': null, 'line2': null, 'countryId': null, 'stateId': null, 'cityId': null, 'pincode': null},
        'joiningDate': null,
        'resignationDate': null,
        'employmentType': null,
        'educations': <Object?>[],
        'emergencyContacts': <Object?>[],
        'isBlocked': true,
        'version': 1,
        'aadhaarMasked': null,
        'person': {'id': 'u1', 'email': 'ravi@example.com'},
        'firstName': 'Ravi',
        'id': 'f2',
      };
      expect(StaffModels.member(json), raviMember);
      expect(raviMember.address.isEmpty, isTrue);
      expect(kavyaMember.address.isEmpty, isFalse);
    });

    test('read a code they do not know as unset', () {
      final member = StaffModels.member({...memberJson(), 'gender': 9, 'employmentType': 9});
      expect(member.gender, isNull);
      expect(member.employmentType, isNull);
      expect(Gender.fromCode(3), Gender.other);
      expect(EmploymentType.fromCode(4), EmploymentType.contract);
    });

    test('refuse an answer they cannot read instead of showing a wrong person', () {
      expect(() => StaffModels.summary('x'), throwsFormatException);
      expect(() => StaffModels.summaries({'a': 1}), throwsFormatException);
      expect(() => StaffModels.member({...memberJson(), 'version': null}), throwsA(isA<TypeError>()));
      expect(() => StaffModels.member({...memberJson(), 'mobile': null}), throwsFormatException);
    });

    test('name a person from the first and last name', () {
      expect(kavya.fullName, 'Kavya Nair');
      expect(ravi.fullName, 'Ravi');
      expect(kavyaMember.fullName, 'Kavya Nair');
      expect(raviMember.fullName, 'Ravi');
    });
  });

  group('STF-01', () {
    test('asks for a page of the Institution, with the search only when there is one', () async {
      final (:repository, :adapter) = build(
        () => okReply([summaryRow()], meta: meta(page: 2)),
      );
      final page = await repository.staff('i1', page: 2, query: 'kav');
      expect(page.items, [kavya]);
      expect([page.page, page.totalPages, page.hasMore], [2, 3, true]);
      expect(adapter.requests.single.uri.path, '/v1/staff');
      expect(adapter.requests.single.uri.queryParameters, {'institutionId': 'i1', 'page': '2', 'q': 'kav'});
      await repository.staff('i1');
      expect(adapter.requests.last.uri.queryParameters, {'institutionId': 'i1', 'page': '1'});
    });

    test('has no more pages after the last, or when the answer has no page numbers', () async {
      final (:repository, adapter: _) = build(() => okReply([summaryRow()], meta: meta(page: 3)));
      expect((await repository.staff('i1', page: 3)).hasMore, isFalse);
      final (repository: whole, adapter: _) = build(() => okReply([summaryRow()]));
      final page = await whole.staff('i1');
      expect([page.page, page.hasMore], [1, false]);
    });

    test('fails with the code the server gave', () async {
      final (:repository, adapter: _) = build(() => errorReply(403, 'FORBIDDEN'));
      await expectLater(
        repository.staff('i1'),
        throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'FORBIDDEN')),
      );
    });
  });

  group('STF-03 and STF-05', () {
    test('reads one staff member by ID', () async {
      final (:repository, :adapter) = build(() => okReply(memberJson()));
      expect(await repository.member('f/1'), kavyaMember);
      expect(adapter.requests.single.uri.path, '/v1/staff/f%2F1');
    });

    test('says a member outside the scope is not found', () async {
      final (:repository, adapter: _) = build(() => errorReply(404, 'NOT_FOUND'));
      await expectLater(
        repository.member('f1'),
        throwsA(isA<ApiFailure>().having((failure) => failure.statusCode, 'status', 404)),
      );
    });

    test('deactivates with DELETE', () async {
      final (:repository, :adapter) = build(() => okReply({'id': 'f1', 'status': 0}));
      await repository.deactivate('f1');
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.uri.path, '/v1/staff/f1');
    });

    test('says it was refused for the caller own record', () async {
      final (:repository, adapter: _) = build(() => errorReply(409, 'CANNOT_ACT_ON_SELF'));
      await expectLater(
        repository.deactivate('f1'),
        throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'CANNOT_ACT_ON_SELF')),
      );
    });
  });

  group('STF-02', () {
    test('sends what is set, with the Institution, and reads the staff member made', () async {
      final (:repository, :adapter) = build(() => okReply(memberJson(), status: 201));
      expect(await repository.create('i1', kavyaDraft), kavyaMember);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/staff']);
      expect(bodyOf(request), {
        'homeInstitutionId': 'i1',
        'email': 'kavya.nair@example.com',
        'firstName': 'Kavya',
        'classCategoryId': 'c1',
        'mobile': {'countryCode': '91', 'number': '9876543210'},
        'lastName': 'Nair',
        'employeeCode': 'T-014',
        'gender': 2,
        'dateOfBirth': '1990-04-17',
        'bloodGroup': 'O+',
        'nationality': 'Indian',
        'designationId': 'd1',
        'alternateNumber': '9876500000',
        'joiningDate': '2020-06-01',
        'resignationDate': '2026-03-31',
        'employmentType': 1,
        'photoFileId': 'p2',
        'address': {
          'line1': '12 Lake Road',
          'line2': 'Near the park',
          'countryId': 'k1',
          'stateId': 's1',
          'cityId': 'y1',
          'pincode': '560066',
        },
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
            'phone': {'countryCode': '91', 'number': '9876511111'},
            'isPrimary': true,
            'relation': 'Father',
            'alternateNumber': '9876522222',
          },
          {
            'contactName': 'Mini Nair',
            'phone': {'countryCode': '91', 'number': '9876533333'},
            'isPrimary': false,
          },
        ],
      });
    });

    test('leaves out what is empty, and sends the two lists even when empty', () async {
      final (:repository, :adapter) = build(() => okReply(memberJson(), status: 201));
      await repository.create('i1', raviDraft);
      expect(bodyOf(adapter.requests.single), {
        'homeInstitutionId': 'i1',
        'email': 'ravi@example.com',
        'firstName': 'Ravi',
        'classCategoryId': 'c1',
        'mobile': {'countryCode': '91', 'number': '9876543210'},
        'educations': <Object?>[],
        'emergencyContacts': <Object?>[],
      });
    });

    for (final code in ['EMPLOYEE_ID_TAKEN', 'DUPLICATE', 'ROLE_CONFLICT', 'ACCOUNT_BLOCKED']) {
      test('fails with $code as the server said', () async {
        final (:repository, adapter: _) = build(() => errorReply(409, code));
        await expectLater(
          repository.create('i1', raviDraft),
          throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)),
        );
      });
    }
  });

  group('STF-04', () {
    test('sends the version and every field, with null for what is empty, and never the email', () async {
      final (:repository, :adapter) = build(() => okReply(memberJson()));
      await repository.update('f1', 4, raviDraft);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['PATCH', '/v1/staff/f1']);
      expect(bodyOf(request), {
        'version': 4,
        'firstName': 'Ravi',
        'classCategoryId': 'c1',
        'mobile': {'countryCode': '91', 'number': '9876543210'},
        'lastName': null,
        'employeeCode': null,
        'gender': null,
        'dateOfBirth': null,
        'bloodGroup': null,
        'nationality': null,
        'designationId': null,
        'alternateNumber': null,
        'joiningDate': null,
        'resignationDate': null,
        'employmentType': null,
        'address': {
          'line1': null,
          'line2': null,
          'countryId': null,
          'stateId': null,
          'cityId': null,
          'pincode': null,
        },
        'educations': <Object?>[],
        'emergencyContacts': <Object?>[],
      });
    });

    test('sends the photo only when a new one was uploaded', () async {
      final (:repository, :adapter) = build(() => okReply(memberJson()));
      await repository.update('f1', 4, kavyaDraft);
      expect(bodyOf(adapter.requests.last)['photoFileId'], 'p2');
      await repository.update('f1', 4, raviDraft);
      expect(bodyOf(adapter.requests.last).containsKey('photoFileId'), isFalse);
    });

    test('says someone saved first', () async {
      final (:repository, adapter: _) = build(() => errorReply(409, 'VERSION_CONFLICT'));
      await expectLater(
        repository.update('f1', 4, raviDraft),
        throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'VERSION_CONFLICT')),
      );
    });
  });

  group('STF-06 to STF-10', () {
    Map<String, Object?> access({bool isBlocked = false}) => {
      ...memberJson(),
      'isBlocked': isBlocked,
      'subjectIds': ['u1', 'u2'],
      'institutionIds': ['i2'],
    };

    test('read the subjects and the extra Institutions the profile holds, none when it has none', () {
      final member = StaffModels.member(access());
      expect(member.subjectIds, ['u1', 'u2']);
      expect(member.institutionIds, ['i2']);
      final none = StaffModels.member({...memberJson(), 'subjectIds': <String>[], 'institutionIds': <String>[]});
      expect(none.subjectIds, isEmpty);
      expect(none.institutionIds, isEmpty);
    });

    test('refuse a profile whose lists they cannot read, as with the rest', () {
      expect(() => StaffModels.member({...memberJson(), 'subjectIds': 'u1'}), throwsA(anything));
    });

    test('read the sections they lead as class teacher, none when they lead none', () {
      final leads = StaffModels.member({
        ...memberJson(),
        'classTeachers': [
          {'academicYearId': 'y1', 'sectionId': 'e1'},
        ],
      });
      expect(leads.classTeachers, const [ClassTeacherAssignment(academicYearId: 'y1', sectionId: 'e1')]);
      expect(StaffModels.member(memberJson()).classTeachers, isEmpty);
    });

    test('refuse a class teacher row they cannot read', () {
      expect(
        () => StaffModels.member({
          ...memberJson(),
          'classTeachers': [
            {'academicYearId': 'y1'},
          ],
        }),
        throwsA(anything),
      );
    });

    test(
      'set the class teacher with PUT, sending the year and the section, and read the assignment it answers',
      () async {
        final (:repository, :adapter) = build(() => okReply({'academicYearId': 'y1', 'sectionId': 'e1'}));
        expect(
          await repository.setClassTeacher('f/1', academicYearId: 'y1', sectionId: 'e1'),
          const ClassTeacherAssignment(academicYearId: 'y1', sectionId: 'e1'),
        );
        expect(adapter.requests.last.method, 'PUT');
        expect(adapter.requests.last.uri.path, '/v1/staff/f%2F1/class-teacher');
        expect(bodyOf(adapter.requests.last), {'academicYearId': 'y1', 'sectionId': 'e1'});
      },
    );

    test('end the class teacher duty by sending a null section, and take the null answer as none', () async {
      final (:repository, :adapter) = build(() => okReply(null));
      expect(await repository.setClassTeacher('f1', academicYearId: 'y1'), isNull);
      expect(bodyOf(adapter.requests.last), {'academicYearId': 'y1', 'sectionId': null});
    });

    test('block and unblock with POST and no body, and read the profile they answer with', () async {
      final (:repository, :adapter) = build(() => okReply(access(isBlocked: true)));
      expect((await repository.block('f/1')).isBlocked, isTrue);
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.uri.path, '/v1/staff/f%2F1/block');
      expect(adapter.requests.last.data, isNull);
      await repository.unblock('f/1');
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.uri.path, '/v1/staff/f%2F1/unblock');
    });

    test('send the whole list of subjects with PUT, an empty list too', () async {
      final (:repository, :adapter) = build(() => okReply(access()));
      final member = await repository.setSubjects('f1', ['u1', 'u2']);
      expect(adapter.requests.single.method, 'PUT');
      expect(adapter.requests.single.uri.path, '/v1/staff/f1/subjects');
      expect(bodyOf(adapter.requests.single), {
        'subjectIds': ['u1', 'u2'],
      });
      expect(member.subjectIds, ['u1', 'u2']);
      await repository.setSubjects('f1', []);
      expect(bodyOf(adapter.requests.last), {'subjectIds': <String>[]});
    });

    test('send the whole list of extra Institutions with PUT', () async {
      final (:repository, :adapter) = build(() => okReply(access()));
      final member = await repository.setInstitutions('f1', ['i2']);
      expect(adapter.requests.single.method, 'PUT');
      expect(adapter.requests.single.uri.path, '/v1/staff/f1/institutions');
      expect(bodyOf(adapter.requests.single), {
        'institutionIds': ['i2'],
      });
      expect(member.institutionIds, ['i2']);
    });

    test('set the Aadhaar number with PUT, and take the masked number the API answers with', () async {
      final (:repository, :adapter) = build(() => okReply({'aadhaarMasked': 'XXXX XXXX 0123'}));
      expect(await repository.setAadhaar('f/1', '234567890123'), 'XXXX XXXX 0123');
      expect(adapter.requests.single.method, 'PUT');
      expect(adapter.requests.single.uri.path, '/v1/staff/f%2F1/identity');
      expect(bodyOf(adapter.requests.single), {'aadhaar': '234567890123'});
    });

    test('clear the Aadhaar number by sending null, and take the null answer as none', () async {
      final (:repository, :adapter) = build(() => okReply({'aadhaarMasked': null}));
      expect(await repository.setAadhaar('f1', null), isNull);
      expect(bodyOf(adapter.requests.single), {'aadhaar': null});
    });

    test('reveal the Aadhaar number with POST, sending the field and the reason', () async {
      final (:repository, :adapter) = build(
        () => okReply({'field': 'aadhaar', 'value': '234567890123', 'revealedAt': '2026-11-11T10:00:00.000Z'}),
      );
      expect(await repository.revealAadhaar('f/1', reason: 'Checking the records'), '234567890123');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.uri.path, '/v1/staff/f%2F1/identity/reveal');
      expect(bodyOf(adapter.requests.single), {'field': 'aadhaar', 'reason': 'Checking the records'});
    });

    for (final (status, code) in [
      (409, 'INVALID_STATE'),
      (409, 'CANNOT_ACT_ON_SELF'),
      (409, 'AADHAAR_EXISTS_IN_SOCIETY'),
      (422, 'INVALID_AADHAAR'),
      (404, 'NOT_SET'),
      (429, 'REVEAL_LIMIT'),
      (403, 'FORBIDDEN'),
      (409, 'SUBJECT_ASSIGNED'),
      (409, 'ADMIN_ACCESS_HELD'),
      (422, 'REFERENCE_INACTIVE'),
    ]) {
      test('fail with $code as the server said', () async {
        final (:repository, adapter: _) = build(() => errorReply(status, code));
        for (final call in [
          () => repository.block('f1'),
          () => repository.unblock('f1'),
          () => repository.setSubjects('f1', ['u1']),
          () => repository.setInstitutions('f1', ['i2']),
          () => repository.setAadhaar('f1', '234567890123'),
          () => repository.revealAadhaar('f1', reason: 'Checking the records'),
        ]) {
          await expectLater(call(), throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)));
        }
      });
    }
  });
}
