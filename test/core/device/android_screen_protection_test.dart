import 'package:bravynix_school_erp/core/device/android_screen_protection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.bravynix.schoolerp/screen'),
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.bravynix.schoolerp/screen'),
      null,
    );
  });

  test('asks the Android window to be kept out of screenshots, and to let go of it', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const protection = AndroidScreenProtection();
    await protection.protect();
    await protection.release();
    expect(calls, ['protect', 'release']);
  });

  test('does nothing on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const protection = AndroidScreenProtection();
    await protection.protect();
    await protection.release();
    expect(calls, isEmpty);
  });
}
