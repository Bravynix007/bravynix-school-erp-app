import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:equatable/equatable.dart';

/// Where an import is (API design 16.2 `runStatus`): waiting for the worker, being read, or settled.
enum ImportStatus {
  queued,
  running,
  done,
  failed;

  /// Null for a number the app does not know.
  static ImportStatus? fromCode(Object? code) => switch (code) {
    1 => queued,
    2 => running,
    3 => done,
    4 => failed,
    _ => null,
  };

  /// The worker is finished with it: nothing more will change.
  bool get isSettled => this == done || this == failed;
}

/// A row of the file that was skipped. [row] counts the header as row 1; [message] is the server's words for why, and
/// never holds the row's phone number or email.
class ImportRowError extends Equatable {
  const new({required this.row, required this.message});

  final int row;
  final String message;

  @override
  List<Object?> get props => [row, message];
}

/// An import as IMP-03 tells it (API design 16.2).
class StudentImport extends Equatable {
  const new({
    required this.id,
    required this.status,
    required this.processedRows,
    required this.importedRows,
    required this.skippedRows,
    required this.overCapacity,
    this.totalRows,
    this.rowErrors = const [],
    this.errorCode,
  });

  final String id;
  final ImportStatus status;

  /// The data rows of the file; null until the worker has read it.
  final int? totalRows;
  final int processedRows;
  final int importedRows;
  final int skippedRows;

  /// A section now holds more students than its capacity.
  final bool overCapacity;

  /// Up to 1,000 skipped rows; there can be more skipped than listed.
  final List<ImportRowError> rowErrors;

  /// Why a failed import read no row (`CSV_HEADER_INVALID`, `CSV_TOO_LARGE`, `CSV_UNREADABLE`, `IMPORT_FAILED`).
  final String? errorCode;

  /// How far the worker has got, from 0 to 1; null while the rows are not counted yet.
  double? get progress {
    final total = totalRows;
    if (total == null) return null;
    return total == 0 ? 1 : processedRows / total;
  }

  @override
  List<Object?> get props => [
    id,
    status,
    totalRows,
    processedRows,
    importedRows,
    skippedRows,
    overCapacity,
    rowErrors,
    errorCode,
  ];
}

/// Student imports from a CSV file (IMP-01 to IMP-03). Methods throw [ApiFailure].
abstract class StudentImportsRepository {
  /// IMP-01: the sample file, as text.
  Future<String> template();

  /// IMP-02: starts the import of the uploaded file [fileId] into the academic year [academicYearId] of the Institution,
  /// and answers with the ID of the import to follow. [idempotencyKey] makes a repeat of the same attempt, after a lost
  /// answer, find the first one. 404 for a file or year that is not found; 400 `INVALID_VALUE` on `fileId` for a file
  /// that is not an import file of this Institution; 422 `FILE_NOT_READY` and `YEAR_NOT_ACTIVE`; 409
  /// `IMPORT_ALREADY_RUNNING` while another import of the Institution is on.
  Future<String> start({
    required String institutionId,
    required String fileId,
    required String academicYearId,
    required String idempotencyKey,
  });

  /// IMP-03: where the import is now. 404 for one that is not the caller's, or has been kept past its 7 days.
  Future<StudentImport> status(String importId);
}
