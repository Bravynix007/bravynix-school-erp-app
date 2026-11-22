import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/choice_chip_group.dart';
import 'package:bravynix_school_erp/core/widgets/day_picker.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/stale_copy_guard.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_form_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_error_text.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_text.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The event to change, or null to add one.
class EventFormArgs {
  const new({this.event});

  final SchoolEvent? event;
}

/// Events → Add event, or Edit event on one (EVT-02, EVT-04). Closes with `true` once saved, so what is behind it reads
/// again. An Owner adds an event for the whole Society or for one Institution, an Admin for one Institution of theirs.
class EventFormPage extends StatelessWidget {
  const new({required this.args, this.clock = DateTime.now, super.key});

  final EventFormArgs args;

  /// What "today" is, for the days a new event opens on.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => EventFormBloc(
      getIt<EventsRepository>(),
      getIt<InstitutionsRepository>(),
      getIt<MastersRepository>(),
      existing: args.event,
    )..add(const EventFormStarted()),
    child: EventFormView(
      event: args.event,
      owner: context.read<SessionBloc>().state.activeRole == RoleCode.societyOwner,
      today: Formatters.parseDay(Formatters.schoolDay(clock()))!,
    ),
  );
}

class EventFormView extends StatefulWidget {
  const new({required this.owner, required this.today, this.event, super.key});

  final SchoolEvent? event;

  /// Only an Owner can add an event for the whole Society.
  final bool owner;

  /// The school day, which a new event starts and ends on.
  final DateTime today;

  @override
  State<EventFormView> createState() => _EventFormViewState();
}

class _EventFormViewState extends State<EventFormView> {
  late final _title = TextEditingController(text: widget.event?.title);
  late final _duration = TextEditingController(text: widget.event?.durationLabel);
  late final _description = TextEditingController(text: widget.event?.description);
  late final _venue = TextEditingController(text: widget.event?.venue);
  late DateTime _start = widget.event?.startDate ?? widget.today;
  late DateTime _end = widget.event?.endDate ?? widget.today;
  late EventAudience _audience = widget.event?.audience ?? EventAudience.everyone;
  late String? _preset = widget.event?.presetImageCode;
  late bool _isHoliday = widget.event?.isHoliday ?? false;
  late HolidayType? _holidayType = widget.event?.holidayType;
  late bool _forStudents = widget.event?.holidayForStudents ?? false;
  late bool _forStaff = widget.event?.holidayForStaff ?? false;
  late final Set<String> _classIds = {...?widget.event?.holidayClassIds};
  late EventScope _scope = widget.owner ? EventScope.society : EventScope.institution;
  String? _institutionId;

  /// The fields a refusal can name; a refusal that names anything else is said above the form.
  static const _fields = {
    'title',
    'durationLabel',
    'startDate',
    'endDate',
    'description',
    'venue',
    'institutionId',
    'holidayType',
    'holidayForStudents',
    'holidayForStaff',
    'holidayPredefinedClassIds',
  };

  /// What the form shows no field for: a refusal that names one of these is said above it.
  bool _namesOnly(ApiFailure failure) => failure.namesOnly(_fields);

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _description.dispose();
    _venue.dispose();
    super.dispose();
  }

  /// The Institution chosen if the form offers it, else the only one it offers, else null: one that is no longer offered
  /// must be chosen again.
  String? _offered(EventOptions options) {
    final ids = [for (final institution in options.institutions) institution.id];
    if (ids.contains(_institutionId)) return _institutionId;
    return ids.length == 1 ? ids.single : null;
  }

  void _submit(EventOptions options) => context.read<EventFormBloc>().add(
    EventFormSubmitted(
      EventFields(
        title: _title.text,
        startDate: _start,
        endDate: _end,
        durationLabel: _duration.text,
        audience: _audience,
        description: _description.text,
        venue: _venue.text,
        presetImageCode: _preset,
        isHoliday: _isHoliday,
        holidayType: _holidayType,
        holidayForStudents: _forStudents,
        holidayForStaff: _forStaff,
        // Only the classes the form offers, in its order.
        holidayClassIds: [
          for (final entry in options.classes)
            if (_classIds.contains(entry.id)) entry.id,
        ],
        scope: _scope,
        institutionId: _offered(options),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<EventFormBloc, EventFormState>(
      listenWhen: (previous, current) => current is EventFormSaved,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.eventSaved, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      builder: (context, state) {
        final editing = state is EventFormEditing ? state : null;
        final failure = editing?.failure;
        return StaleCopyGuard(
          stale: failure?.outdatesCopy ?? false,
          child: Scaffold(
            body: Column(
              children: [
                AppTopBar(
                  title: widget.event == null ? l10n.eventAddTitle : l10n.eventEditTitle,
                  onBack: () => Navigator.maybePop(context),
                  backTooltip: l10n.back,
                ),
                Expanded(
                  child: switch (state) {
                    EventFormLoading() || EventFormSaved() => SkeletonCards(
                      semanticLabel: l10n.loading,
                      heights: const [64, 64, 64],
                    ),
                    EventFormLoadFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                      key: const Key('eventForm.forbidden'),
                      title: eventErrorText(l10n, failure),
                    ),
                    EventFormLoadFailed(:final failure) => StatePanel.error(
                      key: const Key('eventForm.failed'),
                      title: eventErrorText(l10n, failure),
                      actionLabel: l10n.retry,
                      onAction: () => context.read<EventFormBloc>().add(const EventFormStarted()),
                    ),
                    EventFormEditing(:final options) when widget.event == null && options.institutions.isEmpty =>
                      StatePanel.empty(
                        key: const Key('eventForm.noInstitutions'),
                        title: l10n.errorEventNoInstitutions,
                      ),
                    EventFormEditing(:final options) => _form(context, l10n, options, failure),
                  },
                ),
              ],
            ),
            bottomNavigationBar: editing == null || (widget.event == null && editing.options.institutions.isEmpty)
                ? null
                : StickyBottomActions(
                    primaryLabel: l10n.eventSave,
                    primaryLoading: editing.saving,
                    onPrimary: editing.saving ? null : () => _submit(editing.options),
                    secondaryLabel: l10n.cancel,
                    onSecondary: () => Navigator.maybePop(context),
                  ),
          ),
        );
      },
    );
  }

  Widget _form(BuildContext context, AppLocalizations l10n, EventOptions options, ApiFailure? failure) {
    String? error(String field) => failure == null ? null : eventFieldError(l10n, failure, field);
    final first = DateTime(widget.today.year - 1, widget.today.month, widget.today.day);
    final last = DateTime(widget.today.year + 2, widget.today.month, widget.today.day);
    final earliest = [first, ?widget.event?.startDate].reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = [last, ?widget.event?.endDate].reduce((a, b) => a.isAfter(b) ? a : b);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        // A refused field is shown under it; any other refusal (a scope, a stale event) is said above.
        if (failure != null && !_namesOnly(failure)) ...[
          // The event was changed or removed meanwhile, so what is behind this form reads it again.
          InlineMessage.error(
            eventErrorText(l10n, failure),
            key: const Key('eventForm.error'),
            actionLabel: failure.outdatesCopy ? l10n.backToList : null,
            onAction: () => context.pop(true),
            actionKey: const Key('eventForm.backToList'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppTextField(
          key: const Key('eventForm.title'),
          label: l10n.eventFieldTitle,
          controller: _title,
          required: true,
          requiredLabel: l10n.fieldRequired,
          error: error('title'),
          inputFormatters: [LengthLimitingTextInputFormatter(150)],
        ),
        const SizedBox(height: AppSpacing.sm),
        DayField(
          key: const Key('eventForm.start'),
          label: l10n.eventFieldStart,
          day: Formatters.isoDay(_start),
          firstDay: earliest,
          lastDay: latest,
          error: error('startDate'),
          // An end that falls before a later start moves with it.
          onChanged: (day) => setState(() {
            _start = Formatters.parseDay(day)!;
            if (_end.isBefore(_start)) _end = _start;
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        DayField(
          key: const Key('eventForm.end'),
          label: l10n.eventFieldEnd,
          day: Formatters.isoDay(_end),
          firstDay: earliest,
          lastDay: latest,
          error: error('endDate'),
          onChanged: (day) => setState(() => _end = Formatters.parseDay(day)!),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const Key('eventForm.duration'),
          label: l10n.eventFieldDuration,
          hint: l10n.eventFieldDurationHint,
          controller: _duration,
          required: true,
          requiredLabel: l10n.fieldRequired,
          error: error('durationLabel'),
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const Key('eventForm.description'),
          label: l10n.eventFieldDescription,
          controller: _description,
          error: error('description'),
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          inputFormatters: [LengthLimitingTextInputFormatter(2000)],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const Key('eventForm.venue'),
          label: l10n.eventFieldVenue,
          controller: _venue,
          error: error('venue'),
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.eventAudience),
        const SizedBox(height: AppSpacing.xs),
        ChoiceChipGroup<EventAudience>(
          key: const Key('eventForm.audience'),
          options: EventAudience.values,
          labelOf: (audience) => EventText.audience(l10n, audience),
          selected: _audience,
          onSelected: (audience) => setState(() => _audience = audience),
        ),
        if (widget.event == null) ...[
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: l10n.eventScope),
          const SizedBox(height: AppSpacing.xs),
          if (widget.owner) ...[
            ChoiceChipGroup<EventScope>(
              key: const Key('eventForm.scope'),
              options: EventScope.values,
              labelOf: (scope) => EventText.scope(l10n, scope),
              selected: _scope,
              onSelected: (scope) => setState(() => _scope = scope),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_scope == EventScope.institution)
            AppDropdownField<String>(
              key: const Key('eventForm.institution'),
              label: l10n.eventFieldInstitution,
              value: _offered(options),
              required: true,
              requiredLabel: l10n.fieldRequired,
              error: error('institutionId'),
              items: [
                for (final institution in options.institutions)
                  DropdownMenuItem(value: institution.id, child: Text(institution.name)),
              ],
              onChanged: (id) => setState(() => _institutionId = id),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.eventFieldPicture),
        const SizedBox(height: AppSpacing.xs),
        ChoiceChipGroup<String?>(
          key: const Key('eventForm.picture'),
          options: [null, ...EventText.presetIcons.keys],
          labelOf: (code) => EventText.presetName(l10n, code),
          selected: _preset,
          onSelected: (code) => setState(() => _preset = code),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSwitchTile(
          key: const Key('eventForm.holiday'),
          title: l10n.eventIsHoliday,
          subtitle: l10n.eventIsHolidayHelper,
          value: _isHoliday,
          onChanged: (value) => setState(() => _isHoliday = value),
        ),
        if (_isHoliday) ..._holiday(l10n, options, error),
      ],
    );
  }

  List<Widget> _holiday(AppLocalizations l10n, EventOptions options, String? Function(String field) error) => [
    const SizedBox(height: AppSpacing.sm),
    AppDropdownField<HolidayType>(
      key: const Key('eventForm.holidayType'),
      label: l10n.eventHolidayType,
      value: _holidayType,
      required: true,
      requiredLabel: l10n.fieldRequired,
      error: error('holidayType'),
      items: [
        for (final type in HolidayType.values)
          DropdownMenuItem(value: type, child: Text(EventText.holidayType(l10n, type))),
      ],
      onChanged: (type) => setState(() => _holidayType = type),
    ),
    const SizedBox(height: AppSpacing.sm),
    SectionHeader(title: l10n.eventHolidayFor),
    AppCheckboxTile(
      key: const Key('eventForm.forStudents'),
      title: l10n.eventHolidayForStudents,
      value: _forStudents,
      onChanged: (value) => setState(() => _forStudents = value),
    ),
    AppCheckboxTile(
      key: const Key('eventForm.forStaff'),
      title: l10n.eventHolidayForStaff,
      value: _forStaff,
      onChanged: (value) => setState(() => _forStaff = value),
    ),
    if (error('holidayForStudents') case final problem?)
      InlineMessage.error(problem, key: const Key('eventForm.forError')),
    if (_forStudents) ...[
      const SizedBox(height: AppSpacing.sm),
      SectionHeader(title: l10n.eventHolidayClasses),
      Text(l10n.eventHolidayClassesHelper, style: Theme.of(context).textTheme.bodySmall),
      for (final entry in options.classes)
        AppCheckboxTile(
          key: ValueKey('eventForm.class.${entry.id}'),
          title: entry.name,
          value: _classIds.contains(entry.id),
          onChanged: (value) => setState(() => value ? _classIds.add(entry.id) : _classIds.remove(entry.id)),
        ),
      if (error('holidayPredefinedClassIds') case final problem?)
        InlineMessage.error(problem, key: const Key('eventForm.classesError')),
    ],
  ];
}
