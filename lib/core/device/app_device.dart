import 'dart:io' show Platform;

import 'package:equatable/equatable.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum DevicePlatform {
  /// `platform` 1 in the verify body; `android` in `X-App-Platform`.
  android(1),

  /// `platform` 2; `ios`.
  ios(2);

  new(this.code);

  final int code;
}

/// What the API needs to know about this install: the version gate headers
/// (API design 5.2) and the `device` block of the login call (10.2).
class AppDevice extends Equatable {
  const new({required this.platform, required this.appVersion, this.label});

  static Future<AppDevice> load() async {
    final info = await PackageInfo.fromPlatform();
    return AppDevice(
      platform: Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
      appVersion: info.version,
      label: Platform.operatingSystem,
    );
  }

  final DevicePlatform platform;

  /// The version name from pubspec, e.g. `1.4.2`; at most 20 characters.
  final String appVersion;

  /// Shown in "your devices"; at most 100 characters.
  final String? label;

  Map<String, Object?> toJson() => {
    'platform': platform.code,
    'appVersion': appVersion,
    if (label != null) 'label': label,
  };

  @override
  List<Object?> get props => [platform, appVersion, label];
}
