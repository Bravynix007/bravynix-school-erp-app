import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:equatable/equatable.dart';

sealed class StudentFiltersEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the filters, and Try again after the options could not be read.
final class StudentFiltersStarted extends StudentFiltersEvent {
  const new();
}

/// A year was chosen, or null for any year.
final class StudentFiltersYearChosen extends StudentFiltersEvent {
  const new(this.yearId);

  final String? yearId;

  @override
  List<Object?> get props => [yearId];
}

/// A class was chosen, or null for any; a section of another class is let go.
final class StudentFiltersClassChosen extends StudentFiltersEvent {
  const new(this.classId);

  final String? classId;

  @override
  List<Object?> get props => [classId];
}

/// A section was chosen, or null for any.
final class StudentFiltersSectionChosen extends StudentFiltersEvent {
  const new(this.sectionId);

  final String? sectionId;

  @override
  List<Object?> get props => [sectionId];
}

/// Clear filters.
final class StudentFiltersCleared extends StudentFiltersEvent {
  const new();
}

sealed class StudentFiltersState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

final class StudentFiltersLoading extends StudentFiltersState {
  const new();
}

final class StudentFiltersFailed extends StudentFiltersState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The years, classes and sections to choose from, and what is chosen.
final class StudentFiltersReady extends StudentFiltersState {
  const new(this.options, {this.filter = const StudentFilter()});

  final SectionOptions options;
  final StudentFilter filter;

  /// The sections of the chosen class, or all of them when none is chosen.
  List<SectionChoice> get sections => [
    for (final section in options.sections)
      if (filter.classId == null || section.classId == filter.classId) section,
  ];

  @override
  List<Object?> get props => [options, filter];
}

/// The year, class and section the students list is narrowed to. The screen passes the chosen filter on to the list.
class StudentFiltersBloc extends Bloc<StudentFiltersEvent, StudentFiltersState> {
  new(this._options, this._institutionId) : super(const StudentFiltersLoading()) {
    on<StudentFiltersStarted>(_onStarted);
    on<StudentFiltersYearChosen>(
      (event, emit) => _ready(
        (ready) => emit(
          StudentFiltersReady(
            ready.options,
            filter: StudentFilter(
              academicYearId: event.yearId,
              classId: ready.filter.classId,
              sectionId: ready.filter.sectionId,
            ),
          ),
        ),
      ),
    );
    on<StudentFiltersClassChosen>(
      (event, emit) => _ready(
        (ready) => emit(
          StudentFiltersReady(
            ready.options,
            filter: StudentFilter(
              academicYearId: ready.filter.academicYearId,
              classId: event.classId,
              // A section of another class does not belong to the class chosen.
              sectionId:
                  ready.options.sections.any(
                    (section) => section.id == ready.filter.sectionId && section.classId == event.classId,
                  )
                  ? ready.filter.sectionId
                  : null,
            ),
          ),
        ),
      ),
    );
    on<StudentFiltersSectionChosen>(
      (event, emit) => _ready((ready) {
        // Choosing a section also says its class, so the two pills never disagree.
        final classId = ready.options.sections
            .where((section) => section.id == event.sectionId)
            .map((section) => section.classId)
            .firstOrNull;
        emit(
          StudentFiltersReady(
            ready.options,
            filter: StudentFilter(
              academicYearId: ready.filter.academicYearId,
              classId: classId ?? ready.filter.classId,
              sectionId: event.sectionId,
            ),
          ),
        );
      }),
    );
    on<StudentFiltersCleared>((event, emit) => _ready((ready) => emit(StudentFiltersReady(ready.options))));
  }

  final SectionOptionsSource _options;
  final String _institutionId;

  void _ready(void Function(StudentFiltersReady ready) work) {
    if (state case final StudentFiltersReady ready) work(ready);
  }

  Future<void> _onStarted(StudentFiltersStarted event, Emitter<StudentFiltersState> emit) async {
    emit(const StudentFiltersLoading());
    try {
      emit(StudentFiltersReady(await _options.read(_institutionId)));
    } on ApiFailure catch (failure) {
      emit(StudentFiltersFailed(failure));
    }
  }
}
