import 'dart:async';

import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/device/screen_protection.dart';
import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_identity_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/screen_protection.dart';
import '../../helpers/students.dart';

void main() {
  late MockStudentsRepository students;

  const number = '234567890123';
  const reason = 'Checking the records';
  const masked = 'XXXX XXXX 1234';
  const certificate = 'BC-2018-77';

  setUp(() {
    students = MockStudentsRepository();
    getIt.registerSingleton<ScreenProtection>(RecordingScreenProtection());
  });
  tearDown(getIt.reset);

  // The same student, deactivated: the numbers are still on file.
  const deactivated = StudentRecord(
    id: 'p1',
    institutionId: 'i1',
    firstName: 'Asha',
    lastName: 'Rao',
    mobile: null,
    address: Address(),
    guardians: [],
    identity: StudentIdentity(aadhaarMasked: masked, birthCertificateNumber: certificate),
    isBlocked: false,
    isActive: false,
    version: 3,
  );

  Future<void> pump(
    WidgetTester tester, {
    StudentRecord record = ashaRecord,
    double textScale = 1,
    Size size = const Size(400, 1600),
  }) {
    getIt.registerSingleton<StudentsRepository>(students);
    return tester.pumpAppScaled(
      Scaffold(
        body: SingleChildScrollView(child: StudentIdentitySection(record: record)),
      ),
      textScale: textScale,
      size: size,
    );
  }

  AppButton button(WidgetTester tester, String key) => tester.widget<AppButton>(find.byKey(Key(key)));

  TextField field(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)));

  Future<void> open(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  const saved = IdentitySaved(StudentIdentity(aadhaarMasked: 'XXXX XXXX 0123', birthCertificateNumber: certificate));

  group('the identity of a student', () {
    testWidgets('shows both numbers, the Aadhaar masked and the certificate whole, with ways to change them', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text(masked), findsOneWidget);
      expect(find.text(certificate), findsOneWidget);
      expect(find.byKey(const Key('aadhaar.reveal')), findsOneWidget);
      expect(find.byKey(const Key('aadhaar.set')), findsOneWidget);
      expect(find.byKey(const Key('aadhaar.clear')), findsOneWidget);
      expect(find.byKey(const Key('studentCertificate.set')), findsOneWidget);
      // It is shown whole already, so there is nothing to reveal.
      expect(find.byKey(const Key('studentCertificate.reveal')), findsNothing);
      expect(find.byKey(const Key('studentCertificate.clear')), findsOneWidget);
    });

    testWidgets('says each number is not set, with only a way to set it', (tester) async {
      await pump(tester, record: chitraRecord);
      expect(find.text('Not set'), findsNWidgets(2));
      expect(find.text('Set number'), findsNWidgets(2));
      expect(find.byKey(const Key('aadhaar.reveal')), findsNothing);
      expect(find.byKey(const Key('aadhaar.clear')), findsNothing);
      expect(find.byKey(const Key('studentCertificate.clear')), findsNothing);
    });

    testWidgets('of a deactivated student can be shown, and not changed', (tester) async {
      await pump(tester, record: deactivated);
      expect(find.text(masked), findsOneWidget);
      expect(find.text(certificate), findsOneWidget);
      expect(find.byKey(const Key('aadhaar.reveal')), findsOneWidget);
      for (final key in ['aadhaar.set', 'aadhaar.clear', 'studentCertificate.set', 'studentCertificate.clear']) {
        expect(find.byKey(Key(key)), findsNothing, reason: key);
      }
    });

    testWidgets('reads whole at a large text scale on a small phone', (tester) async {
      await pump(tester, textScale: 2, size: const Size(320, 3000));
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    });
  });

  group('the Aadhaar number', () {
    testWidgets('is set on this student, and says so', (tester) async {
      when(() => students.setAadhaar('p3', number)).thenAnswer((_) async => saved);
      await pump(tester, record: chitraRecord);
      await open(tester, 'aadhaar.set');
      await tester.enterText(find.byKey(const Key('aadhaar.field')), number);
      await tester.tap(find.byKey(const Key('aadhaar.save')));
      await tester.pumpAndSettle();
      verify(() => students.setAadhaar('p3', number)).called(1);
      expect(find.text('XXXX XXXX 0123'), findsOneWidget);
      expect(find.text('Aadhaar number saved'), findsOneWidget);
    });

    testWidgets('is asked for from an empty field, never from the masked number it is shown as', (tester) async {
      await pump(tester);
      expect(find.text(masked), findsOneWidget);
      await open(tester, 'aadhaar.set');
      expect(field(tester, 'aadhaar.field').controller!.text, isEmpty);
      expect(find.text(masked), findsOneWidget);
    });

    testWidgets('says when another Institution of the Society holds it too', (tester) async {
      when(() => students.setAadhaar('p3', number)).thenAnswer(
        (_) async => const IdentitySaved(
          StudentIdentity(aadhaarMasked: 'XXXX XXXX 0123'),
          warnings: ['AADHAAR_EXISTS_IN_SOCIETY'],
        ),
      );
      await pump(tester, record: chitraRecord);
      await open(tester, 'aadhaar.set');
      await tester.enterText(find.byKey(const Key('aadhaar.field')), number);
      await tester.tap(find.byKey(const Key('aadhaar.save')));
      await tester.pumpAndSettle();
      expect(find.text('XXXX XXXX 0123'), findsOneWidget);
      expect(
        find.text('Aadhaar number saved. Another Institution of the Society holds this number too.'),
        findsOneWidget,
      );
    });

    testWidgets('is refused, in words of the student, when another student of the Institution holds it', (
      tester,
    ) async {
      when(() => students.setAadhaar(any(), any())).thenThrow(
        const ApiFailure(statusCode: 409, code: 'AADHAAR_DUPLICATE_IN_INSTITUTION', message: 'server words'),
      );
      await pump(tester, record: chitraRecord);
      await open(tester, 'aadhaar.set');
      await tester.enterText(find.byKey(const Key('aadhaar.field')), number);
      await tester.tap(find.byKey(const Key('aadhaar.save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aadhaar.saveError')), findsOneWidget);
      expect(find.text('A student of this Institution already has this Aadhaar number.'), findsOneWidget);
      expect(find.text('server words'), findsNothing);
    });

    testWidgets('is cleared once the person confirms, for this student, and the certificate stays', (tester) async {
      when(() => students.setAadhaar('p1', null)).thenAnswer(
        (_) async => const IdentitySaved(StudentIdentity(birthCertificateNumber: certificate)),
      );
      await pump(tester);
      await open(tester, 'aadhaar.clear');
      expect(find.text('Clear the Aadhaar number of Asha Rao?'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Clear number')));
      await tester.pumpAndSettle();
      verify(() => students.setAadhaar('p1', null)).called(1);
      expect(find.text('Aadhaar number cleared'), findsOneWidget);
      expect(find.text(certificate), findsOneWidget);
    });

    testWidgets('is shown whole for a reason, from this student', (tester) async {
      when(() => students.revealAadhaar('p1', reason: reason)).thenAnswer((_) async => number);
      await pump(tester);
      await open(tester, 'aadhaar.reveal');
      await tester.enterText(find.byKey(const Key('aadhaar.reason')), reason);
      await tester.tap(find.byKey(const Key('aadhaar.show')));
      await tester.pumpAndSettle();
      verify(() => students.revealAadhaar('p1', reason: reason)).called(1);
      expect(find.text('2345 6789 0123'), findsOneWidget);
    });

    testWidgets('is shown whole for a deactivated student too, and says why when the limit is reached', (
      tester,
    ) async {
      when(() => students.revealAadhaar(any(), reason: any(named: 'reason'))).thenThrow(
        const ApiFailure(statusCode: 429, code: 'REVEAL_LIMIT', message: 'x'),
      );
      await pump(tester, record: deactivated);
      await open(tester, 'aadhaar.reveal');
      await tester.enterText(find.byKey(const Key('aadhaar.reason')), reason);
      await tester.tap(find.byKey(const Key('aadhaar.show')));
      await tester.pumpAndSettle();
      expect(find.text("You have reached today's limit of ten reveals. Try again tomorrow."), findsOneWidget);
    });
  });

  group('the birth certificate number', () {
    testWidgets('is asked for with the number it has, and sent as it was typed once trimmed', (tester) async {
      when(() => students.setBirthCertificate('p1', 'BC-2019-12')).thenAnswer(
        (_) async => const IdentitySaved(StudentIdentity(aadhaarMasked: masked, birthCertificateNumber: 'BC-2019-12')),
      );
      await pump(tester);
      await open(tester, 'studentCertificate.set');
      expect(field(tester, 'studentCertificate.field').controller!.text, certificate);
      await tester.enterText(find.byKey(const Key('studentCertificate.field')), '  BC-2019-12 ');
      await tester.tap(find.byKey(const Key('studentCertificate.save')));
      await tester.pumpAndSettle();
      verify(() => students.setBirthCertificate('p1', 'BC-2019-12')).called(1);
      expect(find.byKey(const Key('studentCertificate.field')), findsNothing);
      expect(find.text('BC-2019-12'), findsOneWidget);
      expect(find.text('Birth certificate number saved'), findsOneWidget);
      expect(find.text(masked), findsOneWidget);
    });

    testWidgets('is first set from an empty field, and an empty one sends nothing', (tester) async {
      await pump(tester, record: chitraRecord);
      await open(tester, 'studentCertificate.set');
      await tester.enterText(find.byKey(const Key('studentCertificate.field')), '   ');
      await tester.tap(find.byKey(const Key('studentCertificate.save')));
      await tester.pump();
      expect(find.text('Enter the number as it is written on the certificate.'), findsOneWidget);
      verifyNever(() => students.setBirthCertificate(any(), any()));
      await tester.enterText(find.byKey(const Key('studentCertificate.field')), 'B');
      await tester.pump();
      expect(find.text('Enter the number as it is written on the certificate.'), findsNothing);
    });

    testWidgets('takes no more than 50 characters', (tester) async {
      await pump(tester, record: chitraRecord);
      await open(tester, 'studentCertificate.set');
      await tester.enterText(find.byKey(const Key('studentCertificate.field')), 'x' * 60);
      await tester.pump();
      expect(
        field(tester, 'studentCertificate.field').controller!.text,
        hasLength(50),
      );
    });

    testWidgets('shows progress and leaves the field alone while it is on its way', (tester) async {
      final reply = Completer<IdentitySaved>();
      when(() => students.setBirthCertificate(any(), any())).thenAnswer((_) => reply.future);
      await pump(tester, record: chitraRecord);
      await open(tester, 'studentCertificate.set');
      await tester.enterText(find.byKey(const Key('studentCertificate.field')), 'BC-1');
      await tester.tap(find.byKey(const Key('studentCertificate.save')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(button(tester, 'studentCertificate.save').loading, isTrue);
      expect(field(tester, 'studentCertificate.field').enabled, isFalse);
      reply.complete(const IdentitySaved(StudentIdentity(birthCertificateNumber: 'BC-1')));
      await tester.pumpAndSettle();
    });

    testWidgets('says why in the sheet when it is refused, and keeps the sheet and the number', (tester) async {
      when(() => students.setBirthCertificate(any(), any())).thenThrow(const ApiFailure.network());
      await pump(tester);
      await open(tester, 'studentCertificate.set');
      await tester.enterText(find.byKey(const Key('studentCertificate.field')), 'BC-1');
      await tester.tap(find.byKey(const Key('studentCertificate.save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('studentCertificate.saveError')), findsOneWidget);
      // The card behind says nothing of it.
      expect(find.byKey(const Key('studentCertificate.error')), findsNothing);
      expect(find.text('Birth certificate number saved'), findsNothing);
    });

    testWidgets('does not repeat in the card a refusal the sheet said, once the sheet is closed', (tester) async {
      when(() => students.setBirthCertificate(any(), any())).thenThrow(const ApiFailure.network());
      await pump(tester);
      await open(tester, 'studentCertificate.set');
      await tester.enterText(find.byKey(const Key('studentCertificate.field')), 'BC-1');
      await tester.tap(find.byKey(const Key('studentCertificate.save')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('studentCertificate.field')), findsNothing);
      expect(find.byKey(const Key('studentCertificate.error')), findsNothing);
      expect(find.text(certificate), findsOneWidget);
    });

    testWidgets('says in the card why it was refused when the sheet was closed meanwhile', (tester) async {
      final reply = Completer<IdentitySaved>();
      when(() => students.setBirthCertificate(any(), any())).thenAnswer((_) => reply.future);
      await pump(tester);
      await open(tester, 'studentCertificate.set');
      await tester.enterText(find.byKey(const Key('studentCertificate.field')), 'BC-1');
      await tester.tap(find.byKey(const Key('studentCertificate.save')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      reply.completeError(const ApiFailure.network());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('studentCertificate.error')), findsOneWidget);
      expect(find.text(certificate), findsOneWidget);
    });

    testWidgets('is cleared only once the person confirms, and then says so', (tester) async {
      when(() => students.setBirthCertificate('p1', null)).thenAnswer(
        (_) async => const IdentitySaved(StudentIdentity(aadhaarMasked: masked)),
      );
      await pump(tester);
      await open(tester, 'studentCertificate.clear');
      expect(find.text('Clear the birth certificate number of Asha Rao?'), findsOneWidget);
      verifyNever(() => students.setBirthCertificate(any(), any()));
      expect(
        tester
            .widget<AppButton>(find.descendant(of: find.byType(Dialog), matching: find.byType(AppButton)).last)
            .variant,
        AppButtonVariant.danger,
      );
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Clear number')));
      await tester.pumpAndSettle();
      verify(() => students.setBirthCertificate('p1', null)).called(1);
      expect(find.text('Not set'), findsOneWidget);
      expect(find.text('Birth certificate number cleared'), findsOneWidget);
    });

    testWidgets('is left as it is when the person cancels the clear', (tester) async {
      await pump(tester);
      await open(tester, 'studentCertificate.clear');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => students.setBirthCertificate(any(), any()));
      expect(find.text(certificate), findsOneWidget);
    });

    testWidgets('says why under the number when a clear is refused, and keeps the number', (tester) async {
      when(() => students.setBirthCertificate(any(), any())).thenThrow(
        const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'),
      );
      await pump(tester);
      await open(tester, 'studentCertificate.clear');
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Clear number')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('studentCertificate.error')), findsOneWidget);
      expect(find.text('This student could not be found. They may have been deactivated.'), findsOneWidget);
      expect(find.text(certificate), findsOneWidget);
      expect(find.text('Birth certificate number cleared'), findsNothing);
    });

    testWidgets('cannot be changed again while a clear is on its way', (tester) async {
      final reply = Completer<IdentitySaved>();
      when(() => students.setBirthCertificate(any(), any())).thenAnswer((_) => reply.future);
      await pump(tester);
      await open(tester, 'studentCertificate.clear');
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Clear number')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(button(tester, 'studentCertificate.clear').loading, isTrue);
      expect(button(tester, 'studentCertificate.set').onPressed, isNull);
      reply.complete(const IdentitySaved(StudentIdentity()));
      await tester.pumpAndSettle();
    });
  });
}
