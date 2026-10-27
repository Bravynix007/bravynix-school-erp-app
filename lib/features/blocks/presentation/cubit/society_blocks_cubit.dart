import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/blocks/domain/blocks_repository.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:equatable/equatable.dart';

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
class SocietyBlocksCubit extends Cubit<SocietyBlocksState> {
  new(this._blocks) : super(const SocietyBlocksLoading());

  final BlocksRepository _blocks;

  Future<void> load() async {
    emit(const SocietyBlocksLoading());
    try {
      emit(SocietyBlocksLoaded(await _blocks.societyBlocks()));
    } on ApiFailure catch (failure) {
      emit(SocietyBlocksFailed(failure));
    }
  }
}
