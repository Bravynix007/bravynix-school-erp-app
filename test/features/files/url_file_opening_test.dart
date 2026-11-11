import 'package:bravynix_school_erp/features/files/data/url_file_opening.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// The phone's launcher, answering from [opens] and keeping what it was asked.
class _FakeLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  bool opens = true;
  PlatformException? failure;
  String? url;
  LaunchOptions? options;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    this.options = options;
    if (failure != null) throw failure!;
    return opens;
  }
}

void main() {
  late _FakeLauncher launcher;
  setUp(() {
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  final link = Uri.parse('https://store.test/get/token?sig=1');

  test('hands the link to the browser outside the app, which makes it download the file', () async {
    expect(await const UrlFileOpening().open(link), isTrue);
    expect(launcher.url, link.toString());
    expect(launcher.options?.mode, PreferredLaunchMode.externalApplication);
  });

  test('says no when the phone has nothing to open it with', () async {
    launcher.opens = false;
    expect(await const UrlFileOpening().open(link), isFalse);
  });

  test('says no when the phone refuses the call', () async {
    launcher.failure = PlatformException(code: 'ACTIVITY_NOT_FOUND');
    expect(await const UrlFileOpening().open(link), isFalse);
  });
}
