import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/storage/child_choice_store.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const diya = LinkedChild(studentId: 's1', firstName: 'Diya', institutionName: 'Green Valley', isBlocked: false);
  const arun = LinkedChild(studentId: 's2', firstName: 'Arun', institutionName: 'Green Valley', isBlocked: false);
  const blockedFirst = LinkedChild(studentId: 's3', firstName: 'Meera', institutionName: 'Lake View', isBlocked: true);

  blocTest<ActiveChildBloc, ActiveChildState>(
    'starts on the first child when none was chosen before',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore()),
    act: (bloc) => bloc.add(const ActiveChildChildrenChanged([diya, arun])),
    expect: () => [
      const ActiveChildReady(children: [diya, arun], selected: diya),
    ],
  );

  blocTest<ActiveChildBloc, ActiveChildState>(
    'starts on the child chosen last',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore('s2')),
    act: (bloc) => bloc.add(const ActiveChildChildrenChanged([diya, arun])),
    expect: () => [
      const ActiveChildReady(children: [diya, arun], selected: arun),
    ],
  );

  blocTest<ActiveChildBloc, ActiveChildState>(
    'ignores a remembered child the parent no longer guards',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore('gone')),
    act: (bloc) => bloc.add(const ActiveChildChildrenChanged([diya, arun])),
    expect: () => [
      const ActiveChildReady(children: [diya, arun], selected: diya),
    ],
  );

  blocTest<ActiveChildBloc, ActiveChildState>(
    'with nothing remembered, skips a blocked child for the first one whose data is open',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore()),
    act: (bloc) => bloc.add(const ActiveChildChildrenChanged([blockedFirst, arun])),
    expect: () => [
      const ActiveChildReady(children: [blockedFirst, arun], selected: arun),
    ],
  );

  blocTest<ActiveChildBloc, ActiveChildState>(
    'when every child is blocked, still shows the first, to say why',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore()),
    act: (bloc) => bloc.add(const ActiveChildChildrenChanged([blockedFirst])),
    expect: () => [
      const ActiveChildReady(children: [blockedFirst], selected: blockedFirst),
    ],
  );

  blocTest<ActiveChildBloc, ActiveChildState>(
    'a blocked child chosen on purpose stays chosen',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore('s3')),
    act: (bloc) => bloc.add(const ActiveChildChildrenChanged([arun, blockedFirst])),
    expect: () => [
      const ActiveChildReady(children: [arun, blockedFirst], selected: blockedFirst),
    ],
  );

  blocTest<ActiveChildBloc, ActiveChildState>(
    'no children, as for any other role or after signing out, is none',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore()),
    seed: () => const ActiveChildReady(children: [diya], selected: diya),
    act: (bloc) => bloc.add(const ActiveChildChildrenChanged([])),
    expect: () => [const ActiveChildNone()],
  );

  blocTest<ActiveChildBloc, ActiveChildState>(
    'choosing a sibling switches to them and remembers the choice',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore()),
    seed: () => const ActiveChildReady(children: [diya, arun], selected: diya),
    act: (bloc) => bloc.add(const ActiveChildChosen('s2')),
    expect: () => [
      const ActiveChildReady(children: [diya, arun], selected: arun),
    ],
  );

  test('the choice is read again by the next start', () async {
    final store = InMemoryChildChoiceStore();
    final bloc = ActiveChildBloc(store)
      ..add(const ActiveChildChildrenChanged([diya, arun]))
      ..add(const ActiveChildChosen('s2'));
    await bloc.stream.firstWhere((state) => state is ActiveChildReady && state.selected == arun);
    expect(await store.read(), 's2');
    await bloc.close();
  });

  blocTest<ActiveChildBloc, ActiveChildState>(
    'a child that is not on the list, or the one already chosen, changes nothing',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore()),
    seed: () => const ActiveChildReady(children: [diya, arun], selected: diya),
    act: (bloc) => bloc
      ..add(const ActiveChildChosen('s9'))
      ..add(const ActiveChildChosen('s1')),
    expect: () => <ActiveChildState>[],
  );

  blocTest<ActiveChildBloc, ActiveChildState>(
    'a block lifted while the app is open shows at once, on the same child',
    build: () => ActiveChildBloc(InMemoryChildChoiceStore('s3')),
    seed: () => const ActiveChildReady(children: [arun, blockedFirst], selected: blockedFirst),
    act: (bloc) => bloc.add(
      const ActiveChildChildrenChanged([
        arun,
        LinkedChild(studentId: 's3', firstName: 'Meera', institutionName: 'Lake View', isBlocked: false),
      ]),
    ),
    expect: () => [
      const ActiveChildReady(
        children: [
          arun,
          LinkedChild(studentId: 's3', firstName: 'Meera', institutionName: 'Lake View', isBlocked: false),
        ],
        selected: LinkedChild(studentId: 's3', firstName: 'Meera', institutionName: 'Lake View', isBlocked: false),
      ),
    ],
  );
}
