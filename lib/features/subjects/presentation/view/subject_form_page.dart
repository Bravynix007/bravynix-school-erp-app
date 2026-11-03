import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/bloc/subject_form_bloc.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/view/subject_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Subjects → Add, or Edit on one subject (SUB-02, SUB-03). Closes with `true` once saved, so the list
/// behind it reads again. No endpoint reads one subject, so the list hands over the one to edit (null to add).
class SubjectFormPage extends StatelessWidget {
  const new({this.subject, super.key});

  final Subject? subject;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SubjectFormBloc(getIt<SubjectsRepository>(), existing: subject),
    child: SubjectFormView(subject: subject),
  );
}

class SubjectFormView extends StatefulWidget {
  const new({this.subject, super.key});

  final Subject? subject;

  @override
  State<SubjectFormView> createState() => _SubjectFormViewState();
}

class _SubjectFormViewState extends State<SubjectFormView> {
  late final TextEditingController _name = TextEditingController(text: widget.subject?.name);
  late final TextEditingController _code = TextEditingController(text: widget.subject?.code);

  /// The fields a refusal can name; a refusal that names anything else is said above the form.
  static const _fields = {'name', 'code'};

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.subject != null;
    return BlocConsumer<SubjectFormBloc, SubjectFormState>(
      listenWhen: (previous, current) => current is SubjectFormSaved,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.subjectSaved, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      builder: (context, state) {
        final editing = state is SubjectFormEditing ? state : const SubjectFormEditing(saving: true);
        final failure = editing.failure;
        final onFields =
            failure != null &&
            failure.fieldErrors.isNotEmpty &&
            failure.fieldErrors.every((error) => _fields.contains(error.field));
        return Scaffold(
          body: Column(
            children: [
              AppTopBar(
                title: isEdit ? l10n.subjectEditTitle : l10n.subjectAddTitle,
                onBack: () => context.pop(),
                backTooltip: l10n.back,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenMargin),
                  children: [
                    if (failure != null && !onFields) ...[
                      InlineMessage.error(subjectErrorText(l10n, failure), key: const Key('subjectForm.error')),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AppTextField(
                      key: const Key('subjectForm.name'),
                      label: l10n.subjectName,
                      controller: _name,
                      required: true,
                      requiredLabel: l10n.fieldRequired,
                      error: failure == null ? null : subjectFieldError(l10n, failure, 'name'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      key: const Key('subjectForm.code'),
                      label: l10n.subjectCode,
                      controller: _code,
                      helper: l10n.subjectCodeHelper,
                      error: failure == null ? null : subjectFieldError(l10n, failure, 'code'),
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: StickyBottomActions(
            primaryLabel: l10n.subjectSave,
            primaryLoading: editing.saving,
            onPrimary: editing.saving
                ? null
                : () => context.read<SubjectFormBloc>().add(
                    SubjectFormSubmitted(SubjectFields(name: _name.text, code: _code.text)),
                  ),
            secondaryLabel: l10n.cancel,
            onSecondary: () => context.pop(),
          ),
        );
      },
    );
  }
}
