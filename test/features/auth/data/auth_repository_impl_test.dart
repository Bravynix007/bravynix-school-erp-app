import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/auth/data/auth_repository_impl.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http.dart';

/// Token storage whose Keychain or Keystore calls can fail, on a phone that can be locked.
class _FakeStorage implements TokenStorage {
  new({this.tokens, this.failReads = false, this.failWrites = false, this.failClears = false, this.available = true});

  AuthTokens? tokens;
  bool failReads;
  final bool failWrites;
  bool failClears;
  bool available;
  final List<String> calls = [];

  @override
  Future<bool> isProtectedDataAvailable() async => available;

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

/// A marker whose preferences cannot be saved.
class _BrokenMarker extends InMemoryInstallMarker {
  new() : super(started: true);

  @override
  Future<void> setSignOutPending({required bool pending}) async => throw PlatformException(code: 'PrefsError');
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
    test('a failed read while the phone is locked lets the splash offer Try again', () async {
      final storage = _FakeStorage(tokens: saved, failReads: true, available: false);
      final (:repository, :adapter) = build(storage);
      await expectLater(repository.restoreSession(), throwsA(storageFailure));
      expect(storage.calls, ['read']);
      expect(adapter.requests, isEmpty);
    });

    test('a failed save after the code is checked is shown on the login screen', () async {
      final (:repository, adapter: _) = build(_FakeStorage(failWrites: true));
      await expectLater(repository.verifyOtp(email: 'diya@two-worlds.test', code: '482017'), throwsA(storageFailure));
    });
  });

  group('a read that fails on every launch (final pass)', () {
    test('clears the tokens and signs out instead of offering Try again for ever', () async {
      final storage = _FakeStorage(tokens: saved, failReads: true);
      final (:repository, :adapter) = build(storage);
      expect(await repository.restoreSession(), isNull);
      expect(storage.calls, ['read', 'clear']);
      expect(storage.tokens, isNull);
      expect(adapter.requests, isEmpty);
    });
  });

  group('logout that cannot delete the stored tokens (final pass)', () {
    test('marks them, and the next start deletes them before reading', () async {
      final storage = _FakeStorage(tokens: saved, failClears: true);
      final marker = InMemoryInstallMarker(started: true);
      final (:repository, adapter: _) = build(storage, marker: marker, reply: (_) async => okReply(null));
      await repository.logout();
      expect(await marker.isSignOutPending(), isTrue);
      expect(storage.tokens, saved);

      storage.failClears = false;
      final (repository: nextStart, :adapter) = build(storage, marker: marker);
      expect(await nextStart.restoreSession(), isNull);
      expect(storage.calls, contains('clear'));
      expect(storage.tokens, isNull);
      expect(await marker.isSignOutPending(), isFalse);
      expect(adapter.requests, isEmpty);
    });

    test('throws when the tokens can be neither deleted nor marked', () async {
      final storage = _FakeStorage(tokens: saved, failClears: true);
      final (:repository, adapter: _) = build(storage, marker: _BrokenMarker(), reply: (_) async => okReply(null));
      await expectLater(repository.logout(), throwsA(storageFailure));
    });

    test('a start whose delete fails again signs out rather than restoring', () async {
      final storage = _FakeStorage(tokens: saved, failClears: true);
      final marker = InMemoryInstallMarker(started: true, signOutPending: true);
      final (:repository, :adapter) = build(storage, marker: marker);
      expect(await repository.restoreSession(), isNull);
      expect(await marker.isSignOutPending(), isTrue);
      expect(adapter.requests, isEmpty);
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

    test('a launch while the phone is locked restores the session without waiting', () async {
      final storage = _FakeStorage(tokens: saved, available: false);
      final (:repository, adapter: _) = build(storage, marker: InMemoryInstallMarker(started: true));

      expect(await repository.restoreSession(), isNotNull);
      // Read by the repository, then by the interceptor for ME-01; never cleared.
      expect(storage.calls, ['read', 'read']);
      expect(storage.tokens, saved);
    });

    test('a locked launch still finishes a pending sign-out once the tokens are readable', () async {
      final storage = _FakeStorage(tokens: saved, available: false);
      final marker = InMemoryInstallMarker(started: true, signOutPending: true);
      final (:repository, :adapter) = build(storage, marker: marker);

      expect(await repository.restoreSession(), isNull);
      expect(storage.tokens, isNull);
      expect(await marker.isSignOutPending(), isFalse);
      expect(adapter.requests, isEmpty);
    });
  });

  group('switchContext (AUTH-06)', () {
    const owner = AuthContext(role: RoleCode.societyOwner, societyId: 's2');
    const parent = AuthContext(role: RoleCode.studentParent);

    test('sends the role and Society, and keeps the new access token with the same refresh token', () async {
      final storage = _FakeStorage(tokens: saved);
      final (:repository, :adapter) = build(storage, reply: (_) async => okReply({'accessToken': 'a9'}));
      await repository.switchContext(owner);
      expect(adapter.requests.single.uri.path, '/v1/auth/context');
      expect(adapter.requests.single.data, {'roleCode': 2, 'societyId': 's2'});
      expect(storage.tokens, const AuthTokens(accessToken: 'a9', refreshToken: 'r1'));
    });

    test('leaves the Society out for a parent, whose role spans Societies', () async {
      final (:repository, :adapter) = build(
        _FakeStorage(tokens: saved),
        reply: (_) async => okReply({'accessToken': 'a9'}),
      );
      await repository.switchContext(parent);
      expect(adapter.requests.single.data, {'roleCode': 5});
    });

    test('a refusal keeps the tokens as they were', () async {
      final storage = _FakeStorage(tokens: saved);
      final (:repository, adapter: _) = build(storage, reply: (_) async => errorReply(403, 'CONTEXT_NOT_AVAILABLE'));
      await expectLater(
        repository.switchContext(owner),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'CONTEXT_NOT_AVAILABLE')),
      );
      expect(storage.tokens, saved);
    });

    test('an answer without an access token is an error, not a half-switched session', () async {
      final storage = _FakeStorage(tokens: saved);
      final (:repository, adapter: _) = build(storage, reply: (_) async => okReply({'activeContext': null}));
      await expectLater(repository.switchContext(owner), throwsA(isA<ApiFailure>()));
      expect(storage.tokens, saved);
    });

    test('a failed save is a storage failure', () async {
      final (:repository, adapter: _) = build(
        _FakeStorage(tokens: saved, failWrites: true),
        reply: (_) async => okReply({'accessToken': 'a9'}),
      );
      await expectLater(repository.switchContext(owner), throwsA(storageFailure));
    });
  });
}
