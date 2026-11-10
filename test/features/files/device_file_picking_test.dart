import 'package:bravynix_school_erp/features/files/data/device_file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_check.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../helpers/files.dart';

/// The phone's image picker, answering from [next] and keeping what it was asked.
class _FakeImagePicker extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  XFile? next;
  PlatformException? failure;
  ImageSource? source;
  ImagePickerOptions? options;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    this.source = source;
    this.options = options;
    if (failure != null) throw failure!;
    return next;
  }
}

/// A file the phone's file browser hands back: [size] is what the phone says, and nothing is read until asked.
base class _FakePlatformFile extends PlatformFile {
  new(this.name, this.bytes, {this.size, this.sizeKnown = true});

  @override
  final String name;
  final Uint8List bytes;
  final int? size;

  /// Whether the phone said the size with the pick, or it has to be asked for.
  final bool sizeKnown;

  /// Set when the bytes were read, so a test can say a file was not.
  bool read = false;

  @override
  Uri get uri => Uri.parse('content://files/$name');

  @override
  XFile get xFile => XFile.fromData(bytes);

  @override
  int? lengthSync() => sizeKnown ? size : null;

  @override
  Future<int?> length() async => size ?? bytes.length;

  @override
  Future<Uint8List> readAsBytes() async {
    read = true;
    return bytes;
  }

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

/// The phone's file browser, answering from [next] and keeping what it was asked.
class _FakeFilePicker extends FilePickerPlatform with MockPlatformInterfaceMixin {
  PlatformFile? next;
  PlatformException? failure;
  FileType? type;
  List<String>? allowedExtensions;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    this.type = type;
    this.allowedExtensions = allowedExtensions;
    if (failure != null) throw failure!;
    return next;
  }
}

Uint8List _bytes(List<int> signature, [int length = 40]) =>
    Uint8List.fromList([...signature, ...List.filled(length - signature.length, 7)]);

final Uint8List _jpeg = _bytes([0xFF, 0xD8, 0xFF, 0xE0]);
final Uint8List _webp = _bytes([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits]);

void main() {
  late _FakeImagePicker images;
  late _FakeFilePicker files;
  setUp(() {
    images = _FakeImagePicker();
    ImagePickerPlatform.instance = images;
    files = _FakeFilePicker();
    FilePickerPlatform.instance = files;
  });

  group('photo', () {
    test('takes a photo from the camera or the gallery, cut down and saved as a JPEG', () async {
      images.next = XFile.fromData(_jpeg, path: '/cache/IMG_1.jpg');
      final picked = await const DeviceFilePicking().photo(PhotoSource.camera);
      expect(images.source, ImageSource.camera);
      expect(images.options?.maxWidth, 1600);
      expect(images.options?.maxHeight, 1600);
      expect(images.options?.imageQuality, 85);
      expect(picked?.name, 'IMG_1.jpg');
      expect(picked?.contentType, 'image/jpeg');
      expect(picked?.bytes, _jpeg);
      await const DeviceFilePicking().photo(PhotoSource.gallery);
      expect(images.source, ImageSource.gallery);
    });

    test('says what the bytes are, not what the phone calls them: Android keeps the name of a picture it re-saved', () async {
      // The picker saves an opaque PNG or a WebP as a JPEG under its old name (image_picker_android), and says no type.
      for (final (name, expectedName) in [
        ('scaled_Screenshot_2026.png', 'scaled_Screenshot_2026.jpg'),
        ('scaled_IMG-WA0001.webp', 'scaled_IMG-WA0001.jpg'),
        ('scaled_IMG_1.heic', 'scaled_IMG_1.jpg'),
        ('image_picker_9', 'image_picker_9.jpg'),
      ]) {
        images.next = XFile.fromData(_jpeg, path: '/cache/$name', mimeType: 'image/png');
        final picked = await const DeviceFilePicking().photo(PhotoSource.gallery);
        expect([picked?.name, picked?.contentType], [expectedName, 'image/jpeg'], reason: name);
        expect(checkFile(picked!, FilePurpose.staffPhoto), isNull);
      }
    });

    test('keeps a PNG with transparency a PNG, and a WebP a WebP', () async {
      images.next = XFile.fromData(photo.bytes, path: '/cache/scaled_logo.jpg');
      final png = await const DeviceFilePicking().photo(PhotoSource.gallery);
      expect([png?.name, png?.contentType], ['scaled_logo.png', 'image/png']);
      images.next = XFile.fromData(_webp, path: '/cache/IMG.webp');
      final webp = await const DeviceFilePicking().photo(PhotoSource.gallery);
      expect([webp?.name, webp?.contentType], ['IMG.webp', 'image/webp']);
    });

    test('does not call bytes it does not know a picture, whatever the name says', () async {
      images.next = XFile.fromData(_bytes([1, 2, 3]), path: '/cache/IMG_2.jpg');
      final picked = await const DeviceFilePicking().photo(PhotoSource.gallery);
      expect(picked?.contentType, 'application/octet-stream');
      expect(checkFile(picked!, FilePurpose.staffPhoto), FileProblem.typeNotAllowed);
    });

    test('is null when the person backs out', () async {
      expect(await const DeviceFilePicking().photo(PhotoSource.camera), isNull);
    });

    test('says which source the phone would not open', () async {
      images.failure = PlatformException(code: 'camera_access_denied');
      for (final source in PhotoSource.values) {
        await expectLater(
          const DeviceFilePicking().photo(source),
          throwsA(isA<FilePickFailure>().having((failure) => failure.source, 'source', source)),
        );
      }
    });
  });

  group('document', () {
    final pdfBytes = Uint8List.fromList([...'%PDF-1.7'.codeUnits, ...List.filled(30, 1)]);

    test('offers PDF and pictures only, and gives back a PDF as one', () async {
      files.next = _FakePlatformFile('letter.pdf', pdfBytes);
      final picked = await const DeviceFilePicking().document();
      expect(files.type, FileType.custom);
      expect(files.allowedExtensions, ['pdf', 'jpg', 'jpeg', 'png', 'webp']);
      expect([picked?.name, picked?.contentType, picked?.bytes], ['letter.pdf', 'application/pdf', pdfBytes]);
      expect(checkFile(picked!, FilePurpose.staffDocument), isNull);
    });

    test('takes the type from the bytes, so a PDF that is not one is refused here', () async {
      files.next = _FakePlatformFile('letter.pdf', _bytes([1, 2, 3]));
      final fake = await const DeviceFilePicking().document();
      expect(fake?.contentType, 'application/octet-stream');
      expect(checkFile(fake!, FilePurpose.staffDocument), FileProblem.typeNotAllowed);
      files.next = _FakePlatformFile('scan.dat', _jpeg);
      final scan = await const DeviceFilePicking().document();
      expect([scan?.name, scan?.contentType], ['scan.jpg', 'image/jpeg']);
    });

    test('does not read a file over 5 MB, and says it is too large', () async {
      final big = _FakePlatformFile('scan.pdf', pdfBytes, size: maxFileBytes + 1);
      files.next = big;
      final picked = await const DeviceFilePicking().document();
      expect(big.read, isFalse);
      expect(picked?.sizeBytes, maxFileBytes + 1);
      expect(checkFile(picked!, FilePurpose.staffDocument), FileProblem.tooLarge);
    });

    test('asks the file for its size when the phone did not say, and still reads one under 5 MB', () async {
      final unknown = _FakePlatformFile('a.pdf', pdfBytes);
      files.next = unknown;
      final picked = await const DeviceFilePicking().document();
      expect(unknown.read, isTrue);
      expect(picked?.sizeBytes, pdfBytes.length);
    });

    test('asks the file for its size when the phone did not say, and does not read one over 5 MB', () async {
      final big = _FakePlatformFile('scan.pdf', pdfBytes, size: maxFileBytes + 1, sizeKnown: false);
      files.next = big;
      final picked = await const DeviceFilePicking().document();
      expect(big.read, isFalse);
      expect(checkFile(picked!, FilePurpose.staffDocument), FileProblem.tooLarge);
    });

    test('is null when the person backs out, and says when the phone would not open the files', () async {
      expect(await const DeviceFilePicking().document(), isNull);
      files.failure = PlatformException(code: 'read_external_storage_denied');
      await expectLater(
        const DeviceFilePicking().document(),
        throwsA(isA<FilePickFailure>().having((failure) => failure.source, 'source', isNull)),
      );
    });
  });
}
