import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/sections/data/section_models.dart';
import 'package:bravynix_school_erp/features/sections/data/sections_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/sections.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({SectionsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: SectionsRepositoryImpl(api: api), adapter: adapter);
  }

  group('models', () {
    test('read a section, with and without a capacity, and the count that comes with Phase 4', () {
      expect(SectionModels.section(sectionJson()), sectionA);
      final unset = SectionModels.section(
        sectionJson(id: 'e2', predefined: sectionBRef, displayName: 'Blue', capacity: null, version: 1),
      );
      expect(unset, sectionB);
      expect(unset.capacity, isNull);
      expect(unset.currentStudentCount, isNull);
      expect(SectionModels.section(sectionJson(currentStudentCount: 31)).currentStudentCount, 31);
      expect(SectionModels.sections([sectionJson()]), [sectionA]);
    });

    test('refuse an answer they cannot read instead of showing a wrong section', () {
      expect(() => SectionModels.section('x'), throwsFormatException);
      expect(() => SectionModels.sections({'a': 1}), throwsFormatException);
      expect(() => SectionModels.section({...sectionJson(), 'version': null}), throwsA(isA<TypeError>()));
    });

    test('send only what is set to add a section, with its class', () {
      expect(SectionModels.createBody('k1', predefinedSectionId: 's1'), {'classId': 'k1', 'predefinedSectionId': 's1'});
      expect(SectionModels.createBody('k1', predefinedSectionId: 's1', displayName: 'Blue', capacity: 30), {
        'classId': 'k1',
        'predefinedSectionId': 's1',
        'displayName': 'Blue',
        'capacity': 30,
      });
    });

    test('send the name, the capacity (null to clear it) and the version to change a section', () {
      expect(SectionModels.updateBody(sectionA, displayName: 'Blue', capacity: 35), {
        'version': 2,
        'displayName': 'Blue',
        'capacity': 35,
      });
      expect(SectionModels.updateBody(sectionA, displayName: 'Blue'), {
        'version': 2,
        'displayName': 'Blue',
        'capacity': null,
      });
    });
  });

  group('repository', () {
    test('lists the sections of a class from SEC-01, encoding the ID it puts in the path', () async {
      final (:repository, :adapter) = build(() => okReply([sectionJson()]));
      expect(await repository.sections('a/b'), [sectionA]);
      expect(adapter.paths, ['/v1/classes/a%2Fb/sections']);
    });

    test('adds a section with SEC-02', () async {
      final (:repository, :adapter) = build(() => okReply(sectionJson(), status: 201));
      expect(await repository.create('k1', predefinedSectionId: 's1', capacity: 40), sectionA);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.paths, ['/v1/sections']);
      expect(adapter.requests.single.data, {'classId': 'k1', 'predefinedSectionId': 's1', 'capacity': 40});
    });

    test('changes a section with SEC-03, sending the version it read', () async {
      final (:repository, :adapter) = build(() => okReply(sectionJson(version: 3)));
      await repository.update(sectionA, displayName: 'Blue', capacity: 35);
      expect(adapter.paths, ['/v1/sections/e1']);
      expect(adapter.requests.single.method, 'PATCH');
      expect((adapter.requests.single.data as Map)['version'], 2);
    });

    test('deactivates a section with SEC-04, encoding the ID it puts in the path', () async {
      final (:repository, :adapter) = build(() => okReply({'id': 'a/b', 'status': 0}));
      await repository.deactivate('a/b');
      expect(adapter.paths, ['/v1/sections/a%2Fb']);
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('turns a refusal into an ApiFailure for the screen', () async {
      for (final (status, code) in [(409, 'DUPLICATE'), (409, 'HAS_STUDENTS'), (404, 'NOT_FOUND')]) {
        final (:repository, adapter: _) = build(() => errorReply(status, code));
        await expectLater(
          repository.deactivate('e1'),
          throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)),
        );
      }
    });
  });
}
