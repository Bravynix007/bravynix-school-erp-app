import 'package:flutter/foundation.dart';

/// The app's language: one of the seven in PRD 11.3. It starts from the
/// phone's language and follows the person's `preferredLanguage` once signed
/// in (ME-02). The API reads it from `Accept-Language` before login.
class AppLanguage extends ValueNotifier<String> {
  new([String? initial]) : super(_supported(initial ?? PlatformDispatcher.instance.locale.languageCode));

  static const supported = ['en', 'hi', 'kn', 'ml', 'mr', 'ta', 'te'];

  static String _supported(String code) => supported.contains(code) ? code : 'en';

  void use(String code) => value = _supported(code);
}
