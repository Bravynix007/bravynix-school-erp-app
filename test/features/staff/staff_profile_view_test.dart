import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/device/screen_protection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_profile.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_form_page.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_profile_page.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignments_repository.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/screen_protection.dart';
import '../../helpers/staff.dart';

class _MockProfileBloc extends MockBloc<StaffProfileEvent, StaffProfileState> implements StaffProfileBloc;

void main() {
  late _MockProfileBloc bloc;
  late MockStaffRepository staff;
  setUpAll(() => registerFallbackValue(const StaffProfileRequested()));
  // What the parts of the Access tab read from: the page makes their blocs, and the listeners reach for them, when the
  // profile is shown.
  setUp(() {
    bloc = _MockProfileBloc();
    staff = MockStaffRepository();
    final subjects = MockSubjectsRepository();
    final institutions = MockInstitutionsRepository();
    when(subjects.subjects).thenAnswer((_) async => const []);
    final years = MockAcademicYearsRepository();
    final classes = MockClassesRepository();
    final teaching = MockTeachingAssignmentsRepository();
    when(institutions.institutions).thenAnswer((_) async => const []);
    when(
      () => teaching.assignments(
        any(),
        academicYearId: any(named: 'academicYearId'),
        staffMemberId: any(named: 'staffMemberId'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => const ItemsPage([], page: 1, totalPages: 1));
    when(() => years.years(any())).thenAnswer((_) async => const []);
    when(() => classes.classes(any())).thenAnswer((_) async => const []);
    getIt
      ..registerSingleton<StaffRepository>(staff)
      ..registerSingleton<SubjectsRepository>(subjects)
      ..registerSingleton<InstitutionsRepository>(institutions)
      ..registerSingleton<AcademicYearsRepository>(years)
      ..registerSingleton<ClassesRepository>(classes)
      ..registerSingleton<SectionsRepository>(MockSectionsRepository())
      ..registerSingleton<TeachingAssignmentsRepository>(teaching)
      ..registerSingleton<ScreenProtection>(RecordingScreenProtection());
  });
  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester,
    StaffProfileState state, {
    double textScale = 1,
    Size size = const Size(400, 2400),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<StaffProfileBloc>.value(value: bloc, child: const StaffProfileView(isOwner: false)),
      textScale: textScale,
      size: size,
    );
  }

  testWidgets('shows everything a full profile has', (tester) async {
    await pump(tester, const StaffProfileLoaded(kavyaProfile));
    for (final text in [
      'Kavya Nair',
      'T-014',
      'Mathematics Teacher',
      'Lower Primary',
      'Female',
      '17-04-1990',
      'O+',
      'Indian',
      'kavya.nair@example.com',
      '+91 9876543210',
      '9876500000',
      '12 Lake Road\nNear the park\nBengaluru, Karnataka, India\n560066',
      'XXXX XXXX 1234',
      'Full time',
      '01-06-2020',
      '31-03-2026',
      'B.Ed',
      'Education · Mathematics · Mysore University · 2014',
      'Anil Nair (Father)',
      '+91 9876511111 · 9876522222',
      'Mini Nair',
      '+91 9876533333',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Blocked'), findsNothing);
  });

  testWidgets('does not look for the Admin part, which an Admin has not, when their extra Institutions change', (
    tester,
  ) async {
    final changed = StaffProfileLoaded(kavyaProfile.withMember(kavyaWith(institutionIds: const ['i2'])));
    whenListen(bloc, Stream.value(changed), initialState: const StaffProfileLoaded(kavyaProfile));
    await pump(tester, const StaffProfileLoaded(kavyaProfile));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('the tabs', () {
    testWidgets('offer Personal, Access and Settings, on Personal at first', (tester) async {
      await pump(tester, const StaffProfileLoaded(kavyaProfile));
      for (final label in ['Personal', 'Access', 'Settings']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Anil Nair (Father)'), findsOneWidget);
      expect(find.byKey(const Key('staffAccess.saveSubjects')), findsNothing);
      expect(find.byKey(const Key('staffSettings.toggle')), findsNothing);
    });

    testWidgets('tell the bloc which tab was chosen', (tester) async {
      await pump(tester, const StaffProfileLoaded(kavyaProfile));
      await tester.tap(find.text('Access'));
      verify(() => bloc.add(const StaffProfileTabChosen(StaffProfileTab.access))).called(1);
      await tester.tap(find.text('Settings'));
      verify(() => bloc.add(const StaffProfileTabChosen(StaffProfileTab.settings))).called(1);
    });

    testWidgets('show the access of the staff member on Access, and not the personal details', (tester) async {
      await pump(tester, const StaffProfileLoaded(kavyaProfile, tab: StaffProfileTab.access));
      await tester.pump();
      expect(find.byKey(const Key('staffAccess.saveSubjects')), findsOneWidget);
      expect(find.text('Anil Nair (Father)'), findsNothing);
    });

    testWidgets('show the Other Institutions list on Access to the Society Owner only', (tester) async {
      when(() => bloc.state).thenReturn(const StaffProfileLoaded(kavyaProfile, tab: StaffProfileTab.access));
      await tester.pumpAppScaled(
        BlocProvider<StaffProfileBloc>.value(value: bloc, child: const StaffProfileView(isOwner: true)),
        size: const Size(400, 1600),
      );
      await tester.pump();
      expect(find.byKey(const Key('staffAccess.saveInstitutions')), findsOneWidget);
      expect(find.text('Admin access'), findsOneWidget);
    });

    testWidgets('keep the Institutions list from the Admin on Access', (tester) async {
      await pump(tester, const StaffProfileLoaded(kavyaProfile, tab: StaffProfileTab.access));
      await tester.pump();
      expect(find.byKey(const Key('staffAccess.saveInstitutions')), findsNothing);
      expect(find.text('Admin access'), findsNothing);
    });

    testWidgets('show the access to the app on Settings', (tester) async {
      await pump(tester, const StaffProfileLoaded(kavyaProfile, tab: StaffProfileTab.settings));
      expect(find.byKey(const Key('staffSettings.toggle')), findsOneWidget);
      expect(find.text('Anil Nair (Father)'), findsNothing);
    });
  });

  testWidgets('shows only what a bare profile has, with the Blocked badge', (tester) async {
    await pump(tester, const StaffProfileLoaded(raviProfile));
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Employee ID'), findsNothing);
    expect(find.text('Gender'), findsNothing);
    expect(find.text('Address'), findsNothing);
    expect(find.text('Employment'), findsNothing);
    expect(find.text('Education'), findsNothing);
    expect(find.text('Emergency contacts'), findsNothing);
    expect(find.text('Not set'), findsOneWidget);
  });

  for (final (type, gender, label) in [
    (EmploymentType.partTime, Gender.male, 'Part time'),
    (EmploymentType.visiting, Gender.other, 'Visiting'),
    (EmploymentType.contract, Gender.female, 'Contract'),
  ]) {
    testWidgets('names the $label employment type and the ${gender.name} gender', (tester) async {
      await pump(
        tester,
        StaffProfileLoaded(
          StaffProfile(
            StaffMember(
              id: 'f1',
              homeInstitutionId: 'i1',
              email: 'a@example.com',
              firstName: 'A',
              classCategoryId: 'c1',
              mobile: mobile,
              address: const StaffAddress(),
              educations: const [],
              emergencyContacts: const [],
              isBlocked: false,
              version: 1,
              employmentType: type,
              gender: gender,
            ),
            categoryName: 'Lower Primary',
          ),
        ),
      );
      expect(find.text(label), findsOneWidget);
      expect(find.text({Gender.male: 'Male', Gender.female: 'Female', Gender.other: 'Other'}[gender]!), findsOneWidget);
    });
  }

  testWidgets('leaves out the Category row when the master no longer shows the category', (tester) async {
    await pump(tester, const StaffProfileLoaded(StaffProfile(kavyaMember, designationName: 'Mathematics Teacher')));
    expect(find.text('Category'), findsNothing);
    expect(find.text('Designation'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const StaffProfileLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const StaffProfileFailed(ApiFailure.network()));
    expect(find.byKey(const Key('staffProfile.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const StaffProfileRequested())).called(1);
  });

  testWidgets('says a staff member who is gone is not found, with nothing to retry', (tester) async {
    await pump(tester, const StaffProfileFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')));
    expect(find.byKey(const Key('staffProfile.notFound')), findsOneWidget);
    expect(find.text('This staff member could not be found. They may have been deactivated.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('says a role that may not see staff has no access', (tester) async {
    await pump(tester, const StaffProfileFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.byKey(const Key('staffProfile.forbidden')), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, const StaffProfileLoaded(kavyaProfile), textScale: 2, size: const Size(320, 4000));
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });

  testWidgets('staffErrorText says the caller own record is off limits and a missing one is gone', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(
      staffErrorText(l10n, const ApiFailure(statusCode: 409, code: 'CANNOT_ACT_ON_SELF', message: 'x')),
      "You can't do this to your own record.",
    );
    expect(
      staffErrorText(l10n, const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      'This staff member could not be found. They may have been deactivated.',
    );
    expect(
      staffErrorText(l10n, const ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')),
      l10n.errorForbidden,
    );
  });

  group('Edit', () {
    testWidgets('is offered once the profile is read', (tester) async {
      await pump(tester, const StaffProfileLoaded(kavyaProfile));
      expect(find.byKey(const Key('staffProfile.edit')), findsOneWidget);
    });

    testWidgets('is not offered while the profile loads', (tester) async {
      await pump(tester, const StaffProfileLoading());
      expect(find.byKey(const Key('staffProfile.edit')), findsNothing);
    });

    testWidgets('is not offered when the profile could not be read', (tester) async {
      await pump(tester, const StaffProfileFailed(ApiFailure.network()));
      expect(find.byKey(const Key('staffProfile.edit')), findsNothing);
    });

    Future<List<StaffFormArgs>> pumpWithForm(WidgetTester tester, {required bool? result}) async {
      when(() => bloc.state).thenReturn(const StaffProfileLoaded(kavyaProfile));
      when(() => bloc.id).thenReturn('f1');
      final opened = <StaffFormArgs>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                BlocProvider<StaffProfileBloc>.value(value: bloc, child: const StaffProfileView(isOwner: false)),
          ),
          GoRoute(
            path: AppRoutes.staffForm,
            builder: (context, routeState) {
              opened.add(routeState.extra! as StaffFormArgs);
              return Scaffold(
                body: TextButton(onPressed: () => context.pop(result), child: const Text('close form')),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      return opened;
    }

    testWidgets('opens the form for this staff member, and reads the profile again once it saved', (tester) async {
      final opened = await pumpWithForm(tester, result: true);
      await tester.tap(find.byKey(const Key('staffProfile.edit')));
      await tester.pumpAndSettle();
      expect([opened.single.staffId, opened.single.institutionId], ['f1', null]);
      await tester.tap(find.text('close form'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffProfileRequested())).called(1);
    });

    testWidgets('leaves the profile as it is when the form closed without saving', (tester) async {
      await pumpWithForm(tester, result: null);
      await tester.tap(find.byKey(const Key('staffProfile.edit')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('close form'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const StaffProfileRequested()));
    });
  });
}
