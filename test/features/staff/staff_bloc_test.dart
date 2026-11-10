import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/staff.dart';

const _self = ApiFailure(statusCode: 409, code: 'CANNOT_ACT_ON_SELF', message: 'x');
const _gone = ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x');

void main() {
  late MockStaffRepository staff;
  late MockMastersRepository masters;
  setUp(() {
    staff = MockStaffRepository();
    masters = MockMastersRepository();
    when(() => masters.entries(MasterType.designations)).thenAnswer((_) async => [otherDesignation, designationEntry]);
    when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async => [higherPrimary, lowerPrimary]);
  });

  group('StaffBloc', () {
    StaffBloc build() => StaffBloc(staff, masters, 'i1');

    blocTest<StaffBloc, PagedListState<StaffListEntry>>(
      'reads the first page of its Institution with the names of the designation and the category',
      setUp: () => when(
        () => staff.staff('i1', query: any(named: 'query')),
      ).thenAnswer((_) async => const ItemsPage([kavya, ravi], page: 1, totalPages: 2)),
      build: build,
      act: (bloc) => bloc.add(const PagedListRequested()),
      expect: () => [
        const PagedListLoading<StaffListEntry>(),
        const PagedListLoaded<StaffListEntry>([kavyaEntry, raviEntry], hasMore: true),
      ],
    );

    blocTest<StaffBloc, PagedListState<StaffListEntry>>(
      'passes the search and the page on, and names the rows of the next page',
      setUp: () {
        when(() => staff.staff('i1', query: 'ka'))
            .thenAnswer((_) async => const ItemsPage([kavya], page: 1, totalPages: 2));
        when(() => staff.staff('i1', page: 2, query: 'ka'))
            .thenAnswer((_) async => const ItemsPage([ravi], page: 2, totalPages: 2));
      },
      build: build,
      act: (bloc) async {
        bloc.add(const PagedListSearched('ka'));
        await bloc.stream.firstWhere((state) => state is PagedListLoaded<StaffListEntry>);
        bloc.add(const PagedListMoreRequested());
      },
      skip: 2,
      expect: () => [
        const PagedListLoaded<StaffListEntry>([kavyaEntry], query: 'ka', hasMore: true, loadingMore: true),
        const PagedListLoaded<StaffListEntry>([kavyaEntry, raviEntry], query: 'ka', page: 2),
      ],
    );

    blocTest<StaffBloc, PagedListState<StaffListEntry>>(
      'deactivates a staff member by ID, then reads the first page again, saying which one went',
      setUp: () {
        var gone = false;
        when(() => staff.staff('i1', query: any(named: 'query'))).thenAnswer(
          (_) async => ItemsPage(gone ? [ravi] : [kavya, ravi], page: 1, totalPages: 1),
        );
        when(() => staff.deactivate('f1')).thenAnswer((_) async => gone = true);
      },
      build: build,
      act: (bloc) async {
        bloc.add(const PagedListRequested());
        await bloc.stream.firstWhere((state) => state is PagedListLoaded<StaffListEntry>);
        bloc.add(const StaffDeactivated(kavyaEntry));
      },
      skip: 2,
      expect: () => [
        const PagedListLoaded<StaffListEntry>([kavyaEntry, raviEntry], busyId: 'f1'),
        const PagedListLoaded<StaffListEntry>([raviEntry], changed: kavyaEntry),
      ],
    );

    blocTest<StaffBloc, PagedListState<StaffListEntry>>(
      'says why a deactivation was refused',
      setUp: () {
        when(() => staff.staff('i1', query: any(named: 'query')))
            .thenAnswer((_) async => const ItemsPage([kavya], page: 1, totalPages: 1));
        when(() => staff.deactivate('f1')).thenThrow(_self);
      },
      build: build,
      act: (bloc) async {
        bloc.add(const PagedListRequested());
        await bloc.stream.firstWhere((state) => state is PagedListLoaded<StaffListEntry>);
        bloc.add(const StaffDeactivated(kavyaEntry));
      },
      skip: 2,
      expect: () => [
        const PagedListLoaded<StaffListEntry>([kavyaEntry], busyId: 'f1'),
        const PagedListLoaded<StaffListEntry>([kavyaEntry], actionFailure: _self),
      ],
    );

    blocTest<StaffBloc, PagedListState<StaffListEntry>>(
      'leaves the category name out when the master no longer shows it',
      setUp: () {
        when(() => staff.staff('i1', query: any(named: 'query')))
            .thenAnswer((_) async => const ItemsPage([kavya], page: 1, totalPages: 1));
        when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async => [higherPrimary]);
      },
      build: build,
      act: (bloc) => bloc.add(const PagedListRequested()),
      expect: () => [
        const PagedListLoading<StaffListEntry>(),
        const PagedListLoaded<StaffListEntry>([StaffListEntry(kavya, designationName: 'Mathematics Teacher')]),
      ],
    );

    blocTest<StaffBloc, PagedListState<StaffListEntry>>(
      'fails when the masters cannot be read',
      setUp: () {
        when(() => staff.staff('i1', query: any(named: 'query')))
            .thenAnswer((_) async => const ItemsPage([kavya], page: 1, totalPages: 1));
        when(() => masters.entries(MasterType.designations)).thenThrow(const ApiFailure.network());
      },
      build: build,
      act: (bloc) => bloc.add(const PagedListRequested()),
      expect: () => [
        const PagedListLoading<StaffListEntry>(),
        const PagedListFailed<StaffListEntry>(ApiFailure.network()),
      ],
    );
  });

  group('StaffProfileBloc', () {
    StaffProfileBloc build(String id) => StaffProfileBloc(staff, masters, id);

    setUp(() {
      when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [countryEntry]);
      when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [stateEntry]);
      when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [cityEntry]);
    });

    blocTest<StaffProfileBloc, StaffProfileState>(
      'reads the member with the names of the designation, category and place',
      setUp: () => when(() => staff.member('f1')).thenAnswer((_) async => kavyaMember),
      build: () => build('f1'),
      act: (bloc) => bloc.add(const StaffProfileRequested()),
      expect: () => [const StaffProfileLoading(), const StaffProfileLoaded(kavyaProfile)],
    );

    blocTest<StaffProfileBloc, StaffProfileState>(
      'asks the masters for nothing the member does not have',
      setUp: () => when(() => staff.member('f2')).thenAnswer((_) async => raviMember),
      build: () => build('f2'),
      act: (bloc) => bloc.add(const StaffProfileRequested()),
      expect: () => [const StaffProfileLoading(), const StaffProfileLoaded(raviProfile)],
      verify: (_) {
        verifyNever(() => masters.entries(MasterType.countries));
        verifyNever(() => masters.entries(MasterType.states, parentId: any(named: 'parentId')));
        verifyNever(() => masters.entries(MasterType.cities, parentId: any(named: 'parentId')));
      },
    );

    blocTest<StaffProfileBloc, StaffProfileState>(
      'fails with the reason, and reads again on Try again',
      setUp: () {
        var calls = 0;
        when(() => staff.member('f1')).thenAnswer((_) async {
          if (++calls == 1) throw _gone;
          return kavyaMember;
        });
      },
      build: () => build('f1'),
      act: (bloc) async {
        bloc.add(const StaffProfileRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StaffProfileRequested());
      },
      expect: () => [
        const StaffProfileLoading(),
        const StaffProfileFailed(_gone),
        const StaffProfileLoading(),
        const StaffProfileLoaded(kavyaProfile),
      ],
    );
  });
}
