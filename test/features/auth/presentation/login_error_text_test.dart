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
}
