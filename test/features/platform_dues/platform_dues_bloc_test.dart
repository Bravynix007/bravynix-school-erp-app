import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/bloc/platform_due_bloc.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/bloc/platform_dues_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/platform_dues.dart';

void main() {
  late MockPlatformDuesRepository repository;
  setUp(() => repository = MockPlatformDuesRepository());

  final dues = PlatformDues(totalDueAmount: '80000.00', hasOpenDues: true, dues: [dueLine()]);

  group('PlatformDuesBloc', () {
    blocTest<PlatformDuesBloc, PlatformDuesState>(
      'loads the dues of the Society',
      build: () => PlatformDuesBloc(repository),
      setUp: () => when(() => repository.dues()).thenAnswer((_) async => dues),
      act: (bloc) => bloc.add(const PlatformDuesRequested()),
      expect: () => [const PlatformDuesLoading(), PlatformDuesLoaded(dues)],
    );

    blocTest<PlatformDuesBloc, PlatformDuesState>(
      'keeps the failure for the screen, and loads again on retry',
      build: () => PlatformDuesBloc(repository),
      setUp: () {
        var calls = 0;
        when(() => repository.dues()).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return dues;
        });
      },
      act: (bloc) async {
        bloc.add(const PlatformDuesRequested());
        await bloc.stream.firstWhere((state) => state is PlatformDuesFailed);
        bloc.add(const PlatformDuesRequested());
      },
      expect: () => [
        const PlatformDuesLoading(),
        const PlatformDuesFailed(ApiFailure.network()),
        const PlatformDuesLoading(),
        PlatformDuesLoaded(dues),
      ],
    );
  });

  group('PlatformDueBloc', () {
    blocTest<PlatformDueBloc, PlatformDueState>(
      'loads the due it was made for',
      build: () => PlatformDueBloc(repository, id: 'd1'),
      setUp: () => when(() => repository.due('d1')).thenAnswer((_) async => due()),
      act: (bloc) => bloc.add(const PlatformDueRequested()),
      expect: () => [const PlatformDueLoading(), PlatformDueLoaded(due())],
      verify: (_) => verify(() => repository.due('d1')).called(1),
    );

    blocTest<PlatformDueBloc, PlatformDueState>(
      'keeps a refusal for the screen',
      build: () => PlatformDueBloc(repository, id: 'd1'),
      setUp: () => when(() => repository.due('d1')).thenThrow(
        const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'),
      ),
      act: (bloc) => bloc.add(const PlatformDueRequested()),
      expect: () => [
        const PlatformDueLoading(),
        const PlatformDueFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      ],
    );
  });
}
