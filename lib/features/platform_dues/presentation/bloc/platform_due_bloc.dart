import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_dues_repository.dart';
import 'package:equatable/equatable.dart';

sealed class PlatformDueEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the due, and Try again after a failure.
final class PlatformDueRequested extends PlatformDueEvent {
  const new();
}

sealed class PlatformDueState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class PlatformDueLoading extends PlatformDueState {
  const new();
}

class PlatformDueLoaded extends PlatformDueState {
  const new(this.due);

  final PlatformDue due;

  @override
  List<Object?> get props => [due];
}

class PlatformDueFailed extends PlatformDueState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// One due of the Owner's Society and how its total was reached (BIL-02).
class PlatformDueBloc extends Bloc<PlatformDueEvent, PlatformDueState> {
  new(this._dues, {required this.id}) : super(const PlatformDueLoading()) {
    on<PlatformDueRequested>(_onRequested);
  }

  final PlatformDuesRepository _dues;
  final String id;

  Future<void> _onRequested(PlatformDueRequested event, Emitter<PlatformDueState> emit) async {
    emit(const PlatformDueLoading());
    try {
      emit(PlatformDueLoaded(await _dues.due(id)));
    } on ApiFailure catch (failure) {
      emit(PlatformDueFailed(failure));
    }
  }
}
