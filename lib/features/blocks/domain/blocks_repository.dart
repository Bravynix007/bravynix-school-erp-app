import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';

/// The blocks an Owner can read (API design 10.4e). Methods throw [ApiFailure].
abstract class BlocksRepository {
  /// SOC-02: the active blocks of the Owner's own Society, oldest first. It answers
  /// while the Owners are blocked, so the Owner can see what is blocked and why.
  Future<List<SectionBlock>> societyBlocks();
}
