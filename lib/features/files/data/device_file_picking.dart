import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_check.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// The phone's own pickers: `image_picker` for the camera and the gallery, `file_picker` for documents.
class DeviceFilePicking implements FilePicking {
  const new();

  /// A photo is cut down to this edge and re-saved as a JPEG at this quality, so a 12-megapixel photo is well under
  /// the 5 MB the server takes, and a phone that saves HEIC sends a type the server knows.
  static const _photoEdge = 1600.0;
  static const _photoQuality = 85;

  static const _documentExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];

  @override
  Future<ChosenFile?> photo(PhotoSource source) async {
    final XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: _photoEdge,
        maxHeight: _photoEdge,
        imageQuality: _photoQuality,
      );
    } on PlatformException {
      throw FilePickFailure(source);
    }
    if (image == null) return null;
    // The phone's own word for the type is not used: on Android the picker re-saves the picture as a JPEG and keeps
    // its name, so only the bytes say what it is.
    return ChosenFile.read(name: image.name, bytes: await image.readAsBytes());
  }

  @override
  Future<ChosenFile?> document() async {
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: _documentExtensions);
    } on PlatformException {
      throw const FilePickFailure(null);
    }
    if (file == null) return null;
    // A file over the limit is not read: the check refuses it by its size.
    final size = file.lengthSync() ?? await file.length();
    if (size != null && size > maxFileBytes) return ChosenFile.unread(name: file.name, size: size);
    return ChosenFile.read(name: file.name, bytes: await file.readAsBytes());
  }
}
