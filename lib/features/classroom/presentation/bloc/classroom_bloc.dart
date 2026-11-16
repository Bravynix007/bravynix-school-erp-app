import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/classroom/domain/classroom.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';

/// The students in the sections a teacher leads or teaches (STU-01), searched and read a page at a time. Nothing changes
/// from the list, so only the reading is here.
class ClassroomBloc extends PagedListBloc<ClassroomEntry> {
  new(this._classroom, this._options, this.institutionId);

  final ClassroomRepository _classroom;
  final SectionOptionsSource _options;
  final String institutionId;

  @override
  Future<ItemsPage<ClassroomEntry>> read(int page, String query) async {
    final read = await _classroom.students(institutionId, page: page, query: query);
    // The rows carry IDs only; the options hold the teacher's own sections, read once for the screen.
    final options = await _options.read(institutionId);
    return ItemsPage(
      [
        for (final student in read.items)
          ClassroomEntry(student, placeName: options.sections.nameOf(student.placement.sectionId)),
      ],
      page: read.page,
      totalPages: read.totalPages,
    );
  }
}
