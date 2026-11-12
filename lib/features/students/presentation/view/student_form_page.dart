import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/optional_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/photo_upload_field.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/masters/presentation/bloc/place_bloc.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/person_form_fields.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_form_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_guardian_row.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_warnings.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What the form needs: the Institution the student is added to.
class StudentFormArgs {
  const new(this.institutionId);

  final String institutionId;
}

/// What the snackbar says once a student is added: the name, and a line for each second look the server asked for.
String studentAddedMessage(AppLocalizations l10n, StudentSaved saved) =>
    [l10n.studentAdded(saved.student.fullName), ...studentWarningLines(l10n, saved.warnings)].join(' ');

/// School setup → Students → Add student (STU-02). Closes with `true` once saved, so the list reads again.
class StudentFormPage extends StatelessWidget {
  const new({required this.args, super.key});

  final StudentFormArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StudentFormBloc(
      getIt<StudentsRepository>(),
      SectionOptionsSource(
        years: getIt<AcademicYearsRepository>(),
        classes: getIt<ClassesRepository>(),
        sections: getIt<SectionsRepository>(),
      ),
      args.institutionId,
    )..add(const StudentFormStarted()),
    child: const StudentFormView(),
  );
}

class StudentFormView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<StudentFormBloc, StudentFormState>(
      listenWhen: (previous, current) => current is StudentFormSaved,
      listener: (context, state) {
        if (state is StudentFormSaved) {
          AppSnackbar.show(context, message: studentAddedMessage(l10n, state.saved), kind: AppSnackbarKind.success);
          context.pop(true);
        }
      },
      child: BlocBuilder<StudentFormBloc, StudentFormState>(
        builder: (context, state) => switch (state) {
          StudentFormReady() when state.options.years.isEmpty || state.options.sections.isEmpty => _Frame(
            child: StatePanel.empty(
              key: const Key('studentForm.noPlaces'),
              title: l10n.studentFormNoPlacesTitle,
              message: l10n.studentFormNoPlacesMessage,
            ),
          ),
          StudentFormReady() => _Form(state: state),
          StudentFormFailed(:final failure) when failure.code == 'FORBIDDEN' => _Frame(
            child: StatePanel.forbidden(
              key: const Key('studentForm.forbidden'),
              title: studentFormErrorText(l10n, failure),
            ),
          ),
          StudentFormFailed(:final failure) => _Frame(
            child: StatePanel.error(
              key: const Key('studentForm.failed'),
              title: studentFormErrorText(l10n, failure),
              actionLabel: l10n.retry,
              onAction: () => context.read<StudentFormBloc>().add(const StudentFormStarted()),
            ),
          ),
          _ => _Frame(
            child: SkeletonCards(semanticLabel: l10n.loading, heights: const [160, 280]),
          ),
        },
      ),
    );
  }
}

/// The screen around a body that is not the form: a placeholder, an empty or failed state.
class _Frame extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.studentsAddTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// The form with its own place picker and photo upload: a new student's address starts in India, and the photo is sent
/// for the Institution the student joins.
class _Form extends StatelessWidget {
  const new({required this.state});

  final StudentFormReady state;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => PlaceBloc(getIt<MastersRepository>(), soleCountry: true)..add(const PlaceStarted()),
      ),
      BlocProvider(
        create: (_) => FileUploadBloc(
          getIt<FilesRepository>(),
          purpose: FilePurpose.studentPhoto,
          institutionId: context.read<StudentFormBloc>().institutionId,
        ),
      ),
    ],
    child: _FormBody(state: state),
  );
}

class _FormBody extends StatefulWidget {
  const new({required this.state});

  final StudentFormReady state;

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _admissionNo = TextEditingController();
  final _contactEmail = TextEditingController();
  final _mobileCode = TextEditingController(text: Phone.indiaDialCode);
  final _mobileNumber = TextEditingController();
  final _alternate = TextEditingController();
  final _nationality = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _pincode = TextEditingController();
  final _rollNumber = TextEditingController();
  final _aadhaar = TextEditingController();
  final _birthCertificate = TextEditingController();

  List<TextEditingController> get _controllers => [
    _firstName,
    _lastName,
    _admissionNo,
    _contactEmail,
    _mobileCode,
    _mobileNumber,
    _alternate,
    _nationality,
    _line1,
    _line2,
    _pincode,
    _rollNumber,
    _aadhaar,
    _birthCertificate,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save(PlaceChoice place) => context.read<StudentFormBloc>().add(
    StudentFormSubmitted(
      StudentTexts(
        firstName: _firstName.text,
        lastName: _lastName.text,
        admissionNo: _admissionNo.text,
        contactEmail: _contactEmail.text,
        mobileCountryCode: _mobileCode.text,
        mobileNumber: _mobileNumber.text,
        alternateNumber: _alternate.text,
        nationality: _nationality.text,
        addressLine1: _line1.text,
        addressLine2: _line2.text,
        pincode: _pincode.text,
        rollNumber: _rollNumber.text,
        aadhaar: _aadhaar.text,
        birthCertificate: _birthCertificate.text,
      ),
      place,
    ),
  );

  static const _fields = {
    'firstName',
    'lastName',
    'gender',
    'dateOfBirth',
    'bloodGroup',
    'nationality',
    'admissionNo',
    'admissionDate',
    'contactEmail',
    'mobile',
    'mobile.countryCode',
    'mobile.number',
    'alternateNumber',
    'address.line1',
    'address.line2',
    'address.pincode',
    'address.countryId',
    'address.stateId',
    'address.cityId',
    'enrolment.academicYearId',
    'enrolment.classId',
    'enrolment.sectionId',
    'enrolment.rollNumber',
    'identity.aadhaarNumber',
    'identity.birthCertificateNumber',
  };

  /// The fields the form shows an error under, named as the API names them, for the rows it holds now.
  Set<String> _fieldsShown(StudentFormReady state) => {
    ..._fields,
    for (var i = 0; i < state.failedGuardianIds.length; i++)
      for (final field in guardianFields) 'guardians[$i].$field',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final bloc = context.read<StudentFormBloc>();
    final failure = state.failure;
    String? error(String field) => failure?.fieldError(field)?.message;
    // The API names a row by its place among those the save sent; see StudentFormReady.failedGuardianIds.
    String? rowError(int rowId, String field) {
      final position = state.failedGuardianIds.indexOf(rowId);
      return position < 0 ? null : error('guardians[$position].$field');
    }

    final place = context.select<PlaceBloc, PlaceChoice?>(
      (bloc) => switch (bloc.state) {
        PlaceReady(:final choice) => choice,
        _ => null,
      },
    );
    final uploading = context.select<FileUploadBloc, bool>((bloc) => bloc.state is FileUploadSending);
    // A save that failed on fields of this form is shown under them; any other failure is said above.
    final banner = failure != null && !failure.namesOnly(_fieldsShown(state))
        ? studentFormErrorText(l10n, failure)
        : null;
    final options = state.options;
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.studentsAddTitle, onBack: () => Navigator.maybePop(context), backTooltip: l10n.back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                if (banner != null) ...[
                  InlineMessage.error(banner, key: const Key('studentForm.error')),
                  const SizedBox(height: AppSpacing.sm),
                ],
                SectionHeader(title: l10n.personFormPhoto),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhotoUploadField(
                        picking: getIt<FilePicking>(),
                        imageLabel: l10n.studentPhotoLabel,
                        onChanged: (id) => bloc.add(StudentPhotoChosen(id)),
                      ),
                      if (uploading) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.personUploadingWait,
                          key: const Key('studentForm.uploadingWait'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.personFormPersonal),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: PersonalFields(
                    keyPrefix: 'studentForm',
                    firstName: _firstName,
                    lastName: _lastName,
                    nationality: _nationality,
                    gender: state.gender,
                    bloodGroup: state.bloodGroup,
                    dateOfBirth: state.dateOfBirth,
                    usualAge: 10,
                    errorOf: error,
                    onGenderChosen: (gender) => bloc.add(StudentGenderChosen(gender)),
                    onBloodGroupChosen: (group) => bloc.add(StudentBloodGroupChosen(group)),
                    onBirthDateChosen: (day) => bloc.add(StudentBirthDateChosen(day)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.studentFormAdmission),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const Key('studentForm.admissionNo'),
                        label: l10n.studentAdmissionNo,
                        controller: _admissionNo,
                        mono: true,
                        error: error('admissionNo'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OptionalDateField(
                        key: const Key('studentForm.admissionDate'),
                        label: l10n.studentAdmissionDate,
                        day: state.admissionDate,
                        hint: l10n.chooseDate,
                        clearLabel: l10n.clearDate(l10n.studentAdmissionDate),
                        firstDay: DateTime(2000),
                        lastDay: DateTime(2100),
                        error: error('admissionDate'),
                        onChanged: (day) => bloc.add(StudentAdmissionDateChosen(day)),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(l10n.studentAdmissionDateHelper, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.personFormContact),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const Key('studentForm.contactEmail'),
                        label: l10n.studentContactEmail,
                        controller: _contactEmail,
                        helper: l10n.studentContactEmailHelper,
                        keyboardType: TextInputType.emailAddress,
                        error: error('contactEmail'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PhoneFields(
                        keyPrefix: 'studentForm',
                        countryCode: _mobileCode,
                        number: _mobileNumber,
                        alternate: _alternate,
                        errorOf: error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.personFormAddress),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: AddressFields(
                    keyPrefix: 'studentForm',
                    line1: _line1,
                    line2: _line2,
                    pincode: _pincode,
                    errorOf: error,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.studentFormPlacement),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MasterDropdown(
                        key: const Key('studentForm.year'),
                        label: l10n.studentYear,
                        entries: [for (final year in options.years) MasterEntry(id: year.id, name: year.name)],
                        value: state.yearId,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('enrolment.academicYearId'),
                        onChanged: (id) => bloc.add(StudentYearChosen(id)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      MasterDropdown(
                        key: const Key('studentForm.class'),
                        label: l10n.studentClass,
                        entries: [for (final choice in options.classes) MasterEntry(id: choice.id, name: choice.name)],
                        value: state.classId,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('enrolment.classId'),
                        onChanged: (id) => bloc.add(StudentClassChosen(id)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      MasterDropdown(
                        key: const Key('studentForm.section'),
                        label: l10n.studentSection,
                        entries: [for (final choice in state.sections) MasterEntry(id: choice.id, name: choice.name)],
                        value: state.sectionId,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('enrolment.sectionId'),
                        // The sections are those of the class chosen.
                        onChanged: state.classId == null ? null : (id) => bloc.add(StudentSectionChosen(id)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('studentForm.rollNumber'),
                        label: l10n.studentRollNumber,
                        controller: _rollNumber,
                        mono: true,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('enrolment.rollNumber'),
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.studentFormGuardians),
                const SizedBox(height: AppSpacing.xxs),
                Text(l10n.studentFormGuardiansHelper, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                for (final (index, entry) in state.guardians.indexed) ...[
                  GuardianRow(
                    key: ValueKey('studentForm.guardian.${entry.id}'),
                    entry: entry,
                    index: index,
                    canRemove: state.guardians.length > 1,
                    errorOf: (field) => rowError(entry.id, field),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                AppButton(
                  key: const Key('studentForm.addGuardian'),
                  label: l10n.studentAddGuardian,
                  icon: Icons.add,
                  variant: AppButtonVariant.secondary,
                  onPressed: state.canAddGuardian ? () => bloc.add(const StudentGuardianAdded()) : null,
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.studentFormIdentity),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const Key('studentForm.aadhaar'),
                        label: l10n.studentAadhaar,
                        controller: _aadhaar,
                        mono: true,
                        helper: l10n.studentAadhaarHelper,
                        keyboardType: TextInputType.number,
                        // Twelve digits, which people type with spaces or hyphens between the groups.
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[0-9 -]')),
                          LengthLimitingTextInputFormatter(14),
                        ],
                        error: error('identity.aadhaarNumber'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('studentForm.birthCertificate'),
                        label: l10n.studentBirthCertificate,
                        controller: _birthCertificate,
                        mono: true,
                        error: error('identity.birthCertificateNumber'),
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyBottomActions(
        primaryLabel: l10n.formSave,
        primaryLoading: state.saving,
        // The place is sent with the rest, so Save waits until it is read, and until a photo that is on its way has its ID.
        onPrimary: state.saving || place == null || uploading ? null : () => _save(place),
        secondaryLabel: l10n.cancel,
        onSecondary: () => Navigator.maybePop(context),
      ),
    );
  }
}
