import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/day_picker.dart';
import 'package:bravynix_school_erp/core/widgets/field_error_text.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_repository.dart';
import 'package:bravynix_school_erp/features/diary/presentation/bloc/diary_form_bloc.dart';
import 'package:bravynix_school_erp/features/diary/presentation/view/diary_error_text.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The most days back an entry can be dated (API design 10.14a, `MAX_BACKDATE_DAYS`).
const maxDiaryBackdateDays = 7;

/// What the form closed with: the entry [saved], or the entry it was opened on when that turned out to be changed or
/// removed meanwhile, so the screen reads the day it is on again.
class DiaryFormResult {
  const new saved(this.entry) : saved = true;

  const new outdated(this.entry) : saved = false;

  final DiaryEntry entry;
  final bool saved;
}

/// Add Diary Entry to [sectionId], or Edit [entry] (DIA-02, DIA-03). [today] is the school day (`YYYY-MM-DD`): the last
/// day an entry can be dated, and [day] the one the form opens on. Answers the [DiaryFormResult], or null when the sheet
/// is closed without saving.
Future<DiaryFormResult?> showDiaryFormSheet(
  BuildContext context, {
  required String sectionId,
  required String today,
  required String day,
  DiaryEntry? entry,
}) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<DiaryFormResult>(
    context: context,
    title: entry == null ? l10n.diaryAddTitle : l10n.diaryEditTitle,
    builder: (_) => BlocProvider(
      create: (_) =>
          DiaryFormBloc(getIt<DiaryRepository>(), getIt<SubjectsRepository>(), sectionId: sectionId, existing: entry)
            ..add(const DiaryFormStarted()),
      child: DiaryForm(today: today, day: entry?.day ?? day, entry: entry),
    ),
  );
}

class DiaryForm extends StatefulWidget {
  const new({required this.today, required this.day, this.entry, super.key});

  final String today;

  /// The day the form opens on, `YYYY-MM-DD`.
  final String day;
  final DiaryEntry? entry;

  @override
  State<DiaryForm> createState() => _DiaryFormState();
}

class _DiaryFormState extends State<DiaryForm> {
  late final _description = TextEditingController(text: widget.entry?.description);
  late String? _subjectId = widget.entry?.subjectId;
  late String _day = widget.day;

  /// The fields a refusal can name; a refusal that names anything else is said above the form.
  static const _fields = {'subjectId', 'description'};

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit(DiaryFormEditing editing) => context.read<DiaryFormBloc>().add(
    DiaryFormSubmitted(
      DiaryFields(
        // A subject that is no longer offered must be chosen again.
        subjectId: editing.subjects.any((subject) => subject.id == _subjectId) ? _subjectId : null,
        day: _day,
        description: _description.text,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<DiaryFormBloc, DiaryFormState>(
      listenWhen: (previous, current) => current is DiaryFormSaved,
      listener: (context, state) => Navigator.of(context).pop(DiaryFormResult.saved((state as DiaryFormSaved).entry)),
      builder: (context, state) => switch (state) {
        // A box and not SkeletonCards, which fills a screen: this sits in a sheet as tall as it needs.
        DiaryFormLoading() || DiaryFormSaved() => Semantics(
          label: l10n.loading,
          liveRegion: true,
          child: const ExcludeSemantics(child: SkeletonBox(height: 160, radius: AppRadius.card)),
        ),
        DiaryFormLoadFailed(:final failure) => InlineMessage.error(
          diaryErrorText(l10n, failure),
          key: const Key('diaryForm.loadFailed'),
          actionLabel: l10n.retry,
          onAction: () => context.read<DiaryFormBloc>().add(const DiaryFormStarted()),
        ),
        DiaryFormEditing() => _form(context, l10n, state),
      },
    );
  }

  Widget _form(BuildContext context, AppLocalizations l10n, DiaryFormEditing editing) {
    final failure = editing.failure;
    String? error(String field) {
      final problem = failure?.fieldError(field);
      return problem == null ? null : fieldErrorText(l10n, problem);
    }

    // The entry was changed or removed meanwhile, so every way out hands it back and the list reads its day again.
    final stale = failure?.outdatesCopy ?? false;
    // A refused field is shown under it; any other refusal (a date, a subject that is not theirs) is said above.
    final onFields = failure != null && failure.namesOnly(_fields);
    final end = Formatters.parseDay(widget.today)!;
    final earliest = end.subtract(const Duration(days: maxDiaryBackdateDays));
    final entryDay = Formatters.parseDay(widget.entry?.day ?? widget.today)!;
    return PopScope<DiaryFormResult>(
      canPop: !stale,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(DiaryFormResult.outdated(widget.entry!));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failure != null && !onFields) ...[
            InlineMessage.error(
              diaryEntryErrorText(l10n, failure, adding: widget.entry == null),
              key: const Key('diaryForm.error'),
              actionLabel: stale ? l10n.backToList : null,
              onAction: () => Navigator.of(context).pop(DiaryFormResult.outdated(widget.entry!)),
              actionKey: const Key('diaryForm.backToList'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppDropdownField<String>(
            key: const Key('diaryForm.subject'),
            label: l10n.diarySubject,
            value: editing.subjects.any((subject) => subject.id == _subjectId) ? _subjectId : null,
            required: true,
            requiredLabel: l10n.fieldRequired,
            error: error('subjectId'),
            items: [
              for (final subject in editing.subjects) DropdownMenuItem(value: subject.id, child: Text(subject.name)),
            ],
            onChanged: (value) => setState(() => _subjectId = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          DayField(
            key: const Key('diaryForm.day'),
            label: l10n.diaryDate,
            day: _day,
            // An old entry keeps its own day, which a text correction does not check again.
            firstDay: entryDay.isBefore(earliest) ? entryDay : earliest,
            lastDay: end,
            onChanged: (day) => setState(() => _day = day),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: const Key('diaryForm.description'),
            label: l10n.diaryDescription,
            controller: _description,
            required: true,
            requiredLabel: l10n.fieldRequired,
            error: error('description'),
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            inputFormatters: [LengthLimitingTextInputFormatter(maxDiaryDescription)],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const Key('diaryForm.save'),
            label: l10n.diarySave,
            loading: editing.saving,
            onPressed: editing.saving ? null : () => _submit(editing),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            key: const Key('diaryForm.cancel'),
            label: l10n.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
