import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/app/app.dart';
import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/bloc/app_bloc_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Starts the app for the flavor compiled in by `--dart-define-from-file`.
/// Crash reporting (Sentry, system design 17) plugs in here.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), name: 'flutter', stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log('Uncaught', name: 'app', error: error, stackTrace: stack);
    return true;
  };
  Bloc.observer = AppBlocObserver(verbose: kDebugMode && !config.isProduction);

  await configureDependencies(config);
  runApp(const App());
}
