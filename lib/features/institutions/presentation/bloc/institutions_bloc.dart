import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:equatable/equatable.dart';

sealed class InstitutionsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, Try again after a failure, and coming back from an Institution that was changed.
final class InstitutionsRequested extends InstitutionsEvent {
  const new();
}

sealed class InstitutionsState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class InstitutionsLoading extends InstitutionsState {
  const new();
}

class InstitutionsLoaded extends InstitutionsState {
  const new(this.institutions);

  final List<InstitutionSummary> institutions;

  @override
  List<Object?> get props => [institutions];
}

class InstitutionsFailed extends InstitutionsState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The Institutions the signed-in Owner or Institution Admin can work in (INS-01).
class InstitutionsBloc extends Bloc<InstitutionsEvent, InstitutionsState> {
  new(this._institutions) : super(const InstitutionsLoading()) {
    on<InstitutionsRequested>(_onRequested);
  }

  final InstitutionsRepository _institutions;

  Future<void> _onRequested(InstitutionsRequested event, Emitter<InstitutionsState> emit) async {
    emit(const InstitutionsLoading());
    try {
      emit(InstitutionsLoaded(await _institutions.institutions()));
    } on ApiFailure catch (failure) {
      emit(InstitutionsFailed(failure));
    }
  }
}
