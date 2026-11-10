import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';

/// The largest file the server takes, in bytes (API design 15.4).
const maxFileBytes = 5242880;

/// Why a chosen file is refused before anything is sent. The server checks the same again (413 `FILE_TOO_LARGE`, 415
/// `FILE_TYPE_NOT_ALLOWED`), so this only saves the trip.
enum FileProblem { empty, tooLarge, typeNotAllowed }

/// Null when [file] may go as [purpose].
FileProblem? checkFile(ChosenFile file, FilePurpose purpose) {
  if (file.sizeBytes == 0) return FileProblem.empty;
  if (file.sizeBytes > maxFileBytes) return FileProblem.tooLarge;
  if (!purpose.contentTypes.contains(file.contentType)) return FileProblem.typeNotAllowed;
  return null;
}
