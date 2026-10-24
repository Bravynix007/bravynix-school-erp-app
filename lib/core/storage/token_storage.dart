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
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
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

  final FlutterSecureStorage _storage;
  AuthTokens? _cache;
  bool _loaded = false;

  @override
  Future<AuthTokens?> read() async {
    if (_loaded) return _cache;
    _cache = _decode(await _storage.read(key: _key));
    _loaded = true;
    return _cache;
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(
      key: _key,
      value: jsonEncode({'accessToken': tokens.accessToken, 'refreshToken': tokens.refreshToken}),
    );
    // Only once the write has landed, so memory never runs ahead of storage.
    _cache = tokens;
    _loaded = true;
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
    _cache = null;
    _loaded = true;
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
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
