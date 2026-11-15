import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/students/domain/student_import.dart';

/// Reads the answers of IMP-02 and IMP-03.
abstract final class StudentImportModels {
  /// IMP-02: the ID of the import that was queued.
  static String importId(Object? raw) => jsonObject(raw)['importId'] as String;

  /// IMP-03: the operation resource (API design 16.2) of an import.
  static StudentImport run(Object? raw) {
    final json = jsonObject(raw);
    final result = jsonObject(json['result']);
    final error = json['error'];
    return StudentImport(
      id: json['id'] as String,
      status: ImportStatus.fromCode(json['runStatus']) ?? (throw const FormatException('Unknown runStatus')),
      totalRows: (result['totalRows'] as num?)?.toInt(),
      processedRows: (result['processedRows'] as num).toInt(),
      importedRows: (result['importedRows'] as num).toInt(),
      skippedRows: (result['skippedRows'] as num).toInt(),
      overCapacity: result['overCapacity'] as bool,
      rowErrors: [
        for (final item in jsonList(result['rowErrors']))
          ImportRowError(
            row: (jsonObject(item)['row'] as num).toInt(),
            message: jsonObject(item)['message'] as String,
          ),
      ],
      errorCode: error == null ? null : jsonObject(error)['code'] as String,
    );
  }
}
