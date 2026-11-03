import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
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
import 'package:bravynix_school_erp/features/classes/presentation/bloc/class_form_bloc.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which Institution the form adds a class to, and the class it edits (null to add).
class ClassFormArgs {
  const new({required this.institutionId, this.schoolClass});

  final String institutionId;
  final SchoolClass? schoolClass;
}

/// School setup → Classes → Add, or Edit on one class (CLS-02, CLS-04). Closes with `true` once saved, so the list behind
/// it reads again.
class ClassFormPage extends StatelessWidget {
  const new({required this.args, super.key});

  final ClassFormArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ClassFormBloc(
      getIt<ClassesRepository>(),
      getIt<ClassCatalogue>(),
      args.institutionId,
      existing: args.schoolClass,
    )..add(const ClassFormStarted()),
    child: ClassFormView(schoolClass: args.schoolClass),
  );
}

class ClassFormView extends StatefulWidget {
  const new({this.schoolClass, super.key});

  final SchoolClass? schoolClass;

  @override
  State<ClassFormView> createState() => _ClassFormViewState();
}

class _ClassFormViewState extends State<ClassFormView> {
  late final TextEditingController _displayName = TextEditingController(text: widget.schoolClass?.displayName);
  late final TextEditingController _code = TextEditingController(text: widget.schoolClass?.code);
  final TextEditingController _stream = TextEditingController();
  ClassChoice? _choice;
  bool _missingChoice = false;

  /// The fields a refusal can name; a refusal that names anything else is said above the form.
  static const _fields = {'predefinedClassId', 'streamName', 'displayName', 'code'};

  @override
  void dispose() {
    _displayName.dispose();
    _code.dispose();
    _stream.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (widget.schoolClass == null && _choice == null) {
      setState(() => _missingChoice = true);
      return;
    }
    context.read<ClassFormBloc>().add(
      ClassFormSubmitted(
        ClassFields(choice: _choice, streamName: _stream.text, displayName: _displayName.text, code: _code.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.schoolClass != null;
    return BlocConsumer<ClassFormBloc, ClassFormState>(
      listenWhen: (previous, current) => current is ClassFormSaved,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.classSaved, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      builder: (context, state) {
        final editing = state is ClassFormEditing ? state : null;
        final failure = editing?.failure;
        final onFields = failure != null && failure.namesOnly(_fields);
        String? error(String field) => failure == null ? null : classFieldError(l10n, failure, field);
        return Scaffold(
          body: Column(
            children: [
              AppTopBar(
                title: isEdit ? l10n.classEditTitle : l10n.classAddTitle,
                onBack: () => context.pop(),
                backTooltip: l10n.back,
              ),
              Expanded(
                child: switch (state) {
                  ClassFormLoading() || ClassFormSaved() => SkeletonCards(
                    semanticLabel: l10n.loading,
                    heights: const [200, 120],
                  ),
                  ClassFormFailed(:final failure) => StatePanel.error(
                    key: const Key('classForm.failed'),
                    title: classErrorText(l10n, failure),
                    actionLabel: l10n.retry,
                    onAction: () => context.read<ClassFormBloc>().add(const ClassFormStarted()),
                  ),
                  ClassFormEditing(:final choices) => ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenMargin),
                    children: [
                      if (failure != null && !onFields) ...[
                        InlineMessage.error(classErrorText(l10n, failure), key: const Key('classForm.error')),
                        // The class was changed meanwhile and no endpoint reads one class, so the list is read again.
                        if (failure.code == 'VERSION_CONFLICT')
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: AppButton(
                              key: const Key('classForm.backToList'),
                              label: l10n.backToList,
                              variant: AppButtonVariant.text,
                              size: AppButtonSize.medium,
                              onPressed: () => context.pop(true),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (isEdit)
                        _Summary(schoolClass: widget.schoolClass!)
                      else
                        _Picker(
                          choices: choices,
                          selected: _choice,
                          error: _missingChoice ? l10n.classChooseOne : error('predefinedClassId'),
                          onChanged: (choice) => setState(() {
                            _choice = choice;
                            _missingChoice = false;
                          }),
                        ),
                      if (_choice?.allowsStream ?? false) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const Key('classForm.stream'),
                          label: l10n.classStream,
                          controller: _stream,
                          helper: l10n.classStreamHelper,
                          error: error('streamName'),
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('classForm.displayName'),
                        label: l10n.classDisplayName,
                        controller: _displayName,
                        // Empty, a new class takes the predefined class's name (and its stream); the hint says so.
                        hint: isEdit ? null : l10n.classDisplayNameHint,
                        required: isEdit,
                        requiredLabel: l10n.fieldRequired,
                        error: error('displayName'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('classForm.code'),
                        label: l10n.classCode,
                        controller: _code,
                        helper: l10n.classCodeHelper,
                        error: error('code'),
                        textInputAction: TextInputAction.done,
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
                  primaryLabel: l10n.classSave,
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

/// The class being edited: which predefined class (and stream) it is, which never changes.
class _Summary extends StatelessWidget {
  const new({required this.schoolClass});

  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.classPredefined, style: text.labelMedium),
        Text(
          [schoolClass.predefinedClass.name, ?schoolClass.streamName].join(' '),
          style: text.titleMedium,
        ),
        Text(schoolClass.category.name, style: text.bodySmall),
      ],
    );
  }
}

/// The predefined classes the Institution can add, under their categories.
class _Picker extends StatelessWidget {
  const new({required this.choices, required this.selected, required this.error, required this.onChanged});

  final List<ClassChoice> choices;
  final ClassChoice? selected;
  final String? error;
  final ValueChanged<ClassChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in choices.categories) ...[
          SectionHeader(title: category.name),
          for (final choice in choices.inCategory(category))
            AppRadioTile<String>(
              key: ValueKey('classForm.choice.${choice.predefinedClass.id}'),
              title: choice.predefinedClass.name,
              value: choice.predefinedClass.id,
              groupValue: selected?.predefinedClass.id,
              onChanged: (_) => onChanged(choice),
            ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: InlineMessage.error(error!, key: const Key('classForm.choiceError')),
          ),
        if (choices.isEmpty) Text(l10n.classBulkNone, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
