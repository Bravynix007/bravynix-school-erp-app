import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';

/// Token storage whose Keystore access fails, as a PlatformException would.
class _BrokenTokenStorage implements TokenStorage {
  @override
  Future<AuthTokens?> read() async => throw PlatformException(code: 'KeystoreError');

  @override
  Future<void> write(AuthTokens tokens) async => throw PlatformException(code: 'KeystoreError');

  @override
  Future<void> clear() async {}
}

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  late ApiEvents events;
  late List<ApiFailure> ended;
  late List<ApiFailure> updates;

  setUp(() {
    events = ApiEvents();
    ended = [];
    updates = [];
    events.sessionEnded.listen(ended.add);
    events.updateRequired.listen(updates.add);
  });

  ApiClient clientWith(TokenStorage tokens, FakeHttpAdapter adapter) => createApiClient(
    config: config,
    device: device,
    tokens: tokens,
    events: events,
    language: () => 'en',
    adapter: adapter,
  );

  FakeHttpAdapter expiredThen(Future<FakeReply> Function() refresh) => FakeHttpAdapter(
    (options) async => options.path == 'auth/refresh' ? await refresh() : errorReply(401, 'TOKEN_EXPIRED'),
  );

  group('refresh failures that are not a 401 keep the session (review A3)', () {
    test('a 503 on refresh passes through and keeps the tokens', () async {
      final tokens = InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
      final client = clientWith(tokens, expiredThen(() async => errorReply(503, 'SERVICE_UNAVAILABLE')));

      await expectLater(
        client.data<Object?>('me', parse: (d) => d),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'SERVICE_UNAVAILABLE')),
      );
      await pumpEventQueue();

      expect(await tokens.read(), isNotNull);
      expect(ended, isEmpty);
    });

    test('a 426 on refresh opens "Update required" instead of signing out', () async {
      final tokens = InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
      final client = clientWith(tokens, expiredThen(() async => errorReply(426, 'APP_UPDATE_REQUIRED')));

      await expectLater(client.data<Object?>('me', parse: (d) => d), throwsA(isA<ApiFailure>()));
      await pumpEventQueue();

      expect(updates.single.code, 'APP_UPDATE_REQUIRED');
      expect(ended, isEmpty);
      expect(await tokens.read(), isNotNull);
    });

    test('a refused refresh ends the session with the server reason (review A4)', () async {
      final tokens = InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
      final client = clientWith(
        tokens,
        expiredThen(
          () async => errorReply(
            401,
            'SESSION_ENDED',
            extra: {
              'data': {'reason': 'logout_all'},
            },
          ),
        ),
      );

      await expectLater(
        client.data<Object?>('me', parse: (d) => d),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'SESSION_ENDED')),
      );
      await pumpEventQueue();

      expect(ended.single.details['reason'], 'logout_all');
      expect(await tokens.read(), isNull);
    });
  });

  test('a storage error fails the request instead of stalling the queue (review A5)', () async {
    final adapter = FakeHttpAdapter((_) async => okReply({'ok': true}));
    final client = clientWith(_BrokenTokenStorage(), adapter);

    final calls = [
      for (var i = 0; i < 3; i += 1) client.data<Object?>('me', parse: (d) => d),
    ];
    for (final call in calls) {
      await expectLater(call, throwsA(isA<ApiFailure>())).timeout(const Duration(seconds: 2));
    }
    expect(adapter.requests, isEmpty);
  });

  test('an answer that does not fit its model is an ApiFailure (review A9)', () async {
    final tokens = InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
    final client = clientWith(tokens, FakeHttpAdapter((_) async => okReply({'name': 42})));

    await expectLater(
      client.data<String>('me', parse: (d) => (d! as Map<String, dynamic>)['name'] as String),
      throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'UNEXPECTED_RESPONSE')),
    );
  });
}
