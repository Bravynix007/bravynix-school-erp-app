import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/timetable/data/timetable_models.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_repository.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  const new({required this._api});

  final ApiClient _api;

  @override
  Future<List<TimetableEntry>> week(TimetableWeek week) =>
      _api.data('timetable/entries', query: TimetableModels.query(week), parse: TimetableModels.entries);
}
