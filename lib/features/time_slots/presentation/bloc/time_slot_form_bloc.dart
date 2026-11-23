import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/validation/field_problems.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slots_repository.dart';
import 'package:equatable/equatable.dart';

/// What the form holds: the number and label as typed, the two times chosen (`HH:MM`, empty until chosen) and the break
/// mark. An edit changes the times and the label only, so its number and mark are those of the period.
class TimeSlotFields extends Equatable {
  const new({
    required this.periodNo,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.isBreak,
  });

  final String periodNo;
  final String label;
  final String startTime;
  final String endTime;
  final bool isBreak;

  @override
  List<Object?> get props => [periodNo, label, startTime, endTime, isBreak];
}

sealed class TimeSlotFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

final class TimeSlotFormSubmitted extends TimeSlotFormEvent {
  const new(this.fields);

  final TimeSlotFields fields;

  @override
  List<Object?> get props => [fields];
}

sealed class TimeSlotFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The form is open. [failure] is why the last save was refused.
class TimeSlotFormEditing extends TimeSlotFormState {
  const new({this.saving = false, this.failure});

  final bool saving;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [saving, failure];
}

class TimeSlotFormSaved extends TimeSlotFormState {
  const new(this.slot);

  final TimeSlot slot;

  @override
  List<Object?> get props => [slot];
}

/// Adds a period (TTS-02) to the current year of [institutionId], or, with [existing], changes that period (TTS-03).
class TimeSlotFormBloc extends Bloc<TimeSlotFormEvent, TimeSlotFormState> {
  new(this._slots, this.institutionId, {this.existing}) : super(const TimeSlotFormEditing()) {
    on<TimeSlotFormSubmitted>(_onSubmitted);
  }

  final TimeSlotsRepository _slots;
  final String institutionId;
  final TimeSlot? existing;

  Future<void> _onSubmitted(TimeSlotFormSubmitted event, Emitter<TimeSlotFormState> emit) async {
    if (state case final TimeSlotFormEditing editing when !editing.saving) {
      final fields = event.fields;
      final problems = FieldProblems();
      // The field takes digits only, so a number that does not read is one left empty.
      final periodNo = int.tryParse(fields.periodNo.trim());
      if (existing == null) problems.requireChoice('periodNo', periodNo);
      problems
        ..requireText('startTime', fields.startTime)
        ..requireText('endTime', fields.endTime);
      if (problems.failure case final failure?) {
        emit(TimeSlotFormEditing(failure: failure));
        return;
      }
      emit(const TimeSlotFormEditing(saving: true));
      // An empty label is no label: left out on add, cleared on edit.
      final label = fields.label.trim().isEmpty ? null : fields.label.trim();
      try {
        emit(
          TimeSlotFormSaved(
            existing == null
                ? await _slots.create(
                    institutionId,
                    periodNo: periodNo!,
                    startTime: fields.startTime,
                    endTime: fields.endTime,
                    isBreak: fields.isBreak,
                    label: label,
                  )
                : await _slots.update(existing!, startTime: fields.startTime, endTime: fields.endTime, label: label),
          ),
        );
      } on ApiFailure catch (failure) {
        emit(TimeSlotFormEditing(failure: failure));
      }
    }
  }
}
