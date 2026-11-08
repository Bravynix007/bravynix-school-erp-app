import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/storage/institution_choice_store.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:equatable/equatable.dart';

sealed class InstitutionScopeEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after the list could not be read.
final class InstitutionScopeStarted extends InstitutionScopeEvent {
  const new();
}

final class InstitutionScopeChosen extends InstitutionScopeEvent {
  const new(this.institutionId);

  final String institutionId;

  @override
  List<Object?> get props => [institutionId];
}

sealed class InstitutionScopeState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class InstitutionScopeLoading extends InstitutionScopeState {
  const new();
}

class InstitutionScopeFailed extends InstitutionScopeState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The person has no active Institution to work in.
class InstitutionScopeEmpty extends InstitutionScopeState {
  const new();
}

class InstitutionScopeReady extends InstitutionScopeState {
  const new({required this.institutions, required this.selected});

  final List<InstitutionSummary> institutions;
  final InstitutionSummary selected;

  @override
  List<Object?> get props => [institutions, selected];
}

/// Which Institution an Institution-scoped setup screen (academic years, classes) works on: the one the person chose
/// last if they still have it, else the first. The API takes it as `institutionId` (API design 6.5).
class InstitutionScopeBloc extends Bloc<InstitutionScopeEvent, InstitutionScopeState> {
  new(this._institutions, this._choice) : super(const InstitutionScopeLoading()) {
    on<InstitutionScopeStarted>(_onStarted);
    on<InstitutionScopeChosen>(_onChosen);
  }

  final InstitutionsRepository _institutions;
  final InstitutionChoiceStore _choice;

  Future<void> _onStarted(InstitutionScopeStarted event, Emitter<InstitutionScopeState> emit) async {
    emit(const InstitutionScopeLoading());
    try {
      final institutions = await _institutions.institutions();
      if (institutions.isEmpty) {
        emit(const InstitutionScopeEmpty());
        return;
      }
      final remembered = await _choice.read();
      emit(
        InstitutionScopeReady(
          institutions: institutions,
          selected: institutions.firstWhere((item) => item.id == remembered, orElse: () => institutions.first),
        ),
      );
    } on ApiFailure catch (failure) {
      emit(InstitutionScopeFailed(failure));
    }
  }

  Future<void> _onChosen(InstitutionScopeChosen event, Emitter<InstitutionScopeState> emit) async {
    if (state case final InstitutionScopeReady ready) {
      final chosen = ready.institutions.where((item) => item.id == event.institutionId).firstOrNull;
      if (chosen == null || chosen == ready.selected) return;
      emit(InstitutionScopeReady(institutions: ready.institutions, selected: chosen));
      await _choice.write(chosen.id);
    }
  }
}
