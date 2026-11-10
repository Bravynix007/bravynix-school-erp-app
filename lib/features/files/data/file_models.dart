import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';

/// Where and how to send the file (FIL-01 `upload`): the address, the form fields to send before the file, and when
/// the ticket stops working.
class UploadTicket {
  const new({required this.url, required this.fields});

  final String url;
  final Map<String, String> fields;
}

/// What FIL-01 answers.
class UploadGrant {
  const new({required this.fileId, required this.ticket});

  final String fileId;
  final UploadTicket ticket;
}

/// JSON → domain for FIL-01 and FIL-02. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class FileModels {
  static UploadGrant grant(Object? raw) {
    final json = jsonObject(raw);
    final upload = jsonObject(json['upload']);
    return UploadGrant(
      fileId: json['fileId'] as String,
      ticket: UploadTicket(
        url: upload['url'] as String,
        fields: {for (final field in jsonObject(upload['fields']).entries) field.key: field.value as String},
      ),
    );
  }

  static UploadedFile uploaded(Object? raw) {
    final json = jsonObject(raw);
    return UploadedFile(
      id: json['id'] as String,
      contentType: json['contentType'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
    );
  }

  /// FIL-01: the server takes the name only for purposes that keep it; sending it for all is as the API design says.
  static Map<String, Object?> requestBody(
    ChosenFile file, {
    required FilePurpose purpose,
    required String institutionId,
  }) => {
    'purpose': purpose.code,
    'institutionId': institutionId,
    'contentType': file.contentType,
    'sizeBytes': file.sizeBytes,
    'fileName': file.name,
  };
}
