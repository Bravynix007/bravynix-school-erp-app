import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/documents/domain/document.dart';

/// JSON → domain for STF-14 and STF-15. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class DocumentModels {
  static Document document(Object? raw) {
    final json = jsonObject(raw);
    final file = jsonObject(json['file']);
    return Document(
      id: json['id'] as String,
      title: json['title'] as String,
      file: DocumentFile(
        id: file['id'] as String,
        contentType: file['contentType'] as String,
        sizeBytes: (file['sizeBytes'] as num).toInt(),
        fileName: file['fileName'] as String,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static List<Document> documents(Object? raw) => [for (final item in jsonList(raw)) document(item)];
}
