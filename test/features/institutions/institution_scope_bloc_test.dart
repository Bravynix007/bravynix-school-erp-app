import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/storage/institution_choice_store.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_scope_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockInstitutionsRepository repository;
  late InMemoryInstitutionChoiceStore store;
  final first = summary();
  final second = summary(id: 'i2', code: 'LVS', name: 'Lake View School');

  setUp(() {
    repository = MockInstitutionsRepository();
    store = InMemoryInstitutionChoiceStore();
    when(repository.institutions).thenAnswer((_) async => [first, second]);
  });

  InstitutionScopeBloc build() => InstitutionScopeBloc(repository, store);

  blocTest<InstitutionScopeBloc, InstitutionScopeState>(
    'starts on the first Institution when none was chosen before',
    build: build,
    act: (bloc) => bloc.add(const InstitutionScopeStarted()),
    expect: () => [
      const InstitutionScopeLoading(),
      InstitutionScopeReady(institutions: [first, second], selected: first),
    ],
  );

  blocTest<InstitutionScopeBloc, InstitutionScopeState>(
    'starts on the Institution chosen last',
    build: () => InstitutionScopeBloc(repository, InMemoryInstitutionChoiceStore('i2')),
    act: (bloc) => bloc.add(const InstitutionScopeStarted()),
    expect: () => [
      const InstitutionScopeLoading(),
      InstitutionScopeReady(institutions: [first, second], selected: second),
    ],
  );

  blocTest<InstitutionScopeBloc, InstitutionScopeState>(
    'ignores a remembered Institution the person no longer has',
    build: () => InstitutionScopeBloc(repository, InMemoryInstitutionChoiceStore('gone')),
    act: (bloc) => bloc.add(const InstitutionScopeStarted()),
    expect: () => [
      const InstitutionScopeLoading(),
      InstitutionScopeReady(institutions: [first, second], selected: first),
    ],
  );

  blocTest<InstitutionScopeBloc, InstitutionScopeState>(
    'says so when there is no Institution to work in',
    build: build,
    setUp: () => when(repository.institutions).thenAnswer((_) async => []),
    act: (bloc) => bloc.add(const InstitutionScopeStarted()),
    expect: () => [const InstitutionScopeLoading(), const InstitutionScopeEmpty()],
  );

  blocTest<InstitutionScopeBloc, InstitutionScopeState>(
    'keeps the failure for the screen, and starts again on retry',
    build: build,
    setUp: () {
      var calls = 0;
      when(repository.institutions).thenAnswer((_) async {
        if (++calls == 1) throw const ApiFailure.network();
        return [first];
      });
    },
    act: (bloc) async {
      bloc.add(const InstitutionScopeStarted());
      await bloc.stream.firstWhere((state) => state is InstitutionScopeFailed);
      bloc.add(const InstitutionScopeStarted());
    },
    expect: () => [
      const InstitutionScopeLoading(),
      const InstitutionScopeFailed(ApiFailure.network()),
      const InstitutionScopeLoading(),
      InstitutionScopeReady(institutions: [first], selected: first),
    ],
  );

  blocTest<InstitutionScopeBloc, InstitutionScopeState>(
    'switches to another Institution and remembers it',
    build: build,
    act: (bloc) async {
      bloc.add(const InstitutionScopeStarted());
      await bloc.stream.firstWhere((state) => state is InstitutionScopeReady);
      bloc.add(const InstitutionScopeChosen('i2'));
    },
    skip: 2,
    expect: () => [
      InstitutionScopeReady(institutions: [first, second], selected: second),
    ],
    verify: (_) async => expect(await store.read(), 'i2'),
  );

  blocTest<InstitutionScopeBloc, InstitutionScopeState>(
    'ignores the Institution already chosen, and one it does not have',
    build: build,
    act: (bloc) async {
      bloc.add(const InstitutionScopeStarted());
      await bloc.stream.firstWhere((state) => state is InstitutionScopeReady);
      bloc
        ..add(const InstitutionScopeChosen('i1'))
        ..add(const InstitutionScopeChosen('nope'));
    },
    skip: 2,
    expect: () => <InstitutionScopeState>[],
    verify: (_) async => expect(await store.read(), isNull),
  );
}
