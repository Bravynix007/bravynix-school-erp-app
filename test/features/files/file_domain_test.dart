import 'dart:typed_data';

import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_check.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/files.dart';

ChosenFile _file(String type, int size) => ChosenFile(name: 'x', contentType: type, bytes: Uint8List(size));

void main() {
  group('purposes', () {
    test('carry the numbers of API design 15.2', () {
      expect(
        {for (final purpose in FilePurpose.values) purpose.name: purpose.code},
        {
          'studentPhoto': 3,
          'staffPhoto': 4,
          'studentDocument': 5,
          'staffDocument': 6,
          'importCsv': 12,
        },
      );
    });

    test('take images for photos, PDF as well for documents, and CSV for imports', () {
      expect(FilePurpose.staffPhoto.contentTypes, ['image/jpeg', 'image/png', 'image/webp']);
      expect(FilePurpose.studentDocument.contentTypes, [...FilePurpose.studentPhoto.contentTypes, 'application/pdf']);
      expect(FilePurpose.staffDocument.contentTypes, contains('application/pdf'));
      expect(FilePurpose.importCsv.contentTypes, ['text/csv']);
      expect(
        [
          for (final purpose in FilePurpose.values)
            if (purpose.isPhoto) purpose,
        ],
        [
          FilePurpose.studentPhoto,
          FilePurpose.staffPhoto,
        ],
      );
    });
  });

  group('checkFile', () {
    test('lets a file of a type the purpose takes, up to 5 MB', () {
      expect(checkFile(photo, FilePurpose.staffPhoto), isNull);
      expect(checkFile(pdf, FilePurpose.staffDocument), isNull);
      expect(checkFile(_file('image/png', maxFileBytes), FilePurpose.staffPhoto), isNull);
    });

    test('refuses an empty file, one over 5 MB, and a type the purpose does not take', () {
      expect(checkFile(_file('image/png', 0), FilePurpose.staffPhoto), FileProblem.empty);
      expect(checkFile(_file('image/png', maxFileBytes + 1), FilePurpose.staffPhoto), FileProblem.tooLarge);
      expect(checkFile(pdf, FilePurpose.staffPhoto), FileProblem.typeNotAllowed);
      expect(checkFile(photo, FilePurpose.importCsv), FileProblem.typeNotAllowed);
    });

    test('says what is wrong with the size before the type', () {
      expect(checkFile(_file('application/pdf', maxFileBytes + 1), FilePurpose.staffPhoto), FileProblem.tooLarge);
    });
  });

  group('contentTypeOfName', () {
    test('knows the types the app sends, whatever the case of the extension', () {
      expect(contentTypeOfName('a.JPG'), 'image/jpeg');
      expect(contentTypeOfName('a.jpeg'), 'image/jpeg');
      expect(contentTypeOfName('a.png'), 'image/png');
      expect(contentTypeOfName('a.webp'), 'image/webp');
      expect(contentTypeOfName('scan.final.pdf'), 'application/pdf');
      expect(contentTypeOfName('rows.csv'), 'text/csv');
    });

    test('has no answer for another type or a name with no extension', () {
      expect(contentTypeOfName('a.heic'), isNull);
      expect(contentTypeOfName('a'), isNull);
    });
  });

  group('what the bytes are', () {
    Uint8List bytes(List<int> signature) => Uint8List.fromList([...signature, ...List.filled(20, 9)]);
    final jpeg = bytes([0xFF, 0xD8, 0xFF]);
    final png = bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    final webp = bytes([...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WEBP'.codeUnits]);
    final pdfFile = bytes([...'%PDF-'.codeUnits]);

    test('are told from the four signatures the server checks', () {
      expect(contentTypeOfBytes(jpeg), 'image/jpeg');
      expect(contentTypeOfBytes(png), 'image/png');
      expect(contentTypeOfBytes(webp), 'image/webp');
      expect(contentTypeOfBytes(pdfFile), 'application/pdf');
    });

    test('are not told from a part of a signature, a RIFF that is not WebP, or too few bytes', () {
      expect(contentTypeOfBytes(bytes([0xFF, 0xD8])), isNull);
      expect(contentTypeOfBytes(bytes([0x89, 0x50, 0x4E, 0x47])), isNull);
      expect(contentTypeOfBytes(bytes([...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WAVE'.codeUnits])), isNull);
      expect(contentTypeOfBytes(Uint8List.fromList([0xFF, 0xD8, 0xFF])), 'image/jpeg');
      expect(contentTypeOfBytes(Uint8List(0)), isNull);
      expect(contentTypeOfBytes(Uint8List.fromList(' %PDF-1'.codeUnits)), isNull);
    });

    test('decide the type and the extension of a file that is read, whatever its name says', () {
      expect(ChosenFile.read(name: 'a.png', bytes: jpeg).name, 'a.jpg');
      expect(ChosenFile.read(name: 'a.PNG', bytes: png).name, 'a.PNG');
      expect(ChosenFile.read(name: 'a.jpeg', bytes: jpeg).name, 'a.jpeg');
      expect(ChosenFile.read(name: 'scan', bytes: pdfFile).name, 'scan.pdf');
      expect(ChosenFile.read(name: '.hidden', bytes: webp).name, '.hidden.webp');
      expect(ChosenFile.read(name: 'a.b.heic', bytes: jpeg).name, 'a.b.jpg');
    });

    test('are not taken from the name when the name is of a type with a signature the bytes lack', () {
      expect(ChosenFile.read(name: 'a.pdf', bytes: bytes([1, 2])).contentType, 'application/octet-stream');
      expect(ChosenFile.read(name: 'a.png', bytes: bytes([1, 2])).contentType, 'application/octet-stream');
      expect(ChosenFile.read(name: 'a.heic', bytes: bytes([1, 2])).contentType, 'application/octet-stream');
    });

    test('are taken from the name for a type with no signature, such as CSV', () {
      final csv = ChosenFile.read(name: 'rows.csv', bytes: Uint8List.fromList('Name,Class\n'.codeUnits));
      expect([csv.name, csv.contentType], ['rows.csv', 'text/csv']);
      expect(checkFile(csv, FilePurpose.importCsv), isNull);
    });

    test('are not read for a file too big: only its size is kept, and the check refuses it', () {
      final big = ChosenFile.unread(name: 'scan.pdf', size: maxFileBytes + 1);
      expect([big.sizeBytes, big.bytes, big.contentType], [maxFileBytes + 1, isEmpty, 'application/pdf']);
      expect(checkFile(big, FilePurpose.staffDocument), FileProblem.tooLarge);
      expect(ChosenFile.unread(name: 'scan.xyz', size: 9).contentType, 'application/octet-stream');
    });
  });

  test('a chosen file is as long as its bytes, and equal to one with the same bytes', () {
    expect(photo.sizeBytes, photo.bytes.length);
    expect(photo, ChosenFile(name: photo.name, contentType: photo.contentType, bytes: Uint8List.fromList(photo.bytes)));
  });
}
