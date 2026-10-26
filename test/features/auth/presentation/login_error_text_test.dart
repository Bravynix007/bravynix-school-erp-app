import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('a secure storage failure has its own copy (re-review R-A1)', () {
    expect(
      loginErrorText(l10n, const ApiFailure.storage()),
      "Couldn't read or save your sign-in on this phone. Try again.",
    );
  });

  test('a half-formed gateway answer reads as a generic error', () {
    expect(loginErrorText(l10n, const ApiFailure.unexpected(400)), 'Something went wrong');
  });

  String lock(String code, Duration? retryAfter) =>
      loginErrorText(l10n, ApiFailure(statusCode: 423, code: code, message: '', retryAfter: retryAfter));

  group('a lock says for how long, rounded up', () {
    test('minutes', () {
      expect(lock('AUTH_LOCKED', const Duration(minutes: 30)), 'Too many failed sign-ins. Try again in 30 minutes.');
      expect(lock('AUTH_LOCKED', const Duration(seconds: 61)), 'Too many failed sign-ins. Try again in 2 minutes.');
      expect(lock('AUTH_LOCKED', const Duration(seconds: 5)), 'Too many failed sign-ins. Try again in 1 minute.');
    });

    test('hours from one hour up', () {
      expect(lock('AUTH_LOCKED', const Duration(hours: 24)), 'Too many failed sign-ins. Try again in 24 hours.');
      expect(lock('AUTH_LOCKED', const Duration(hours: 1)), 'Too many failed sign-ins. Try again in 1 hour.');
      expect(lock('AUTH_LOCKED', const Duration(seconds: 3601)), 'Too many failed sign-ins. Try again in 2 hours.');
    });

    test('the fifth wrong code names the wait too', () {
      expect(
        lock('OTP_ATTEMPTS_EXCEEDED', const Duration(minutes: 30)),
        'Too many incorrect codes. Try again in 30 minutes.',
      );
    });

    test('without a length they fall back to the plain copy', () {
      expect(lock('AUTH_LOCKED', null), 'Too many failed sign-ins. This email is locked for 30 minutes.');
      expect(lock('OTP_ATTEMPTS_EXCEEDED', null), 'Too many incorrect codes. Request a new one.');
    });
  });

  group('isLockedOut', () {
    ApiFailure failure(String code, {Duration? retryAfter}) =>
        ApiFailure(statusCode: 423, code: code, message: '', retryAfter: retryAfter);

    test('is true for AUTH_LOCKED and for a spent code with a lock length', () {
      expect(failure('AUTH_LOCKED').isLockedOut, isTrue);
      expect(failure('OTP_ATTEMPTS_EXCEEDED', retryAfter: const Duration(minutes: 30)).isLockedOut, isTrue);
    });

    test('is false for a dead code that can simply be requested again', () {
      expect(failure('OTP_ATTEMPTS_EXCEEDED').isLockedOut, isFalse);
      expect(failure('OTP_EXPIRED').isLockedOut, isFalse);
    });
  });
}
