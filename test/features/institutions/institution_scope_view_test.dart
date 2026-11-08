import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_scope_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/institutions.dart';
import '../../helpers/pump_app.dart';

class _MockScopeBloc extends MockBloc<InstitutionScopeEvent, InstitutionScopeState> implements InstitutionScopeBloc;

void main() {
  late _MockScopeBloc bloc;
  final first = summary();
  final second = summary(id: 'i2', code: 'LVS', name: 'Lake View School');
  setUpAll(() => registerFallbackValue(const InstitutionScopeStarted()));
  setUp(() => bloc = _MockScopeBloc());

  Future<void> pump(WidgetTester tester, InstitutionScopeState state, {double textScale = 1}) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<InstitutionScopeBloc>.value(
          value: bloc,
          child: InstitutionScopeView(builder: (_, institution) => Text('content for ${institution.id}')),
        ),
      ),
      textScale: textScale,
    );
  }

  testWidgets('with one Institution, shows its name as the heading and its content', (tester) async {
    await pump(tester, InstitutionScopeReady(institutions: [first], selected: first));
    expect(find.text('Sri Vidya High School'), findsOneWidget);
    expect(find.byKey(const Key('institutionScope.switcher')), findsNothing);
    expect(find.text('content for i1'), findsOneWidget);
  });

  testWidgets('with several, offers a switcher that asks for the one picked', (tester) async {
    await pump(tester, InstitutionScopeReady(institutions: [first, second], selected: first));
    expect(find.byKey(const Key('institutionScope.switcher')), findsOneWidget);
    expect(find.text('Change Institution'), findsOneWidget);
    await tester.tap(find.byKey(const Key('institutionScope.switcher')));
    await tester.pumpAndSettle();
    expect(find.text('Choose an Institution'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('institutionScope.option.i2')));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const InstitutionScopeChosen('i2'))).called(1);
  });

  testWidgets('closing the sheet without a choice, or choosing the current one, asks for nothing new', (tester) async {
    await pump(tester, InstitutionScopeReady(institutions: [first, second], selected: first));
    await tester.tap(find.byKey(const Key('institutionScope.switcher')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<InstitutionScopeChosen>())));
  });

  testWidgets('the content is built again for the next Institution, not reused', (tester) async {
    var built = 0;
    when(() => bloc.state).thenReturn(InstitutionScopeReady(institutions: [first, second], selected: first));
    whenListen(
      bloc,
      Stream.value(InstitutionScopeReady(institutions: [first, second], selected: second)),
      initialState: InstitutionScopeReady(institutions: [first, second], selected: first),
    );
    await tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<InstitutionScopeBloc>.value(
          value: bloc,
          child: InstitutionScopeView(
            builder: (_, institution) => _Counter(institution.id, onInit: () => built++),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(built, 2);
    expect(find.text('content for i2'), findsOneWidget);
  });

  testWidgets('says the person has no Institution to work in', (tester) async {
    await pump(tester, const InstitutionScopeEmpty());
    expect(find.text('No Institutions yet'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const InstitutionScopeLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and starts again on Try again', (tester) async {
    await pump(tester, const InstitutionScopeFailed(ApiFailure.network()));
    expect(find.byKey(const Key('institutionScope.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const InstitutionScopeStarted())).called(1);
  });

  testWidgets('says a role that may not see Institutions has no access', (tester) async {
    await pump(tester, const InstitutionScopeFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.byKey(const Key('institutionScope.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    final long = summary(id: 'i3', name: 'Sri Vidya Educational Society Senior Secondary School');
    await pump(tester, InstitutionScopeReady(institutions: [first, long], selected: long), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}

class _Counter extends StatefulWidget {
  const new(this.id, {required this.onInit});

  final String id;
  final VoidCallback onInit;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => Text('content for ${widget.id}');
}
