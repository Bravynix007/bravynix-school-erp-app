import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/storage/institution_choice_store.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_scope_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The body of a setup screen that works on one Institution (academic years, classes): the Institution switcher over
/// the person's Institutions, and [builder]'s content for the one chosen. The content is rebuilt from scratch when the
/// choice changes, so what it loaded for the last Institution is never shown for the next.
class InstitutionScope extends StatelessWidget {
  const new({required this.builder, super.key});

  final Widget Function(BuildContext context, InstitutionSummary institution) builder;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        InstitutionScopeBloc(getIt<InstitutionsRepository>(), getIt<InstitutionChoiceStore>())
          ..add(const InstitutionScopeStarted()),
    child: InstitutionScopeView(builder: builder),
  );
}

class InstitutionScopeView extends StatelessWidget {
  const new({required this.builder, super.key});

  final Widget Function(BuildContext context, InstitutionSummary institution) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<InstitutionScopeBloc, InstitutionScopeState>(
      builder: (context, state) => switch (state) {
        InstitutionScopeLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [64]),
        InstitutionScopeFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
          key: const Key('institutionScope.forbidden'),
          title: apiErrorText(l10n, failure, notFound: l10n.errorInstitutionNotFound),
        ),
        InstitutionScopeFailed(:final failure) => StatePanel.error(
          key: const Key('institutionScope.failed'),
          title: apiErrorText(l10n, failure, notFound: l10n.errorInstitutionNotFound),
          actionLabel: l10n.retry,
          onAction: () => context.read<InstitutionScopeBloc>().add(const InstitutionScopeStarted()),
        ),
        InstitutionScopeEmpty() => StatePanel.empty(
          title: l10n.institutionsEmptyTitle,
          message: l10n.institutionsEmptyMessage,
        ),
        InstitutionScopeReady(:final institutions, :final selected) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.screenMargin,
                AppSpacing.screenMargin,
                0,
              ),
              child: _Switcher(institutions: institutions, selected: selected),
            ),
            // A new key per Institution rebuilds the content, so its Blocs start again for that Institution.
            Expanded(
              child: KeyedSubtree(key: ValueKey(selected.id), child: builder(context, selected)),
            ),
          ],
        ),
      },
    );
  }
}

class _Switcher extends StatelessWidget {
  const new({required this.institutions, required this.selected});

  final List<InstitutionSummary> institutions;
  final InstitutionSummary selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // With one Institution there is nothing to switch to: its name is shown as a heading so it is still clear which
    // Institution the screen is about.
    if (institutions.length == 1) {
      return Semantics(
        header: true,
        child: Text(selected.name, style: Theme.of(context).textTheme.titleMedium),
      );
    }
    final text = Theme.of(context).textTheme;
    return AppCard(
      key: const Key('institutionScope.switcher'),
      onTap: () => _choose(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(selected.name, style: text.titleMedium),
          Text(
            l10n.institutionSwitchHint,
            style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  /// A sheet rather than a dropdown, so a long name wraps at large text sizes instead of being cut.
  Future<void> _choose(BuildContext context) async {
    final bloc = context.read<InstitutionScopeBloc>();
    final id = await showAppBottomSheet<String>(
      context: context,
      title: AppLocalizations.of(context).institutionSwitchTitle,
      builder: (sheet) => Column(
        children: [
          for (final institution in institutions)
            AppRadioTile<String>(
              key: ValueKey('institutionScope.option.${institution.id}'),
              title: institution.name,
              subtitle: institution.code,
              value: institution.id,
              groupValue: selected.id,
              onChanged: (id) => Navigator.of(sheet).pop(id),
            ),
        ],
      ),
    );
    if (id != null) bloc.add(InstitutionScopeChosen(id));
  }
}
