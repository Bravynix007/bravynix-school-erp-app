import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/diary/data/diary_models.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_repository.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _entry(String id) => 'diary-entries/${Uri.encodeComponent(id)}';

  @override
  Future<List<DiaryEntry>> ofSection(String sectionId, String day) =>
      _api.data('diary-entries', query: {'sectionId': sectionId, 'date': day}, parse: DiaryModels.entries);

  @override
  Future<List<DiaryEntry>> ofChild(String studentId, String day) =>
      _api.data('diary-entries', query: {'studentId': studentId, 'date': day}, parse: DiaryModels.entries);

  @override
  Future<DiaryEntry> add(String sectionId, DiaryInput input) => _api.data(
    'diary-entries',
    method: HttpMethod.post,
    body: DiaryModels.createBody(sectionId, input),
    parse: DiaryModels.entry,
  );

  @override
  Future<DiaryEntry> change(DiaryEntry entry, DiaryInput input) => _api.data(
    _entry(entry.id),
    method: HttpMethod.patch,
    body: DiaryModels.changeBody(entry, input),
    parse: DiaryModels.entry,
  );

  @override
  Future<void> remove(String id) => _api.data(_entry(id), method: HttpMethod.delete, parse: (_) {});
}
