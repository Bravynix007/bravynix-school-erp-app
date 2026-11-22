import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/day_picker.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/view/child_panel.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_repository.dart';
import 'package:bravynix_school_erp/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:bravynix_school_erp/features/diary/presentation/view/diary_error_text.dart';
import 'package:bravynix_school_erp/features/diary/presentation/view/diary_form_sheet.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// "Diary" (API design 10.14a): an Owner, an Admin or a teacher reads the diary of a section for a day under the
/// Institution switcher, and writes it; a parent reads the diary of the child shown at the top, and nothing else.
class DiaryPage extends StatelessWidget {
  const new({this.clock = DateTime.now, super.key});

  /// What "today" is: the school day it falls on in IST, as everywhere in the app.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = context.read<SessionBloc>().state;
    final session = active is SessionAuthenticated ? active.session.activeContext : null;
    final parent = session?.role == RoleCode.studentParent;
    final admin = session?.role == RoleCode.societyOwner || session?.role == RoleCode.institutionAdmin;
    final today = Formatters.schoolDay(clock());
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.diaryTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          if (parent) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: ChildPanel(),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Expanded(
            child: parent
                ? BlocBuilder<ActiveChildBloc, ActiveChildState>(
                    builder: (context, child) => child is ActiveChildReady
                        // A new key per child starts the diary again for that child, so the last child's never shows.
                        ? BlocProvider(
                            key: ValueKey(child.selected.studentId),
                            create: (_) => DiaryBloc(
                              getIt<DiaryRepository>(),
                              getIt<AttendanceRepository>(),
                              studentId: child.selected.studentId,
                              clock: clock,
                            )..add(const DiaryStarted()),
                            child: DiaryView(today: today, parent: true),
                          )
                        : StatePanel.empty(
                            key: const Key('diary.noChild'),
                            title: l10n.attendanceCalendarNoChildTitle,
                            message: l10n.diaryNoChildMessage,
                          ),
                  )
                : InstitutionScope(
                    // The scope builds its child again for each Institution, so the classes are those of the one chosen.
                    builder: (context, institution) {
                      // An Owner or an Admin writes at every Institution they reach; a teacher at their own only (API
                      // design 10.14a): at another Institution of theirs they read.
                      final mayWrite = admin || institution.id == session?.homeInstitutionId;
                      return BlocProvider(
                        create: (_) => DiaryBloc(
                          getIt<DiaryRepository>(),
                          getIt<AttendanceRepository>(),
                          institutionId: institution.id,
                          clock: clock,
                        )..add(const DiaryStarted()),
                        child: DiaryView(
                          today: today,
                          parent: false,
                          mayWrite: mayWrite,
                          // An Owner or an Admin changes every entry, a teacher the ones they wrote.
                          mayChange: (entry) =>
                              mayWrite &&
                              (admin || (entry.teacherId != null && entry.teacherId == session?.staffMemberId)),
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

class DiaryView extends StatelessWidget {
  const new({required this.today, required this.parent, this.mayWrite = false, this.mayChange = _never, super.key});

  /// The school day (IST), `YYYY-MM-DD`: the last day that can be read or written.
  final String today;

  /// A parent reads their child's diary; staff choose a section.
  final bool parent;

  /// Whether the person may add entries at this Institution.
  final bool mayWrite;

  /// Whether the person may edit and delete [DiaryEntry]: an Owner or an Admin any, a teacher their own.
  final bool Function(DiaryEntry entry) mayChange;

  static bool _never(DiaryEntry entry) => false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<DiaryBloc, DiaryState>(
      builder: (context, state) => switch (state) {
        DiaryLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [64, 64, 120]),
        DiaryFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
          key: const Key('diary.forbidden'),
          title: diaryErrorText(l10n, failure),
        ),
        DiaryFailed(:final failure) => StatePanel.error(
          key: const Key('diary.failed'),
          title: diaryErrorText(l10n, failure),
          actionLabel: l10n.retry,
          onAction: () => context.read<DiaryBloc>().add(const DiaryStarted()),
        ),
        DiaryReady(:final classes) when !parent && classes.isEmpty => StatePanel.empty(
          key: const Key('diary.noSections'),
          title: l10n.diaryNoSectionsTitle,
          message: l10n.diaryNoSectionsMessage,
        ),
        DiaryReady() => _Screen(state: state, today: today, parent: parent, mayWrite: mayWrite, mayChange: mayChange),
      },
    );
  }
}

class _Screen extends StatelessWidget {
  const new({
    required this.state,
    required this.today,
    required this.parent,
    required this.mayWrite,
    required this.mayChange,
  });

  final DiaryReady state;
  final String today;
  final bool parent;
  final bool mayWrite;
  final bool Function(DiaryEntry entry) mayChange;

  Future<void> _openForm(BuildContext context, {DiaryEntry? entry}) async {
    final bloc = context.read<DiaryBloc>();
    final l10n = AppLocalizations.of(context);
    final saved = await showDiaryFormSheet(
      context,
      sectionId: state.sectionId!,
      today: today,
      day: state.day,
      entry: entry,
    );
    if (saved == null) return;
    // The list reads the day the entry is on: the one it was written for, or the one it was found to be out of date at.
    bloc.add(DiaryRead(day: saved.entry.day));
    if (saved.saved && context.mounted) {
      AppSnackbar.show(context, message: l10n.diarySaved, kind: AppSnackbarKind.success);
    }
  }

  Future<void> _confirmDelete(BuildContext context, DiaryEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<DiaryBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.diaryDeleteTitle,
      message: l10n.diaryDeleteMessage,
      confirmLabel: l10n.diaryDeleteConfirm,
      cancelLabel: l10n.cancel,
      destructive: true,
      icon: Icons.delete_outline,
    );
    if (confirmed ?? false) bloc.add(DiaryEntryRemoved(entry));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<DiaryBloc>();
    final end = Formatters.parseDay(today)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        if (!parent) ...[
          MasterDropdown(
            key: const Key('diary.class'),
            label: l10n.studentClass,
            entries: [for (final choice in state.classes) MasterEntry(id: choice.id, name: choice.name)],
            value: state.classId,
            onChanged: (id) => bloc.add(DiaryClassChosen(id)),
          ),
          const SizedBox(height: AppSpacing.sm),
          MasterDropdown(
            key: const Key('diary.section'),
            label: l10n.studentSection,
            entries: [for (final choice in state.sectionsInClass) MasterEntry(id: choice.id, name: choice.name)],
            value: state.sectionId,
            onChanged: state.classId == null ? null : (id) => bloc.add(DiarySectionChosen(id)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        DayField(
          key: const Key('diary.day'),
          label: l10n.diaryDate,
          day: state.day,
          // The diary of the current year is what anyone looks at, so a year back is as far as the calendar goes.
          firstDay: DateTime(end.year - 1, end.month, end.day),
          lastDay: end,
          onChanged: (day) => bloc.add(DiaryDayChosen(day)),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._body(context, l10n),
      ],
    );
  }

  List<Widget> _body(BuildContext context, AppLocalizations l10n) {
    switch (state.board) {
      case DiaryBoardEmpty():
        return [
          StatePanel.empty(
            key: const Key('diary.pick'),
            title: l10n.diaryChooseSectionTitle,
            message: l10n.diaryChooseSectionMessage,
          ),
        ];
      case DiaryBoardLoading():
        return [
          SkeletonCards(semanticLabel: l10n.loading, heights: const [96, 96]),
        ];
      case DiaryBoardFailed(:final failure):
        return [
          StatePanel.error(
            key: const Key('diary.entriesFailed'),
            title: diaryErrorText(l10n, failure),
            actionLabel: l10n.retry,
            onAction: () => context.read<DiaryBloc>().add(const DiaryRead()),
          ),
        ];
      case DiaryBoardLoaded(:final entries, :final removing, :final failure):
        return [
          if (failure != null) ...[
            InlineMessage.error(
              diaryEntryErrorText(l10n, failure, adding: false),
              key: const Key('diary.actionFailed'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (mayWrite) ...[
            AppButton(
              key: const Key('diary.add'),
              label: l10n.diaryAdd,
              icon: Icons.add,
              variant: AppButtonVariant.secondary,
              onPressed: removing == null ? () => _openForm(context) : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (entries.isEmpty)
            StatePanel.empty(
              key: const Key('diary.empty'),
              title: l10n.diaryEmptyTitle,
              message: l10n.diaryEmptyMessage,
            ),
          for (final entry in entries) ...[
            _EntryCard(
              entry: entry,
              busy: removing == entry.id,
              locked: removing != null,
              onEdit: mayChange(entry) ? () => _openForm(context, entry: entry) : null,
              onDelete: mayChange(entry) ? () => _confirmDelete(context, entry) : null,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ];
    }
  }
}

class _EntryCard extends StatelessWidget {
  const new({required this.entry, required this.busy, required this.locked, this.onEdit, this.onDelete});

  final DiaryEntry entry;

  /// This entry is being deleted.
  final bool busy;

  /// An entry is being deleted, so no card starts another change.
  final bool locked;

  /// Both are set for the people who may change the entry, and neither otherwise.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      key: ValueKey('diary.entry.${entry.id}'),
      // A word wider than the card is shrunk to fit it rather than broken in half.
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget line(String value, TextStyle? style) =>
              Text(value, style: style, textScaler: fitWordScaler(context, value, style, constraints.maxWidth));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              line(entry.subjectName, text.titleSmall),
              line(Formatters.schoolDate(entry.day), text.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              line(entry.description, text.bodyMedium),
              if (entry.teacherName case final teacher?) ...[
                const SizedBox(height: AppSpacing.xs),
                line(l10n.diaryBy(teacher), text.bodySmall),
              ],
              if (onEdit != null && onDelete != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppButton(
                      key: ValueKey('diary.edit.${entry.id}'),
                      label: l10n.diaryEdit,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.medium,
                      onPressed: locked ? null : onEdit,
                    ),
                    AppButton(
                      key: ValueKey('diary.delete.${entry.id}'),
                      label: l10n.diaryDelete,
                      variant: AppButtonVariant.text,
                      size: AppButtonSize.medium,
                      loading: busy,
                      onPressed: locked ? null : onDelete,
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
