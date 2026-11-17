import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/push/domain/push_device_repository.dart';

class PushDeviceRepositoryImpl implements PushDeviceRepository {
  const new({required this._api, required this._device, required this._language});

  final ApiClient _api;
  final AppDevice _device;

  /// The language the alerts are written in: the app's, as it is when the call is made.
  final String Function() _language;

  @override
  Future<void> register(String token) => _api.data<void>(
    'me/push-device',
    method: HttpMethod.put,
    body: {
      'fcmToken': token,
      'platform': _device.platform.code,
      'appVersion': _device.appVersion,
      'language': _language(),
    },
    parse: (_) {},
  );
}
