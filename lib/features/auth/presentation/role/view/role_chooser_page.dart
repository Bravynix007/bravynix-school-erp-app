import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/person_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/cubit/role_cubit.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/role_titles.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Role chooser (PRD 4): shown after sign-in when the email holds more than one
/// role, and again from Profile to switch.
class RoleChooserPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionBloc>().state;
    return BlocProvider(
      create: (_) => RoleCubit(
        getIt<AuthRepository>(),
        current: session is SessionAuthenticated ? session.session.activeContext : null,
      ),
      child: const RoleChooserView(),
    );
  }
}

class RoleChooserView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionBloc>().state;
    if (state is! SessionAuthenticated) return const SizedBox.shrink();
    final session = state.session;
    // Switching from Profile can go back; a first choice has nowhere to go back to.
    final canLeave = session.activeContext != null;

    return BlocListener<RoleCubit, RoleState>(
      listenWhen: (previous, current) => current.chosen != null,
      listener: (context, state) {
        context.read<SessionBloc>().add(SessionContextChosen(state.chosen!));
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        body: Column(
          children: [
            AppTopBar(
              title: l10n.chooseRoleTitle,
              onBack: canLeave ? () => context.pop() : null,
              backTooltip: canLeave ? l10n.back : null,
            ),
            Expanded(
              child: session.contexts.isEmpty
                  ? StatePanel.empty(
                      title: l10n.noRoleTitle,
                      message: l10n.noRoleBody,
                      actionLabel: l10n.logOut,
                      onAction: () => context.read<SessionBloc>().add(const SessionLogoutRequested()),
                    )
                  : _Choices(contexts: session.contexts, active: session.activeContext, canLogOut: !canLeave),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const new({required this.contexts, required this.active, required this.canLogOut});

  final List<AuthContext> contexts;
  final AuthContext? active;
  final bool canLogOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<RoleCubit>();
    return BlocBuilder<RoleCubit, RoleState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          Text(l10n.chooseRoleSubtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          if (state.failure != null) ...[
            InlineMessage.error(roleErrorText(l10n, state.failure!)),
            const SizedBox(height: AppSpacing.md),
          ],
          for (final option in contexts)
            PersonListTile(
              key: ValueKey('role.${option.role.code}.${option.societyId}'),
              name: roleTitle(l10n, option.role),
              subtitle: option.societyName,
              trailing: option.isBlocked ? StatusChip(label: l10n.roleBlocked, tone: StatusTone.error) : null,
              onTap: state.isSubmitting ? null : () => cubit.choose(option),
            ),
          if (canLogOut) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              key: const Key('role.logOut'),
              onPressed: state.isSubmitting
                  ? null
                  : () => context.read<SessionBloc>().add(const SessionLogoutRequested()),
              child: Text(l10n.logOut),
            ),
          ],
        ],
      ),
    );
  }
}
