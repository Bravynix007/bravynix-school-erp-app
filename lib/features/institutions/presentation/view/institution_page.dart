import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/board_name.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Institutions → one Institution (INS-03). Only an Owner can edit (INS-04) or deactivate it (INS-05);
/// the API refuses anyone else, so the buttons are hidden for convenience only. Closes with `true` once it was edited
/// or deactivated, so the list behind it reads again.
class InstitutionPage extends StatelessWidget {
  const new({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;
    final isOwner = session is SessionAuthenticated && session.session.activeContext?.role == RoleCode.societyOwner;
    return BlocProvider(
      create: (_) => InstitutionBloc(getIt<InstitutionsRepository>(), id)..add(const InstitutionRequested()),
      child: InstitutionView(isOwner: isOwner),
    );
  }
}

class InstitutionView extends StatefulWidget {
  const new({required this.isOwner, super.key});

  final bool isOwner;

  @override
  State<InstitutionView> createState() => _InstitutionViewState();
}

class _InstitutionViewState extends State<InstitutionView> {
  /// Set once the form saved a change, so closing this screen tells the list to read again.
  bool _changed = false;

  Future<void> _edit(String id) async {
    final bloc = context.read<InstitutionBloc>();
    final saved = await context.push<bool>(AppRoutes.institutionEdit(id));
    if (saved ?? false) {
      _changed = true;
      bloc.add(const InstitutionRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<InstitutionBloc, InstitutionState>(
      listenWhen: (previous, current) => current is InstitutionDeactivated,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.institutionDeactivated, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      // The system back gesture closes with the same answer as the arrow in the bar.
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.pop(_changed);
        },
        child: Scaffold(
          body: Column(
            children: [
              AppTopBar(title: l10n.institutionTitle, onBack: () => context.pop(_changed), backTooltip: l10n.back),
              Expanded(
                child: BlocBuilder<InstitutionBloc, InstitutionState>(
                  builder: (context, state) => switch (state) {
                    InstitutionLoading() || InstitutionDeactivated() => SkeletonCards(
                      semanticLabel: AppLocalizations.of(context).loading,
                      heights: const [160, 112],
                    ),
                    InstitutionFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                      key: const Key('institution.forbidden'),
                      title: apiErrorText(l10n, failure, notFound: l10n.errorInstitutionNotFound),
                    ),
                    InstitutionFailed(:final failure) when failure.code == 'NOT_FOUND' => StatePanel.empty(
                      key: const Key('institution.notFound'),
                      title: apiErrorText(l10n, failure, notFound: l10n.errorInstitutionNotFound),
                    ),
                    InstitutionFailed(:final failure) => StatePanel.error(
                      key: const Key('institution.failed'),
                      title: apiErrorText(l10n, failure, notFound: l10n.errorInstitutionNotFound),
                      actionLabel: l10n.retry,
                      onAction: () => context.read<InstitutionBloc>().add(const InstitutionRequested()),
                    ),
                    InstitutionLoaded() => _Details(
                      state: state,
                      isOwner: widget.isOwner,
                      onEdit: () => _edit(state.institution.id),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const new({required this.state, required this.isOwner, required this.onEdit});

  final InstitutionLoaded state;
  final bool isOwner;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final institution = state.institution;
    final address = [
      institution.addressLine1,
      ?institution.addressLine2,
      ?institution.pincode,
    ].join('\n');
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(institution.name, style: text.headlineSmall),
              ),
              const SizedBox(height: AppSpacing.xs),
              KeyValueRow(label: l10n.institutionCode, value: institution.code, mono: true),
              if (institution.place case final place?) KeyValueRow(label: l10n.institutionPlace, value: place),
              if (institution.board case final board?)
                KeyValueRow(label: l10n.institutionBoard, value: boardName(l10n, board)),
              if (institution.affiliationNumber case final number?)
                KeyValueRow(label: l10n.institutionAffiliation, value: number, mono: true),
              if (institution.gstin case final gstin?)
                KeyValueRow(label: l10n.institutionGstin, value: gstin, mono: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.institutionContact),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(label: l10n.institutionAddress, value: address),
              if (institution.email case final email?) KeyValueRow(label: l10n.profileEmail, value: email),
              if (institution.phone case final phone?) KeyValueRow(label: l10n.institutionPhone, value: phone.display),
              if (institution.telephone case final telephone?)
                KeyValueRow(label: l10n.institutionTelephone, value: telephone),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.institutionClassesOffered),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: institution.classesOffered.isEmpty
              ? Text(l10n.institutionNoClassesOffered, style: text.bodyMedium)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final category in institution.classesOffered) _Category(category: category)],
                ),
        ),
        if (isOwner) ...[
          const SizedBox(height: AppSpacing.lg),
          AppButton(key: const Key('institution.edit'), label: l10n.institutionEdit, onPressed: onEdit),
          const SizedBox(height: AppSpacing.sm),
          if (state.deactivateFailure case final failure?) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                apiErrorText(l10n, failure, notFound: l10n.errorInstitutionNotFound),
                key: const Key('institution.deactivateFailed'),
                style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          AppButton(
            key: const Key('institution.deactivate'),
            label: l10n.institutionDeactivate,
            variant: AppButtonVariant.secondary,
            loading: state.deactivating,
            onPressed: () => _confirm(context, institution),
          ),
        ],
      ],
    );
  }

  Future<void> _confirm(BuildContext context, Institution institution) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<InstitutionBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.institutionDeactivateTitle(institution.name),
      message: l10n.institutionDeactivateMessage,
      confirmLabel: l10n.institutionDeactivate,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(const InstitutionDeactivateRequested());
  }
}

class _Category extends StatelessWidget {
  const new({required this.category});

  final OfferedCategory category;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
    child: Text(category.name, style: Theme.of(context).textTheme.bodyMedium),
  );
}
