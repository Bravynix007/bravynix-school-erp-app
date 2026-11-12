import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/menu_list_tile.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Profile → School setup (decision 3, Phase 3): where an Owner or an Institution Admin sets the school up. Each
/// setup screen is listed here as it lands.
class SchoolSetupPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.schoolSetupTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                AppCard(
                  child: MenuListTile(
                    key: const Key('schoolSetup.institutions'),
                    icon: Icons.apartment_outlined,
                    title: l10n.institutionsTitle,
                    subtitle: l10n.institutionsDetail,
                    onTap: () => context.push(AppRoutes.institutions),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: MenuListTile(
                    key: const Key('schoolSetup.academicYears'),
                    icon: Icons.event_outlined,
                    title: l10n.academicYearsTitle,
                    subtitle: l10n.academicYearsDetail,
                    onTap: () => context.push(AppRoutes.academicYears),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: MenuListTile(
                    key: const Key('schoolSetup.subjects'),
                    icon: Icons.menu_book_outlined,
                    title: l10n.subjectsTitle,
                    subtitle: l10n.subjectsDetail,
                    onTap: () => context.push(AppRoutes.subjects),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: MenuListTile(
                    key: const Key('schoolSetup.classes'),
                    icon: Icons.class_outlined,
                    title: l10n.classesTitle,
                    subtitle: l10n.classesDetail,
                    onTap: () => context.push(AppRoutes.classes),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: MenuListTile(
                    key: const Key('schoolSetup.staff'),
                    icon: Icons.groups_outlined,
                    title: l10n.staffTitle,
                    subtitle: l10n.staffDetail,
                    onTap: () => context.push(AppRoutes.staff),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: MenuListTile(
                    key: const Key('schoolSetup.students'),
                    icon: Icons.school_outlined,
                    title: l10n.studentsTitle,
                    subtitle: l10n.studentsDetail,
                    onTap: () => context.push(AppRoutes.students),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
