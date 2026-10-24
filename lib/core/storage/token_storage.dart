import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokens extends Equatable {
  const new({required this.accessToken, required this.refreshToken});

  final String accessToken;

  /// Opaque, single use, rotated on every refresh (API design 6.1).
  final String refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];

  @override
  String toString() => 'AuthTokens(<redacted>)';
}

/// Where the session's tokens live. The app keeps them in the Keychain or
/// Keystore only (system design 13, mobile row), and caches them in memory.
abstract class TokenStorage {
  /// Completes once the stored tokens can be read. On iOS the Keychain is out
  /// of reach until the phone's first unlock, which a prewarmed or background
  /// launch can come before.
  Future<void> waitUntilAvailable();
  Future<AuthTokens?> read();

  /// Keeps [tokens] in memory first, so they are used even if saving them
  /// then fails, and throws that failure.
  Future<void> write(AuthTokens tokens);

  /// Forgets the tokens in memory first, then in storage.
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  new([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          );

  /// Both tokens in one value, so a write is all or nothing: a kill between
  /// two writes could otherwise keep a spent refresh token, whose next use
  /// ends the session as REFRESH_TOKEN_REUSED (API design 6.3).
  static const _key = 'auth.tokens';

  /// Where builds before 24 Oct 2026 kept the tokens; deleted on every clear.
  static const _legacyKeys = ['auth.access_token', 'auth.refresh_token'];

  final FlutterSecureStorage _storage;
  AuthTokens? _cache;
  bool _loaded = false;

  @override
  Future<void> waitUntilAvailable() async {
    // null on Android and other platforms, where there is nothing to wait for.
    if (await _storage.isCupertinoProtectedDataAvailable() ?? true) return;
    await _storage.onCupertinoProtectedDataAvailabilityChanged?.firstWhere((available) => available);
  }

  @override
  Future<AuthTokens?> read() async {
    if (_loaded) return _cache;
    _cache = _decode(await _storage.read(key: _key));
    _loaded = true;
    return _cache;
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    // Memory first: after a refresh the old refresh token is spent, and using
    // it again ends the session as REFRESH_TOKEN_REUSED (API design 6.3). If
    // saving fails, this run still holds the new pair (re-review R-A6).
    _cache = tokens;
    _loaded = true;
    await _storage.write(
      key: _key,
      value: jsonEncode({'accessToken': tokens.accessToken, 'refreshToken': tokens.refreshToken}),
    );
  }

  @override
  Future<void> clear() async {
    // Memory first, so this run is signed out even if the delete fails.
    _cache = null;
    _loaded = true;
    await _storage.delete(key: _key);
    for (final key in _legacyKeys) {
      await _storage.delete(key: key);
    }
  }

  static AuthTokens? _decode(String? value) {
    if (value == null) return null;
    try {
      final json = jsonDecode(value);
      if (json case {'accessToken': final String access, 'refreshToken': final String refresh}) {
        return AuthTokens(accessToken: access, refreshToken: refresh);
      }
    } on FormatException {
      // A damaged value is treated as no session.
    }
    return null;
  }
}

/// For tests and previews.
class InMemoryTokenStorage implements TokenStorage {
  new([this._tokens]);

  AuthTokens? _tokens;

  @override
  Future<void> waitUntilAvailable() async {}

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
