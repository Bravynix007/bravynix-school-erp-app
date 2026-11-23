import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The accent colour the person picked in Profile (PRD 6.3), so the app opens in it. It is only a preference: a name
/// the app no longer has is ignored.
abstract class AccentChoiceStore {
  Future<AppAccent?> read();
  Future<void> write(AppAccent accent);
}

class PreferencesAccentChoiceStore implements AccentChoiceStore {
  new([SharedPreferencesAsync? preferences]) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'app.accent';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppAccent?> read() async {
    final name = await _preferences.getString(_key);
    return AppAccent.values.where((accent) => accent.name == name).firstOrNull;
  }

  @override
  Future<void> write(AppAccent accent) => _preferences.setString(_key, accent.name);
}

/// For tests and previews.
class InMemoryAccentChoiceStore implements AccentChoiceStore {
  new([this._accent]);

  AppAccent? _accent;

  @override
  Future<AppAccent?> read() async => _accent;

  @override
  Future<void> write(AppAccent accent) async => _accent = accent;
}
