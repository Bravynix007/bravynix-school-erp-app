import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:equatable/equatable.dart';

sealed class ClassesEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, Try again after a failure, and coming back from a form that saved.
final class ClassesRequested extends ClassesEvent {
  const new();
}

final class ClassDeactivated extends ClassesEvent {
  const new(this.schoolClass);

  final SchoolClass schoolClass;

  @override
  List<Object?> get props => [schoolClass];
}

sealed class ClassesState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class ClassesLoading extends ClassesState {
  const new();
}

class ClassesFailed extends ClassesState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The classes. [busyId] is the class a deactivation is on its way for; [actionFailure] is why the last one was
/// refused, and [deactivated] is the class the last one went through for.
class ClassesLoaded extends ClassesState {
  const new(this.classes, {this.busyId, this.actionFailure, this.deactivated});

  final List<SchoolClass> classes;
  final String? busyId;
  final ApiFailure? actionFailure;
  final SchoolClass? deactivated;

  @override
  List<Object?> get props => [classes, busyId, actionFailure, deactivated];
}

/// The classes of one Institution (CLS-01) and deactivating one (CLS-05).
class ClassesBloc extends Bloc<ClassesEvent, ClassesState> {
  new(this._classes, this.institutionId) : super(const ClassesLoading()) {
    on<ClassesRequested>(_onRequested);
    on<ClassDeactivated>(_onDeactivated);
  }

  final ClassesRepository _classes;
  final String institutionId;

  Future<void> _onRequested(ClassesRequested event, Emitter<ClassesState> emit) async {
    emit(const ClassesLoading());
    try {
      emit(ClassesLoaded(await _classes.classes(institutionId)));
    } on ApiFailure catch (failure) {
      emit(ClassesFailed(failure));
    }
  }

  /// Deactivates, then reads the classes again: a refusal such as 404 means the list on screen is out of date.
  Future<void> _onDeactivated(ClassDeactivated event, Emitter<ClassesState> emit) async {
    if (state case final ClassesLoaded loaded when loaded.busyId == null) {
      emit(ClassesLoaded(loaded.classes, busyId: event.schoolClass.id));
      ApiFailure? refused;
      try {
        await _classes.deactivate(event.schoolClass.id);
      } on ApiFailure catch (failure) {
        refused = failure;
      }
      try {
        emit(
          ClassesLoaded(
            await _classes.classes(institutionId),
            actionFailure: refused,
            deactivated: refused == null ? event.schoolClass : null,
          ),
        );
      } on ApiFailure catch (failure) {
        emit(ClassesFailed(failure));
      }
    }
  }
}
