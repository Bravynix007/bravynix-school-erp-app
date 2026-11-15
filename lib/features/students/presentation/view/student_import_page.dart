import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_progress.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/document_upload_field.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/features/students/domain/student_import.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_import_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The columns the file starts with, as IMP-02 requires them (API design 10.8).
const _columns = 'Name,RollNumber,Class,Section,GuardianName,GuardianPhone,GuardianEmail';

/// School setup → Students → Import (IMP-01 to IMP-03). Closes with `true` once an import was started, so the list reads
/// again: the import carries on at the server whether or not the screen stays.
class StudentImportPage extends StatelessWidget {
  const new({required this.institutionId, super.key});

  final String institutionId;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => StudentImportBloc(
          getIt<AcademicYearsRepository>(),
          getIt<StudentImportsRepository>(),
          institutionId,
        )..add(const StudentImportStarted()),
      ),
      BlocProvider(
        create: (_) => FileUploadBloc(
          getIt<FilesRepository>(),
          purpose: FilePurpose.importCsv,
          institutionId: institutionId,
        ),
      ),
    ],
    child: StudentImportView(picking: getIt<FilePicking>()),
  );
}

class StudentImportView extends StatelessWidget {
  const new({required this.picking, super.key});

  final FilePicking picking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<FileUploadBloc, FileUploadState>(
      // The file that went up is the one the import takes; a file removed or replaced is no longer.
      listenWhen: (previous, current) => current is FileUploadDone || previous is FileUploadDone,
      listener: (context, state) => context.read<StudentImportBloc>().add(
        StudentImportFileChosen(state is FileUploadDone ? state.uploaded.id : null),
      ),
      child: BlocBuilder<StudentImportBloc, StudentImportState>(
        builder: (context, state) => switch (state) {
          StudentImportReady() => _Form(state: state, picking: picking),
          StudentImportRunning() || StudentImportLost() => _Progress(state: state),
          StudentImportFinished() => _Result(run: state.run),
          StudentImportFailed(:final failure) when failure.code == 'FORBIDDEN' => _Frame(
            body: StatePanel.forbidden(key: const Key('import.forbidden'), title: studentErrorText(l10n, failure)),
          ),
          StudentImportFailed(:final failure) => _Frame(
            body: StatePanel.error(
              key: const Key('import.failed'),
              title: studentErrorText(l10n, failure),
              actionLabel: l10n.retry,
              onAction: () => context.read<StudentImportBloc>().add(const StudentImportStarted()),
            ),
          ),
          StudentImportLoading() => _Frame(
            body: SkeletonCards(semanticLabel: l10n.loading, heights: const [120, 200]),
          ),
        },
      ),
    );
  }
}

/// The screen around a body, closing with [started] once an import is on its way.
class _Frame extends StatelessWidget {
  const new({required this.body, this.started = false, this.bottom});

  final Widget body;
  final bool started;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.importTitle, onBack: () => context.pop(started), backTooltip: l10n.back),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottom,
    );
  }
}

class _Form extends StatelessWidget {
  const new({required this.state, required this.picking});

  final StudentImportReady state;
  final FilePicking picking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final bloc = context.read<StudentImportBloc>();
    final failure = state.failure;
    return _Frame(
      bottom: StickyBottomActions(
        primaryLabel: l10n.importStart,
        primaryLoading: state.starting,
        onPrimary: state.canStart ? () => bloc.add(const StudentImportSubmitted()) : null,
        secondaryLabel: l10n.cancel,
        onSecondary: () => Navigator.maybePop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          if (failure != null) ...[
            InlineMessage.error(studentImportErrorText(l10n, failure), key: const Key('import.error')),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(l10n.importIntro, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.importColumns, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  _columns,
                  key: const Key('import.columns'),
                  style: text.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (state.sample case final sample?) ...[
                  Text(l10n.importSampleTitle, style: text.titleSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  SelectableText(
                    sample,
                    key: const Key('import.sample'),
                    style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ] else
                  AppButton(
                    key: const Key('import.showSample'),
                    label: l10n.importShowSample,
                    variant: AppButtonVariant.secondary,
                    loading: state.sampleLoading,
                    onPressed: () => bloc.add(const StudentImportSampleRequested()),
                  ),
                if (state.sampleFailure case final sampleFailure?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  InlineMessage.error(
                    studentImportErrorText(l10n, sampleFailure),
                    key: const Key('import.sampleError'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: l10n.importFile),
          const SizedBox(height: AppSpacing.xs),
          AppCard(child: DocumentUploadField(picking: picking, csv: true)),
          const SizedBox(height: AppSpacing.md),
          MasterDropdown(
            key: const Key('import.year'),
            label: l10n.importYear,
            entries: [for (final year in state.years) MasterEntry(id: year.id, name: year.name)],
            value: state.yearId,
            required: true,
            requiredLabel: l10n.fieldRequired,
            onChanged: (id) => bloc.add(StudentImportYearChosen(id)),
          ),
        ],
      ),
    );
  }
}

/// The import is on: how far the worker has got, and a way to look again when the connection was lost.
class _Progress extends StatelessWidget {
  const new({required this.state});

  final StudentImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final (run, lost) = switch (state) {
      StudentImportRunning(:final run) => (run, null),
      StudentImportLost(:final run, :final failure) => (run, failure),
      _ => (null, null),
    };
    final total = run?.totalRows;
    final progress = run?.progress;
    return _Frame(
      started: true,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  liveRegion: true,
                  header: true,
                  child: Text(l10n.importRunningTitle, style: text.titleMedium),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  run == null || total == null ? l10n.importWaiting : l10n.importReading(run.processedRows, total),
                  key: const Key('import.progress'),
                  style: text.bodyMedium,
                ),
                if (progress != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppProgressBar(value: progress, semanticLabel: l10n.importRunningTitle),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.importLeave, style: text.bodySmall),
              ],
            ),
          ),
          if (lost != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InlineMessage.error(
              studentImportErrorText(l10n, lost),
              key: const Key('import.lost'),
              actionLabel: l10n.importCheckAgain,
              onAction: () => context.read<StudentImportBloc>().add(const StudentImportChecked()),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the import did: how many students, how many rows were skipped and why, and the section capacity warning.
class _Result extends StatelessWidget {
  const new({required this.run});

  final StudentImport run;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final errorCode = run.errorCode;
    final errors = run.rowErrors;
    return _Frame(
      started: true,
      bottom: StickyBottomActions(primaryLabel: l10n.importDoneAction, onPrimary: () => context.pop(true)),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        // The summary card, the notes, a title, and a line for each skipped row.
        itemCount: 3 + errors.length,
        itemBuilder: (context, index) => switch (index) {
          0 => AppCard(
            child: Semantics(
              liveRegion: true,
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorCode == null ? l10n.importDoneTitle : l10n.importFailedTitle,
                    key: const Key('import.done'),
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    errorCode == null
                        ? l10n.importDoneSummary(run.importedRows, run.skippedRows)
                        : studentImportFailureText(l10n, errorCode),
                    key: const Key('import.summary'),
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          1 => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (run.overCapacity)
                  InlineMessage.warning(l10n.importOverCapacity, key: const Key('import.overCapacity')),
                if (errors.isNotEmpty) ...[
                  if (run.overCapacity) const SizedBox(height: AppSpacing.sm),
                  Text(l10n.importRowErrorsTitle, style: text.titleSmall),
                  if (run.skippedRows > errors.length) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.importRowErrorsMore(errors.length, run.skippedRows),
                      key: const Key('import.more'),
                      style: text.bodySmall,
                    ),
                  ],
                ],
              ],
            ),
          ),
          2 => const SizedBox(height: AppSpacing.xs),
          _ => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              l10n.importRowError(errors[index - 3].row, errors[index - 3].message),
              key: Key('import.row.${errors[index - 3].row}'),
              style: text.bodyMedium,
            ),
          ),
        },
      ),
    );
  }
}
