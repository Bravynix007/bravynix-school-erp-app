import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/validation/field_problems.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:equatable/equatable.dart';

sealed class EventScopeEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Reads the Institutions the event can move to; sent again on Try again.
final class EventScopeStarted extends EventScopeEvent {
  const new();
}

final class EventScopeSubmitted extends EventScopeEvent {
  const new(this.scope, this.institutionId);

  final EventScope scope;

  /// The Institution, when [scope] is one.
  final String? institutionId;

  @override
  List<Object?> get props => [scope, institutionId];
}

sealed class EventScopeState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class EventScopeLoading extends EventScopeState {
  const new();
}

class EventScopeLoadFailed extends EventScopeState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The sheet is open. [failure] is why the last move was refused.
class EventScopeEditing extends EventScopeState {
  const new(this.institutions, {this.saving = false, this.failure});

  final List<InstitutionSummary> institutions;
  final bool saving;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [institutions, saving, failure];
}

class EventScopeSaved extends EventScopeState {
  const new(this.event);

  final SchoolEvent event;

  @override
  List<Object?> get props => [event];
}

/// Moves [event] between the whole Society and one Institution (EVT-06, an Owner only).
class EventScopeBloc extends Bloc<EventScopeEvent, EventScopeState> {
  new(this._events, this._institutions, this.event) : super(const EventScopeLoading()) {
    on<EventScopeStarted>(_onStarted);
    on<EventScopeSubmitted>(_onSubmitted);
  }

  final EventsRepository _events;
  final InstitutionsRepository _institutions;
  final SchoolEvent event;

  Future<void> _onStarted(EventScopeStarted _, Emitter<EventScopeState> emit) async {
    emit(const EventScopeLoading());
    try {
      emit(EventScopeEditing(await _institutions.institutions()));
    } on ApiFailure catch (failure) {
      emit(EventScopeLoadFailed(failure));
    }
  }

  Future<void> _onSubmitted(EventScopeSubmitted submitted, Emitter<EventScopeState> emit) async {
    if (state case final EventScopeEditing editing when !editing.saving) {
      final problems = FieldProblems();
      if (submitted.scope == EventScope.institution) problems.requireChoice('institutionId', submitted.institutionId);
      if (problems.failure case final failure?) {
        emit(EventScopeEditing(editing.institutions, failure: failure));
        return;
      }
      emit(EventScopeEditing(editing.institutions, saving: true));
      try {
        emit(
          EventScopeSaved(
            await _events.changeScope(
              event,
              scope: submitted.scope,
              institutionId: submitted.scope == EventScope.institution ? submitted.institutionId : null,
            ),
          ),
        );
      } on ApiFailure catch (failure) {
        emit(EventScopeEditing(editing.institutions, failure: failure));
      }
    }
  }
}
