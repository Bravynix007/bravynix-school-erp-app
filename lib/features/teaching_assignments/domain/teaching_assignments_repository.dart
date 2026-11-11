import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignment.dart';

/// Who teaches which section and subject (ASG-01 to ASG-03). Methods throw [ApiFailure].
abstract class TeachingAssignmentsRepository {
  /// ASG-01: [page] (from 1) of what the staff member teaches in the academic year at the Institution, by section.
  Future<ItemsPage<TeachingAssignment>> assignments(
    String institutionId, {
    required String academicYearId,
    required String staffMemberId,
    int page = 1,
  });

  /// ASG-02: 409 DUPLICATE when they already teach the subject in the section that year, 422 SUBJECT_NOT_TAUGHT unless
  /// the subject is on their own list, 422 STAFF_BLOCKED, 422 REFERENCE_INACTIVE, 404.
  Future<TeachingAssignment> assign({
    required String staffMemberId,
    required String academicYearId,
    required String sectionId,
    required String subjectId,
  });

  /// ASG-03: ends the assignment; the row stays as history. 404 when it is not there, or already ended.
  Future<void> end(String id);
}
