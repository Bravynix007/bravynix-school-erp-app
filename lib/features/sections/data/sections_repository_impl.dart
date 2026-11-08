import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/sections/data/section_models.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';

class SectionsRepositoryImpl implements SectionsRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _path(String id) => 'sections/${Uri.encodeComponent(id)}';

  @override
  Future<List<Section>> sections(String classId) =>
      _api.data('classes/${Uri.encodeComponent(classId)}/sections', parse: SectionModels.sections);

  @override
  Future<Section> create(String classId, {required String predefinedSectionId, String? displayName, int? capacity}) =>
      _api.data(
        'sections',
        method: HttpMethod.post,
        body: SectionModels.createBody(
          classId,
          predefinedSectionId: predefinedSectionId,
          displayName: displayName,
          capacity: capacity,
        ),
        parse: SectionModels.section,
      );

  @override
  Future<Section> update(Section section, {required String displayName, int? capacity}) => _api.data(
    _path(section.id),
    method: HttpMethod.patch,
    body: SectionModels.updateBody(section, displayName: displayName, capacity: capacity),
    parse: SectionModels.section,
  );

  @override
  Future<void> deactivate(String id) => _api.data(_path(id), method: HttpMethod.delete, parse: (_) {});
}
