import 'dart:async';

import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_segmented_control.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';
import 'package:bravynix_school_erp/features/notifications/domain/notifications_repository.dart';
import 'package:bravynix_school_erp/features/notifications/presentation/bloc/inbox_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The bell's screen (PRD 7.17): the person's notices by tab, newest first, with mark all read and the trash icon.
/// Every role has it, and a block does not stop it (API design 6.5).
class InboxPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = InboxTab.of(context.read<SessionBloc>().state.activeRole);
    return BlocProvider(
      create: (_) => InboxBloc(getIt<NotificationsRepository>(), tabs.first)..add(InboxRequested(tabs.first)),
      child: InboxView(tabs: tabs),
    );
  }
}

class InboxView extends StatelessWidget {
  const new({required this.tabs, super.key});

  final List<InboxTab> tabs;

  static String tabLabel(AppLocalizations l10n, InboxTab tab) => switch (tab) {
    InboxTab.onlyForYou => l10n.inboxTabOnlyForYou,
    InboxTab.all => l10n.inboxTabAll,
    InboxTab.allTeachers => l10n.inboxTabAllTeachers,
    InboxTab.allStudents => l10n.inboxTabAllStudents,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<InboxBloc>();
    return Scaffold(
      body: BlocBuilder<InboxBloc, InboxState>(
        builder: (context, state) {
          final tab = switch (state) {
            InboxLoading(:final tab) || InboxFailed(:final tab) || InboxLoaded(:final tab) => tab,
          };
          final loaded = state is InboxLoaded ? state : null;
          return Column(
            children: [
              AppTopBar(
                title: l10n.inboxTitle,
                onBack: () => context.pop(),
                backTooltip: l10n.back,
                actions: [
                  IconButton(
                    key: const Key('inbox.markAllRead'),
                    tooltip: l10n.inboxMarkAllRead,
                    icon: const Icon(Icons.done_all),
                    onPressed: loaded != null && loaded.hasUnread && !loaded.working
                        ? () => bloc.add(const InboxMarkedAllRead())
                        : null,
                  ),
                  IconButton(
                    key: const Key('inbox.clear'),
                    tooltip: l10n.inboxClear,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: loaded != null && loaded.items.isNotEmpty && !loaded.working
                        ? () => _confirmClear(context, bloc, tab)
                        : null,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                child: AppSegmentedControl<InboxTab>(
                  key: const Key('inbox.tabs'),
                  options: tabs,
                  labelOf: (tab) => tabLabel(l10n, tab),
                  selected: tab,
                  scrollable: true,
                  onChanged: (next) {
                    if (next != tab) bloc.add(InboxRequested(next));
                  },
                ),
              ),
              Expanded(child: _Body(state: state)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, InboxBloc bloc, InboxTab tab) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.inboxClearTitle,
      message: l10n.inboxClearMessage(tabLabel(l10n, tab)),
      confirmLabel: l10n.inboxClearConfirm,
      cancelLabel: l10n.cancel,
      destructive: true,
      icon: Icons.delete_outline,
    );
    if (confirmed ?? false) bloc.add(const InboxCleared());
  }
}

class _Body extends StatelessWidget {
  const new({required this.state});

  final InboxState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (state) {
      InboxLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [88, 88, 88]),
      InboxFailed(:final tab, :final failure) => StatePanel.error(
        key: const Key('inbox.failed'),
        title: apiErrorText(l10n, failure, notFound: l10n.errorGeneric),
        actionLabel: l10n.retry,
        onAction: () => context.read<InboxBloc>().add(InboxRequested(tab)),
      ),
      InboxLoaded(:final items) when items.isEmpty => StatePanel.empty(
        title: l10n.inboxEmptyTitle,
        message: l10n.inboxEmptyMessage,
      ),
      final InboxLoaded loaded => _List(state: loaded),
    };
  }
}

class _List extends StatelessWidget {
  const new({required this.state});

  final InboxLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<InboxBloc>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        if (state.actionFailure case final failure?) ...[
          InlineMessage.error(
            apiErrorText(l10n, failure, notFound: l10n.errorGeneric),
            key: const Key('inbox.actionFailed'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final item in state.items) ...[
          _ItemCard(
            item: item,
            onTap: () {
              bloc.add(InboxItemOpened(item.id));
              final location = _locationOf(item);
              if (location == null) return;
              // A notice about one child opens the screens of that child, which read the child shown at the top; an
              // event names its child itself.
              if (item.target?.type != NotificationTargetType.event && item.studentId != null) {
                context.read<ActiveChildBloc>().add(ActiveChildChosen(item.studentId!));
              }
              unawaited(context.push(location));
            },
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (state.moreFailure case final failure?) ...[
          InlineMessage.error(
            apiErrorText(l10n, failure, notFound: l10n.errorGeneric),
            key: const Key('inbox.moreFailed'),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (state.hasMore)
          AppButton(
            key: const Key('inbox.more'),
            label: state.moreFailure == null ? l10n.inboxLoadMore : l10n.retry,
            variant: AppButtonVariant.secondary,
            loading: state.loadingMore,
            onPressed: state.working ? null : () => bloc.add(const InboxMoreRequested()),
          ),
      ],
    );
  }
}

/// The screen a notice opens: an absent alert the child's attendance (it goes to guardians, who read the calendar), a
/// diary entry the diary, an event the event.
String? _locationOf(InboxItem item) => switch (item.target?.type) {
  NotificationTargetType.attendance => AppRoutes.attendanceCalendar,
  NotificationTargetType.diary => AppRoutes.diary,
  NotificationTargetType.event => AppRoutes.event(item.target!.id, studentId: item.studentId),
  null => null,
};

class _ItemCard extends StatelessWidget {
  const new({required this.item, required this.onTap});

  final InboxItem item;
  final VoidCallback onTap;

  static IconData _icon(NotificationCategory category) => switch (category) {
    NotificationCategory.attendance => Icons.fact_check_outlined,
    NotificationCategory.diary => Icons.menu_book_outlined,
    NotificationCategory.event => Icons.event_outlined,
    NotificationCategory.other => Icons.notifications_none,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sender = item.senderDisplayName;
    final when = Formatters.instant(item.createdAt);
    return AppCard(
      key: ValueKey('inbox.item.${item.id}'),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(_icon(item.category), color: theme.colorScheme.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            // A word wider than the line is shrunk to fit it rather than broken in half.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final text = theme.textTheme;
                final titleStyle = text.titleSmall?.copyWith(fontWeight: item.isRead ? null : FontWeight.w700);
                final byline = sender == null ? when : l10n.inboxFrom(sender, when);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: titleStyle,
                      textScaler: fitWordScaler(context, item.title, titleStyle, constraints.maxWidth),
                    ),
                    if (item.body.isNotEmpty)
                      Text(
                        item.body,
                        style: text.bodyMedium,
                        textScaler: fitWordScaler(context, item.body, text.bodyMedium, constraints.maxWidth),
                      ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      byline,
                      style: text.bodySmall,
                      textScaler: fitWordScaler(context, byline, text.bodySmall, constraints.maxWidth),
                    ),
                  ],
                );
              },
            ),
          ),
          if (!item.isRead)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs, top: AppSpacing.xxs),
              child: Semantics(
                label: l10n.inboxUnread,
                child: Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}
