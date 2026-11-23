import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';

/// The diary (DIA-01 to DIA-05). Methods throw [ApiFailure].
abstract interface class DiaryRepository {
  /// DIA-01 for staff: the entries of a section on a day, in the order written. 403 NOT_ASSIGNED for a teacher who
  /// neither leads nor teaches the section, 404 for a section out of reach.
  Future<List<DiaryEntry>> ofSection(String sectionId, String day);

  /// DIA-01 for a parent: the entries of the section the child sits in now. 404 for a child that is not theirs, 403
  /// CHILD_ACCESS_BLOCKED for a blocked one.
  Future<List<DiaryEntry>> ofChild(String studentId, String day);

  /// DIA-05: the subjects the caller may write for in the section, which are those DIA-02 accepts: every subject for
  /// an Owner, an Admin and the section's class teacher, else the ones a teacher teaches there. 403 NOT_ASSIGNED for a
  /// teacher who neither leads nor teaches the section, 404 for a section out of reach.
  Future<List<Subject>> subjects(String sectionId);

  /// DIA-02: 403 NOT_ASSIGNED unless the teacher teaches the subject in the section or leads it, 422 DATE_IN_FUTURE,
  /// DATE_TOO_OLD, DATE_OUTSIDE_CURRENT_YEAR, CURRENT_YEAR_REQUIRED and REFERENCE_INACTIVE.
  Future<DiaryEntry> add(String sectionId, DiaryInput input);

  /// DIA-03: sends what differs from [entry] with the version that was read. 409 VERSION_CONFLICT when it changed
  /// meanwhile, 403 NOT_ASSIGNED for a teacher who did not write it, 404 for one removed.
  Future<DiaryEntry> change(DiaryEntry entry, DiaryInput input);

  /// DIA-04: removes the entry from every list; nothing is deleted. 404 when it is already removed.
  Future<void> remove(String id);
}
