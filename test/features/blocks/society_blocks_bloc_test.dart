import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/bloc/society_blocks_bloc.dart';
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

  blocTest<SocietyBlocksBloc, SocietyBlocksState>(
    'loads the blocks of the Society',
    build: () => SocietyBlocksBloc(blocks),
    setUp: () => when(() => blocks.societyBlocks()).thenAnswer((_) async => [owners]),
    act: (bloc) => bloc.add(const SocietyBlocksRequested()),
    expect: () => [
      const SocietyBlocksLoading(),
      SocietyBlocksLoaded([owners]),
    ],
  );

  blocTest<SocietyBlocksBloc, SocietyBlocksState>(
    'keeps the failure for the screen, and loads again on retry',
    build: () => SocietyBlocksBloc(blocks),
    setUp: () {
      var calls = 0;
      when(() => blocks.societyBlocks()).thenAnswer((_) async {
        if (++calls == 1) throw const ApiFailure.network();
        return [owners];
      });
    },
    act: (bloc) async {
      bloc.add(const SocietyBlocksRequested());
      await bloc.stream.firstWhere((state) => state is SocietyBlocksFailed);
      bloc.add(const SocietyBlocksRequested());
    },
    expect: () => [
      const SocietyBlocksLoading(),
      const SocietyBlocksFailed(ApiFailure.network()),
      const SocietyBlocksLoading(),
      SocietyBlocksLoaded([owners]),
    ],
  );
}
