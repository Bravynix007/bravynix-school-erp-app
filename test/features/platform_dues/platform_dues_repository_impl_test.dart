import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/platform_dues/data/platform_dues_repository_impl.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/platform_dues.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({PlatformDuesRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: PlatformDuesRepositoryImpl(api: api), adapter: adapter);
  }

  test('reads the total and the dues of the Owner’s Society from BIL-01', () async {
    final (:repository, :adapter) = build(
      () => okReply({
        'banner': {'totalDueAmount': '80000.00', 'hasOpenDues': true},
        'dues': [dueLineJson()],
      }),
    );
    final dues = await repository.dues();
    expect(dues.totalDueAmount, '80000.00');
    expect(dues.dues.single.status, DueStatus.due);
    expect(adapter.paths, ['/v1/platform-dues']);
    expect(adapter.requests.single.method, 'GET');
  });

  test('reads one due from BIL-02, encoding the ID it puts in the path', () async {
    final (:repository, :adapter) = build(
      () => okReply({
        ...dueLineJson(),
        'studentCount': 1650,
        'ratePerStudentAmount': '50.00',
        'baseAmount': '82500.00',
        'adjustmentAmount': '-2500.00',
        'adjustmentNote': null,
      }),
    );
    final read = await repository.due('a/b');
    expect(read.studentCount, 1650);
    expect(adapter.paths, ['/v1/platform-dues/a%2Fb']);
  });

  test('turns a 403 and a 404 into an ApiFailure for the screen', () async {
    final (:repository, adapter: _) = build(() => errorReply(403, 'FORBIDDEN'));
    await expectLater(repository.dues(), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'FORBIDDEN')));
    final (repository: missing, adapter: _) = build(() => errorReply(404, 'NOT_FOUND'));
    await expectLater(missing.due('d9'), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'NOT_FOUND')));
  });

  test('turns an answer it cannot read into an ApiFailure, not a crash', () async {
    final (:repository, adapter: _) = build(() => okReply({'banner': null, 'dues': <Object?>[]}));
    await expectLater(repository.dues(), throwsA(isA<ApiFailure>()));
  });
}
