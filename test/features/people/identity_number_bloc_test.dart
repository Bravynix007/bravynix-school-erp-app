import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/identity_number_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockStaffRepository staff;

  const masked = 'XXXX XXXX 1234';
  const number = '234567890123';
  const invalid = ApiFailure(statusCode: 422, code: 'INVALID_AADHAAR', message: 'x');

  setUp(() => staff = MockStaffRepository());

  IdentityNumberBloc build({String? held = masked, bool elsewhere = false}) => IdentityNumberBloc(
    save: (aadhaar) async => (number: await staff.setAadhaar('f1', aadhaar), elsewhere: elsewhere),
    reveal: (reason) => staff.revealAadhaar('f1', reason: reason),
    number: held,
  );

  group('saving a number', () {
    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'sends it and shows the masked number the API answers with',
      setUp: () => when(() => staff.setAadhaar('f1', number)).thenAnswer((_) async => 'XXXX XXXX 0123'),
      build: build,
      act: (bloc) => bloc.add(const IdentityNumberSaved(number)),
      expect: () => [
        const IdentityNumberWorking(masked, IdentityNumberAction.save),
        const IdentityNumberIdle('XXXX XXXX 0123'),
      ],
    );

    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'says when another Institution of the Society holds the number too',
      setUp: () => when(() => staff.setAadhaar('f1', number)).thenAnswer((_) async => 'XXXX XXXX 0123'),
      build: () => build(elsewhere: true),
      act: (bloc) => bloc.add(const IdentityNumberSaved(number)),
      expect: () => [
        const IdentityNumberWorking(masked, IdentityNumberAction.save),
        const IdentityNumberIdle('XXXX XXXX 0123', elsewhere: true),
      ],
    );

    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'keeps the number it had, and says why, when it is refused',
      setUp: () => when(() => staff.setAadhaar(any(), any())).thenThrow(invalid),
      build: build,
      act: (bloc) => bloc.add(const IdentityNumberSaved(number)),
      expect: () => [
        const IdentityNumberWorking(masked, IdentityNumberAction.save),
        const IdentityNumberRefused(masked, IdentityNumberAction.save, invalid, inSheet: true),
      ],
    );

    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'sets the first number of a staff member who had none',
      setUp: () => when(() => staff.setAadhaar('f1', number)).thenAnswer((_) async => masked),
      build: () => build(held: null),
      act: (bloc) => bloc.add(const IdentityNumberSaved(number)),
      expect: () => [
        const IdentityNumberWorking(null, IdentityNumberAction.save),
        const IdentityNumberIdle(masked),
      ],
    );
  });

  group('clearing the number', () {
    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'sends null and shows none',
      setUp: () => when(() => staff.setAadhaar('f1', null)).thenAnswer((_) async => null),
      build: build,
      act: (bloc) => bloc.add(const IdentityNumberCleared()),
      expect: () => [
        const IdentityNumberWorking(masked, IdentityNumberAction.clear),
        const IdentityNumberIdle(null),
      ],
    );

    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'keeps the number, and says why, when it is refused',
      setUp: () => when(() => staff.setAadhaar(any(), any())).thenThrow(const ApiFailure.network()),
      build: build,
      act: (bloc) => bloc.add(const IdentityNumberCleared()),
      expect: () => [
        const IdentityNumberWorking(masked, IdentityNumberAction.clear),
        const IdentityNumberRefused(masked, IdentityNumberAction.clear, ApiFailure.network(), inSheet: false),
      ],
    );
  });

  group('revealing the number', () {
    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'sends the reason and holds the whole number until it is hidden',
      setUp: () =>
          when(() => staff.revealAadhaar('f1', reason: 'Checking the records')).thenAnswer((_) async => number),
      build: build,
      act: (bloc) async {
        bloc.add(const IdentityNumberRevealed('Checking the records'));
        await pumpEventQueue();
        bloc.add(const IdentityNumberHidden());
      },
      expect: () => [
        const IdentityNumberWorking(masked, IdentityNumberAction.reveal),
        const IdentityNumberShown(masked, number),
        const IdentityNumberIdle(masked),
      ],
    );

    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'says why when it is refused, and keeps the number masked',
      setUp: () => when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenThrow(
        const ApiFailure(statusCode: 429, code: 'REVEAL_LIMIT', message: 'x'),
      ),
      build: build,
      act: (bloc) => bloc.add(const IdentityNumberRevealed('Checking the records')),
      expect: () => [
        const IdentityNumberWorking(masked, IdentityNumberAction.reveal),
        const IdentityNumberRefused(
          masked,
          IdentityNumberAction.reveal,
          ApiFailure(statusCode: 429, code: 'REVEAL_LIMIT', message: 'x'),
          inSheet: true,
        ),
      ],
    );

    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'shows none when the API says no number is set, as the screen was behind',
      setUp: () => when(() => staff.revealAadhaar(any(), reason: any(named: 'reason'))).thenThrow(
        const ApiFailure(statusCode: 404, code: 'NOT_SET', message: 'x'),
      ),
      build: build,
      act: (bloc) => bloc.add(const IdentityNumberRevealed('Checking the records')),
      expect: () => [
        const IdentityNumberWorking(masked, IdentityNumberAction.reveal),
        const IdentityNumberRefused(
          null,
          IdentityNumberAction.reveal,
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
      final states = <IdentityNumberState>[];
      bloc.stream.listen(states.add);
      bloc.add(const IdentityNumberRevealed('Checking the records'));
      await bloc.stream.firstWhere((state) => state is IdentityNumberWorking);
      bloc.add(const IdentityNumberHidden());
      await pumpEventQueue();
      held.complete(number);
      await pumpEventQueue();
      expect(bloc.state, const IdentityNumberIdle(masked));
      expect(states.whereType<IdentityNumberShown>(), isEmpty);
    });

    test('forgets that it was closed once the next call starts, so that sheet gets its number', () async {
      final held = Completer<String>();
      when(() => staff.revealAadhaar('f1', reason: 'First reason here')).thenAnswer((_) => held.future);
      when(() => staff.revealAadhaar('f1', reason: 'Checking the records')).thenAnswer((_) async => number);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const IdentityNumberRevealed('First reason here'));
      await bloc.stream.firstWhere((state) => state is IdentityNumberWorking);
      bloc.add(const IdentityNumberHidden());
      await pumpEventQueue();
      held.complete(number);
      await pumpEventQueue();
      bloc.add(const IdentityNumberRevealed('Checking the records'));
      await bloc.stream.firstWhere((state) => state is IdentityNumberShown);
      expect(bloc.state, const IdentityNumberShown(masked, number));
    });

    test('says a refusal on the card, as there is no sheet to say it', () async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const IdentityNumberSaved(number));
      await bloc.stream.firstWhere((state) => state is IdentityNumberWorking);
      bloc.add(const IdentityNumberHidden());
      await pumpEventQueue();
      held.completeError(invalid);
      await bloc.stream.firstWhere((state) => state is IdentityNumberRefused);
      expect(bloc.state, const IdentityNumberRefused(masked, IdentityNumberAction.save, invalid, inSheet: false));
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
      bloc.add(const IdentityNumberSaved(number));
      await bloc.stream.firstWhere((state) => state is IdentityNumberWorking);
      bloc.add(const IdentityNumberHidden());
      await pumpEventQueue();
      held.complete(masked);
      await pumpEventQueue();
      bloc.add(const IdentityNumberSaved(number));
      await bloc.stream.firstWhere((state) => state is IdentityNumberRefused);
      expect(bloc.state, const IdentityNumberRefused(masked, IdentityNumberAction.save, invalid, inSheet: true));
    });

    test('keeps a masked number that went through, as the card shows it', () async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const IdentityNumberSaved(number));
      await bloc.stream.firstWhere((state) => state is IdentityNumberWorking);
      bloc.add(const IdentityNumberHidden());
      await pumpEventQueue();
      held.complete('XXXX XXXX 0123');
      await pumpEventQueue();
      expect(bloc.state, const IdentityNumberIdle('XXXX XXXX 0123'));
    });
  });

  group('hiding', () {
    test('forgets a refusal', () async {
      when(() => staff.setAadhaar(any(), any())).thenThrow(invalid);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const IdentityNumberSaved(number));
      await bloc.stream.firstWhere((state) => state is IdentityNumberRefused);
      bloc.add(const IdentityNumberHidden());
      await bloc.stream.firstWhere((state) => state is IdentityNumberIdle);
      expect(bloc.state.number, masked);
    });

    test('does nothing while a change is on its way, or when nothing is shown', () async {
      final held = Completer<String?>();
      when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const IdentityNumberHidden());
      await pumpEventQueue();
      expect(bloc.state, const IdentityNumberIdle(masked));
      bloc.add(const IdentityNumberSaved(number));
      await bloc.stream.firstWhere((state) => state is IdentityNumberWorking);
      bloc.add(const IdentityNumberHidden());
      await pumpEventQueue();
      expect(bloc.state, const IdentityNumberWorking(masked, IdentityNumberAction.save));
      held.complete(masked);
    });
  });

  test('sends nothing while another change is on its way', () async {
    final held = Completer<String?>();
    when(() => staff.setAadhaar(any(), any())).thenAnswer((_) => held.future);
    final bloc = build();
    addTearDown(bloc.close);
    bloc.add(const IdentityNumberSaved(number));
    await bloc.stream.firstWhere((state) => state is IdentityNumberWorking);
    bloc
      ..add(const IdentityNumberCleared())
      ..add(const IdentityNumberRevealed('Checking the records'));
    await pumpEventQueue();
    verify(() => staff.setAadhaar(any(), any())).called(1);
    verifyNever(() => staff.revealAadhaar(any(), reason: any(named: 'reason')));
    held.complete(masked);
  });

  group('a number that is shown whole, so has no reveal', () {
    IdentityNumberBloc certificate() => IdentityNumberBloc(
      save: (number) async => (number: number, elsewhere: false),
      number: 'BC-2018-77',
    );

    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'is set and cleared as any other',
      build: certificate,
      act: (bloc) => bloc
        ..add(const IdentityNumberSaved('BC-2019-12'))
        ..add(const IdentityNumberCleared()),
      expect: () => [
        const IdentityNumberWorking('BC-2018-77', IdentityNumberAction.save),
        const IdentityNumberIdle('BC-2019-12'),
        const IdentityNumberWorking('BC-2019-12', IdentityNumberAction.clear),
        const IdentityNumberIdle(null),
      ],
    );

    blocTest<IdentityNumberBloc, IdentityNumberState>(
      'ignores a request to reveal it',
      build: certificate,
      act: (bloc) => bloc.add(const IdentityNumberRevealed('Checking the records')),
      expect: () => <IdentityNumberState>[],
    );
  });
}
