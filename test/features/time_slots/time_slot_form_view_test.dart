import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/bloc/time_slot_form_bloc.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/view/time_slot_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/leaving_a_form.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/time_slots.dart';

class _MockFormBloc extends MockBloc<TimeSlotFormEvent, TimeSlotFormState> implements TimeSlotFormBloc;

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

void main() {
  late _MockFormBloc bloc;
  setUpAll(
    () => registerFallbackValue(
      const TimeSlotFormSubmitted(
        TimeSlotFields(periodNo: '', label: '', startTime: '', endTime: '', isBreak: false),
      ),
    ),
  );
  setUp(() => bloc = _MockFormBloc());

  Future<void> pump(
    WidgetTester tester,
    TimeSlotFormState state, {
    TimeSlot? slot,
    double textScale = 1,
    Size size = const Size(400, 1400),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<TimeSlotFormBloc>.value(
        value: bloc,
        child: TimeSlotFormView(slot: slot),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder inputOf(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

  TimeSlotFormSubmitted submitted() => verify(() => bloc.add(captureAny())).captured.single as TimeSlotFormSubmitted;

  Future<void> pickTime(WidgetTester tester, String field, {required int hour, required int minute}) async {
    await tester.tap(find.byKey(Key(field)));
    await tester.pumpAndSettle();
    // The clock opens on its keyboard entry: type the hour and the minute.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final boxes = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));
    await tester.enterText(boxes.at(0), hour.toString());
    await tester.enterText(boxes.at(1), minute.toString().padLeft(2, '0'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty form to add: no times chosen yet, and the number can be typed', (tester) async {
    await pump(tester, const TimeSlotFormEditing());
    expect(find.text('Add period'), findsOneWidget);
    expect(tester.widget<TextField>(inputOf('timeSlotForm.number')).enabled, isTrue);
    expect(tester.widget<TextField>(inputOf('timeSlotForm.number')).controller!.text, isEmpty);
    expect(find.textContaining('Starts at', findRichText: true), findsOneWidget);
    expect(find.textContaining('Ends at', findRichText: true), findsOneWidget);
  });

  testWidgets('an edit starts from the period, and cannot change its number or whether it is a break', (tester) async {
    await pump(tester, const TimeSlotFormEditing(), slot: lunch);
    expect(find.text('Edit period'), findsOneWidget);
    expect(tester.widget<TextField>(inputOf('timeSlotForm.number')).enabled, isFalse);
    expect(tester.widget<TextField>(inputOf('timeSlotForm.number')).controller!.text, '4');
    expect(tester.widget<TextField>(inputOf('timeSlotForm.label')).controller!.text, 'Lunch');
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('12:30'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byKey(const Key('timeSlotForm.break')));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('Save sends what is typed, the times picked on the clock and the break mark', (tester) async {
    await pump(tester, const TimeSlotFormEditing());
    await tester.enterText(inputOf('timeSlotForm.number'), '5');
    await tester.enterText(inputOf('timeSlotForm.label'), 'Snack');
    await pickTime(tester, 'timeSlotForm.start', hour: 10, minute: 5);
    expect(find.text('10:05'), findsOneWidget);
    await pickTime(tester, 'timeSlotForm.end', hour: 10, minute: 20);
    await tester.tap(find.byKey(const Key('timeSlotForm.break')));
    await tester.pump();
    await tester.tap(find.text('Save'));
    expect(
      submitted().fields,
      const TimeSlotFields(periodNo: '5', label: 'Snack', startTime: '10:05', endTime: '10:20', isBreak: true),
    );
  });

  testWidgets('the number takes digits only, two at most', (tester) async {
    await pump(tester, const TimeSlotFormEditing());
    await tester.enterText(inputOf('timeSlotForm.number'), '1a2b3');
    expect(tester.widget<TextField>(inputOf('timeSlotForm.number')).controller!.text, '12');
  });

  testWidgets('a clock that is cancelled changes nothing', (tester) async {
    await pump(tester, const TimeSlotFormEditing(), slot: lunch);
    await tester.tap(find.byKey(const Key('timeSlotForm.end')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Cancel')));
    await tester.pumpAndSettle();
    expect(find.text('12:30'), findsOneWidget);
  });

  testWidgets('while saving, Save does nothing', (tester) async {
    await pump(tester, const TimeSlotFormEditing(saving: true), slot: lunch);
    final save = find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('shows a field left empty as required, under that field', (tester) async {
    await pump(
      tester,
      const TimeSlotFormEditing(
        failure: ApiFailure.invalid([FieldError.required('startTime'), FieldError.required('periodNo')]),
      ),
    );
    expect(find.text('This field is required.'), findsNWidgets(2));
    expect(find.byKey(const Key('timeSlotForm.error')), findsNothing);
  });

  testWidgets('says an overlap under the start time, in the app words', (tester) async {
    await pump(
      tester,
      TimeSlotFormEditing(
        failure: _failure(
          409,
          'TIME_SLOT_OVERLAP',
          fields: const [FieldError(field: 'startTime', code: 'TIME_SLOT_OVERLAP', message: 'x')],
        ),
      ),
    );
    expect(find.textContaining('overlap another period of this year'), findsOneWidget);
    expect(find.byKey(const Key('timeSlotForm.error')), findsNothing);
  });

  testWidgets('says a taken number under the number, in the app words', (tester) async {
    await pump(
      tester,
      TimeSlotFormEditing(
        failure: _failure(
          409,
          'DUPLICATE',
          fields: const [FieldError(field: 'periodNo', code: 'DUPLICATE', message: 'x')],
        ),
      ),
    );
    expect(find.text('Another period of this year has this number.'), findsOneWidget);
    expect(find.byKey(const Key('timeSlotForm.error')), findsNothing);
  });

  testWidgets('says a refusal of a field the form does not show above it', (tester) async {
    await pump(tester, TimeSlotFormEditing(failure: _failure(422, 'CURRENT_YEAR_REQUIRED')));
    expect(find.byKey(const Key('timeSlotForm.error')), findsOneWidget);
    expect(find.textContaining('has no current academic year'), findsOneWidget);
  });

  testWidgets('offers Back to the list only after a version conflict', (tester) async {
    await pump(tester, TimeSlotFormEditing(failure: _failure(409, 'TIME_SLOT_OVERLAP')), slot: lunch);
    expect(find.byKey(const Key('timeSlotForm.backToList')), findsNothing);
  });

  leavingAFormTests(
    backToList: const Key('timeSlotForm.backToList'),
    setFailure: (failure) => when(() => bloc.state).thenReturn(TimeSlotFormEditing(failure: failure)),
    form: () => BlocProvider<TimeSlotFormBloc>.value(
      value: bloc,
      child: const TimeSlotFormView(slot: lunch),
    ),
  );

  testWidgets('closes with true and says so once saved', (tester) async {
    whenListen(
      bloc,
      Stream.value(const TimeSlotFormSaved(lunch)),
      initialState: const TimeSlotFormEditing(saving: true),
    );
    bool? closedWith;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => closedWith = await context.push<bool>('/form'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (_, _) => BlocProvider<TimeSlotFormBloc>.value(value: bloc, child: const TimeSlotFormView()),
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
    expect(closedWith, isTrue);
    expect(find.text('Period saved'), findsOneWidget);
  });

  for (final slot in [null, lunch]) {
    testWidgets('reads whole at a large text scale on a small phone, ${slot == null ? 'to add' : 'to edit'}', (
      tester,
    ) async {
      await pump(
        tester,
        TimeSlotFormEditing(failure: _failure(422, 'CURRENT_YEAR_REQUIRED')),
        slot: slot,
        textScale: 2,
        size: const Size(320, 2000),
      );
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    });
  }
}
