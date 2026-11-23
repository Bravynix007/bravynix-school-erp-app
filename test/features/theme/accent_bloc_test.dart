import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/storage/accent_choice_store.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/features/theme/presentation/bloc/accent_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts on the default accent', () {
    expect(AccentBloc(InMemoryAccentChoiceStore()).state.accent, AppAccent.teal);
  });

  blocTest<AccentBloc, AccentState>(
    'opens on the accent chosen last',
    build: () => AccentBloc(InMemoryAccentChoiceStore(AppAccent.royalPurple)),
    act: (bloc) => bloc.add(const AccentStarted()),
    expect: () => [const AccentState(AppAccent.royalPurple)],
  );

  blocTest<AccentBloc, AccentState>(
    'stays on the default when nothing was chosen before',
    build: () => AccentBloc(InMemoryAccentChoiceStore()),
    act: (bloc) => bloc.add(const AccentStarted()),
    expect: () => <AccentState>[],
  );

  test('a chosen accent shows at once and is remembered', () async {
    final store = InMemoryAccentChoiceStore();
    final bloc = AccentBloc(store)..add(const AccentChosen(AppAccent.sunsetOrange));
    await bloc.stream.first;
    expect(bloc.state.accent, AppAccent.sunsetOrange);
    await pumpEventQueue();
    expect(await store.read(), AppAccent.sunsetOrange);
    await bloc.close();
  });

  blocTest<AccentBloc, AccentState>(
    'choosing the accent already shown changes nothing',
    build: () => AccentBloc(InMemoryAccentChoiceStore()),
    act: (bloc) => bloc.add(const AccentChosen(AppAccent.teal)),
    expect: () => <AccentState>[],
  );
}
