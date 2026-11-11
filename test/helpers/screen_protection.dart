import 'package:bravynix_school_erp/core/device/screen_protection.dart';

/// Remembers whether the screen is kept out of screenshots, and every change made to it.
class RecordingScreenProtection implements ScreenProtection {
  final changes = <String>[];

  bool get isOn => changes.isNotEmpty && changes.last == 'protect';

  @override
  Future<void> protect() async => changes.add('protect');

  @override
  Future<void> release() async => changes.add('release');
}
