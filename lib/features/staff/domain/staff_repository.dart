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
}
