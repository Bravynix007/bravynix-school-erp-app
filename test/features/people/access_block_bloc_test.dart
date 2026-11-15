import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/access_block_bloc.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/staff.dart';

void main() {
  late MockStaffRepository staff;
  setUp(() => staff = MockStaffRepository());

  /// The bloc on a staff member's access, as the staff profile makes it: the same bloc serves a student's.
  AccessBlockBloc<StaffMember> build(StaffMember member) => AccessBlockBloc<StaffMember>(
    member,
    isBlocked: (member) => member.isBlocked,
    block: (member) => staff.block(member.id),
    unblock: (member) => staff.unblock(member.id),
    read: (member) => staff.member(member.id),
  );

  final active = kavyaWith();
  final blocked = kavyaWith(isBlocked: true, version: 5);
  const refusal = ApiFailure(statusCode: 409, code: 'CANNOT_ACT_ON_SELF', message: 'x');

  blocTest<AccessBlockBloc<StaffMember>, AccessBlockState<StaffMember>>(
    'blocks a staff member who is not blocked, and takes the record the API answers with',
    setUp: () => when(() => staff.block('f1')).thenAnswer((_) async => blocked),
    build: () => build(active),
    act: (bloc) => bloc.add(const AccessBlockToggled()),
    expect: () => [AccessBlockWorking(active), AccessBlockIdle(blocked)],
    verify: (_) => verifyNever(() => staff.unblock(any())),
  );

  blocTest<AccessBlockBloc<StaffMember>, AccessBlockState<StaffMember>>(
    'lifts the block of one who is blocked',
    setUp: () => when(() => staff.unblock('f1')).thenAnswer((_) async => active),
    build: () => build(blocked),
    act: (bloc) => bloc.add(const AccessBlockToggled()),
    expect: () => [AccessBlockWorking(blocked), AccessBlockIdle(active)],
    verify: (_) => verifyNever(() => staff.block(any())),
  );

  blocTest<AccessBlockBloc<StaffMember>, AccessBlockState<StaffMember>>(
    'keeps the record and the reason when it is refused, and tries the same again on the next press',
    setUp: () {
      var calls = 0;
      when(() => staff.block('f1')).thenAnswer((_) async {
        if (++calls == 1) throw refusal;
        return blocked;
      });
    },
    build: () => build(active),
    act: (bloc) async {
      bloc.add(const AccessBlockToggled());
      await bloc.stream.firstWhere((state) => state is AccessBlockRefused);
      bloc.add(const AccessBlockToggled());
    },
    expect: () => [
      AccessBlockWorking(active),
      AccessBlockRefused(active, refusal),
      AccessBlockWorking(active),
      AccessBlockIdle(blocked),
    ],
  );

  const alreadyBlocked = ApiFailure(statusCode: 409, code: 'INVALID_STATE', message: 'x');

  blocTest<AccessBlockBloc<StaffMember>, AccessBlockState<StaffMember>>(
    'reads the record again when someone else already blocked it, so the screen is as the API holds it',
    setUp: () {
      when(() => staff.block('f1')).thenThrow(alreadyBlocked);
      when(() => staff.member('f1')).thenAnswer((_) async => blocked);
    },
    build: () => build(active),
    act: (bloc) => bloc.add(const AccessBlockToggled()),
    expect: () => [AccessBlockWorking(active), AccessBlockRefused(blocked, alreadyBlocked)],
    verify: (_) => verify(() => staff.member('f1')).called(1),
  );

  blocTest<AccessBlockBloc<StaffMember>, AccessBlockState<StaffMember>>(
    'asks for the other thing on the next press once it knows the record is blocked',
    setUp: () {
      when(() => staff.block('f1')).thenThrow(alreadyBlocked);
      when(() => staff.member('f1')).thenAnswer((_) async => blocked);
      when(() => staff.unblock('f1')).thenAnswer((_) async => active);
    },
    build: () => build(active),
    act: (bloc) async {
      bloc.add(const AccessBlockToggled());
      await bloc.stream.firstWhere((state) => state is AccessBlockRefused);
      bloc.add(const AccessBlockToggled());
    },
    verify: (bloc) {
      expect(bloc.state, AccessBlockIdle(active));
      verify(() => staff.block('f1')).called(1);
      verify(() => staff.unblock('f1')).called(1);
    },
  );

  blocTest<AccessBlockBloc<StaffMember>, AccessBlockState<StaffMember>>(
    'keeps the record it had when it cannot read it again',
    setUp: () {
      when(() => staff.block('f1')).thenThrow(alreadyBlocked);
      when(() => staff.member('f1')).thenThrow(const ApiFailure.network());
    },
    build: () => build(active),
    act: (bloc) => bloc.add(const AccessBlockToggled()),
    expect: () => [AccessBlockWorking(active), AccessBlockRefused(active, alreadyBlocked)],
  );

  blocTest<AccessBlockBloc<StaffMember>, AccessBlockState<StaffMember>>(
    'does not read the record again for a refusal that says nothing of its state',
    setUp: () => when(() => staff.block('f1')).thenThrow(refusal),
    build: () => build(active),
    act: (bloc) => bloc.add(const AccessBlockToggled()),
    verify: (_) => verifyNever(() => staff.member(any())),
  );

  test('does not send twice while a request is on its way', () async {
    final held = Completer<StaffMember>();
    when(() => staff.block('f1')).thenAnswer((_) => held.future);
    final bloc = build(active);
    addTearDown(bloc.close);
    bloc
      ..add(const AccessBlockToggled())
      ..add(const AccessBlockToggled());
    await pumpEventQueue();
    verify(() => staff.block('f1')).called(1);
    held.complete(blocked);
  });
}
