import 'package:bravynix_school_erp/core/storage/accent_choice_store.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('remembers the accent in the preferences, and reads nothing before one was chosen', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final store = PreferencesAccentChoiceStore(SharedPreferencesAsync());
    expect(await store.read(), isNull);
    await store.write(AppAccent.rosePink);
    expect(await PreferencesAccentChoiceStore(SharedPreferencesAsync()).read(), AppAccent.rosePink);
  });

  test('ignores a name the app no longer has', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({'app.accent': 'mauve'});
    expect(await PreferencesAccentChoiceStore(SharedPreferencesAsync()).read(), isNull);
  });

  test('the in-memory store remembers the last accent written', () async {
    final store = InMemoryAccentChoiceStore();
    expect(await store.read(), isNull);
    await store.write(AppAccent.steelBlue);
    await store.write(AppAccent.darkCyan);
    expect(await store.read(), AppAccent.darkCyan);
  });
}
