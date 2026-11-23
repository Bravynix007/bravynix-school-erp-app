import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/choice_chip_group.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_text.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/photo_upload_field.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The picture in the form of an event (EVT-02, EVT-04): one the app has, or one of the person's own, never both. The
/// last choice wins: a preset drops an upload, and an upload drops the preset.
///
/// A picture is uploaded for an Institution ([institutionId]), which is null until one is chosen; the field starts again
/// when it changes, as a picture sent for one Institution is not valid for an event of another. [onBusy] tells the form
/// while a picture is going, so it can wait for it.
class EventPictureField extends StatelessWidget {
  const new({
    required this.institutionId,
    required this.preset,
    required this.current,
    required this.onPreset,
    required this.onImage,
    required this.onRemoveCurrent,
    required this.onBusy,
    this.error,
    super.key,
  });

  final String? institutionId;
  final String? preset;

  /// The picture the event has now, until the person chooses or removes one.
  final ImageProvider? current;
  final ValueChanged<String?> onPreset;

  /// The ID of the picture once the server has checked it, and null when it is taken off.
  final ValueChanged<String?> onImage;
  final VoidCallback onRemoveCurrent;
  final ValueChanged<bool> onBusy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final institution = institutionId;
    if (institution == null) return _column(context, uploads: false);
    return BlocProvider(
      key: ValueKey(institution),
      create: (_) => FileUploadBloc(
        getIt<FilesRepository>(),
        purpose: FilePurpose.eventImage,
        institutionId: institution,
      ),
      child: BlocListener<FileUploadBloc, FileUploadState>(
        listener: (context, state) => onBusy(state is FileUploadSending),
        child: _column(context, uploads: true),
      ),
    );
  }

  Widget _column(BuildContext context, {required bool uploads}) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) => ChoiceChipGroup<String?>(
            key: const Key('eventForm.picture'),
            options: [null, ...EventText.presetIcons.keys],
            labelOf: (code) => EventText.presetName(l10n, code),
            selected: preset,
            onSelected: (code) {
              onPreset(code);
              // A preset replaces an upload: forget the file, so the tile is empty again.
              if (uploads && code != null) context.read<FileUploadBloc>().add(const FileUploadCleared());
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.eventPictureOwn, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        if (uploads)
          PhotoUploadField(
            key: const Key('eventForm.upload'),
            picking: getIt<FilePicking>(),
            imageLabel: l10n.eventPictureLabel,
            onChanged: onImage,
            current: current,
            onRemoveCurrent: onRemoveCurrent,
          )
        else
          Text(l10n.eventPictureChooseInstitution, key: const Key('eventForm.pictureWaits')),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          InlineMessage.error(error!, key: const Key('eventForm.pictureError')),
        ],
      ],
    );
  }
}
