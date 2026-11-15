import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/students/domain/promotion.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';

/// The students of the Society (STU-01 to STU-09). Methods throw [ApiFailure].
abstract class StudentsRepository {
  /// STU-01: [page] (from 1) of the active students of the Institution, by name, each with the section they were last
  /// placed in, or the one of the year in [filter]; [query] searches the name, the Admission ID and the roll number and
  /// is empty for no search, else at least two letters.
  Future<ItemsPage<StudentSummary>> students(
    String institutionId, {
    int page = 1,
    String query = '',
    StudentFilter filter = const StudentFilter(),
  });

  /// STU-03: one student with their guardians. A deactivated student is still read, with `isActive` false; 404 for a
  /// student of an Institution the caller does not reach.
  Future<StudentRecord> student(String id);

  /// STU-04: changes the personal and contact fields of the student; a field [draft] leaves empty is cleared, and a
  /// photo only when [draft] holds a new one. [version] is the one that was read. The answer is the student as STU-03
  /// reads them. 404 for a student already deactivated; 409 `VERSION_CONFLICT` and `ADMISSION_NO_TAKEN`.
  Future<StudentRecord> update(String id, int version, StudentDraft draft);

  /// STU-06: stops the guardians' access to this child only. The answer is the student as STU-03 reads them, with
  /// `isBlocked`. 404 for a student already deactivated; 409 `INVALID_STATE` when already blocked; 403 `FORBIDDEN`.
  Future<StudentRecord> block(String id);

  /// STU-07: lifts the block, with the same answer and errors as [block] (409 `INVALID_STATE` when not blocked).
  Future<StudentRecord> unblock(String id);

  /// STU-10: sets the Aadhaar number, or clears it when [aadhaar] is null; the birth certificate number stays. The
  /// answer is the numbers as they are now, the Aadhaar masked, and the warnings of the write. 404 for a student
  /// already deactivated; 422 `INVALID_AADHAAR`; 409 `AADHAAR_DUPLICATE_IN_INSTITUTION` when another active student of
  /// the Institution holds it.
  Future<IdentitySaved> setAadhaar(String id, String? aadhaar);

  /// STU-10: sets the birth certificate number (1 to 50 characters), or clears it when [number] is null; the Aadhaar
  /// number stays. The answer and errors are those of [setAadhaar].
  Future<IdentitySaved> setBirthCertificate(String id, String? number);

  /// STU-11: the whole Aadhaar number, for a [reason] of 10 to 500 characters that is kept in the audit. Works for a
  /// deactivated student. 404 `NOT_SET` when none is held, 429 `REVEAL_LIMIT` after ten in a day.
  Future<String> revealAadhaar(String id, {required String reason});

  /// STU-09: promotes the student from their open placement to [target], or completes the final class when it is null,
  /// with [rollNumber] when given (the old one otherwise). The answer is the profile with the new placement, and the
  /// warnings of the write. 404 for a student already deactivated; 409 `ALREADY_ENROLLED` and `ROLL_NUMBER_TAKEN`; 422
  /// `NO_CURRENT_PLACEMENT`, `TARGET_YEAR_NOT_AFTER_SOURCE`, `TARGET_CLASS_BELOW_SOURCE`, `NOT_FINAL_CLASS`,
  /// `SECTION_NOT_IN_CLASS`, `INACTIVE_SECTION` and `YEAR_NOT_ACTIVE`.
  Future<Promoted> promoteStudent(String id, {PromotionTarget? target, String? rollNumber});

  /// PRM-01: promotes the active students of a class, or of one section of it ([fromSectionId] null for every section),
  /// to [target], or completes the final class when it is null. All of them or none. [idempotencyKey] makes a repeat of
  /// the same attempt, after a lost answer, find the first one done. Students who cannot be promoted are left and
  /// counted. 413 `BATCH_TOO_LARGE` above 500; 409 `ROLL_NUMBER_TAKEN`; and the 422 codes of [promoteStudent].
  Future<PromotionResult> promote({
    required String institutionId,
    required String fromAcademicYearId,
    required String fromClassId,
    required String idempotencyKey,
    String? fromSectionId,
    PromotionTarget? target,
    bool keepRollNumbers = true,
  });

  /// STU-05: deactivates the student for [reason]; the guardians lose the child, the open placement and the enrolment
  /// end today. 404 for a student already deactivated.
  Future<void> deactivate(String id, LeavingReason reason);

  /// STU-08: moves the student to [sectionId] of the same class, or gives them [rollNumber], from [effectiveDate]
  /// (`YYYY-MM-DD`; today when null, never in the future or before the current placement began). Send what changes. The
  /// answer is the warnings of the write (`SECTION_OVER_CAPACITY`). 404 for a student already deactivated; 409
  /// `ROLL_NUMBER_TAKEN`; 422 `INACTIVE_SECTION`, `SECTION_NOT_IN_CLASS` and `YEAR_NOT_ACTIVE`; 400 `INVALID_VALUE` on
  /// `effectiveDate`.
  Future<List<String>> move(String id, {String? sectionId, String? rollNumber, String? effectiveDate});

  /// STU-12: puts the student in [classId] and its [sectionId] for the whole of the year they are enrolled in, when they
  /// were in the wrong class from the start; [rollNumber] only when it changes. The answer is the warnings of the write
  /// (`SECTION_OVER_CAPACITY`). 404 for a student already deactivated; 409 `ROLL_NUMBER_TAKEN`; 422 `CLASS_UNCHANGED`,
  /// `TARGET_CLASS_BELOW_SOURCE` (below the class they were promoted from), `NO_CURRENT_PLACEMENT`,
  /// `SECTION_NOT_IN_CLASS`, `INACTIVE_SECTION` and `YEAR_NOT_ACTIVE`.
  Future<List<String>> correctClass(
    String id, {
    required String classId,
    required String sectionId,
    String? rollNumber,
  });

  /// STU-02: adds a student to [institutionId] with the first placement ([enrolment]), one to five [guardians] with
  /// exactly one primary, and the [identity] numbers when given. The answer carries the warnings of the write. 409
  /// `ADMISSION_NO_TAKEN`, `ROLL_NUMBER_TAKEN`, `AADHAAR_DUPLICATE_IN_INSTITUTION`, `ROLE_CONFLICT` and
  /// `ACCOUNT_BLOCKED` (a guardian's email); 422 `SECTION_NOT_IN_CLASS`, `YEAR_NOT_ACTIVE`, `INACTIVE_SECTION`,
  /// `INVALID_AADHAAR` and `PRIMARY_GUARDIAN_REQUIRED`.
  Future<StudentSaved> create(
    String institutionId,
    StudentDraft draft, {
    required EnrolmentDraft enrolment,
    required List<GuardianDraft> guardians,
    IdentityDraft identity = const IdentityDraft(),
  });
}
