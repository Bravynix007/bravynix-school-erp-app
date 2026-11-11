import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/documents/data/document_models.dart';
import 'package:bravynix_school_erp/features/documents/domain/document.dart';
import 'package:bravynix_school_erp/features/documents/domain/documents_repository.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _staff(String staffMemberId) => 'staff/${Uri.encodeComponent(staffMemberId)}/documents';

  @override
  Future<List<Document>> staffDocuments(String staffMemberId) =>
      _api.data(_staff(staffMemberId), parse: DocumentModels.documents);

  @override
  Future<Document> attachToStaff(String staffMemberId, {required String title, required String fileId}) => _api.data(
    _staff(staffMemberId),
    method: HttpMethod.post,
    body: {'title': title, 'fileId': fileId},
    parse: DocumentModels.document,
  );

  @override
  Future<void> deactivate(String documentId) => _api.data(
    'documents/${Uri.encodeComponent(documentId)}',
    method: HttpMethod.delete,
    parse: (_) {},
  );
}
