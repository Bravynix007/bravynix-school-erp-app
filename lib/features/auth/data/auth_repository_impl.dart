import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/auth/data/models/auth_models.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  new({
    required this._api,
    required this._tokens,
    required this._device,
    required this._events,
  });

  final ApiClient _api;
  final TokenStorage _tokens;
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
    final data = await _api.data<Map<String, dynamic>>(
      'auth/otp/verify',
      method: HttpMethod.post,
      anonymous: true,
      body: {'email': email.trim().toLowerCase(), 'code': code, 'clientType': _mobile, 'device': _device.toJson()},
      parse: (data) => data! as Map<String, dynamic>,
    );
    await _tokens.write(AuthModels.tokens(data));
    return AuthModels.session(data);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (await _tokens.read() == null) return null;
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

  @override
  Future<void> logout({bool everywhere = false}) async {
    try {
      await _api.data<void>(everywhere ? 'auth/logout-all' : 'auth/logout', method: HttpMethod.post, parse: (_) {});
    } on ApiFailure {
      // The server session may already be gone; signing out locally is what matters.
    } finally {
      await _tokens.clear();
    }
  }
}
