import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';

/// Where and how to send the file (FIL-01 `upload`). The local store takes a multipart form (`POST`) with the [fields]
/// before the file; R2 takes the bytes alone (`PUT`) with the [headers] the ticket was signed for.
class UploadTicket {
  const new({required this.url, required this.fields, this.method = 'POST', this.headers = const {}});

  final String url;
  final String method;
  final Map<String, String> fields;
  final Map<String, String> headers;
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
        method: upload['method'] as String? ?? 'POST',
        fields: _strings(upload['fields']),
        headers: _strings(upload['headers']),
      ),
    );
  }

  static Map<String, String> _strings(Object? raw) => {
    if (raw != null)
      for (final entry in jsonObject(raw).entries) entry.key: entry.value as String,
  };

  static UploadedFile uploaded(Object? raw) {
    final json = jsonObject(raw);
    return UploadedFile(
      id: json['id'] as String,
      contentType: json['contentType'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
    );
  }

  /// FIL-03: the address; when it stops working is not kept, as it is used at once.
  static Uri link(Object? raw) => Uri.parse(jsonObject(raw)['url'] as String);

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
