import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/documents/domain/documents_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/file_opening.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_own_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/documents.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'x');

void main() {
  late MockStaffRepository staff;
  late MockDocumentsRepository documents;
  late MockFilesRepository files;
  late MockFileOpening opening;

  setUpAll(() => registerFallbackValue(Uri()));
  setUp(() {
    staff = MockStaffRepository();
    documents = MockDocumentsRepository();
    files = MockFilesRepository();
    opening = MockFileOpening();
    final masters = MockMastersRepository();
    when(() => staff.member('f1')).thenAnswer((_) async => kavyaMember);
    when(() => documents.staffDocuments('f1')).thenAnswer((_) async => [degreeCertificate]);
    when(() => files.downloadLink('fl2')).thenAnswer((_) async => Uri.parse('https://store.test/get/token'));
    when(() => opening.open(any())).thenAnswer((_) async => true);
    when(() => masters.entries(MasterType.designations)).thenAnswer((_) async => [designationEntry]);
    when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async => [lowerPrimary]);
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [countryEntry]);
    when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [stateEntry]);
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [cityEntry]);
    getIt
      ..registerSingleton<StaffRepository>(staff)
      ..registerSingleton<MastersRepository>(masters)
      ..registerSingleton<DocumentsRepository>(documents)
      ..registerSingleton<FilesRepository>(files)
      ..registerSingleton<FileOpening>(opening);
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    await tester.pumpAppScaled(
      const StaffOwnProfilePage(staffMemberId: 'f1'),
      textScale: textScale,
      size: const Size(320, 2800),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the record of the teacher, with no way to change it and no identity card', (tester) async {
    await pump(tester);
    expect(find.text('My details'), findsOneWidget);
    expect(find.text('Kavya Nair'), findsOneWidget);
    expect(find.text('Mathematics Teacher'), findsOneWidget);
    expect(find.text('kavya.nair@example.com'), findsOneWidget);
    expect(find.byKey(const Key('staffProfile.edit')), findsNothing);
    expect(find.text('Identity'), findsNothing);
    verify(() => staff.member('f1')).called(1);
  });

  testWidgets('has only the personal and documents tabs', (tester) async {
    await pump(tester);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Access'), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('lists the documents to open, with nothing to add and nothing to take off', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('B.Ed certificate'), findsOneWidget);
    expect(find.byKey(const Key('staffDocuments.open.o2')), findsOneWidget);
    expect(find.byKey(const Key('staffDocuments.remove.o2')), findsNothing);
    expect(find.byKey(const Key('staffDocuments.title')), findsNothing);
    expect(find.byKey(const Key('staffDocuments.attach')), findsNothing);
    verify(() => documents.staffDocuments('f1')).called(1);
  });

  testWidgets('opens a document through a link that was just made', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('staffDocuments.open.o2')));
    await tester.pumpAndSettle();
    verify(() => files.downloadLink('fl2')).called(1);
    verify(() => opening.open(Uri.parse('https://store.test/get/token'))).called(1);
  });

  testWidgets('says the record is not theirs to read, with no retry', (tester) async {
    when(() => staff.member('f1')).thenThrow(_failure(403, 'FORBIDDEN'));
    await pump(tester);
    expect(find.byKey(const Key('staffOwn.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('says the record could not be found', (tester) async {
    when(() => staff.member('f1')).thenThrow(_failure(404, 'NOT_FOUND'));
    await pump(tester);
    expect(find.byKey(const Key('staffOwn.notFound')), findsOneWidget);
  });

  testWidgets('says why it could not be read, and reads again on Try again', (tester) async {
    when(() => staff.member('f1')).thenThrow(_failure(503, 'UNAVAILABLE'));
    await pump(tester);
    expect(find.byKey(const Key('staffOwn.failed')), findsOneWidget);
    when(() => staff.member('f1')).thenAnswer((_) async => kavyaMember);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Kavya Nair'), findsOneWidget);
  });

  testWidgets('fits a narrow phone at a large text size', (tester) async {
    await pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 196), isEmpty);
  });
}
