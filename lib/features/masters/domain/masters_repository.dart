import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';

/// The shared lists (MST-01). Methods throw [ApiFailure].
abstract class MastersRepository {
  /// The shown entries of [type], in the master's order. [parentId] narrows states to a country, cities to a state
  /// (required for cities) and predefined classes to a class category.
  ///
  /// A list is kept for five minutes, then asked for again with `If-None-Match`, so a screen that opens often reads
  /// it from the phone and the server answers 304 when nothing changed (API design 10.4g, 19.2).
  Future<List<MasterEntry>> entries(MasterType type, {String? parentId});
}
