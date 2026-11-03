import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_form_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/institutions.dart';
import '../../helpers/pump_app.dart';

class _MockFormBloc extends MockBloc<InstitutionFormEvent, InstitutionFormState> implements InstitutionFormBloc;

const _addState = InstitutionFormReady(
  categories: [lowerPrimary, higherPrimary],
  countries: [india],
  states: [karnataka, kerala],
  countryId: 'k1',
);

const _editState = InstitutionFormReady(
  existing: institution,
  categories: [lowerPrimary, higherPrimary],
  countries: [india],
  states: [karnataka, kerala],
  cities: [bengaluru, mysuru],
  board: Board.cbse,
  categoryIds: ['c1', 'c2'],
  countryId: 'k1',
  stateId: 's1',
  cityId: 'y1',
);

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

void main() {
  late _MockFormBloc bloc;
  setUpAll(() => registerFallbackValue(const InstitutionFormStarted()));
  setUp(() => bloc = _MockFormBloc());

  Future<void> pump(
    WidgetTester tester,
    InstitutionFormState state, {
    String? id,
    double textScale = 1,
    Size size = const Size(400, 3000),
  }) {
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.institutionId).thenReturn(id);
    return tester.pumpAppScaled(
      BlocProvider<InstitutionFormBloc>.value(value: bloc, child: const InstitutionFormView()),
      textScale: textScale,
      size: size,
    );
  }

  Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
  String textOf(WidgetTester tester, String key) => tester.widget<TextField>(field(key)).controller!.text;

  testWidgets('an empty form to add: the dial code starts as India, the code can be typed', (tester) async {
    await pump(tester, _addState);
    expect(find.text('Add Institution'), findsOneWidget);
    expect(textOf(tester, 'institutionForm.name'), isEmpty);
    expect(textOf(tester, 'institutionForm.phoneCode'), '91');
    expect(tester.widget<TextField>(field('institutionForm.code')).enabled, isTrue);
    expect(find.text("Letters and digits. It can't be changed after saving."), findsOneWidget);
    expect(find.text('Lower Primary'), findsOneWidget);
    expect(find.text('Higher Primary'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);
  });

  testWidgets('an edit starts from the Institution, and the code cannot be changed', (tester) async {
    await pump(tester, _editState, id: 'i1');
    expect(find.text('Edit Institution'), findsOneWidget);
    expect(textOf(tester, 'institutionForm.name'), 'Sri Vidya High School');
    expect(textOf(tester, 'institutionForm.code'), 'SVHS');
    expect(tester.widget<TextField>(field('institutionForm.code')).enabled, isFalse);
    expect(textOf(tester, 'institutionForm.place'), 'Whitefield');
    expect(textOf(tester, 'institutionForm.affiliation'), '830123');
    expect(textOf(tester, 'institutionForm.gstin'), '29ABCDE1234F1Z5');
    expect(textOf(tester, 'institutionForm.line1'), '12 Lake Road');
    expect(textOf(tester, 'institutionForm.line2'), 'Near the park');
    expect(textOf(tester, 'institutionForm.pincode'), '560066');
    expect(textOf(tester, 'institutionForm.email'), 'office@svhs.example.org');
    expect(textOf(tester, 'institutionForm.phoneCode'), '91');
    expect(textOf(tester, 'institutionForm.phoneNumber'), '9876543210');
    expect(textOf(tester, 'institutionForm.telephone'), '080 2345 6789');
    expect(find.text('CBSE'), findsOneWidget);
    expect(find.text('Karnataka'), findsOneWidget);
    expect(find.text('Bengaluru'), findsOneWidget);
    expect(find.text("Letters and digits. It can't be changed after saving."), findsNothing);
  });

  testWidgets('sends what was typed when Save is pressed', (tester) async {
    await pump(tester, _addState);
    await tester.enterText(field('institutionForm.name'), 'Lake View School');
    await tester.enterText(field('institutionForm.code'), 'LVS');
    await tester.enterText(field('institutionForm.line1'), '3 Hill Street');
    await tester.enterText(field('institutionForm.phoneNumber'), '9876543210');
    await tester.tap(find.text('Save'));
    final sent =
        verify(() => bloc.add(captureAny(that: isA<InstitutionFormSubmitted>()))).captured.single
            as InstitutionFormSubmitted;
    expect(
      sent.texts,
      const InstitutionTexts(
        name: 'Lake View School',
        code: 'LVS',
        addressLine1: '3 Hill Street',
        phoneCountryCode: '91',
        phoneNumber: '9876543210',
      ),
    );
  });

  testWidgets('ticks a category, picks a board, a state and a city through the bloc', (tester) async {
    await pump(tester, _editState, id: 'i1');
    await tester.tap(find.text('Lower Primary'));
    verify(() => bloc.add(const InstitutionCategoryToggled('c1'))).called(1);

    await tester.tap(find.byKey(const Key('institutionForm.board')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IB').last);
    await tester.pumpAndSettle();
    verify(() => bloc.add(const InstitutionBoardChosen(Board.ib))).called(1);

    await tester.tap(find.byKey(const Key('institutionForm.state')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kerala').last);
    await tester.pumpAndSettle();
    verify(() => bloc.add(const InstitutionStateChosen('s2'))).called(1);

    await tester.tap(find.byKey(const Key('institutionForm.city')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mysuru').last);
    verify(() => bloc.add(const InstitutionCityChosen('y2'))).called(1);
  });

  testWidgets('a state is chosen within a country and a city within a state', (tester) async {
    await pump(
      tester,
      const InstitutionFormReady(categories: [lowerPrimary], countries: [india]),
    );
    final state = tester.widget<DropdownButtonFormField<String>>(
      find.descendant(
        of: find.byKey(const Key('institutionForm.state')),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    final city = tester.widget<DropdownButtonFormField<String>>(
      find.descendant(
        of: find.byKey(const Key('institutionForm.city')),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    expect(state.onChanged, isNull);
    expect(city.onChanged, isNull);
  });

  testWidgets('keeps a place the Institution holds although its entry is not listed now', (tester) async {
    await pump(
      tester,
      const InstitutionFormReady(
        existing: institution,
        categories: [lowerPrimary],
        countries: [india],
        states: [kerala],
        categoryIds: ['c1'],
        countryId: 'k1',
        stateId: 's1',
      ),
      id: 'i1',
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Karnataka'), findsNothing);
    expect(find.text('India'), findsOneWidget);
  });

  testWidgets('says there is nothing to choose when no class category is listed', (tester) async {
    await pump(tester, const InstitutionFormReady(categories: [], countries: [india]));
    expect(find.text('There are no class categories to choose from.'), findsOneWidget);
  });

  group('after a refused save', () {
    testWidgets('shows each field error under its field', (tester) async {
      await pump(
        tester,
        _addState.copyWith(
          failure: () => _failure(
            400,
            'VALIDATION_FAILED',
            fields: const [
              FieldError(field: 'name', code: 'REQUIRED', message: 'Enter the name'),
              FieldError(field: 'address.line1', code: 'REQUIRED', message: 'Enter the address'),
              FieldError(field: 'phone.number', code: 'INVALID_VALUE', message: 'Not a phone number'),
              FieldError(field: 'gstin', code: 'INVALID_FORMAT', message: 'Not a GSTIN'),
              FieldError(field: 'classesOffered', code: 'INVALID_VALUE', message: 'Pick fewer'),
            ],
          ),
        ),
      );
      expect(find.text('Enter the name'), findsOneWidget);
      expect(find.text('Enter the address'), findsOneWidget);
      expect(find.text('Not a phone number'), findsOneWidget);
      expect(find.text('Not a GSTIN'), findsOneWidget);
      expect(find.text('Pick fewer'), findsOneWidget);
      expect(find.byKey(const Key('institutionForm.error')), findsNothing);
    });

    testWidgets('says a code already in use under the code', (tester) async {
      await pump(
        tester,
        _addState.copyWith(
          failure: () => _failure(
            409,
            'DUPLICATE',
            fields: const [FieldError(field: 'code', code: 'DUPLICATE', message: 'Code in use')],
          ),
        ),
      );
      expect(find.text('Code in use'), findsOneWidget);
    });

    for (final (code, status, text) in [
      ('VERSION_CONFLICT', 409, 'Someone else changed this Institution. Your changes were not saved.'),
      ('REFERENCE_INACTIVE', 422, 'Something you chose is no longer available. Choose again.'),
      ('FORBIDDEN', 403, "You don't have access to this."),
      ('NOT_FOUND', 404, 'This Institution could not be found. It may have been deactivated.'),
    ]) {
      testWidgets('says $code in words above the form', (tester) async {
        await pump(tester, _editState.copyWith(failure: () => _failure(status, code)), id: 'i1');
        expect(find.byKey(const Key('institutionForm.error')), findsOneWidget);
        expect(find.text(text), findsOneWidget);
      });
    }

    testWidgets('offers Reload after a version conflict, which reads the Institution again', (tester) async {
      await pump(tester, _editState.copyWith(failure: () => _failure(409, 'VERSION_CONFLICT')), id: 'i1');
      await tester.tap(find.byKey(const Key('institutionForm.reload')));
      verify(() => bloc.add(const InstitutionFormStarted())).called(1);
    });

    testWidgets('offers Reload for no other failure', (tester) async {
      await pump(tester, _addState.copyWith(failure: () => const ApiFailure.network()));
      expect(find.byKey(const Key('institutionForm.reload')), findsNothing);
    });

    testWidgets('says a category in use under the categories, as the API names the field', (tester) async {
      await pump(
        tester,
        _editState.copyWith(
          failure: () => _failure(
            409,
            'CATEGORY_IN_USE',
            fields: const [FieldError(field: 'classesOffered', code: 'CATEGORY_IN_USE', message: 'In use')],
          ),
        ),
        id: 'i1',
      );
      expect(find.text('In use'), findsOneWidget);
      expect(find.byKey(const Key('institutionForm.error')), findsNothing);
    });

    testWidgets('says a hidden category in words above the form, as the API names it by position', (tester) async {
      await pump(
        tester,
        _editState.copyWith(
          failure: () => _failure(
            422,
            'REFERENCE_INACTIVE',
            fields: const [FieldError(field: 'classesOffered[1]', code: 'REFERENCE_INACTIVE', message: 'Hidden')],
          ),
        ),
        id: 'i1',
      );
      expect(find.text('Something you chose is no longer available. Choose again.'), findsOneWidget);
    });

    testWidgets('says a category in use in words when the API names no field', (tester) async {
      await pump(tester, _editState.copyWith(failure: () => _failure(409, 'CATEGORY_IN_USE')), id: 'i1');
      expect(
        find.text('Classes already use a category you unticked, so it has to stay offered. Tick it again to save.'),
        findsOneWidget,
      );
    });

    testWidgets('says a missing connection above the form', (tester) async {
      await pump(tester, _addState.copyWith(failure: () => const ApiFailure.network()));
      expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
    });
  });

  testWidgets('does not send twice while saving', (tester) async {
    await pump(tester, _addState.copyWith(saving: true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton)));
    verifyNever(() => bloc.add(any(that: isA<InstitutionFormSubmitted>())));
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const InstitutionFormLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why the lists could not be read, and starts again on Try again', (tester) async {
    await pump(tester, const InstitutionFormFailed(ApiFailure.network()));
    expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const InstitutionFormStarted())).called(1);
  });

  testWidgets('says there is no access, with no retry', (tester) async {
    await pump(tester, InstitutionFormFailed(_failure(403, 'FORBIDDEN')));
    expect(find.text("You don't have access to this."), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('says the Institution is gone, with no retry', (tester) async {
    await pump(tester, InstitutionFormFailed(_failure(404, 'NOT_FOUND')), id: 'i1');
    expect(find.text('This Institution could not be found. It may have been deactivated.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('closes with a message and tells the screen behind it once saved', (tester) async {
    whenListen(bloc, Stream.value(const InstitutionFormSaved(institution)), initialState: _addState);
    when(() => bloc.institutionId).thenReturn(null);
    bool? result;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await context.push<bool>('/form'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (_, _) => BlocProvider<InstitutionFormBloc>.value(value: bloc, child: const InstitutionFormView()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.text('Institution saved'), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, _editState, id: 'i1', textScale: 2, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    await tester.scrollUntilVisible(
      find.byKey(const Key('institutionForm.telephone')),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
