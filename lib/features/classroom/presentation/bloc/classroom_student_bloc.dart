import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classroom/domain/classroom.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:equatable/equatable.dart';

sealed class ClassroomStudentEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after a failure.
final class ClassroomStudentRequested extends ClassroomStudentEvent {
  const new();
}

sealed class ClassroomStudentState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class ClassroomStudentLoading extends ClassroomStudentState {
  const new();
}

class ClassroomStudentLoaded extends ClassroomStudentState {
  const new(this.entry);

  final ClassroomEntry entry;

  @override
  List<Object?> get props => [entry];
}

class ClassroomStudentFailed extends ClassroomStudentState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// One student of the teacher's own sections (STU-03), with the name of the section they sit in.
class ClassroomStudentBloc extends Bloc<ClassroomStudentEvent, ClassroomStudentState> {
  new(this._classroom, this._options, this.id) : super(const ClassroomStudentLoading()) {
    on<ClassroomStudentRequested>(_onRequested);
  }

  final ClassroomRepository _classroom;
  final SectionOptionsSource _options;
  final String id;

  Future<void> _onRequested(ClassroomStudentRequested event, Emitter<ClassroomStudentState> emit) async {
    emit(const ClassroomStudentLoading());
    try {
      final student = await _classroom.student(id);
      final options = await _options.read(student.institutionId);
      final place = options.sections.where((section) => section.id == student.placement.sectionId).firstOrNull;
      emit(ClassroomStudentLoaded(ClassroomEntry(student, placeName: place?.name)));
    } on ApiFailure catch (failure) {
      emit(ClassroomStudentFailed(failure));
    }
  }
}
