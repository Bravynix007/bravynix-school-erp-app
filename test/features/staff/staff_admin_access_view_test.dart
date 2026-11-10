import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution_admin.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_admin_access_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_admin_access_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';

class _MockBloc extends MockBloc<StaffAdminAccessEvent, StaffAdminAccessState> implements StaffAdminAccessBloc;

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late _MockBloc bloc;

  setUpAll(() => registerFallbackValue(const StaffAdminAccessStarted()));
  setUp(() => bloc = _MockBloc());

  final home = summary();
  final lakeView = summary(id: 'i2', code: 'LVS', name: 'Lake View School', place: null, board: null);

  StaffAdminAccessReady ready({
    List<String> adminAt = const ['i2'],
    String? working,
    ApiFailure? failure,
    String? failedAt,
  }) => StaffAdminAccessReady(
    institutions: [home, lakeView],
    adminAt: adminAt,
    working: working,
    failure: failure,
    failedAt: failedAt,
  );

  Future<void> pump(
    WidgetTester tester,
    StaffAdminAccessState state, {
    double textScale = 1,
    Size size = const Size(400, 1400),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<StaffAdminAccessBloc>.value(
        value: bloc,
        child: const Scaffold(
          body: SingleChildScrollView(child: StaffAdminAccessView(memberName: 'Kavya Nair')),
        ),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder toggle(String id) => find.byKey(Key('staffAdmin.toggle.$id'));
  AppButton button(WidgetTester tester, String id) => tester.widget<AppButton>(toggle(id));

  group('the Institutions', () {
    testWidgets('say where they are an Admin, with the way to change it', (tester) async {
      await pump(tester, ready());
      expect(find.text('Admin access'), findsOneWidget);
      expect(find.text('Sri Vidya High School'), findsOneWidget);
      expect(find.text('Lake View School'), findsOneWidget);
      expect(find.byKey(const Key('staffAdmin.isAdmin.i2')), findsOneWidget);
      expect(find.byKey(const Key('staffAdmin.isAdmin.i1')), findsNothing);
      expect(find.text('Not an Admin here.'), findsOneWidget);
      expect(button(tester, 'i1').label, 'Make Admin');
      expect(button(tester, 'i2').label, 'Take away Admin access');
    });

    testWidgets('say when there is none they could be an Admin of', (tester) async {
      await pump(tester, const StaffAdminAccessReady(institutions: [], adminAt: []));
      expect(find.byKey(const Key('staffAdmin.empty')), findsOneWidget);
    });
  });

  group('making an Admin', () {
    testWidgets('asks first, and gives the access once the person confirms', (tester) async {
      await pump(tester, ready());
      await tester.tap(toggle('i1'));
      await tester.pumpAndSettle();
      expect(find.text('Make Kavya Nair an Admin of Sri Vidya High School?'), findsOneWidget);
      expect(find.text('They can run this Institution. They are told by email.'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Make Admin')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffAdminGranted('i1'))).called(1);
    });

    testWidgets('is not done when the person cancels or dismisses the question', (tester) async {
      await pump(tester, ready());
      await tester.tap(toggle('i1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(toggle('i1'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      verifyNever(() => bloc.add(any()));
    });
  });

  group('taking the access away', () {
    testWidgets('asks first, in red, and takes it once the person confirms', (tester) async {
      await pump(tester, ready());
      await tester.tap(toggle('i2'));
      await tester.pumpAndSettle();
      expect(find.text('Take away Admin access of Kavya Nair to Lake View School?'), findsOneWidget);
      expect(find.textContaining('signed out as Admin of this Society at once'), findsOneWidget);
      final confirm = find.descendant(of: find.byType(Dialog), matching: find.byType(AppButton)).last;
      expect(tester.widget<AppButton>(confirm).variant, AppButtonVariant.danger);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Take away Admin access')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffAdminRevoked('i2'))).called(1);
    });

    testWidgets('is not done when the person cancels', (tester) async {
      await pump(tester, ready());
      await tester.tap(toggle('i2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any()));
    });
  });

  group('while one is on its way', () {
    testWidgets('shows the Institution it is for, and offers no change at the others', (tester) async {
      await pump(tester, ready(working: 'i1'));
      expect(button(tester, 'i1').loading, isTrue);
      expect(button(tester, 'i2').loading, isFalse);
      expect(button(tester, 'i2').onPressed, isNull);
    });
  });

  group('after a refusal', () {
    for (final (failure, words) in [
      (_failure(422, 'STAFF_BLOCKED'), 'They are blocked. Unblock them under Settings before giving Admin access.'),
      (
        _failure(422, 'STAFF_NOT_AT_INSTITUTION'),
        'They are not at this Institution. Add it under Other Institutions and save first.',
      ),
      (_failure(409, 'ALREADY_ADMIN'), 'They are already an Admin of this Institution. The screen is up to date now.'),
      (_failure(409, 'INVALID_STATE'), 'Their account cannot hold this role right now.'),
      (_failure(409, 'ACCOUNT_BLOCKED'), "This account is blocked and can't access the app."),
      (
        _failure(404, 'NOT_FOUND'),
        'This staff member could not be found. They may have been deactivated.',
      ),
    ]) {
      testWidgets('says ${failure.code} under the Institution it was for, and there only', (tester) async {
        await pump(tester, ready(failure: failure, failedAt: 'i1'));
        expect(find.byKey(const Key('staffAdmin.error.i1')), findsOneWidget);
        expect(find.text(words), findsOneWidget);
        expect(find.text('server words'), findsNothing);
        expect(find.byKey(const Key('staffAdmin.error.i2')), findsNothing);
        expect(button(tester, 'i1').onPressed, isNotNull);
      });
    }
  });

  group('before the Institutions are ready', () {
    testWidgets('shows a placeholder while they load', (tester) async {
      await pump(tester, const StaffAdminAccessLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.text('Admin access'), findsOneWidget);
    });

    testWidgets('says why they could not be read, and starts again on Try again', (tester) async {
      await pump(tester, const StaffAdminAccessFailed(ApiFailure.network()));
      expect(find.byKey(const Key('staffAdmin.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StaffAdminAccessStarted())).called(1);
    });
  });

  group('once a change went through', () {
    testWidgets('says that an Admin was made', (tester) async {
      final before = ready();
      whenListen(
        bloc,
        Stream.value(
          StaffAdminAccessReady(
            institutions: before.institutions,
            adminAt: const ['i1', 'i2'],
            done: const StaffAdminChange('i1', granted: true),
          ),
        ),
        initialState: before,
      );
      await pump(tester, before);
      await tester.pump();
      expect(find.text('Kavya Nair is now an Admin of Sri Vidya High School'), findsOneWidget);
    });

    testWidgets('says that the access was taken away', (tester) async {
      final before = ready();
      whenListen(
        bloc,
        Stream.value(
          StaffAdminAccessReady(
            institutions: before.institutions,
            adminAt: const [],
            done: const StaffAdminChange('i2', granted: false),
          ),
        ),
        initialState: before,
      );
      await pump(tester, before);
      await tester.pump();
      expect(find.text('Kavya Nair is no longer an Admin of Lake View School'), findsOneWidget);
    });

    testWidgets('says nothing when the next change starts', (tester) async {
      final done = StaffAdminAccessReady(
        institutions: [home, lakeView],
        adminAt: const ['i2'],
        done: const StaffAdminChange('i2', granted: true),
      );
      whenListen(
        bloc,
        Stream.value(done.copyWith(working: () => 'i1', done: () => null)),
        initialState: done,
      );
      await pump(tester, done);
      await tester.pump();
      expect(find.textContaining('is now an Admin'), findsNothing);
    });
  });

  group('the section', () {
    late MockInstitutionsRepository institutions;

    setUp(() {
      institutions = MockInstitutionsRepository();
      when(() => institutions.institutions()).thenAnswer((_) async => [home, lakeView]);
      when(() => institutions.admins(any(), page: any(named: 'page'))).thenAnswer(
        (call) async => ItemsPage(
          call.positionalArguments.first == 'i2' ? [adminOf(institutionId: 'i2')] : const <InstitutionAdmin>[],
          page: 1,
          totalPages: 1,
        ),
      );
      getIt.registerSingleton<InstitutionsRepository>(institutions);
    });
    tearDown(getIt.reset);

    Future<void> pumpSection(WidgetTester tester, StaffMember member) => tester.pumpApp(
      Scaffold(
        body: SingleChildScrollView(child: StaffAdminAccessSection(member: member)),
      ),
    );

    testWidgets('reads who is an Admin where the person is at, and shows it', (tester) async {
      await pumpSection(tester, kavyaWith(institutionIds: ['i2']));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staffAdmin.isAdmin.i2')), findsOneWidget);
      expect(find.byKey(const Key('staffAdmin.isAdmin.i1')), findsNothing);
    });

    testWidgets('gives the access through the API once the person confirms, and says so', (tester) async {
      when(() => institutions.grantAdmin('i1', 'f1')).thenAnswer((_) async => adminOf());
      await pumpSection(tester, kavyaWith(institutionIds: ['i2']));
      await tester.pumpAndSettle();
      await tester.tap(toggle('i1'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Make Admin')));
      await tester.pumpAndSettle();
      verify(() => institutions.grantAdmin('i1', 'f1')).called(1);
      expect(find.byKey(const Key('staffAdmin.isAdmin.i1')), findsOneWidget);
      expect(find.text('Kavya Nair is now an Admin of Sri Vidya High School'), findsOneWidget);
    });

    testWidgets('reads again when the extra Institutions of the person change, and not when anything else does', (
      tester,
    ) async {
      await pumpSection(tester, kavyaWith(institutionIds: ['i2']));
      await tester.pumpAndSettle();
      await pumpSection(tester, kavyaWith(institutionIds: ['i2'], subjectIds: ['u1'], version: 9));
      await tester.pumpAndSettle();
      verify(() => institutions.institutions()).called(1);
      await pumpSection(tester, kavyaWith());
      await tester.pumpAndSettle();
      verify(() => institutions.institutions()).called(1);
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      ready(failure: _failure(422, 'STAFF_NOT_AT_INSTITUTION'), failedAt: 'i1'),
      textScale: 2,
      size: const Size(320, 3000),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
