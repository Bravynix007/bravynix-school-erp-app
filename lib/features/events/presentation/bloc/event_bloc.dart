import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:equatable/equatable.dart';

sealed class EventEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after a failure.
final class EventRequested extends EventEvent {
  const new();
}

/// Delete the event (EVT-05).
final class EventRemoved extends EventEvent {
  const new();
}

sealed class EventState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class EventLoading extends EventState {
  const new();
}

class EventFailed extends EventState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The event. [removing] is the delete on its way; [failure] is why the last one was refused.
class EventLoaded extends EventState {
  const new(this.event, {this.removing = false, this.failure});

  final SchoolEvent event;
  final bool removing;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [event, removing, failure];
}

/// The event was deleted.
class EventGone extends EventState {
  const new();
}

/// One event or holiday (EVT-03, and EVT-05 to delete it). It is opened from the list or from a notice, so it is read by
/// its ID; a parent reads it for [studentId].
class EventBloc extends Bloc<EventEvent, EventState> {
  new(this._events, this.id, {this.studentId}) : super(const EventLoading()) {
    on<EventRequested>(_onRequested);
    on<EventRemoved>(_onRemoved);
  }

  final EventsRepository _events;
  final String id;
  final String? studentId;

  Future<void> _onRequested(EventRequested event, Emitter<EventState> emit) async {
    emit(const EventLoading());
    try {
      emit(EventLoaded(await _events.event(id, studentId: studentId)));
    } on ApiFailure catch (failure) {
      emit(EventFailed(failure));
    }
  }

  Future<void> _onRemoved(EventRemoved event, Emitter<EventState> emit) async {
    if (state case final EventLoaded loaded when !loaded.removing) {
      emit(EventLoaded(loaded.event, removing: true));
      try {
        await _events.remove(id);
        emit(const EventGone());
      } on ApiFailure catch (failure) {
        // An event already removed is gone from the person's lists too, which the screen says.
        emit(failure.code == 'NOT_FOUND' ? EventFailed(failure) : EventLoaded(loaded.event, failure: failure));
      }
    }
  }
}
