import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A file the person chose on the phone, read into memory (the server takes at most 5 MB, API design 15.4).
class ChosenFile extends Equatable {
  /// [size] is given only for a file too big to be read: the bytes are then empty, and the check refuses the file by
  /// its size.
  const new({required this.name, required this.contentType, required this.bytes, int? size})
    : sizeBytes = size ?? bytes.length;

  /// A file read from the phone. The type is the one the first bytes say, because that is what the server checks
  /// (API design 15.4): a picker may re-save a PNG as a JPEG and keep its name. The name is changed to match what the
  /// bytes are. When no signature matches, a type with a signature is not taken from the name, so the check refuses
  /// the file instead of the server; a type with none (CSV) is.
  factory read({required String name, required Uint8List bytes}) {
    final sniffed = contentTypeOfBytes(bytes);
    if (sniffed != null) return ChosenFile(name: _named(name, sniffed), contentType: sniffed, bytes: bytes);
    final byName = contentTypeOfName(name);
    return ChosenFile(
      name: name,
      contentType: byName == null || _extensions.containsKey(byName) ? _unknown : byName,
      bytes: bytes,
    );
  }

  /// A file too big to read: only its [size] is kept, so the check can refuse it without the phone holding it.
  factory unread({required String name, required int size}) =>
      ChosenFile(name: name, contentType: contentTypeOfName(name) ?? _unknown, bytes: Uint8List(0), size: size);

  /// The type of a file whose first bytes the app does not know.
  static const _unknown = 'application/octet-stream';

  /// The extension each type with a signature is saved under.
  static const _extensions = {'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'application/pdf': 'pdf'};

  static String _named(String name, String contentType) {
    if (contentTypeOfName(name) == contentType) return name;
    final dot = name.lastIndexOf('.');
    return '${dot > 0 ? name.substring(0, dot) : name}.${_extensions[contentType]}';
  }

  /// The name as the phone gave it, with the extension of the type the bytes are; the server keeps it for documents
  /// only.
  final String name;
  final String contentType;
  final Uint8List bytes;
  final int sizeBytes;

  @override
  List<Object?> get props => [name, contentType, bytes, sizeBytes];

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

bool _startsWith(Uint8List bytes, List<int> prefix, {int at = 0}) {
  if (bytes.length < at + prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[at + i] != prefix[i]) return false;
  }
  return true;
}

/// The content type the first bytes of a file say, by the four signatures the server checks (API design 15.4): JPEG
/// `FF D8 FF`, PNG `89 50 4E 47 0D 0A 1A 0A`, WebP `RIFF....WEBP` and PDF `%PDF-`. Null when none matches.
String? contentTypeOfBytes(Uint8List bytes) {
  if (_startsWith(bytes, [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (_startsWith(bytes, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return 'image/png';
  if (_startsWith(bytes, [0x52, 0x49, 0x46, 0x46]) && _startsWith(bytes, [0x57, 0x45, 0x42, 0x50], at: 8)) {
    return 'image/webp';
  }
  if (_startsWith(bytes, [0x25, 0x50, 0x44, 0x46, 0x2D])) return 'application/pdf';
  return null;
}
