import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_progress.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/file_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Picks a PDF or a picture from the phone's files and sends it, with progress, an error that says what to do, and a way
/// to send it again. The [FileUploadBloc] comes from the context, so the screen owns the upload, and tells its form of
/// the file's ID once the server has checked it: this field only shows and asks.
class DocumentUploadField extends StatefulWidget {
  const new({required this.picking, super.key});

  final FilePicking picking;

  @override
  State<DocumentUploadField> createState() => _DocumentUploadFieldState();
}

class _DocumentUploadFieldState extends State<DocumentUploadField> {
  /// Why the phone would not give a file; gone when the next one is chosen.
  FilePickFailure? _pickFailure;

  Future<void> _choose() async {
    final bloc = context.read<FileUploadBloc>();
    try {
      final file = await widget.picking.document();
      // The screen may have gone while the phone's file browser was open, and its upload with it.
      if (!mounted) return;
      setState(() => _pickFailure = null);
      if (file != null) bloc.add(FileUploadStarted(file));
    } on FilePickFailure catch (failure) {
      if (mounted) setState(() => _pickFailure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return BlocBuilder<FileUploadBloc, FileUploadState>(
      builder: (context, state) {
        final bloc = context.read<FileUploadBloc>();
        final sending = state is FileUploadSending;
        final chosen = switch (state) {
          FileUploadSending(:final file) || FileUploadDone(:final file) => file,
          // A file that could not be sent stays, so "Try again" is about what the person sees.
          FileUploadFailed(:final file) when state.canRetry => file,
          _ => null,
        };
        // A file that will be refused again is not kept: the message says why, and Choose a file replaces it.
        final refusal = switch (state) {
          FileUploadFailed(:final problem?) => fileProblemText(l10n, problem),
          FileUploadFailed(:final failure?) when !state.canRetry => fileErrorText(l10n, failure),
          _ => null,
        };
        final failure = state is FileUploadFailed && state.canRetry ? state.failure : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (chosen != null)
              Text(
                l10n.filesNameAndSize(chosen.name, Formatters.fileSize(chosen.sizeBytes)),
                key: const Key('document.chosen'),
                style: text.bodyMedium,
              )
            else
              Text(l10n.filesDocumentHint, style: text.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              key: const Key('document.pick'),
              label: chosen == null ? l10n.filesChooseDocument : l10n.filesChangeDocument,
              variant: AppButtonVariant.secondary,
              icon: Icons.attach_file,
              onPressed: sending ? null : _choose,
            ),
            if (chosen != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                key: const Key('document.remove'),
                label: l10n.filesRemoveDocument,
                variant: AppButtonVariant.text,
                onPressed: sending ? null : () => bloc.add(const FileUploadCleared()),
              ),
            ],
            if (state case FileUploadSending(:final sent)) ...[
              const SizedBox(height: AppSpacing.xs),
              AppProgressBar(value: sent, semanticLabel: l10n.filesUploadingDocument),
            ],
            if (refusal != null) ...[
              const SizedBox(height: AppSpacing.xs),
              InlineMessage.error(refusal, key: const Key('document.refused')),
            ],
            if (failure != null) ...[
              const SizedBox(height: AppSpacing.xs),
              InlineMessage.error(
                fileErrorText(l10n, failure),
                actionLabel: l10n.retry,
                onAction: () => bloc.add(const FileUploadRetried()),
              ),
            ],
            if (_pickFailure != null) ...[
              const SizedBox(height: AppSpacing.xs),
              InlineMessage.error(filePickFailureText(l10n, _pickFailure!)),
            ],
          ],
        );
      },
    );
  }
}
