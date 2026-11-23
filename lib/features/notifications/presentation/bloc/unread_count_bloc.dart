import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/notifications/domain/notifications_repository.dart';
import 'package:equatable/equatable.dart';

sealed class UnreadCountEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the home, and coming back to it from the inbox: the count is read again.
final class UnreadCountRequested extends UnreadCountEvent {
  const new();
}

/// How many notices are unread, for the bell (NTF-02): 0 until the first answer. A count that cannot be read keeps the
/// last one: the bell is not worth an error on the home.
class UnreadCountBloc extends Bloc<UnreadCountEvent, int> {
  new(this._notifications) : super(0) {
    on<UnreadCountRequested>(_onRequested);
  }

  final NotificationsRepository _notifications;

  Future<void> _onRequested(UnreadCountRequested event, Emitter<int> emit) async {
    try {
      emit(await _notifications.unreadCount());
    } on ApiFailure {
      // Keeps the last count.
    }
  }
}
