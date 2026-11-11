import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/documents/data/document_models.dart';
import 'package:bravynix_school_erp/features/documents/data/documents_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/documents.dart';
import '../../helpers/fake_http.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({DocumentsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: DocumentsRepositoryImpl(api: api), adapter: adapter);
  }

  test('reads a document with its file, ignoring what it does not show', () {
    expect(DocumentModels.document(documentJson()), appointmentLetter);
    expect(
      DocumentModels.document(
        documentJson(
          id: 'o2',
          title: 'B.Ed certificate',
          fileId: 'fl2',
          contentType: 'image/jpeg',
          sizeBytes: 1258291,
          fileName: 'bed.jpg',
          createdAt: '2026-11-09T08:00:00.000Z',
        ),
      ),
      degreeCertificate,
    );
  });

  test('refuses an answer it cannot read', () {
    expect(() => DocumentModels.document('x'), throwsFormatException);
    expect(() => DocumentModels.document({...documentJson(), 'file': null}), throwsFormatException);
  });

  test('lists the documents of a staff member with STF-14, in the order the server gives', () async {
    final (:repository, :adapter) = build(
      () => okReply([documentJson(id: 'o2', title: 'B.Ed certificate'), documentJson()]),
    );
    final documents = await repository.staffDocuments('f/1');
    expect(documents.map((document) => document.id), ['o2', 'o1']);
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.uri.path, '/v1/staff/f%2F1/documents');
  });

  test('attaches a file with STF-15, sending the title and the file and nothing else', () async {
    final (:repository, :adapter) = build(() => okReply(documentJson(), status: 201));
    final made = await repository.attachToStaff('f1', title: 'Appointment letter', fileId: 'fl1');
    expect(made, appointmentLetter);
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.uri.path, '/v1/staff/f1/documents');
    expect(bodyOf(adapter.requests.single), {'title': 'Appointment letter', 'fileId': 'fl1'});
  });

  test('deactivates with DOC-03, encoding the ID it puts in the path', () async {
    final (:repository, :adapter) = build(() => okReply({'id': 'o/1', 'status': 0}));
    await repository.deactivate('o/1');
    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.uri.path, '/v1/documents/o%2F1');
  });

  test('passes a refusal on as the failure it is', () async {
    final (:repository, adapter: _) = build(() => errorReply(409, 'DUPLICATE'));
    await expectLater(
      repository.attachToStaff('f1', title: 'Appointment letter', fileId: 'fl1'),
      throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'DUPLICATE')),
    );
  });
}
