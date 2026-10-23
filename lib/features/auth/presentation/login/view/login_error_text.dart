import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for each login error code (API design 6.2, 10.1, 10.2). Unknown codes
/// fall back to the server's message, which is already in the user's language.
String loginErrorText(AppLocalizations l10n, ApiFailure failure) {
  switch (failure.code) {
    case 'OTP_INVALID':
      final left = (failure.details['attemptsLeft'] as num?)?.toInt();
      return left == null ? l10n.errorOtpInvalidNoCount : l10n.errorOtpInvalid(left);
    case 'OTP_EXPIRED':
      return l10n.errorOtpExpired;
    case 'OTP_ATTEMPTS_EXCEEDED':
      return l10n.errorOtpAttemptsExceeded;
    case 'OTP_RESEND_TOO_SOON':
      return l10n.errorOtpResendTooSoon;
    case 'OTP_REQUEST_LIMIT':
      return l10n.errorOtpRequestLimit;
    case 'AUTH_LOCKED':
      return l10n.errorAuthLocked;
    case 'RATE_LIMITED':
      return l10n.errorRateLimited;
    case 'ACCOUNT_BLOCKED':
      return l10n.errorAccountBlocked;
    case ApiFailure.networkError:
    case ApiFailure.timeoutError:
      return l10n.errorNetwork;
  }
  if (failure.statusCode >= 500 && failure.requestId != null) {
    return l10n.errorWithRequestId(failure.requestId!);
  }
  return failure.message.isNotEmpty ? failure.message : l10n.errorGeneric;
}
