import 'package:bravynix_school_erp/core/storage/institution_choice_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('remembers the Institution in the preferences, and reads nothing before one was chosen', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final store = PreferencesInstitutionChoiceStore(SharedPreferencesAsync());
    expect(await store.read(), isNull);
    await store.write('i2');
    expect(await PreferencesInstitutionChoiceStore(SharedPreferencesAsync()).read(), 'i2');
  });

  test('the in-memory store remembers the last Institution written', () async {
    final store = InMemoryInstitutionChoiceStore();
    expect(await store.read(), isNull);
    await store.write('i1');
    await store.write('i2');
    expect(await store.read(), 'i2');
  });
}
