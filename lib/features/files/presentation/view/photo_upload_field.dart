import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_progress.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/menu_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/photo_upload_tile.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/file_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Picks a photo from the camera or the gallery and sends it, with progress, an error that says what to do, and a way to
/// send it again. The form reads the file's ID from [onChanged]: the ID once the server has checked the photo, and null
/// when the person removes it. The [FileUploadBloc] comes from the context, so the screen owns the upload.
///
/// [imageLabel] says what the picture shows, for screen readers: "Photo of Kavya".
class PhotoUploadField extends StatefulWidget {
  const new({required this.picking, required this.imageLabel, required this.onChanged, super.key});

  final FilePicking picking;
  final String imageLabel;
  final ValueChanged<String?> onChanged;

  @override
  State<PhotoUploadField> createState() => _PhotoUploadFieldState();
}

class _PhotoUploadFieldState extends State<PhotoUploadField> {
  /// Why the phone would not give a photo; gone when the next one is chosen.
  FilePickFailure? _pickFailure;

  Future<void> _choose() async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<FileUploadBloc>();
    final source = await showAppBottomSheet<PhotoSource>(
      context: context,
      title: l10n.filesPhotoSourceTitle,
      builder: (sheet) => Column(
        children: [
          MenuListTile(
            key: const Key('photo.camera'),
            icon: Icons.photo_camera_outlined,
            title: l10n.filesTakePhoto,
            onTap: () => Navigator.of(sheet).pop(PhotoSource.camera),
          ),
          MenuListTile(
            key: const Key('photo.gallery'),
            icon: Icons.photo_library_outlined,
            title: l10n.filesChooseFromGallery,
            onTap: () => Navigator.of(sheet).pop(PhotoSource.gallery),
          ),
        ],
      ),
    );
    if (source == null) return;
    try {
      final photo = await widget.picking.photo(source);
      if (mounted) setState(() => _pickFailure = null);
      if (photo != null) bloc.add(FileUploadStarted(photo));
    } on FilePickFailure catch (failure) {
      if (mounted) setState(() => _pickFailure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<FileUploadBloc, FileUploadState>(
      listenWhen: (before, now) => now is FileUploadDone || before is FileUploadDone,
      listener: (context, state) => widget.onChanged(state is FileUploadDone ? state.uploaded.id : null),
      builder: (context, state) {
        final bloc = context.read<FileUploadBloc>();
        final sending = state is FileUploadSending;
        final chosen = switch (state) {
          FileUploadSending(:final file) || FileUploadDone(:final file) => file,
          // A photo that could not be sent stays on the tile, so "Send again" is about what the person sees.
          FileUploadFailed(:final file) when state.canRetry => file,
          _ => null,
        };
        // A refused file is a different file from the one before: it has no preview, and the tile says why.
        final refused = state is FileUploadFailed && !state.canRetry ? state : null;
        final failure = state is FileUploadFailed ? state.failure : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotoUploadTile(
              label: l10n.filesAddPhoto,
              onPick: sending ? null : _choose,
              image: chosen == null ? null : MemoryImage(chosen.bytes),
              imageLabel: widget.imageLabel,
              changeLabel: l10n.filesChangePhoto,
              onRemove: chosen == null || sending ? null : () => bloc.add(const FileUploadCleared()),
              removeLabel: l10n.filesRemovePhoto,
              errorText: refused?.problem == null ? null : fileProblemText(l10n, refused!.problem!),
            ),
            if (state case FileUploadSending(:final sent)) ...[
              const SizedBox(height: AppSpacing.xs),
              AppProgressBar(value: sent, semanticLabel: l10n.filesUploadingPhoto),
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
