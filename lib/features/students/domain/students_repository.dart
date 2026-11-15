import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';

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
