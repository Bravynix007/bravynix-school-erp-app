import 'dart:async';

import 'package:bravynix_school_erp/core/network/api_failure.dart';

/// App-wide signals raised by the network layer, so the session bloc and the
/// router can react without every screen handling them (API design 8.2).
class ApiEvents {
  final _sessionEnded = StreamController<ApiFailure>.broadcast();
  final _updateRequired = StreamController<ApiFailure>.broadcast();

  /// A 401 that a refresh cannot fix: the app signs out locally and shows the reason.
  Stream<ApiFailure> get sessionEnded => _sessionEnded.stream;

  /// A 426: the app is too old and must be updated from the store (API design 5.2).
  Stream<ApiFailure> get updateRequired => _updateRequired.stream;

  void emitSessionEnded(ApiFailure failure) => _sessionEnded.add(failure);

  void emitUpdateRequired(ApiFailure failure) => _updateRequired.add(failure);

  Future<void> dispose() async {
    await _sessionEnded.close();
    await _updateRequired.close();
  }
}
