import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/section_options.dart';
import 'package:equatable/equatable.dart';

sealed class StaffClassTeacherEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the section, and Try again after a failure.
final class StaffClassTeacherStarted extends StaffClassTeacherEvent {
  const new();
}

/// Another academic year: the section shown is the one they lead in it.
final class StaffClassTeacherYearChosen extends StaffClassTeacherEvent {
  const new(this.yearId);

  final String yearId;

  @override
  List<Object?> get props => [yearId];
}

/// A section to lead in the year, or null for none.
final class StaffClassTeacherSectionChosen extends StaffClassTeacherEvent {
  const new(this.sectionId);

  final String? sectionId;

  @override
  List<Object?> get props => [sectionId];
}

final class StaffClassTeacherSaved extends StaffClassTeacherEvent {
  const new();
}

sealed class StaffClassTeacherState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StaffClassTeacherLoading extends StaffClassTeacherState {
  const new();
}

class StaffClassTeacherFailed extends StaffClassTeacherState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The academic years and sections to choose from, the section they lead in each year ([assigned], by year), and what
/// is chosen now for the [yearId], which may differ from what is assigned until it is saved.
class StaffClassTeacherReady extends StaffClassTeacherState {
  const new({
    required this.years,
    required this.sections,
    required this.assigned,
    required this.yearId,
    required this.sectionId,
    this.saving = false,
    this.failure,
  });

  final List<AcademicYear> years;
  final List<SectionChoice> sections;

  /// The section they lead in each year, by the ID of the year.
  final Map<String, String> assigned;

  /// The year being looked at; null when the Institution has none.
  final String? yearId;

  /// The section chosen for the year; null for none.
  final String? sectionId;
  final bool saving;

  /// The last save that was refused.
  final ApiFailure? failure;

  bool get changed => yearId != null && sectionId != assigned[yearId];

  StaffClassTeacherReady copyWith({
    Map<String, String>? assigned,
    String? Function()? yearId,
    String? Function()? sectionId,
    bool? saving,
    ApiFailure? Function()? failure,
  }) => StaffClassTeacherReady(
    years: years,
    sections: sections,
    assigned: assigned ?? this.assigned,
    yearId: yearId == null ? this.yearId : yearId(),
    sectionId: sectionId == null ? this.sectionId : sectionId(),
    saving: saving ?? this.saving,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [years, sections, assigned, yearId, sectionId, saving, failure];
}

/// The section a staff member leads as class teacher, for each academic year of their home Institution (STF-09). The
/// section of a year is chosen from the sections of the Institution, and saved on its own.
class StaffClassTeacherBloc extends Bloc<StaffClassTeacherEvent, StaffClassTeacherState> {
  new(this._staff, this._options, {required this.member}) : super(const StaffClassTeacherLoading()) {
    on<StaffClassTeacherStarted>(_onStarted);
    on<StaffClassTeacherYearChosen>(
      (event, emit) => _ready((ready) {
        if (ready.saving) return;
        emit(
          ready.copyWith(
            yearId: () => event.yearId,
            sectionId: () => ready.assigned[event.yearId],
            failure: () => null,
          ),
        );
      }),
    );
    on<StaffClassTeacherSectionChosen>(
      (event, emit) => _ready((ready) {
        if (ready.saving) return;
        emit(ready.copyWith(sectionId: () => event.sectionId, failure: () => null));
      }),
    );
    on<StaffClassTeacherSaved>(_onSaved);
  }

  final StaffRepository _staff;
  final SectionOptionsSource _options;

  /// The staff member as the section was opened.
  final StaffMember member;

  void _ready(void Function(StaffClassTeacherReady ready) work) {
    if (state case final StaffClassTeacherReady ready) work(ready);
  }

  Future<void> _onStarted(StaffClassTeacherStarted event, Emitter<StaffClassTeacherState> emit) async {
    emit(const StaffClassTeacherLoading());
    try {
      final options = await _options.read(member.homeInstitutionId);
      final assigned = {for (final item in member.classTeachers) item.academicYearId: item.sectionId};
      final yearId = options.firstYearId;
      emit(
        StaffClassTeacherReady(
          years: options.years,
          sections: options.sections,
          assigned: assigned,
          yearId: yearId,
          sectionId: assigned[yearId],
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StaffClassTeacherFailed(failure));
    }
  }

  Future<void> _onSaved(StaffClassTeacherSaved event, Emitter<StaffClassTeacherState> emit) async {
    if (state case final StaffClassTeacherReady ready when !ready.saving && ready.changed) {
      final yearId = ready.yearId!;
      emit(ready.copyWith(saving: true, failure: () => null));
      try {
        final saved = await _staff.setClassTeacher(member.id, academicYearId: yearId, sectionId: ready.sectionId);
        _ready(
          (now) => emit(
            now.copyWith(
              assigned: {
                for (final entry in now.assigned.entries)
                  if (entry.key != yearId) entry.key: entry.value,
                if (saved != null) yearId: saved.sectionId,
              },
              saving: false,
            ),
          ),
        );
      } on ApiFailure catch (failure) {
        _ready((now) => emit(now.copyWith(saving: false, failure: () => failure)));
      }
    }
  }
}
