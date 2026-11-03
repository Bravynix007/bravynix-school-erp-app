import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';

final class AcademicYearMadeCurrent extends ListEvent {
  const new(this.year);

  final AcademicYear year;

  @override
  List<Object?> get props => [year];
}

final class AcademicYearDeactivated extends ListEvent {
  const new(this.year);

  final AcademicYear year;

  @override
  List<Object?> get props => [year];
}

/// What a change that went through did, for the message the screen says.
enum AcademicYearsNotice { madeCurrent, deactivated }

/// The academic years of one Institution (AY-01), with making one current (AY-04) and deactivating one (AY-05). A change
/// moves the current mark, so the years are read again after it.
class AcademicYearsBloc extends ListBloc<AcademicYear> {
  new(this._years, this.institutionId) {
    on<AcademicYearMadeCurrent>(
      (event, emit) => change(
        emit,
        event.year,
        event.year.id,
        () => _years.makeCurrent(event.year),
        notice: AcademicYearsNotice.madeCurrent,
      ),
    );
    on<AcademicYearDeactivated>(
      (event, emit) => change(
        emit,
        event.year,
        event.year.id,
        () => _years.deactivate(event.year.id),
        notice: AcademicYearsNotice.deactivated,
      ),
    );
  }

  final AcademicYearsRepository _years;
  final String institutionId;

  @override
  Future<List<AcademicYear>> read() => _years.years(institutionId);
}
