/// Hands a link to the phone, which opens it in the browser. Tests fake this, so no test touches the phone.
abstract class FileOpening {
  /// False when the phone has nothing that opens the link.
  Future<bool> open(Uri url);
}
