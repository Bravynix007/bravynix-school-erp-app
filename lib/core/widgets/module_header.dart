import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The accent header every module screen starts with, as a sliver for a
/// `CustomScrollView`. Expanded it is 260 px (taller if large text needs it)
/// and shows a back button, the title and a hero card (outline icon, title and
/// a one-line description). It is pinned, so on scrolling it shrinks to the
/// back button and the title and the hero card fades out. At large text the
/// title moves under the back button and the hero icon above its text, so no
/// word is broken or cut.
class ModuleHeader extends StatelessWidget {
  const new({
    required this.title,
    required this.heroIcon,
    required this.heroTitle,
    this.description,
    this.onBack,
    this.backTooltip,
    this.actions = const [],
    super.key,
  }) : assert(onBack == null || backTooltip != null, 'The back button needs a tooltip: it is its spoken name');

  final String title;
  final IconData heroIcon;
  final String heroTitle;
  final String? description;
  final VoidCallback? onBack;
  final String? backTooltip;

  /// Icon buttons on the right of the title row (48 px wide each). Use `onAccent` where a widget has it.
  final List<Widget> actions;

  /// The least expanded height, including the status bar.
  static const expandedHeight = 260.0;

  /// The title row.
  static const toolbarHeight = 56.0;

  static const double _iconBox = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top;
    final titleStyle = theme.textTheme.titleLarge;
    final heroTitleStyle = theme.textTheme.titleMedium;
    final descriptionStyle = theme.textTheme.bodyMedium;

    // The title row. Beside the back button and the actions if its longest word fits there,
    // else on a line of its own under them. A word wider than the screen is scaled down to fit.
    final backWidth = onBack != null ? AppSpacing.minTouchTarget : AppSpacing.screenMargin;
    final beside = width - backWidth - actions.length * AppSpacing.minTouchTarget - AppSpacing.xxs;
    final stackedTitle = longestWordWidth(context, title, titleStyle) > beside;
    final titleRoom = stackedTitle ? width - 2 * AppSpacing.screenMargin : beside;
    final titleScaler = fitWordScaler(context, title, titleStyle, titleRoom);
    final titleHeight = measureTextHeight(context, title, titleStyle, titleRoom, scaler: titleScaler);
    final toolbar = stackedTitle
        ? toolbarHeight + titleHeight + AppSpacing.sm
        : (titleHeight + 2 * AppSpacing.sm).clamp(toolbarHeight, double.infinity);

    // The hero card. The icon sits beside the text if the longest word fits there, else above it.
    final cardInner = width - 2 * AppSpacing.screenMargin - 2 * AppSpacing.md;
    final besideIcon = cardInner - _iconBox - AppSpacing.sm;
    final longest = [
      longestWordWidth(context, heroTitle, heroTitleStyle),
      if (description != null) longestWordWidth(context, description!, descriptionStyle),
    ].reduce((a, b) => a > b ? a : b);
    final stackedHero = longest > besideIcon;
    final heroRoom = stackedHero ? cardInner : besideIcon;
    final heroTitleScaler = fitWordScaler(context, heroTitle, heroTitleStyle, heroRoom);
    final descriptionScaler = description == null
        ? null
        : fitWordScaler(context, description!, descriptionStyle, heroRoom);
    final heroTitleHeight = measureTextHeight(context, heroTitle, heroTitleStyle, heroRoom, scaler: heroTitleScaler);
    final descriptionHeight = description == null
        ? 0.0
        : AppSpacing.xxs +
              measureTextHeight(context, description!, descriptionStyle, heroRoom, scaler: descriptionScaler);
    final textHeight = heroTitleHeight + descriptionHeight;
    final heroHeight =
        2 * AppSpacing.md +
        (stackedHero ? _iconBox + AppSpacing.xs + textHeight : textHeight.clamp(_iconBox, double.infinity));

    final minExtent = top + toolbar;
    final maxExtent = (minExtent + AppSpacing.xs + heroHeight + AppSpacing.lg).clamp(expandedHeight, double.infinity);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _Delegate(
        header: this,
        layout: (
          top: top,
          toolbar: toolbar,
          minExtent: minExtent,
          maxExtent: maxExtent,
          heroHeight: heroHeight,
          stackedTitle: stackedTitle,
          stackedHero: stackedHero,
          titleScaler: titleScaler,
          heroTitleScaler: heroTitleScaler,
          descriptionScaler: descriptionScaler,
        ),
      ),
    );
  }
}

typedef _Layout = ({
  double top,
  double toolbar,
  double minExtent,
  double maxExtent,
  double heroHeight,
  bool stackedTitle,
  bool stackedHero,
  TextScaler titleScaler,
  TextScaler heroTitleScaler,
  TextScaler? descriptionScaler,
});

class _Delegate extends SliverPersistentHeaderDelegate {
  const new({required this.header, required this.layout});

  final ModuleHeader header;
  final _Layout layout;

  @override
  double get minExtent => layout.minExtent;

  @override
  double get maxExtent => layout.maxExtent;

  @override
  bool shouldRebuild(_Delegate oldDelegate) => header != oldDelegate.header || layout != oldDelegate.layout;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final range = maxExtent - minExtent;
    final progress = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final heroOpacity = (1 - progress * 1.6).clamp(0.0, 1.0);
    final onAccent = scheme.onPrimary;
    final accentTheme = theme.copyWith(
      iconTheme: theme.iconTheme.copyWith(color: onAccent),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: onAccent)),
    );
    final title = Semantics(
      header: true,
      child: Text(
        header.title,
        style: theme.textTheme.titleLarge?.copyWith(color: onAccent),
        textScaler: layout.titleScaler,
      ),
    );
    final back = header.onBack != null
        ? IconButton(
            onPressed: header.onBack,
            tooltip: header.backTooltip,
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(minimumSize: const Size.square(AppSpacing.minTouchTarget)),
          )
        : const SizedBox(width: AppSpacing.screenMargin);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: accentTheme,
        child: ColoredBox(
          color: scheme.primary,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: layout.top,
                height: layout.toolbar,
                child: layout.stackedTitle
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: ModuleHeader.toolbarHeight,
                            child: Row(
                              children: [
                                back,
                                const Spacer(),
                                ...header.actions,
                                const SizedBox(width: AppSpacing.xxs),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                            child: title,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          back,
                          Expanded(child: title),
                          ...header.actions,
                          const SizedBox(width: AppSpacing.xxs),
                        ],
                      ),
              ),
              Positioned(
                left: AppSpacing.screenMargin,
                right: AppSpacing.screenMargin,
                bottom: AppSpacing.lg,
                height: layout.heroHeight,
                child: ExcludeSemantics(
                  excluding: heroOpacity == 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: heroOpacity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.raised(scheme.primary),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: _hero(theme, onAccent),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(ThemeData theme, Color onAccent) {
    final icon = SizedBox.square(
      dimension: 40,
      child: Icon(header.heroIcon, color: onAccent, size: 28),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          header.heroTitle,
          style: theme.textTheme.titleMedium?.copyWith(color: onAccent),
          textScaler: layout.heroTitleScaler,
        ),
        if (header.description != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            header.description!,
            style: theme.textTheme.bodyMedium?.copyWith(color: onAccent),
            textScaler: layout.descriptionScaler,
          ),
        ],
      ],
    );
    return layout.stackedHero
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(height: AppSpacing.xs),
              text,
            ],
          )
        : Row(
            children: [
              icon,
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: text),
            ],
          );
  }
}
