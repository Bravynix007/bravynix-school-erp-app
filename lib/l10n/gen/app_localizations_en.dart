// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BravyNix';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Enter your email and we\'ll send you a 6-digit code.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequired => 'Enter your email address.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get sendCode => 'Send code';

  @override
  String get codeTitle => 'Check your email';

  @override
  String codeSubtitle(String email) {
    return 'Enter the 6-digit code sent to $email';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String get verify => 'Verify';

  @override
  String resendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String errorOtpInvalid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return 'Incorrect code. $_temp0 left.';
  }

  @override
  String get errorOtpInvalidNoCount => 'Incorrect code.';

  @override
  String get errorOtpExpired => 'This code has expired. Request a new one.';

  @override
  String get errorOtpAttemptsExceeded => 'Too many incorrect codes. Request a new one.';

  @override
  String errorOtpAttemptsLocked(String duration) {
    return 'Too many incorrect codes. Try again in $duration.';
  }

  @override
  String get errorOtpResendTooSoon => 'Wait a minute before asking for another code.';

  @override
  String get errorOtpRequestLimit => 'Too many codes requested. Try again later.';

  @override
  String get errorAuthLocked => 'Too many failed sign-ins. This email is locked for 30 minutes.';

  @override
  String errorAuthLockedFor(String duration) {
    return 'Too many failed sign-ins. Try again in $duration.';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get startAgain => 'Start again';

  @override
  String get errorRateLimited => 'Too many attempts. Try again shortly.';

  @override
  String get errorAccountBlocked => 'This account is blocked and can\'t access the app.';

  @override
  String get errorNetwork => 'Can\'t reach the server. Check your connection and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorDeviceStorage => 'Couldn\'t read or save your sign-in on this phone. Try again.';

  @override
  String errorWithRequestId(String requestId) {
    return 'Something went wrong. Reference: $requestId';
  }

  @override
  String get sessionEndedTitle => 'You\'ve been signed out';

  @override
  String get sessionEndedExpired => 'Your session expired. Sign in again.';

  @override
  String get sessionEndedBlocked => 'This account is blocked.';

  @override
  String get sessionEndedElsewhere => 'You were signed out from another device.';

  @override
  String get sessionEndedAdminRevoked =>
      'Your Institution Admin access was removed. Sign in again to use your other roles.';

  @override
  String get sessionEndedEmailChanged => 'The email for this account was changed. Sign in with the new address.';

  @override
  String get sessionEndedGeneric => 'Your session has ended. Sign in again.';

  @override
  String get signOutIncomplete =>
      'You\'re signed out, but this phone couldn\'t forget your sign-in. Sign in and log out again to finish.';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version of the app is no longer supported. Update it from the store to continue.';

  @override
  String get homeTitle => 'Home';

  @override
  String homeWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeComingSoon => 'Your home screen arrives with the next modules of the build plan.';

  @override
  String get logOut => 'Log out';

  @override
  String get back => 'Back';

  @override
  String get roleSuperAdmin => 'Super Admin';

  @override
  String get roleSocietyOwner => 'Society Owner';

  @override
  String get roleInstitutionAdmin => 'Institution Admin';

  @override
  String get roleTeacherStaff => 'Teacher / Staff';

  @override
  String get roleStudentParent => 'Parent / Student';

  @override
  String get roleBlocked => 'Blocked';

  @override
  String get chooseRoleTitle => 'Choose how to continue';

  @override
  String get chooseRoleSubtitle => 'Your email has more than one role. You can change this later from Profile.';

  @override
  String get noRoleTitle => 'No role available';

  @override
  String get noRoleBody => 'This account has no active role. Ask your Society to add you, then sign in again.';

  @override
  String get errorContextNotAvailable => 'You no longer have that role. Choose another one or sign in again.';

  @override
  String get errorAccessBlocked => 'Access is blocked for that role. Choose another one or contact your Society.';

  @override
  String get errorSectionBlocked => 'Access is blocked for your group. Contact your Society.';

  @override
  String get errorSectionBlockedOwners => 'Access to your Society is blocked. Contact BravyNix support.';

  @override
  String blockedOwnersNotice(String society) {
    return 'Access to $society is blocked. Contact BravyNix support.';
  }

  @override
  String blockedStaffNotice(String society) {
    return 'Your access to $society is blocked. Contact your Society.';
  }

  @override
  String get blockedParentNotice => 'Access to your children\'s information is blocked. Contact the school.';

  @override
  String blocksTitle(String society) {
    return 'Blocked in $society';
  }

  @override
  String get blockTitleOwners => 'Owners';

  @override
  String blockTitleStaff(String institution) {
    return 'Staff of $institution';
  }

  @override
  String blockTitleStudents(String institution) {
    return 'Parents of $institution';
  }

  @override
  String blockReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String blockedOn(String date) {
    return 'Blocked on $date';
  }

  @override
  String get retry => 'Try again';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileRole => 'Role';

  @override
  String get profileSociety => 'Society';

  @override
  String get switchRole => 'Switch role';

  @override
  String get switchRoleDetail => 'Use the app as another role';

  @override
  String get openProfile => 'Profile';

  @override
  String get platformDuesTitle => 'Platform dues';

  @override
  String get platformDuesDetail => 'What BravyNix has charged your Society';

  @override
  String platformDuesBannerDue(String amount) {
    return 'You are due $amount';
  }

  @override
  String get platformDuesBannerPaid => 'All dues are paid';

  @override
  String get platformDuesBannerPaidDetail => 'Nothing is waiting for payment.';

  @override
  String get platformDuesEmptyTitle => 'No dues yet';

  @override
  String get platformDuesEmptyMessage => 'BravyNix has not charged your Society anything so far.';

  @override
  String get dueStatusDue => 'Due';

  @override
  String get dueStatusPaid => 'Paid';

  @override
  String get dueStatusCancelled => 'Cancelled';

  @override
  String get dueStatusOverdue => 'Overdue';

  @override
  String duePeriod(String start, String end) {
    return '$start to $end';
  }

  @override
  String duePayBy(String date) {
    return 'Pay by $date';
  }

  @override
  String duePaidOn(String date) {
    return 'Paid on $date';
  }

  @override
  String get dueDetailTitle => 'Due';

  @override
  String get duePayByLabel => 'Pay by';

  @override
  String get duePaidOnLabel => 'Paid on';

  @override
  String get dueInvoiceNumber => 'Invoice number';

  @override
  String get duePeriodLabel => 'Period';

  @override
  String get dueTotal => 'Total';

  @override
  String dueStudentsTimesRate(int count, String rate) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString students',
      one: '1 student',
    );
    return '$_temp0 × $rate';
  }

  @override
  String get dueAdjustment => 'Adjustment';

  @override
  String get dueHowReached => 'How the total was reached';

  @override
  String get duePaymentTitle => 'Payment';

  @override
  String get duePaidBy => 'Paid by';

  @override
  String get duePaymentReference => 'Reference';

  @override
  String get dueCancelledNote => 'Cancelled by BravyNix. You do not owe this.';

  @override
  String get paymentModeCash => 'Cash';

  @override
  String get paymentModeBankTransfer => 'Bank transfer';

  @override
  String get paymentModeUpi => 'UPI';

  @override
  String get paymentModeCheque => 'Cheque';

  @override
  String get cancel => 'Cancel';

  @override
  String get schoolSetupTitle => 'School setup';

  @override
  String get schoolSetupDetail => 'Your Institutions and how they are set up';

  @override
  String get institutionsTitle => 'Institutions';

  @override
  String get institutionsDetail => 'The Institutions you work in';

  @override
  String get institutionsEmptyTitle => 'No Institutions yet';

  @override
  String get institutionsEmptyMessage => 'There is no active Institution for you to work in.';

  @override
  String get institutionTitle => 'Institution';

  @override
  String get institutionSwitchHint => 'Change Institution';

  @override
  String get institutionSwitchTitle => 'Choose an Institution';

  @override
  String get institutionCode => 'Code';

  @override
  String get institutionPlace => 'Place';

  @override
  String get institutionBoard => 'Board';

  @override
  String get institutionAffiliation => 'Affiliation number';

  @override
  String get institutionGstin => 'GSTIN';

  @override
  String get institutionContact => 'Contact';

  @override
  String get addressSection => 'Address';

  @override
  String get institutionPhone => 'Phone';

  @override
  String get institutionTelephone => 'Telephone';

  @override
  String get institutionClassesOffered => 'Classes offered';

  @override
  String get institutionNoClassesOffered => 'No class categories are offered yet.';

  @override
  String get institutionDeactivate => 'Deactivate Institution';

  @override
  String institutionDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get institutionDeactivateMessage =>
      'It leaves your list, and the Institution Admins of it lose access to it. Nothing is deleted.';

  @override
  String get institutionDeactivated => 'Institution deactivated';

  @override
  String get institutionAdd => 'Add Institution';

  @override
  String get institutionAddTitle => 'Add Institution';

  @override
  String get institutionEdit => 'Edit';

  @override
  String get institutionEditTitle => 'Edit Institution';

  @override
  String get institutionSaved => 'Institution saved';

  @override
  String get institutionSave => 'Save';

  @override
  String get institutionFormBasics => 'Details';

  @override
  String get institutionName => 'Name';

  @override
  String get institutionCodeHelper => 'Letters and digits. It can\'t be changed after saving.';

  @override
  String get institutionBoardNone => 'Not set';

  @override
  String get addressLine1 => 'Address line 1';

  @override
  String get addressLine2 => 'Address line 2';

  @override
  String get addressPincode => 'Pincode';

  @override
  String get placeCountry => 'Country';

  @override
  String get placeState => 'State';

  @override
  String get placeCity => 'City';

  @override
  String get phoneCountryCode => 'Country code';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get institutionNoCategories => 'There are no class categories to choose from.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get errorInstitutionDuplicate => 'Another Institution already uses this code.';

  @override
  String get errorVersionConflict => 'Someone else changed this. Your changes were not saved.';

  @override
  String get institutionReload => 'Reload';

  @override
  String get errorCategoryInUse =>
      'Classes already use a category you unticked, so it has to stay offered. Tick it again to save.';

  @override
  String get errorReferenceInactive => 'Something you chose is no longer available. Choose again.';

  @override
  String get errorValidation => 'Check the fields marked in red.';

  @override
  String get academicYearsTitle => 'Academic years';

  @override
  String get academicYearsDetail => 'The school years of each Institution';

  @override
  String get academicYearsEmptyTitle => 'No academic years yet';

  @override
  String get academicYearsEmptyMessage => 'Add the first year. It becomes the current year.';

  @override
  String get academicYearAdd => 'Add academic year';

  @override
  String get academicYearAddTitle => 'Add academic year';

  @override
  String get academicYearEditTitle => 'Edit academic year';

  @override
  String get academicYearEdit => 'Edit';

  @override
  String get academicYearCurrent => 'Current';

  @override
  String get academicYearCurrentHint => 'To deactivate this year, make another year current first.';

  @override
  String get backToList => 'Back to the list';

  @override
  String get academicYearMakeCurrent => 'Make current';

  @override
  String get academicYearDeactivate => 'Deactivate';

  @override
  String academicYearDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get academicYearDeactivateMessage => 'It leaves the list and its dates are free again. Nothing is deleted.';

  @override
  String get academicYearDeactivated => 'Academic year deactivated';

  @override
  String academicYearMadeCurrent(String name) {
    return '$name is now the current year';
  }

  @override
  String get academicYearSaved => 'Academic year saved';

  @override
  String get academicYearName => 'Name';

  @override
  String get academicYearNameHelper => 'For example 2026-2027';

  @override
  String get academicYearStart => 'Starts on';

  @override
  String get academicYearEnd => 'Ends on';

  @override
  String academicYearDates(String start, String end) {
    return '$start to $end';
  }

  @override
  String get academicYearSave => 'Save';

  @override
  String get errorYearOverlap => 'These dates overlap another academic year of this Institution.';

  @override
  String get errorYearDuplicate => 'Another academic year of this Institution has this name.';

  @override
  String get errorCurrentYearLocked => 'The current year can\'t be deactivated. Make another year current first.';

  @override
  String get subjectsTitle => 'Subjects';

  @override
  String get subjectsDetail => 'The subjects every Institution of the Society teaches';

  @override
  String get subjectsEmptyTitle => 'No subjects yet';

  @override
  String get subjectsEmptyMessage => 'Add the subjects your Institutions teach. They are shared by all of them.';

  @override
  String get subjectAdd => 'Add subject';

  @override
  String get subjectAddTitle => 'Add subject';

  @override
  String get subjectEditTitle => 'Edit subject';

  @override
  String get subjectEdit => 'Edit';

  @override
  String get subjectDeactivate => 'Deactivate';

  @override
  String subjectDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get subjectDeactivateMessage => 'It leaves the list and its name and code are free again. Nothing is deleted.';

  @override
  String subjectDeactivated(String name) {
    return '$name deactivated';
  }

  @override
  String get subjectSaved => 'Subject saved';

  @override
  String get subjectName => 'Name';

  @override
  String get subjectCode => 'Code';

  @override
  String get subjectCodeHelper => 'Optional, like MATH';

  @override
  String get subjectSave => 'Save';

  @override
  String get errorSubjectDuplicate => 'Another subject has this name or code.';

  @override
  String get errorSubjectNameTaken => 'Another subject has this name.';

  @override
  String get errorSubjectCodeTaken => 'Another subject has this code.';

  @override
  String get errorSubjectNotFound => 'This subject could not be found. It may have been deactivated.';

  @override
  String get classesTitle => 'Classes';

  @override
  String get classesDetail => 'The classes of each Institution and their sections';

  @override
  String get classesEmptyTitle => 'No classes yet';

  @override
  String get classesEmptyMessage => 'Add the classes this Institution teaches, from the categories it offers.';

  @override
  String get classAdd => 'Add class';

  @override
  String get classAddSeveral => 'Add several';

  @override
  String get classAddTitle => 'Add class';

  @override
  String get classEditTitle => 'Edit class';

  @override
  String get classEdit => 'Edit';

  @override
  String get classDeactivate => 'Deactivate';

  @override
  String classDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get classDeactivateMessage => 'Its sections are deactivated with it. Nothing is deleted.';

  @override
  String classDeactivated(String name) {
    return '$name deactivated';
  }

  @override
  String get classSaved => 'Class saved';

  @override
  String classesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes added',
      one: '1 class added',
    );
    return '$_temp0';
  }

  @override
  String classSections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sections',
      one: '1 section',
      zero: 'No sections',
    );
    return '$_temp0';
  }

  @override
  String get classPredefined => 'Class';

  @override
  String get classStream => 'Stream';

  @override
  String get classStreamHelper => 'For example PCMC';

  @override
  String get classDisplayName => 'Name';

  @override
  String get classDisplayNameHint => 'Class name';

  @override
  String get classCode => 'Code';

  @override
  String get classCodeHelper => 'Optional';

  @override
  String get classChooseOne => 'Choose a class';

  @override
  String get classSave => 'Save';

  @override
  String get classBulkTitle => 'Add several classes';

  @override
  String get classBulkMessage =>
      'Tick the classes to add. Pre-University classes have streams, so add them one at a time.';

  @override
  String get classBulkAlready => 'Already added';

  @override
  String get classBulkNone =>
      'Every class of the categories this Institution offers is already added, or needs a stream.';

  @override
  String classBulkAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count classes',
      one: 'Add 1 class',
      zero: 'Add classes',
    );
    return '$_temp0';
  }

  @override
  String get errorClassDuplicate => 'Another class of this Institution already has this name or stream.';

  @override
  String get errorClassNameTaken => 'Another class of this Institution has this name.';

  @override
  String get errorClassTaken => 'This class is already added to this Institution.';

  @override
  String get errorClassNotOffered =>
      'This Institution does not offer this class\'s category. Tick the category on the Institution first.';

  @override
  String get errorStreamNotAllowed => 'Only Pre-University classes have a stream.';

  @override
  String get errorClassHasStudents => 'Students are placed in this class. Move them first.';

  @override
  String classBulkItemRefused(String name, String reason) {
    return '$name: $reason';
  }

  @override
  String get errorClassNotFound => 'This class could not be found. It may have been deactivated.';

  @override
  String get errorSectionNotFound => 'This section could not be found. It may have been deactivated.';

  @override
  String get classOpenSections => 'Sections';

  @override
  String get sectionsTitle => 'Sections';

  @override
  String get sectionsEmptyTitle => 'No sections yet';

  @override
  String sectionsEmptyMessage(String name) {
    return 'Add the sections of $name, such as A and B.';
  }

  @override
  String get sectionAdd => 'Add section';

  @override
  String get sectionAddTitle => 'Add section';

  @override
  String get sectionEditTitle => 'Edit section';

  @override
  String get sectionEdit => 'Edit';

  @override
  String get sectionDeactivate => 'Deactivate';

  @override
  String sectionDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get sectionDeactivateMessage => 'Its name can be used again. Nothing is deleted.';

  @override
  String sectionDeactivated(String name) {
    return '$name deactivated';
  }

  @override
  String get sectionSaved => 'Section saved';

  @override
  String sectionCapacity(int count) {
    return 'Capacity $count';
  }

  @override
  String get sectionNoCapacity => 'No capacity set';

  @override
  String sectionStudents(String count) {
    return 'Students $count';
  }

  @override
  String get sectionPredefined => 'Section';

  @override
  String get sectionDisplayName => 'Name';

  @override
  String get sectionDisplayNameHint => 'Section name';

  @override
  String get sectionCapacityLabel => 'Capacity';

  @override
  String get sectionCapacityHelper => 'Optional. A warning, not a limit';

  @override
  String get sectionCapacityInvalid => 'Use 1 to 32767.';

  @override
  String get sectionChooseOne => 'Choose a section';

  @override
  String get sectionNoneLeft => 'Every predefined section is already added to this class.';

  @override
  String get sectionSave => 'Save';

  @override
  String get errorSectionDuplicate => 'Another section of this class already has this name.';

  @override
  String get errorSectionNameTaken => 'Another section of this class has this name.';

  @override
  String get errorSectionTaken => 'This section is already added to this class.';

  @override
  String get errorSectionHasStudents => 'Students are placed in this section. Move them first.';

  @override
  String get errorYearNotFound => 'This academic year could not be found. It may have been deactivated.';

  @override
  String get errorInstitutionNotFound => 'This Institution could not be found. It may have been deactivated.';

  @override
  String get boardCbse => 'CBSE';

  @override
  String get boardIcse => 'ICSE';

  @override
  String get boardState => 'State Board';

  @override
  String get boardIb => 'IB';

  @override
  String get boardIgcse => 'IGCSE';

  @override
  String get boardOther => 'Other';

  @override
  String get errorForbidden => 'You don\'t have access to this.';

  @override
  String get errorDueNotFound => 'This due could not be found. It may belong to another Society.';

  @override
  String get loading => 'Loading';

  @override
  String get filesAddPhoto => 'Add photo';

  @override
  String get filesChangePhoto => 'Change photo';

  @override
  String get filesRemovePhoto => 'Remove photo';

  @override
  String get filesPhotoSourceTitle => 'Add a photo';

  @override
  String get filesTakePhoto => 'Take a photo';

  @override
  String get filesChooseFromGallery => 'Choose from gallery';

  @override
  String get filesUploadingPhoto => 'Uploading photo';

  @override
  String get errorFileEmpty => 'This file is empty. Choose another one.';

  @override
  String get errorFileTooLarge => 'This file is larger than 5 MB. Choose a smaller one.';

  @override
  String get errorFileTypeNotAllowed => 'This kind of file can\'t be used here. Choose a different one.';

  @override
  String get errorFileCheckFailed => 'The file is damaged or is not what it says it is. Choose it again.';

  @override
  String get errorFileNotArrived => 'The file did not arrive. Send it again.';

  @override
  String get errorFileRefused => 'The file could not be sent. Send it again.';

  @override
  String get errorFileSchoolNotFound => 'You can\'t add files for this school.';

  @override
  String get errorFilePickCamera => 'Couldn\'t open the camera. Allow it in Settings and try again.';

  @override
  String get errorFilePickGallery => 'Couldn\'t open your photos. Allow it in Settings and try again.';

  @override
  String get errorFilePickFiles => 'Couldn\'t open your files. Try again.';

  @override
  String get staffTitle => 'Teachers / Staff';

  @override
  String get staffDetail => 'The teachers and staff of each Institution';

  @override
  String get staffSearchHint => 'Search name or ID';

  @override
  String get staffSearchClear => 'Clear search';

  @override
  String get staffEmptyTitle => 'No staff yet';

  @override
  String get staffEmptyMessage => 'Teachers and staff added to this Institution appear here.';

  @override
  String staffNoMatchTitle(String query) {
    return 'No staff match \"$query\"';
  }

  @override
  String get staffNoMatchMessage => 'Check the spelling, or search by Employee ID.';

  @override
  String get staffLoadMore => 'Load more';

  @override
  String get staffBlocked => 'Blocked';

  @override
  String get staffDeactivate => 'Deactivate';

  @override
  String staffDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get staffDeactivateMessage =>
      'They can no longer sign in as staff, any Admin Access they hold is taken away, and their class and subject assignments end. Nothing is deleted.';

  @override
  String staffDeactivated(String name) {
    return '$name deactivated';
  }

  @override
  String get errorStaffNotFound => 'This staff member could not be found. They may have been deactivated.';

  @override
  String get errorCannotActOnSelf => 'You can\'t do this to your own record.';

  @override
  String get staffProfileTitle => 'Teacher profile';

  @override
  String get staffSectionContact => 'Contact';

  @override
  String get staffSectionEmployment => 'Employment';

  @override
  String get staffSectionEducation => 'Education';

  @override
  String get staffSectionEmergency => 'Emergency contacts';

  @override
  String get staffEmployeeId => 'Employee ID';

  @override
  String get staffDesignation => 'Designation';

  @override
  String get staffCategory => 'Category';

  @override
  String get staffGender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get staffDateOfBirth => 'Date of birth';

  @override
  String get staffBloodGroup => 'Blood group';

  @override
  String get staffNationality => 'Nationality';

  @override
  String get staffMobile => 'Mobile';

  @override
  String get staffAlternateNumber => 'Alternate number';

  @override
  String get staffAddress => 'Address';

  @override
  String get staffJoiningDate => 'Joining date';

  @override
  String get staffResignationDate => 'Resignation date';

  @override
  String get staffEmploymentType => 'Employment type';

  @override
  String get employmentFullTime => 'Full time';

  @override
  String get employmentPartTime => 'Part time';

  @override
  String get employmentVisiting => 'Visiting';

  @override
  String get employmentContract => 'Contract';

  @override
  String get staffPrimaryContact => 'Primary';

  @override
  String staffContactRelation(String name, String relation) {
    return '$name ($relation)';
  }

  @override
  String get staffAddTitle => 'Add staff';

  @override
  String get staffEditTitle => 'Edit staff';

  @override
  String get staffSave => 'Save';

  @override
  String get staffSaved => 'Staff saved';

  @override
  String get staffFormPhoto => 'Photo';

  @override
  String get staffPhotoKept => 'A photo is saved. Choose another to replace it.';

  @override
  String get staffPhotoLabel => 'Staff photo';

  @override
  String get staffFormPersonal => 'Personal details';

  @override
  String get staffFirstName => 'First name';

  @override
  String get staffLastName => 'Last name';

  @override
  String get staffEmailAddHelper => 'They sign in with a code sent to this email.';

  @override
  String get staffEmailEditHelper => 'The login email can\'t be changed here.';

  @override
  String get staffFormAddress => 'Address';

  @override
  String get staffFormEducation => 'Education';

  @override
  String get staffFormEmergency => 'Emergency contacts';

  @override
  String get choiceNone => 'Not set';

  @override
  String get masterEntryKept => 'No longer offered (kept)';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String clearDate(String label) {
    return 'Clear $label';
  }

  @override
  String staffEducationRow(int number) {
    return 'Education $number';
  }

  @override
  String get staffEducationDegree => 'Degree';

  @override
  String get staffEducationQualification => 'Qualification';

  @override
  String get staffEducationSpecialization => 'Specialization';

  @override
  String get staffEducationSchool => 'School or college';

  @override
  String get staffEducationYear => 'Year of passing';

  @override
  String get staffAddEducation => 'Add education';

  @override
  String staffRemoveEducation(int number) {
    return 'Remove education $number';
  }

  @override
  String staffContactRow(int number) {
    return 'Contact $number';
  }

  @override
  String get staffContactName => 'Name';

  @override
  String get staffContactRelationLabel => 'Relation';

  @override
  String get staffAddContact => 'Add emergency contact';

  @override
  String staffRemoveContact(int number) {
    return 'Remove contact $number';
  }

  @override
  String get staffUploadingWait => 'Wait for the photo to finish sending.';

  @override
  String get staffTabPersonal => 'Personal';

  @override
  String get staffTabAccess => 'Access';

  @override
  String get staffTabSettings => 'Settings';

  @override
  String get staffAccessSubjects => 'Subjects they can teach';

  @override
  String get staffAccessSubjectsHelper => 'Only these can be assigned to them in a section.';

  @override
  String get staffAccessSubjectsEmpty => 'No subjects yet. Add them under School setup, Subjects.';

  @override
  String get staffAccessInstitutions => 'Other Institutions';

  @override
  String get staffAccessInstitutionsHelper =>
      'They can see these Institutions besides their own. They only view there.';

  @override
  String get staffAccessInstitutionsEmpty => 'There is no other Institution in this Society.';

  @override
  String get staffAccessSaveSubjects => 'Save subjects';

  @override
  String get staffAccessSaveInstitutions => 'Save Institutions';

  @override
  String get staffAccessSaved => 'Access saved';

  @override
  String get staffSettingsAccess => 'Access to the app';

  @override
  String get staffSettingsActive => 'They can use the app as staff.';

  @override
  String get staffSettingsBlockedMessage =>
      'They are blocked. They cannot use the app as staff or Admin of this Society.';

  @override
  String get staffBlockAction => 'Block access';

  @override
  String get staffUnblockAction => 'Unblock access';

  @override
  String staffBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get staffBlockMessage =>
      'They are signed out at once and cannot use the app as staff or Admin of this Society until you unblock them. Their record is kept.';

  @override
  String staffUnblockTitle(String name) {
    return 'Unblock $name?';
  }

  @override
  String get staffUnblockMessage => 'They can use the app as staff again.';

  @override
  String staffBlockDone(String name) {
    return '$name blocked';
  }

  @override
  String staffUnblockDone(String name) {
    return '$name unblocked';
  }

  @override
  String get errorStaffAccessState => 'Their access is already as you asked. The screen is up to date now.';

  @override
  String get errorStaffBlockForbidden => 'Only the Society Owner can change the access of an Institution Admin.';

  @override
  String get errorSubjectAssigned =>
      'They are assigned to teach one of the subjects you removed. End that assignment first.';

  @override
  String get errorAdminAccessHeld =>
      'They are an Institution Admin at one of the Institutions you removed. Take that Admin Access away first.';

  @override
  String get errorEmployeeIdTaken => 'Another staff member of this Institution has this Employee ID.';

  @override
  String get errorStaffDuplicate => 'This person already has a staff record in this Society.';

  @override
  String get staffAdminTitle => 'Admin access';

  @override
  String get staffAdminHelper =>
      'An Admin runs an Institution: its school setup, staff and students. They are told by email when it is given.';

  @override
  String get staffAdminEmpty => 'They are not at an Institution that can be given Admin access.';

  @override
  String get staffAdminIs => 'Admin';

  @override
  String get staffAdminIsNot => 'Not an Admin here.';

  @override
  String get staffAdminGrantAction => 'Make Admin';

  @override
  String get staffAdminRevokeAction => 'Take away Admin access';

  @override
  String staffAdminGrantTitle(String name, String institution) {
    return 'Make $name an Admin of $institution?';
  }

  @override
  String get staffAdminGrantMessage => 'They can run this Institution. They are told by email.';

  @override
  String staffAdminRevokeTitle(String name, String institution) {
    return 'Take away Admin access of $name to $institution?';
  }

  @override
  String get staffAdminRevokeMessage =>
      'They are signed out as Admin of this Society at once. Their staff access stays.';

  @override
  String staffAdminGranted(String name, String institution) {
    return '$name is now an Admin of $institution';
  }

  @override
  String staffAdminRevoked(String name, String institution) {
    return '$name is no longer an Admin of $institution';
  }

  @override
  String get errorAdminAlready => 'They are already an Admin of this Institution. The screen is up to date now.';

  @override
  String get errorAdminStaffBlocked => 'They are blocked. Unblock them under Settings before giving Admin access.';

  @override
  String get errorAdminNotAtInstitution =>
      'They are not at this Institution. Add it under Other Institutions and save first.';

  @override
  String get errorAdminNotHeld => 'They no longer hold Admin access here. The screen is up to date now.';

  @override
  String get errorAdminAccountState => 'Their account cannot hold this role right now.';

  @override
  String get staffClassTeacherTitle => 'Class teacher';

  @override
  String get staffClassTeacherHelper =>
      'The section they lead in an academic year. A section has one class teacher, and a teacher leads one section.';

  @override
  String get staffClassTeacherYear => 'Academic year';

  @override
  String get staffClassTeacherSection => 'Section';

  @override
  String get staffClassTeacherNone => 'No section';

  @override
  String get staffClassTeacherNoYears => 'Add an academic year under School setup first.';

  @override
  String get staffClassTeacherSave => 'Save class teacher';

  @override
  String get staffClassTeacherSaved => 'Class teacher saved';

  @override
  String get errorClassTeacherTaken => 'Another teacher is already the class teacher of this section for this year.';

  @override
  String get errorClassTeacherNotFound =>
      'The staff member, the year or the section could not be found. It may have been deactivated.';

  @override
  String get errorStaffBlocked => 'They are blocked. Unblock them under Settings first.';

  @override
  String get staffTeachingTitle => 'Teaching';

  @override
  String get staffTeachingHelper =>
      'The subjects they teach in each section of an academic year. Only a subject on their list above can be given to them.';

  @override
  String get staffTeachingYear => 'Academic year';

  @override
  String get staffTeachingNoYears => 'Add an academic year under School setup first.';

  @override
  String get staffTeachingNone => 'They do not teach in any section this year.';

  @override
  String get staffTeachingNoSubjects => 'Add subjects to their list above and save, then give them a section.';

  @override
  String get staffTeachingNoSections => 'Add a class with a section under School setup first.';

  @override
  String get staffTeachingChoose => 'Choose';

  @override
  String get staffTeachingSection => 'Section';

  @override
  String get staffTeachingSubject => 'Subject';

  @override
  String get staffTeachingAssign => 'Assign';

  @override
  String get staffTeachingEnd => 'End';

  @override
  String staffTeachingEndTitle(String subject, String section) {
    return 'End $subject in $section?';
  }

  @override
  String get staffTeachingEndMessage => 'They stop teaching it. The record stays as history.';

  @override
  String get staffTeachingEndAction => 'End assignment';

  @override
  String staffTeachingAssigned(String subject, String section) {
    return '$subject in $section assigned';
  }

  @override
  String staffTeachingEnded(String subject, String section) {
    return '$subject in $section ended';
  }

  @override
  String get errorTeachingDuplicate => 'They already teach this subject in this section this year.';

  @override
  String get errorSubjectNotTaught => 'This subject is not on their list. Add it to their subjects and save first.';

  @override
  String get errorTeachingNotFound =>
      'The assignment, the section or the subject could not be found. It may have been ended or deactivated.';

  @override
  String get staffIdentityTitle => 'Identity';

  @override
  String get staffAadhaar => 'Aadhaar number';

  @override
  String get staffAadhaarNotSet => 'Not set';

  @override
  String get staffAadhaarShow => 'Show full number';

  @override
  String get staffAadhaarSet => 'Set number';

  @override
  String get staffAadhaarChange => 'Change number';

  @override
  String get staffAadhaarClear => 'Clear number';

  @override
  String get staffAadhaarSetHelper => 'Twelve digits, the first one from 2 to 9. It is kept sealed and shown masked.';

  @override
  String get staffAadhaarInvalid => 'Check the twelve digits.';

  @override
  String get staffAadhaarSave => 'Save number';

  @override
  String get staffAadhaarSaved => 'Aadhaar number saved';

  @override
  String get staffAadhaarCleared => 'Aadhaar number cleared';

  @override
  String staffAadhaarClearTitle(String name) {
    return 'Clear the Aadhaar number of $name?';
  }

  @override
  String get staffAadhaarClearMessage => 'The number is removed. You can set it again later.';

  @override
  String get staffAadhaarRevealTitle => 'Show Aadhaar number';

  @override
  String get staffAadhaarReason => 'Reason (at least 10 characters)';

  @override
  String get staffAadhaarReasonHelper => 'It is kept in the audit log with your name.';

  @override
  String get staffAadhaarReasonShort => 'At least 10 characters.';

  @override
  String get staffAadhaarRevealAction => 'Show number';

  @override
  String get staffAadhaarRevealed => 'This is hidden again when you close it.';

  @override
  String get staffAadhaarDone => 'Done';

  @override
  String get errorAadhaarInvalid => 'This is not a valid Aadhaar number. Check the twelve digits.';

  @override
  String get errorAadhaarExists => 'This Aadhaar number is already recorded for someone in this Society.';

  @override
  String get errorAadhaarNotSet => 'No Aadhaar number is set for them.';

  @override
  String get errorRevealLimit => 'You have reached today\'s limit of ten reveals. Try again tomorrow.';

  @override
  String get errorRoleConflict => 'This email belongs to a platform account, which can\'t also be staff.';

  @override
  String get filesChooseDocument => 'Choose a file';

  @override
  String get filesChangeDocument => 'Change file';

  @override
  String get filesRemoveDocument => 'Remove file';

  @override
  String get filesUploadingDocument => 'Uploading file';

  @override
  String get filesDocumentHint => 'PDF, JPG, PNG or WebP, up to 5 MB.';

  @override
  String get staffTabDocuments => 'Documents';

  @override
  String get staffDocumentsHelper => 'Appointment letters, certificates and other files kept with this record.';

  @override
  String get staffDocumentsNone => 'No documents yet.';

  @override
  String get staffDocumentAddTitle => 'Add a document';

  @override
  String get staffDocumentTitle => 'Title';

  @override
  String get staffDocumentAttach => 'Add document';

  @override
  String staffDocumentAdded(String title) {
    return '$title added';
  }

  @override
  String filesNameAndSize(String name, String size) {
    return '$name · $size';
  }

  @override
  String staffDocumentOn(String date) {
    return 'Added $date';
  }

  @override
  String get staffDocumentOpen => 'Open';

  @override
  String get staffDocumentRemove => 'Remove';

  @override
  String staffDocumentRemoveTitle(String title) {
    return 'Remove $title?';
  }

  @override
  String get staffDocumentRemoveMessage => 'It leaves this record now. The file itself is deleted after 30 days.';

  @override
  String staffDocumentRemoved(String title) {
    return '$title removed';
  }

  @override
  String get errorDocumentDuplicate => 'This file is attached already.';

  @override
  String get errorDocumentInvalid => 'This file cannot be attached. Remove it and choose it again.';

  @override
  String get errorDocumentNotFound =>
      'The document, the file or the staff member could not be found. It may have been removed.';

  @override
  String get errorDocumentOpen => 'This phone could not open the file.';
}
