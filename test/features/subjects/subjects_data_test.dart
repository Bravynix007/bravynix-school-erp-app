import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/subjects/data/subject_models.dart';
import 'package:bravynix_school_erp/features/subjects/data/subjects_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/subjects.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({SubjectsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: SubjectsRepositoryImpl(api: api), adapter: adapter);
  }

  group('models', () {
    test('read a subject with and without a code, ignoring the fields they do not show', () {
      expect(SubjectModels.subject(subjectJson()), maths);
      expect(SubjectModels.subjects([subjectJson(), subjectJson(id: 'u2', name: 'Art', code: null, version: 1)]), [
        maths,
        art,
      ]);
    });

    test('refuse an answer they cannot read instead of showing a wrong subject', () {
      expect(() => SubjectModels.subject('x'), throwsFormatException);
      expect(() => SubjectModels.subjects({'a': 1}), throwsFormatException);
      expect(() => SubjectModels.subject({...subjectJson(), 'version': null}), throwsA(isA<TypeError>()));
    });

    test('send no code to add a subject without one, and null with the version to clear it', () {
      expect(SubjectModels.createBody(name: 'Art'), {'name': 'Art'});
      expect(SubjectModels.createBody(name: 'Mathematics', code: 'MATH'), {'name': 'Mathematics', 'code': 'MATH'});
      expect(SubjectModels.updateBody(maths, name: 'Maths'), {'version': 2, 'name': 'Maths', 'code': null});
    });
  });

  group('repository', () {
    test('lists the subjects from SUB-01', () async {
      final (:repository, :adapter) = build(() => okReply([subjectJson()]));
      expect(await repository.subjects(), [maths]);
      expect(adapter.paths, ['/v1/subjects']);
    });

    test('adds a subject with SUB-02', () async {
      final (:repository, :adapter) = build(() => okReply(subjectJson(), status: 201));
      expect(await repository.create(name: 'Mathematics', code: 'MATH'), maths);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {'name': 'Mathematics', 'code': 'MATH'});
    });

    test('changes a subject with SUB-03, sending the version it read', () async {
      final (:repository, :adapter) = build(() => okReply(subjectJson(version: 3)));
      await repository.update(maths, name: 'Maths', code: 'MATH');
      expect(adapter.paths, ['/v1/subjects/u1']);
      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.data, {'version': 2, 'name': 'Maths', 'code': 'MATH'});
    });

    test('deactivates a subject with SUB-04, encoding the ID it puts in the path', () async {
      final (:repository, :adapter) = build(() => okReply({'id': 'a/b', 'status': 0}));
      await repository.deactivate('a/b');
      expect(adapter.paths, ['/v1/subjects/a%2Fb']);
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('turns a refusal into an ApiFailure for the screen', () async {
      for (final (status, code) in [(409, 'DUPLICATE'), (409, 'VERSION_CONFLICT'), (404, 'NOT_FOUND')]) {
        final (:repository, adapter: _) = build(() => errorReply(status, code));
        await expectLater(
          repository.deactivate('u1'),
          throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)),
        );
      }
    });
  });
}
