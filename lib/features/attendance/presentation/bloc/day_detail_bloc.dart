import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_calendar.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:equatable/equatable.dart';

sealed class DayDetailEvent {
  const new();
}

/// Reading the day, and Try again after it could not be read.
final class DayDetailRequested extends DayDetailEvent {
  const new();
}

sealed class DayDetailState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class DayDetailLoading extends DayDetailState {
  const new();
}

class DayDetailFailed extends DayDetailState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

class DayDetailLoaded extends DayDetailState {
  const new(this.detail);

  final DayDetail detail;

  @override
  List<Object?> get props => [detail];
}

/// ATT-08: one day of one student, for the sheet a day of the calendar opens.
class DayDetailBloc extends Bloc<DayDetailEvent, DayDetailState> {
  new(this._attendance, this.studentId, this.day) : super(const DayDetailLoading()) {
    on<DayDetailRequested>(_onRequested);
  }

  final AttendanceRepository _attendance;
  final String studentId;

  /// `YYYY-MM-DD`.
  final String day;

  Future<void> _onRequested(DayDetailRequested event, Emitter<DayDetailState> emit) async {
    emit(const DayDetailLoading());
    try {
      emit(DayDetailLoaded(await _attendance.dayDetail(studentId, day)));
    } on ApiFailure catch (failure) {
      emit(DayDetailFailed(failure));
    }
  }
}
