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

  group('adding and changing an entry', () {
    String entryText(int status, String code, {Map<String, dynamic> details = const {}}) => timetableEntryErrorText(
      l10n,
      ApiFailure(statusCode: status, code: code, message: 'server words', details: details),
    );

    test('says which clash it was, and who else the teacher is teaching when the server says', () {
      expect(entryText(409, 'SECTION_SLOT_TAKEN'), 'This section already has an entry in that period on that day.');
      expect(
        entryText(409, 'TEACHER_DOUBLE_BOOKED'),
        'That teacher already has a lesson in that period on that day.',
      );
      expect(
        entryText(
          409,
          'TEACHER_DOUBLE_BOOKED',
          details: {
            'conflict': {'sectionName': 'B', 'className': '8th'},
          },
        ),
        'That teacher is already teaching 8th - B in that period on that day.',
      );
      // A clash outside the caller's scope is not named.
      expect(
        entryText(409, 'TEACHER_DOUBLE_BOOKED', details: {'conflict': null}),
        'That teacher already has a lesson in that period on that day.',
      );
    });

    test('says what is wrong with the period, the subject and the teacher', () {
      expect(entryText(400, 'INVALID_SLOT'), startsWith('That period cannot take this entry'));
      expect(entryText(422, 'SUBJECT_NOT_TAUGHT'), startsWith('That teacher does not teach this subject'));
      expect(entryText(422, 'STAFF_NOT_AT_INSTITUTION'), 'That teacher is based at another Institution.');
      expect(entryText(422, 'STAFF_BLOCKED'), "That teacher's access is blocked.");
    });

    test('the rest reads as for the week', () {
      expect(entryText(409, 'VERSION_CONFLICT'), isNotEmpty);
      expect(entryText(404, 'NOT_FOUND'), 'This timetable could not be found.');
      expect(entryText(422, 'CURRENT_YEAR_REQUIRED'), startsWith('No current academic year'));
    });

    test('a subject or teacher deactivated meanwhile is said under its own field', () {
      const failure = ApiFailure(
        statusCode: 422,
        code: 'REFERENCE_INACTIVE',
        message: 'x',
        fieldErrors: [FieldError(field: 'staffMemberId', code: 'REFERENCE_INACTIVE', message: 'server words')],
      );
      expect(timetableEntryFieldError(l10n, failure, 'staffMemberId'), l10n.errorReferenceInactive);
      expect(timetableEntryFieldError(l10n, failure, 'subjectId'), isNull);
    });
  });
}
