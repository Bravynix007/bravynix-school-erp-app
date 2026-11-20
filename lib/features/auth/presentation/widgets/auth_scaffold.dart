import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps a single scrollable content tree when the keyboard or tablet width changes the layout.
class AuthScaffold extends StatelessWidget {
  const new({required this.child, this.showCampus = false, this.onBack, super.key});

  static const _desktopBreakpoint = 1024.0;
  static const double _desktopGutter = AppSpacing.xxl + AppSpacing.md;
  static const _sidePanelAlignment = AlignmentDirectional(0.8, 0.12);

  final Widget child;
  final bool showCampus;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final topInset = MediaQuery.paddingOf(context).top;
    final largeText = MediaQuery.textScalerOf(context).scale(16) >= 24;

    return Scaffold(
      backgroundColor: AuthColors.canvas,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final desktop =
                viewport.maxWidth >= _desktopBreakpoint && viewport.maxHeight >= 360 && !keyboardOpen && !largeText;
            final hasHero =
                !desktop && showCampus && !keyboardOpen && !largeText && viewport.maxHeight + topInset >= 560;
            final split = hasHero && viewport.maxWidth >= 800;
            final edgeToEdge = hasHero && !split && viewport.maxWidth <= 480;
            final margin = viewport.maxWidth < 360 ? AppSpacing.md : AppSpacing.xl;
            final panelWidth = ((viewport.maxWidth - 2 * margin).clamp(0, 960) - AppSpacing.xxl) / 2;
            final railWidth = (viewport.maxWidth * 0.45).clamp(440.0, 760.0);
            final top = topInset + (keyboardOpen ? AppSpacing.sm : AppSpacing.xl);

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: edgeToEdge ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: split ? margin : 0).copyWith(
                  top: split || (hasHero && !edgeToEdge) ? top : 0,
                  bottom: desktop ? 0 : AppSpacing.xl,
                ),
                child: Stack(
                  children: [
                    if (desktop)
                      PositionedDirectional(
                        start: 0,
                        top: 0,
                        bottom: 0,
                        width: railWidth,
                        child: _CampusHero(
                          minHeight: viewport.maxHeight,
                          imageAlignment: _sidePanelAlignment,
                          padding: EdgeInsetsDirectional.fromSTEB(
                            _desktopGutter,
                            top + AppSpacing.md,
                            _desktopGutter,
                            AppSpacing.xxl * 2,
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: desktop ? double.infinity : (split ? 960 : 480)),
                        child: Flex(
                          direction: split ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: split ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: split ? panelWidth : null,
                              child: desktop
                                  ? null
                                  : Padding(
                                      padding: EdgeInsets.only(top: hasHero ? 0 : top),
                                      child: hasHero
                                          ? _CampusHero(
                                              minHeight: split ? 420 : (viewport.maxWidth < 360 ? 260 : 298) + topInset,
                                              imageAlignment: split ? _sidePanelAlignment : null,
                                              padding: EdgeInsetsDirectional.fromSTEB(
                                                margin,
                                                edgeToEdge ? top : AppSpacing.xl,
                                                margin,
                                                split ? AppSpacing.xxl : AppSpacing.xxl + AppSpacing.md,
                                              ),
                                              rounded: !edgeToEdge,
                                              sheetEdge: !split,
                                            )
                                          : Padding(
                                              padding: EdgeInsets.symmetric(horizontal: margin),
                                              child: _AuthHeader(onBack: onBack),
                                            ),
                                    ),
                            ),
                            SizedBox(
                              width: split ? AppSpacing.xxl : 0,
                              height: desktop || split ? 0 : (hasHero || keyboardOpen ? AppSpacing.md : AppSpacing.xxl),
                            ),
                            SizedBox(
                              width: split ? panelWidth : null,
                              child: Padding(
                                padding: desktop
                                    ? EdgeInsetsDirectional.fromSTEB(
                                        railWidth + _desktopGutter,
                                        top,
                                        _desktopGutter,
                                        AppSpacing.xxl,
                                      )
                                    : EdgeInsets.symmetric(horizontal: split ? 0 : margin),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: desktop ? 440 : double.infinity,
                                      minHeight: desktop
                                          ? (viewport.maxHeight - top - AppSpacing.xxl).clamp(0, double.infinity)
                                          : 0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      mainAxisAlignment: desktop ? MainAxisAlignment.center : MainAxisAlignment.start,
                                      children: [
                                        if (desktop && onBack != null)
                                          Align(
                                            alignment: AlignmentDirectional.centerStart,
                                            child: BackButton(onPressed: onBack),
                                          ),
                                        child,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const new({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    if (onBack == null) return const AuthWordmark();
    return Row(
      children: [
        BackButton(
          onPressed: onBack,
          style: IconButton.styleFrom(minimumSize: const Size.square(AppSpacing.minTouchTarget)),
        ),
        const SizedBox(width: AppSpacing.xs),
        const Expanded(child: AuthWordmark()),
      ],
    );
  }
}

/// The same supplied artwork is used in the compact header, photo and startup screen.
class AuthWordmark extends StatelessWidget {
  const new({this.inverse = false, this.centered = false, super.key});

  final bool inverse;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final title = centered ? text.displayMedium : text.headlineMedium;
    final detail = centered ? text.bodyLarge : text.bodySmall;
    final alignment = centered ? TextAlign.center : TextAlign.start;
    final name = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appName,
          textAlign: alignment,
          style: title?.copyWith(color: inverse ? AuthColors.onBrand : AuthColors.brand, fontWeight: FontWeight.bold),
        ),
        Text(
          l10n.authProductName,
          textAlign: alignment,
          style: detail?.copyWith(color: inverse ? AuthColors.onBrandMuted : AppColors.inkSecondary),
        ),
      ],
    );

    return MergeSemantics(
      child: Flex(
        direction: centered ? Axis.vertical : Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(centered ? AppRadius.authPanel : AppRadius.button),
            child: Image.asset(
              'assets/auth/bravynix-logo.png',
              width: centered ? 100 : AppSizes.buttonMedium,
              height: centered ? 100 : AppSizes.buttonMedium,
              excludeFromSemantics: true,
            ),
          ),
          if (centered) ...[
            const SizedBox(height: AppSpacing.lg),
            name,
          ] else ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: name),
          ],
        ],
      ),
    );
  }
}

class _CampusHero extends StatelessWidget {
  const new({
    required this.minHeight,
    required this.padding,
    this.imageAlignment,
    this.rounded = false,
    this.sheetEdge = false,
  });

  final double minHeight;
  final EdgeInsetsDirectional padding;
  final AlignmentGeometry? imageAlignment;
  final bool rounded;
  final bool sheetEdge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(rounded ? AppRadius.authPanel : 0),
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: AuthColors.brand,
              child: Image.asset(
                'assets/auth/campus-sign-in.jpg',
                fit: BoxFit.cover,
                alignment: imageAlignment ?? const AlignmentDirectional(0.32, 0.12),
                excludeFromSemantics: true,
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [AuthColors.heroShade, AuthColors.heroShade, AuthColors.heroEdge],
                  stops: [0, 0.35, 1],
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight, minWidth: double.infinity),
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AuthWordmark(inverse: true),
                  const SizedBox(height: AppSpacing.lg),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: AppSpacing.xxl,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AuthColors.gold,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${l10n.authTaglineLead}\n'),
                            TextSpan(
                              text: l10n.authTaglineEmphasis,
                              style: AppTextStyles.authEditorial.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        style: AppTextStyles.authEditorial.copyWith(color: AuthColors.onBrand),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (sheetEdge)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: AppRadius.authPanel,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AuthColors.canvas,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.authPanel)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthGlyph extends StatelessWidget {
  const new(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: SizedBox.square(
          dimension: AppSizes.buttonMedium,
          child: Icon(icon, color: scheme.onPrimaryContainer, size: 22),
        ),
      ),
    );
  }
}

class AuthHeading extends StatelessWidget {
  const new({required this.title, this.subtitle, this.inverse = false, super.key});

  final String title;
  final String? subtitle;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.displayMedium?.copyWith(color: inverse ? AuthColors.onBrand : AuthColors.brand),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: text.bodyMedium?.copyWith(color: inverse ? AuthColors.onBrandMuted : AppColors.inkSecondary),
          ),
        ],
      ],
    );
  }
}
