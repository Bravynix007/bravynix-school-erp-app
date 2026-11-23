import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/field_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes TT-01 adds (API design 9.7): 403 NOT_ASSIGNED (a teacher reads only a section they lead or teach),
/// 422 CURRENT_YEAR_REQUIRED, and 404 for a section out of reach or a child that is not the parent's; the rest, a blocked
/// child included, reads as everywhere else.
String timetableErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'NOT_ASSIGNED' => l10n.errorTimetableNotAssigned,
  'CURRENT_YEAR_REQUIRED' => l10n.errorTimetableNoYear,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorTimetableNotFound),
};

/// Copy for the codes TT-02 to TT-04 add (API design 9.7, 12.6): 409 SECTION_SLOT_TAKEN and TEACHER_DOUBLE_BOOKED (named
/// in the section the teacher is in, when the caller may see it), 400 INVALID_SLOT, and 422 SUBJECT_NOT_TAUGHT,
/// STAFF_NOT_AT_INSTITUTION and STAFF_BLOCKED; the rest reads as for the week.
String timetableEntryErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'SECTION_SLOT_TAKEN' => l10n.errorTimetableSlotTaken,
  'TEACHER_DOUBLE_BOOKED' => switch (failure.details['conflict']) {
    {'sectionName': final String section, 'className': final String className} => l10n.errorTimetableTeacherBusyIn(
      '$className - $section',
    ),
    _ => l10n.errorTimetableTeacherBusy,
  },
  'INVALID_SLOT' => l10n.errorTimetableInvalidSlot,
  'SUBJECT_NOT_TAUGHT' => l10n.errorTimetableSubjectNotTaught,
  'STAFF_NOT_AT_INSTITUTION' => l10n.errorTimetableTeacherElsewhere,
  'STAFF_BLOCKED' => l10n.errorTimetableTeacherBlocked,
  _ => timetableErrorText(l10n, failure),
};

/// What to say under [field] for a refusal that names it, or null when it does not: a subject or teacher that was
/// deactivated meanwhile is said in the app's words; the rest keep the words the server gave.
String? timetableEntryFieldError(AppLocalizations l10n, ApiFailure failure, String field) {
  final error = failure.fieldError(field);
  if (error == null) return null;
  return switch (error.code) {
    'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
    _ => fieldErrorText(l10n, error),
  };
}
