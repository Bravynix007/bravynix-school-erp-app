import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dev may use plain HTTP to the local API', () {
    expect(const AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://10.0.2.2:3000/v1').validate, returnsNormally);
  });

  test('staging and prod must use HTTPS', () {
    expect(const AppConfig(flavor: Flavor.prod, apiBaseUrl: 'http://api.bravynix.in/v1').validate, throwsStateError);
  });

  test('the base URL must end in /v1', () {
    expect(const AppConfig(flavor: Flavor.staging, apiBaseUrl: 'https://api.bravynix.in').validate, throwsStateError);
  });

  test('unknown flavors are rejected', () => expect(() => Flavor.parse('qa'), throwsArgumentError));
}
