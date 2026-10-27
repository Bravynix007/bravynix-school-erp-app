import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/cubit/society_blocks_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockBlocksRepository blocks;
  final owners = SectionBlock(
    id: 'b1',
    section: BlockSection.owners,
    reason: 'Terms not accepted',
    blockedAt: DateTime.utc(2026, 10, 27),
  );

  setUp(() => blocks = MockBlocksRepository());

  blocTest<SocietyBlocksCubit, SocietyBlocksState>(
    'loads the blocks of the Society',
    build: () => SocietyBlocksCubit(blocks),
    setUp: () => when(() => blocks.societyBlocks()).thenAnswer((_) async => [owners]),
    act: (cubit) => cubit.load(),
    expect: () => [
      const SocietyBlocksLoading(),
      SocietyBlocksLoaded([owners]),
    ],
  );

  blocTest<SocietyBlocksCubit, SocietyBlocksState>(
    'keeps the failure for the screen, and loads again on retry',
    build: () => SocietyBlocksCubit(blocks),
    setUp: () {
      var calls = 0;
      when(() => blocks.societyBlocks()).thenAnswer((_) async {
        if (++calls == 1) throw const ApiFailure.network();
        return [owners];
      });
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    expect: () => [
      const SocietyBlocksLoading(),
      const SocietyBlocksFailed(ApiFailure.network()),
      const SocietyBlocksLoading(),
      SocietyBlocksLoaded([owners]),
    ],
  );
}
