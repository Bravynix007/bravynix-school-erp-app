import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';

/// The owner or Admin confirmed Deactivate on this staff member's card (STF-05).
final class StaffDeactivated extends PagedListEvent {
  const new(this.entry);

  final StaffListEntry entry;

  @override
  List<Object?> get props => [entry];
}

/// The staff of one Institution (STF-01), searched and read a page at a time, and the deactivation of one (STF-05).
class StaffBloc extends PagedListBloc<StaffListEntry> {
  new(this._staff, this._masters, this.institutionId) {
    on<StaffDeactivated>(
      (event, emit) =>
          change(emit, event.entry, event.entry.summary.id, () => _staff.deactivate(event.entry.summary.id)),
    );
  }

  final StaffRepository _staff;
  final MastersRepository _masters;
  final String institutionId;

  @override
  Future<ItemsPage<StaffListEntry>> read(int page, String query) async {
    final read = await _staff.staff(institutionId, page: page, query: query);
    // The rows carry IDs only; the masters are kept on the phone for five minutes, so this costs little.
    final designations = {for (final entry in await _masters.entries(MasterType.designations)) entry.id: entry.name};
    final categories = {for (final entry in await _masters.entries(MasterType.classCategories)) entry.id: entry.name};
    return ItemsPage(
      [
        for (final summary in read.items)
          StaffListEntry(
            summary,
            designationName: designations[summary.designationId],
            categoryName: categories[summary.classCategoryId],
          ),
      ],
      page: read.page,
      totalPages: read.totalPages,
    );
  }
}
