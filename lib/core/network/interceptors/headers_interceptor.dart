import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Headers every mobile call carries (API design 7.2, 5.2, 20):
/// `X-App-Version` and `X-App-Platform` for the version gate, a client-made
/// `X-Request-Id`, and `Accept-Language` for messages before login.
class HeadersInterceptor extends Interceptor {
  new({required this.device, required this.language, Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDevice device;

  /// The app's current language code: en, hi, kn, ml, mr, ta or te (PRD 11.3).
  final String Function() language;
  final Uuid _uuid;

  static const requestIdHeader = 'X-Request-Id';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      'Accept': 'application/json',
      'Accept-Language': language(),
      'X-App-Version': device.appVersion,
      'X-App-Platform': device.platform.name,
    });
    // A retry keeps its request id, so the logs show one tap.
    options.headers.putIfAbsent(requestIdHeader, _uuid.v7);
    handler.next(options);
  }
}
