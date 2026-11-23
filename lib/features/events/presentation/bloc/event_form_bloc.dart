import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/validation/field_problems.dart';
import 'package:bravynix_school_erp/features/classes/domain/class_catalogue.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:equatable/equatable.dart';

/// What the form offers: the Institutions an event can be created for (none when one is edited, which keeps its scope),
/// and the predefined classes a holiday for students can be limited to.
class EventOptions extends Equatable {
  const new({required this.institutions, required this.classes});

  final List<InstitutionSummary> institutions;
  final List<ClassChoice> classes;

  @override
  List<Object?> get props => [institutions, classes];
}

/// What the form holds: the event as typed, and for a new event its [scope] and, for an Institution, which one.
class EventFields extends Equatable {
  const new({required this.input, this.scope = EventScope.institution, this.institutionId});

  final EventInput input;
  final EventScope scope;
  final String? institutionId;

  @override
  List<Object?> get props => [input, scope, institutionId];
}

sealed class EventFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Reads what the form offers; sent again on Try again.
final class EventFormStarted extends EventFormEvent {
  const new();
}

final class EventFormSubmitted extends EventFormEvent {
  const new(this.fields);

  final EventFields fields;

  @override
  List<Object?> get props => [fields];
}

sealed class EventFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class EventFormLoading extends EventFormState {
  const new();
}

class EventFormLoadFailed extends EventFormState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The form is open. [failure] is why the last save was refused.
class EventFormEditing extends EventFormState {
  const new(this.options, {this.saving = false, this.failure});

  final EventOptions options;
  final bool saving;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [options, saving, failure];
}

class EventFormSaved extends EventFormState {
  const new(this.event);

  final SchoolEvent event;

  @override
  List<Object?> get props => [event];
}

/// Creates an event (EVT-02), or, with [existing], changes that event (EVT-04).
class EventFormBloc extends Bloc<EventFormEvent, EventFormState> {
  new(this._events, this._institutions, this._catalogue, {this.existing}) : super(const EventFormLoading()) {
    on<EventFormStarted>(_onStarted);
    on<EventFormSubmitted>(_onSubmitted);
  }

  final EventsRepository _events;
  final InstitutionsRepository _institutions;
  final ClassCatalogue _catalogue;
  final SchoolEvent? existing;

  Future<void> _onStarted(EventFormStarted event, Emitter<EventFormState> emit) async {
    emit(const EventFormLoading());
    try {
      // One after the other: the first refusal is the one to show.
      final institutions = existing == null ? await _institutions.institutions() : const <InstitutionSummary>[];
      emit(EventFormEditing(EventOptions(institutions: institutions, classes: await _catalogue.all())));
    } on ApiFailure catch (failure) {
      emit(EventFormLoadFailed(failure));
    }
  }

  Future<void> _onSubmitted(EventFormSubmitted event, Emitter<EventFormState> emit) async {
    if (state case final EventFormEditing editing when !editing.saving) {
      final fields = event.fields;
      final input = fields.input;
      final problems = FieldProblems()
        ..requireText('title', input.title)
        ..requireText('durationLabel', input.durationLabel);
      if (input.endDate.isBefore(input.startDate)) problems.add('endDate', 'OUT_OF_RANGE');
      if (existing == null && fields.scope == EventScope.institution) {
        problems.requireChoice('institutionId', fields.institutionId);
      }
      if (input.isHoliday) {
        problems.requireChoice('holidayType', input.holidayType);
        if (!input.holidayForStudents && !input.holidayForStaff) problems.add('holidayForStudents', 'REQUIRED');
      }
      if (problems.failure case final failure?) {
        emit(EventFormEditing(editing.options, failure: failure));
        return;
      }
      emit(EventFormEditing(editing.options, saving: true));
      try {
        emit(
          EventFormSaved(
            existing == null
                ? await _events.create(input, scope: fields.scope, institutionId: _institutionOf(fields))
                : await _events.change(existing!, input),
          ),
        );
      } on ApiFailure catch (failure) {
        emit(EventFormEditing(editing.options, failure: failure));
      }
    }
  }

  /// A Society event names no Institution.
  static String? _institutionOf(EventFields fields) =>
      fields.scope == EventScope.institution ? fields.institutionId : null;
}
