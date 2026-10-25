import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_avatar.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_fab.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/floating_pill_nav_bar.dart';
import 'package:bravynix_school_erp/core/widgets/module_header.dart';
import 'package:bravynix_school_erp/core/widgets/notification_bell.dart';
import 'package:bravynix_school_erp/core/widgets/person_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The shell pieces on one page, in the accent chosen in the component gallery.
/// Debug and profile builds only, like the gallery; the sample text is plain English.
class ShellGalleryPage extends StatefulWidget {
  const new({super.key});

  @override
  State<ShellGalleryPage> createState() => _ShellGalleryPageState();
}

class _ShellGalleryPageState extends State<ShellGalleryPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shell')),
      body: ListView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(100000),
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
            child: AppTopBar(
              leading: const _LogoTile(),
              overline: 'Good afternoon',
              title: 'Kavya',
              actions: [
                NotificationBell(tooltip: 'Notifications', unreadLabel: '12 unread', count: 12, onPressed: () {}),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: AppAvatar(name: 'Kavya Iyer', size: AvatarSize.small),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
            child: AppTopBar(title: 'Fee receipt', onBack: () {}, backTooltip: 'Back'),
          ),
          const SizedBox(height: AppSpacing.md),
          FloatingPillNavBar(
            currentIndex: _tab,
            onSelected: (index) => setState(() => _tab = index),
            items: const [
              PillNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
              PillNavItem(
                icon: Icons.event_available_outlined,
                selectedIcon: Icons.event_available,
                label: 'Attendance',
              ),
              PillNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppFab(icon: Icons.add, label: 'Add student', onPressed: () {}),
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
            child: StickyBottomActions(
              primaryLabel: 'Save changes',
              onPrimary: () {},
              secondaryLabel: 'Discard',
              onSecondary: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Open a module screen',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Theme(data: Theme.of(context), child: const _ModuleDemo()),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(AppRadius.button)),
      child: SizedBox.square(dimension: 40, child: Icon(Icons.school, color: scheme.onPrimary)),
    );
  }
}

/// A module screen as the shell pieces build it: collapsing accent header, a
/// list, the floating action button and the sticky actions.
class _ModuleDemo extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ModuleHeader(
            title: 'Attendance',
            heroIcon: Icons.event_available_outlined,
            heroTitle: 'Mark attendance',
            description: "Mark today's attendance for your section",
            onBack: () => Navigator.of(context).pop(),
            backTooltip: 'Back',
            actions: [NotificationBell(tooltip: 'Notifications', onPressed: () {}, onAccent: true)],
          ),
          // A Builder, so the clearance is read inside the Scaffold body (see AppFab.listClearance).
          Builder(
            builder: (context) => SliverPadding(
              // The button floats over the list: leave room to scroll the last row clear of it.
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.screenMargin,
                AppSpacing.screenMargin,
                AppFab.listClearance(context, 'Add student'),
              ),
              sliver: SliverList.separated(
                itemCount: 12,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (_, index) => PersonListTile(
                  name: 'Student ${index + 1}',
                  subtitle: 'Roll ${index + 1} · UID STU-${2290 + index}',
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AppFab(icon: Icons.add, label: 'Add student', onPressed: () {}),
      bottomNavigationBar: StickyBottomActions(
        primaryLabel: 'Confirm and submit',
        onPrimary: () {},
        secondaryLabel: 'Cancel',
        onSecondary: () => Navigator.of(context).pop(),
      ),
    );
  }
}
