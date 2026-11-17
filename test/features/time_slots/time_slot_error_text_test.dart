import 'dart:ui';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/view/time_slot_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String text(int status, String code) =>
      timeSlotErrorText(l10n, ApiFailure(statusCode: status, code: code, message: 'server words'));

  test("says in the app's own words what each refusal of the period endpoints means", () {
    expect(text(409, 'DUPLICATE'), 'Another period of this year has this number.');
    expect(
      text(409, 'TIME_SLOT_OVERLAP'),
      'These times overlap another period of this year. A period may end when the next begins.',
    );
    expect(text(409, 'TIME_SLOT_IN_USE'), 'A timetable entry sits in this period. Remove it from the timetable first.');
    expect(
      text(422, 'CURRENT_YEAR_REQUIRED'),
      'This Institution has no current academic year. Make one current under Academic years first.',
    );
    expect(text(404, 'NOT_FOUND'), 'This period could not be found. It may have been deactivated.');
    expect(text(409, 'VERSION_CONFLICT'), 'Someone else changed this. Your changes were not saved.');
  });

  test('the rest read as everywhere else', () {
    expect(text(403, 'FORBIDDEN'), "You don't have access to this.");
  });

  group('under a field', () {
    ApiFailure failure(String field, String code) => ApiFailure(
      statusCode: 409,
      code: code,
      message: 'm',
      fieldErrors: [FieldError(field: field, code: code, message: 'Server words')],
    );

    test('a taken number and an overlap are said in the app words', () {
      expect(
        timeSlotFieldError(l10n, failure('periodNo', 'DUPLICATE'), 'periodNo'),
        'Another period of this year has this number.',
      );
      expect(
        timeSlotFieldError(l10n, failure('startTime', 'TIME_SLOT_OVERLAP'), 'startTime'),
        'These times overlap another period of this year. A period may end when the next begins.',
      );
    });

    test('a field left empty reads as required, and any other refusal keeps the words the server gave', () {
      expect(timeSlotFieldError(l10n, failure('startTime', 'REQUIRED'), 'startTime'), 'This field is required.');
      expect(timeSlotFieldError(l10n, failure('endTime', 'OUT_OF_RANGE'), 'endTime'), 'Server words');
    });

    test('a field the refusal does not name has nothing to say', () {
      expect(timeSlotFieldError(l10n, failure('periodNo', 'DUPLICATE'), 'startTime'), isNull);
    });
  });
}
