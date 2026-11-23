import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_repository.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';

final class EntryRemoved extends ListEvent {
  const new(this.entry);

  final TimetableEntry entry;

  @override
  List<Object?> get props => [entry];
}

/// The lessons and breaks of one week (TT-01), read again on Try again, and removing one (TT-04).
class TimetableBloc extends ListBloc<TimetableEntry> {
  new(this._timetable, this.week) {
    on<EntryRemoved>(
      (event, emit) => change(emit, event.entry, event.entry.id, () => _timetable.remove(event.entry.id)),
    );
  }

  final TimetableRepository _timetable;
  final TimetableWeek week;

  @override
  Future<List<TimetableEntry>> read() => _timetable.week(week);
}
