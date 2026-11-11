import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_identity_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockStaffRepository staff;

  const masked = 'XXXX XXXX 1234';
  const number = '234567890123';
  const invalid = ApiFailure(statusCode: 422, code: 'INVALID_AADHAAR', message: 'x');

  setUp(() => staff = MockStaffRepository());

  StaffIdentityBloc build({String? held = masked}) => StaffIdentityBloc(staff, staffMemberId: 'f1', masked: held);

  group('saving a number', () {
    blocTest<StaffIdentityBloc, StaffIdentityState>(
      'sends it and shows the masked number the API answers with',
      setUp: () => when(() => staff.setAadhaar('f1', number)).thenAnswer((_) async => 'XXXX XXXX 0123'),
      build: build,
      act: (bloc) => bloc.add(const StaffAadhaarSaved(number)),
      expect: () => [
        const StaffIdentityWorking(masked, StaffIdentityAction.save),
        const StaffIdentityIdle('XXXX XXXX 0123'),
      ],
    );

    blocTest<StaffIdentityBloc, StaffIdentityState>(
      'keeps the number it had, and says why, when it is refused',
      setUp: () => when(() => staff.setAadhaar(any(), any())).thenThrow(invalid),
      build: build,
      act: (bloc) => bloc.add(const StaffAadhaarSaved(number)),
      expect: () => [
        const StaffIdentityWorking(masked, StaffIdentityAction.save),
        const StaffIdentityRefused(masked, StaffIdentityAction.save, invalid),
      ],
    );

    blocTest<StaffIdentityBloc, StaffIdentityState>(
      'sets the first number of a staff member who had none',
      setUp: () => when(() => staff.setAadhaar('f1', number)).thenAnswer((_) async => masked),
      build: () => build(held: null),
      act: (bloc) => bloc.add(const StaffAadhaarSaved(number)),
      expect: () => [
        const StaffIdentityWorking(null, StaffIdentityAction.save),
        const StaffIdentityIdle(masked),
      ],
    );
  });

  group('clearing the number', () {
    blocTest<StaffIdentityBloc, StaffIdentityState>(
      'sends null and shows none',
      setUp: () => when(() => staff.setAadhaar('f1', null)).thenAnswer((_) async => null),
      build: build,
      act: (bloc) => bloc.add(const StaffAadhaarCleared()),
      expect: () => [
        const StaffIdentityWorking(masked, StaffIdentityAction.clear),
        const StaffIdentityIdle(null),
      ],
    );

    blocTest<StaffIdentityBloc, StaffIdentityState>(
      'keeps the number, and says why, when it is refused',
      setUp: () => when(() => staff.setAadhaar(any(), any())).thenThrow(const ApiFailure.network()),
      build: build,
      act: (bloc) => bloc.add(const StaffAadhaarCleared()),
      expect: () => [
        const StaffIdentityWorking(masked, StaffIdentityAction.clear),
        const StaffIdentityRefused(masked, StaffIdentityAction.clear, ApiFailure.network()),
      ],
    );
  });

  group('revealing the number', () {
    blocTest<StaffIdentityBloc, StaffIdentityState>(
      'sends the reason and holds the whole number until it is hidden',
      setUp: () =>
          when(() => staff.revealAadhaar('f1', reason: 'Checking the records')).thenAnswer((_) async => number),
      build: build,
      act: (bloc) async {
        bloc.add(const StaffAadhaarRevealed('Checking the records'));
        await pumpEventQueue();
        bloc.add(const StaffIdentityHidden());
      },
      expect: () => [
        const StaffIdentityWorking(masked, StaffIdentityAction.reveal),
        const StaffIdentityRevealed(masked, number),
        const StaffIdentityIdle(masked),
      ],
    );

    blocTest<StaffIdentityBloc, StaffIdentityState>(
      'says why when it is refused, and keeps the number masked',
      setUp: () => when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenThrow(
        const ApiFailure(statusCode: 429, code: 'REVEAL_LIMIT', message: 'x'),
      ),
      build: build,
      act: (bloc) => bloc.add(const StaffAadhaarRevealed('Checking the records')),
      expect: () => [
        const StaffIdentityWorking(masked, StaffIdentityAction.reveal),
        const StaffIdentityRefused(
          masked,
          StaffIdentityAction.reveal,
          ApiFailure(statusCode: 429, code: 'REVEAL_LIMIT', message: 'x'),
        ),
      ],
    );

    blocTest<StaffIdentityBloc, StaffIdentityState>(
      'shows none when the API says no number is set, as the screen was behind',
      setUp: () => when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenThrow(
        const ApiFailure(statusCode: 404, code: 'NOT_SET', message: 'x'),
      ),
      build: build,
      act: (bloc) => bloc.add(const StaffAadhaarRevealed('Checking the records')),
      expect: () => [
        const StaffIdentityWorking(masked, StaffIdentityAction.reveal),
        const StaffIdentityRefused(
          null,
          StaffIdentityAction.reveal,
          ApiFailure(statusCode: 404, code: 'NOT_SET', message: 'x'),
        ),
      ],
    );
  });

  group('hiding', () {
    test('forgets a refusal', () async {
      when(() => staff.setAadhaar(any(), any())).thenThrow(invalid);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const StaffAadhaarSaved(number));
      await bloc.stream.firstWhere((state) => state is StaffIdentityRefused);
      bloc.add(const StaffIdentityHidden());
      await bloc.stream.firstWhere((state) => state is StaffIdentityIdle);
      expect(bloc.state.masked, masked);
    });

    test('does nothing while a change is on its way, or when nothing is shown', () async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const StaffIdentityHidden());
      await pumpEventQueue();
      expect(bloc.state, const StaffIdentityIdle(masked));
      bloc.add(const StaffAadhaarSaved(number));
      await bloc.stream.firstWhere((state) => state is StaffIdentityWorking);
      bloc.add(const StaffIdentityHidden());
      await pumpEventQueue();
      expect(bloc.state, const StaffIdentityWorking(masked, StaffIdentityAction.save));
      held.complete(masked);
    });
  });

  test('sends nothing while another change is on its way', () async {
    final held = Completer<String?>();
    when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
    final bloc = build();
    addTearDown(bloc.close);
    bloc.add(const StaffAadhaarSaved(number));
    await bloc.stream.firstWhere((state) => state is StaffIdentityWorking);
    bloc
      ..add(const StaffAadhaarCleared())
      ..add(const StaffAadhaarRevealed('Checking the records'));
    await pumpEventQueue();
    verify(() => staff.setAadhaar(any(), any())).called(1);
    verifyNever(() => staff.revealAadhaar(any(), reason: any(named: 'reason')));
    held.complete(masked);
  });
}
