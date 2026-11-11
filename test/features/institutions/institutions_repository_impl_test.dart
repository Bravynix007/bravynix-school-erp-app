import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/institutions/data/institutions_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/institutions.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({InstitutionsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: InstitutionsRepositoryImpl(api: api), adapter: adapter);
  }

  test('lists the Institutions of the caller from INS-01', () async {
    final (:repository, :adapter) = build(() => okReply([summaryJson()]));
    expect(await repository.institutions(), [summary()]);
    expect(adapter.paths, ['/v1/institutions']);
    expect(adapter.requests.single.method, 'GET');
  });

  test('reads one Institution from INS-03, encoding the ID it puts in the path', () async {
    final (:repository, :adapter) = build(() => okReply(institutionJson()));
    expect(await repository.institution('a/b'), institution);
    expect(adapter.paths, ['/v1/institutions/a%2Fb']);
  });

  test('deactivates with INS-05', () async {
    final (:repository, :adapter) = build(() => okReply({'id': 'i1', 'status': 0}));
    await repository.deactivate('i1');
    expect(adapter.paths, ['/v1/institutions/i1']);
    expect(adapter.requests.single.method, 'DELETE');
  });

  group('Admin access', () {
    test('lists a page of the Admins of an Institution from INS-08, and says whether there are more', () async {
      final (:repository, :adapter) = build(
        () => okReply([adminJson()], meta: {'page': 2, 'limit': 20, 'totalItems': 41, 'totalPages': 3}),
      );
      final page = await repository.admins('i1', page: 2);
      expect(page.items, [adminOf()]);
      expect([page.page, page.totalPages, page.hasMore], [2, 3, true]);
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.uri.path, '/v1/institutions/i1/admins');
      expect(adapter.requests.single.uri.queryParameters, {'page': '2'});
    });

    test('takes an answer without page numbers as the whole list', () async {
      final (:repository, adapter: _) = build(() => okReply([adminJson()]));
      expect((await repository.admins('i1')).hasMore, isFalse);
    });

    test('grants with INS-09, sending the staff member', () async {
      final (:repository, :adapter) = build(() => okReply(adminJson(), status: 201));
      expect(await repository.grantAdmin('i1', 'f1'), adminOf());
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.uri.path, '/v1/institutions/i1/admins');
      expect(bodyOf(adapter.requests.single), {'staffMemberId': 'f1'});
    });

    test('revokes with INS-10, encoding the IDs it puts in the path', () async {
      final (:repository, :adapter) = build(() => okReply(null));
      await repository.revokeAdmin('i/1', 'f/1');
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.paths, ['/v1/institutions/i%2F1/admins/f%2F1']);
    });

    test('turns the refusals into an ApiFailure with the code of the API', () async {
      final (:repository, adapter: _) = build(
        () => errorReply(409, 'ALREADY_ADMIN'),
      );
      await expectLater(
        repository.grantAdmin('i1', 'f1'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'ALREADY_ADMIN')),
      );
    });
  });

  test('turns a 403, a 404 and a 423 into an ApiFailure for the screen', () async {
    final (:repository, adapter: _) = build(() => errorReply(403, 'FORBIDDEN'));
    await expectLater(
      repository.deactivate('i1'),
      throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'FORBIDDEN')),
    );
    final (repository: missing, adapter: _) = build(() => errorReply(404, 'NOT_FOUND'));
    await expectLater(missing.institution('i9'), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'NOT_FOUND')));
    final (repository: blocked, adapter: _) = build(
      () => errorReply(
        423,
        'SECTION_BLOCKED',
        extra: {
          'data': {'section': 'staff'},
        },
      ),
    );
    await expectLater(
      blocked.institution('i1'),
      throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'SECTION_BLOCKED')),
    );
  });

  test('turns an answer it cannot read into an ApiFailure, not a crash', () async {
    final (:repository, adapter: _) = build(() => okReply({'id': 'i1'}));
    await expectLater(repository.institution('i1'), throwsA(isA<ApiFailure>()));
  });
}
