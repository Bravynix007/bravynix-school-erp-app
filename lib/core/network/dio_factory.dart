import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/interceptors/auth_interceptor.dart';
import 'package:bravynix_school_erp/core/network/interceptors/headers_interceptor.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Builds the [ApiClient] and its two Dio instances: the main one with the
/// auth interceptor, and a bare one for refreshes and repeats.
ApiClient createApiClient({
  required AppConfig config,
  required AppDevice device,
  required TokenStorage tokens,
  required ApiEvents events,
  required String Function() language,
  HttpClientAdapter? adapter,
}) {
  final options = BaseOptions(
    // A trailing slash so relative paths resolve under /v1.
    baseUrl: '${config.apiBaseUrl}/',
    connectTimeout: ApiClient.defaultTimeout,
    sendTimeout: ApiClient.defaultTimeout,
    receiveTimeout: ApiClient.defaultTimeout,
    contentType: Headers.jsonContentType,
  );
  final headers = HeadersInterceptor(device: device, language: language);

  Dio build() {
    final dio = Dio(options);
    if (adapter != null) dio.httpClientAdapter = adapter;
    return dio;
  }

  final bare = build()..interceptors.add(headers);
  final main = build()
    ..interceptors.addAll([
      headers,
      AuthInterceptor(storage: tokens, refresher: DioTokenRefresher(bare), retryDio: bare, events: events),
    ]);
  return ApiClient(main, events: events);
}
