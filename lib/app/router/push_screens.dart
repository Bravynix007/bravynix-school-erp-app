import 'package:bravynix_school_erp/app/router/app_routes.dart';

/// The route an alert asks to open. The server names the screen in the push (SDD 18: the screen to open, never an ID),
/// and the notice itself then opens its target from the inbox. A name this app does not know opens nothing.
String? routeOfPushScreen(String screen) => switch (screen) {
  'inbox' => AppRoutes.inbox,
  _ => null,
};
