import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/field_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('says the codes a form raises itself in the app’s words, and the rest as the server did', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(fieldErrorText(l10n, const FieldError.required('firstName')), 'This field is required.');
    expect(
      fieldErrorText(l10n, const FieldError(field: 'a', code: 'INVALID_AADHAAR', message: 'server')),
      l10n.errorAadhaarInvalid,
    );
    expect(
      fieldErrorText(l10n, const FieldError(field: 'a', code: 'TOO_SHORT', message: 'Too short, said the server')),
      'Too short, said the server',
    );
  });
}
