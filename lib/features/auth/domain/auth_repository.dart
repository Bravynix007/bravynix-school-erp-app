import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';

/// Login and session for the mobile app (API design 6, AUTH-01 to AUTH-08).
/// Methods throw [ApiFailure]; the blocs turn failures into states.
abstract class AuthRepository {
  /// AUTH-01. Always "sent if registered", so it never reveals whether an email exists.
  Future<OtpRequested> requestOtp(String email);

  /// AUTH-02. Stores the tokens and returns the session.
  Future<AuthSession> verifyOtp({required String email, required String code});

  /// On app start: the stored session, if its tokens still work, else null.
  Future<AuthSession?> restoreSession();

  /// AUTH-07, or AUTH-08 with [everywhere]. Local tokens are cleared even if the call fails.
  /// Throws [ApiFailure.storage] if the phone may still restore the session on its next start.
  Future<void> logout({bool everywhere = false});

  /// 401s that ended the session elsewhere (blocked, signed out on another device).
  Stream<ApiFailure> get sessionEnded;
}
