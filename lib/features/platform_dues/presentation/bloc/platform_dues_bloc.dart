import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_dues_repository.dart';
import 'package:equatable/equatable.dart';

sealed class PlatformDuesEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, pulling to refresh, and Try again after a failure.
final class PlatformDuesRequested extends PlatformDuesEvent {
  const new();
}

sealed class PlatformDuesState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class PlatformDuesLoading extends PlatformDuesState {
  const new();
}

class PlatformDuesLoaded extends PlatformDuesState {
  const new(this.dues);

  final PlatformDues dues;

  @override
  List<Object?> get props => [dues];
}

class PlatformDuesFailed extends PlatformDuesState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// What BravyNix has charged the Owner's Society (BIL-01). View only.
class PlatformDuesBloc extends Bloc<PlatformDuesEvent, PlatformDuesState> {
  new(this._dues) : super(const PlatformDuesLoading()) {
    on<PlatformDuesRequested>(_onRequested);
  }

  final PlatformDuesRepository _dues;

  Future<void> _onRequested(PlatformDuesRequested event, Emitter<PlatformDuesState> emit) async {
    emit(const PlatformDuesLoading());
    try {
      emit(PlatformDuesLoaded(await _dues.dues()));
    } on ApiFailure catch (failure) {
      emit(PlatformDuesFailed(failure));
    }
  }
}
