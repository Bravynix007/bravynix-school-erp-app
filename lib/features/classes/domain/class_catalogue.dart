import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';

/// The predefined classes an Institution can add: those of the categories it offers (decision 24), read from the
/// Institution and from the shared lists. Throws [ApiFailure].
class ClassCatalogue {
  const new(this._institutions, this._masters);

  final InstitutionsRepository _institutions;
  final MastersRepository _masters;

  Future<List<ClassChoice>> offered(String institutionId) async {
    final institution = await _institutions.institution(institutionId);
    final offeredIds = {for (final category in institution.classesOffered) category.id};
    final categories = [
      for (final category in await _masters.entries(MasterType.classCategories))
        if (offeredIds.contains(category.id)) category,
    ];
    return [
      for (final category in categories)
        for (final entry in await _masters.entries(MasterType.predefinedClasses, parentId: category.id))
          ClassChoice(
            predefinedClass: NamedRef(id: entry.id, code: entry.code ?? '', name: entry.name),
            category: NamedRef(id: category.id, code: category.code ?? '', name: category.name),
          ),
    ];
  }
}
