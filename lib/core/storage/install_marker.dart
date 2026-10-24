import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that this install has started before, and that a sign-out still
/// has stored tokens to delete. It lives in the app's preferences, which are
/// deleted with the app, unlike the iOS Keychain.
abstract class InstallMarker {
  Future<bool> isSet();
  Future<void> set();

  /// Set when logging out could not delete the stored tokens, so the next
  /// start deletes them before anything reads them.
  Future<bool> isSignOutPending();
  Future<void> setSignOutPending({required bool pending});
}

class PreferencesInstallMarker implements InstallMarker {
  new([SharedPreferencesAsync? preferences]) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'app.install_started';
  static const _signOutKey = 'auth.sign_out_pending';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isSet() async => await _preferences.getBool(_key) ?? false;

  @override
  Future<void> set() => _preferences.setBool(_key, true);

  @override
  Future<bool> isSignOutPending() async => await _preferences.getBool(_signOutKey) ?? false;

  @override
  Future<void> setSignOutPending({required bool pending}) =>
      pending ? _preferences.setBool(_signOutKey, true) : _preferences.remove(_signOutKey);
}

/// For tests and previews.
class InMemoryInstallMarker implements InstallMarker {
  new({this._started = false, this._signOutPending = false});

  bool _started;
  bool _signOutPending;

  @override
  Future<bool> isSet() async => _started;

  @override
  Future<void> set() async => _started = true;

  @override
  Future<bool> isSignOutPending() async => _signOutPending;

  @override
  Future<void> setSignOutPending({required bool pending}) async => _signOutPending = pending;
}

/// iOS keeps Keychain items after the app is deleted, so a reinstall would
/// open straight into the last person's session: on a shared family phone,
/// another child's data. The first start of each install clears the tokens,
/// as does the first start after a logout that could not delete them.
///
/// Called when the session is restored, after `runApp`, and only once the
/// stored tokens have been read. Before the phone's first unlock the
/// preferences read as empty, which would make a prewarmed launch look like a
/// first start and sign the person out (re-review R-A2); the tokens
/// (first_unlock_this_device) cannot be read then either, so a read that
/// worked means the preferences can be trusted, even on a locked phone
/// (final pass). Returns whether the tokens were cleared.
Future<bool> clearTokensOnFirstStart({required InstallMarker marker, required TokenStorage tokens}) async {
  var cleared = false;
  if (await marker.isSignOutPending()) {
    await tokens.clear();
    await marker.setSignOutPending(pending: false);
    cleared = true;
  }
  if (await marker.isSet()) return cleared;
  await tokens.clear();
  await marker.set();
  return true;
}
