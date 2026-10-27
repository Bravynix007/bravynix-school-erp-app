/// Every route path in one place. Feature routes are added here as modules land.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const updateRequired = '/update-required';
  static const chooseRole = '/choose-role';
  static const profile = '/profile';

  /// The component gallery, registered in debug and profile builds only.
  static const gallery = '/gallery';

  /// Reachable without a session.
  static const Set<String> public = {splash, login, updateRequired};
}
