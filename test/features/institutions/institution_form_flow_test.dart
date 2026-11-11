import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_form_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_form_page.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

/// The form with its real bloc, for what only shows when the screen and the bloc work together.

/// The Institution as someone else saved it meanwhile.
const _newer = Institution(
  id: 'i1',
  code: 'SVHS',
  name: 'Sri Vidya Reloaded',
  addressLine1: '12 Lake Road',
  version: 4,
  classesOffered: [OfferedCategory(id: 'c1', name: 'Lower Primary')],
);

void main() {
  late MockInstitutionsRepository institutions;
  late MockMastersRepository masters;

  setUpAll(() {
    registerFallbackValue(const InstitutionDraft(name: 'x', code: 'x', addressLine1: 'x', classesOffered: []));
    registerFallbackValue(MasterType.countries);
  });

  setUp(() {
    institutions = MockInstitutionsRepository();
    masters = MockMastersRepository();
    when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async => [lowerPrimary, higherPrimary]);
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [india]);
    when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [karnataka]);
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [bengaluru]);
    getIt.registerSingleton<MastersRepository>(masters);
  });
  tearDown(getIt.reset);

  testWidgets('Reload after a version conflict shows the newer Institution, even when it is read at once', (
    tester,
  ) async {
    var reads = 0;
    when(() => institutions.institution('i1')).thenAnswer((_) async => ++reads == 1 ? institution : _newer);
    when(() => institutions.update(any(), any(), any())).thenThrow(
      const ApiFailure(statusCode: 409, code: 'VERSION_CONFLICT', message: 'server words'),
    );
    final bloc = InstitutionFormBloc(institutions, masters, institutionId: 'i1')..add(const InstitutionFormStarted());
    addTearDown(bloc.close);
    await tester.pumpAppScaled(
      BlocProvider<InstitutionFormBloc>.value(value: bloc, child: const InstitutionFormView()),
      size: const Size(400, 3000),
    );
    await tester.pumpAndSettle();
    Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
    String nameShown() => tester.widget<TextField>(field('institutionForm.name')).controller!.text;

    await tester.enterText(field('institutionForm.name'), 'My own words');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('institutionForm.reload')), findsOneWidget);
    expect(nameShown(), 'My own words');

    await tester.tap(find.byKey(const Key('institutionForm.reload')));
    await tester.pumpAndSettle();

    expect(nameShown(), 'Sri Vidya Reloaded');
    // The next Save is for the newer version.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final draft = verify(() => institutions.update('i1', 4, captureAny())).captured.single as InstitutionDraft;
    expect(draft.name, 'Sri Vidya Reloaded');
  });
}
