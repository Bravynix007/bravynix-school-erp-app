import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_draft.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_form_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/files.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';

/// The form with its real bloc, for what only shows when the screen and the bloc work together.

/// Kavya as someone else saved her meanwhile.
const _newer = StaffMember(
  id: 'f1',
  homeInstitutionId: 'i1',
  email: 'kavya.nair@example.com',
  firstName: 'Kavya R',
  classCategoryId: 'c1',
  mobile: mobile,
  address: Address(),
  educations: [],
  emergencyContacts: [],
  isBlocked: false,
  version: 5,
);

const _conflict = ApiFailure(statusCode: 409, code: 'VERSION_CONFLICT', message: 'server words');

void main() {
  late MockStaffRepository staff;
  late MockMastersRepository masters;

  setUpAll(() {
    registerFallbackValue(raviDraft);
    registerFallbackValue(MasterType.countries);
  });

  setUp(() {
    staff = MockStaffRepository();
    masters = MockMastersRepository();
    when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async => [lowerPrimary]);
    when(() => masters.entries(MasterType.designations)).thenAnswer((_) async => [designationEntry]);
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [india]);
    when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [karnataka]);
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [bengaluru]);
    getIt
      ..registerSingleton<MastersRepository>(masters)
      ..registerSingleton<FilesRepository>(MockFilesRepository())
      ..registerSingleton<FilePicking>(FakeFilePicking(result: photo));
  });
  tearDown(getIt.reset);

  Future<void> openKavya(WidgetTester tester) async {
    final bloc = StaffFormBloc(staff, masters, staffId: 'f1')..add(const StaffFormStarted());
    addTearDown(bloc.close);
    await tester.pumpAppScaled(
      BlocProvider<StaffFormBloc>.value(value: bloc, child: const StaffFormView()),
      size: const Size(400, 8000),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
  String textOf(WidgetTester tester, String key) => tester.widget<TextField>(field(key)).controller!.text;

  testWidgets('Reload after a version conflict shows the newer record, even when it is read at once', (tester) async {
    var reads = 0;
    when(() => staff.member('f1')).thenAnswer((_) async => ++reads == 1 ? kavyaMember : _newer);
    when(() => staff.update(any(), any(), any())).thenThrow(_conflict);
    await openKavya(tester);
    await tester.enterText(field('staffForm.firstName'), 'Kavitha');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staffForm.reload')), findsOneWidget);
    expect(textOf(tester, 'staffForm.firstName'), 'Kavitha');

    await tester.tap(find.byKey(const Key('staffForm.reload')));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'staffForm.firstName'), 'Kavya R');
    expect(find.byKey(const Key('staffForm.error')), findsNothing);
    // The next Save is for the newer version, with the newer text.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final call = verify(() => staff.update('f1', 5, captureAny())).captured.single as StaffDraft;
    expect(call.firstName, 'Kavya R');
  });

  testWidgets('keeps an error under the line it was about when an earlier line is removed afterwards', (tester) async {
    when(() => staff.member('f1')).thenAnswer((_) async => kavyaMember);
    when(() => staff.update(any(), any(), any())).thenThrow(
      const ApiFailure(
        statusCode: 400,
        code: 'VALIDATION_FAILED',
        message: 'x',
        fieldErrors: [FieldError(field: 'educations[1].degree', code: 'REQUIRED', message: 'Enter the degree')],
      ),
    );
    await openKavya(tester);
    // Three lines: the one the record has (row 0) and two added (rows 3 and 4).
    await tester.tap(find.byKey(const Key('staffForm.addEducation')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('staffForm.addEducation')));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    Finder errorUnder(int row) => find.descendant(
      of: find.byKey(Key('staffForm.education.$row.degree')),
      matching: find.text('Enter the degree'),
    );
    expect(errorUnder(3), findsOneWidget);
    expect(find.text('Enter the degree'), findsOneWidget);

    await tester.tap(find.byKey(const Key('staffForm.education.0.remove')));
    await tester.pumpAndSettle();
    expect(errorUnder(3), findsOneWidget);
    expect(errorUnder(4), findsNothing);
    expect(find.text('Enter the degree'), findsOneWidget);
    expect(find.byKey(const Key('staffForm.error')), findsNothing);
  });
}
