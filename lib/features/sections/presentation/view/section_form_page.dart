import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/section_form_bloc.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/section_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which class the form adds a section to, the predefined sections the class has already ([taken], so they are not
/// offered again), and the section it edits (null to add).
class SectionFormArgs {
  const new({required this.classId, this.taken = const {}, this.section});

  final String classId;
  final Set<String> taken;
  final Section? section;
}

/// School setup → Classes → Sections → Add, or Edit on one section (SEC-02, SEC-03). Closes with `true` once saved, so the
/// list behind it reads again.
class SectionFormPage extends StatelessWidget {
  const new({required this.args, super.key});

  final SectionFormArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SectionFormBloc(
      getIt<SectionsRepository>(),
      getIt<MastersRepository>(),
      args.classId,
      taken: args.taken,
      existing: args.section,
    )..add(const SectionFormStarted()),
    child: SectionFormView(section: args.section),
  );
}

class SectionFormView extends StatefulWidget {
  const new({this.section, super.key});

  final Section? section;

  @override
  State<SectionFormView> createState() => _SectionFormViewState();
}

class _SectionFormViewState extends State<SectionFormView> {
  late final TextEditingController _displayName = TextEditingController(text: widget.section?.displayName);
  late final TextEditingController _capacity = TextEditingController(text: widget.section?.capacity?.toString());
  String? _predefinedSectionId;
  bool _missingChoice = false;
  bool _badCapacity = false;

  /// The fields a refusal can name; a refusal that names anything else is said above the form.
  static const _fields = {'predefinedSectionId', 'displayName', 'capacity'};

  @override
  void dispose() {
    _displayName.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final digits = _capacity.text.trim();
    final capacity = digits.isEmpty ? null : int.tryParse(digits);
    final badCapacity = digits.isNotEmpty && (capacity == null || capacity < 1 || capacity > maxSectionCapacity);
    final missingChoice = widget.section == null && _predefinedSectionId == null;
    if (badCapacity || missingChoice) {
      setState(() {
        _badCapacity = badCapacity;
        _missingChoice = missingChoice;
      });
      return;
    }
    context.read<SectionFormBloc>().add(
      SectionFormSubmitted(
        SectionFields(predefinedSectionId: _predefinedSectionId, displayName: _displayName.text, capacity: capacity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final section = widget.section;
    final isEdit = section != null;
    return BlocConsumer<SectionFormBloc, SectionFormState>(
      listenWhen: (previous, current) => current is SectionFormSaved,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.sectionSaved, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      builder: (context, state) {
        final editing = state is SectionFormEditing ? state : null;
        final failure = editing?.failure;
        final onFields = failure != null && failure.namesOnly(_fields);
        String? error(String field) => failure == null ? null : sectionFieldError(l10n, failure, field);
        return Scaffold(
          body: Column(
            children: [
              AppTopBar(
                title: isEdit ? l10n.sectionEditTitle : l10n.sectionAddTitle,
                onBack: () => context.pop(),
                backTooltip: l10n.back,
              ),
              Expanded(
                child: switch (state) {
                  SectionFormLoading() || SectionFormSaved() => SkeletonCards(
                    semanticLabel: l10n.loading,
                    heights: const [160, 120],
                  ),
                  SectionFormFailed(:final failure) => StatePanel.error(
                    key: const Key('sectionForm.failed'),
                    title: sectionErrorText(l10n, failure),
                    actionLabel: l10n.retry,
                    onAction: () => context.read<SectionFormBloc>().add(const SectionFormStarted()),
                  ),
                  SectionFormEditing(:final choices) => ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenMargin),
                    children: [
                      if (failure != null && !onFields) ...[
                        InlineMessage.error(sectionErrorText(l10n, failure), key: const Key('sectionForm.error')),
                        // The section was changed meanwhile and no endpoint reads one section, so the list is read again.
                        if (failure.code == 'VERSION_CONFLICT')
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: AppButton(
                              key: const Key('sectionForm.backToList'),
                              label: l10n.backToList,
                              variant: AppButtonVariant.text,
                              size: AppButtonSize.medium,
                              onPressed: () => context.pop(true),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (isEdit)
                        _Summary(section: section)
                      else
                        _Picker(
                          choices: choices,
                          selected: _predefinedSectionId,
                          error: _missingChoice ? l10n.sectionChooseOne : error('predefinedSectionId'),
                          onChanged: (id) => setState(() {
                            _predefinedSectionId = id;
                            _missingChoice = false;
                          }),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('sectionForm.displayName'),
                        label: l10n.sectionDisplayName,
                        controller: _displayName,
                        // Empty, a new section takes the predefined section's name; the hint says so.
                        hint: isEdit ? null : l10n.sectionDisplayNameHint,
                        required: isEdit,
                        requiredLabel: l10n.fieldRequired,
                        error: error('displayName'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('sectionForm.capacity'),
                        label: l10n.sectionCapacityLabel,
                        controller: _capacity,
                        helper: l10n.sectionCapacityHelper,
                        error: _badCapacity ? l10n.sectionCapacityInvalid : error('capacity'),
                        mono: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() => _badCapacity = false),
                      ),
                    ],
                  ),
                },
              ),
            ],
          ),
          bottomNavigationBar: editing == null
              ? null
              : StickyBottomActions(
                  primaryLabel: l10n.sectionSave,
                  primaryLoading: editing.saving,
                  onPrimary: editing.saving ? null : () => _save(context),
                  secondaryLabel: l10n.cancel,
                  onSecondary: () => context.pop(),
                ),
        );
      },
    );
  }
}

/// The section being edited: which predefined section it is, which never changes.
class _Summary extends StatelessWidget {
  const new({required this.section});

  final Section section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sectionPredefined, style: text.labelMedium),
        Text(section.predefinedSection.name, style: text.titleMedium),
      ],
    );
  }
}

/// The predefined sections the class does not have yet.
class _Picker extends StatelessWidget {
  const new({required this.choices, required this.selected, required this.error, required this.onChanged});

  final List<MasterEntry> choices;
  final String? selected;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sectionPredefined, style: Theme.of(context).textTheme.labelMedium),
        for (final choice in choices)
          AppRadioTile<String>(
            key: ValueKey('sectionForm.choice.${choice.id}'),
            title: choice.name,
            value: choice.id,
            groupValue: selected,
            onChanged: (_) => onChanged(choice.id),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: InlineMessage.error(error!, key: const Key('sectionForm.choiceError')),
          ),
        if (choices.isEmpty) Text(l10n.sectionNoneLeft, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
