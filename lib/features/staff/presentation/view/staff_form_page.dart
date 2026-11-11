import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/optional_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/stale_copy_guard.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/photo_upload_field.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/masters/presentation/bloc/place_bloc.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/place_fields.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_form_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_form_rows.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_names.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What the form needs: the Institution a new staff member is based at, or the staff member to edit. Exactly one is set.
class StaffFormArgs {
  const new add(String this.institutionId) : staffId = null;
  const new edit(String this.staffId) : institutionId = null;

  final String? institutionId;
  final String? staffId;
}

/// School setup → Teachers / Staff → Add staff, or Edit on one profile (STF-02, STF-04). Closes with `true` once saved,
/// so the screen behind it reads its data again.
class StaffFormPage extends StatelessWidget {
  const new({required this.args, super.key});

  final StaffFormArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StaffFormBloc(
      getIt<StaffRepository>(),
      getIt<MastersRepository>(),
      institutionId: args.institutionId,
      staffId: args.staffId,
    )..add(const StaffFormStarted()),
    child: const StaffFormView(),
  );
}

class StaffFormView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = context.read<StaffFormBloc>().staffId == null ? l10n.staffAddTitle : l10n.staffEditTitle;
    return BlocListener<StaffFormBloc, StaffFormState>(
      listenWhen: (previous, current) => current is StaffFormSaved,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.staffSaved, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      child: BlocBuilder<StaffFormBloc, StaffFormState>(
        builder: (context, state) => switch (state) {
          // A read of another version builds a new form, so no typed text or picker outlives the record it was typed on.
          StaffFormReady() => _Form(key: ValueKey(state.existing?.version), state: state, title: title),
          _ => Scaffold(
            body: Column(
              children: [
                AppTopBar(title: title, onBack: () => context.pop(), backTooltip: l10n.back),
                Expanded(
                  child: switch (state) {
                    StaffFormFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                      key: const Key('staffForm.forbidden'),
                      title: staffErrorText(l10n, failure),
                    ),
                    StaffFormFailed(:final failure) when failure.code == 'NOT_FOUND' => StatePanel.empty(
                      key: const Key('staffForm.notFound'),
                      title: staffErrorText(l10n, failure),
                    ),
                    StaffFormFailed(:final failure) => StatePanel.error(
                      key: const Key('staffForm.failed'),
                      title: staffErrorText(l10n, failure),
                      actionLabel: l10n.retry,
                      onAction: () => context.read<StaffFormBloc>().add(const StaffFormStarted()),
                    ),
                    _ => SkeletonCards(semanticLabel: l10n.loading, heights: const [160, 280]),
                  },
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

/// The form with its own place picker and photo upload: the place starts from the one the record holds (a new record
/// starts in India), and the photo is sent for the Institution the staff member is based at.
class _Form extends StatelessWidget {
  const new({required this.state, required this.title, super.key});

  final StaffFormReady state;
  final String title;

  @override
  Widget build(BuildContext context) {
    final existing = state.existing;
    final address = existing?.address;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PlaceBloc(
            getIt<MastersRepository>(),
            initial: PlaceChoice(countryId: address?.countryId, stateId: address?.stateId, cityId: address?.cityId),
            soleCountry: existing == null,
          )..add(const PlaceStarted()),
        ),
        BlocProvider(
          create: (_) => FileUploadBloc(
            getIt<FilesRepository>(),
            purpose: FilePurpose.staffPhoto,
            institutionId: existing?.homeInstitutionId ?? context.read<StaffFormBloc>().institutionId!,
          ),
        ),
      ],
      child: _FormBody(state: state, title: title),
    );
  }
}

class _FormBody extends StatefulWidget {
  const new({required this.state, required this.title});

  final StaffFormReady state;
  final String title;

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _mobileCode;
  late final TextEditingController _mobileNumber;
  late final TextEditingController _alternate;
  late final TextEditingController _nationality;
  late final TextEditingController _employeeCode;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _pincode;

  @override
  void initState() {
    super.initState();
    final existing = widget.state.existing;
    _firstName = TextEditingController(text: existing?.firstName);
    _lastName = TextEditingController(text: existing?.lastName);
    _email = TextEditingController(text: existing?.email);
    _mobileCode = TextEditingController(text: existing == null ? indiaDialCode : existing.mobile.countryCode);
    _mobileNumber = TextEditingController(text: existing?.mobile.number);
    _alternate = TextEditingController(text: existing?.alternateNumber);
    _nationality = TextEditingController(text: existing?.nationality);
    _employeeCode = TextEditingController(text: existing?.employeeCode);
    _line1 = TextEditingController(text: existing?.address.line1);
    _line2 = TextEditingController(text: existing?.address.line2);
    _pincode = TextEditingController(text: existing?.address.pincode);
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _email,
      _mobileCode,
      _mobileNumber,
      _alternate,
      _nationality,
      _employeeCode,
      _line1,
      _line2,
      _pincode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save(PlaceChoice place) => context.read<StaffFormBloc>().add(
    StaffFormSubmitted(
      StaffTexts(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: _email.text,
        mobileCountryCode: _mobileCode.text,
        mobileNumber: _mobileNumber.text,
        alternateNumber: _alternate.text,
        nationality: _nationality.text,
        employeeCode: _employeeCode.text,
        addressLine1: _line1.text,
        addressLine2: _line2.text,
        pincode: _pincode.text,
      ),
      place,
    ),
  );

  /// The fields the form shows an error under, named as the API names them, for the rows it holds now.
  Set<String> _fieldsShown(StaffFormReady state) => {
    ..._fields,
    for (var i = 0; i < state.failedEducationIds.length; i++)
      for (final field in educationFields) 'educations[$i].$field',
    for (var i = 0; i < state.failedContactIds.length; i++)
      for (final field in contactFields) 'emergencyContacts[$i].$field',
  };

  static const _fields = {
    'firstName',
    'lastName',
    'email',
    'mobile',
    'mobile.countryCode',
    'mobile.number',
    'alternateNumber',
    'gender',
    'dateOfBirth',
    'bloodGroup',
    'nationality',
    'classCategoryId',
    'designationId',
    'employeeCode',
    'joiningDate',
    'resignationDate',
    'employmentType',
    'address.line1',
    'address.line2',
    'address.pincode',
    'address.countryId',
    'address.stateId',
    'address.cityId',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final bloc = context.read<StaffFormBloc>();
    final failure = state.failure;
    String? error(String field) => failure?.fieldError(field)?.message;
    // The API names a row by its place among those the save sent; see StaffFormReady.failedEducationIds.
    String? rowError(String list, List<int> sentIds, int rowId, String field) {
      final position = sentIds.indexOf(rowId);
      return position < 0 ? null : error('$list[$position].$field');
    }

    final place = context.select<PlaceBloc, PlaceChoice?>(
      (bloc) => switch (bloc.state) {
        PlaceReady(:final choice) => choice,
        _ => null,
      },
    );
    final uploading = context.select<FileUploadBloc, bool>((bloc) => bloc.state is FileUploadSending);
    // A save that failed on fields of this form is shown under them; any other failure is said above.
    final banner = failure != null && !failure.namesOnly(_fieldsShown(state)) ? staffErrorText(l10n, failure) : null;
    final today = DateTime.now();
    return StaleCopyGuard(
      // The staff member was deactivated meanwhile, so the screen behind reads again.
      stale: failure?.code == 'NOT_FOUND',
      child: Scaffold(
        body: Column(
          children: [
            AppTopBar(title: widget.title, onBack: () => Navigator.maybePop(context), backTooltip: l10n.back),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                children: [
                  if (banner != null) ...[
                    // Someone else saved first, so the form is read again before another Save can succeed (API design 8.2).
                    InlineMessage.error(
                      banner,
                      key: const Key('staffForm.error'),
                      actionLabel: failure?.code == 'VERSION_CONFLICT' ? l10n.institutionReload : null,
                      onAction: () => bloc.add(const StaffFormStarted()),
                      actionKey: const Key('staffForm.reload'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  SectionHeader(title: l10n.staffFormPhoto),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PhotoUploadField(
                          picking: getIt<FilePicking>(),
                          imageLabel: l10n.staffPhotoLabel,
                          onChanged: (id) => bloc.add(StaffPhotoChosen(id)),
                        ),
                        if (uploading) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.staffUploadingWait,
                            key: const Key('staffForm.uploadingWait'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (state.isEdit && state.existing!.photoFileId != null && state.photoFileId == null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.staffPhotoKept,
                            key: const Key('staffForm.photoKept'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(title: l10n.staffFormPersonal),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          key: const Key('staffForm.firstName'),
                          label: l10n.staffFirstName,
                          controller: _firstName,
                          required: true,
                          requiredLabel: l10n.fieldRequired,
                          error: error('firstName'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const Key('staffForm.lastName'),
                          label: l10n.staffLastName,
                          controller: _lastName,
                          error: error('lastName'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppDropdownField<Gender?>(
                          key: const Key('staffForm.gender'),
                          label: l10n.staffGender,
                          value: state.gender,
                          error: error('gender'),
                          items: [
                            DropdownMenuItem<Gender?>(child: Text(l10n.choiceNone)),
                            for (final gender in Gender.values)
                              DropdownMenuItem<Gender?>(value: gender, child: Text(genderName(l10n, gender))),
                          ],
                          onChanged: (gender) => bloc.add(StaffGenderChosen(gender)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OptionalDateField(
                          key: const Key('staffForm.dateOfBirth'),
                          label: l10n.staffDateOfBirth,
                          day: state.dateOfBirth,
                          hint: l10n.chooseDate,
                          clearLabel: l10n.clearDate(l10n.staffDateOfBirth),
                          firstDay: DateTime(1900),
                          lastDay: today.subtract(const Duration(days: 1)),
                          initialDay: DateTime(today.year - 30),
                          error: error('dateOfBirth'),
                          onChanged: (day) => bloc.add(StaffBirthDateChosen(day)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppDropdownField<String?>(
                          key: const Key('staffForm.bloodGroup'),
                          label: l10n.staffBloodGroup,
                          value: state.bloodGroup,
                          error: error('bloodGroup'),
                          items: [
                            DropdownMenuItem<String?>(child: Text(l10n.choiceNone)),
                            for (final group in bloodGroups)
                              DropdownMenuItem<String?>(value: group, child: Text(group)),
                          ],
                          onChanged: (group) => bloc.add(StaffBloodGroupChosen(group)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const Key('staffForm.nationality'),
                          label: l10n.staffNationality,
                          controller: _nationality,
                          error: error('nationality'),
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(title: l10n.staffSectionContact),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          key: const Key('staffForm.email'),
                          label: l10n.profileEmail,
                          controller: _email,
                          required: true,
                          requiredLabel: l10n.fieldRequired,
                          // The login is named when a staff member is added; STF-13 changes it.
                          enabled: !state.isEdit,
                          helper: state.isEdit ? l10n.staffEmailEditHelper : l10n.staffEmailAddHelper,
                          keyboardType: TextInputType.emailAddress,
                          error: error('email'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const Key('staffForm.mobileCode'),
                          label: l10n.phoneCountryCode,
                          controller: _mobileCode,
                          mono: true,
                          keyboardType: TextInputType.number,
                          error: error('mobile.countryCode'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const Key('staffForm.mobileNumber'),
                          label: l10n.staffMobile,
                          controller: _mobileNumber,
                          mono: true,
                          required: true,
                          requiredLabel: l10n.fieldRequired,
                          keyboardType: TextInputType.phone,
                          error: error('mobile.number') ?? error('mobile'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const Key('staffForm.alternate'),
                          label: l10n.staffAlternateNumber,
                          controller: _alternate,
                          mono: true,
                          keyboardType: TextInputType.phone,
                          error: error('alternateNumber'),
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(title: l10n.staffFormAddress),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          key: const Key('staffForm.line1'),
                          label: l10n.addressLine1,
                          controller: _line1,
                          error: error('address.line1'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const Key('staffForm.line2'),
                          label: l10n.addressLine2,
                          controller: _line2,
                          error: error('address.line2'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PlaceFields(
                          keyPrefix: 'staffForm',
                          countryError: error('address.countryId'),
                          stateError: error('address.stateId'),
                          cityError: error('address.cityId'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const Key('staffForm.pincode'),
                          label: l10n.addressPincode,
                          controller: _pincode,
                          mono: true,
                          keyboardType: TextInputType.number,
                          error: error('address.pincode'),
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(title: l10n.staffSectionEmployment),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          key: const Key('staffForm.employeeCode'),
                          label: l10n.staffEmployeeId,
                          controller: _employeeCode,
                          mono: true,
                          error: error('employeeCode'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MasterDropdown(
                          key: const Key('staffForm.category'),
                          label: l10n.staffCategory,
                          entries: state.categories,
                          value: state.categoryId,
                          required: true,
                          requiredLabel: l10n.fieldRequired,
                          error: error('classCategoryId'),
                          onChanged: (id) => bloc.add(StaffCategoryChosen(id)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MasterDropdown(
                          key: const Key('staffForm.designation'),
                          label: l10n.staffDesignation,
                          entries: state.designations,
                          value: state.designationId,
                          noneLabel: l10n.choiceNone,
                          error: error('designationId'),
                          onChanged: (id) => bloc.add(StaffDesignationChosen(id)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppDropdownField<EmploymentType?>(
                          key: const Key('staffForm.employmentType'),
                          label: l10n.staffEmploymentType,
                          value: state.employmentType,
                          error: error('employmentType'),
                          items: [
                            DropdownMenuItem<EmploymentType?>(child: Text(l10n.choiceNone)),
                            for (final type in EmploymentType.values)
                              DropdownMenuItem<EmploymentType?>(value: type, child: Text(employmentName(l10n, type))),
                          ],
                          onChanged: (type) => bloc.add(StaffEmploymentTypeChosen(type)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OptionalDateField(
                          key: const Key('staffForm.joiningDate'),
                          label: l10n.staffJoiningDate,
                          day: state.joiningDate,
                          hint: l10n.chooseDate,
                          clearLabel: l10n.clearDate(l10n.staffJoiningDate),
                          firstDay: DateTime(1950),
                          lastDay: DateTime(2100),
                          error: error('joiningDate'),
                          onChanged: (day) => bloc.add(StaffJoiningDateChosen(day)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OptionalDateField(
                          key: const Key('staffForm.resignationDate'),
                          label: l10n.staffResignationDate,
                          day: state.resignationDate,
                          hint: l10n.chooseDate,
                          clearLabel: l10n.clearDate(l10n.staffResignationDate),
                          firstDay: DateTime(1950),
                          lastDay: DateTime(2100),
                          error: error('resignationDate'),
                          onChanged: (day) => bloc.add(StaffResignationDateChosen(day)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(title: l10n.staffFormEducation),
                  const SizedBox(height: AppSpacing.xs),
                  for (final (index, entry) in state.educations.indexed) ...[
                    EducationRow(
                      key: ValueKey('staffForm.education.${entry.id}'),
                      entry: entry,
                      index: index,
                      errorOf: (field) => rowError('educations', state.failedEducationIds, entry.id, field),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  AppButton(
                    key: const Key('staffForm.addEducation'),
                    label: l10n.staffAddEducation,
                    icon: Icons.add,
                    variant: AppButtonVariant.secondary,
                    onPressed: state.canAddEducation ? () => bloc.add(const StaffEducationAdded()) : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(title: l10n.staffFormEmergency),
                  const SizedBox(height: AppSpacing.xs),
                  for (final (index, entry) in state.contacts.indexed) ...[
                    ContactRow(
                      key: ValueKey('staffForm.contact.${entry.id}'),
                      entry: entry,
                      index: index,
                      errorOf: (field) => rowError('emergencyContacts', state.failedContactIds, entry.id, field),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  AppButton(
                    key: const Key('staffForm.addContact'),
                    label: l10n.staffAddContact,
                    icon: Icons.add,
                    variant: AppButtonVariant.secondary,
                    onPressed: state.canAddContact ? () => bloc.add(const StaffContactAdded()) : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: StickyBottomActions(
          primaryLabel: l10n.staffSave,
          primaryLoading: state.saving,
          // The place is sent with the rest, so Save waits until it is read (an edit would otherwise drop it), and
          // until a photo that is on its way has its ID.
          onPrimary: state.saving || place == null || uploading ? null : () => _save(place),
          secondaryLabel: l10n.cancel,
          onSecondary: () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}
