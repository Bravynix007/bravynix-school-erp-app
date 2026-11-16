import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/classroom/data/classroom_models.dart';
import 'package:bravynix_school_erp/features/classroom/data/classroom_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/classroom.dart';
import '../../helpers/fake_http.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({ClassroomRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: ClassroomRepositoryImpl(api: api), adapter: adapter);
  }

  test('a student is read without the fields the classroom view leaves out', () {
    expect(ClassroomModels.student(classroomJson()), ashaClassroom);
    final plain = ClassroomModels.student({
      ...classroomJson(id: 'p2', firstName: 'Bala'),
      'lastName': null,
      'gender': null,
      'dateOfBirth': null,
      'bloodGroup': null,
    });
    expect([plain.fullName, plain.gender, plain.dateOfBirth, plain.bloodGroup], ['Bala', null, null, null]);
    expect(ashaClassroom.gender, Gender.female);
  });

  group('STU-01', () {
    test('asks for a page of the Institution, with the search only when there is one', () async {
      final (:repository, :adapter) = build(
        () => okReply(
          [classroomJson()],
          meta: {'page': 2, 'limit': 20, 'totalItems': 41, 'totalPages': 3},
        ),
      );
      final page = await repository.students('i1', page: 2, query: 'ash');
      expect(page.items, [ashaClassroom]);
      expect([page.page, page.totalPages, page.hasMore], [2, 3, true]);
      expect(adapter.requests.single.uri.path, '/v1/students');
      expect(adapter.requests.single.uri.queryParameters, {'institutionId': 'i1', 'page': '2', 'q': 'ash'});
      await repository.students('i1');
      expect(adapter.requests.last.uri.queryParameters, {'institutionId': 'i1', 'page': '1'});
    });

    test('has no more pages when the answer has no page numbers', () async {
      final (:repository, adapter: _) = build(() => okReply([classroomJson()]));
      final page = await repository.students('i1');
      expect([page.page, page.hasMore], [1, false]);
    });
  });

  group('STU-03', () {
    test('reads one student by their ID', () async {
      final (:repository, :adapter) = build(() => okReply(classroomJson()));
      expect(await repository.student('p1'), ashaClassroom);
      expect(adapter.requests.single.uri.path, '/v1/students/p1');
    });

    test('keeps the code of a refusal', () async {
      final (:repository, adapter: _) = build(() => errorReply(403, 'NOT_ASSIGNED'));
      await expectLater(
        repository.student('p1'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'NOT_ASSIGNED')),
      );
    });
  });
}
