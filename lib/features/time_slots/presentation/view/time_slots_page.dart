import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slots_repository.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/bloc/time_slots_bloc.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/view/time_slot_error_text.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/view/time_slot_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What a period is called on screen: its name when the school gave it one, else its number.
String timeSlotName(AppLocalizations l10n, TimeSlot slot) => slot.label ?? l10n.timeSlotName(slot.periodNo);

/// School setup → Period timings: the periods of the chosen Institution's current year, earliest first (TTS-01). Owners
/// and Institution Admins reach School setup, and both may add, change and deactivate (API design 9.7).
class TimeSlotsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.timeSlotsTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: InstitutionScope(
              builder: (context, institution) => BlocProvider(
                create: (_) => TimeSlotsBloc(getIt<TimeSlotsRepository>(), institution.id)..add(const ListRequested()),
                child: const TimeSlotsView(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The periods of one Institution, under the switcher.
class TimeSlotsView extends StatelessWidget {
  const new({super.key});

  Future<void> _openForm(BuildContext context, {TimeSlot? slot}) async {
    final bloc = context.read<TimeSlotsBloc>();
    final saved = await context.push<bool>(
      AppRoutes.timeSlotForm,
      extra: TimeSlotFormArgs(institutionId: bloc.institutionId, slot: slot),
    );
    if (saved ?? false) bloc.add(const ListRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<TimeSlotsBloc, ListState<TimeSlot>>(
      listenWhen: (previous, current) => current is ListLoaded<TimeSlot> && current.changed != null,
      listener: (context, state) =>
          AppSnackbar.show(context, message: l10n.timeSlotDeactivated, kind: AppSnackbarKind.success),
      builder: (context, state) => switch (state) {
        ListLoading<TimeSlot>() => SkeletonCards(semanticLabel: l10n.loading, heights: const [96, 96]),
        ListFailed<TimeSlot>(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
          key: const Key('timeSlots.forbidden'),
          title: timeSlotErrorText(l10n, failure),
        ),
        ListFailed<TimeSlot>(:final failure) => StatePanel.error(
          key: const Key('timeSlots.failed'),
          title: timeSlotErrorText(l10n, failure),
          actionLabel: l10n.retry,
          onAction: () => context.read<TimeSlotsBloc>().add(const ListRequested()),
        ),
        ListLoaded<TimeSlot>(:final items) when items.isEmpty => StatePanel.empty(
          title: l10n.timeSlotsEmptyTitle,
          message: l10n.timeSlotsEmptyMessage,
          actionLabel: l10n.timeSlotAdd,
          onAction: () => _openForm(context),
        ),
        ListLoaded<TimeSlot>() => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          children: [
            if (state.actionFailure case final failure?) ...[
              InlineMessage.error(timeSlotErrorText(l10n, failure), key: const Key('timeSlots.actionFailed')),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton(
              key: const Key('timeSlots.add'),
              label: l10n.timeSlotAdd,
              icon: Icons.add,
              variant: AppButtonVariant.secondary,
              onPressed: () => _openForm(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final slot in state.items) ...[
              _SlotCard(
                slot: slot,
                busy: state.busyId == slot.id,
                locked: state.busyId != null,
                onEdit: () => _openForm(context, slot: slot),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      },
    );
  }
}

class _SlotCard extends StatelessWidget {
  const new({required this.slot, required this.busy, required this.locked, required this.onEdit});

  final TimeSlot slot;

  /// A change to this period is on its way.
  final bool busy;

  /// A change to any period is on its way, so no card starts another.
  final bool locked;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      key: ValueKey('timeSlot.${slot.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(timeSlotName(l10n, slot), style: text.titleMedium),
              if (slot.isBreak) StatusChip(label: l10n.timeSlotBreakChip),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.timeSlotTimes(slot.startTime, slot.endTime), style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppButton(
                key: ValueKey('timeSlot.edit.${slot.id}'),
                label: l10n.timeSlotEdit,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: locked ? null : onEdit,
              ),
              AppButton(
                key: ValueKey('timeSlot.deactivate.${slot.id}'),
                label: l10n.timeSlotDeactivate,
                variant: AppButtonVariant.text,
                size: AppButtonSize.medium,
                loading: busy,
                onPressed: locked ? null : () => _confirmDeactivate(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<TimeSlotsBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.timeSlotDeactivateTitle(timeSlotName(l10n, slot)),
      message: l10n.timeSlotDeactivateMessage,
      confirmLabel: l10n.timeSlotDeactivate,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(TimeSlotDeactivated(slot));
  }
}
