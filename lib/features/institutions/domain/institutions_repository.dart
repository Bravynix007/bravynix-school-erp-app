import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';

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
}
