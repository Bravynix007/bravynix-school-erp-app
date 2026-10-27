import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/blocks/data/blocks_repository_impl.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({BlocksRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: BlocksRepositoryImpl(api: api), adapter: adapter);
  }

  test('reads the blocks of the Owner’s own Society from SOC-02', () async {
    final (:repository, :adapter) = build(
      () => okReply([
        {
          'id': 'b1',
          'section': 'students',
          'institutionId': 'i1',
          'institutionName': 'Sri Vidya High School',
          'reason': 'Annual fee unpaid',
          'blockedAt': '2026-10-27T04:30:00.000Z',
        },
      ]),
    );
    final blocks = await repository.societyBlocks();
    expect(blocks.single.section, BlockSection.students);
    expect(blocks.single.reason, 'Annual fee unpaid');
    expect(adapter.paths, ['/v1/society/access-blocks']);
    expect(adapter.requests.single.method, 'GET');
  });

  test('turns a 403 into an ApiFailure for the screen', () async {
    final (:repository, adapter: _) = build(() => errorReply(403, 'FORBIDDEN'));
    await expectLater(
      repository.societyBlocks(),
      throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'FORBIDDEN')),
    );
  });

  test('turns an answer it cannot read into an ApiFailure, not a crash', () async {
    final (:repository, adapter: _) = build(
      () => okReply([
        {'id': 'b1', 'section': 'nonsense'},
      ]),
    );
    await expectLater(repository.societyBlocks(), throwsA(isA<ApiFailure>()));
  });
}
