import 'dart:async';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_identity_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_identity_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/screen_protection.dart';

void main() {
  late MockStaffRepository staff;
  late RecordingScreenProtection protection;

  const masked = 'XXXX XXXX 1234';
  const number = '234567890123';
  const reason = 'Checking the records';

  setUp(() {
    staff = MockStaffRepository();
    protection = RecordingScreenProtection();
  });

  Future<StaffIdentityBloc> pump(
    WidgetTester tester, {
    String? held = masked,
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) async {
    final bloc = StaffIdentityBloc(staff, staffMemberId: 'f1', masked: held);
    addTearDown(bloc.close);
    await tester.pumpAppScaled(
      BlocProvider.value(
        value: bloc,
        child: Scaffold(
          body: SingleChildScrollView(
            child: StaffIdentitySection(memberName: 'Kavya Nair', protection: protection),
          ),
        ),
      ),
      textScale: textScale,
      size: size,
    );
    return bloc;
  }

  AppButton button(WidgetTester tester, String key) => tester.widget<AppButton>(find.byKey(Key('staffIdentity.$key')));

  Future<void> open(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key('staffIdentity.$key')));
    await tester.pumpAndSettle();
  }

  group('the number', () {
    testWidgets('is shown masked, with ways to show it whole, change it and clear it', (tester) async {
      await pump(tester);
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text(masked), findsOneWidget);
      expect(find.text('Show full number'), findsOneWidget);
      expect(find.text('Change number'), findsOneWidget);
      expect(find.text('Clear number'), findsOneWidget);
    });

    testWidgets('is said to be not set, with only a way to set it', (tester) async {
      await pump(tester, held: null);
      expect(find.text('Not set'), findsOneWidget);
      expect(find.text('Set number'), findsOneWidget);
      expect(find.byKey(const Key('staffIdentity.reveal')), findsNothing);
      expect(find.byKey(const Key('staffIdentity.clear')), findsNothing);
    });
  });

  group('clearing', () {
    testWidgets('is asked in red, and sent only once the person confirms, and then says so', (tester) async {
      when(() => staff.setAadhaar('f1', null)).thenAnswer((_) async => null);
      await pump(tester);
      await open(tester, 'clear');
      expect(find.text('Clear the Aadhaar number of Kavya Nair?'), findsOneWidget);
      final confirm = find.descendant(of: find.byType(Dialog), matching: find.byType(AppButton)).last;
      expect(tester.widget<AppButton>(confirm).variant, AppButtonVariant.danger);
      verifyNever(() => staff.setAadhaar(any(), any()));
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Clear number')));
      await tester.pumpAndSettle();
      verify(() => staff.setAadhaar('f1', null)).called(1);
      expect(find.text('Not set'), findsOneWidget);
      expect(find.text('Aadhaar number cleared'), findsOneWidget);
    });

    testWidgets('is left as it is when the person cancels', (tester) async {
      await pump(tester);
      await open(tester, 'clear');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => staff.setAadhaar(any(), any()));
      expect(find.text(masked), findsOneWidget);
    });

    testWidgets('shows progress while it is on its way, and offers nothing else meanwhile', (tester) async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar('f1', null)).thenAnswer((_) => held.future);
      await pump(tester);
      await open(tester, 'clear');
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Clear number')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(button(tester, 'clear').loading, isTrue);
      expect(button(tester, 'set').onPressed, isNull);
      expect(button(tester, 'reveal').onPressed, isNull);
      held.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('says why under the number when it is refused, and keeps the number', (tester) async {
      when(() => staff.setAadhaar('f1', null)).thenThrow(const ApiFailure.network());
      await pump(tester);
      await open(tester, 'clear');
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Clear number')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staffIdentity.error')), findsOneWidget);
      expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
      expect(find.text(masked), findsOneWidget);
      expect(find.text('Aadhaar number cleared'), findsNothing);
    });
  });

  group('setting a number', () {
    testWidgets('sends the twelve digits however they were typed, closes, and says so', (tester) async {
      when(() => staff.setAadhaar('f1', number)).thenAnswer((_) async => 'XXXX XXXX 0123');
      await pump(tester, held: null);
      await open(tester, 'set');
      await tester.enterText(find.byKey(const Key('staffIdentity.aadhaar')), '2345 6789-0123');
      await tester.tap(find.byKey(const Key('staffIdentity.save')));
      await tester.pumpAndSettle();
      verify(() => staff.setAadhaar('f1', number)).called(1);
      expect(find.byKey(const Key('staffIdentity.aadhaar')), findsNothing);
      expect(find.text('XXXX XXXX 0123'), findsOneWidget);
      expect(find.text('Aadhaar number saved'), findsOneWidget);
    });

    testWidgets('asks for twelve digits, and sends nothing, when what was typed is not a number', (tester) async {
      await pump(tester, held: null);
      await open(tester, 'set');
      for (final typed in ['', '2345 6789 012', '1345 6789 0123']) {
        await tester.enterText(find.byKey(const Key('staffIdentity.aadhaar')), typed);
        await tester.tap(find.byKey(const Key('staffIdentity.save')));
        await tester.pump();
        expect(find.text('Check the twelve digits.'), findsOneWidget, reason: typed);
      }
      verifyNever(() => staff.setAadhaar(any(), any()));
    });

    testWidgets('takes only digits, spaces and hyphens, and no more than fourteen characters', (tester) async {
      await pump(tester, held: null);
      await open(tester, 'set');
      await tester.enterText(find.byKey(const Key('staffIdentity.aadhaar')), 'ab2345 6789 0123 99');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '2345 6789 0123');
    });

    for (final (failure, words) in [
      (
        const ApiFailure(statusCode: 422, code: 'INVALID_AADHAAR', message: 'server words'),
        'This is not a valid Aadhaar number. Check the twelve digits.',
      ),
      (
        const ApiFailure(statusCode: 409, code: 'AADHAAR_EXISTS_IN_SOCIETY', message: 'server words'),
        'This Aadhaar number is already recorded for someone in this Society.',
      ),
      (const ApiFailure.network(), "Can't reach the server. Check your connection and try again."),
    ]) {
      testWidgets('says ${failure.code} in the sheet, and keeps it open with the number typed', (tester) async {
        when(() => staff.setAadhaar(any(), any())).thenThrow(failure);
        await pump(tester, held: null);
        await open(tester, 'set');
        await tester.enterText(find.byKey(const Key('staffIdentity.aadhaar')), number);
        await tester.tap(find.byKey(const Key('staffIdentity.save')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('staffIdentity.saveError')), findsOneWidget);
        expect(find.text(words), findsOneWidget);
        expect(find.text('server words'), findsNothing);
        expect(find.text(number), findsOneWidget);
      });
    }

    testWidgets('shows progress and leaves the field alone while it is on its way', (tester) async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      await pump(tester, held: null);
      await open(tester, 'set');
      await tester.enterText(find.byKey(const Key('staffIdentity.aadhaar')), number);
      await tester.tap(find.byKey(const Key('staffIdentity.save')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(button(tester, 'save').loading, isTrue);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      held.complete(masked);
      await tester.pumpAndSettle();
    });

    testWidgets('forgets a refusal when the sheet is closed', (tester) async {
      when(() => staff.setAadhaar(any(), any())).thenThrow(const ApiFailure.network());
      final bloc = await pump(tester, held: null);
      await open(tester, 'set');
      await tester.enterText(find.byKey(const Key('staffIdentity.aadhaar')), number);
      await tester.tap(find.byKey(const Key('staffIdentity.save')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(bloc.state, const StaffIdentityIdle(null));
    });
  });

  group('showing the whole number', () {
    testWidgets('asks for a reason of at least ten characters, and sends nothing without one', (tester) async {
      await pump(tester);
      await open(tester, 'reveal');
      expect(find.text('Show Aadhaar number'), findsOneWidget);
      for (final typed in ['', 'too short', '         short    ']) {
        await tester.enterText(find.byKey(const Key('staffIdentity.reason')), typed);
        await tester.tap(find.byKey(const Key('staffIdentity.show')));
        await tester.pump();
        expect(find.text('At least 10 characters.'), findsOneWidget, reason: typed);
      }
      verifyNever(() => staff.revealAadhaar(any(), reason: any(named: 'reason')));
    });

    testWidgets('takes no more than 500 characters of the reason', (tester) async {
      await pump(tester);
      await open(tester, 'reveal');
      await tester.enterText(find.byKey(const Key('staffIdentity.reason')), 'x' * 600);
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, hasLength(500));
    });

    testWidgets('sends the reason, shows the number in groups with a note, and hides it again once done', (
      tester,
    ) async {
      when(() => staff.revealAadhaar('f1', reason: reason)).thenAnswer((_) async => number);
      final bloc = await pump(tester);
      await open(tester, 'reveal');
      await tester.enterText(find.byKey(const Key('staffIdentity.reason')), '  $reason ');
      await tester.tap(find.byKey(const Key('staffIdentity.show')));
      await tester.pumpAndSettle();
      verify(() => staff.revealAadhaar('f1', reason: reason)).called(1);
      expect(find.text('2345 6789 0123'), findsOneWidget);
      expect(find.text('This is hidden again when you close it.'), findsOneWidget);
      expect(find.byKey(const Key('staffIdentity.reason')), findsNothing);
      await tester.tap(find.byKey(const Key('staffIdentity.done')));
      await tester.pumpAndSettle();
      expect(find.text('2345 6789 0123'), findsNothing);
      expect(find.text(masked), findsOneWidget);
      expect(bloc.state, const StaffIdentityIdle(masked));
      expect(find.text('Aadhaar number saved'), findsNothing);
    });

    testWidgets('hides the number when the sheet is dismissed another way', (tester) async {
      when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenAnswer((_) async => number);
      final bloc = await pump(tester);
      await open(tester, 'reveal');
      await tester.enterText(find.byKey(const Key('staffIdentity.reason')), reason);
      await tester.tap(find.byKey(const Key('staffIdentity.show')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(bloc.state, const StaffIdentityIdle(masked));
    });

    for (final (failure, words) in [
      (
        const ApiFailure(statusCode: 429, code: 'REVEAL_LIMIT', message: 'server words'),
        "You have reached today's limit of ten reveals. Try again tomorrow.",
      ),
      (
        const ApiFailure(statusCode: 404, code: 'NOT_SET', message: 'server words'),
        'No Aadhaar number is set for them.',
      ),
      (const ApiFailure.network(), "Can't reach the server. Check your connection and try again."),
    ]) {
      testWidgets('says ${failure.code} in the sheet, in words', (tester) async {
        when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenThrow(failure);
        await pump(tester);
        await open(tester, 'reveal');
        await tester.enterText(find.byKey(const Key('staffIdentity.reason')), reason);
        await tester.tap(find.byKey(const Key('staffIdentity.show')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('staffIdentity.revealError')), findsOneWidget);
        expect(find.text(words), findsOneWidget);
        expect(find.text('server words'), findsNothing);
      });
    }

    testWidgets('shows progress while it is on its way', (tester) async {
      final held = Completer<String>();
      when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenAnswer((_) => held.future);
      await pump(tester);
      await open(tester, 'reveal');
      await tester.enterText(find.byKey(const Key('staffIdentity.reason')), reason);
      await tester.tap(find.byKey(const Key('staffIdentity.show')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(button(tester, 'show').loading, isTrue);
      held.complete(number);
      await tester.pumpAndSettle();
    });
  });

  group('the screen while the whole number is shown', () {
    Future<void> reveal(WidgetTester tester) async {
      await open(tester, 'reveal');
      await tester.enterText(find.byKey(const Key('staffIdentity.reason')), reason);
      await tester.tap(find.byKey(const Key('staffIdentity.show')));
      await tester.pumpAndSettle();
    }

    setUp(() => when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenAnswer((_) async => number));

    testWidgets('is kept out of screenshots once the number shows, and let go of on Done', (tester) async {
      await pump(tester);
      expect(protection.changes, isEmpty);
      await reveal(tester);
      expect(find.text('2345 6789 0123'), findsOneWidget);
      expect(protection.isOn, isTrue);
      await tester.tap(find.byKey(const Key('staffIdentity.done')));
      await tester.pumpAndSettle();
      expect(protection.changes, ['protect', 'release']);
    });

    testWidgets('is let go of when the sheet is swiped away', (tester) async {
      await pump(tester);
      await reveal(tester);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(protection.changes, ['protect', 'release']);
    });

    testWidgets('is let go of when the profile is left with the sheet open', (tester) async {
      await pump(tester);
      await reveal(tester);
      expect(protection.isOn, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(protection.isOn, isFalse);
    });

    testWidgets('is on from the moment the number is asked for, and off again when the sheet closes before it comes', (
      tester,
    ) async {
      final held = Completer<String>();
      when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenAnswer((_) => held.future);
      await pump(tester);
      await open(tester, 'reveal');
      await tester.enterText(find.byKey(const Key('staffIdentity.reason')), reason);
      await tester.tap(find.byKey(const Key('staffIdentity.show')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(protection.isOn, isTrue);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      held.complete(number);
      await tester.pumpAndSettle();
      expect(protection.changes, ['protect', 'release']);
    });

    testWidgets('is left alone when the reason is refused, and by the other sheets', (tester) async {
      when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenThrow(const ApiFailure.network());
      await pump(tester);
      await reveal(tester);
      expect(find.byKey(const Key('staffIdentity.revealError')), findsOneWidget);
      expect(protection.changes, ['protect', 'release']);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      protection.changes.clear();
      await open(tester, 'set');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(protection.changes, isEmpty);
    });
  });

  group('a sheet closed while its call is on its way', () {
    testWidgets('does not keep the whole number, and the next Show asks for a reason again', (tester) async {
      final held = Completer<String>();
      when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenAnswer((_) => held.future);
      final bloc = await pump(tester);
      await open(tester, 'reveal');
      await tester.enterText(find.byKey(const Key('staffIdentity.reason')), reason);
      await tester.tap(find.byKey(const Key('staffIdentity.show')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      held.complete(number);
      await tester.pumpAndSettle();
      expect(bloc.state, const StaffIdentityIdle(masked));
      expect(find.text('Aadhaar number saved'), findsNothing);
      await open(tester, 'reveal');
      expect(find.byKey(const Key('staffIdentity.reason')), findsOneWidget);
      expect(find.text('2345 6789 0123'), findsNothing);
      verify(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).called(1);
    });

    testWidgets('says a refusal of a save on the card, and the next Set sheet opens clean', (tester) async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      await pump(tester, held: null);
      await open(tester, 'set');
      await tester.enterText(find.byKey(const Key('staffIdentity.aadhaar')), number);
      await tester.tap(find.byKey(const Key('staffIdentity.save')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      held.completeError(
        const ApiFailure(statusCode: 409, code: 'AADHAAR_EXISTS_IN_SOCIETY', message: 'server words'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staffIdentity.error')), findsOneWidget);
      expect(find.text('This Aadhaar number is already recorded for someone in this Society.'), findsOneWidget);
      await open(tester, 'set');
      expect(find.byKey(const Key('staffIdentity.saveError')), findsNothing);
      expect(find.text(number), findsNothing);
    });

    testWidgets('says a refusal of a reveal on the card too', (tester) async {
      final held = Completer<String>();
      when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenAnswer((_) => held.future);
      await pump(tester);
      await open(tester, 'reveal');
      await tester.enterText(find.byKey(const Key('staffIdentity.reason')), reason);
      await tester.tap(find.byKey(const Key('staffIdentity.show')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      held.completeError(const ApiFailure(statusCode: 429, code: 'REVEAL_LIMIT', message: 'server words'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staffIdentity.error')), findsOneWidget);
      expect(find.byKey(const Key('staffIdentity.revealError')), findsNothing);
      await open(tester, 'reveal');
      expect(find.byKey(const Key('staffIdentity.reason')), findsOneWidget);
      expect(find.byKey(const Key('staffIdentity.revealError')), findsNothing);
    });

    testWidgets('says a save that went through after the sheet closed', (tester) async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      await pump(tester, held: null);
      await open(tester, 'set');
      await tester.enterText(find.byKey(const Key('staffIdentity.aadhaar')), number);
      await tester.tap(find.byKey(const Key('staffIdentity.save')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      held.complete(masked);
      await tester.pumpAndSettle();
      expect(find.text('Aadhaar number saved'), findsOneWidget);
      expect(find.text(masked), findsOneWidget);
    });
  });

  testWidgets('reads whole at a large text scale on a small phone, with the sheet open', (tester) async {
    await pump(tester, textScale: 2, size: const Size(320, 3000));
    await open(tester, 'reveal');
    await tester.enterText(find.byKey(const Key('staffIdentity.reason')), 'x');
    await tester.tap(find.byKey(const Key('staffIdentity.show')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });

  testWidgets('reads whole at a large text scale on a small phone, with the number sheet open', (tester) async {
    when(() => staff.setAadhaar(any(), any())).thenThrow(
      const ApiFailure(statusCode: 409, code: 'AADHAAR_EXISTS_IN_SOCIETY', message: 'x'),
    );
    await pump(tester, held: null, textScale: 2, size: const Size(320, 3000));
    await open(tester, 'set');
    await tester.enterText(find.byKey(const Key('staffIdentity.aadhaar')), number);
    await tester.tap(find.byKey(const Key('staffIdentity.save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staffIdentity.saveError')), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
