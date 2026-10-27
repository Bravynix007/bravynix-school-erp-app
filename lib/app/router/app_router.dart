import 'dart:async';

import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_page.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_chooser_page.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/auth/presentation/splash/splash_page.dart';
import 'package:bravynix_school_erp/features/gallery/presentation/component_gallery_page.dart';
import 'package:bravynix_school_erp/features/home/presentation/home_page.dart';
import 'package:bravynix_school_erp/features/profile/presentation/profile_page.dart';
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
      GoRoute(path: AppRoutes.updateRequired, builder: (_, _) => const UpdateRequiredPage()),
      if (!kReleaseMode) GoRoute(path: AppRoutes.gallery, builder: (_, _) => const ComponentGalleryPage()),
    ],
    debugLogDiagnostics: kDebugMode,
  );
}
