import 'dart:convert';
import 'dart:typed_data';

import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';

/// A real 1x1 PNG, so a widget test can show it, named and typed as the bytes are.
final photo = ChosenFile(
  name: 'kavya.png',
  contentType: 'image/png',
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAHnOcQAAAAABJRU5ErkJggg==',
  ),
);

final pdf = ChosenFile(
  name: 'letter.pdf',
  contentType: 'application/pdf',
  bytes: Uint8List.fromList([...'%PDF-1.4'.codeUnits, ...List.filled(900, 2)]),
);

final uploadedPhoto = UploadedFile(id: 'f1', contentType: 'image/png', sizeBytes: photo.sizeBytes);

final uploadedPdf = UploadedFile(id: 'f9', contentType: 'application/pdf', sizeBytes: pdf.sizeBytes);

Map<String, Object?> grantJson({String fileId = 'f1', String url = 'http://store.test/v1/local-storage/token'}) => {
  'fileId': fileId,
  'upload': {
    'url': url,
    'fields': {'key': 'k1', 'policy': 'p1'},
    'expiresAt': '2026-11-10T05:00:00.000Z',
  },
  'maxBytes': 5242880,
};

Map<String, Object?> confirmedJson({String id = 'f1'}) => {
  'id': id,
  'purpose': 4,
  'contentType': 'image/png',
  'sizeBytes': photo.sizeBytes,
  'fileStatus': 2,
};

/// A picker that hands back what it is given, or fails as the phone does.
class FakeFilePicking implements FilePicking {
  new({this.result, this.failure});

  ChosenFile? result;
  FilePickFailure? failure;
  final List<PhotoSource> asked = [];
  int documents = 0;

  @override
  Future<ChosenFile?> photo(PhotoSource source) async {
    asked.add(source);
    if (failure != null) throw failure!;
    return result;
  }

  @override
  Future<ChosenFile?> document() async {
    documents++;
    if (failure != null) throw failure!;
    return result;
  }
}
