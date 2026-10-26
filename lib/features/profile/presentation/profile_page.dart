import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_avatar.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/menu_list_tile.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/role_titles.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Profile (PRD 6.3): who is signed in, the role in use, switching role, log out.
class ProfilePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionBloc>().state;
    if (state is! SessionAuthenticated) return const SizedBox.shrink();
    final session = state.session;
    final person = session.person;
    final active = session.activeContext;

    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.profileTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          AppAvatar(name: person.displayName, size: AvatarSize.large),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(person.displayName, style: Theme.of(context).textTheme.titleLarge)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      KeyValueRow(label: l10n.profileEmail, value: person.email),
                      if (active != null) KeyValueRow(label: l10n.profileRole, value: roleTitle(l10n, active.role)),
                      if (active?.societyName case final society?)
                        KeyValueRow(label: l10n.profileSociety, value: society),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (session.contexts.length > 1)
                  MenuListTile(
                    key: const Key('profile.switchRole'),
                    icon: Icons.swap_horiz,
                    title: l10n.switchRole,
                    subtitle: l10n.switchRoleDetail,
                    onTap: () => context.push(AppRoutes.chooseRole),
                  ),
                MenuListTile(
                  key: const Key('profile.logOut'),
                  icon: Icons.logout,
                  title: l10n.logOut,
                  destructive: true,
                  onTap: () => context.read<SessionBloc>().add(const SessionLogoutRequested()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
