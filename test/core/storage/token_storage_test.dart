import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Secure storage whose writes fail, as when the app is killed or the Keystore errors.
class _FailingWrites extends FlutterSecureStorage {
  const new();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'KeystoreError');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tokens = AuthTokens(accessToken: 'a1', refreshToken: 'r1');

  group('SecureTokenStorage (review A6)', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('keeps both tokens in one value and reads them back', () async {
      await SecureTokenStorage().write(tokens);

      final stored = await const FlutterSecureStorage().readAll();
      expect(stored.keys, ['auth.tokens']);
      expect(await SecureTokenStorage().read(), tokens);
    });

    test('does not change the cached tokens when the write fails', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth.tokens': '{"accessToken":"a0","refreshToken":"r0"}',
      });
      final storage = SecureTokenStorage(const _FailingWrites());
      expect(await storage.read(), const AuthTokens(accessToken: 'a0', refreshToken: 'r0'));

      await expectLater(storage.write(tokens), throwsA(isA<PlatformException>()));
      expect(await storage.read(), const AuthTokens(accessToken: 'a0', refreshToken: 'r0'));
    });

    test('treats a damaged value as no session', () async {
      FlutterSecureStorage.setMockInitialValues({'auth.tokens': 'not json'});
      expect(await SecureTokenStorage().read(), isNull);
    });

    test('clear removes the tokens', () async {
      final storage = SecureTokenStorage();
      await storage.write(tokens);
      await storage.clear();
      expect(await SecureTokenStorage().read(), isNull);
    });
  });

  group('clearTokensOnFirstStart (review A7)', () {
    test('clears tokens left by a previous install, once', () async {
      final storage = InMemoryTokenStorage(tokens);
      final marker = InMemoryInstallMarker();

      await clearTokensOnFirstStart(marker: marker, tokens: storage);
      expect(await storage.read(), isNull);
      expect(await marker.isSet(), isTrue);

      await storage.write(tokens);
      await clearTokensOnFirstStart(marker: marker, tokens: storage);
      expect(await storage.read(), tokens);
    });
  });
}
