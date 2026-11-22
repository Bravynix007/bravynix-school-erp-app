import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_calendar.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:equatable/equatable.dart';

sealed class AttendanceCalendarEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen on the month of today.
final class AttendanceCalendarStarted extends AttendanceCalendarEvent {
  const new();
}

/// Another month; [month] is its first day.
final class AttendanceCalendarMonthChosen extends AttendanceCalendarEvent {
  const new(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

/// Try again after the month could not be read.
final class AttendanceCalendarRetried extends AttendanceCalendarEvent {
  const new();
}

/// A month of one student; [month] is its first day, so the stepper always has a month to step from.
sealed class AttendanceCalendarState extends Equatable {
  const new(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

class AttendanceCalendarLoading extends AttendanceCalendarState {
  const new(super.month);
}

class AttendanceCalendarFailed extends AttendanceCalendarState {
  const new(super.month, this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [month, failure];
}

class AttendanceCalendarReady extends AttendanceCalendarState {
  const new(super.month, this.calendar);

  final AttendanceCalendar calendar;

  @override
  List<Object?> get props => [month, calendar];
}

/// ATT-07 for one student, a month at a time.
class AttendanceCalendarBloc extends Bloc<AttendanceCalendarEvent, AttendanceCalendarState> {
  new(this._attendance, this.studentId, {DateTime Function() clock = DateTime.now})
    : super(AttendanceCalendarLoading(_firstOfMonth(clock()))) {
    on<AttendanceCalendarStarted>((event, emit) => _read(state.month, emit));
    on<AttendanceCalendarMonthChosen>((event, emit) => _read(_monthOf(event.month), emit));
    on<AttendanceCalendarRetried>((event, emit) => _read(state.month, emit));
  }

  final AttendanceRepository _attendance;
  final String studentId;

  /// Counts the reads, so the answer of one that a later month or Try again overtook is dropped.
  int _reading = 0;

  /// The first day of the month [instant] falls in, in IST like every school day.
  static DateTime _firstOfMonth(DateTime instant) {
    final today = Formatters.parseDay(Formatters.schoolDay(instant))!;
    return DateTime(today.year, today.month);
  }

  static DateTime _monthOf(DateTime day) => DateTime(day.year, day.month);

  Future<void> _read(DateTime month, Emitter<AttendanceCalendarState> emit) async {
    final token = ++_reading;
    emit(AttendanceCalendarLoading(month));
    try {
      final calendar = await _attendance.calendar(studentId, Formatters.isoMonth(month));
      if (token == _reading) emit(AttendanceCalendarReady(month, calendar));
    } on ApiFailure catch (failure) {
      if (token == _reading) emit(AttendanceCalendarFailed(month, failure));
    }
  }
}
