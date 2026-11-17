import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/timetable/data/timetable_models.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_repository.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _path(String id) => 'timetable/entries/${Uri.encodeComponent(id)}';

  @override
  Future<List<TimetableEntry>> week(TimetableWeek week) =>
      _api.data('timetable/entries', query: TimetableModels.query(week), parse: TimetableModels.entries);

  @override
  Future<TimetableEntry> add(String sectionId, EntryInput input) => _api.data(
    'timetable/entries',
    method: HttpMethod.post,
    body: TimetableModels.createBody(sectionId, input),
    parse: TimetableModels.entry,
  );

  @override
  Future<TimetableEntry> change(TimetableEntry entry, EntryInput input) => _api.data(
    _path(entry.id),
    method: HttpMethod.patch,
    body: TimetableModels.updateBody(entry, input),
    parse: TimetableModels.entry,
  );

  @override
  Future<void> remove(String entryId) => _api.data(_path(entryId), method: HttpMethod.delete, parse: (_) {});
}
