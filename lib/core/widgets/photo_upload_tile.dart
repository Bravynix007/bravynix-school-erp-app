import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:flutter/material.dart';

/// Pick a photo (student, staff, receipt): an outlined square with a camera
/// and a label, or the chosen picture with "Change photo" and "Remove" beside
/// it. The picking itself (camera, gallery, permissions) belongs to the caller;
/// this widget only asks for it through [onPick].
///
/// All words come from the caller, so they are translated with the screen.
class PhotoUploadTile extends StatelessWidget {
  const new({
    required this.label,
    required this.onPick,
    this.image,
    this.imageLabel,
    this.changeLabel,
    this.onRemove,
    this.removeLabel,
    this.errorText,
    this.size = 96,
    super.key,
  }) : assert(image == null || (imageLabel != null && changeLabel != null), 'A chosen photo needs words for it'),
       assert(onRemove == null || removeLabel != null, 'Remove needs a label');

  /// On the empty tile: "Add photo".
  final String label;
  final VoidCallback? onPick;

  /// The chosen picture, if any.
  final ImageProvider? image;

  /// What the picture shows, for screen readers: "Photo of Kavya".
  final String? imageLabel;

  /// On the button beside a chosen picture: "Change photo".
  final String? changeLabel;
  final VoidCallback? onRemove;
  final String? removeLabel;
  final String? errorText;

  /// The edge of the square, at least.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = BorderRadius.circular(AppRadius.card);
    final hasImage = image != null;
    final error = errorText != null;
    final borderColour = error ? AppColors.error : AppColors.fieldBorder;

    final square = hasImage
        ? Semantics(
            image: true,
            label: imageLabel,
            child: ClipRRect(
              borderRadius: shape,
              child: Image(image: image!, width: size, height: size, fit: BoxFit.cover, excludeFromSemantics: true),
            ),
          )
        : MergeSemantics(
            child: Semantics(
              button: true,
              enabled: onPick != null,
              child: Material(
                color: AppColors.sunken,
                borderOnForeground: false,
                shape: RoundedRectangleBorder(
                  borderRadius: shape,
                  side: BorderSide(color: borderColour, width: error ? 2 : 1),
                ),
                child: RingInkWell(
                  onTap: onPick,
                  borderRadius: shape,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: size, minHeight: size),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: 28,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: onPick == null ? AppColors.disabled : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            square,
            if (hasImage)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: onPick, child: Text(changeLabel!)),
                  if (onRemove != null)
                    TextButton(
                      onPressed: onRemove,
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: Text(removeLabel!),
                    ),
                ],
              ),
          ],
        ),
        if (error) ...[
          const SizedBox(height: AppSpacing.xxs),
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ),
        ],
      ],
    );
  }
}
