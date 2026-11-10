import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A file the person chose on the phone, read into memory (the server takes at most 5 MB, API design 15.4).
class ChosenFile extends Equatable {
  const new({required this.name, required this.contentType, required this.bytes});

  /// The name as the phone gave it; the server keeps it for documents only.
  final String name;
  final String contentType;
  final Uint8List bytes;

  int get sizeBytes => bytes.length;

  @override
  List<Object?> get props => [name, contentType, bytes];

  /// Short: the bytes would fill a test report and a log.
  @override
  String toString() => 'ChosenFile($name, $contentType, $sizeBytes bytes)';
}

/// The content type for a file name, for pickers that do not say. Null for a type the app does not know, which the
/// check then refuses.
String? contentTypeOfName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0) return null;
  return switch (name.substring(dot + 1).toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    'csv' => 'text/csv',
    _ => null,
  };
}
