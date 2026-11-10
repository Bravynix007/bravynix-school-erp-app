import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_names.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_profile.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:equatable/equatable.dart';

sealed class StaffProfileEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, Try again after a failure, and coming back from the form that saved.
final class StaffProfileRequested extends StaffProfileEvent {
  const new();
}

sealed class StaffProfileState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StaffProfileLoading extends StaffProfileState {
  const new();
}

class StaffProfileLoaded extends StaffProfileState {
  const new(this.profile);

  final StaffProfile profile;

  @override
  List<Object?> get props => [profile];
}

class StaffProfileFailed extends StaffProfileState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// One staff member's profile (STF-03).
class StaffProfileBloc extends Bloc<StaffProfileEvent, StaffProfileState> {
  new(this._staff, this._masters, this.id) : super(const StaffProfileLoading()) {
    on<StaffProfileRequested>(_onRequested);
  }

  final StaffRepository _staff;
  final MastersRepository _masters;
  final String id;

  Future<void> _onRequested(StaffProfileRequested event, Emitter<StaffProfileState> emit) async {
    emit(const StaffProfileLoading());
    try {
      final member = await _staff.member(id);
      final address = member.address;
      emit(
        StaffProfileLoaded(
          StaffProfile(
            member,
            designationName: await _masters.nameOf(MasterType.designations, member.designationId),
            categoryName: await _masters.nameOf(MasterType.classCategories, member.classCategoryId),
            countryName: await _masters.nameOf(MasterType.countries, address.countryId),
            stateName: await _masters.nameOf(MasterType.states, address.stateId, parentId: address.countryId),
            cityName: address.stateId == null
                ? null
                : await _masters.nameOf(MasterType.cities, address.cityId, parentId: address.stateId),
          ),
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StaffProfileFailed(failure));
    }
  }
}
