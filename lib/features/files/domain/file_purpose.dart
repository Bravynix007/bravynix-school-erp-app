/// What a file is for (API design 15.2). The server decides who may upload each purpose and which types it takes; this
/// is the part the app needs to check first and to say. Purposes the app has no screen for are not listed.
enum FilePurpose {
  studentPhoto(3, _images),
  staffPhoto(4, _images),
  studentDocument(5, _documents),
  staffDocument(6, _documents),
  importCsv(12, ['text/csv']);

  new(this.code, this.contentTypes);

  /// The number FIL-01 takes.
  final int code;

  /// The types the server accepts for this purpose.
  final List<String> contentTypes;

  bool get isPhoto => contentTypes == _images;
}

const List<String> _images = ['image/jpeg', 'image/png', 'image/webp'];
const List<String> _documents = [..._images, 'application/pdf'];
