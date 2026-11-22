import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/bloc/role_bloc.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/role_titles.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/auth/presentation/widgets/auth_scaffold.dart';
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
      create: (_) => RoleBloc(
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

    return BlocListener<RoleBloc, RoleState>(
      listenWhen: (previous, current) => current.chosen != null,
      listener: (context, state) {
        context.read<SessionBloc>().add(SessionContextChosen(state.chosen!));
        context.go(AppRoutes.home);
      },
      child: AuthScaffold(
        onBack: canLeave ? () => context.pop() : null,
        child: session.contexts.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeading(title: l10n.noRoleTitle, subtitle: l10n.noRoleBody),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton(
                    onPressed: () => context.read<SessionBloc>().add(const SessionLogoutRequested()),
                    child: Text(l10n.logOut),
                  ),
                ],
              )
            : _Choices(contexts: session.contexts, active: session.activeContext, canLogOut: !canLeave),
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
    final bloc = context.read<RoleBloc>();
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeading(title: l10n.chooseRoleTitle, subtitle: l10n.chooseRoleSubtitle),
          const SizedBox(height: AppSpacing.lg),
          if (state.failure != null) ...[
            InlineMessage.error(roleErrorText(l10n, state.failure!)),
            const SizedBox(height: AppSpacing.md),
          ],
          for (final option in contexts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RoleCard(
                key: ValueKey('role.${option.role.code}.${option.societyId}'),
                option: option,
                current: active == option,
                loading: state.choosing == option,
                onTap: state.isSubmitting ? null : () => bloc.add(RoleChosen(option)),
              ),
            ),
          if (canLogOut) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const Key('role.logOut'),
                onPressed: state.isSubmitting
                    ? null
                    : () => context.read<SessionBloc>().add(const SessionLogoutRequested()),
                child: Text(l10n.logOut),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const new({
    required this.option,
    required this.current,
    required this.loading,
    required this.onTap,
    super.key,
  });

  final AuthContext option;
  final bool current;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showIcon = MediaQuery.textScalerOf(context).scale(16) < 28;
    final radius = BorderRadius.circular(AppRadius.card);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: current ? scheme.primary : AppColors.border),
      ),
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: RingInkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (showIcon) ...[
                  AuthGlyph(_roleIcon(option.role)),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(roleTitle(l10n, option.role), style: theme.textTheme.titleMedium),
                      if (option.societyName case final name?) Text(name, style: theme.textTheme.bodySmall),
                      if (option.isBlocked || current) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        if (option.isBlocked)
                          StatusChip(label: l10n.roleBlocked, tone: StatusTone.error)
                        else
                          Text(
                            l10n.roleCurrent,
                            style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (loading)
                  SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: l10n.loading),
                  )
                else
                  const ExcludeSemantics(child: Icon(Icons.chevron_right, color: AppColors.inkSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _roleIcon(RoleCode role) => switch (role) {
    RoleCode.superAdmin => Icons.admin_panel_settings_outlined,
    RoleCode.societyOwner => Icons.apartment_outlined,
    RoleCode.institutionAdmin => Icons.account_balance_outlined,
    RoleCode.teacherStaff => Icons.co_present_outlined,
    RoleCode.studentParent => Icons.family_restroom_outlined,
  };
}
