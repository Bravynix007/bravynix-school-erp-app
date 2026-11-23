import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_scope_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_error_text.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_scope_fields.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Where does this event belong (EVT-06, an Owner only): the whole Society or one Institution. Answers `true` when the
/// event moved, or when it turned out to be changed or removed meanwhile, so the screen reads it again; null when the
/// sheet is closed without saving.
Future<bool?> showEventScopeSheet(BuildContext context, SchoolEvent event) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<bool>(
    context: context,
    title: l10n.eventScopeTitle,
    builder: (_) => BlocProvider(
      create: (_) =>
          EventScopeBloc(getIt<EventsRepository>(), getIt<InstitutionsRepository>(), event)
            ..add(const EventScopeStarted()),
      child: EventScopeForm(event: event),
    ),
  );
}

class EventScopeForm extends StatefulWidget {
  const new({required this.event, super.key});

  final SchoolEvent event;

  @override
  State<EventScopeForm> createState() => _EventScopeFormState();
}

class _EventScopeFormState extends State<EventScopeForm> {
  late EventScope _scope = widget.event.scope;
  late String? _institutionId = widget.event.institutionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<EventScopeBloc, EventScopeState>(
      listenWhen: (previous, current) => current is EventScopeSaved,
      listener: (context, _) => Navigator.of(context).pop(true),
      builder: (context, state) => switch (state) {
        // A box and not SkeletonCards, which fills a screen: this sits in a sheet as tall as it needs.
        EventScopeLoading() || EventScopeSaved() => Semantics(
          label: l10n.loading,
          liveRegion: true,
          child: const ExcludeSemantics(child: SkeletonBox(height: 120, radius: AppRadius.card)),
        ),
        EventScopeLoadFailed(:final failure) => InlineMessage.error(
          eventErrorText(l10n, failure),
          key: const Key('eventScope.loadFailed'),
          // A refusal gives the same answer again, so there is nothing to retry.
          actionLabel: failure.refused ? null : l10n.retry,
          onAction: () => context.read<EventScopeBloc>().add(const EventScopeStarted()),
        ),
        EventScopeEditing() => _form(context, l10n, state),
      },
    );
  }

  Widget _form(BuildContext context, AppLocalizations l10n, EventScopeEditing editing) {
    final failure = editing.failure;
    final institutionId = offeredInstitution(editing.institutions, _institutionId);
    // The event was changed or removed meanwhile: what was read is old, so the way out reads it again.
    final stale = failure?.outdatesCopy ?? false;
    final onField = failure?.namesOnly(const {'institutionId'}) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (failure != null && !onField) ...[
          InlineMessage.error(
            eventErrorText(l10n, failure),
            key: const Key('eventScope.error'),
            actionLabel: stale ? l10n.eventScopeReload : null,
            onAction: () => Navigator.of(context).pop(true),
            actionKey: const Key('eventScope.reload'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        EventScopeFields(
          keyPrefix: 'eventScope',
          scope: _scope,
          onScope: (scope) => setState(() => _scope = scope),
          institutions: editing.institutions,
          institutionId: institutionId,
          onInstitution: (id) => setState(() => _institutionId = id),
          error: failure == null ? null : eventFieldError(l10n, failure, 'institutionId'),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: const Key('eventScope.save'),
          label: l10n.eventSave,
          loading: editing.saving,
          onPressed: editing.saving || stale
              ? null
              : () => context.read<EventScopeBloc>().add(EventScopeSubmitted(_scope, institutionId)),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          key: const Key('eventScope.cancel'),
          label: l10n.cancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
