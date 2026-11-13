import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';

/// The year, class or section the list is narrowed to changed; the first page is read again.
final class StudentsFiltered extends PagedListEvent {
  const new(this.filter);

  final StudentFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// The owner or Admin chose why, and confirmed Deactivate on this student's card (STU-05).
final class StudentDeactivated extends PagedListEvent {
  const new(this.entry, this.reason);

  final StudentListEntry entry;
  final LeavingReason reason;

  @override
  List<Object?> get props => [entry, reason];
}

/// The students of one Institution (STU-01), searched, filtered and read a page at a time, and the deactivation of one
/// (STU-05).
class StudentsBloc extends PagedListBloc<StudentListEntry> {
  new(this._students, this._options, this.institutionId) {
    on<StudentsFiltered>((event, emit) async {
      // Like a search, a filter would drop the outcome of the change that is going, so it waits (the screen locks the
      // filters meanwhile).
      if (event.filter == _filter || (state is PagedListLoaded<StudentListEntry> && _busy)) return;
      _filter = event.filter;
      await reload(emit);
    });
    on<StudentDeactivated>(
      (event, emit) => change(
        emit,
        event.entry,
        event.entry.summary.id,
        () => _students.deactivate(event.entry.summary.id, event.reason),
      ),
    );
  }

  final StudentsRepository _students;
  final SectionOptionsSource _options;
  final String institutionId;
  StudentFilter _filter = const StudentFilter();

  bool get _busy => (state as PagedListLoaded<StudentListEntry>).busyId != null;

  @override
  Future<ItemsPage<StudentListEntry>> read(int page, String query) async {
    final read = await _students.students(institutionId, page: page, query: query, filter: _filter);
    // The rows carry IDs only; the options are read once for the screen, so this costs little.
    final options = await _options.read(institutionId);
    final places = {for (final section in options.sections) section.id: section.name};
    return ItemsPage(
      [for (final summary in read.items) StudentListEntry(summary, placeName: places[summary.placement.sectionId])],
      page: read.page,
      totalPages: read.totalPages,
    );
  }
}
