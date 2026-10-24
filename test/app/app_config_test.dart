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

  group('resolve (review A8)', () {
    test('a debug run without a config file uses the local API', () {
      final config = AppConfig.resolve(flavor: '', apiBaseUrl: '', buildFlavor: null, release: false);
      expect(config, const AppConfig(flavor: Flavor.dev, apiBaseUrl: AppConfig.localApiBaseUrl));
    });

    test('a release build without a config file refuses to start', () {
      expect(
        () => AppConfig.resolve(flavor: '', apiBaseUrl: '', buildFlavor: 'prod', release: true),
        throwsStateError,
      );
    });

    test('the config file must match the build flavor', () {
      expect(
        () => AppConfig.resolve(
          flavor: 'dev',
          apiBaseUrl: 'http://10.0.2.2:3000/v1',
          buildFlavor: 'prod',
          release: true,
        ),
        throwsStateError,
      );
    });

    test('a matching prod config resolves', () {
      final config = AppConfig.resolve(
        flavor: 'prod',
        apiBaseUrl: 'https://api.bravynix.in/v1',
        buildFlavor: 'prod',
        release: true,
      );
      expect(config.isProduction, isTrue);
    });

    test('half a config is refused', () {
      expect(
        () => AppConfig.resolve(flavor: 'staging', apiBaseUrl: '', buildFlavor: null, release: false),
        throwsStateError,
      );
    });
  });
}
