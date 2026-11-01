import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/bloc/role_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository auth;

  setUpAll(() => registerFallbackValue(ownerNorth));
  setUp(() => auth = MockAuthRepository());

  blocTest<RoleBloc, RoleState>(
    'switches through the API, then reports the role as chosen',
    build: () => RoleBloc(auth),
    setUp: () => when(() => auth.switchContext(any())).thenAnswer((_) async {}),
    act: (bloc) => bloc.add(const RoleChosen(ownerSouth)),
    expect: () => [const RoleState(choosing: ownerSouth), const RoleState(chosen: ownerSouth)],
    verify: (_) => verify(() => auth.switchContext(ownerSouth)).called(1),
  );

  blocTest<RoleBloc, RoleState>(
    'a refusal is kept for the screen, and nothing is chosen',
    build: () => RoleBloc(auth),
    setUp: () => when(() => auth.switchContext(any())).thenThrow(
      const ApiFailure(statusCode: 403, code: 'CONTEXT_NOT_AVAILABLE', message: ''),
    ),
    act: (bloc) => bloc.add(const RoleChosen(ownerSouth)),
    expect: () => [
      const RoleState(choosing: ownerSouth),
      isA<RoleState>()
          .having((s) => s.failure?.code, 'code', 'CONTEXT_NOT_AVAILABLE')
          .having((s) => s.chosen, 'chosen', isNull)
          .having((s) => s.isSubmitting, 'submitting', isFalse),
    ],
  );

  blocTest<RoleBloc, RoleState>(
    'choosing the role already in use needs no call',
    build: () => RoleBloc(auth, current: ownerNorth),
    act: (bloc) => bloc.add(const RoleChosen(ownerNorth)),
    expect: () => [const RoleState(chosen: ownerNorth)],
    verify: (_) => verifyNever(() => auth.switchContext(any())),
  );

  blocTest<RoleBloc, RoleState>(
    'a second tap while one switch is running is ignored',
    build: () => RoleBloc(auth),
    seed: () => const RoleState(choosing: ownerNorth),
    act: (bloc) => bloc.add(const RoleChosen(ownerSouth)),
    expect: () => <RoleState>[],
    verify: (_) => verifyNever(() => auth.switchContext(any())),
  );
}
