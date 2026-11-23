import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_segmented_control.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/date_badge_card.dart';
import 'package:bravynix_school_erp/core/widgets/month_stepper.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/view/child_panel.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/events_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// "Events" (PRD 7.12): the events and holidays of a month, earliest first, all of them or only the holidays. A parent
/// reads them for the child shown at the top, and changing child reads them again.
class EventsPage extends StatelessWidget {
  const new({this.clock = DateTime.now, super.key});

  /// What "today" is, for the month the screen opens on.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = context.read<SessionBloc>().state.activeRole;
    final parent = role == RoleCode.studentParent;
    // An Owner and an Admin add events; each event says whether the person may change it.
    final canAdd = role == RoleCode.societyOwner || role == RoleCode.institutionAdmin;
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.eventsTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          if (parent) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: ChildPanel(),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Expanded(
            child: BlocBuilder<ActiveChildBloc, ActiveChildState>(
              builder: (context, child) {
                final studentId = parent && child is ActiveChildReady ? child.selected.studentId : null;
                // A new key per child starts the list again for that child, so the last child's events never show.
                return KeyedSubtree(
                  key: ValueKey(studentId),
                  child: BlocProvider(
                    create: (_) =>
                        EventsBloc(getIt<EventsRepository>(), today: clock(), studentId: studentId)
                          ..add(const EventsRequested()),
                    child: EventsView(canAdd: canAdd),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EventsView extends StatelessWidget {
  const new({this.canAdd = false, super.key});

  /// Whether the person may add events.
  final bool canAdd;

  Future<void> _add(BuildContext context) async {
    final bloc = context.read<EventsBloc>();
    final saved = await context.push<bool>(AppRoutes.eventForm, extra: const EventFormArgs());
    if (saved ?? false) bloc.add(const EventsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<EventsBloc>();
    return BlocBuilder<EventsBloc, EventsState>(
      builder: (context, state) => Column(
        children: [
          MonthStepper(
            month: state.month,
            previousTooltip: l10n.eventsPreviousMonth,
            nextTooltip: l10n.eventsNextMonth,
            onChanged: (month) => bloc.add(EventsMonthChosen(month)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
            child: AppSegmentedControl<bool>(
              key: const Key('events.filter'),
              options: const [false, true],
              labelOf: (holidaysOnly) => holidaysOnly ? l10n.eventsFilterHolidays : l10n.eventsFilterAll,
              selected: state.holidaysOnly,
              onChanged: (holidaysOnly) => bloc.add(EventsHolidaysOnlyChosen(holidaysOnly: holidaysOnly)),
            ),
          ),
          if (canAdd)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: AppSpacing.xs),
              child: AppButton(
                key: const Key('events.add'),
                label: l10n.eventAdd,
                icon: Icons.add,
                variant: AppButtonVariant.secondary,
                onPressed: () => _add(context),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: switch (state) {
              EventsLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [88, 88, 88]),
              EventsFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                key: const Key('events.forbidden'),
                title: apiErrorText(l10n, failure, notFound: l10n.errorEventNotFound),
              ),
              EventsFailed(:final failure) => StatePanel.error(
                key: const Key('events.failed'),
                title: apiErrorText(l10n, failure, notFound: l10n.errorEventNotFound),
                actionLabel: l10n.retry,
                onAction: () => bloc.add(const EventsRequested()),
              ),
              EventsLoaded(:final events) when events.isEmpty => StatePanel.empty(
                title: state.holidaysOnly ? l10n.eventsEmptyHolidaysTitle : l10n.eventsEmptyTitle,
                message: l10n.eventsEmptyMessage,
              ),
              EventsLoaded(:final events) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  0,
                  AppSpacing.screenMargin,
                  AppSpacing.screenMargin,
                ),
                children: [
                  for (final event in events) ...[
                    _EventCard(event: event, onOpened: canAdd ? () => bloc.add(const EventsRequested()) : null),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const new({required this.event, this.onOpened});

  final SchoolEvent event;

  /// Said when the event's screen closes: the person who can change events reads the list again.
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = [event.durationLabel, ?event.venue].join(' · ');
    return DateBadgeCard(
      key: ValueKey('events.item.${event.id}'),
      date: event.startDate,
      title: event.title,
      subtitle: note,
      trailing: event.isHoliday ? StatusChip(label: l10n.eventHolidayTag, tone: StatusTone.info) : null,
      onTap: () async {
        await context.push<bool>(AppRoutes.event(event.id));
        onOpened?.call();
      },
    );
  }
}
