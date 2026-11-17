import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/widgets/notification_bell.dart';
import 'package:bravynix_school_erp/features/notifications/domain/notifications_repository.dart';
import 'package:bravynix_school_erp/features/notifications/presentation/bloc/unread_count_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The bell for a top bar: the unread count (NTF-02), and the inbox on a tap. The count is read again on the way back
/// from the inbox, where notices were read or cleared.
class NotificationBellButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => UnreadCountBloc(getIt<NotificationsRepository>())..add(const UnreadCountRequested()),
    child: const NotificationBellView(),
  );
}

class NotificationBellView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<UnreadCountBloc, int>(
      builder: (context, count) => NotificationBell(
        key: const Key('home.bell'),
        tooltip: l10n.bellTooltip,
        unreadLabel: l10n.bellUnread(count),
        count: count,
        onPressed: () async {
          final bloc = context.read<UnreadCountBloc>();
          await context.push(AppRoutes.inbox);
          bloc.add(const UnreadCountRequested());
        },
      ),
    );
  }
}
