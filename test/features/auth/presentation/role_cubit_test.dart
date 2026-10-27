import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/cubit/role_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository auth;

  setUpAll(() => registerFallbackValue(ownerNorth));
  setUp(() => auth = MockAuthRepository());

  blocTest<RoleCubit, RoleState>(
    'switches through the API, then reports the role as chosen',
    build: () => RoleCubit(auth),
    setUp: () => when(() => auth.switchContext(any())).thenAnswer((_) async {}),
    act: (cubit) => cubit.choose(ownerSouth),
    expect: () => [const RoleState(choosing: ownerSouth), const RoleState(chosen: ownerSouth)],
    verify: (_) => verify(() => auth.switchContext(ownerSouth)).called(1),
  );

  blocTest<RoleCubit, RoleState>(
    'a refusal is kept for the screen, and nothing is chosen',
    build: () => RoleCubit(auth),
    setUp: () => when(() => auth.switchContext(any())).thenThrow(
      const ApiFailure(statusCode: 403, code: 'CONTEXT_NOT_AVAILABLE', message: ''),
    ),
    act: (cubit) => cubit.choose(ownerSouth),
    expect: () => [
      const RoleState(choosing: ownerSouth),
      isA<RoleState>()
          .having((s) => s.failure?.code, 'code', 'CONTEXT_NOT_AVAILABLE')
          .having((s) => s.chosen, 'chosen', isNull)
          .having((s) => s.isSubmitting, 'submitting', isFalse),
    ],
  );

  blocTest<RoleCubit, RoleState>(
    'choosing the role already in use needs no call',
    build: () => RoleCubit(auth, current: ownerNorth),
    act: (cubit) => cubit.choose(ownerNorth),
    expect: () => [const RoleState(chosen: ownerNorth)],
    verify: (_) => verifyNever(() => auth.switchContext(any())),
  );

  blocTest<RoleCubit, RoleState>(
    'a second tap while one switch is running is ignored',
    build: () => RoleCubit(auth),
    seed: () => const RoleState(choosing: ownerNorth),
    act: (cubit) => cubit.choose(ownerSouth),
    expect: () => <RoleState>[],
    verify: (_) => verifyNever(() => auth.switchContext(any())),
  );
}
