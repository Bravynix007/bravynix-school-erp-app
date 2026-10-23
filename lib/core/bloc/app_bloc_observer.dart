import 'dart:developer';

import 'package:bloc/bloc.dart';

/// Logs bloc errors in every build, and transitions in dev only. State is
/// never logged in release builds: it can hold children's data.
class AppBlocObserver extends BlocObserver {
  const new({this.verbose = false});

  final bool verbose;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (verbose) log('${bloc.runtimeType} ${change.nextState.runtimeType}', name: 'bloc');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('${bloc.runtimeType} failed', name: 'bloc', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
