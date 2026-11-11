import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:equatable/equatable.dart';

sealed class StaffIdentityEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Set the Aadhaar number, as typed.
final class StaffAadhaarSaved extends StaffIdentityEvent {
  const new(this.aadhaar);

  final String aadhaar;

  @override
  List<Object?> get props => [aadhaar];
}

final class StaffAadhaarCleared extends StaffIdentityEvent {
  const new();
}

/// Show the whole number, for a reason that is kept in the audit.
final class StaffAadhaarRevealed extends StaffIdentityEvent {
  const new(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// The sheet that showed the number, or a refusal, is closed: forget both.
final class StaffIdentityHidden extends StaffIdentityEvent {
  const new();
}

/// What the person asked for.
enum StaffIdentityAction { save, clear, reveal }

sealed class StaffIdentityState extends Equatable {
  const new(this.masked);

  /// The Aadhaar number with all but the last four digits hidden; null when none is set.
  final String? masked;

  @override
  List<Object?> get props => [masked];
}

class StaffIdentityIdle extends StaffIdentityState {
  const new(super.masked);
}

class StaffIdentityWorking extends StaffIdentityState {
  const new(super.masked, this.action);

  final StaffIdentityAction action;

  @override
  List<Object?> get props => [masked, action];
}

class StaffIdentityRefused extends StaffIdentityState {
  const new(super.masked, this.action, this.failure);

  final StaffIdentityAction action;
  final ApiFailure failure;

  @override
  List<Object?> get props => [masked, action, failure];
}

/// The whole number, for as long as the sheet that shows it is open.
class StaffIdentityRevealed extends StaffIdentityState {
  const new(super.masked, this.value);

  final String value;

  @override
  List<Object?> get props => [masked, value];
}

/// The Aadhaar number of one staff member (STF-11, STF-12): seen masked, set, cleared, and revealed in full for a
/// reason. The number is held only while it is shown, and the API never sends it back after it is set.
class StaffIdentityBloc extends Bloc<StaffIdentityEvent, StaffIdentityState> {
  new(this._staff, {required this.staffMemberId, String? masked}) : super(StaffIdentityIdle(masked)) {
    on<StaffAadhaarSaved>((event, emit) => _set(event.aadhaar, StaffIdentityAction.save, emit));
    on<StaffAadhaarCleared>((event, emit) => _set(null, StaffIdentityAction.clear, emit));
    on<StaffAadhaarRevealed>(_onRevealed);
    on<StaffIdentityHidden>((event, emit) {
      if (state is StaffIdentityRevealed || state is StaffIdentityRefused) emit(StaffIdentityIdle(state.masked));
    });
  }

  final StaffRepository _staff;
  final String staffMemberId;

  bool get _free => state is! StaffIdentityWorking;

  Future<void> _set(String? aadhaar, StaffIdentityAction action, Emitter<StaffIdentityState> emit) async {
    if (!_free) return;
    emit(StaffIdentityWorking(state.masked, action));
    try {
      emit(StaffIdentityIdle(await _staff.setAadhaar(staffMemberId, aadhaar)));
    } on ApiFailure catch (failure) {
      emit(StaffIdentityRefused(state.masked, action, failure));
    }
  }

  Future<void> _onRevealed(StaffAadhaarRevealed event, Emitter<StaffIdentityState> emit) async {
    if (!_free) return;
    emit(StaffIdentityWorking(state.masked, StaffIdentityAction.reveal));
    try {
      emit(StaffIdentityRevealed(state.masked, await _staff.revealAadhaar(staffMemberId, reason: event.reason)));
    } on ApiFailure catch (failure) {
      emit(
        StaffIdentityRefused(
          // No number is held: the screen was out of date.
          failure.code == 'NOT_SET' ? null : state.masked,
          StaffIdentityAction.reveal,
          failure,
        ),
      );
    }
  }
}
