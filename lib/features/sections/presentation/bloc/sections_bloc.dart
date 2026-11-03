import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:equatable/equatable.dart';

sealed class SectionsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, Try again after a failure, and coming back from a form that saved.
final class SectionsRequested extends SectionsEvent {
  const new();
}

final class SectionDeactivated extends SectionsEvent {
  const new(this.section);

  final Section section;

  @override
  List<Object?> get props => [section];
}

sealed class SectionsState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class SectionsLoading extends SectionsState {
  const new();
}

class SectionsFailed extends SectionsState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The sections. [busyId] is the section a deactivation is on its way for; [actionFailure] is why the last one was
/// refused, and [deactivated] is the section the last one went through for.
class SectionsLoaded extends SectionsState {
  const new(this.sections, {this.busyId, this.actionFailure, this.deactivated});

  final List<Section> sections;
  final String? busyId;
  final ApiFailure? actionFailure;
  final Section? deactivated;

  @override
  List<Object?> get props => [sections, busyId, actionFailure, deactivated];
}

/// The sections of one class (SEC-01) and deactivating one (SEC-04).
class SectionsBloc extends Bloc<SectionsEvent, SectionsState> {
  new(this._sections, this.classId) : super(const SectionsLoading()) {
    on<SectionsRequested>(_onRequested);
    on<SectionDeactivated>(_onDeactivated);
  }

  final SectionsRepository _sections;
  final String classId;

  Future<void> _onRequested(SectionsRequested event, Emitter<SectionsState> emit) async {
    emit(const SectionsLoading());
    try {
      emit(SectionsLoaded(await _sections.sections(classId)));
    } on ApiFailure catch (failure) {
      emit(SectionsFailed(failure));
    }
  }

  /// Deactivates, then reads the sections again: a refusal such as 404 means the list on screen is out of date.
  Future<void> _onDeactivated(SectionDeactivated event, Emitter<SectionsState> emit) async {
    if (state case final SectionsLoaded loaded when loaded.busyId == null) {
      emit(SectionsLoaded(loaded.sections, busyId: event.section.id));
      ApiFailure? refused;
      try {
        await _sections.deactivate(event.section.id);
      } on ApiFailure catch (failure) {
        refused = failure;
      }
      try {
        emit(
          SectionsLoaded(
            await _sections.sections(classId),
            actionFailure: refused,
            deactivated: refused == null ? event.section : null,
          ),
        );
      } on ApiFailure catch (failure) {
        emit(SectionsFailed(failure));
      }
    }
  }
}
