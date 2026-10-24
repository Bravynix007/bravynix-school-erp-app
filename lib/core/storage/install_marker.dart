import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that this install has started before. It lives in the app's
/// preferences, which are deleted with the app, unlike the iOS Keychain.
abstract class InstallMarker {
  Future<bool> isSet();
  Future<void> set();
}

class PreferencesInstallMarker implements InstallMarker {
  new([SharedPreferencesAsync? preferences]) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'app.install_started';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isSet() async => await _preferences.getBool(_key) ?? false;

  @override
  Future<void> set() => _preferences.setBool(_key, true);
}

/// For tests and previews.
class InMemoryInstallMarker implements InstallMarker {
  new({this._started = false});

  bool _started;

  @override
  Future<bool> isSet() async => _started;

  @override
  Future<void> set() async => _started = true;
}

/// iOS keeps Keychain items after the app is deleted, so a reinstall would
/// open straight into the last person's session: on a shared family phone,
/// another child's data. The first start of each install clears the tokens.
///
/// Called when the session is restored, after `runApp`, and only once the
/// tokens are readable: before the phone's first unlock the preferences read
/// as empty too, which would make every prewarmed launch look like a first
/// start and sign the person out (re-review R-A2).
Future<void> clearTokensOnFirstStart({required InstallMarker marker, required TokenStorage tokens}) async {
  await tokens.waitUntilAvailable();
  if (await marker.isSet()) return;
  await tokens.clear();
  await marker.set();
}
