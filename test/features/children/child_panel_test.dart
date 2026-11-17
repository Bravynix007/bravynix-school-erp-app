import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/view/child_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockActiveChildBloc extends MockBloc<ActiveChildEvent, ActiveChildState> implements ActiveChildBloc;

void main() {
  const diya = LinkedChild(
    studentId: 's1',
    firstName: 'Diya',
    lastName: 'Shetty',
    institutionName: 'Green Valley School',
    className: '7th',
    sectionName: 'A',
    isBlocked: false,
  );
  const arun = LinkedChild(
    studentId: 's2',
    firstName: 'Arun',
    institutionName: 'Lake View School',
    className: '4th',
    isBlocked: false,
  );
  const meera = LinkedChild(studentId: 's3', firstName: 'Meera', institutionName: 'Lake View School', isBlocked: true);

  late _MockActiveChildBloc bloc;
  setUpAll(() => registerFallbackValue(const ActiveChildChosen('x')));
  setUp(() => bloc = _MockActiveChildBloc());

  Future<void> pump(WidgetTester tester, ActiveChildState state, {double textScale = 1}) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<ActiveChildBloc>.value(value: bloc, child: const ChildPanel()),
      ),
      textScale: textScale,
    );
  }

  testWidgets('shows nothing for a person with no child', (tester) async {
    await pump(tester, const ActiveChildNone());
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('one child: the name, class and school, and nothing to switch', (tester) async {
    await pump(tester, const ActiveChildReady(children: [diya], selected: diya));
    expect(find.text('Diya Shetty'), findsOneWidget);
    expect(find.text('7th - A, Green Valley School'), findsOneWidget);
    expect(find.text('Change child'), findsNothing);
  });

  testWidgets('several children: the switcher asks for the one picked', (tester) async {
    await pump(tester, const ActiveChildReady(children: [diya, arun], selected: diya));
    expect(find.text('Change child'), findsOneWidget);
    await tester.tap(find.byKey(const Key('child.switcher')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a child'), findsOneWidget);
    expect(find.text('4th, Lake View School'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('child.option.s2')));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const ActiveChildChosen('s2'))).called(1);
  });

  testWidgets('a child not placed in a class yet says so', (tester) async {
    const newcomer = LinkedChild(studentId: 's4', firstName: 'Ravi', institutionName: 'Lake View', isBlocked: false);
    await pump(tester, const ActiveChildReady(children: [newcomer], selected: newcomer));
    expect(find.text('Not placed in a class yet'), findsOneWidget);
  });

  testWidgets('a blocked child with an open sibling is named in a notice, and the sibling is one tap away', (
    tester,
  ) async {
    await pump(tester, const ActiveChildReady(children: [diya, meera], selected: meera));
    expect(find.text("Access to Meera's information is blocked. Contact the school."), findsOneWidget);
    expect(find.text('Change child'), findsOneWidget);
  });

  testWidgets('an open child shows no notice', (tester) async {
    await pump(tester, const ActiveChildReady(children: [diya, meera], selected: diya));
    expect(find.textContaining('is blocked'), findsNothing);
  });

  testWidgets('when every child is blocked the home says so once, so this adds no second notice', (tester) async {
    await pump(tester, const ActiveChildReady(children: [meera], selected: meera));
    expect(find.textContaining('is blocked'), findsNothing);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    const long = LinkedChild(
      studentId: 's5',
      firstName: 'Lakshmi Priyadarshini',
      lastName: 'Venkataramanaswamy',
      institutionName: 'Sri Vidya Educational Society Senior Secondary School',
      className: '10th',
      sectionName: 'B',
      isBlocked: false,
    );
    await pump(tester, const ActiveChildReady(children: [long, meera], selected: long), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    await tester.tap(find.byKey(const Key('child.switcher')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
