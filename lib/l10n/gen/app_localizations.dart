import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BravyNix'**
  String get appName;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a 6-digit code.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get codeTitle;

  /// No description provided for @codeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}'**
  String codeSubtitle(String email);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String resendIn(String time);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// No description provided for @errorOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code. {count, plural, =1{1 attempt} other{{count} attempts}} left.'**
  String errorOtpInvalid(int count);

  /// No description provided for @errorOtpInvalidNoCount.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code.'**
  String get errorOtpInvalidNoCount;

  /// No description provided for @errorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Request a new one.'**
  String get errorOtpExpired;

  /// No description provided for @errorOtpAttemptsExceeded.
  ///
  /// In en, this message translates to:
  /// **'Too many incorrect codes. Request a new one.'**
  String get errorOtpAttemptsExceeded;

  /// No description provided for @errorOtpAttemptsLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many incorrect codes. Try again in {duration}.'**
  String errorOtpAttemptsLocked(String duration);

  /// No description provided for @errorOtpResendTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Wait a minute before asking for another code.'**
  String get errorOtpResendTooSoon;

  /// No description provided for @errorOtpRequestLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many codes requested. Try again later.'**
  String get errorOtpRequestLimit;

  /// No description provided for @errorAuthLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many failed sign-ins. This email is locked for 30 minutes.'**
  String get errorAuthLocked;

  /// No description provided for @errorAuthLockedFor.
  ///
  /// In en, this message translates to:
  /// **'Too many failed sign-ins. Try again in {duration}.'**
  String errorAuthLockedFor(String duration);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String durationHours(int count);

  /// No description provided for @startAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get startAgain;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again shortly.'**
  String get errorRateLimited;

  /// No description provided for @errorAccountBlocked.
  ///
  /// In en, this message translates to:
  /// **'This account is blocked and can\'t access the app.'**
  String get errorAccountBlocked;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @errorDeviceStorage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read or save your sign-in on this phone. Try again.'**
  String get errorDeviceStorage;

  /// No description provided for @errorWithRequestId.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Reference: {requestId}'**
  String errorWithRequestId(String requestId);

  /// No description provided for @sessionEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been signed out'**
  String get sessionEndedTitle;

  /// No description provided for @sessionEndedExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again.'**
  String get sessionEndedExpired;

  /// No description provided for @sessionEndedBlocked.
  ///
  /// In en, this message translates to:
  /// **'This account is blocked.'**
  String get sessionEndedBlocked;

  /// No description provided for @sessionEndedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'You were signed out from another device.'**
  String get sessionEndedElsewhere;

  /// No description provided for @sessionEndedAdminRevoked.
  ///
  /// In en, this message translates to:
  /// **'Your Institution Admin access was removed. Sign in again to use your other roles.'**
  String get sessionEndedAdminRevoked;

  /// No description provided for @sessionEndedEmailChanged.
  ///
  /// In en, this message translates to:
  /// **'The email for this account was changed. Sign in with the new address.'**
  String get sessionEndedEmailChanged;

  /// No description provided for @sessionEndedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Sign in again.'**
  String get sessionEndedGeneric;

  /// No description provided for @signOutIncomplete.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed out, but this phone couldn\'t forget your sign-in. Sign in and log out again to finish.'**
  String get signOutIncomplete;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of the app is no longer supported. Update it from the store to continue.'**
  String get updateRequiredBody;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String homeWelcome(String name);

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Your home screen arrives with the next modules of the build plan.'**
  String get homeComingSoon;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleSuperAdmin;

  /// No description provided for @roleSocietyOwner.
  ///
  /// In en, this message translates to:
  /// **'Society Owner'**
  String get roleSocietyOwner;

  /// No description provided for @roleInstitutionAdmin.
  ///
  /// In en, this message translates to:
  /// **'Institution Admin'**
  String get roleInstitutionAdmin;

  /// No description provided for @roleTeacherStaff.
  ///
  /// In en, this message translates to:
  /// **'Teacher / Staff'**
  String get roleTeacherStaff;

  /// No description provided for @roleStudentParent.
  ///
  /// In en, this message translates to:
  /// **'Parent / Student'**
  String get roleStudentParent;

  /// No description provided for @roleBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get roleBlocked;

  /// No description provided for @chooseRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how to continue'**
  String get chooseRoleTitle;

  /// No description provided for @chooseRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your email has more than one role. You can change this later from Profile.'**
  String get chooseRoleSubtitle;

  /// No description provided for @noRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'No role available'**
  String get noRoleTitle;

  /// No description provided for @noRoleBody.
  ///
  /// In en, this message translates to:
  /// **'This account has no active role. Ask your Society to add you, then sign in again.'**
  String get noRoleBody;

  /// No description provided for @errorContextNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'You no longer have that role. Choose another one or sign in again.'**
  String get errorContextNotAvailable;

  /// No description provided for @errorAccessBlocked.
  ///
  /// In en, this message translates to:
  /// **'Access is blocked for that role. Choose another one or contact your Society.'**
  String get errorAccessBlocked;

  /// No description provided for @errorSectionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Access is blocked for your group. Contact your Society.'**
  String get errorSectionBlocked;

  /// No description provided for @errorSectionBlockedOwners.
  ///
  /// In en, this message translates to:
  /// **'Access to your Society is blocked. Contact BravyNix support.'**
  String get errorSectionBlockedOwners;

  /// No description provided for @blockedOwnersNotice.
  ///
  /// In en, this message translates to:
  /// **'Access to {society} is blocked. Contact BravyNix support.'**
  String blockedOwnersNotice(String society);

  /// No description provided for @blockedStaffNotice.
  ///
  /// In en, this message translates to:
  /// **'Your access to {society} is blocked. Contact your Society.'**
  String blockedStaffNotice(String society);

  /// No description provided for @blockedParentNotice.
  ///
  /// In en, this message translates to:
  /// **'Access to your children\'s information is blocked. Contact the school.'**
  String get blockedParentNotice;

  /// No description provided for @blocksTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked in {society}'**
  String blocksTitle(String society);

  /// No description provided for @blockTitleOwners.
  ///
  /// In en, this message translates to:
  /// **'Owners'**
  String get blockTitleOwners;

  /// No description provided for @blockTitleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff of {institution}'**
  String blockTitleStaff(String institution);

  /// No description provided for @blockTitleStudents.
  ///
  /// In en, this message translates to:
  /// **'Parents of {institution}'**
  String blockTitleStudents(String institution);

  /// No description provided for @blockReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String blockReason(String reason);

  /// No description provided for @blockedOn.
  ///
  /// In en, this message translates to:
  /// **'Blocked on {date}'**
  String blockedOn(String date);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRole;

  /// No description provided for @profileSociety.
  ///
  /// In en, this message translates to:
  /// **'Society'**
  String get profileSociety;

  /// No description provided for @switchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch role'**
  String get switchRole;

  /// No description provided for @switchRoleDetail.
  ///
  /// In en, this message translates to:
  /// **'Use the app as another role'**
  String get switchRoleDetail;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get openProfile;

  /// No description provided for @platformDuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform dues'**
  String get platformDuesTitle;

  /// No description provided for @platformDuesDetail.
  ///
  /// In en, this message translates to:
  /// **'What BravyNix has charged your Society'**
  String get platformDuesDetail;

  /// No description provided for @platformDuesBannerDue.
  ///
  /// In en, this message translates to:
  /// **'You are due {amount}'**
  String platformDuesBannerDue(String amount);

  /// No description provided for @platformDuesBannerPaid.
  ///
  /// In en, this message translates to:
  /// **'All dues are paid'**
  String get platformDuesBannerPaid;

  /// No description provided for @platformDuesBannerPaidDetail.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting for payment.'**
  String get platformDuesBannerPaidDetail;

  /// No description provided for @platformDuesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No dues yet'**
  String get platformDuesEmptyTitle;

  /// No description provided for @platformDuesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'BravyNix has not charged your Society anything so far.'**
  String get platformDuesEmptyMessage;

  /// No description provided for @dueStatusDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueStatusDue;

  /// No description provided for @dueStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get dueStatusPaid;

  /// No description provided for @dueStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get dueStatusCancelled;

  /// No description provided for @dueStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dueStatusOverdue;

  /// No description provided for @duePeriod.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String duePeriod(String start, String end);

  /// No description provided for @duePayBy.
  ///
  /// In en, this message translates to:
  /// **'Pay by {date}'**
  String duePayBy(String date);

  /// No description provided for @duePaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String duePaidOn(String date);

  /// No description provided for @dueDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueDetailTitle;

  /// No description provided for @duePayByLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay by'**
  String get duePayByLabel;

  /// No description provided for @duePaidOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get duePaidOnLabel;

  /// No description provided for @dueInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get dueInvoiceNumber;

  /// No description provided for @duePeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get duePeriodLabel;

  /// No description provided for @dueTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get dueTotal;

  /// No description provided for @dueStudentsTimesRate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student} other{{count} students}} × {rate}'**
  String dueStudentsTimesRate(int count, String rate);

  /// No description provided for @dueAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get dueAdjustment;

  /// No description provided for @dueHowReached.
  ///
  /// In en, this message translates to:
  /// **'How the total was reached'**
  String get dueHowReached;

  /// No description provided for @duePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get duePaymentTitle;

  /// No description provided for @duePaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get duePaidBy;

  /// No description provided for @duePaymentReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get duePaymentReference;

  /// No description provided for @dueCancelledNote.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by BravyNix. You do not owe this.'**
  String get dueCancelledNote;

  /// No description provided for @paymentModeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentModeCash;

  /// No description provided for @paymentModeBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentModeBankTransfer;

  /// No description provided for @paymentModeUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get paymentModeUpi;

  /// No description provided for @paymentModeCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get paymentModeCheque;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @schoolSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'School setup'**
  String get schoolSetupTitle;

  /// No description provided for @schoolSetupDetail.
  ///
  /// In en, this message translates to:
  /// **'Your Institutions and how they are set up'**
  String get schoolSetupDetail;

  /// No description provided for @institutionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Institutions'**
  String get institutionsTitle;

  /// No description provided for @institutionsDetail.
  ///
  /// In en, this message translates to:
  /// **'The Institutions you work in'**
  String get institutionsDetail;

  /// No description provided for @institutionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Institutions yet'**
  String get institutionsEmptyTitle;

  /// No description provided for @institutionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'There is no active Institution for you to work in.'**
  String get institutionsEmptyMessage;

  /// No description provided for @institutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institutionTitle;

  /// No description provided for @institutionSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Change Institution'**
  String get institutionSwitchHint;

  /// No description provided for @institutionSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an Institution'**
  String get institutionSwitchTitle;

  /// No description provided for @institutionCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get institutionCode;

  /// No description provided for @institutionPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get institutionPlace;

  /// No description provided for @institutionBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get institutionBoard;

  /// No description provided for @institutionAffiliation.
  ///
  /// In en, this message translates to:
  /// **'Affiliation number'**
  String get institutionAffiliation;

  /// No description provided for @institutionGstin.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get institutionGstin;

  /// No description provided for @institutionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get institutionContact;

  /// No description provided for @institutionAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get institutionAddress;

  /// No description provided for @institutionPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get institutionPhone;

  /// No description provided for @institutionTelephone.
  ///
  /// In en, this message translates to:
  /// **'Telephone'**
  String get institutionTelephone;

  /// No description provided for @institutionClassesOffered.
  ///
  /// In en, this message translates to:
  /// **'Classes offered'**
  String get institutionClassesOffered;

  /// No description provided for @institutionNoClassesOffered.
  ///
  /// In en, this message translates to:
  /// **'No class categories are offered yet.'**
  String get institutionNoClassesOffered;

  /// No description provided for @institutionDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Institution'**
  String get institutionDeactivate;

  /// No description provided for @institutionDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String institutionDeactivateTitle(String name);

  /// No description provided for @institutionDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'It leaves your list, and the Institution Admins of it lose access to it. Nothing is deleted.'**
  String get institutionDeactivateMessage;

  /// No description provided for @institutionDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Institution deactivated'**
  String get institutionDeactivated;

  /// No description provided for @institutionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Institution'**
  String get institutionAdd;

  /// No description provided for @institutionAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Institution'**
  String get institutionAddTitle;

  /// No description provided for @institutionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get institutionEdit;

  /// No description provided for @institutionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Institution'**
  String get institutionEditTitle;

  /// No description provided for @institutionSaved.
  ///
  /// In en, this message translates to:
  /// **'Institution saved'**
  String get institutionSaved;

  /// No description provided for @institutionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get institutionSave;

  /// No description provided for @institutionFormBasics.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get institutionFormBasics;

  /// No description provided for @institutionName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get institutionName;

  /// No description provided for @institutionCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Letters and digits. It can\'t be changed after saving.'**
  String get institutionCodeHelper;

  /// No description provided for @institutionBoardNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get institutionBoardNone;

  /// No description provided for @institutionAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address line 1'**
  String get institutionAddressLine1;

  /// No description provided for @institutionAddressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address line 2'**
  String get institutionAddressLine2;

  /// No description provided for @institutionPincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get institutionPincode;

  /// No description provided for @institutionCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get institutionCountry;

  /// No description provided for @institutionState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get institutionState;

  /// No description provided for @institutionCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get institutionCity;

  /// No description provided for @institutionCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get institutionCountryCode;

  /// No description provided for @institutionPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get institutionPhoneNumber;

  /// No description provided for @institutionNoCategories.
  ///
  /// In en, this message translates to:
  /// **'There are no class categories to choose from.'**
  String get institutionNoCategories;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @errorInstitutionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Another Institution already uses this code.'**
  String get errorInstitutionDuplicate;

  /// No description provided for @errorVersionConflict.
  ///
  /// In en, this message translates to:
  /// **'Someone else changed this. Your changes were not saved.'**
  String get errorVersionConflict;

  /// No description provided for @institutionReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get institutionReload;

  /// No description provided for @errorCategoryInUse.
  ///
  /// In en, this message translates to:
  /// **'Classes already use a category you unticked, so it has to stay offered. Tick it again to save.'**
  String get errorCategoryInUse;

  /// No description provided for @errorReferenceInactive.
  ///
  /// In en, this message translates to:
  /// **'Something you chose is no longer available. Choose again.'**
  String get errorReferenceInactive;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Check the fields marked in red.'**
  String get errorValidation;

  /// No description provided for @academicYearsTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic years'**
  String get academicYearsTitle;

  /// No description provided for @academicYearsDetail.
  ///
  /// In en, this message translates to:
  /// **'The school years of each Institution'**
  String get academicYearsDetail;

  /// No description provided for @academicYearsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No academic years yet'**
  String get academicYearsEmptyTitle;

  /// No description provided for @academicYearsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the first year. It becomes the current year.'**
  String get academicYearsEmptyMessage;

  /// No description provided for @academicYearAdd.
  ///
  /// In en, this message translates to:
  /// **'Add academic year'**
  String get academicYearAdd;

  /// No description provided for @academicYearAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add academic year'**
  String get academicYearAddTitle;

  /// No description provided for @academicYearEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit academic year'**
  String get academicYearEditTitle;

  /// No description provided for @academicYearEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get academicYearEdit;

  /// No description provided for @academicYearCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get academicYearCurrent;

  /// No description provided for @academicYearCurrentHint.
  ///
  /// In en, this message translates to:
  /// **'To deactivate this year, make another year current first.'**
  String get academicYearCurrentHint;

  /// No description provided for @backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to the list'**
  String get backToList;

  /// No description provided for @academicYearMakeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Make current'**
  String get academicYearMakeCurrent;

  /// No description provided for @academicYearDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get academicYearDeactivate;

  /// No description provided for @academicYearDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String academicYearDeactivateTitle(String name);

  /// No description provided for @academicYearDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'It leaves the list and its dates are free again. Nothing is deleted.'**
  String get academicYearDeactivateMessage;

  /// No description provided for @academicYearDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Academic year deactivated'**
  String get academicYearDeactivated;

  /// No description provided for @academicYearMadeCurrent.
  ///
  /// In en, this message translates to:
  /// **'{name} is now the current year'**
  String academicYearMadeCurrent(String name);

  /// No description provided for @academicYearSaved.
  ///
  /// In en, this message translates to:
  /// **'Academic year saved'**
  String get academicYearSaved;

  /// No description provided for @academicYearName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get academicYearName;

  /// No description provided for @academicYearNameHelper.
  ///
  /// In en, this message translates to:
  /// **'For example 2026-2027'**
  String get academicYearNameHelper;

  /// No description provided for @academicYearStart.
  ///
  /// In en, this message translates to:
  /// **'Starts on'**
  String get academicYearStart;

  /// No description provided for @academicYearEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get academicYearEnd;

  /// No description provided for @academicYearDates.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String academicYearDates(String start, String end);

  /// No description provided for @academicYearSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get academicYearSave;

  /// No description provided for @errorYearOverlap.
  ///
  /// In en, this message translates to:
  /// **'These dates overlap another academic year of this Institution.'**
  String get errorYearOverlap;

  /// No description provided for @errorYearDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Another academic year of this Institution has this name.'**
  String get errorYearDuplicate;

  /// No description provided for @errorCurrentYearLocked.
  ///
  /// In en, this message translates to:
  /// **'The current year can\'t be deactivated. Make another year current first.'**
  String get errorCurrentYearLocked;

  /// No description provided for @subjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjectsTitle;

  /// No description provided for @subjectsDetail.
  ///
  /// In en, this message translates to:
  /// **'The subjects every Institution of the Society teaches'**
  String get subjectsDetail;

  /// No description provided for @subjectsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No subjects yet'**
  String get subjectsEmptyTitle;

  /// No description provided for @subjectsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the subjects your Institutions teach. They are shared by all of them.'**
  String get subjectsEmptyMessage;

  /// No description provided for @subjectAdd.
  ///
  /// In en, this message translates to:
  /// **'Add subject'**
  String get subjectAdd;

  /// No description provided for @subjectAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add subject'**
  String get subjectAddTitle;

  /// No description provided for @subjectEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit subject'**
  String get subjectEditTitle;

  /// No description provided for @subjectEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get subjectEdit;

  /// No description provided for @subjectDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get subjectDeactivate;

  /// No description provided for @subjectDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String subjectDeactivateTitle(String name);

  /// No description provided for @subjectDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'It leaves the list and its name and code are free again. Nothing is deleted.'**
  String get subjectDeactivateMessage;

  /// No description provided for @subjectDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated'**
  String subjectDeactivated(String name);

  /// No description provided for @subjectSaved.
  ///
  /// In en, this message translates to:
  /// **'Subject saved'**
  String get subjectSaved;

  /// No description provided for @subjectName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get subjectName;

  /// No description provided for @subjectCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get subjectCode;

  /// No description provided for @subjectCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional, like MATH'**
  String get subjectCodeHelper;

  /// No description provided for @subjectSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get subjectSave;

  /// No description provided for @errorSubjectDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Another subject has this name or code.'**
  String get errorSubjectDuplicate;

  /// No description provided for @errorSubjectNameTaken.
  ///
  /// In en, this message translates to:
  /// **'Another subject has this name.'**
  String get errorSubjectNameTaken;

  /// No description provided for @errorSubjectCodeTaken.
  ///
  /// In en, this message translates to:
  /// **'Another subject has this code.'**
  String get errorSubjectCodeTaken;

  /// No description provided for @errorSubjectNotFound.
  ///
  /// In en, this message translates to:
  /// **'This subject could not be found. It may have been deactivated.'**
  String get errorSubjectNotFound;

  /// No description provided for @classesTitle.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classesTitle;

  /// No description provided for @classesDetail.
  ///
  /// In en, this message translates to:
  /// **'The classes of each Institution and their sections'**
  String get classesDetail;

  /// No description provided for @classesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No classes yet'**
  String get classesEmptyTitle;

  /// No description provided for @classesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the classes this Institution teaches, from the categories it offers.'**
  String get classesEmptyMessage;

  /// No description provided for @classAdd.
  ///
  /// In en, this message translates to:
  /// **'Add class'**
  String get classAdd;

  /// No description provided for @classAddSeveral.
  ///
  /// In en, this message translates to:
  /// **'Add several'**
  String get classAddSeveral;

  /// No description provided for @classAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add class'**
  String get classAddTitle;

  /// No description provided for @classEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit class'**
  String get classEditTitle;

  /// No description provided for @classEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get classEdit;

  /// No description provided for @classDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get classDeactivate;

  /// No description provided for @classDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String classDeactivateTitle(String name);

  /// No description provided for @classDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'Its sections are deactivated with it. Nothing is deleted.'**
  String get classDeactivateMessage;

  /// No description provided for @classDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated'**
  String classDeactivated(String name);

  /// No description provided for @classSaved.
  ///
  /// In en, this message translates to:
  /// **'Class saved'**
  String get classSaved;

  /// No description provided for @classesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 class added} other{{count} classes added}}'**
  String classesAdded(int count);

  /// No description provided for @classSections.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sections} =1{1 section} other{{count} sections}}'**
  String classSections(int count);

  /// No description provided for @classPredefined.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classPredefined;

  /// No description provided for @classStream.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get classStream;

  /// No description provided for @classStreamHelper.
  ///
  /// In en, this message translates to:
  /// **'For example PCMC'**
  String get classStreamHelper;

  /// No description provided for @classDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get classDisplayName;

  /// No description provided for @classDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Class name'**
  String get classDisplayNameHint;

  /// No description provided for @classCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get classCode;

  /// No description provided for @classCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get classCodeHelper;

  /// No description provided for @classChooseOne.
  ///
  /// In en, this message translates to:
  /// **'Choose a class'**
  String get classChooseOne;

  /// No description provided for @classSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get classSave;

  /// No description provided for @classBulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Add several classes'**
  String get classBulkTitle;

  /// No description provided for @classBulkMessage.
  ///
  /// In en, this message translates to:
  /// **'Tick the classes to add. Pre-University classes have streams, so add them one at a time.'**
  String get classBulkMessage;

  /// No description provided for @classBulkAlready.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get classBulkAlready;

  /// No description provided for @classBulkNone.
  ///
  /// In en, this message translates to:
  /// **'Every class of the categories this Institution offers is already added, or needs a stream.'**
  String get classBulkNone;

  /// No description provided for @classBulkAdd.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add classes} =1{Add 1 class} other{Add {count} classes}}'**
  String classBulkAdd(int count);

  /// No description provided for @errorClassDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Another class of this Institution already has this name or stream.'**
  String get errorClassDuplicate;

  /// No description provided for @errorClassNameTaken.
  ///
  /// In en, this message translates to:
  /// **'Another class of this Institution has this name.'**
  String get errorClassNameTaken;

  /// No description provided for @errorClassTaken.
  ///
  /// In en, this message translates to:
  /// **'This class is already added to this Institution.'**
  String get errorClassTaken;

  /// No description provided for @errorClassNotOffered.
  ///
  /// In en, this message translates to:
  /// **'This Institution does not offer this class\'s category. Tick the category on the Institution first.'**
  String get errorClassNotOffered;

  /// No description provided for @errorStreamNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only Pre-University classes have a stream.'**
  String get errorStreamNotAllowed;

  /// No description provided for @errorClassHasStudents.
  ///
  /// In en, this message translates to:
  /// **'Students are placed in this class. Move them first.'**
  String get errorClassHasStudents;

  /// No description provided for @classBulkItemRefused.
  ///
  /// In en, this message translates to:
  /// **'{name}: {reason}'**
  String classBulkItemRefused(String name, String reason);

  /// No description provided for @errorClassNotFound.
  ///
  /// In en, this message translates to:
  /// **'This class could not be found. It may have been deactivated.'**
  String get errorClassNotFound;

  /// No description provided for @errorSectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This section could not be found. It may have been deactivated.'**
  String get errorSectionNotFound;

  /// No description provided for @classOpenSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get classOpenSections;

  /// No description provided for @sectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get sectionsTitle;

  /// No description provided for @sectionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sections yet'**
  String get sectionsEmptyTitle;

  /// No description provided for @sectionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the sections of {name}, such as A and B.'**
  String sectionsEmptyMessage(String name);

  /// No description provided for @sectionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get sectionAdd;

  /// No description provided for @sectionAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get sectionAddTitle;

  /// No description provided for @sectionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit section'**
  String get sectionEditTitle;

  /// No description provided for @sectionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get sectionEdit;

  /// No description provided for @sectionDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get sectionDeactivate;

  /// No description provided for @sectionDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String sectionDeactivateTitle(String name);

  /// No description provided for @sectionDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'Its name can be used again. Nothing is deleted.'**
  String get sectionDeactivateMessage;

  /// No description provided for @sectionDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated'**
  String sectionDeactivated(String name);

  /// No description provided for @sectionSaved.
  ///
  /// In en, this message translates to:
  /// **'Section saved'**
  String get sectionSaved;

  /// No description provided for @sectionCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity {count}'**
  String sectionCapacity(int count);

  /// No description provided for @sectionNoCapacity.
  ///
  /// In en, this message translates to:
  /// **'No capacity set'**
  String get sectionNoCapacity;

  /// No description provided for @sectionStudents.
  ///
  /// In en, this message translates to:
  /// **'Students {count}'**
  String sectionStudents(String count);

  /// No description provided for @sectionPredefined.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get sectionPredefined;

  /// No description provided for @sectionDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sectionDisplayName;

  /// No description provided for @sectionDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Section name'**
  String get sectionDisplayNameHint;

  /// No description provided for @sectionCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get sectionCapacityLabel;

  /// No description provided for @sectionCapacityHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. A warning, not a limit'**
  String get sectionCapacityHelper;

  /// No description provided for @sectionCapacityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 32767.'**
  String get sectionCapacityInvalid;

  /// No description provided for @sectionChooseOne.
  ///
  /// In en, this message translates to:
  /// **'Choose a section'**
  String get sectionChooseOne;

  /// No description provided for @sectionNoneLeft.
  ///
  /// In en, this message translates to:
  /// **'Every predefined section is already added to this class.'**
  String get sectionNoneLeft;

  /// No description provided for @sectionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get sectionSave;

  /// No description provided for @errorSectionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Another section of this class already has this name.'**
  String get errorSectionDuplicate;

  /// No description provided for @errorSectionNameTaken.
  ///
  /// In en, this message translates to:
  /// **'Another section of this class has this name.'**
  String get errorSectionNameTaken;

  /// No description provided for @errorSectionTaken.
  ///
  /// In en, this message translates to:
  /// **'This section is already added to this class.'**
  String get errorSectionTaken;

  /// No description provided for @errorSectionHasStudents.
  ///
  /// In en, this message translates to:
  /// **'Students are placed in this section. Move them first.'**
  String get errorSectionHasStudents;

  /// No description provided for @errorYearNotFound.
  ///
  /// In en, this message translates to:
  /// **'This academic year could not be found. It may have been deactivated.'**
  String get errorYearNotFound;

  /// No description provided for @errorInstitutionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This Institution could not be found. It may have been deactivated.'**
  String get errorInstitutionNotFound;

  /// No description provided for @boardCbse.
  ///
  /// In en, this message translates to:
  /// **'CBSE'**
  String get boardCbse;

  /// No description provided for @boardIcse.
  ///
  /// In en, this message translates to:
  /// **'ICSE'**
  String get boardIcse;

  /// No description provided for @boardState.
  ///
  /// In en, this message translates to:
  /// **'State Board'**
  String get boardState;

  /// No description provided for @boardIb.
  ///
  /// In en, this message translates to:
  /// **'IB'**
  String get boardIb;

  /// No description provided for @boardIgcse.
  ///
  /// In en, this message translates to:
  /// **'IGCSE'**
  String get boardIgcse;

  /// No description provided for @boardOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get boardOther;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this.'**
  String get errorForbidden;

  /// No description provided for @errorDueNotFound.
  ///
  /// In en, this message translates to:
  /// **'This due could not be found. It may belong to another Society.'**
  String get errorDueNotFound;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @filesAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get filesAddPhoto;

  /// No description provided for @filesChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get filesChangePhoto;

  /// No description provided for @filesRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get filesRemovePhoto;

  /// No description provided for @filesPhotoSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get filesPhotoSourceTitle;

  /// No description provided for @filesTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get filesTakePhoto;

  /// No description provided for @filesChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get filesChooseFromGallery;

  /// No description provided for @filesUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo'**
  String get filesUploadingPhoto;

  /// No description provided for @errorFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'This file is empty. Choose another one.'**
  String get errorFileEmpty;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is larger than 5 MB. Choose a smaller one.'**
  String get errorFileTooLarge;

  /// No description provided for @errorFileTypeNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This kind of file can\'t be used here. Choose a different one.'**
  String get errorFileTypeNotAllowed;

  /// No description provided for @errorFileCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'The file is damaged or is not what it says it is. Choose it again.'**
  String get errorFileCheckFailed;

  /// No description provided for @errorFileNotArrived.
  ///
  /// In en, this message translates to:
  /// **'The file did not arrive. Send it again.'**
  String get errorFileNotArrived;

  /// No description provided for @errorFileRefused.
  ///
  /// In en, this message translates to:
  /// **'The file could not be sent. Send it again.'**
  String get errorFileRefused;

  /// No description provided for @errorFileSchoolNotFound.
  ///
  /// In en, this message translates to:
  /// **'You can\'t add files for this school.'**
  String get errorFileSchoolNotFound;

  /// No description provided for @errorFilePickCamera.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera. Allow it in Settings and try again.'**
  String get errorFilePickCamera;

  /// No description provided for @errorFilePickGallery.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your photos. Allow it in Settings and try again.'**
  String get errorFilePickGallery;

  /// No description provided for @errorFilePickFiles.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your files. Try again.'**
  String get errorFilePickFiles;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Teachers / Staff'**
  String get staffTitle;

  /// No description provided for @staffDetail.
  ///
  /// In en, this message translates to:
  /// **'The teachers and staff of each Institution'**
  String get staffDetail;

  /// No description provided for @staffSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or ID'**
  String get staffSearchHint;

  /// No description provided for @staffSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get staffSearchClear;

  /// No description provided for @staffEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No staff yet'**
  String get staffEmptyTitle;

  /// No description provided for @staffEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Teachers and staff added to this Institution appear here.'**
  String get staffEmptyMessage;

  /// No description provided for @staffNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No staff match \"{query}\"'**
  String staffNoMatchTitle(String query);

  /// No description provided for @staffNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or search by Employee ID.'**
  String get staffNoMatchMessage;

  /// No description provided for @staffLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get staffLoadMore;

  /// No description provided for @staffBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get staffBlocked;

  /// No description provided for @staffDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get staffDeactivate;

  /// No description provided for @staffDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String staffDeactivateTitle(String name);

  /// No description provided for @staffDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'They can no longer sign in as staff, any Admin Access they hold is taken away, and their class and subject assignments end. Nothing is deleted.'**
  String get staffDeactivateMessage;

  /// No description provided for @staffDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated'**
  String staffDeactivated(String name);

  /// No description provided for @errorStaffNotFound.
  ///
  /// In en, this message translates to:
  /// **'This staff member could not be found. They may have been deactivated.'**
  String get errorStaffNotFound;

  /// No description provided for @errorCannotActOnSelf.
  ///
  /// In en, this message translates to:
  /// **'You can\'t do this to your own record.'**
  String get errorCannotActOnSelf;

  /// No description provided for @staffProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher profile'**
  String get staffProfileTitle;

  /// No description provided for @staffSectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get staffSectionPersonal;

  /// No description provided for @staffSectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get staffSectionContact;

  /// No description provided for @staffSectionEmployment.
  ///
  /// In en, this message translates to:
  /// **'Employment'**
  String get staffSectionEmployment;

  /// No description provided for @staffSectionEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get staffSectionEducation;

  /// No description provided for @staffSectionEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get staffSectionEmergency;

  /// No description provided for @staffEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get staffEmployeeId;

  /// No description provided for @staffDesignation.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get staffDesignation;

  /// No description provided for @staffCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get staffCategory;

  /// No description provided for @staffGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get staffGender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @staffDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get staffDateOfBirth;

  /// No description provided for @staffBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get staffBloodGroup;

  /// No description provided for @staffNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get staffNationality;

  /// No description provided for @staffMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get staffMobile;

  /// No description provided for @staffAlternateNumber.
  ///
  /// In en, this message translates to:
  /// **'Alternate number'**
  String get staffAlternateNumber;

  /// No description provided for @staffAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get staffAddress;

  /// No description provided for @staffJoiningDate.
  ///
  /// In en, this message translates to:
  /// **'Joining date'**
  String get staffJoiningDate;

  /// No description provided for @staffResignationDate.
  ///
  /// In en, this message translates to:
  /// **'Resignation date'**
  String get staffResignationDate;

  /// No description provided for @staffEmploymentType.
  ///
  /// In en, this message translates to:
  /// **'Employment type'**
  String get staffEmploymentType;

  /// No description provided for @employmentFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full time'**
  String get employmentFullTime;

  /// No description provided for @employmentPartTime.
  ///
  /// In en, this message translates to:
  /// **'Part time'**
  String get employmentPartTime;

  /// No description provided for @employmentVisiting.
  ///
  /// In en, this message translates to:
  /// **'Visiting'**
  String get employmentVisiting;

  /// No description provided for @employmentContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get employmentContract;

  /// No description provided for @staffPrimaryContact.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get staffPrimaryContact;

  /// No description provided for @staffContactRelation.
  ///
  /// In en, this message translates to:
  /// **'{name} ({relation})'**
  String staffContactRelation(String name, String relation);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
