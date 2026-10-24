import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The three build environments. Each is an Android product flavor with its
/// own application id, so they install side by side.
enum Flavor {
  dev,
  staging,
  prod;

  static Flavor parse(String value) => Flavor.values.firstWhere(
    (flavor) => flavor.name == value,
    orElse: () => throw ArgumentError.value(value, 'APP_FLAVOR', 'must be dev, staging or prod'),
  );
}

/// Build-time configuration, read from `--dart-define-from-file=config/<flavor>.json`.
/// Nothing secret belongs here: the values are compiled into the app.
class AppConfig extends Equatable {
  const new({required this.flavor, required this.apiBaseUrl});

  factory fromEnvironment() => AppConfig.resolve(
    flavor: const String.fromEnvironment('APP_FLAVOR'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    buildFlavor: appFlavor,
    release: kReleaseMode,
  );

  /// The local API, for a debug run started without a config file.
  static const localApiBaseUrl = 'http://10.0.2.2:3000/v1';

  /// Checks the compiled-in values. A release build must come with its config
  /// file, and the file's `APP_FLAVOR` must match the `--flavor` it was built
  /// with, so a prod build can never carry dev settings or plain HTTP.
  static AppConfig resolve({
    required String flavor,
    required String apiBaseUrl,
    required String? buildFlavor,
    required bool release,
  }) {
    if (flavor.isEmpty && apiBaseUrl.isEmpty) {
      if (release) throw StateError('A release build needs --dart-define-from-file=config/<flavor>.json');
      return const AppConfig(flavor: Flavor.dev, apiBaseUrl: localApiBaseUrl)..validate();
    }
    if (flavor.isEmpty || apiBaseUrl.isEmpty) {
      throw StateError('Set both APP_FLAVOR and API_BASE_URL (config/<flavor>.json)');
    }
    final config = AppConfig(flavor: Flavor.parse(flavor), apiBaseUrl: apiBaseUrl)..validate();
    if (buildFlavor != null && buildFlavor.isNotEmpty && buildFlavor != config.flavor.name) {
      throw StateError('APP_FLAVOR "$flavor" does not match the build flavor "$buildFlavor"');
    }
    return config;
  }

  final Flavor flavor;

  /// The API's `/v1` base, e.g. `https://api.bravynix.in/v1` (API design 5.1).
  final String apiBaseUrl;

  bool get isProduction => flavor == Flavor.prod;

  /// HTTPS everywhere except a developer's machine (API design 5.1).
  void validate() {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || !uri.path.endsWith('/v1')) {
      throw StateError('API_BASE_URL must be an absolute URL ending in /v1, got "$apiBaseUrl"');
    }
    if (flavor != Flavor.dev && uri.scheme != 'https') {
      throw StateError('API_BASE_URL must use HTTPS outside dev');
    }
  }

  @override
  List<Object?> get props => [flavor, apiBaseUrl];
}
