import 'package:shared_preferences/shared_preferences.dart';

/// The Institution the person last worked in, so every Institution-scoped setup screen opens on it. It is only a
/// preference: an Institution that is no longer in the person's list is ignored.
abstract class InstitutionChoiceStore {
  Future<String?> read();
  Future<void> write(String institutionId);
}

class PreferencesInstitutionChoiceStore implements InstitutionChoiceStore {
  new([SharedPreferencesAsync? preferences]) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'setup.institution_id';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> write(String institutionId) => _preferences.setString(_key, institutionId);
}

/// For tests and previews.
class InMemoryInstitutionChoiceStore implements InstitutionChoiceStore {
  new([this._id]);

  String? _id;

  @override
  Future<String?> read() async => _id;

  @override
  Future<void> write(String institutionId) async => _id = institutionId;
}
