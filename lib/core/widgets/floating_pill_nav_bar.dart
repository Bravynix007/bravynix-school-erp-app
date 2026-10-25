import 'package:bravynix_school_erp/core/a11y/reduce_motion.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_shadows.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// One tab of [FloatingPillNavBar].
class PillNavItem {
  const new({required this.icon, required this.label, this.selectedIcon});

  final IconData icon;
  final IconData? selectedIcon;

  /// Shown in the chosen tab and spoken for every tab.
  final String label;
}

/// The floating bottom navigation: a 64 px pill in the accent colour (corner
/// radius 26) with two to five tabs. The chosen tab is a white pill with its
/// icon and label; the others are icons, named for screen readers. It grows
/// taller, wrapping the label, instead of cutting it at large text. Put it in
/// `Scaffold.bottomNavigationBar`.
class FloatingPillNavBar extends StatelessWidget {
  const new({required this.items, required this.currentIndex, required this.onSelected, super.key});

  final List<PillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    assert(items.length >= 2 && items.length <= 5, 'A pill nav bar has two to five tabs');
    assert(currentIndex >= 0 && currentIndex < items.length, 'currentIndex is outside the tabs');
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final duration = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 200);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, 0, AppSpacing.screenMargin, AppSpacing.sm),
        child: Semantics(
          role: SemanticsRole.tabBar,
          container: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.pillNav),
              boxShadow: AppShadows.floatingNav,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.pillNavHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Room for the chosen tab's pill once the others have taken their 48 px.
                    final room = constraints.maxWidth - (items.length - 1) * AppSpacing.minTouchTarget;
                    final style = theme.textTheme.labelLarge;
                    final needed = _Tab.pillChrome + longestWordWidth(context, items[currentIndex].label, style);
                    final showLabel = needed <= room;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          // Only the chosen tab flexes; the others stay 48 px so the label has the room.
                          _wrap(
                            selected: i == currentIndex,
                            child: _Tab(
                              item: items[i],
                              selected: i == currentIndex,
                              showLabel: showLabel,
                              // The web's role="tab" already announces the position; saying it twice is noise (as TabBar does).
                              hint: kIsWeb ? null : localizations.tabLabel(tabIndex: i + 1, tabCount: items.length),
                              duration: duration,
                              onTap: () => onSelected(i),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Every tab sits in a [Flexible] and only the chosen one has a flex. Giving
  /// the tabs different parent widgets would rebuild a tab from scratch when the
  /// choice moves, and its [AnimatedSize] would never run.
  static Widget _wrap({required bool selected, required Widget child}) =>
      Flexible(flex: selected ? 1 : 0, child: child);
}

class _Tab extends StatelessWidget {
  const new({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.duration,
    required this.onTap,
    this.hint,
  });

  final PillNavItem item;
  final bool selected;

  /// False when the label cannot fit beside the icon: the chosen tab is then
  /// the white pill with the icon alone, and the label is spoken and shown as a tooltip.
  final bool showLabel;
  final String? hint;
  final Duration duration;
  final VoidCallback onTap;

  /// Padding and icon of the chosen pill, around its label.
  static const double pillChrome = 2 * AppSpacing.md + 24 + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.full);
    final icon = selected ? (item.selectedIcon ?? item.icon) : item.icon;
    final inner = selected && showLabel
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: scheme.onSecondaryContainer),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    item.label,
                    style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          )
        : SizedBox.square(
            dimension: AppSpacing.minTouchTarget,
            child: Icon(
              icon,
              size: 24,
              color: selected ? scheme.onSecondaryContainer : scheme.onPrimary,
              semanticLabel: item.label,
            ),
          );

    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        hint: hint,
        child: _Resize(
          duration: duration,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Material(
              type: selected ? MaterialType.canvas : MaterialType.transparency,
              color: selected ? AppColors.surface : null,
              borderRadius: radius,
              child: Tooltip(
                message: item.label,
                excludeFromSemantics: true,
                child: RingInkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  ringColor: selected ? AppColors.focusRing : scheme.onPrimary,
                  child: inner,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animates the tab's width change, or applies it at once for Reduce Motion
/// (even a zero-length [AnimatedSize] needs a frame to land).
class _Resize extends StatelessWidget {
  const new({required this.duration, required this.child});

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      duration == Duration.zero ? child : AnimatedSize(duration: duration, child: child);
}
