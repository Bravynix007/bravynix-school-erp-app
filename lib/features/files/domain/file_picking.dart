import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';

/// Where a photo comes from.
enum PhotoSource { camera, gallery }

/// The phone's camera, gallery and file browser. Each returns null when the person backs out. Tests fake this, so no
/// test touches the phone.
abstract class FilePicking {
  Future<ChosenFile?> photo(PhotoSource source);

  /// A PDF or a picture from the phone's files.
  Future<ChosenFile?> document();
}

/// The phone would not open the camera, the gallery or the files (a permission refused, no camera).
class FilePickFailure implements Exception {
  const new(this.source);

  /// Null for the file browser.
  final PhotoSource? source;
}
