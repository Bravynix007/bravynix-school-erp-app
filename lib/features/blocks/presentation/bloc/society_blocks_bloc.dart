import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/blocks/domain/blocks_repository.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:equatable/equatable.dart';

sealed class SocietyBlocksEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the section, and Retry after a failure.
final class SocietyBlocksRequested extends SocietyBlocksEvent {
  const new();
}

sealed class SocietyBlocksState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class SocietyBlocksLoading extends SocietyBlocksState {
  const new();
}

class SocietyBlocksLoaded extends SocietyBlocksState {
  const new(this.blocks);

  final List<SectionBlock> blocks;

  @override
  List<Object?> get props => [blocks];
}

class SocietyBlocksFailed extends SocietyBlocksState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// What is blocked in the Owner's Society and why (SOC-02).
class SocietyBlocksBloc extends Bloc<SocietyBlocksEvent, SocietyBlocksState> {
  new(this._blocks) : super(const SocietyBlocksLoading()) {
    on<SocietyBlocksRequested>(_onRequested);
  }

  final BlocksRepository _blocks;

  Future<void> _onRequested(SocietyBlocksRequested event, Emitter<SocietyBlocksState> emit) async {
    emit(const SocietyBlocksLoading());
    try {
      emit(SocietyBlocksLoaded(await _blocks.societyBlocks()));
    } on ApiFailure catch (failure) {
      emit(SocietyBlocksFailed(failure));
    }
  }
}
