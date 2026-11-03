import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';

/// The Society's subjects (SUB-01 to SUB-04). Methods throw [ApiFailure].
abstract class SubjectsRepository {
  /// SUB-01: the active subjects by name.
  Future<List<Subject>> subjects();

  /// SUB-02: [code] is left out when empty. 409 DUPLICATE on the name or the code.
  Future<Subject> create({required String name, String? code});

  /// SUB-03: sends the name and the code (`null` clears it) with the version that was read. 409 VERSION_CONFLICT when
  /// it changed meanwhile, 409 DUPLICATE as for [create].
  Future<Subject> update(Subject subject, {required String name, String? code});

  /// SUB-04: deactivates the subject; nothing is deleted, and its name and code are free again.
  Future<void> deactivate(String id);
}
