import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';

/// The Teachers / Staff of the Society (STF-01 to STF-05). Methods throw [ApiFailure].
abstract class StaffRepository {
  /// STF-01: [page] (from 1) of the active staff based at the Institution, by name; [query] searches the name and the
  /// Employee ID and is empty for no search, else at least two letters.
  Future<ItemsPage<StaffSummary>> staff(String institutionId, {int page = 1, String query = ''});

  /// STF-03: one staff member; 404 for one outside the caller's scope or deactivated.
  Future<StaffMember> member(String id);

  /// STF-05: deactivates the staff member. 409 CANNOT_ACT_ON_SELF for the caller's own record.
  Future<void> deactivate(String id);
}
