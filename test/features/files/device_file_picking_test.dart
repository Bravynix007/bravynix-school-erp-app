import 'package:bravynix_school_erp/features/files/data/device_file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

void main() {
  late _FakeImagePicker platform;
  setUp(() {
    platform = _FakeImagePicker();
    ImagePickerPlatform.instance = platform;
  });

  final bytes = Uint8List.fromList([1, 2, 3]);

  test('takes a photo from the camera or the gallery, cut down and saved as a JPEG', () async {
    platform.next = XFile.fromData(bytes, path: '/cache/IMG_1.jpg', mimeType: 'image/jpeg');
    final picked = await const DeviceFilePicking().photo(PhotoSource.camera);
    expect(platform.source, ImageSource.camera);
    expect(platform.options?.maxWidth, 1600);
    expect(platform.options?.maxHeight, 1600);
    expect(platform.options?.imageQuality, 85);
    expect(picked?.name, 'IMG_1.jpg');
    expect(picked?.contentType, 'image/jpeg');
    expect(picked?.bytes, bytes);
    await const DeviceFilePicking().photo(PhotoSource.gallery);
    expect(platform.source, ImageSource.gallery);
  });

  test(
    'reads the type from the name when the phone does not say, and falls back to JPEG for a name it does not know',
    () async {
      platform.next = XFile.fromData(bytes, path: '/cache/IMG_2.PNG');
      expect((await const DeviceFilePicking().photo(PhotoSource.gallery))?.contentType, 'image/png');
      platform.next = XFile.fromData(bytes, path: '/cache/image_picker_9');
      expect((await const DeviceFilePicking().photo(PhotoSource.gallery))?.contentType, 'image/jpeg');
    },
  );

  test('is null when the person backs out', () async {
    expect(await const DeviceFilePicking().photo(PhotoSource.camera), isNull);
  });

  test('says which source the phone would not open', () async {
    platform.failure = PlatformException(code: 'camera_access_denied');
    for (final source in PhotoSource.values) {
      await expectLater(
        const DeviceFilePicking().photo(source),
        throwsA(isA<FilePickFailure>().having((failure) => failure.source, 'source', source)),
      );
    }
  });
}
