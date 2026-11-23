import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/quick_access_tile.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/view/blocked_access_notice.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/view/society_blocks_section.dart';
import 'package:bravynix_school_erp/features/children/presentation/view/child_panel.dart';
import 'package:bravynix_school_erp/features/notifications/presentation/view/notification_bell_button.dart';
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
          const NotificationBellButton(),
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
            if (active.role == RoleCode.studentParent) const ChildPanel(),
            if (active.role == RoleCode.societyOwner)
              SocietyBlocksSection(
                // One bloc per Society, so switching Society reads that Society's blocks again.
                key: ValueKey('home.blocks.${active.societyId}'),
                societyName: active.societyName ?? '',
              ),
            const SizedBox(height: 8),
          ],
          SectionHeader(title: l10n.quickAccessTitle),
          const SizedBox(height: AppSpacing.xs),
          QuickAccessGrid(
            tiles: [
              // A teacher reads their own week and a parent their child's; an Owner or an Admin opens a section's.
              if (active?.role == RoleCode.teacherStaff || active?.role == RoleCode.studentParent)
                QuickAccessTile(
                  key: const Key('home.quick.timetable'),
                  icon: Icons.calendar_view_week_outlined,
                  label: l10n.timetableTitle,
                  onTap: () => context.push(AppRoutes.timetable),
                ),
              // An Owner, an Admin or a teacher takes registers; a parent reads their child's calendar.
              if (active != null)
                QuickAccessTile(
                  key: const Key('home.quick.attendance'),
                  icon: Icons.fact_check_outlined,
                  label: l10n.attendanceTitle,
                  onTap: () => context.push(
                    active.role == RoleCode.studentParent ? AppRoutes.attendanceCalendar : AppRoutes.attendance,
                  ),
                ),
              QuickAccessTile(
                key: const Key('home.quick.events'),
                icon: Icons.event_outlined,
                label: l10n.eventsTitle,
                onTap: () => context.push(AppRoutes.events),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.homeComingSoon, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
