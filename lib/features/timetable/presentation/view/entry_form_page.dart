import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/stale_copy_guard.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slots_repository.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/view/time_slots_page.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_repository.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/bloc/entry_form_bloc.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/day_name.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/timetable_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which section the form adds to, at which Institution, and the entry it changes (null to add).
class EntryFormArgs {
  const new({required this.sectionId, required this.institutionId, this.entry});

  final String sectionId;
  final String institutionId;
  final TimetableEntry? entry;
}

/// A section's timetable → Add entry, or Edit on one (TT-02, TT-03). Closes with `true` once saved, so the week behind
/// it reads again.
class EntryFormPage extends StatelessWidget {
  const new({required this.args, super.key});

  final EntryFormArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => EntryFormBloc(
      getIt<TimetableRepository>(),
      getIt<TimeSlotsRepository>(),
      getIt<SubjectsRepository>(),
      getIt<StaffRepository>(),
      sectionId: args.sectionId,
      institutionId: args.institutionId,
      existing: args.entry,
    )..add(const EntryFormStarted()),
    child: EntryFormView(entry: args.entry),
  );
}

class EntryFormView extends StatefulWidget {
  const new({this.entry, super.key});

  final TimetableEntry? entry;

  @override
  State<EntryFormView> createState() => _EntryFormViewState();
}

class _EntryFormViewState extends State<EntryFormView> {
  late int? _day = widget.entry?.dayOfWeek;
  late String? _slotId = widget.entry?.slot.id;
  late bool _isBreak = widget.entry?.isBreak ?? false;
  late String? _subjectId = widget.entry?.subject?.id;
  late String? _teacherId = widget.entry?.teacher?.id;

  /// The fields a refusal can name; a refusal that names anything else is said above the form.
  static const _fields = {'dayOfWeek', 'timeSlotId', 'subjectId', 'staffMemberId'};

  /// [chosen] if the form offers it, else null: a subject or teacher that is no longer offered must be chosen again.
  static String? _offered(String? chosen, Iterable<String> ids) => ids.contains(chosen) ? chosen : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    return BlocConsumer<EntryFormBloc, EntryFormState>(
      listenWhen: (previous, current) => current is EntryFormSaved,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.timetableEntrySaved, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      builder: (context, state) {
        final editing = state is EntryFormEditing ? state : null;
        final failure = editing?.failure;
        return StaleCopyGuard(
          stale: failure?.outdatesCopy ?? false,
          child: Scaffold(
            body: Column(
              children: [
                AppTopBar(
                  title: entry == null ? l10n.timetableEntryAddTitle : l10n.timetableEntryEditTitle,
                  onBack: () => Navigator.maybePop(context),
                  backTooltip: l10n.back,
                ),
                Expanded(
                  child: switch (state) {
                    EntryFormLoading() || EntryFormSaved() => SkeletonCards(
                      semanticLabel: l10n.loading,
                      heights: const [64, 64, 64],
                    ),
                    EntryFormLoadFailed(:final failure) when failure.refused => StatePanel.forbidden(
                      key: const Key('entryForm.forbidden'),
                      title: timetableEntryErrorText(l10n, failure),
                    ),
                    EntryFormLoadFailed(:final failure) => StatePanel.error(
                      key: const Key('entryForm.failed'),
                      title: timetableEntryErrorText(l10n, failure),
                      actionLabel: l10n.retry,
                      onAction: () => context.read<EntryFormBloc>().add(const EntryFormStarted()),
                    ),
                    EntryFormEditing(:final options) when options.slots.isEmpty => StatePanel.empty(
                      title: l10n.timetableEntryNoPeriodsTitle,
                      message: l10n.timetableEntryNoPeriodsMessage,
                    ),
                    EntryFormEditing(:final options) => _form(context, l10n, options, failure),
                  },
                ),
              ],
            ),
            bottomNavigationBar: editing == null || editing.options.slots.isEmpty
                ? null
                : StickyBottomActions(
                    primaryLabel: l10n.timetableEntrySave,
                    primaryLoading: editing.saving,
                    onPrimary: editing.saving ? null : () => _submit(context, editing.options),
                    secondaryLabel: l10n.cancel,
                    onSecondary: () => Navigator.maybePop(context),
                  ),
          ),
        );
      },
    );
  }

  void _submit(BuildContext context, EntryOptions options) => context.read<EntryFormBloc>().add(
    EntryFormSubmitted(
      EntryFields(
        dayOfWeek: _day,
        timeSlotId: _offered(_slotId, [for (final slot in options.slots) slot.id]),
        isBreak: _isBreak,
        subjectId: _offered(_subjectId, [for (final subject in options.subjects) subject.id]),
        staffMemberId: _offered(_teacherId, [for (final teacher in options.teachers) teacher.id]),
      ),
    ),
  );

  Widget _form(BuildContext context, AppLocalizations l10n, EntryOptions options, ApiFailure? failure) {
    final locale = Localizations.localeOf(context).toString();
    String? error(String field) => failure == null ? null : timetableEntryFieldError(l10n, failure, field);
    // A refused field is shown under it; any other refusal (a clash, a stale entry) is said above.
    final onFields = failure != null && failure.namesOnly(_fields);
    final slotIds = [for (final slot in options.slots) slot.id];
    final slot = options.slots.where((slot) => slot.id == _slotId).firstOrNull;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        if (failure != null && !onFields) ...[
          // The entry was changed or removed meanwhile and no endpoint reads one entry, so the week is read again.
          InlineMessage.error(
            timetableEntryErrorText(l10n, failure),
            key: const Key('entryForm.error'),
            actionLabel: failure.outdatesCopy ? l10n.backToList : null,
            onAction: () => context.pop(true),
            actionKey: const Key('entryForm.backToList'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppDropdownField<int>(
          key: const Key('entryForm.day'),
          label: l10n.timetableEntryDay,
          value: _day,
          required: true,
          requiredLabel: l10n.fieldRequired,
          error: error('dayOfWeek'),
          items: [
            for (final day in [1, 2, 3, 4, 5, 6]) DropdownMenuItem(value: day, child: Text(dayName(locale, day))),
          ],
          onChanged: (value) => setState(() => _day = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppDropdownField<String>(
          key: const Key('entryForm.period'),
          label: l10n.timetableEntryPeriod,
          value: _offered(_slotId, slotIds),
          required: true,
          requiredLabel: l10n.fieldRequired,
          error: error('timeSlotId'),
          items: [
            for (final slot in options.slots)
              DropdownMenuItem(
                value: slot.id,
                child: Text('${timeSlotName(l10n, slot)} · ${l10n.timeSlotTimes(slot.startTime, slot.endTime)}'),
              ),
          ],
          onChanged: (value) => setState(() {
            _slotId = value;
            // A break period takes only a break.
            if (options.slots.any((slot) => slot.id == value && slot.isBreak)) _isBreak = true;
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSwitchTile(
          key: const Key('entryForm.break'),
          title: l10n.timetableEntryBreak,
          subtitle: l10n.timetableEntryBreakHelper,
          value: _isBreak,
          onChanged: slot?.isBreak ?? false ? null : (value) => setState(() => _isBreak = value),
        ),
        if (!_isBreak) ...[
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField<String>(
            key: const Key('entryForm.subject'),
            label: l10n.timetableEntrySubject,
            value: _offered(_subjectId, [for (final subject in options.subjects) subject.id]),
            required: true,
            requiredLabel: l10n.fieldRequired,
            error: error('subjectId'),
            items: [
              for (final subject in options.subjects) DropdownMenuItem(value: subject.id, child: Text(subject.name)),
            ],
            onChanged: (value) => setState(() => _subjectId = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField<String>(
            key: const Key('entryForm.teacher'),
            label: l10n.timetableEntryTeacher,
            value: _offered(_teacherId, [for (final teacher in options.teachers) teacher.id]),
            required: true,
            requiredLabel: l10n.fieldRequired,
            error: error('staffMemberId'),
            items: [
              for (final teacher in options.teachers)
                DropdownMenuItem(value: teacher.id, child: Text(teacher.fullName)),
            ],
            onChanged: (value) => setState(() => _teacherId = value),
          ),
        ],
      ],
    );
  }
}
