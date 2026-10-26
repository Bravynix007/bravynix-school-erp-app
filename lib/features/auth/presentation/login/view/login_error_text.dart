import 'dart:math';

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
      final lock = failure.retryAfter;
      return lock == null ? l10n.errorOtpAttemptsExceeded : l10n.errorOtpAttemptsLocked(_lockLength(l10n, lock));
    case 'OTP_RESEND_TOO_SOON':
      return l10n.errorOtpResendTooSoon;
    case 'OTP_REQUEST_LIMIT':
      return l10n.errorOtpRequestLimit;
    case 'AUTH_LOCKED':
      final lock = failure.retryAfter;
      return lock == null ? l10n.errorAuthLocked : l10n.errorAuthLockedFor(_lockLength(l10n, lock));
    case 'RATE_LIMITED':
      return l10n.errorRateLimited;
    case 'ACCOUNT_BLOCKED':
      return l10n.errorAccountBlocked;
    case ApiFailure.networkError:
    case ApiFailure.timeoutError:
      return l10n.errorNetwork;
    case ApiFailure.storageError:
      return l10n.errorDeviceStorage;
  }
  if (failure.statusCode >= 500 && failure.requestId != null) {
    return l10n.errorWithRequestId(failure.requestId!);
  }
  return failure.message.isNotEmpty ? failure.message : l10n.errorGeneric;
}

/// A lock of 30 minutes or 24 hours, as the lockout email words it. It rounds
/// up, so nobody tries again a minute early and is refused.
String _lockLength(AppLocalizations l10n, Duration lock) {
  if (lock.inSeconds >= Duration.secondsPerHour) {
    return l10n.durationHours((lock.inSeconds / Duration.secondsPerHour).ceil());
  }
  return l10n.durationMinutes(max(1, (lock.inSeconds / Duration.secondsPerMinute).ceil()));
}
