import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/features/documents/domain/document.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/document_upload_field.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_documents_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The documents tab of the staff profile (PRD 7.5): the files kept with the record (STF-14), a way to add one (STF-15),
/// to take one off (DOC-03) and to open its file (FIL-03). Its blocs are provided above the tabs, and what joins them
/// is there too (the profile page), so another tab does not lose a file that is on its way up, a title that is half
/// written, or the word that a document was added. Showing the tab is what reads the list, the first time.
class StaffDocumentsView extends StatefulWidget {
  const new({required this.picking, super.key});

  final FilePicking picking;

  @override
  State<StaffDocumentsView> createState() => _StaffDocumentsViewState();
}

class _StaffDocumentsViewState extends State<StaffDocumentsView> {
  @override
  void initState() {
    super.initState();
    context.read<StaffDocumentsBloc>().add(const StaffDocumentsStarted());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        Text(l10n.staffDocumentsHelper, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        BlocBuilder<StaffDocumentsBloc, StaffDocumentsState>(
          builder: (context, state) => switch (state) {
            // A box and not SkeletonCards, which is a list of its own: this part sits inside the one of the tab.
            StaffDocumentsLoading() => Semantics(
              label: l10n.loading,
              liveRegion: true,
              child: const ExcludeSemantics(child: SkeletonBox(height: 160, radius: AppRadius.card)),
            ),
            StaffDocumentsFailed(:final failure) => InlineMessage.error(
              staffDocumentErrorText(l10n, failure),
              key: const Key('staffDocuments.failed'),
              actionLabel: l10n.retry,
              onAction: () => context.read<StaffDocumentsBloc>().add(const StaffDocumentsStarted()),
            ),
            StaffDocumentsReady() => _Ready(state: state, picking: widget.picking),
          },
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const new({required this.state, required this.picking});

  final StaffDocumentsReady state;
  final FilePicking picking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Documents(state: state),
        // What was refused or could not be opened, whether it was an add, a removal or a link.
        if (state.failure case final failure?) ...[
          const SizedBox(height: AppSpacing.sm),
          InlineMessage.error(staffDocumentErrorText(l10n, failure), key: const Key('staffDocuments.error')),
        ],
        if (state.phoneRefused) ...[
          const SizedBox(height: AppSpacing.sm),
          InlineMessage.error(l10n.errorDocumentOpen, key: const Key('staffDocuments.phoneRefused')),
        ],
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.staffDocumentAddTitle),
        const SizedBox(height: AppSpacing.xs),
        _Add(state: state, picking: picking),
      ],
    );
  }
}

class _Documents extends StatelessWidget {
  const new({required this.state});

  final StaffDocumentsReady state;

  Future<void> _confirmRemove(BuildContext context, Document document) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffDocumentsBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.staffDocumentRemoveTitle(document.title),
      message: l10n.staffDocumentRemoveMessage,
      confirmLabel: l10n.staffDocumentRemove,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(StaffDocumentsRemoved(document.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final bloc = context.read<StaffDocumentsBloc>();
    return AppCard(
      child: state.documents.isEmpty
          ? Text(l10n.staffDocumentsNone, key: const Key('staffDocuments.none'), style: text.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, document) in state.documents.indexed) ...[
                  if (index > 0) const Divider(height: AppSpacing.md * 2),
                  Text(document.title, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.filesNameAndSize(document.file.fileName, Formatters.fileSize(document.file.sizeBytes)),
                    style: text.bodySmall,
                  ),
                  Text(
                    l10n.staffDocumentOn(Formatters.schoolDate(Formatters.schoolDay(document.createdAt))),
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    key: Key('staffDocuments.open.${document.id}'),
                    label: l10n.staffDocumentOpen,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.open_in_new,
                    loading: state.opening == document.id,
                    onPressed: state.busy ? null : () => bloc.add(StaffDocumentsOpened(document.id)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    key: Key('staffDocuments.remove.${document.id}'),
                    label: l10n.staffDocumentRemove,
                    variant: AppButtonVariant.secondary,
                    loading: state.removing == document.id,
                    onPressed: state.busy ? null : () => _confirmRemove(context, document),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Add extends StatefulWidget {
  const new({required this.state, required this.picking});

  final StaffDocumentsReady state;
  final FilePicking picking;

  @override
  State<_Add> createState() => _AddState();
}

class _AddState extends State<_Add> {
  /// Starts from the title kept in the bloc, which the person may have left half written on another tab.
  late final _title = TextEditingController(text: widget.state.title);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffDocumentsBloc>();
    final state = widget.state;
    return BlocListener<StaffDocumentsBloc, StaffDocumentsState>(
      // Once the document is added, its title is gone from the bloc and so from the field.
      listenWhen: (previous, current) =>
          current is StaffDocumentsReady && current.title.isEmpty && _title.text.isNotEmpty,
      listener: (context, state) => _title.clear(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: const Key('staffDocuments.title'),
            controller: _title,
            label: l10n.staffDocumentTitle,
            required: true,
            requiredLabel: l10n.fieldRequired,
            maxLength: 150,
            enabled: !state.attaching,
            onChanged: (title) => bloc.add(StaffDocumentsTitleChanged(title)),
          ),
          const SizedBox(height: AppSpacing.sm),
          DocumentUploadField(
            picking: widget.picking,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const Key('staffDocuments.attach'),
            label: l10n.staffDocumentAttach,
            loading: state.attaching,
            onPressed: state.canAttach ? () => bloc.add(const StaffDocumentsAttached()) : null,
          ),
        ],
      ),
    );
  }
}
