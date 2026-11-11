import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_draft.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';

/// The Teachers / Staff of the Society (STF-01 to STF-05). Methods throw [ApiFailure].
abstract class StaffRepository {
  /// STF-01: [page] (from 1) of the active staff based at the Institution, by name; [query] searches the name and the
  /// Employee ID and is empty for no search, else at least two letters.
  Future<ItemsPage<StaffSummary>> staff(String institutionId, {int page = 1, String query = ''});

  /// STF-03: one staff member; 404 for one outside the caller's scope or deactivated.
  Future<StaffMember> member(String id);

  /// STF-02: adds a staff member based at [institutionId], with the login by email. 409 `EMPLOYEE_ID_TAKEN`, `DUPLICATE`
  /// (the person already has an active record in the Society), `ROLE_CONFLICT` and `ACCOUNT_BLOCKED`.
  Future<StaffMember> create(String institutionId, StaffDraft draft);

  /// STF-04: changes the staff member the app read at [version]. A field left empty in [draft] is cleared, the two
  /// lists are replaced whole, and the email and the photo are left alone unless the draft carries a new photo. 409
  /// `VERSION_CONFLICT` when someone saved first, 409 `EMPLOYEE_ID_TAKEN`.
  Future<StaffMember> update(String id, int version, StaffDraft draft);

  /// STF-05: deactivates the staff member. 409 CANNOT_ACT_ON_SELF for the caller's own record.
  Future<void> deactivate(String id);

  /// STF-06: blocks the staff member's access in this Society and ends their sessions as Admin or Teacher / Staff. An
  /// answer with the profile as it is now. 409 `INVALID_STATE` when already blocked, 409 `CANNOT_ACT_ON_SELF`, 403
  /// when an Institution Admin blocks a fellow Admin (only the Society Owner may).
  Future<StaffMember> block(String id);

  /// STF-07: lifts the block, with the same answer and errors as [block] (409 `INVALID_STATE` when not blocked).
  Future<StaffMember> unblock(String id);

  /// STF-08: the whole list of subjects they can teach (at most 50; an empty list clears it). 422 `REFERENCE_INACTIVE`
  /// for a subject that is deactivated and new to them, 409 `SUBJECT_ASSIGNED` for dropping one they are assigned to
  /// teach.
  Future<StaffMember> setSubjects(String id, List<String> subjectIds);

  /// STF-10: Society Owner only. The whole list of extra Institutions (at most 50; an empty list clears it). 422
  /// `REFERENCE_INACTIVE` for an Institution that is deactivated, 409 `ADMIN_ACCESS_HELD` for dropping one they
  /// administer.
  Future<StaffMember> setInstitutions(String id, List<String> institutionIds);

  /// STF-09: the section the staff member leads as class teacher in the academic year of their home Institution;
  /// [sectionId] null ends it. Answers with the assignment, or null after null. 409 `CLASS_TEACHER_TAKEN` when another
  /// teacher leads the section that year, 422 `STAFF_BLOCKED`, 422 `REFERENCE_INACTIVE` for a year or section that is
  /// deactivated, 404 for a year or section that is not found.
  Future<ClassTeacherAssignment?> setClassTeacher(String id, {required String academicYearId, String? sectionId});

  /// STF-11: sets the Aadhaar number, or clears it when [aadhaar] is null. Answers with the masked number, or null after
  /// null; the number itself is never sent back. 422 `INVALID_AADHAAR`, 409 `AADHAAR_EXISTS_IN_SOCIETY` when another
  /// active record of the Society holds it.
  Future<String?> setAadhaar(String id, String? aadhaar);

  /// STF-12: the whole Aadhaar number, for a [reason] of 10 to 500 characters that is kept in the audit. 404 `NOT_SET`
  /// when none is held, 429 `REVEAL_LIMIT` after ten in a day.
  Future<String> revealAadhaar(String id, {required String reason});
}
