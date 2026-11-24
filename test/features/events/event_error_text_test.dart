import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

ApiFailure _code(String code, {int status = 422, List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'x', fieldErrors: fields);

void main() {
  late AppLocalizations l10n;
  setUp(() => l10n = AppLocalizationsEn());

  test('an Admin refused an event of the whole Society is told who may, and the rest reads as everywhere else', () {
    expect(eventErrorText(l10n, _code('SCOPE_NOT_ALLOWED', status: 403)), l10n.errorEventScopeNotAllowed);
    expect(eventErrorText(l10n, _code('FILE_NOT_READY')), l10n.errorFileNotArrived);
    expect(eventErrorText(l10n, _code('NOT_FOUND', status: 404)), l10n.errorEventNotFound);
    expect(eventErrorText(l10n, _code('VERSION_CONFLICT', status: 409)), l10n.errorVersionConflict);
    expect(eventErrorText(l10n, _code('FORBIDDEN', status: 403)), l10n.errorForbidden);
  });

  test('a field says its own problem in the app’s words', () {
    FieldError error(String field, String code) => FieldError(field: field, code: code, message: 'server words');
    String? say(String field, String code) =>
        eventFieldError(l10n, _code('VALIDATION_FAILED', status: 400, fields: [error(field, code)]), field);
    expect(say('endDate', 'OUT_OF_RANGE'), l10n.errorEventEndBeforeStart);
    expect(say('institutionId', 'INVALID_VALUE'), l10n.errorEventPictureInstitution);
    expect(say('holidayForStudents', 'REQUIRED'), l10n.errorEventHolidayWho);
    expect(say('title', 'REQUIRED'), l10n.errorFieldRequired);
    expect(say('holidayPredefinedClassIds', 'REFERENCE_INACTIVE'), l10n.errorReferenceInactive);
    expect(say('title', 'SOMETHING_ELSE'), 'server words');
  });

  test('a field the refusal does not name has nothing to say', () {
    expect(eventFieldError(l10n, _code('SCOPE_NOT_ALLOWED', status: 403), 'title'), isNull);
  });
}
