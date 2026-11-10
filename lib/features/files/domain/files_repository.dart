import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';

/// The upload flow of API design 15.1. Methods throw [ApiFailure].
abstract class FilesRepository {
  /// Asks for a ticket (FIL-01), sends the file to the store, and has the server check it (FIL-02). [onProgress] is
  /// told how much of the file has been sent, from 0 to 1. Failures the screen can say: 403 `FORBIDDEN`, 404 for an
  /// Institution the caller does not reach, 413 `FILE_TOO_LARGE`, 415 `FILE_TYPE_NOT_ALLOWED`, 422 `FILE_CHECK_FAILED`
  /// (the file is not what it said; it is discarded), 422 `UPLOAD_NOT_FOUND`, and `UPLOAD_REFUSED` when the store
  /// refuses the file. A retry starts again with a new ticket.
  Future<UploadedFile> upload(
    ChosenFile file, {
    required FilePurpose purpose,
    required String institutionId,
    void Function(double sent)? onProgress,
  });
}
