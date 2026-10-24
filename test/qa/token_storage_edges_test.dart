// QA: a Keystore or Keychain read that fails once (locked phone, background
// launch) must not be remembered as "no session" for the rest of the run,
// which would send a signed-in parent to the login screen.
import 'dart:convert';

import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailsFirstRead extends FlutterSecureStorage {
  new();

  int reads = 0;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    reads += 1;
    if (reads == 1) throw PlatformException(code: 'KeychainLocked');
    return jsonEncode({'accessToken': 'a1', 'refreshToken': 'r1'});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a failed first read is retried, not cached as signed out', () async {
    final storage = SecureTokenStorage(_FailsFirstRead());
    await expectLater(storage.read(), throwsA(isA<PlatformException>()));
    expect(await storage.read(), const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
  });

  test('clear wins over a later failed write of the same run', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecureTokenStorage();
    await storage.write(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
    await storage.clear();
    expect(await storage.read(), isNull);
  });
}
