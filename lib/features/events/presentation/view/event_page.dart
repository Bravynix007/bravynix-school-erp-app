import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// One event or holiday (EVT-03), opened from the list or from a notice. A parent reads it for the child they are
/// viewing.
class EventPage extends StatelessWidget {
  const new({required this.id, this.studentId, super.key});

  final String id;

  /// The child a notice is about, when it was opened from one: a parent of children at two Institutions reads the event
  /// for that child, not for the one shown at the top.
  final String? studentId;

  @override
  Widget build(BuildContext context) {
    final parent = context.read<SessionBloc>().state.activeRole == RoleCode.studentParent;
    final child = context.read<ActiveChildBloc>().state;
    final readFor = parent ? studentId ?? (child is ActiveChildReady ? child.selected.studentId : null) : null;
    return BlocProvider(
      create: (_) => EventBloc(getIt<EventsRepository>(), id, studentId: readFor)..add(const EventRequested()),
      child: const EventView(),
    );
  }
}

class EventView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.eventsTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: BlocBuilder<EventBloc, EventState>(
              builder: (context, state) => switch (state) {
                EventLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [120, 160]),
                EventFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                  key: const Key('event.forbidden'),
                  title: apiErrorText(l10n, failure, notFound: l10n.errorEventNotFound),
                ),
                EventFailed(:final failure) when failure.code == 'NOT_FOUND' => StatePanel.empty(
                  key: const Key('event.notFound'),
                  title: l10n.errorEventNotFound,
                ),
                EventFailed(:final failure) => StatePanel.error(
                  key: const Key('event.failed'),
                  title: apiErrorText(l10n, failure, notFound: l10n.errorEventNotFound),
                  actionLabel: l10n.retry,
                  onAction: () => context.read<EventBloc>().add(const EventRequested()),
                ),
                EventLoaded(:final event) => _Detail(event: event),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const new({required this.event});

  final SchoolEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final type = event.holidayType;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ExcludeSemantics(child: Icon(EventText.icon(event), size: 32, color: theme.colorScheme.primary)),
                  const SizedBox(width: AppSpacing.sm),
                  if (event.isHoliday) StatusChip(label: l10n.eventHolidayTag, tone: StatusTone.info),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                header: true,
                child: Text(event.title, style: theme.textTheme.headlineSmall),
              ),
              Text(event.durationLabel, style: theme.textTheme.bodyMedium),
              if (event.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(event.description!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              KeyValueRow(label: l10n.eventWhen, value: EventText.days(l10n, event)),
              if (event.venue != null) KeyValueRow(label: l10n.eventVenue, value: event.venue!),
              KeyValueRow(label: l10n.eventAudience, value: EventText.audience(l10n, event.audience)),
              KeyValueRow(label: l10n.eventScope, value: EventText.scope(l10n, event.scope)),
              if (type != null) KeyValueRow(label: l10n.eventHolidayType, value: EventText.holidayType(l10n, type)),
              if (event.isHoliday) ...[
                KeyValueRow(
                  label: l10n.eventHolidayFor,
                  value: switch ((event.holidayForStudents, event.holidayForStaff)) {
                    (true, true) => l10n.eventHolidayForBoth,
                    (true, false) => l10n.eventHolidayForStudents,
                    _ => l10n.eventHolidayForStaff,
                  },
                ),
                if (event.holidayForStudents)
                  KeyValueRow(
                    label: l10n.eventHolidayClasses,
                    value: event.holidayClassIds.isEmpty
                        ? l10n.eventHolidayEveryClass
                        : l10n.eventHolidaySomeClasses(event.holidayClassIds.length),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
