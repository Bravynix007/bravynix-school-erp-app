import 'dart:async';

import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_year_form_page.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_years_page.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_page.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_chooser_page.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/auth/presentation/splash/splash_page.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_bulk_page.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_form_page.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/classes_page.dart';
import 'package:bravynix_school_erp/features/gallery/presentation/component_gallery_page.dart';
import 'package:bravynix_school_erp/features/home/presentation/home_page.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_form_page.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_page.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institutions_page.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/view/platform_due_page.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/view/platform_dues_page.dart';
import 'package:bravynix_school_erp/features/profile/presentation/profile_page.dart';
import 'package:bravynix_school_erp/features/school_setup/presentation/school_setup_page.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/section_form_page.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/sections_page.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/view/subject_form_page.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/view/subjects_page.dart';
import 'package:bravynix_school_erp/features/update_required/presentation/update_required_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Where the session state sends a location, or null to stay. Pure, so it is
/// unit tested on its own. Screens are hidden by role for convenience only;
/// the API checks every call (system design 13).
String? sessionRedirect(SessionState session, String location) {
  if (location == AppRoutes.updateRequired) return null;
  // The gallery route exists only in non-release builds.
  if (!kReleaseMode && location == AppRoutes.gallery) return null;
  return switch (session) {
    SessionUnknown() || SessionRestoreFailed() => location == AppRoutes.splash ? null : AppRoutes.splash,
    SessionUnauthenticated() => location == AppRoutes.login ? null : AppRoutes.login,
    // Nothing but the chooser until a role is active; it also says when the account has none.
    SessionAuthenticated(:final session) when session.activeContext == null =>
      location == AppRoutes.chooseRole ? null : AppRoutes.chooseRole,
    SessionAuthenticated() => AppRoutes.public.contains(location) ? AppRoutes.home : null,
  };
}

/// The academic year form needs the Institution and year the list passes as `extra`; opened any other way there is
/// nothing to show, so it goes back to the list. Pure, like [sessionRedirect].
String? academicYearFormRedirect(Object? extra) => extra is AcademicYearFormArgs ? null : AppRoutes.academicYears;

/// The class forms need the Institution the list passes as `extra`; opened any other way they go back to the list.
String? classFormRedirect(Object? extra) => extra is ClassFormArgs ? null : AppRoutes.classes;

String? classBulkRedirect(Object? extra) => extra is ClassBulkArgs ? null : AppRoutes.classes;

/// The sections page needs the class, and the section form the class and its sections; opened any other way they go back
/// to the class list.
String? classSectionsRedirect(Object? extra) => extra is SectionsArgs ? null : AppRoutes.classes;

String? sectionFormRedirect(Object? extra) => extra is SectionFormArgs ? null : AppRoutes.classes;

/// Re-runs the redirect whenever the session changes. GoRouter does not own
/// its `refreshListenable`, so whoever creates this disposes it.
class SessionChanges extends ChangeNotifier {
  new(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

GoRouter createRouter(SessionBloc session, {required SessionChanges changes}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: changes,
    redirect: (context, state) => sessionRedirect(session.state, state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(path: AppRoutes.chooseRole, builder: (_, _) => const RoleChooserPage()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage()),
      GoRoute(path: AppRoutes.platformDues, builder: (_, _) => const PlatformDuesPage()),
      GoRoute(
        path: AppRoutes.platformDuePattern,
        builder: (_, state) => PlatformDuePage(id: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.schoolSetup, builder: (_, _) => const SchoolSetupPage()),
      GoRoute(path: AppRoutes.institutions, builder: (_, _) => const InstitutionsPage()),
      GoRoute(path: AppRoutes.institutionNew, builder: (_, _) => const InstitutionFormPage()),
      GoRoute(
        path: AppRoutes.institutionPattern,
        builder: (_, state) => InstitutionPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.institutionEditPattern,
        builder: (_, state) => InstitutionFormPage(id: state.pathParameters['id']),
      ),
      GoRoute(path: AppRoutes.academicYears, builder: (_, _) => const AcademicYearsPage()),
      GoRoute(
        path: AppRoutes.academicYearForm,
        redirect: (_, state) => academicYearFormRedirect(state.extra),
        builder: (_, state) => AcademicYearFormPage(args: state.extra! as AcademicYearFormArgs),
      ),
      GoRoute(path: AppRoutes.subjects, builder: (_, _) => const SubjectsPage()),
      GoRoute(
        path: AppRoutes.subjectForm,
        builder: (_, state) => SubjectFormPage(subject: state.extra is Subject ? state.extra! as Subject : null),
      ),
      GoRoute(path: AppRoutes.classes, builder: (_, _) => const ClassesPage()),
      GoRoute(
        path: AppRoutes.classForm,
        redirect: (_, state) => classFormRedirect(state.extra),
        builder: (_, state) => ClassFormPage(args: state.extra! as ClassFormArgs),
      ),
      GoRoute(
        path: AppRoutes.classBulk,
        redirect: (_, state) => classBulkRedirect(state.extra),
        builder: (_, state) => ClassBulkPage(args: state.extra! as ClassBulkArgs),
      ),
      GoRoute(
        path: AppRoutes.classSections,
        redirect: (_, state) => classSectionsRedirect(state.extra),
        builder: (_, state) => SectionsPage(args: state.extra! as SectionsArgs),
      ),
      GoRoute(
        path: AppRoutes.sectionForm,
        redirect: (_, state) => sectionFormRedirect(state.extra),
        builder: (_, state) => SectionFormPage(args: state.extra! as SectionFormArgs),
      ),
      GoRoute(path: AppRoutes.updateRequired, builder: (_, _) => const UpdateRequiredPage()),
      if (!kReleaseMode) GoRoute(path: AppRoutes.gallery, builder: (_, _) => const ComponentGalleryPage()),
    ],
    debugLogDiagnostics: kDebugMode,
  );
}
