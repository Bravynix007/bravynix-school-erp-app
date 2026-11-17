import 'dart:ui';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/timetable_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String text(int status, String code) =>
      timetableErrorText(l10n, ApiFailure(statusCode: status, code: code, message: 'server words'));

  test("says in the app's own words what each refusal of the timetable endpoint means", () {
    expect(text(403, 'NOT_ASSIGNED'), 'You can see the timetable of a section you lead or teach.');
    expect(
      text(422, 'CURRENT_YEAR_REQUIRED'),
      'No current academic year has been set up yet, so there is no timetable to show.',
    );
    expect(text(404, 'NOT_FOUND'), 'This timetable could not be found.');
  });

  test('a blocked child and the rest read as everywhere else', () {
    expect(text(403, 'CHILD_ACCESS_BLOCKED'), "Access to this child's information is blocked. Contact the school.");
    expect(text(403, 'FORBIDDEN'), "You don't have access to this.");
    expect(text(423, 'SECTION_BLOCKED'), isNotEmpty);
  });
}
