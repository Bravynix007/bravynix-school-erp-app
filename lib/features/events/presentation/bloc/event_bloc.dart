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

class EventLoaded extends EventState {
  const new(this.event);

  final SchoolEvent event;

  @override
  List<Object?> get props => [event];
}

/// One event or holiday (EVT-03). It is opened from the list or from a notice, so it is read by its ID; a parent reads
/// it for [studentId].
class EventBloc extends Bloc<EventEvent, EventState> {
  new(this._events, this.id, {this.studentId}) : super(const EventLoading()) {
    on<EventRequested>(_onRequested);
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
}
