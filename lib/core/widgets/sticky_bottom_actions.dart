import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_shadows.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart' show InlineMessage;
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// The bar pinned to the bottom of a form or a confirm screen: one full-width
/// primary button, or a secondary ("Cancel") beside the primary. When the two
/// labels do not fit side by side at the current text size they stack, primary
/// on top. Use it as `Scaffold.bottomNavigationBar`. A Scaffold only moves its
/// body up for the keyboard, so the bar pads itself by the keyboard height and
/// stays above it, as well as above the home indicator.
///
/// A form long enough to scroll shows the refusal of its save as [notice], above the buttons, where the person is
/// looking after pressing Save.
class StickyBottomActions extends StatelessWidget {
  const new({
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.notice,
    super.key,
  }) : assert(
         (secondaryLabel == null) == (onSecondary == null),
         'Give both secondaryLabel and onSecondary, or neither',
       );

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final IconData? primaryIcon;
  final bool primaryLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// A message shown above the buttons, usually an [InlineMessage].
  final Widget? notice;

  /// The gap between the two buttons.
  static const double _gap = AppSpacing.sm;

  /// The most of the screen's height the notice takes.
  static const double _noticeShare = 0.25;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: AppColors.surface,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            // The fill hides the shadow under the bar, so only the part above it shows.
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
            boxShadow: AppShadows.stickyBar,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (notice != null) ...[
                    // A long message at a large text size scrolls inside its share of the screen, so the buttons stay.
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * _noticeShare),
                      child: SingleChildScrollView(child: notice),
                    ),
                    const SizedBox(height: _gap),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Padding on each side of a button label, and room for an icon.
                      const chrome = 2 * AppSpacing.md;
                      const iconRoom = 28.0;
                      final iconWidth = primaryIcon == null ? 0.0 : iconRoom;
                      AppButton primary(double room) => AppButton(
                        label: primaryLabel,
                        icon: primaryIcon,
                        loading: primaryLoading,
                        onPressed: onPrimary,
                        labelRoom: room - chrome - iconWidth,
                      );
                      AppButton secondary(double room) => AppButton(
                        label: secondaryLabel!,
                        variant: AppButtonVariant.secondary,
                        onPressed: onSecondary,
                        labelRoom: room - chrome,
                      );
                      if (secondaryLabel == null) return primary(constraints.maxWidth);
                      final primaryNeed = measureText(context, primaryLabel, style) + chrome + iconWidth;
                      final secondaryNeed = measureText(context, secondaryLabel!, style) + chrome;
                      final half = (constraints.maxWidth - _gap) / 2;
                      final sideBySide = primaryNeed <= half && secondaryNeed <= half;
                      return sideBySide
                          ? Row(
                              children: [
                                Expanded(child: secondary(half)),
                                const SizedBox(width: _gap),
                                Expanded(child: primary(half)),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                primary(constraints.maxWidth),
                                const SizedBox(height: _gap),
                                secondary(constraints.maxWidth),
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
