import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:equatable/equatable.dart';

/// What the form holds: the name as typed and the two school days chosen (`YYYY-MM-DD`, empty until chosen).
class AcademicYearFields extends Equatable {
  const new({required this.name, required this.startDate, required this.endDate});

  final String name;
  final String startDate;
  final String endDate;

  @override
  List<Object?> get props => [name, startDate, endDate];
}

sealed class AcademicYearFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

final class AcademicYearFormSubmitted extends AcademicYearFormEvent {
  const new(this.fields);

  final AcademicYearFields fields;

  @override
  List<Object?> get props => [fields];
}

sealed class AcademicYearFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The form is open. [failure] is why the last save was refused.
class AcademicYearFormEditing extends AcademicYearFormState {
  const new({this.saving = false, this.failure});

  final bool saving;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [saving, failure];
}

class AcademicYearFormSaved extends AcademicYearFormState {
  const new(this.year);

  final AcademicYear year;

  @override
  List<Object?> get props => [year];
}

/// Adds a year (AY-02) to [institutionId], or, with [existing], changes that year (AY-03).
class AcademicYearFormBloc extends Bloc<AcademicYearFormEvent, AcademicYearFormState> {
  new(this._years, this.institutionId, {this.existing}) : super(const AcademicYearFormEditing()) {
    on<AcademicYearFormSubmitted>(_onSubmitted);
  }

  final AcademicYearsRepository _years;
  final String institutionId;
  final AcademicYear? existing;

  Future<void> _onSubmitted(AcademicYearFormSubmitted event, Emitter<AcademicYearFormState> emit) async {
    if (state case final AcademicYearFormEditing editing when !editing.saving) {
      emit(const AcademicYearFormEditing(saving: true));
      final name = event.fields.name.trim();
      try {
        emit(
          AcademicYearFormSaved(
            existing == null
                ? await _years.create(
                    institutionId,
                    name: name,
                    startDate: event.fields.startDate,
                    endDate: event.fields.endDate,
                  )
                : await _years.update(
                    existing!,
                    name: name,
                    startDate: event.fields.startDate,
                    endDate: event.fields.endDate,
                  ),
          ),
        );
      } on ApiFailure catch (failure) {
        emit(AcademicYearFormEditing(failure: failure));
      }
    }
  }
}
