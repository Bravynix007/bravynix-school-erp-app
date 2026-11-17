import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/validation/field_problems.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slots_repository.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_repository.dart';
import 'package:equatable/equatable.dart';

/// What the form offers: the periods of the Institution's current year, the Society's subjects, and the staff based at
/// the Institution who can still be given a lesson.
class EntryOptions extends Equatable {
  const new({required this.slots, required this.subjects, required this.teachers});

  final List<TimeSlot> slots;
  final List<Subject> subjects;
  final List<StaffSummary> teachers;

  @override
  List<Object?> get props => [slots, subjects, teachers];
}

/// What the form holds: each is null until chosen. A break ignores the subject and the teacher.
class EntryFields extends Equatable {
  const new({this.dayOfWeek, this.timeSlotId, this.isBreak = false, this.subjectId, this.staffMemberId});

  final int? dayOfWeek;
  final String? timeSlotId;
  final bool isBreak;
  final String? subjectId;
  final String? staffMemberId;

  @override
  List<Object?> get props => [dayOfWeek, timeSlotId, isBreak, subjectId, staffMemberId];
}

sealed class EntryFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Reads what the form offers; sent again on Try again.
final class EntryFormStarted extends EntryFormEvent {
  const new();
}

final class EntryFormSubmitted extends EntryFormEvent {
  const new(this.fields);

  final EntryFields fields;

  @override
  List<Object?> get props => [fields];
}

sealed class EntryFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class EntryFormLoading extends EntryFormState {
  const new();
}

class EntryFormLoadFailed extends EntryFormState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The form is open. [failure] is why the last save was refused.
class EntryFormEditing extends EntryFormState {
  const new(this.options, {this.saving = false, this.failure});

  final EntryOptions options;
  final bool saving;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [options, saving, failure];
}

class EntryFormSaved extends EntryFormState {
  const new(this.entry);

  final TimetableEntry entry;

  @override
  List<Object?> get props => [entry];
}

/// Adds an entry to [sectionId]'s week (TT-02), or, with [existing], changes that entry (TT-03).
class EntryFormBloc extends Bloc<EntryFormEvent, EntryFormState> {
  new(
    this._timetable,
    this._slots,
    this._subjects,
    this._staff, {
    required this.sectionId,
    required this.institutionId,
    this.existing,
  }) : super(const EntryFormLoading()) {
    on<EntryFormStarted>(_onStarted);
    on<EntryFormSubmitted>(_onSubmitted);
  }

  final TimetableRepository _timetable;
  final TimeSlotsRepository _slots;
  final SubjectsRepository _subjects;
  final StaffRepository _staff;
  final String sectionId;
  final String institutionId;
  final TimetableEntry? existing;

  Future<void> _onStarted(EntryFormStarted event, Emitter<EntryFormState> emit) async {
    emit(const EntryFormLoading());
    try {
      // One after the other: a record's `wait` would wrap a refusal in a ParallelWaitError, and the first refusal is
      // the one to show.
      final slots = await _slots.slots(institutionId);
      final subjects = await _subjects.subjects();
      final teachers = await _allStaff();
      emit(EntryFormEditing(EntryOptions(slots: slots, subjects: subjects, teachers: teachers)));
    } on ApiFailure catch (failure) {
      emit(EntryFormLoadFailed(failure));
    }
  }

  /// Every active staff member based at the Institution, page by page; one who is blocked cannot be given a lesson.
  Future<List<StaffSummary>> _allStaff() async {
    final all = <StaffSummary>[];
    var page = 1;
    while (true) {
      final answer = await _staff.staff(institutionId, page: page);
      all.addAll(answer.items.where((member) => !member.isBlocked));
      if (!answer.hasMore) return all;
      page++;
    }
  }

  Future<void> _onSubmitted(EntryFormSubmitted event, Emitter<EntryFormState> emit) async {
    if (state case final EntryFormEditing editing when !editing.saving) {
      final fields = event.fields;
      final problems = FieldProblems()
        ..requireChoice('dayOfWeek', fields.dayOfWeek)
        ..requireChoice('timeSlotId', fields.timeSlotId);
      if (!fields.isBreak) {
        problems
          ..requireChoice('subjectId', fields.subjectId)
          ..requireChoice('staffMemberId', fields.staffMemberId);
      }
      if (problems.failure case final failure?) {
        emit(EntryFormEditing(editing.options, failure: failure));
        return;
      }
      emit(EntryFormEditing(editing.options, saving: true));
      final input = EntryInput(
        dayOfWeek: fields.dayOfWeek!,
        timeSlotId: fields.timeSlotId!,
        isBreak: fields.isBreak,
        subjectId: fields.subjectId,
        staffMemberId: fields.staffMemberId,
      );
      try {
        emit(
          EntryFormSaved(
            existing == null ? await _timetable.add(sectionId, input) : await _timetable.change(existing!, input),
          ),
        );
      } on ApiFailure catch (failure) {
        emit(EntryFormEditing(editing.options, failure: failure));
      }
    }
  }
}
