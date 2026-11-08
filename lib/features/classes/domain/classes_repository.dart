import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';

/// The classes of an Institution (CLS-01 to CLS-05). Methods throw [ApiFailure].
abstract class ClassesRepository {
  /// CLS-01: the active classes by category, predefined class and stream.
  Future<List<SchoolClass>> classes(String institutionId);

  /// CLS-02: [displayName] and [code] are left out when null (the name then defaults to the predefined name, with the
  /// stream after it). 409 DUPLICATE, 422 CLASS_NOT_OFFERED, 422 STREAM_NOT_ALLOWED.
  Future<SchoolClass> create(
    String institutionId,
    NewClass item, {
    String? displayName,
    String? code,
  });

  /// CLS-03: up to 50 classes, all or nothing; a refusal names the item in its field path (`classes[2].streamName`).
  Future<List<SchoolClass>> createMany(String institutionId, List<NewClass> items);

  /// CLS-04: the name and the code (`null` clears it) with the version that was read. The predefined class, the stream
  /// and the category never change.
  Future<SchoolClass> update(SchoolClass schoolClass, {required String displayName, String? code});

  /// CLS-05: deactivates the class and its active sections; nothing is deleted.
  Future<void> deactivate(String id);
}
