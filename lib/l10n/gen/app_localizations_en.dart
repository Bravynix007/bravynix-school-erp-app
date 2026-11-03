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
  String get institutionAddress => 'Address';

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
  String get institutionAddressLine1 => 'Address line 1';

  @override
  String get institutionAddressLine2 => 'Address line 2';

  @override
  String get institutionPincode => 'Pincode';

  @override
  String get institutionCountry => 'Country';

  @override
  String get institutionState => 'State';

  @override
  String get institutionCity => 'City';

  @override
  String get institutionCountryCode => 'Country code';

  @override
  String get institutionPhoneNumber => 'Phone number';

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
}
