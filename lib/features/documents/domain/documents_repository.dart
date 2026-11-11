import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/documents/domain/document.dart';

/// The documents kept with a record (API design 10.5b). Methods throw [ApiFailure].
abstract class DocumentsRepository {
  /// STF-14: the active documents of a staff member, newest first. 404 for a staff member outside the caller's scope or
  /// deactivated.
  Future<List<Document>> staffDocuments(String staffMemberId);

  /// STF-15: attaches an uploaded file (purpose 6, made for the staff member's home Institution) under [title]. 400
  /// `INVALID_VALUE` for a file that is not Ready or has another purpose, 409 `DUPLICATE` when the file is attached
  /// already, 404 for a staff member that is deactivated.
  Future<Document> attachToStaff(String staffMemberId, {required String title, required String fileId});

  /// DOC-03: deactivates the document; its file is removed 30 days later. 404 when it is gone already.
  Future<void> deactivate(String documentId);
}
