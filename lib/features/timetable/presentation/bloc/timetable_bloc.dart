import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_repository.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';

/// The lessons and breaks of one week (TT-01), read again on Try again.
class TimetableBloc extends ListBloc<TimetableEntry> {
  new(this._timetable, this.week);

  final TimetableRepository _timetable;
  final TimetableWeek week;

  @override
  Future<List<TimetableEntry>> read() => _timetable.week(week);
}
