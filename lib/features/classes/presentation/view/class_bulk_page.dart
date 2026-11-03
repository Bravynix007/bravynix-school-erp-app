import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/classes/domain/class_catalogue.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/classes/presentation/bloc/class_bulk_bloc.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which Institution the bulk add works on, and the predefined classes it already has (those cannot be added twice).
class ClassBulkArgs {
  const new({required this.institutionId, required this.added});

  final String institutionId;
  final Set<String> added;
}

/// School setup → Classes → Add several (CLS-03). Closes with `true` once saved, so the list behind it reads again.
class ClassBulkPage extends StatelessWidget {
  const new({required this.args, super.key});

  final ClassBulkArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ClassBulkBloc(getIt<ClassesRepository>(), getIt<ClassCatalogue>(), args.institutionId)
          ..add(const ClassBulkStarted()),
    child: ClassBulkView(added: args.added),
  );
}

class ClassBulkView extends StatefulWidget {
  const new({required this.added, super.key});

  final Set<String> added;

  @override
  State<ClassBulkView> createState() => _ClassBulkViewState();
}

class _ClassBulkViewState extends State<ClassBulkView> {
  final Set<String> _ticked = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<ClassBulkBloc, ClassBulkState>(
      listenWhen: (previous, current) => current is ClassBulkSaved,
      listener: (context, state) {
        if (state is ClassBulkSaved) {
          AppSnackbar.show(context, message: l10n.classesAdded(state.classes.length), kind: AppSnackbarKind.success);
        }
        context.pop(true);
      },
      builder: (context, state) {
        final editing = state is ClassBulkEditing ? state : null;
        return Scaffold(
          body: Column(
            children: [
              AppTopBar(title: l10n.classBulkTitle, onBack: () => context.pop(), backTooltip: l10n.back),
              Expanded(
                child: switch (state) {
                  ClassBulkLoading() || ClassBulkSaved() => SkeletonCards(
                    semanticLabel: l10n.loading,
                    heights: const [200, 120],
                  ),
                  ClassBulkFailed(:final failure) => StatePanel.error(
                    key: const Key('classBulk.failed'),
                    title: classErrorText(l10n, failure),
                    actionLabel: l10n.retry,
                    onAction: () => context.read<ClassBulkBloc>().add(const ClassBulkStarted()),
                  ),
                  ClassBulkEditing() => _list(context, state),
                },
              ),
            ],
          ),
          bottomNavigationBar: editing == null
              ? null
              : StickyBottomActions(
                  primaryLabel: l10n.classBulkAdd(_ticked.length),
                  primaryLoading: editing.saving,
                  onPrimary: editing.saving || _ticked.isEmpty
                      ? null
                      : () => context.read<ClassBulkBloc>().add(
                          ClassBulkSubmitted([
                            for (final choice in editing.choices)
                              if (_ticked.contains(choice.predefinedClass.id)) choice.predefinedClass.id,
                          ]),
                        ),
                  secondaryLabel: l10n.cancel,
                  onSecondary: () => context.pop(),
                ),
        );
      },
    );
  }

  Widget _list(BuildContext context, ClassBulkEditing state) {
    final l10n = AppLocalizations.of(context);
    final failure = state.failure;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        if (failure != null) ...[
          InlineMessage.error(classErrorText(l10n, failure), key: const Key('classBulk.error')),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(l10n.classBulkMessage, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        if (state.choices.every((choice) => widget.added.contains(choice.predefinedClass.id)))
          Text(l10n.classBulkNone, key: const Key('classBulk.none')),
        for (final category in state.choices.categories) ...[
          SectionHeader(title: category.name),
          for (final choice in state.choices.inCategory(category))
            AppCheckboxTile(
              key: ValueKey('classBulk.choice.${choice.predefinedClass.id}'),
              title: choice.predefinedClass.name,
              subtitle: widget.added.contains(choice.predefinedClass.id) ? l10n.classBulkAlready : null,
              value: _ticked.contains(choice.predefinedClass.id),
              onChanged: widget.added.contains(choice.predefinedClass.id)
                  ? null
                  : (ticked) => setState(
                      () => ticked ? _ticked.add(choice.predefinedClass.id) : _ticked.remove(choice.predefinedClass.id),
                    ),
            ),
        ],
      ],
    );
  }
}
