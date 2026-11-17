import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';

/// The class timetable of an Institution's current year (TT-01). Methods throw [ApiFailure].
abstract class TimetableRepository {
  /// TT-01: the entries of [week], by day and period. 422 CURRENT_YEAR_REQUIRED when the Institution has no current
  /// year, 403 NOT_ASSIGNED for a teacher and a section they neither lead nor teach, 404 for a section out of reach and
  /// for a child that is not the parent's, 403 CHILD_ACCESS_BLOCKED or 423 SECTION_BLOCKED for a blocked child.
  Future<List<TimetableEntry>> week(TimetableWeek week);

  /// TT-02: adds [input] to [sectionId]'s week. 400 INVALID_SLOT, 404 and 422 REFERENCE_INACTIVE, STAFF_BLOCKED,
  /// STAFF_NOT_AT_INSTITUTION or SUBJECT_NOT_TAUGHT for a subject or teacher that cannot be used, 409 SECTION_SLOT_TAKEN
  /// and TEACHER_DOUBLE_BOOKED (its `conflict` names the section the teacher is in), 422 CURRENT_YEAR_REQUIRED.
  Future<TimetableEntry> add(String sectionId, EntryInput input);

  /// TT-03: changes [entry] as it was read, with its version, to [input]. The same refusals as [add], and 409
  /// VERSION_CONFLICT when it changed meanwhile, 404 when it was removed.
  Future<TimetableEntry> change(TimetableEntry entry, EntryInput input);

  /// TT-04: removes the entry; its section's and its teacher's period are free again. 404 when it is already gone.
  Future<void> remove(String entryId);
}
