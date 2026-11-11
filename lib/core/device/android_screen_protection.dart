import 'package:bravynix_school_erp/core/device/screen_protection.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

/// Android's `FLAG_SECURE` on the window, set by `MainActivity` over a method channel. The other platforms are left as
/// they are: this does nothing there.
class AndroidScreenProtection implements ScreenProtection {
  const new();

  static const _channel = MethodChannel('com.bravynix.schoolerp/screen');

  bool get _onAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> protect() async {
    if (_onAndroid) await _channel.invokeMethod<void>('protect');
  }

  @override
  Future<void> release() async {
    if (_onAndroid) await _channel.invokeMethod<void>('release');
  }
}
