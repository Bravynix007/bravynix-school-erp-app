import 'package:bravynix_school_erp/features/blocks/data/block_models.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> staff() => {
    'id': 'b1',
    'section': 'staff',
    'institutionId': 'i1',
    'institutionName': 'Sri Vidya High School',
    'reason': 'Annual fee unpaid',
    'blockedAt': '2026-10-27T04:30:00.000Z',
    'future': 'ignored',
  };

  test('reads a block of an Institution, and ignores fields it does not know', () {
    expect(
      BlockModels.block(staff()),
      SectionBlock(
        id: 'b1',
        section: BlockSection.staff,
        institutionId: 'i1',
        institutionName: 'Sri Vidya High School',
        reason: 'Annual fee unpaid',
        blockedAt: DateTime.utc(2026, 10, 27, 4, 30),
      ),
    );
  });

  test('reads the Owners’ block, which names no Institution', () {
    final block = BlockModels.block({...staff(), 'section': 'owners', 'institutionId': null, 'institutionName': null});
    expect(block.section, BlockSection.owners);
    expect(block.institutionId, isNull);
    expect(block.institutionName, isNull);
  });

  test('refuses a section it does not know, rather than showing a block under the wrong name', () {
    expect(() => BlockModels.block({...staff(), 'section': 'teachers'}), throwsFormatException);
  });

  test('reads a list, and refuses anything else', () {
    expect(BlockModels.blocks([staff(), staff()]), hasLength(2));
    expect(BlockModels.blocks(<Object?>[]), isEmpty);
    expect(() => BlockModels.blocks({'items': <Object?>[]}), throwsFormatException);
    expect(() => BlockModels.blocks(['x']), throwsFormatException);
  });
}
