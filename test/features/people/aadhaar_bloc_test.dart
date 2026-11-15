import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/aadhaar_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockStaffRepository staff;

  const masked = 'XXXX XXXX 1234';
  const number = '234567890123';
  const invalid = ApiFailure(statusCode: 422, code: 'INVALID_AADHAAR', message: 'x');

  setUp(() => staff = MockStaffRepository());

  AadhaarBloc build({String? held = masked, bool elsewhere = false}) => AadhaarBloc(
    save: (aadhaar) async => (masked: await staff.setAadhaar('f1', aadhaar), elsewhere: elsewhere),
    reveal: (reason) => staff.revealAadhaar('f1', reason: reason),
    masked: held,
  );

  group('saving a number', () {
    blocTest<AadhaarBloc, AadhaarState>(
      'sends it and shows the masked number the API answers with',
      setUp: () => when(() => staff.setAadhaar('f1', number)).thenAnswer((_) async => 'XXXX XXXX 0123'),
      build: build,
      act: (bloc) => bloc.add(const AadhaarSaved(number)),
      expect: () => [
        const AadhaarWorking(masked, AadhaarAction.save),
        const AadhaarIdle('XXXX XXXX 0123'),
      ],
    );

    blocTest<AadhaarBloc, AadhaarState>(
      'says when another Institution of the Society holds the number too',
      setUp: () => when(() => staff.setAadhaar('f1', number)).thenAnswer((_) async => 'XXXX XXXX 0123'),
      build: () => build(elsewhere: true),
      act: (bloc) => bloc.add(const AadhaarSaved(number)),
      expect: () => [
        const AadhaarWorking(masked, AadhaarAction.save),
        const AadhaarIdle('XXXX XXXX 0123', elsewhere: true),
      ],
    );

    blocTest<AadhaarBloc, AadhaarState>(
      'keeps the number it had, and says why, when it is refused',
      setUp: () => when(() => staff.setAadhaar(any(), any())).thenThrow(invalid),
      build: build,
      act: (bloc) => bloc.add(const AadhaarSaved(number)),
      expect: () => [
        const AadhaarWorking(masked, AadhaarAction.save),
        const AadhaarRefused(masked, AadhaarAction.save, invalid, inSheet: true),
      ],
    );

    blocTest<AadhaarBloc, AadhaarState>(
      'sets the first number of a staff member who had none',
      setUp: () => when(() => staff.setAadhaar('f1', number)).thenAnswer((_) async => masked),
      build: () => build(held: null),
      act: (bloc) => bloc.add(const AadhaarSaved(number)),
      expect: () => [
        const AadhaarWorking(null, AadhaarAction.save),
        const AadhaarIdle(masked),
      ],
    );
  });

  group('clearing the number', () {
    blocTest<AadhaarBloc, AadhaarState>(
      'sends null and shows none',
      setUp: () => when(() => staff.setAadhaar('f1', null)).thenAnswer((_) async => null),
      build: build,
      act: (bloc) => bloc.add(const AadhaarCleared()),
      expect: () => [
        const AadhaarWorking(masked, AadhaarAction.clear),
        const AadhaarIdle(null),
      ],
    );

    blocTest<AadhaarBloc, AadhaarState>(
      'keeps the number, and says why, when it is refused',
      setUp: () => when(() => staff.setAadhaar(any(), any())).thenThrow(const ApiFailure.network()),
      build: build,
      act: (bloc) => bloc.add(const AadhaarCleared()),
      expect: () => [
        const AadhaarWorking(masked, AadhaarAction.clear),
        const AadhaarRefused(masked, AadhaarAction.clear, ApiFailure.network(), inSheet: false),
      ],
    );
  });

  group('revealing the number', () {
    blocTest<AadhaarBloc, AadhaarState>(
      'sends the reason and holds the whole number until it is hidden',
      setUp: () =>
          when(() => staff.revealAadhaar('f1', reason: 'Checking the records')).thenAnswer((_) async => number),
      build: build,
      act: (bloc) async {
        bloc.add(const AadhaarRevealed('Checking the records'));
        await pumpEventQueue();
        bloc.add(const AadhaarHidden());
      },
      expect: () => [
        const AadhaarWorking(masked, AadhaarAction.reveal),
        const AadhaarShown(masked, number),
        const AadhaarIdle(masked),
      ],
    );

    blocTest<AadhaarBloc, AadhaarState>(
      'says why when it is refused, and keeps the number masked',
      setUp: () => when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenThrow(
        const ApiFailure(statusCode: 429, code: 'REVEAL_LIMIT', message: 'x'),
      ),
      build: build,
      act: (bloc) => bloc.add(const AadhaarRevealed('Checking the records')),
      expect: () => [
        const AadhaarWorking(masked, AadhaarAction.reveal),
        const AadhaarRefused(
          masked,
          AadhaarAction.reveal,
          ApiFailure(statusCode: 429, code: 'REVEAL_LIMIT', message: 'x'),
          inSheet: true,
        ),
      ],
    );

    blocTest<AadhaarBloc, AadhaarState>(
      'shows none when the API says no number is set, as the screen was behind',
      setUp: () => when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenThrow(
        const ApiFailure(statusCode: 404, code: 'NOT_SET', message: 'x'),
      ),
      build: build,
      act: (bloc) => bloc.add(const AadhaarRevealed('Checking the records')),
      expect: () => [
        const AadhaarWorking(masked, AadhaarAction.reveal),
        const AadhaarRefused(
          null,
          AadhaarAction.reveal,
          ApiFailure(statusCode: 404, code: 'NOT_SET', message: 'x'),
          inSheet: true,
        ),
      ],
    );
  });

  group('a sheet closed while its call is on its way', () {
    test('does not keep the whole number that comes back, and has nothing to show when asked again', () async {
      final held = Completer<String>();
      when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenAnswer((_) => held.future);
      final bloc = build();
      addTearDown(bloc.close);
      final states = <AadhaarState>[];
      bloc.stream.listen(states.add);
      bloc.add(const AadhaarRevealed('Checking the records'));
      await bloc.stream.firstWhere((state) => state is AadhaarWorking);
      bloc.add(const AadhaarHidden());
      await pumpEventQueue();
      held.complete(number);
      await pumpEventQueue();
      expect(bloc.state, const AadhaarIdle(masked));
      expect(states.whereType<AadhaarShown>(), isEmpty);
    });

    test('forgets that it was closed once the next call starts, so that sheet gets its number', () async {
      final held = Completer<String>();
      when(() => staff.revealAadhaar('f1', reason: 'First reason here')).thenAnswer((_) => held.future);
      when(() => staff.revealAadhaar('f1', reason: 'Checking the records')).thenAnswer((_) async => number);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const AadhaarRevealed('First reason here'));
      await bloc.stream.firstWhere((state) => state is AadhaarWorking);
      bloc.add(const AadhaarHidden());
      await pumpEventQueue();
      held.complete(number);
      await pumpEventQueue();
      bloc.add(const AadhaarRevealed('Checking the records'));
      await bloc.stream.firstWhere((state) => state is AadhaarShown);
      expect(bloc.state, const AadhaarShown(masked, number));
    });

    test('says a refusal on the card, as there is no sheet to say it', () async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const AadhaarSaved(number));
      await bloc.stream.firstWhere((state) => state is AadhaarWorking);
      bloc.add(const AadhaarHidden());
      await pumpEventQueue();
      held.completeError(invalid);
      await bloc.stream.firstWhere((state) => state is AadhaarRefused);
      expect(bloc.state, const AadhaarRefused(masked, AadhaarAction.save, invalid, inSheet: false));
    });

    test('is forgotten once the next save starts, so a refusal there is said in its sheet', () async {
      final held = Completer<String?>();
      var sent = 0;
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) {
        if (sent++ == 0) return held.future;
        throw invalid;
      });
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const AadhaarSaved(number));
      await bloc.stream.firstWhere((state) => state is AadhaarWorking);
      bloc.add(const AadhaarHidden());
      await pumpEventQueue();
      held.complete(masked);
      await pumpEventQueue();
      bloc.add(const AadhaarSaved(number));
      await bloc.stream.firstWhere((state) => state is AadhaarRefused);
      expect(bloc.state, const AadhaarRefused(masked, AadhaarAction.save, invalid, inSheet: true));
    });

    test('keeps a masked number that went through, as the card shows it', () async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const AadhaarSaved(number));
      await bloc.stream.firstWhere((state) => state is AadhaarWorking);
      bloc.add(const AadhaarHidden());
      await pumpEventQueue();
      held.complete('XXXX XXXX 0123');
      await pumpEventQueue();
      expect(bloc.state, const AadhaarIdle('XXXX XXXX 0123'));
    });
  });

  group('hiding', () {
    test('forgets a refusal', () async {
      when(() => staff.setAadhaar(any(), any())).thenThrow(invalid);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const AadhaarSaved(number));
      await bloc.stream.firstWhere((state) => state is AadhaarRefused);
      bloc.add(const AadhaarHidden());
      await bloc.stream.firstWhere((state) => state is AadhaarIdle);
      expect(bloc.state.masked, masked);
    });

    test('does nothing while a change is on its way, or when nothing is shown', () async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const AadhaarHidden());
      await pumpEventQueue();
      expect(bloc.state, const AadhaarIdle(masked));
      bloc.add(const AadhaarSaved(number));
      await bloc.stream.firstWhere((state) => state is AadhaarWorking);
      bloc.add(const AadhaarHidden());
      await pumpEventQueue();
      expect(bloc.state, const AadhaarWorking(masked, AadhaarAction.save));
      held.complete(masked);
    });
  });

  test('sends nothing while another change is on its way', () async {
    final held = Completer<String?>();
    when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
    final bloc = build();
    addTearDown(bloc.close);
    bloc.add(const AadhaarSaved(number));
    await bloc.stream.firstWhere((state) => state is AadhaarWorking);
    bloc
      ..add(const AadhaarCleared())
      ..add(const AadhaarRevealed('Checking the records'));
    await pumpEventQueue();
    verify(() => staff.setAadhaar(any(), any())).called(1);
    verifyNever(() => staff.revealAadhaar(any(), reason: any(named: 'reason')));
    held.complete(masked);
  });
}
