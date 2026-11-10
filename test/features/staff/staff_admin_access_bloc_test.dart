import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution_admin.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_admin_access_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/staff.dart';

void main() {
  late MockInstitutionsRepository institutions;

  // Kavya is based at i1 and sees i2 besides; the Society also has i3, which she has nothing to do with.
  final home = summary();
  final lakeView = summary(id: 'i2', code: 'LVS', name: 'Lake View School', place: null, board: null);
  final hillTop = summary(id: 'i3', code: 'HTS', name: 'Hill Top School', place: null, board: null);
  final kavya = kavyaWith(institutionIds: ['i2']);

  ItemsPage<InstitutionAdmin> only(List<InstitutionAdmin> admins, {int page = 1, int pages = 1}) =>
      ItemsPage(admins, page: page, totalPages: pages);

  setUp(() {
    institutions = MockInstitutionsRepository();
    when(() => institutions.institutions()).thenAnswer((_) async => [home, lakeView, hillTop]);
    when(() => institutions.admins(any(), page: any(named: 'page'))).thenAnswer((_) async => only([]));
  });

  StaffAdminAccessBloc build() => StaffAdminAccessBloc(institutions, member: kavya);

  Future<StaffAdminAccessBloc> opened() async {
    final bloc = build();
    addTearDown(bloc.close);
    bloc.add(const StaffAdminAccessStarted());
    await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady);
    return bloc;
  }

  StaffAdminAccessReady ready(StaffAdminAccessBloc bloc) => bloc.state as StaffAdminAccessReady;

  group('starting', () {
    blocTest<StaffAdminAccessBloc, StaffAdminAccessState>(
      'lists the Institutions the person is at, their own and their extra ones, and where they are an Admin',
      setUp: () {
        when(() => institutions.admins('i2', page: any(named: 'page')))
            .thenAnswer((_) async => only([adminOf(institutionId: 'i2')]));
        // Another person is an Admin at their home Institution.
        when(() => institutions.admins('i1', page: any(named: 'page')))
            .thenAnswer((_) async => only([adminOf(staffMemberId: 'f9', name: 'Someone else')]));
      },
      build: build,
      act: (bloc) => bloc.add(const StaffAdminAccessStarted()),
      expect: () => [
        const StaffAdminAccessLoading(),
        StaffAdminAccessReady(institutions: [home, lakeView], adminAt: const ['i2']),
      ],
      verify: (_) => verifyNever(() => institutions.admins('i3', page: any(named: 'page'))),
    );

    blocTest<StaffAdminAccessBloc, StaffAdminAccessState>(
      'reads the list a page at a time until the person is in it, and no further',
      setUp: () {
        when(() => institutions.admins('i1', page: any(named: 'page'))).thenAnswer(
          (call) async => switch (call.namedArguments[#page]) {
            1 => only([adminOf(staffMemberId: 'f9')], pages: 3),
            _ => only([adminOf()], page: 2, pages: 3),
          },
        );
      },
      build: build,
      act: (bloc) => bloc.add(const StaffAdminAccessStarted()),
      verify: (bloc) {
        expect(ready(bloc).adminAt, ['i1']);
        verifyNever(() => institutions.admins('i1', page: 3));
      },
    );

    blocTest<StaffAdminAccessBloc, StaffAdminAccessState>(
      'reads every page before it says the person is not an Admin',
      setUp: () {
        when(() => institutions.admins('i1', page: any(named: 'page'))).thenAnswer(
          (call) async => only([], page: call.namedArguments[#page]! as int, pages: 2),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const StaffAdminAccessStarted()),
      verify: (bloc) {
        expect(ready(bloc).adminAt, isEmpty);
        verify(() => institutions.admins('i1', page: 2)).called(1);
      },
    );

    blocTest<StaffAdminAccessBloc, StaffAdminAccessState>(
      'leaves out an Institution that is no longer offered, such as a deactivated one',
      setUp: () => when(() => institutions.institutions()).thenAnswer((_) async => [home]),
      build: build,
      act: (bloc) => bloc.add(const StaffAdminAccessStarted()),
      expect: () => [
        const StaffAdminAccessLoading(),
        StaffAdminAccessReady(institutions: [home], adminAt: const []),
      ],
    );

    blocTest<StaffAdminAccessBloc, StaffAdminAccessState>(
      'keeps the failure for the screen, and starts again on retry',
      setUp: () {
        var calls = 0;
        when(() => institutions.institutions()).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [home];
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const StaffAdminAccessStarted());
        await bloc.stream.firstWhere((state) => state is StaffAdminAccessFailed);
        bloc.add(const StaffAdminAccessStarted());
      },
      expect: () => [
        const StaffAdminAccessLoading(),
        const StaffAdminAccessFailed(ApiFailure.network()),
        const StaffAdminAccessLoading(),
        isA<StaffAdminAccessReady>(),
      ],
    );

    blocTest<StaffAdminAccessBloc, StaffAdminAccessState>(
      'fails when the list of Admins cannot be read',
      setUp: () =>
          when(() => institutions.admins(any(), page: any(named: 'page'))).thenThrow(const ApiFailure.network()),
      build: build,
      act: (bloc) => bloc.add(const StaffAdminAccessStarted()),
      expect: () => [const StaffAdminAccessLoading(), const StaffAdminAccessFailed(ApiFailure.network())],
    );
  });

  group('granting', () {
    test('gives the access and says it went through', () async {
      when(() => institutions.grantAdmin('i2', 'f1')).thenAnswer((_) async => adminOf(institutionId: 'i2'));
      final bloc = await opened();
      bloc.add(const StaffAdminGranted('i2'));
      await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && state.done != null);
      expect(ready(bloc).adminAt, ['i2']);
      expect(ready(bloc).working, isNull);
      expect(ready(bloc).done, const StaffAdminChange('i2', granted: true));
      expect(ready(bloc).failure, isNull);
    });

    test('shows which Institution is on its way, and sends nothing else meanwhile', () async {
      final held = Completer<InstitutionAdmin>();
      when(() => institutions.grantAdmin(any(), any())).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc.add(const StaffAdminGranted('i1'));
      await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && state.working == 'i1');
      bloc
        ..add(const StaffAdminGranted('i2'))
        ..add(const StaffAdminRevoked('i1'));
      await pumpEventQueue();
      verify(() => institutions.grantAdmin(any(), any())).called(1);
      verifyNever(() => institutions.revokeAdmin(any(), any()));
      held.complete(adminOf());
    });

    for (final (code, status) in [
      ('STAFF_BLOCKED', 422),
      ('STAFF_NOT_AT_INSTITUTION', 422),
      ('ACCOUNT_BLOCKED', 409),
      ('INVALID_STATE', 409),
    ]) {
      test('keeps things as they are, with the failure of the Institution it was for, when $code refuses it', () async {
        final failure = ApiFailure(statusCode: status, code: code, message: 'x');
        when(() => institutions.grantAdmin(any(), any())).thenThrow(failure);
        final bloc = await opened();
        bloc.add(const StaffAdminGranted('i2'));
        await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && state.failure != null);
        expect(ready(bloc).failure, failure);
        expect(ready(bloc).failedAt, 'i2');
        expect(ready(bloc).adminAt, isEmpty);
        expect(ready(bloc).working, isNull);
        expect(ready(bloc).done, isNull);
      });
    }

    test('shows them as an Admin when the API says they already are', () async {
      when(() => institutions.grantAdmin(any(), any()))
          .thenThrow(const ApiFailure(statusCode: 409, code: 'ALREADY_ADMIN', message: 'x'));
      final bloc = await opened();
      bloc.add(const StaffAdminGranted('i2'));
      await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && state.failure != null);
      expect(ready(bloc).adminAt, ['i2']);
    });

    test('forgets the last refusal and the last success when the next one is sent', () async {
      when(() => institutions.grantAdmin('i2', any())).thenThrow(const ApiFailure.network());
      when(() => institutions.grantAdmin('i1', any())).thenAnswer((_) async => adminOf());
      final bloc = await opened();
      bloc.add(const StaffAdminGranted('i2'));
      await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && state.failure != null);
      bloc.add(const StaffAdminGranted('i1'));
      await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && state.done != null);
      expect(ready(bloc).failure, isNull);
      expect(ready(bloc).failedAt, isNull);
    });
  });

  group('revoking', () {
    setUp(() {
      when(() => institutions.admins('i2', page: any(named: 'page')))
          .thenAnswer((_) async => only([adminOf(institutionId: 'i2')]));
    });

    test('takes the access away and says it went through, leaving the other Institutions as they are', () async {
      when(() => institutions.grantAdmin('i1', 'f1')).thenAnswer((_) async => adminOf());
      when(() => institutions.revokeAdmin('i2', 'f1')).thenAnswer((_) async {});
      final bloc = await opened();
      bloc.add(const StaffAdminGranted('i1'));
      await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && state.adminAt.contains('i1'));
      bloc.add(const StaffAdminRevoked('i2'));
      await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && !state.adminAt.contains('i2'));
      expect(ready(bloc).adminAt, ['i1']);
      expect(ready(bloc).done, const StaffAdminChange('i2', granted: false));
    });

    test('keeps them an Admin, with the failure, when it is refused', () async {
      when(() => institutions.revokeAdmin(any(), any())).thenThrow(const ApiFailure.network());
      final bloc = await opened();
      bloc.add(const StaffAdminRevoked('i2'));
      await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && state.failure != null);
      expect(ready(bloc).adminAt, ['i2']);
      expect(ready(bloc).failedAt, 'i2');
    });

    test('shows them as not an Admin when the API says there is no access to take away', () async {
      when(() => institutions.revokeAdmin(any(), any()))
          .thenThrow(const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'));
      final bloc = await opened();
      bloc.add(const StaffAdminRevoked('i2'));
      await bloc.stream.firstWhere((state) => state is StaffAdminAccessReady && state.failure != null);
      expect(ready(bloc).adminAt, isEmpty);
    });
  });

  test('sends nothing before the Institutions are read', () async {
    final bloc = build();
    addTearDown(bloc.close);
    bloc
      ..add(const StaffAdminGranted('i1'))
      ..add(const StaffAdminRevoked('i1'));
    await pumpEventQueue();
    verifyNever(() => institutions.grantAdmin(any(), any()));
    verifyNever(() => institutions.revokeAdmin(any(), any()));
  });
}
