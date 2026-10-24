import 'dart:convert';
import 'dart:io';

import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/build.dart' as build;

/// Every config file the release builds use (re-review R-A5).
void main() {
  Map<String, dynamic> configFor(Flavor flavor) =>
      jsonDecode(File('config/${flavor.name}.json').readAsStringSync()) as Map<String, dynamic>;

  for (final flavor in Flavor.values) {
    test('config/${flavor.name}.json is a valid ${flavor.name} release config', () {
      final config = configFor(flavor);
      expect(build.configProblem(flavor.name, config), isNull);
      // As the app checks it on Android (with a build flavor) and on iOS (without one).
      for (final buildFlavor in [flavor.name, null]) {
        expect(
          AppConfig.resolve(
            flavor: config['APP_FLAVOR'] as String,
            apiBaseUrl: config['API_BASE_URL'] as String,
            buildFlavor: buildFlavor,
            release: true,
          ),
          isA<AppConfig>().having((c) => c.flavor, 'flavor', flavor),
        );
      }
    });
  }

  test('the build script refuses a config file of another flavor', () {
    expect(build.configProblem('prod', configFor(Flavor.dev)), contains('APP_FLAVOR "dev"'));
    expect(build.configProblem('staging', configFor(Flavor.prod)), contains('APP_FLAVOR "prod"'));
  });

  test('the build script refuses plain HTTP outside dev', () {
    expect(
      build.configProblem('prod', {'APP_FLAVOR': 'prod', 'API_BASE_URL': 'http://api.bravynix.in/v1'}),
      contains('HTTPS'),
    );
    expect(build.configProblem('prod', {'APP_FLAVOR': 'prod'}), contains('API_BASE_URL'));
    expect(build.configProblem('prod', ['not', 'a', 'map']), contains('JSON object'));
  });
}
