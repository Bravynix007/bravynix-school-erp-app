import 'package:shared_preferences/shared_preferences.dart';

/// The child a parent last looked at, so the app opens on the same child. It is only a preference: a child who is no
/// longer in the parent's list is ignored.
abstract class ChildChoiceStore {
  Future<String?> read();
  Future<void> write(String studentId);
}

class PreferencesChildChoiceStore implements ChildChoiceStore {
  new([SharedPreferencesAsync? preferences]) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'parent.child_id';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> write(String studentId) => _preferences.setString(_key, studentId);
}

/// For tests and previews.
class InMemoryChildChoiceStore implements ChildChoiceStore {
  new([this._id]);

  String? _id;

  @override
  Future<String?> read() async => _id;

  @override
  Future<void> write(String studentId) async => _id = studentId;
}
