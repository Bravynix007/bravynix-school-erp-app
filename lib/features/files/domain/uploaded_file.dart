import 'package:equatable/equatable.dart';

/// A file the server has checked and calls Ready (FIL-02): its [id] goes in the `...FileId` field of the form.
class UploadedFile extends Equatable {
  const new({required this.id, required this.contentType, required this.sizeBytes});

  final String id;
  final String contentType;
  final int sizeBytes;

  @override
  List<Object?> get props => [id, contentType, sizeBytes];
}
