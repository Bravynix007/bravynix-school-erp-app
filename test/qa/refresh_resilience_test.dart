// QA: a flaky network during a token refresh must not sign the user out
// (QA strategy 8, API design 8.2: a network failure means "not saved, retry",
// not "session ended"). Parents and teachers often use weak mobile data.
import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_http.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  test('a connection error on refresh keeps the stored tokens and ends no session', () async {
    final events = ApiEvents();
    final tokens = InMemoryTokenStorage();
    await tokens.write(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
    var ended = false;
    events.sessionEnded.listen((_) => ended = true);

    final adapter = FakeHttpAdapter((options) async {
      if (options.path.endsWith('auth/refresh')) {
        throw DioException.connectionError(requestOptions: options, reason: 'no network');
      }
      return errorReply(401, 'TOKEN_EXPIRED');
    });
    final client = createApiClient(
      config: config,
      device: device,
      tokens: tokens,
      events: events,
      language: () => 'en',
      adapter: adapter,
    );

    await expectLater(client.data<Object?>('me', parse: (d) => d), throwsA(anything));
    await Future<void>.delayed(Duration.zero);

    expect(await tokens.read(), isNotNull, reason: 'tokens were wiped by a network blip');
    expect(ended, isFalse, reason: 'the user was signed out by a network blip');
  });
}
