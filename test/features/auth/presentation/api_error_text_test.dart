import 'dart:ui';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String text(int status, String code) => apiErrorText(
    l10n,
    ApiFailure(statusCode: status, code: code, message: 'server words'),
    notFound: 'This thing could not be found.',
  );

  test('says once, for every screen that reads or changes a record, what the codes of API design 8 mean', () {
    expect(text(403, 'FORBIDDEN'), "You don't have access to this.");
    expect(text(400, 'VALIDATION_FAILED'), 'Check the fields marked in red.');
    expect(text(409, 'VERSION_CONFLICT'), 'Someone else changed this. Your changes were not saved.');
    expect(text(404, 'NOT_FOUND'), 'This thing could not be found.');
  });

  test('anything else reads as everywhere else', () {
    expect(text(423, 'ACCESS_BLOCKED'), isNot('server words'));
  });
}
