import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';

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
}
