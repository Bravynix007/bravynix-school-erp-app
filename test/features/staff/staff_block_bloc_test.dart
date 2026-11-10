import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_block_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/staff.dart';

void main() {
  late MockStaffRepository staff;
  setUp(() => staff = MockStaffRepository());

  final active = kavyaWith();
  final blocked = kavyaWith(isBlocked: true, version: 5);
  const refusal = ApiFailure(statusCode: 409, code: 'CANNOT_ACT_ON_SELF', message: 'x');

  blocTest<StaffBlockBloc, StaffBlockState>(
    'blocks a staff member who is not blocked, and takes the record the API answers with',
    setUp: () => when(() => staff.block('f1')).thenAnswer((_) async => blocked),
    build: () => StaffBlockBloc(staff, active),
    act: (bloc) => bloc.add(const StaffBlockToggled()),
    expect: () => [StaffBlockWorking(active), StaffBlockIdle(blocked)],
    verify: (_) => verifyNever(() => staff.unblock(any())),
  );

  blocTest<StaffBlockBloc, StaffBlockState>(
    'lifts the block of one who is blocked',
    setUp: () => when(() => staff.unblock('f1')).thenAnswer((_) async => active),
    build: () => StaffBlockBloc(staff, blocked),
    act: (bloc) => bloc.add(const StaffBlockToggled()),
    expect: () => [StaffBlockWorking(blocked), StaffBlockIdle(active)],
    verify: (_) => verifyNever(() => staff.block(any())),
  );

  blocTest<StaffBlockBloc, StaffBlockState>(
    'keeps the record and the reason when it is refused, and tries the same again on the next press',
    setUp: () {
      var calls = 0;
      when(() => staff.block('f1')).thenAnswer((_) async {
        if (++calls == 1) throw refusal;
        return blocked;
      });
    },
    build: () => StaffBlockBloc(staff, active),
    act: (bloc) async {
      bloc.add(const StaffBlockToggled());
      await bloc.stream.firstWhere((state) => state is StaffBlockRefused);
      bloc.add(const StaffBlockToggled());
    },
    expect: () => [
      StaffBlockWorking(active),
      StaffBlockRefused(active, refusal),
      StaffBlockWorking(active),
      StaffBlockIdle(blocked),
    ],
  );

  test('does not send twice while a request is on its way', () async {
    final held = Completer<StaffMember>();
    when(() => staff.block('f1')).thenAnswer((_) => held.future);
    final bloc = StaffBlockBloc(staff, active);
    addTearDown(bloc.close);
    bloc
      ..add(const StaffBlockToggled())
      ..add(const StaffBlockToggled());
    await pumpEventQueue();
    verify(() => staff.block('f1')).called(1);
    held.complete(blocked);
  });
}
