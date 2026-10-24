import 'dart:async';

import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/auth/data/auth_repository_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http.dart';

/// Token storage whose Keychain or Keystore calls can fail or wait for the first unlock.
class _FakeStorage implements TokenStorage {
  new({this.tokens, this.failReads = false, this.failWrites = false, this.failClears = false, Future<void>? unlocked})
    : _unlocked = unlocked ?? Future.value();

  AuthTokens? tokens;
  final bool failReads;
  final bool failWrites;
  final bool failClears;
  final Future<void> _unlocked;
  final List<String> calls = [];

  @override
  Future<void> waitUntilAvailable() => _unlocked;

  @override
  Future<AuthTokens?> read() async {
    calls.add('read');
    if (failReads) throw PlatformException(code: 'KeystoreError');
    return tokens;
  }

  @override
  Future<void> write(AuthTokens value) async {
    calls.add('write');
    if (failWrites) throw PlatformException(code: 'KeystoreError');
    tokens = value;
  }

  @override
  Future<void> clear() async {
    calls.add('clear');
    if (failClears) throw PlatformException(code: 'KeystoreError');
    tokens = null;
  }
}

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');
  const saved = AuthTokens(accessToken: 'a1', refreshToken: 'r1');

  final storageFailure = isA<ApiFailure>().having((f) => f.code, 'code', ApiFailure.storageError);

  Map<String, Object?> sessionData() => {
    'accessToken': 'a2',
    'refreshToken': 'r2',
    'accessTokenExpiresAt': '2026-10-24T05:00:00.000Z',
    'person': {'id': 'p1', 'email': 'diya@two-worlds.test', 'firstName': 'Diya', 'lastName': 'Rao'},
    'contexts': <Object?>[],
  };

  ({AuthRepositoryImpl repository, FakeHttpAdapter adapter}) build(
    TokenStorage tokens, {
    InstallMarker? marker,
    Future<FakeReply> Function(String path)? reply,
  }) {
    final events = ApiEvents();
    final answer = reply ?? (_) async => okReply(sessionData());
    final adapter = FakeHttpAdapter((options) => answer(options.path));
    final api = createApiClient(
      config: config,
      device: device,
      tokens: tokens,
      events: events,
      language: () => 'en',
      adapter: adapter,
    );
    return (
      repository: AuthRepositoryImpl(
        api: api,
        tokens: tokens,
        installMarker: marker ?? InMemoryInstallMarker(started: true),
        device: device,
        events: events,
      ),
      adapter: adapter,
    );
  }

  group('secure storage failures become ApiFailures (re-review R-A1)', () {
    test('a failed read while restoring lets the splash offer Try again', () async {
      final (:repository, :adapter) = build(_FakeStorage(tokens: saved, failReads: true));
      await expectLater(repository.restoreSession(), throwsA(storageFailure));
      expect(adapter.requests, isEmpty);
    });

    test('a failed save after the code is checked is shown on the login screen', () async {
      final (:repository, adapter: _) = build(_FakeStorage(failWrites: true));
      await expectLater(repository.verifyOtp(email: 'diya@two-worlds.test', code: '482017'), throwsA(storageFailure));
    });

    test('a failed delete on logout still signs out', () async {
      final storage = _FakeStorage(tokens: saved, failClears: true);
      final (:repository, adapter: _) = build(storage, reply: (_) async => okReply(null));
      await repository.logout();
      expect(storage.calls, contains('clear'));
    });
  });

  group('first start of an install (re-review R-A2)', () {
    test('clears tokens a previous install left, when the session is restored', () async {
      final storage = _FakeStorage(tokens: saved);
      final marker = InMemoryInstallMarker();
      final (:repository, :adapter) = build(storage, marker: marker);

      expect(await repository.restoreSession(), isNull);
      expect(storage.tokens, isNull);
      expect(await marker.isSet(), isTrue);
      expect(adapter.requests, isEmpty);
    });

    test('waits for the first unlock before deciding anything', () async {
      final unlocked = Completer<void>();
      final storage = _FakeStorage(tokens: saved, unlocked: unlocked.future);
      final marker = InMemoryInstallMarker(started: true);
      final (:repository, adapter: _) = build(storage, marker: marker);

      var restored = false;
      final restoring = repository.restoreSession().then((_) => restored = true);
      await pumpEventQueue();
      expect(storage.calls, isEmpty);
      expect(restored, isFalse);

      unlocked.complete();
      await restoring;
      // Read by the repository, then by the interceptor for ME-01; never cleared.
      expect(storage.calls, ['read', 'read']);
      expect(storage.tokens, saved);
    });
  });
}
