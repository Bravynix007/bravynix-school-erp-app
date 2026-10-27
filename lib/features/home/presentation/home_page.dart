import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/view/blocked_access_notice.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/view/society_blocks_section.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Placeholder until the role-aware home (HOME-01) lands in build plan phase 8.
class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionBloc>().state;
    final name = state is SessionAuthenticated ? state.session.person.greetingName : '';
    final active = state is SessionAuthenticated ? state.session.activeContext : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            key: const Key('home.profile'),
            tooltip: l10n.openProfile,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(AppRoutes.profile),
          ),
          IconButton(
            key: const Key('home.logout'),
            tooltip: l10n.logOut,
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SessionBloc>().add(const SessionLogoutRequested()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.homeWelcome(name), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (active != null) ...[
            BlockedAccessNotice(active: active),
            if (active.role == RoleCode.societyOwner)
              SocietyBlocksSection(key: const Key('home.blocks'), societyName: active.societyName ?? ''),
            const SizedBox(height: 8),
          ],
          Text(l10n.homeComingSoon, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
