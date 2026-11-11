import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/data/teaching_assignments_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/teaching_assignments.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({TeachingAssignmentsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: TeachingAssignmentsRepositoryImpl(api: api), adapter: adapter);
  }

  test(
    'reads a page of what a teacher teaches in a year from ASG-01, with the class and the section as one name',
    () async {
      final (:repository, :adapter) = build(
        () => okReply(
          [assignmentJson(), assignmentJson(id: 'g2', sectionId: 'e2', sectionName: 'Blue')],
          meta: {'page': 2, 'limit': 20, 'totalItems': 41, 'totalPages': 3},
        ),
      );
      final page = await repository.assignments('i1', academicYearId: 'y1', staffMemberId: 'f1', page: 2);
      expect(page.items, [mathsInClass1A, mathsInClass1Blue]);
      expect([page.page, page.totalPages, page.hasMore], [2, 3, true]);
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.uri.path, '/v1/teaching-assignments');
      expect(adapter.requests.single.uri.queryParameters, {
        'institutionId': 'i1',
        'academicYearId': 'y1',
        'staffMemberId': 'f1',
        'page': '2',
      });
    },
  );

  test('takes an answer without page numbers as the whole list', () async {
    final (:repository, adapter: _) = build(() => okReply([assignmentJson()]));
    final page = await repository.assignments('i1', academicYearId: 'y1', staffMemberId: 'f1');
    expect(page.hasMore, isFalse);
  });

  test('assigns with ASG-02, sending the four IDs and nothing else', () async {
    final (:repository, :adapter) = build(() => okReply(assignmentJson(), status: 201));
    final made = await repository.assign(
      staffMemberId: 'f1',
      academicYearId: 'y1',
      sectionId: 'e1',
      subjectId: 'u1',
    );
    expect(made, mathsInClass1A);
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.uri.path, '/v1/teaching-assignments');
    expect(bodyOf(adapter.requests.single), {
      'staffMemberId': 'f1',
      'academicYearId': 'y1',
      'sectionId': 'e1',
      'subjectId': 'u1',
    });
  });

  test('ends with ASG-03, encoding the ID it puts in the path', () async {
    final (:repository, :adapter) = build(() => okReply(null));
    await repository.end('g/1');
    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.paths, ['/v1/teaching-assignments/g%2F1']);
  });

  test('turns the refusals into an ApiFailure with the code of the API', () async {
    final (:repository, adapter: _) = build(() => errorReply(422, 'SUBJECT_NOT_TAUGHT'));
    await expectLater(
      repository.assign(staffMemberId: 'f1', academicYearId: 'y1', sectionId: 'e1', subjectId: 'u9'),
      throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'SUBJECT_NOT_TAUGHT')),
    );
  });
}
