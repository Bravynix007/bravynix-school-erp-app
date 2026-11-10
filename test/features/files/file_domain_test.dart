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

  test('a chosen file is as long as its bytes, and equal to one with the same bytes', () {
    expect(photo.sizeBytes, photo.bytes.length);
    expect(photo, ChosenFile(name: photo.name, contentType: photo.contentType, bytes: Uint8List.fromList(photo.bytes)));
  });
}
