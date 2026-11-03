import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:equatable/equatable.dart';

sealed class InstitutionEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after a failure.
final class InstitutionRequested extends InstitutionEvent {
  const new();
}

/// The Owner confirmed Deactivate.
final class InstitutionDeactivateRequested extends InstitutionEvent {
  const new();
}

sealed class InstitutionState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class InstitutionLoading extends InstitutionState {
  const new();
}

/// The Institution, with Deactivate under way or the failure of the last try.
class InstitutionLoaded extends InstitutionState {
  const new(this.institution, {this.deactivating = false, this.deactivateFailure});

  final Institution institution;
  final bool deactivating;
  final ApiFailure? deactivateFailure;

  @override
  List<Object?> get props => [institution, deactivating, deactivateFailure];
}

class InstitutionFailed extends InstitutionState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// INS-05 went through: the screen closes and the list is read again.
class InstitutionDeactivated extends InstitutionState {
  const new();
}

/// One Institution (INS-03), and its deactivation for an Owner (INS-05).
class InstitutionBloc extends Bloc<InstitutionEvent, InstitutionState> {
  new(this._institutions, this.id) : super(const InstitutionLoading()) {
    on<InstitutionRequested>(_onRequested);
    on<InstitutionDeactivateRequested>(_onDeactivate);
  }

  final InstitutionsRepository _institutions;
  final String id;

  Future<void> _onRequested(InstitutionRequested event, Emitter<InstitutionState> emit) async {
    emit(const InstitutionLoading());
    try {
      emit(InstitutionLoaded(await _institutions.institution(id)));
    } on ApiFailure catch (failure) {
      emit(InstitutionFailed(failure));
    }
  }

  Future<void> _onDeactivate(InstitutionDeactivateRequested event, Emitter<InstitutionState> emit) async {
    final current = state;
    if (current is! InstitutionLoaded || current.deactivating) return;
    emit(InstitutionLoaded(current.institution, deactivating: true));
    try {
      await _institutions.deactivate(id);
      emit(const InstitutionDeactivated());
    } on ApiFailure catch (failure) {
      emit(InstitutionLoaded(current.institution, deactivateFailure: failure));
    }
  }
}
