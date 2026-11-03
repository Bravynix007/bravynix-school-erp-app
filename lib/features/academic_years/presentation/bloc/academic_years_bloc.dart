import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:equatable/equatable.dart';

sealed class AcademicYearsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, Try again after a failure, and coming back from the form with a saved year.
final class AcademicYearsRequested extends AcademicYearsEvent {
  const new();
}

final class AcademicYearMadeCurrent extends AcademicYearsEvent {
  const new(this.year);

  final AcademicYear year;

  @override
  List<Object?> get props => [year];
}

final class AcademicYearDeactivated extends AcademicYearsEvent {
  const new(this.year);

  final AcademicYear year;

  @override
  List<Object?> get props => [year];
}

sealed class AcademicYearsState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class AcademicYearsLoading extends AcademicYearsState {
  const new();
}

class AcademicYearsFailed extends AcademicYearsState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// What a change that went through did, for the message the screen says.
enum AcademicYearsNotice { madeCurrent, deactivated }

/// The years of the Institution. [busyId] is the year a change is on its way for; [actionFailure] is why the last
/// change was refused, and [notice] says what the last one did.
class AcademicYearsLoaded extends AcademicYearsState {
  const new(this.years, {this.busyId, this.actionFailure, this.notice, this.noticeYear});

  final List<AcademicYear> years;
  final String? busyId;
  final ApiFailure? actionFailure;
  final AcademicYearsNotice? notice;

  /// The year the [notice] is about.
  final AcademicYear? noticeYear;

  @override
  List<Object?> get props => [years, busyId, actionFailure, notice, noticeYear];
}

/// The academic years of one Institution (AY-01), with making one current (AY-04) and deactivating one (AY-05).
class AcademicYearsBloc extends Bloc<AcademicYearsEvent, AcademicYearsState> {
  new(this._years, this.institutionId) : super(const AcademicYearsLoading()) {
    on<AcademicYearsRequested>(_onRequested);
    on<AcademicYearMadeCurrent>(
      (event, emit) => _change(emit, event.year, AcademicYearsNotice.madeCurrent, () => _years.makeCurrent(event.year)),
    );
    on<AcademicYearDeactivated>(
      (event, emit) =>
          _change(emit, event.year, AcademicYearsNotice.deactivated, () => _years.deactivate(event.year.id)),
    );
  }

  final AcademicYearsRepository _years;
  final String institutionId;

  Future<void> _onRequested(AcademicYearsRequested event, Emitter<AcademicYearsState> emit) async {
    emit(const AcademicYearsLoading());
    try {
      emit(AcademicYearsLoaded(await _years.years(institutionId)));
    } on ApiFailure catch (failure) {
      emit(AcademicYearsFailed(failure));
    }
  }

  /// Runs [change] for [year], then reads the years again: a change moves the current mark, and a refusal such as
  /// VERSION_CONFLICT means the list on screen is out of date.
  Future<void> _change(
    Emitter<AcademicYearsState> emit,
    AcademicYear year,
    AcademicYearsNotice notice,
    Future<Object?> Function() change,
  ) async {
    if (state case final AcademicYearsLoaded loaded when loaded.busyId == null) {
      emit(AcademicYearsLoaded(loaded.years, busyId: year.id));
      ApiFailure? refused;
      try {
        await change();
      } on ApiFailure catch (failure) {
        refused = failure;
      }
      try {
        emit(
          AcademicYearsLoaded(
            await _years.years(institutionId),
            actionFailure: refused,
            notice: refused == null ? notice : null,
            noticeYear: refused == null ? year : null,
          ),
        );
      } on ApiFailure catch (failure) {
        emit(AcademicYearsFailed(failure));
      }
    }
  }
}
