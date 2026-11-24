import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_error_text.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_form_page.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_scope_sheet.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The height of an event's picture, and of the placeholder that stands in for one that does not load.
const eventPictureHeight = 180.0;

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
      child: EventView(owner: context.read<SessionBloc>().state.activeRole == RoleCode.societyOwner),
    );
  }
}

class EventView extends StatelessWidget {
  const new({required this.owner, super.key});

  /// Only an Owner changes where an event belongs.
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.eventsTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: BlocConsumer<EventBloc, EventState>(
              listenWhen: (previous, current) => current is EventGone,
              listener: (context, _) {
                AppSnackbar.show(context, message: l10n.eventDeleted, kind: AppSnackbarKind.success);
                // The list behind this reads again.
                context.pop(true);
              },
              builder: (context, state) => switch (state) {
                EventLoading() || EventGone() => SkeletonCards(semanticLabel: l10n.loading, heights: const [120, 160]),
                EventFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                  key: const Key('event.forbidden'),
                  title: eventErrorText(l10n, failure),
                ),
                EventFailed(:final failure) when failure.code == 'NOT_FOUND' => StatePanel.empty(
                  key: const Key('event.notFound'),
                  title: l10n.errorEventNotFound,
                ),
                EventFailed(:final failure) => StatePanel.error(
                  key: const Key('event.failed'),
                  title: eventErrorText(l10n, failure),
                  actionLabel: l10n.retry,
                  onAction: () => context.read<EventBloc>().add(const EventRequested()),
                ),
                EventLoaded(:final event, :final removing, :final failure) => _Detail(
                  event: event,
                  owner: owner,
                  removing: removing,
                  failure: failure,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const new({required this.event, required this.owner, required this.removing, this.failure});

  final SchoolEvent event;
  final bool owner;

  /// The delete is on its way.
  final bool removing;

  /// Why the last delete was refused.
  final ApiFailure? failure;

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<EventBloc>();
    final saved = await context.push<bool>(AppRoutes.eventForm, extra: EventFormArgs(event: event));
    if (saved ?? false) bloc.add(const EventRequested());
  }

  Future<void> _moveScope(BuildContext context) async {
    final bloc = context.read<EventBloc>();
    if (await showEventScopeSheet(context, event) ?? false) bloc.add(const EventRequested());
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<EventBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.eventDeleteTitle,
      message: l10n.eventDeleteMessage,
      confirmLabel: l10n.eventDeleteConfirm,
      cancelLabel: l10n.cancel,
      destructive: true,
      icon: Icons.delete_outline,
    );
    if (confirmed ?? false) bloc.add(const EventRemoved());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final type = event.holidayType;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        if (failure case final failure?) ...[
          InlineMessage.error(eventErrorText(l10n, failure), key: const Key('event.actionFailed')),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.image case final image?) ...[
                // The event's own picture, which anyone it is shown to can open; one that does not load shows a quiet
                // placeholder of the same size, so the page does not jump.
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Image.network(
                    image.url,
                    key: const Key('event.image'),
                    width: double.infinity,
                    height: eventPictureHeight,
                    fit: BoxFit.cover,
                    semanticLabel: l10n.eventPictureLabel,
                    errorBuilder: (_, _, _) => const SizedBox(
                      key: Key('event.imagePlaceholder'),
                      height: eventPictureHeight,
                      child: ColoredBox(
                        color: AppColors.sunken,
                        child: Center(
                          child: ExcludeSemantics(child: Icon(Icons.image_not_supported_outlined, size: 32)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
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
        if (event.canEdit) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const Key('event.edit'),
            label: l10n.eventEdit,
            variant: AppButtonVariant.secondary,
            onPressed: removing ? null : () => _edit(context),
          ),
          if (owner) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              key: const Key('event.scope'),
              label: l10n.eventScopeChange,
              variant: AppButtonVariant.secondary,
              onPressed: removing ? null : () => _moveScope(context),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            key: const Key('event.delete'),
            label: l10n.eventDelete,
            variant: AppButtonVariant.danger,
            loading: removing,
            onPressed: removing ? null : () => _confirmDelete(context),
          ),
        ],
      ],
    );
  }
}
