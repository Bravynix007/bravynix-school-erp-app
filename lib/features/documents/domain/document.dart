import 'package:equatable/equatable.dart';

/// The file a document holds (API design 10.5b): [fileName] is what the person chose on their phone.
class DocumentFile extends Equatable {
  const new({required this.id, required this.contentType, required this.sizeBytes, required this.fileName});

  final String id;
  final String contentType;
  final int sizeBytes;
  final String fileName;

  @override
  List<Object?> get props => [id, contentType, sizeBytes, fileName];
}

/// A file kept with a person's record under a title, such as an appointment letter.
class Document extends Equatable {
  const new({required this.id, required this.title, required this.file, required this.createdAt});

  final String id;
  final String title;
  final DocumentFile file;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, title, file, createdAt];
}
