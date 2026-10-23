import 'package:equatable/equatable.dart';

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

  factory fromEnvironment() {
    const flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/v1');
    return AppConfig(flavor: Flavor.parse(flavor), apiBaseUrl: apiBaseUrl)..validate();
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
