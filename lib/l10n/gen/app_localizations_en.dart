// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BravyNix';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Enter your email and we\'ll send you a 6-digit code.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequired => 'Enter your email address.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get sendCode => 'Send code';

  @override
  String get codeTitle => 'Check your email';

  @override
  String codeSubtitle(String email) {
    return 'Enter the 6-digit code sent to $email';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String get verify => 'Verify';

  @override
  String resendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String errorOtpInvalid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return 'Incorrect code. $_temp0 left.';
  }

  @override
  String get errorOtpInvalidNoCount => 'Incorrect code.';

  @override
  String get errorOtpExpired => 'This code has expired. Request a new one.';

  @override
  String get errorOtpAttemptsExceeded => 'Too many incorrect codes. Request a new one.';

  @override
  String errorOtpAttemptsLocked(String duration) {
    return 'Too many incorrect codes. Try again in $duration.';
  }

  @override
  String get errorOtpResendTooSoon => 'Wait a minute before asking for another code.';

  @override
  String get errorOtpRequestLimit => 'Too many codes requested. Try again later.';

  @override
  String get errorAuthLocked => 'Too many failed sign-ins. This email is locked for 30 minutes.';

  @override
  String errorAuthLockedFor(String duration) {
    return 'Too many failed sign-ins. Try again in $duration.';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get startAgain => 'Start again';

  @override
  String get errorRateLimited => 'Too many attempts. Try again shortly.';

  @override
  String get errorAccountBlocked => 'This account is blocked and can\'t access the app.';

  @override
  String get errorNetwork => 'Can\'t reach the server. Check your connection and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorDeviceStorage => 'Couldn\'t read or save your sign-in on this phone. Try again.';

  @override
  String errorWithRequestId(String requestId) {
    return 'Something went wrong. Reference: $requestId';
  }

  @override
  String get sessionEndedTitle => 'You\'ve been signed out';

  @override
  String get sessionEndedExpired => 'Your session expired. Sign in again.';

  @override
  String get sessionEndedBlocked => 'This account is blocked.';

  @override
  String get sessionEndedElsewhere => 'You were signed out from another device.';

  @override
  String get sessionEndedAdminRevoked =>
      'Your Institution Admin access was removed. Sign in again to use your other roles.';

  @override
  String get sessionEndedEmailChanged => 'The email for this account was changed. Sign in with the new address.';

  @override
  String get sessionEndedGeneric => 'Your session has ended. Sign in again.';

  @override
  String get signOutIncomplete =>
      'You\'re signed out, but this phone couldn\'t forget your sign-in. Sign in and log out again to finish.';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version of the app is no longer supported. Update it from the store to continue.';

  @override
  String get homeTitle => 'Home';

  @override
  String homeWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeComingSoon => 'Your home screen arrives with the next modules of the build plan.';

  @override
  String get logOut => 'Log out';

  @override
  String get loading => 'Loading';
}
