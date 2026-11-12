import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/students/data/student_models.dart';
import 'package:bravynix_school_erp/features/students/data/students_repository_impl.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
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
}
