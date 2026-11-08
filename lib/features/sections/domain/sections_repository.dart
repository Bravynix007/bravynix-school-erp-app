import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';

/// The sections of a class (SEC-01 to SEC-04). Methods throw [ApiFailure].
abstract class SectionsRepository {
  /// SEC-01: the active sections in the order of the predefined sections.
  Future<List<Section>> sections(String classId);

  /// SEC-02: [displayName] and [capacity] are left out when null (the name then defaults to the predefined name).
  /// 409 DUPLICATE on the predefined section or the name.
  Future<Section> create(String classId, {required String predefinedSectionId, String? displayName, int? capacity});

  /// SEC-03: the name and the capacity (`null` clears it) with the version that was read. The class and the predefined
  /// section never change.
  Future<Section> update(Section section, {required String displayName, int? capacity});

  /// SEC-04: deactivates the section; its name and predefined section are free again.
  Future<void> deactivate(String id);
}
