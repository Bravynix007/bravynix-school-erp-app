import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/blocks/data/block_models.dart';
import 'package:bravynix_school_erp/features/blocks/domain/blocks_repository.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';

class BlocksRepositoryImpl implements BlocksRepository {
  const new({required this._api});

  final ApiClient _api;

  @override
  Future<List<SectionBlock>> societyBlocks() => _api.data('society/access-blocks', parse: BlockModels.blocks);
}
