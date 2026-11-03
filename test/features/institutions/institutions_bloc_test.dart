import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institutions_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockInstitutionsRepository repository;
  setUp(() => repository = MockInstitutionsRepository());

  group('InstitutionsBloc', () {
    blocTest<InstitutionsBloc, InstitutionsState>(
      'loads the Institutions of the caller',
      build: () => InstitutionsBloc(repository),
      setUp: () => when(() => repository.institutions()).thenAnswer((_) async => [summary()]),
      act: (bloc) => bloc.add(const InstitutionsRequested()),
      expect: () => [
        const InstitutionsLoading(),
        InstitutionsLoaded([summary()]),
      ],
    );

    blocTest<InstitutionsBloc, InstitutionsState>(
      'keeps the failure for the screen, and loads again on retry',
      build: () => InstitutionsBloc(repository),
      setUp: () {
        var calls = 0;
        when(() => repository.institutions()).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [summary()];
        });
      },
      act: (bloc) async {
        bloc.add(const InstitutionsRequested());
        await bloc.stream.firstWhere((state) => state is InstitutionsFailed);
        bloc.add(const InstitutionsRequested());
      },
      expect: () => [
        const InstitutionsLoading(),
        const InstitutionsFailed(ApiFailure.network()),
        const InstitutionsLoading(),
        InstitutionsLoaded([summary()]),
      ],
    );
  });

  group('InstitutionBloc', () {
    blocTest<InstitutionBloc, InstitutionState>(
      'loads the Institution it was opened for',
      build: () => InstitutionBloc(repository, 'i1'),
      setUp: () => when(() => repository.institution('i1')).thenAnswer((_) async => institution),
      act: (bloc) => bloc.add(const InstitutionRequested()),
      expect: () => [const InstitutionLoading(), const InstitutionLoaded(institution)],
    );

    blocTest<InstitutionBloc, InstitutionState>(
      'keeps a 404 for the screen',
      build: () => InstitutionBloc(repository, 'i1'),
      setUp: () => when(
        () => repository.institution('i1'),
      ).thenThrow(const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      act: (bloc) => bloc.add(const InstitutionRequested()),
      expect: () => [
        const InstitutionLoading(),
        const InstitutionFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      ],
    );

    blocTest<InstitutionBloc, InstitutionState>(
      'deactivates, and says so for the screen to close',
      build: () => InstitutionBloc(repository, 'i1'),
      seed: () => const InstitutionLoaded(institution),
      setUp: () => when(() => repository.deactivate('i1')).thenAnswer((_) async {}),
      act: (bloc) => bloc.add(const InstitutionDeactivateRequested()),
      expect: () => [const InstitutionLoaded(institution, deactivating: true), const InstitutionDeactivated()],
      verify: (_) => verify(() => repository.deactivate('i1')).called(1),
    );

    blocTest<InstitutionBloc, InstitutionState>(
      'keeps the Institution and the failure when deactivating is refused, so it can be tried again',
      build: () => InstitutionBloc(repository, 'i1'),
      seed: () => const InstitutionLoaded(institution),
      setUp: () => when(() => repository.deactivate('i1')).thenThrow(const ApiFailure.network()),
      act: (bloc) => bloc.add(const InstitutionDeactivateRequested()),
      expect: () => [
        const InstitutionLoaded(institution, deactivating: true),
        const InstitutionLoaded(institution, deactivateFailure: ApiFailure.network()),
      ],
    );

    blocTest<InstitutionBloc, InstitutionState>(
      'does not deactivate twice, or before the Institution is loaded',
      build: () => InstitutionBloc(repository, 'i1'),
      seed: () => const InstitutionLoaded(institution, deactivating: true),
      act: (bloc) => bloc.add(const InstitutionDeactivateRequested()),
      expect: () => <InstitutionState>[],
      verify: (_) => verifyNever(() => repository.deactivate(any())),
    );

    blocTest<InstitutionBloc, InstitutionState>(
      'does nothing while still loading',
      build: () => InstitutionBloc(repository, 'i1'),
      act: (bloc) => bloc.add(const InstitutionDeactivateRequested()),
      expect: () => <InstitutionState>[],
    );
  });
}
