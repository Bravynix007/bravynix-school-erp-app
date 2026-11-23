import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/notifications/presentation/bloc/unread_count_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockNotificationsRepository repository;
  setUp(() => repository = MockNotificationsRepository());

  blocTest<UnreadCountBloc, int>(
    'reads the count for the bell',
    build: () {
      when(repository.unreadCount).thenAnswer((_) async => 4);
      return UnreadCountBloc(repository);
    },
    act: (bloc) => bloc.add(const UnreadCountRequested()),
    expect: () => [4],
  );

  blocTest<UnreadCountBloc, int>(
    'keeps the last count when it cannot be read',
    build: () {
      when(repository.unreadCount).thenThrow(const ApiFailure.network());
      return UnreadCountBloc(repository);
    },
    seed: () => 4,
    act: (bloc) => bloc.add(const UnreadCountRequested()),
    expect: () => <int>[],
  );
}
