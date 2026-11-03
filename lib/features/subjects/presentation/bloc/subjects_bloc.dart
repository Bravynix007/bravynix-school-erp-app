import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:equatable/equatable.dart';

sealed class SubjectsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, Try again after a failure, and coming back from the form with a saved subject.
final class SubjectsRequested extends SubjectsEvent {
  const new();
}

final class SubjectDeactivated extends SubjectsEvent {
  const new(this.subject);

  final Subject subject;

  @override
  List<Object?> get props => [subject];
}

sealed class SubjectsState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class SubjectsLoading extends SubjectsState {
  const new();
}

class SubjectsFailed extends SubjectsState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The subjects. [busyId] is the subject a deactivation is on its way for; [actionFailure] is why the last one was
/// refused, and [deactivated] is the subject the last one went through for.
class SubjectsLoaded extends SubjectsState {
  const new(this.subjects, {this.busyId, this.actionFailure, this.deactivated});

  final List<Subject> subjects;
  final String? busyId;
  final ApiFailure? actionFailure;
  final Subject? deactivated;

  @override
  List<Object?> get props => [subjects, busyId, actionFailure, deactivated];
}

/// The Society's subjects (SUB-01) and deactivating one (SUB-04).
class SubjectsBloc extends Bloc<SubjectsEvent, SubjectsState> {
  new(this._subjects) : super(const SubjectsLoading()) {
    on<SubjectsRequested>(_onRequested);
    on<SubjectDeactivated>(_onDeactivated);
  }

  final SubjectsRepository _subjects;

  Future<void> _onRequested(SubjectsRequested event, Emitter<SubjectsState> emit) async {
    emit(const SubjectsLoading());
    try {
      emit(SubjectsLoaded(await _subjects.subjects()));
    } on ApiFailure catch (failure) {
      emit(SubjectsFailed(failure));
    }
  }

  /// Deactivates, then reads the subjects again: a refusal such as 404 means the list on screen is out of date.
  Future<void> _onDeactivated(SubjectDeactivated event, Emitter<SubjectsState> emit) async {
    if (state case final SubjectsLoaded loaded when loaded.busyId == null) {
      emit(SubjectsLoaded(loaded.subjects, busyId: event.subject.id));
      ApiFailure? refused;
      try {
        await _subjects.deactivate(event.subject.id);
      } on ApiFailure catch (failure) {
        refused = failure;
      }
      try {
        emit(
          SubjectsLoaded(
            await _subjects.subjects(),
            actionFailure: refused,
            deactivated: refused == null ? event.subject : null,
          ),
        );
      } on ApiFailure catch (failure) {
        emit(SubjectsFailed(failure));
      }
    }
  }
}
