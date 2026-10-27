import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  String blocked(Map<String, Object?> details) =>
      roleErrorText(l10n, ApiFailure(statusCode: 423, code: 'SECTION_BLOCKED', message: '', details: details));

  test('a blocked Society’s Owners are sent to BravyNix support', () {
    expect(blocked({'section': 'owners'}), 'Access to your Society is blocked. Contact BravyNix support.');
  });

  test('blocked staff or parents are sent to their Society', () {
    expect(blocked({'section': 'staff'}), 'Access is blocked for your group. Contact your Society.');
    expect(blocked({'section': 'students'}), 'Access is blocked for your group. Contact your Society.');
    expect(blocked({}), 'Access is blocked for your group. Contact your Society.');
  });
}
