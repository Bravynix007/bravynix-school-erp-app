import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:equatable/equatable.dart';

sealed class EventsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after a failure.
final class EventsRequested extends EventsEvent {
  const new();
}

/// The month stepper moved: [month] is its first day.
final class EventsMonthChosen extends EventsEvent {
  const new(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

/// The holidays filter was switched on or off.
final class EventsHolidaysOnlyChosen extends EventsEvent {
  const new({required this.holidaysOnly});

  final bool holidaysOnly;

  @override
  List<Object?> get props => [holidaysOnly];
}

sealed class EventsState extends Equatable {
  const new(this.month, {required this.holidaysOnly});

  /// The first day of the month shown.
  final DateTime month;
  final bool holidaysOnly;

  @override
  List<Object?> get props => [month, holidaysOnly];
}

class EventsLoading extends EventsState {
  const new(super.month, {required super.holidaysOnly});
}

class EventsFailed extends EventsState {
  const new(super.month, this.failure, {required super.holidaysOnly});

  final ApiFailure failure;

  @override
  List<Object?> get props => [month, holidaysOnly, failure];
}

class EventsLoaded extends EventsState {
  const new(super.month, this.events, {required super.holidaysOnly});

  final List<SchoolEvent> events;

  @override
  List<Object?> get props => [month, holidaysOnly, events];
}

/// The events and holidays of one month (EVT-01), earliest first, all of them or only the holidays. A parent's list
/// is the child's ([studentId]).
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  new(this._events, {required DateTime today, this.studentId})
    : super(EventsLoading(DateTime(today.year, today.month), holidaysOnly: false)) {
    on<EventsRequested>((event, emit) => _read(emit, state.month, holidaysOnly: state.holidaysOnly));
    on<EventsMonthChosen>(
      (event, emit) => _read(emit, DateTime(event.month.year, event.month.month), holidaysOnly: state.holidaysOnly),
    );
    on<EventsHolidaysOnlyChosen>((event, emit) => _read(emit, state.month, holidaysOnly: event.holidaysOnly));
  }

  final EventsRepository _events;
  final String? studentId;

  /// Counts the times the list was asked for, so the answer to an earlier ask can tell it is out of date.
  int _round = 0;

  Future<void> _read(Emitter<EventsState> emit, DateTime month, {required bool holidaysOnly}) async {
    final round = ++_round;
    emit(EventsLoading(month, holidaysOnly: holidaysOnly));
    try {
      final events = await _events.events(
        from: month,
        to: DateTime(month.year, month.month + 1, 0),
        holidaysOnly: holidaysOnly,
        studentId: studentId,
      );
      if (round == _round) emit(EventsLoaded(month, events, holidaysOnly: holidaysOnly));
    } on ApiFailure catch (failure) {
      if (round == _round) emit(EventsFailed(month, failure, holidaysOnly: holidaysOnly));
    }
  }
}
