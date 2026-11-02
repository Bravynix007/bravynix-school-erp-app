import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';

/// What BravyNix has charged the Owner's Society (API design 10.22). Methods throw [ApiFailure].
abstract class PlatformDuesRepository {
  /// BIL-01: the total still due and every due of the Society, newest first. It answers while the Owners
  /// are blocked, so a blocked Owner can still see what is owed.
  Future<PlatformDues> dues();

  /// BIL-02: one due of the Owner's own Society; 404 for any other.
  Future<PlatformDue> due(String id);
}
