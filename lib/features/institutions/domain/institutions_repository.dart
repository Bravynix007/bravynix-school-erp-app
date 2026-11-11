import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution_admin.dart';

/// The Institutions in the caller's scope (API design 10.4c). Methods throw [ApiFailure].
abstract class InstitutionsRepository {
  /// INS-01: the active Institutions the caller can work in, by name. An Owner gets all of the Society's; an
  /// Institution Admin only those they are granted.
  Future<List<InstitutionSummary>> institutions();

  /// INS-03: one Institution; 404 outside the caller's scope.
  Future<Institution> institution(String id);

  /// INS-02: Owner only. Adds the Institution to the Owner's Society and answers with it. 409 DUPLICATE on the code.
  Future<Institution> create(InstitutionDraft draft);

  /// INS-04: Owner only. Sends every field of [draft] except the code, with the [version] that was read, and answers
  /// with the Institution. 409 VERSION_CONFLICT when it changed meanwhile.
  Future<Institution> update(String id, int version, InstitutionDraft draft);

  /// INS-05: Owner only. Deactivates the Institution; nothing is deleted.
  Future<void> deactivate(String id);

  /// INS-08: Owner only. [page] (from 1) of the people who hold Admin access to the Institution, by name.
  Future<ItemsPage<InstitutionAdmin>> admins(String institutionId, {int page = 1});

  /// INS-09: Owner only. Gives the staff member Admin access to the Institution, which tells them by email. 404 for a
  /// staff member who is gone, 422 `STAFF_BLOCKED`, 422 `STAFF_NOT_AT_INSTITUTION` unless it is their home or one of
  /// their extra Institutions, 409 `ALREADY_ADMIN`, 409 `ACCOUNT_BLOCKED` or `INVALID_STATE`.
  Future<InstitutionAdmin> grantAdmin(String institutionId, String staffMemberId);

  /// INS-10: Owner only. Takes the Admin access away, which ends their Admin sessions in the Society. 404 when they
  /// do not hold it.
  Future<void> revokeAdmin(String institutionId, String staffMemberId);
}
