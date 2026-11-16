import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/students/data/student_import_models.dart';
import 'package:bravynix_school_erp/features/students/data/student_imports_repository_impl.dart';
import 'package:bravynix_school_erp/features/students/domain/student_import.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/students.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({StudentImportsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: StudentImportsRepositoryImpl(api: api), adapter: adapter);
  }

  Map<String, Object?> run({
    int status = 3,
    Map<String, Object?>? error,
    int? totalRows = 10,
  }) => {
    'id': 'm1',
    'kind': 'import',
    'runStatus': status,
    'institutionId': 'i1',
    'result': {
      'totalRows': totalRows,
      'processedRows': 10,
      'importedRows': 8,
      'skippedRows': 2,
      'overCapacity': true,
      'summary': '8 students imported, 2 row(s) skipped',
      'rowErrors': [
        {'row': 4, 'message': 'The roll number is already taken.'},
        {'row': 9, 'message': 'The class was not found.'},
      ],
    },
    'error': error,
  };

  group('IMP-01', () {
    test('reads the sample file as the text it is', () async {
      // The answer is the file, not the envelope.
      final (:repository, :adapter) = build(
        () => (
          status: 200,
          body: 'Name,RollNumber,Class,Section,GuardianName,GuardianPhone,GuardianEmail\r\n',
          headers: const {},
        ),
      );
      expect(await repository.template(), startsWith('Name,RollNumber,'));
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['GET', '/v1/imports/templates/students']);
    });

    test('says when the answer is not text', () async {
      final (:repository, adapter: _) = build(() => okReply({'not': 'text'}));
      await expectLater(repository.template(), throwsA(isA<ApiFailure>()));
    });

    test('keeps the refusal of the server', () async {
      final (:repository, adapter: _) = build(() => errorReply(403, 'FORBIDDEN'));
      await expectLater(repository.template(), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'FORBIDDEN')));
    });
  });

  group('IMP-02', () {
    test('sends the file, the year and the key, and answers with the ID to follow', () async {
      final (:repository, :adapter) = build(
        () => okReply({'importId': 'm1', 'runStatus': 1}, code: 'ACCEPTED', status: 202),
      );
      final id = await repository.start(
        institutionId: 'i1',
        fileId: 'f1',
        academicYearId: 'y1',
        idempotencyKey: 'key-1',
      );
      expect(id, 'm1');
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/imports']);
      expect(request.headers['Idempotency-Key'], 'key-1');
      expect(bodyOf(request), {'institutionId': 'i1', 'importType': 1, 'fileId': 'f1', 'academicYearId': 'y1'});
    });

    test('keeps the code of a refusal', () async {
      final (:repository, adapter: _) = build(() => errorReply(409, 'IMPORT_ALREADY_RUNNING'));
      await expectLater(
        repository.start(institutionId: 'i1', fileId: 'f1', academicYearId: 'y1', idempotencyKey: 'k'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'IMPORT_ALREADY_RUNNING')),
      );
    });
  });

  group('IMP-03', () {
    test('reads a finished import with its skipped rows', () async {
      final (:repository, :adapter) = build(() => okReply(run()));
      expect(await repository.status('m/1'), importDone);
      expect(adapter.requests.single.uri.path, '/v1/imports/m%2F1');
    });

    test('reads one the worker has not counted yet', () async {
      expect(StudentImportModels.run(run(status: 1, totalRows: null)).totalRows, isNull);
      expect(StudentImportModels.run(run(status: 2)).status, ImportStatus.running);
    });

    test('reads why an import that read no row stopped', () {
      final refused = StudentImportModels.run({
        ...run(status: 4, totalRows: null),
        'error': {'code': 'CSV_HEADER_INVALID', 'message': 'The first row is wrong'},
      });
      expect([refused.status, refused.errorCode], [ImportStatus.failed, 'CSV_HEADER_INVALID']);
    });

    test('is a failure, not a wrong screen, when the status is one the app does not know', () async {
      final (:repository, adapter: _) = build(() => okReply(run(status: 9)));
      await expectLater(repository.status('m1'), throwsA(isA<ApiFailure>()));
    });
  });
}
