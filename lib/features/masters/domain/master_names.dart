import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';

extension MasterNames on MastersRepository {
  /// The name of entry [id] of [type] (narrowed to [parentId] where the master has one), or null when there is no
  /// [id] or the master no longer shows it.
  Future<String?> nameOf(MasterType type, String? id, {String? parentId}) async {
    if (id == null) return null;
    for (final entry in await entries(type, parentId: parentId)) {
      if (entry.id == id) return entry.name;
    }
    return null;
  }
}
