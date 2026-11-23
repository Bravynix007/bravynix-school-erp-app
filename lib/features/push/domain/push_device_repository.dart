import 'package:bravynix_school_erp/core/network/api_failure.dart';

/// Tells the server where to push this session's alerts (ME-04). Throws [ApiFailure].
abstract class PushDeviceRepository {
  /// Registers or refreshes [token] for the signed-in session; the server moves it from any session that held it.
  Future<void> register(String token);
}
