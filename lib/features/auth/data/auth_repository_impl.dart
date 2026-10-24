import 'dart:developer' show log;

import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/auth/data/models/auth_models.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  new({
    required this._api,
    required this._tokens,
    required this._installMarker,
    required this._device,
    required this._events,
  });

  final ApiClient _api;
  final TokenStorage _tokens;
  final InstallMarker _installMarker;
  final AppDevice _device;
  final ApiEvents _events;

  /// `clientType` 1 is the mobile app (API design 10.1).
  static const _mobile = 1;

  @override
  Stream<ApiFailure> get sessionEnded => _events.sessionEnded;

  @override
  Future<OtpRequested> requestOtp(String email) => _api.data(
    'auth/otp',
    method: HttpMethod.post,
    anonymous: true,
    body: {'email': email.trim().toLowerCase(), 'clientType': _mobile},
    parse: AuthModels.otpRequested,
  );

  @override
  Future<AuthSession> verifyOtp({required String email, required String code}) async {
    // Both parse inside the client, so a malformed answer is an ApiFailure and
    // no tokens are stored for a session the app could not read.
    final (tokens, session) = await _api.data(
      'auth/otp/verify',
      method: HttpMethod.post,
      anonymous: true,
      body: {'email': email.trim().toLowerCase(), 'code': code, 'clientType': _mobile, 'device': _device.toJson()},
      parse: (data) => (AuthModels.tokens(data), AuthModels.session(data)),
    );
    await _secure(() => _tokens.write(tokens));
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final tokens = await _readSaved();
    try {
      // After the read, which proves the preferences are readable too.
      if (await clearTokensOnFirstStart(marker: _installMarker, tokens: _tokens)) return null;
    } on Object catch (error, stackTrace) {
      // Fail closed: tokens that were due to go are never restored. They are
      // already gone from memory, and the next start tries again (final pass).
      log('Could not clear the stored tokens on start', name: 'auth', error: error, stackTrace: stackTrace);
      return null;
    }
    if (tokens == null) return null;
    try {
      // ME-01 carries the same person and contexts as the login answer.
      return await _api.data('me', parse: AuthModels.session);
    } on ApiFailure catch (failure) {
      // A dead session was already cleared by the auth interceptor. Anything
      // else (offline, 503) keeps the tokens so the splash can retry.
      if (failure.isSessionEnded) return null;
      rethrow;
    }
  }

  /// The saved tokens. A read that fails while the phone's protected data is
  /// available will fail on every launch (a damaged Keystore entry), so the
  /// tokens are cleared and the person signs in again rather than meeting
  /// Try again for ever (final pass). While the phone is locked the failure
  /// may pass, so the splash offers Try again.
  Future<AuthTokens?> _readSaved() async {
    try {
      return await _tokens.read();
    } on Object catch (error, stackTrace) {
      log('Could not read the stored tokens', name: 'auth', error: error, stackTrace: stackTrace);
      final available = await _secure(_tokens.isProtectedDataAvailable);
      if (!available) throw const ApiFailure.storage();
      await _secure(_tokens.clear);
      return null;
    }
  }

  /// Ends the session here even if the server cannot be told. Throws
  /// [ApiFailure.storage] only when the stored tokens could neither be
  /// deleted nor marked for deletion, so the next start could restore them.
  @override
  Future<void> logout({bool everywhere = false}) async {
    try {
      await _api.data<void>(everywhere ? 'auth/logout-all' : 'auth/logout', method: HttpMethod.post, parse: (_) {});
    } on ApiFailure {
      // The server session may already be gone; signing out locally is what matters.
    }
    try {
      await _tokens.clear();
    } on Object catch (error, stackTrace) {
      // The tokens are gone from memory, so this run is signed out; the next
      // start deletes the stored ones before reading them (final pass).
      log('Could not delete the stored tokens', name: 'auth', error: error, stackTrace: stackTrace);
      await _secure(() => _installMarker.setSignOutPending(pending: true));
    }
  }

  /// Runs a Keychain or Keystore call. A platform failure (a missing key, a
  /// locked Keychain) becomes an [ApiFailure], which the splash and login
  /// already show with a way to try again; anything else would leave them
  /// waiting for ever (re-review R-A1).
  Future<T> _secure<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      log('Secure storage failed', name: 'auth', error: error, stackTrace: stackTrace);
      throw const ApiFailure.storage();
    }
  }
}
