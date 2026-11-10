import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
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
}
