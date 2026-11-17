import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/push/domain/push_device_repository.dart';
import 'package:bravynix_school_erp/features/push/domain/push_messaging.dart';

/// Registers this install's push token with the server once the person is signed in, and again when the token or the
/// language changes. A refusal is not shown: alerts still reach the inbox, and the next sign-in tries again.
class PushRegistrar {
  const new(this._messaging, this._devices);

  final PushMessaging _messaging;
  final PushDeviceRepository _devices;

  /// Whether the server now has this install's token; false when the phone gave none or the server refused it.
  Future<bool> register() async {
    final token = await _messaging.token();
    if (token == null || token.isEmpty) return false;
    try {
      await _devices.register(token);
      return true;
    } on ApiFailure {
      return false;
    }
  }
}
