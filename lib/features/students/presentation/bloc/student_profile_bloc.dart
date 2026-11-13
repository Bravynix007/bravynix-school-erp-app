import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_names.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:equatable/equatable.dart';

sealed class StudentProfileEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after a failure.
final class StudentProfileRequested extends StudentProfileEvent {
  const new();
}

sealed class StudentProfileState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StudentProfileLoading extends StudentProfileState {
  const new();
}

class StudentProfileLoaded extends StudentProfileState {
  const new(this.profile);

  final StudentProfile profile;

  @override
  List<Object?> get props => [profile];
}

class StudentProfileFailed extends StudentProfileState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// One student's profile (STU-03), with the names of the class, section and places the record holds the IDs of.
class StudentProfileBloc extends Bloc<StudentProfileEvent, StudentProfileState> {
  new(this._students, this._masters, this._classes, this._sections, this.id) : super(const StudentProfileLoading()) {
    on<StudentProfileRequested>(_onRequested);
  }

  final StudentsRepository _students;
  final MastersRepository _masters;
  final ClassesRepository _classes;
  final SectionsRepository _sections;
  final String id;

  Future<void> _onRequested(StudentProfileRequested event, Emitter<StudentProfileState> emit) async {
    emit(const StudentProfileLoading());
    try {
      final record = await _students.student(id);
      final address = record.address;
      emit(
        StudentProfileLoaded(
          StudentProfile(
            record,
            placeName: await _placeName(record),
            countryName: await _masters.nameOf(MasterType.countries, address.countryId),
            stateName: await _masters.nameOf(MasterType.states, address.stateId, parentId: address.countryId),
            cityName: address.stateId == null
                ? null
                : await _masters.nameOf(MasterType.cities, address.cityId, parentId: address.stateId),
          ),
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StudentProfileFailed(failure));
    }
  }

  /// "Class 5 · A", or the class alone when its section is no longer offered; null without a placement or a class.
  Future<String?> _placeName(StudentRecord record) async {
    final classId = record.placement?.classId;
    if (classId == null) return null;
    final classes = await _classes.classes(record.institutionId);
    final schoolClass = classes.where((candidate) => candidate.id == classId).firstOrNull;
    if (schoolClass == null) return null;
    final sections = await _sections.sections(classId);
    final section = sections.where((candidate) => candidate.id == record.placement!.sectionId).firstOrNull;
    return [schoolClass.displayName, ?section?.displayName].join(' · ');
  }
}
