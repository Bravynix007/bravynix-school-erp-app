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

  /// No description provided for @authProductName.
  ///
  /// In en, this message translates to:
  /// **'School ERP'**
  String get authProductName;

  /// No description provided for @authTaglineLead.
  ///
  /// In en, this message translates to:
  /// **'School life,'**
  String get authTaglineLead;

  /// No description provided for @authTaglineEmphasis.
  ///
  /// In en, this message translates to:
  /// **'connected.'**
  String get authTaglineEmphasis;

  /// No description provided for @authEmailExample.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailExample;

  /// No description provided for @authSignInHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help? Contact your school office.'**
  String get authSignInHelp;

  /// No description provided for @authCheckingSession.
  ///
  /// In en, this message translates to:
  /// **'Checking your sign-in…'**
  String get authCheckingSession;

  /// No description provided for @authRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the app'**
  String get authRestoreTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the email address you shared with your school.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
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
  /// **'Send sign-in code'**
  String get sendCode;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get codeTitle;

  /// No description provided for @codeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If this email is registered, a code has been sent.'**
  String get codeSubtitle;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// No description provided for @codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter all six digits.'**
  String get codeRequired;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
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

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get inboxTitle;

  /// No description provided for @inboxTabOnlyForYou.
  ///
  /// In en, this message translates to:
  /// **'Only for you'**
  String get inboxTabOnlyForYou;

  /// No description provided for @inboxTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inboxTabAll;

  /// No description provided for @inboxTabAllTeachers.
  ///
  /// In en, this message translates to:
  /// **'All teachers'**
  String get inboxTabAllTeachers;

  /// No description provided for @inboxTabAllStudents.
  ///
  /// In en, this message translates to:
  /// **'All students'**
  String get inboxTabAllStudents;

  /// No description provided for @inboxMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get inboxMarkAllRead;

  /// No description provided for @inboxClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get inboxClear;

  /// No description provided for @inboxClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear notifications?'**
  String get inboxClearTitle;

  /// No description provided for @inboxClearMessage.
  ///
  /// In en, this message translates to:
  /// **'Every notification in \"{tab}\" is deleted for good.'**
  String inboxClearMessage(String tab);

  /// No description provided for @inboxClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get inboxClearConfirm;

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get inboxEmptyTitle;

  /// No description provided for @inboxEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'New notifications about your school show up here.'**
  String get inboxEmptyMessage;

  /// No description provided for @inboxLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get inboxLoadMore;

  /// No description provided for @inboxUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get inboxUnread;

  /// No description provided for @inboxFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {sender} · {when}'**
  String inboxFrom(String sender, String when);

  /// No description provided for @bellTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get bellTooltip;

  /// No description provided for @bellUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String bellUnread(int count);

  /// No description provided for @quickAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccessTitle;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @eventsPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get eventsPreviousMonth;

  /// No description provided for @eventsNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get eventsNextMonth;

  /// No description provided for @eventsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get eventsFilterAll;

  /// No description provided for @eventsFilterHolidays.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get eventsFilterHolidays;

  /// No description provided for @eventsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No events this month'**
  String get eventsEmptyTitle;

  /// No description provided for @eventsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Events and holidays your school adds show up here.'**
  String get eventsEmptyMessage;

  /// No description provided for @eventsEmptyHolidaysTitle.
  ///
  /// In en, this message translates to:
  /// **'No holidays this month'**
  String get eventsEmptyHolidaysTitle;

  /// No description provided for @eventHolidayTag.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get eventHolidayTag;

  /// No description provided for @eventWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get eventWhen;

  /// No description provided for @eventOneDay.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String eventOneDay(String date);

  /// No description provided for @eventDays.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String eventDays(String start, String end);

  /// No description provided for @eventVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get eventVenue;

  /// No description provided for @eventAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get eventAbout;

  /// No description provided for @eventAudience.
  ///
  /// In en, this message translates to:
  /// **'Told to'**
  String get eventAudience;

  /// No description provided for @eventAudienceEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get eventAudienceEveryone;

  /// No description provided for @eventAudienceStudents.
  ///
  /// In en, this message translates to:
  /// **'Students and parents'**
  String get eventAudienceStudents;

  /// No description provided for @eventAudienceStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get eventAudienceStaff;

  /// No description provided for @eventScope.
  ///
  /// In en, this message translates to:
  /// **'Belongs to'**
  String get eventScope;

  /// No description provided for @eventScopeSociety.
  ///
  /// In en, this message translates to:
  /// **'The whole Society'**
  String get eventScopeSociety;

  /// No description provided for @eventScopeInstitution.
  ///
  /// In en, this message translates to:
  /// **'One Institution'**
  String get eventScopeInstitution;

  /// No description provided for @eventHolidayType.
  ///
  /// In en, this message translates to:
  /// **'Kind of holiday'**
  String get eventHolidayType;

  /// No description provided for @eventHolidayPublic.
  ///
  /// In en, this message translates to:
  /// **'Public holiday'**
  String get eventHolidayPublic;

  /// No description provided for @eventHolidayVacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get eventHolidayVacation;

  /// No description provided for @eventHolidayEvent.
  ///
  /// In en, this message translates to:
  /// **'Event holiday'**
  String get eventHolidayEvent;

  /// No description provided for @eventHolidayOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get eventHolidayOptional;

  /// No description provided for @eventHolidayFor.
  ///
  /// In en, this message translates to:
  /// **'Holiday for'**
  String get eventHolidayFor;

  /// No description provided for @eventHolidayForStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get eventHolidayForStudents;

  /// No description provided for @eventHolidayForStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get eventHolidayForStaff;

  /// No description provided for @eventHolidayForBoth.
  ///
  /// In en, this message translates to:
  /// **'Students and staff'**
  String get eventHolidayForBoth;

  /// No description provided for @eventHolidayClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get eventHolidayClasses;

  /// No description provided for @eventHolidayEveryClass.
  ///
  /// In en, this message translates to:
  /// **'Every class'**
  String get eventHolidayEveryClass;

  /// No description provided for @eventHolidaySomeClasses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 class} other{{count} classes}}'**
  String eventHolidaySomeClasses(int count);

  /// No description provided for @errorEventNotFound.
  ///
  /// In en, this message translates to:
  /// **'This event is no longer available.'**
  String get errorEventNotFound;

  /// No description provided for @errorChildAccessBlocked.
  ///
  /// In en, this message translates to:
  /// **'Access to this child\'s information is blocked. Contact the school.'**
  String get errorChildAccessBlocked;

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
  /// **'Choose a role'**
  String get chooseRoleTitle;

  /// No description provided for @chooseRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can switch roles later from Profile.'**
  String get chooseRoleSubtitle;

  /// No description provided for @roleCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current role'**
  String get roleCurrent;

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

  /// No description provided for @blockedChildNotice.
  ///
  /// In en, this message translates to:
  /// **'Access to {child}\'s information is blocked. Contact the school.'**
  String blockedChildNotice(String child);

  /// No description provided for @childSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Change child'**
  String get childSwitchHint;

  /// No description provided for @childSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a child'**
  String get childSwitchTitle;

  /// No description provided for @childDetail.
  ///
  /// In en, this message translates to:
  /// **'{classSection}, {institution}'**
  String childDetail(String classSection, String institution);

  /// No description provided for @childNoClass.
  ///
  /// In en, this message translates to:
  /// **'Not placed in a class yet'**
  String get childNoClass;

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

  /// No description provided for @addressSection.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressSection;

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

  /// No description provided for @addressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address line 1'**
  String get addressLine1;

  /// No description provided for @addressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address line 2'**
  String get addressLine2;

  /// No description provided for @addressPincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get addressPincode;

  /// No description provided for @placeCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get placeCountry;

  /// No description provided for @placeState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get placeState;

  /// No description provided for @placeCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get placeCity;

  /// No description provided for @phoneCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get phoneCountryCode;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

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

  /// No description provided for @errorFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get errorFieldRequired;

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

  /// No description provided for @timeSlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Period timings'**
  String get timeSlotsTitle;

  /// No description provided for @timeSlotsDetail.
  ///
  /// In en, this message translates to:
  /// **'The periods of the school day, for the current academic year'**
  String get timeSlotsDetail;

  /// No description provided for @timeSlotsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No periods yet'**
  String get timeSlotsEmptyTitle;

  /// No description provided for @timeSlotsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the periods and breaks of the school day. The class timetable is built from them.'**
  String get timeSlotsEmptyMessage;

  /// No description provided for @timeSlotAdd.
  ///
  /// In en, this message translates to:
  /// **'Add period'**
  String get timeSlotAdd;

  /// No description provided for @timeSlotAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add period'**
  String get timeSlotAddTitle;

  /// No description provided for @timeSlotEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit period'**
  String get timeSlotEditTitle;

  /// No description provided for @timeSlotEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get timeSlotEdit;

  /// No description provided for @timeSlotDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get timeSlotDeactivate;

  /// No description provided for @timeSlotDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String timeSlotDeactivateTitle(String name);

  /// No description provided for @timeSlotDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'It leaves the list and its number and times are free again. Nothing is deleted.'**
  String get timeSlotDeactivateMessage;

  /// No description provided for @timeSlotDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Period deactivated'**
  String get timeSlotDeactivated;

  /// No description provided for @timeSlotSaved.
  ///
  /// In en, this message translates to:
  /// **'Period saved'**
  String get timeSlotSaved;

  /// No description provided for @timeSlotName.
  ///
  /// In en, this message translates to:
  /// **'Period {number}'**
  String timeSlotName(int number);

  /// No description provided for @timeSlotTimes.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String timeSlotTimes(String start, String end);

  /// No description provided for @timeSlotBreakChip.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get timeSlotBreakChip;

  /// No description provided for @timeSlotNumber.
  ///
  /// In en, this message translates to:
  /// **'Period number'**
  String get timeSlotNumber;

  /// No description provided for @timeSlotNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'1 to 30'**
  String get timeSlotNumberHelper;

  /// No description provided for @timeSlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get timeSlotLabel;

  /// No description provided for @timeSlotLabelHelper.
  ///
  /// In en, this message translates to:
  /// **'For example Lunch'**
  String get timeSlotLabelHelper;

  /// No description provided for @timeSlotStart.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get timeSlotStart;

  /// No description provided for @timeSlotEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends at'**
  String get timeSlotEnd;

  /// No description provided for @timeSlotBreak.
  ///
  /// In en, this message translates to:
  /// **'This is a break'**
  String get timeSlotBreak;

  /// No description provided for @timeSlotBreakHelper.
  ///
  /// In en, this message translates to:
  /// **'No lesson is given in a break. It cannot be changed once the period is added.'**
  String get timeSlotBreakHelper;

  /// No description provided for @timeSlotSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get timeSlotSave;

  /// No description provided for @errorTimeSlotDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Another period of this year has this number.'**
  String get errorTimeSlotDuplicate;

  /// No description provided for @errorTimeSlotOverlap.
  ///
  /// In en, this message translates to:
  /// **'These times overlap another period of this year. A period may end when the next begins.'**
  String get errorTimeSlotOverlap;

  /// No description provided for @errorTimeSlotInUse.
  ///
  /// In en, this message translates to:
  /// **'A timetable entry sits in this period. Remove it from the timetable first.'**
  String get errorTimeSlotInUse;

  /// No description provided for @errorTimeSlotNotFound.
  ///
  /// In en, this message translates to:
  /// **'This period could not be found. It may have been deactivated.'**
  String get errorTimeSlotNotFound;

  /// No description provided for @timetableTitle.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get timetableTitle;

  /// No description provided for @timetableEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No timetable yet'**
  String get timetableEmptyTitle;

  /// No description provided for @timetableEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No lessons have been added to the week yet.'**
  String get timetableEmptyMessage;

  /// No description provided for @timetableDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No periods} =1{1 period} other{{count} periods}}'**
  String timetableDayCount(int count);

  /// No description provided for @timetableDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is planned for this day.'**
  String get timetableDayEmpty;

  /// No description provided for @timetableBreak.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get timetableBreak;

  /// No description provided for @errorTimetableNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'You can see the timetable of a section you lead or teach.'**
  String get errorTimetableNotAssigned;

  /// No description provided for @errorTimetableNotFound.
  ///
  /// In en, this message translates to:
  /// **'This timetable could not be found.'**
  String get errorTimetableNotFound;

  /// No description provided for @errorTimetableNoYear.
  ///
  /// In en, this message translates to:
  /// **'No current academic year has been set up yet, so there is no timetable to show.'**
  String get errorTimetableNoYear;

  /// No description provided for @timetableEntryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get timetableEntryAdd;

  /// No description provided for @timetableEntryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get timetableEntryAddTitle;

  /// No description provided for @timetableEntryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get timetableEntryEditTitle;

  /// No description provided for @timetableEntryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get timetableEntryEdit;

  /// No description provided for @timetableEntryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get timetableEntryDelete;

  /// No description provided for @timetableEntryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get timetableEntryDeleteTitle;

  /// No description provided for @timetableEntryDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'It leaves the timetable, and its period is free again for the section and the teacher.'**
  String get timetableEntryDeleteMessage;

  /// No description provided for @timetableEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get timetableEntryDeleted;

  /// No description provided for @timetableEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved'**
  String get timetableEntrySaved;

  /// No description provided for @timetableEntrySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get timetableEntrySave;

  /// No description provided for @timetableEntryDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get timetableEntryDay;

  /// No description provided for @timetableEntryPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get timetableEntryPeriod;

  /// No description provided for @timetableEntryBreak.
  ///
  /// In en, this message translates to:
  /// **'This is a break'**
  String get timetableEntryBreak;

  /// No description provided for @timetableEntryBreakHelper.
  ///
  /// In en, this message translates to:
  /// **'A break has no subject or teacher.'**
  String get timetableEntryBreakHelper;

  /// No description provided for @timetableEntrySubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get timetableEntrySubject;

  /// No description provided for @timetableEntryTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get timetableEntryTeacher;

  /// No description provided for @timetableEntryNoPeriodsTitle.
  ///
  /// In en, this message translates to:
  /// **'No periods yet'**
  String get timetableEntryNoPeriodsTitle;

  /// No description provided for @timetableEntryNoPeriodsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the periods of the school day under Period timings first.'**
  String get timetableEntryNoPeriodsMessage;

  /// No description provided for @errorTimetableSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'This section already has an entry in that period on that day.'**
  String get errorTimetableSlotTaken;

  /// No description provided for @errorTimetableTeacherBusy.
  ///
  /// In en, this message translates to:
  /// **'That teacher already has a lesson in that period on that day.'**
  String get errorTimetableTeacherBusy;

  /// No description provided for @errorTimetableTeacherBusyIn.
  ///
  /// In en, this message translates to:
  /// **'That teacher is already teaching {section} in that period on that day.'**
  String errorTimetableTeacherBusyIn(String section);

  /// No description provided for @errorTimetableInvalidSlot.
  ///
  /// In en, this message translates to:
  /// **'That period cannot take this entry. A break period takes only a break.'**
  String get errorTimetableInvalidSlot;

  /// No description provided for @errorTimetableSubjectNotTaught.
  ///
  /// In en, this message translates to:
  /// **'That teacher does not teach this subject. Add it to their subjects first.'**
  String get errorTimetableSubjectNotTaught;

  /// No description provided for @errorTimetableTeacherElsewhere.
  ///
  /// In en, this message translates to:
  /// **'That teacher is based at another Institution.'**
  String get errorTimetableTeacherElsewhere;

  /// No description provided for @errorTimetableTeacherBlocked.
  ///
  /// In en, this message translates to:
  /// **'That teacher\'s access is blocked.'**
  String get errorTimetableTeacherBlocked;

  /// No description provided for @errorCurrentYearRequired.
  ///
  /// In en, this message translates to:
  /// **'This Institution has no current academic year. Make one current under Academic years first.'**
  String get errorCurrentYearRequired;

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

  /// No description provided for @staffOwnTitle.
  ///
  /// In en, this message translates to:
  /// **'My details'**
  String get staffOwnTitle;

  /// No description provided for @staffOwnDetail.
  ///
  /// In en, this message translates to:
  /// **'Your staff record and documents'**
  String get staffOwnDetail;

  /// No description provided for @personFormContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get personFormContact;

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

  /// No description provided for @personGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get personGender;

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

  /// No description provided for @personDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get personDateOfBirth;

  /// No description provided for @personBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get personBloodGroup;

  /// No description provided for @personNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get personNationality;

  /// No description provided for @personMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get personMobile;

  /// No description provided for @personAlternateNumber.
  ///
  /// In en, this message translates to:
  /// **'Alternate number'**
  String get personAlternateNumber;

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

  /// No description provided for @staffAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get staffAddTitle;

  /// No description provided for @staffEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit staff'**
  String get staffEditTitle;

  /// No description provided for @formSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get formSave;

  /// No description provided for @staffSaved.
  ///
  /// In en, this message translates to:
  /// **'Staff saved'**
  String get staffSaved;

  /// No description provided for @personFormPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get personFormPhoto;

  /// No description provided for @personPhotoKept.
  ///
  /// In en, this message translates to:
  /// **'A photo is saved. Choose another to replace it.'**
  String get personPhotoKept;

  /// No description provided for @staffPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Staff photo'**
  String get staffPhotoLabel;

  /// No description provided for @personFormPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personFormPersonal;

  /// No description provided for @personFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get personFirstName;

  /// No description provided for @personLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get personLastName;

  /// No description provided for @staffEmailAddHelper.
  ///
  /// In en, this message translates to:
  /// **'They sign in with a code sent to this email.'**
  String get staffEmailAddHelper;

  /// No description provided for @staffEmailEditHelper.
  ///
  /// In en, this message translates to:
  /// **'The login email can\'t be changed here.'**
  String get staffEmailEditHelper;

  /// No description provided for @personFormAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get personFormAddress;

  /// No description provided for @staffFormEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get staffFormEducation;

  /// No description provided for @staffFormEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get staffFormEmergency;

  /// No description provided for @choiceNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get choiceNone;

  /// No description provided for @masterEntryKept.
  ///
  /// In en, this message translates to:
  /// **'No longer offered (kept)'**
  String get masterEntryKept;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseDate;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear {label}'**
  String clearDate(String label);

  /// No description provided for @staffEducationRow.
  ///
  /// In en, this message translates to:
  /// **'Education {number}'**
  String staffEducationRow(int number);

  /// No description provided for @staffEducationDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get staffEducationDegree;

  /// No description provided for @staffEducationQualification.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get staffEducationQualification;

  /// No description provided for @staffEducationSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get staffEducationSpecialization;

  /// No description provided for @staffEducationSchool.
  ///
  /// In en, this message translates to:
  /// **'School or college'**
  String get staffEducationSchool;

  /// No description provided for @staffEducationYear.
  ///
  /// In en, this message translates to:
  /// **'Year of passing'**
  String get staffEducationYear;

  /// No description provided for @staffAddEducation.
  ///
  /// In en, this message translates to:
  /// **'Add education'**
  String get staffAddEducation;

  /// No description provided for @staffRemoveEducation.
  ///
  /// In en, this message translates to:
  /// **'Remove education {number}'**
  String staffRemoveEducation(int number);

  /// No description provided for @staffContactRow.
  ///
  /// In en, this message translates to:
  /// **'Contact {number}'**
  String staffContactRow(int number);

  /// No description provided for @staffContactName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get staffContactName;

  /// No description provided for @staffContactRelationLabel.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get staffContactRelationLabel;

  /// No description provided for @staffAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contact'**
  String get staffAddContact;

  /// No description provided for @staffRemoveContact.
  ///
  /// In en, this message translates to:
  /// **'Remove contact {number}'**
  String staffRemoveContact(int number);

  /// No description provided for @personUploadingWait.
  ///
  /// In en, this message translates to:
  /// **'Wait for the photo to finish sending.'**
  String get personUploadingWait;

  /// No description provided for @staffTabPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get staffTabPersonal;

  /// No description provided for @staffTabAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get staffTabAccess;

  /// No description provided for @staffTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get staffTabSettings;

  /// No description provided for @staffAccessSubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects they can teach'**
  String get staffAccessSubjects;

  /// No description provided for @staffAccessSubjectsHelper.
  ///
  /// In en, this message translates to:
  /// **'Only these can be assigned to them in a section.'**
  String get staffAccessSubjectsHelper;

  /// No description provided for @staffAccessSubjectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No subjects yet. Add them under School setup, Subjects.'**
  String get staffAccessSubjectsEmpty;

  /// No description provided for @staffAccessInstitutions.
  ///
  /// In en, this message translates to:
  /// **'Other Institutions'**
  String get staffAccessInstitutions;

  /// No description provided for @staffAccessInstitutionsHelper.
  ///
  /// In en, this message translates to:
  /// **'They can see these Institutions besides their own. They only view there.'**
  String get staffAccessInstitutionsHelper;

  /// No description provided for @staffAccessInstitutionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is no other Institution in this Society.'**
  String get staffAccessInstitutionsEmpty;

  /// No description provided for @staffAccessSaveSubjects.
  ///
  /// In en, this message translates to:
  /// **'Save subjects'**
  String get staffAccessSaveSubjects;

  /// No description provided for @staffAccessSaveInstitutions.
  ///
  /// In en, this message translates to:
  /// **'Save Institutions'**
  String get staffAccessSaveInstitutions;

  /// No description provided for @staffAccessSaved.
  ///
  /// In en, this message translates to:
  /// **'Access saved'**
  String get staffAccessSaved;

  /// No description provided for @staffSettingsAccess.
  ///
  /// In en, this message translates to:
  /// **'Access to the app'**
  String get staffSettingsAccess;

  /// No description provided for @staffSettingsActive.
  ///
  /// In en, this message translates to:
  /// **'They can use the app as staff.'**
  String get staffSettingsActive;

  /// No description provided for @staffSettingsBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'They are blocked. They cannot use the app as staff or Admin of this Society.'**
  String get staffSettingsBlockedMessage;

  /// No description provided for @staffBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Block access'**
  String get staffBlockAction;

  /// No description provided for @staffUnblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock access'**
  String get staffUnblockAction;

  /// No description provided for @staffBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String staffBlockTitle(String name);

  /// No description provided for @staffBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'They are signed out at once and cannot use the app as staff or Admin of this Society until you unblock them. Their record is kept.'**
  String get staffBlockMessage;

  /// No description provided for @staffUnblockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}?'**
  String staffUnblockTitle(String name);

  /// No description provided for @staffUnblockMessage.
  ///
  /// In en, this message translates to:
  /// **'They can use the app as staff again.'**
  String get staffUnblockMessage;

  /// No description provided for @staffBlockDone.
  ///
  /// In en, this message translates to:
  /// **'{name} blocked'**
  String staffBlockDone(String name);

  /// No description provided for @staffUnblockDone.
  ///
  /// In en, this message translates to:
  /// **'{name} unblocked'**
  String staffUnblockDone(String name);

  /// No description provided for @errorStaffAccessState.
  ///
  /// In en, this message translates to:
  /// **'Their access is already as you asked. The screen is up to date now.'**
  String get errorStaffAccessState;

  /// No description provided for @errorStaffBlockForbidden.
  ///
  /// In en, this message translates to:
  /// **'Only the Society Owner can change the access of an Institution Admin.'**
  String get errorStaffBlockForbidden;

  /// No description provided for @errorSubjectAssigned.
  ///
  /// In en, this message translates to:
  /// **'They are assigned to teach one of the subjects you removed. End that assignment first.'**
  String get errorSubjectAssigned;

  /// No description provided for @errorAdminAccessHeld.
  ///
  /// In en, this message translates to:
  /// **'They are an Institution Admin at one of the Institutions you removed. Take that Admin Access away first.'**
  String get errorAdminAccessHeld;

  /// No description provided for @errorEmployeeIdTaken.
  ///
  /// In en, this message translates to:
  /// **'Another staff member of this Institution has this Employee ID.'**
  String get errorEmployeeIdTaken;

  /// No description provided for @errorStaffDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This person already has a staff record in this Society.'**
  String get errorStaffDuplicate;

  /// No description provided for @staffAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin access'**
  String get staffAdminTitle;

  /// No description provided for @staffAdminHelper.
  ///
  /// In en, this message translates to:
  /// **'An Admin runs an Institution: its school setup, staff and students. They are told by email when it is given.'**
  String get staffAdminHelper;

  /// No description provided for @staffAdminEmpty.
  ///
  /// In en, this message translates to:
  /// **'They are not at an Institution that can be given Admin access.'**
  String get staffAdminEmpty;

  /// No description provided for @staffAdminIs.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get staffAdminIs;

  /// No description provided for @staffAdminIsNot.
  ///
  /// In en, this message translates to:
  /// **'Not an Admin here.'**
  String get staffAdminIsNot;

  /// No description provided for @staffAdminGrantAction.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get staffAdminGrantAction;

  /// No description provided for @staffAdminRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'Take away Admin access'**
  String get staffAdminRevokeAction;

  /// No description provided for @staffAdminGrantTitle.
  ///
  /// In en, this message translates to:
  /// **'Make {name} an Admin of {institution}?'**
  String staffAdminGrantTitle(String name, String institution);

  /// No description provided for @staffAdminGrantMessage.
  ///
  /// In en, this message translates to:
  /// **'They can run this Institution. They are told by email.'**
  String get staffAdminGrantMessage;

  /// No description provided for @staffAdminRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Take away Admin access of {name} to {institution}?'**
  String staffAdminRevokeTitle(String name, String institution);

  /// No description provided for @staffAdminRevokeMessage.
  ///
  /// In en, this message translates to:
  /// **'They are signed out as Admin of this Society at once. Their staff access stays.'**
  String get staffAdminRevokeMessage;

  /// No description provided for @staffAdminGranted.
  ///
  /// In en, this message translates to:
  /// **'{name} is now an Admin of {institution}'**
  String staffAdminGranted(String name, String institution);

  /// No description provided for @staffAdminRevoked.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer an Admin of {institution}'**
  String staffAdminRevoked(String name, String institution);

  /// No description provided for @errorAdminAlready.
  ///
  /// In en, this message translates to:
  /// **'They are already an Admin of this Institution. The screen is up to date now.'**
  String get errorAdminAlready;

  /// No description provided for @errorAdminStaffBlocked.
  ///
  /// In en, this message translates to:
  /// **'They are blocked. Unblock them under Settings before giving Admin access.'**
  String get errorAdminStaffBlocked;

  /// No description provided for @errorAdminNotAtInstitution.
  ///
  /// In en, this message translates to:
  /// **'They are not at this Institution. Add it under Other Institutions and save first.'**
  String get errorAdminNotAtInstitution;

  /// No description provided for @errorAdminNotHeld.
  ///
  /// In en, this message translates to:
  /// **'They no longer hold Admin access here. The screen is up to date now.'**
  String get errorAdminNotHeld;

  /// No description provided for @errorAdminAccountState.
  ///
  /// In en, this message translates to:
  /// **'Their account cannot hold this role right now.'**
  String get errorAdminAccountState;

  /// No description provided for @staffClassTeacherTitle.
  ///
  /// In en, this message translates to:
  /// **'Class teacher'**
  String get staffClassTeacherTitle;

  /// No description provided for @staffClassTeacherHelper.
  ///
  /// In en, this message translates to:
  /// **'The section they lead in an academic year. A section has one class teacher, and a teacher leads one section.'**
  String get staffClassTeacherHelper;

  /// No description provided for @staffClassTeacherYear.
  ///
  /// In en, this message translates to:
  /// **'Academic year'**
  String get staffClassTeacherYear;

  /// No description provided for @staffClassTeacherSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get staffClassTeacherSection;

  /// No description provided for @staffClassTeacherNone.
  ///
  /// In en, this message translates to:
  /// **'No section'**
  String get staffClassTeacherNone;

  /// No description provided for @staffClassTeacherNoYears.
  ///
  /// In en, this message translates to:
  /// **'Add an academic year under School setup first.'**
  String get staffClassTeacherNoYears;

  /// No description provided for @staffClassTeacherSave.
  ///
  /// In en, this message translates to:
  /// **'Save class teacher'**
  String get staffClassTeacherSave;

  /// No description provided for @staffClassTeacherSaved.
  ///
  /// In en, this message translates to:
  /// **'Class teacher saved'**
  String get staffClassTeacherSaved;

  /// No description provided for @errorClassTeacherTaken.
  ///
  /// In en, this message translates to:
  /// **'Another teacher is already the class teacher of this section for this year.'**
  String get errorClassTeacherTaken;

  /// No description provided for @errorClassTeacherNotFound.
  ///
  /// In en, this message translates to:
  /// **'The staff member, the year or the section could not be found. It may have been deactivated.'**
  String get errorClassTeacherNotFound;

  /// No description provided for @errorStaffBlocked.
  ///
  /// In en, this message translates to:
  /// **'They are blocked. Unblock them under Settings first.'**
  String get errorStaffBlocked;

  /// No description provided for @staffTeachingTitle.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get staffTeachingTitle;

  /// No description provided for @staffTeachingHelper.
  ///
  /// In en, this message translates to:
  /// **'The subjects they teach in each section of an academic year. Only a subject on their list above can be given to them.'**
  String get staffTeachingHelper;

  /// No description provided for @staffTeachingYear.
  ///
  /// In en, this message translates to:
  /// **'Academic year'**
  String get staffTeachingYear;

  /// No description provided for @staffTeachingNoYears.
  ///
  /// In en, this message translates to:
  /// **'Add an academic year under School setup first.'**
  String get staffTeachingNoYears;

  /// No description provided for @staffTeachingNone.
  ///
  /// In en, this message translates to:
  /// **'They do not teach in any section this year.'**
  String get staffTeachingNone;

  /// No description provided for @staffTeachingNoSubjects.
  ///
  /// In en, this message translates to:
  /// **'Add subjects to their list above and save, then give them a section.'**
  String get staffTeachingNoSubjects;

  /// No description provided for @staffTeachingNoSections.
  ///
  /// In en, this message translates to:
  /// **'Add a class with a section under School setup first.'**
  String get staffTeachingNoSections;

  /// No description provided for @staffTeachingChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get staffTeachingChoose;

  /// No description provided for @staffTeachingSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get staffTeachingSection;

  /// No description provided for @staffTeachingSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get staffTeachingSubject;

  /// No description provided for @staffTeachingAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get staffTeachingAssign;

  /// No description provided for @staffTeachingEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get staffTeachingEnd;

  /// No description provided for @staffTeachingEndTitle.
  ///
  /// In en, this message translates to:
  /// **'End {subject} in {section}?'**
  String staffTeachingEndTitle(String subject, String section);

  /// No description provided for @staffTeachingEndMessage.
  ///
  /// In en, this message translates to:
  /// **'They stop teaching it. The record stays as history.'**
  String get staffTeachingEndMessage;

  /// No description provided for @staffTeachingEndAction.
  ///
  /// In en, this message translates to:
  /// **'End assignment'**
  String get staffTeachingEndAction;

  /// No description provided for @staffTeachingAssigned.
  ///
  /// In en, this message translates to:
  /// **'{subject} in {section} assigned'**
  String staffTeachingAssigned(String subject, String section);

  /// No description provided for @staffTeachingEnded.
  ///
  /// In en, this message translates to:
  /// **'{subject} in {section} ended'**
  String staffTeachingEnded(String subject, String section);

  /// No description provided for @errorTeachingDuplicate.
  ///
  /// In en, this message translates to:
  /// **'They already teach this subject in this section this year.'**
  String get errorTeachingDuplicate;

  /// No description provided for @errorSubjectNotTaught.
  ///
  /// In en, this message translates to:
  /// **'This subject is not on their list. Add it to their subjects and save first.'**
  String get errorSubjectNotTaught;

  /// No description provided for @errorTeachingNotFound.
  ///
  /// In en, this message translates to:
  /// **'The assignment, the section or the subject could not be found. It may have been ended or deactivated.'**
  String get errorTeachingNotFound;

  /// No description provided for @identityTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identityTitle;

  /// No description provided for @aadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number'**
  String get aadhaar;

  /// No description provided for @aadhaarNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get aadhaarNotSet;

  /// No description provided for @aadhaarShow.
  ///
  /// In en, this message translates to:
  /// **'Show full number'**
  String get aadhaarShow;

  /// No description provided for @aadhaarSet.
  ///
  /// In en, this message translates to:
  /// **'Set number'**
  String get aadhaarSet;

  /// No description provided for @aadhaarChange.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get aadhaarChange;

  /// No description provided for @aadhaarClear.
  ///
  /// In en, this message translates to:
  /// **'Clear number'**
  String get aadhaarClear;

  /// No description provided for @aadhaarSetHelper.
  ///
  /// In en, this message translates to:
  /// **'Twelve digits, the first one from 2 to 9. It is kept sealed and shown masked.'**
  String get aadhaarSetHelper;

  /// No description provided for @aadhaarInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the twelve digits.'**
  String get aadhaarInvalid;

  /// No description provided for @aadhaarSave.
  ///
  /// In en, this message translates to:
  /// **'Save number'**
  String get aadhaarSave;

  /// No description provided for @aadhaarSaved.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number saved'**
  String get aadhaarSaved;

  /// No description provided for @aadhaarSavedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number saved. Another Institution of the Society holds this number too.'**
  String get aadhaarSavedElsewhere;

  /// No description provided for @aadhaarCleared.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number cleared'**
  String get aadhaarCleared;

  /// No description provided for @aadhaarClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the Aadhaar number of {name}?'**
  String aadhaarClearTitle(String name);

  /// No description provided for @aadhaarClearMessage.
  ///
  /// In en, this message translates to:
  /// **'The number is removed. You can set it again later.'**
  String get aadhaarClearMessage;

  /// No description provided for @aadhaarRevealTitle.
  ///
  /// In en, this message translates to:
  /// **'Show Aadhaar number'**
  String get aadhaarRevealTitle;

  /// No description provided for @aadhaarReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (at least 10 characters)'**
  String get aadhaarReason;

  /// No description provided for @aadhaarReasonHelper.
  ///
  /// In en, this message translates to:
  /// **'It is kept in the audit log with your name.'**
  String get aadhaarReasonHelper;

  /// No description provided for @aadhaarReasonShort.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters.'**
  String get aadhaarReasonShort;

  /// No description provided for @aadhaarRevealAction.
  ///
  /// In en, this message translates to:
  /// **'Show number'**
  String get aadhaarRevealAction;

  /// No description provided for @aadhaarRevealed.
  ///
  /// In en, this message translates to:
  /// **'This is hidden again when you close it.'**
  String get aadhaarRevealed;

  /// No description provided for @aadhaarDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get aadhaarDone;

  /// No description provided for @errorAadhaarInvalid.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid Aadhaar number. Check the twelve digits.'**
  String get errorAadhaarInvalid;

  /// No description provided for @errorAadhaarExists.
  ///
  /// In en, this message translates to:
  /// **'This Aadhaar number is already recorded for someone in this Society.'**
  String get errorAadhaarExists;

  /// No description provided for @errorAadhaarNotSet.
  ///
  /// In en, this message translates to:
  /// **'No Aadhaar number is set for them.'**
  String get errorAadhaarNotSet;

  /// No description provided for @errorRevealLimit.
  ///
  /// In en, this message translates to:
  /// **'You have reached today\'s limit of ten reveals. Try again tomorrow.'**
  String get errorRevealLimit;

  /// No description provided for @errorRoleConflict.
  ///
  /// In en, this message translates to:
  /// **'This email belongs to a platform account, which can\'t also be staff.'**
  String get errorRoleConflict;

  /// No description provided for @filesChooseDocument.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get filesChooseDocument;

  /// No description provided for @filesChangeDocument.
  ///
  /// In en, this message translates to:
  /// **'Change file'**
  String get filesChangeDocument;

  /// No description provided for @filesRemoveDocument.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get filesRemoveDocument;

  /// No description provided for @filesUploadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Uploading file'**
  String get filesUploadingDocument;

  /// No description provided for @filesDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'PDF, JPG, PNG or WebP, up to 5 MB.'**
  String get filesDocumentHint;

  /// No description provided for @filesCsvHint.
  ///
  /// In en, this message translates to:
  /// **'A CSV file, up to 5 MB.'**
  String get filesCsvHint;

  /// No description provided for @staffTabDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get staffTabDocuments;

  /// No description provided for @staffDocumentsHelper.
  ///
  /// In en, this message translates to:
  /// **'Appointment letters, certificates and other files kept with this record.'**
  String get staffDocumentsHelper;

  /// No description provided for @staffDocumentsNone.
  ///
  /// In en, this message translates to:
  /// **'No documents yet.'**
  String get staffDocumentsNone;

  /// No description provided for @staffDocumentAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a document'**
  String get staffDocumentAddTitle;

  /// No description provided for @staffDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get staffDocumentTitle;

  /// No description provided for @staffDocumentAttach.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get staffDocumentAttach;

  /// No description provided for @staffDocumentAdded.
  ///
  /// In en, this message translates to:
  /// **'{title} added'**
  String staffDocumentAdded(String title);

  /// No description provided for @filesNameAndSize.
  ///
  /// In en, this message translates to:
  /// **'{name} · {size}'**
  String filesNameAndSize(String name, String size);

  /// No description provided for @staffDocumentOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String staffDocumentOn(String date);

  /// No description provided for @staffDocumentOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get staffDocumentOpen;

  /// No description provided for @staffDocumentRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get staffDocumentRemove;

  /// No description provided for @staffDocumentRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {title}?'**
  String staffDocumentRemoveTitle(String title);

  /// No description provided for @staffDocumentRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'It leaves this record now. The file itself is deleted after 30 days.'**
  String get staffDocumentRemoveMessage;

  /// No description provided for @staffDocumentRemoved.
  ///
  /// In en, this message translates to:
  /// **'{title} removed'**
  String staffDocumentRemoved(String title);

  /// No description provided for @errorDocumentDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This file is attached already.'**
  String get errorDocumentDuplicate;

  /// No description provided for @errorDocumentInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be attached. Remove it and choose it again.'**
  String get errorDocumentInvalid;

  /// No description provided for @errorDocumentNotFound.
  ///
  /// In en, this message translates to:
  /// **'The document, the file or the staff member could not be found. It may have been removed.'**
  String get errorDocumentNotFound;

  /// No description provided for @errorDocumentOpen.
  ///
  /// In en, this message translates to:
  /// **'This phone could not open the file.'**
  String get errorDocumentOpen;

  /// No description provided for @classroomTitle.
  ///
  /// In en, this message translates to:
  /// **'My students'**
  String get classroomTitle;

  /// No description provided for @classroomDetail.
  ///
  /// In en, this message translates to:
  /// **'The students of the sections you lead or teach'**
  String get classroomDetail;

  /// No description provided for @classroomSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or roll'**
  String get classroomSearchHint;

  /// No description provided for @classroomEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No students in your sections yet'**
  String get classroomEmptyTitle;

  /// No description provided for @classroomEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Students of the sections you lead or teach this year appear here.'**
  String get classroomEmptyMessage;

  /// No description provided for @classroomNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or search by roll number.'**
  String get classroomNoMatchMessage;

  /// No description provided for @studentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentsTitle;

  /// No description provided for @studentsDetail.
  ///
  /// In en, this message translates to:
  /// **'The students of each Institution'**
  String get studentsDetail;

  /// No description provided for @studentsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or ID'**
  String get studentsSearchHint;

  /// No description provided for @studentsSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get studentsSearchClear;

  /// No description provided for @studentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No students yet'**
  String get studentsEmptyTitle;

  /// No description provided for @studentsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Students added to this Institution appear here.'**
  String get studentsEmptyMessage;

  /// No description provided for @studentsNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No students match \"{query}\"'**
  String studentsNoMatchTitle(String query);

  /// No description provided for @studentsNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or search by Admission ID or roll number.'**
  String get studentsNoMatchMessage;

  /// No description provided for @studentsNoFilterMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No students in this selection'**
  String get studentsNoFilterMatchTitle;

  /// No description provided for @studentsNoFilterMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another year, class or section, or clear the filters.'**
  String get studentsNoFilterMatchMessage;

  /// No description provided for @studentsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get studentsLoadMore;

  /// No description provided for @studentsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get studentsBlocked;

  /// No description provided for @studentsRoll.
  ///
  /// In en, this message translates to:
  /// **'Roll {roll}'**
  String studentsRoll(String roll);

  /// No description provided for @studentsAdmissionId.
  ///
  /// In en, this message translates to:
  /// **'ID {id}'**
  String studentsAdmissionId(String id);

  /// No description provided for @studentsFilterYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get studentsFilterYear;

  /// No description provided for @studentsFilterClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get studentsFilterClass;

  /// No description provided for @studentsFilterSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get studentsFilterSection;

  /// No description provided for @studentsFilterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get studentsFilterAny;

  /// No description provided for @studentsFiltersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get studentsFiltersClear;

  /// No description provided for @studentsFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Opens choices'**
  String get studentsFilterHint;

  /// No description provided for @studentsDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get studentsDeactivate;

  /// No description provided for @studentsDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String studentsDeactivateTitle(String name);

  /// No description provided for @studentsDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'Their guardians lose access to this child, and their class placement ends today. Nothing is deleted. Why are you deactivating?'**
  String get studentsDeactivateMessage;

  /// No description provided for @studentsReasonLeft.
  ///
  /// In en, this message translates to:
  /// **'Left the Institution'**
  String get studentsReasonLeft;

  /// No description provided for @studentsReasonMistake.
  ///
  /// In en, this message translates to:
  /// **'Added by mistake'**
  String get studentsReasonMistake;

  /// No description provided for @studentsReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Another reason'**
  String get studentsReasonOther;

  /// No description provided for @studentsDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated'**
  String studentsDeactivated(String name);

  /// No description provided for @errorStudentNotFound.
  ///
  /// In en, this message translates to:
  /// **'This student could not be found. They may have been deactivated.'**
  String get errorStudentNotFound;

  /// No description provided for @errorStudentProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'This student could not be found.'**
  String get errorStudentProfileNotFound;

  /// No description provided for @studentsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add student'**
  String get studentsAddTitle;

  /// No description provided for @studentPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Student photo'**
  String get studentPhotoLabel;

  /// No description provided for @studentFormAdmission.
  ///
  /// In en, this message translates to:
  /// **'Admission'**
  String get studentFormAdmission;

  /// No description provided for @studentAdmissionNo.
  ///
  /// In en, this message translates to:
  /// **'Admission ID'**
  String get studentAdmissionNo;

  /// No description provided for @studentAdmissionDate.
  ///
  /// In en, this message translates to:
  /// **'Admission date'**
  String get studentAdmissionDate;

  /// No description provided for @studentAdmissionDateHelper.
  ///
  /// In en, this message translates to:
  /// **'The day the class placement starts. Today when left empty.'**
  String get studentAdmissionDateHelper;

  /// No description provided for @studentContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Student\'s email'**
  String get studentContactEmail;

  /// No description provided for @studentContactEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Not a login. Guardians sign in with their own email.'**
  String get studentContactEmailHelper;

  /// No description provided for @studentFormPlacement.
  ///
  /// In en, this message translates to:
  /// **'Class and section'**
  String get studentFormPlacement;

  /// No description provided for @studentYear.
  ///
  /// In en, this message translates to:
  /// **'Academic year'**
  String get studentYear;

  /// No description provided for @studentClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get studentClass;

  /// No description provided for @studentSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get studentSection;

  /// No description provided for @studentRollNumber.
  ///
  /// In en, this message translates to:
  /// **'Roll number'**
  String get studentRollNumber;

  /// No description provided for @studentFormGuardians.
  ///
  /// In en, this message translates to:
  /// **'Parents and guardians'**
  String get studentFormGuardians;

  /// No description provided for @studentFormGuardiansHelper.
  ///
  /// In en, this message translates to:
  /// **'Add one to five. Exactly one is the primary guardian.'**
  String get studentFormGuardiansHelper;

  /// No description provided for @studentGuardianRow.
  ///
  /// In en, this message translates to:
  /// **'Guardian {number}'**
  String studentGuardianRow(int number);

  /// No description provided for @studentRemoveGuardian.
  ///
  /// In en, this message translates to:
  /// **'Remove guardian {number}'**
  String studentRemoveGuardian(int number);

  /// No description provided for @studentGuardianRelation.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get studentGuardianRelation;

  /// No description provided for @relationFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get relationFather;

  /// No description provided for @relationMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get relationMother;

  /// No description provided for @relationGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get relationGuardian;

  /// No description provided for @relationGrandparent.
  ///
  /// In en, this message translates to:
  /// **'Grandparent'**
  String get relationGrandparent;

  /// No description provided for @relationSibling.
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get relationSibling;

  /// No description provided for @relationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationOther;

  /// No description provided for @studentGuardianEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get studentGuardianEmail;

  /// No description provided for @studentGuardianEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Their login. A parent who already has an account is linked by this email.'**
  String get studentGuardianEmailHelper;

  /// No description provided for @studentGuardianOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get studentGuardianOccupation;

  /// No description provided for @studentGuardianPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary guardian'**
  String get studentGuardianPrimary;

  /// No description provided for @studentGuardianEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get studentGuardianEmergency;

  /// No description provided for @studentAddGuardian.
  ///
  /// In en, this message translates to:
  /// **'Add guardian'**
  String get studentAddGuardian;

  /// No description provided for @studentFormIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get studentFormIdentity;

  /// No description provided for @studentAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number'**
  String get studentAadhaar;

  /// No description provided for @studentAadhaarHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Twelve digits, kept encrypted.'**
  String get studentAadhaarHelper;

  /// No description provided for @studentBirthCertificate.
  ///
  /// In en, this message translates to:
  /// **'Birth certificate number'**
  String get studentBirthCertificate;

  /// No description provided for @studentCertificateSet.
  ///
  /// In en, this message translates to:
  /// **'Set number'**
  String get studentCertificateSet;

  /// No description provided for @studentCertificateChange.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get studentCertificateChange;

  /// No description provided for @studentCertificateClear.
  ///
  /// In en, this message translates to:
  /// **'Clear number'**
  String get studentCertificateClear;

  /// No description provided for @studentCertificateRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the number as it is written on the certificate.'**
  String get studentCertificateRequired;

  /// No description provided for @studentCertificateSaved.
  ///
  /// In en, this message translates to:
  /// **'Birth certificate number saved'**
  String get studentCertificateSaved;

  /// No description provided for @studentCertificateCleared.
  ///
  /// In en, this message translates to:
  /// **'Birth certificate number cleared'**
  String get studentCertificateCleared;

  /// No description provided for @studentCertificateClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the birth certificate number of {name}?'**
  String studentCertificateClearTitle(String name);

  /// No description provided for @studentCertificateClearMessage.
  ///
  /// In en, this message translates to:
  /// **'The number is removed. You can set it again later.'**
  String get studentCertificateClearMessage;

  /// No description provided for @studentAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent access'**
  String get studentAccessTitle;

  /// No description provided for @studentAccessActive.
  ///
  /// In en, this message translates to:
  /// **'Parents and guardians can see this child.'**
  String get studentAccessActive;

  /// No description provided for @studentAccessBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Parent access is blocked. Parents and guardians cannot see this child. Their other children are not affected.'**
  String get studentAccessBlockedMessage;

  /// No description provided for @studentBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Block parent access'**
  String get studentBlockAction;

  /// No description provided for @studentUnblockAction.
  ///
  /// In en, this message translates to:
  /// **'Restore parent access'**
  String get studentUnblockAction;

  /// No description provided for @studentBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block parent access to {name}?'**
  String studentBlockTitle(String name);

  /// No description provided for @studentBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'Parents and guardians will not see this child until you restore access. Their other children and their accounts are not affected.'**
  String get studentBlockMessage;

  /// No description provided for @studentUnblockTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore parent access to {name}?'**
  String studentUnblockTitle(String name);

  /// No description provided for @studentUnblockMessage.
  ///
  /// In en, this message translates to:
  /// **'Parents and guardians will see this child again.'**
  String get studentUnblockMessage;

  /// No description provided for @studentBlockDone.
  ///
  /// In en, this message translates to:
  /// **'Parent access to {name} blocked'**
  String studentBlockDone(String name);

  /// No description provided for @studentUnblockDone.
  ///
  /// In en, this message translates to:
  /// **'Parent access to {name} restored'**
  String studentUnblockDone(String name);

  /// No description provided for @errorStudentAccessState.
  ///
  /// In en, this message translates to:
  /// **'Someone else already changed this child\'s parent access. The screen now shows how it is.'**
  String get errorStudentAccessState;

  /// No description provided for @studentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit student'**
  String get studentEditTitle;

  /// No description provided for @studentSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved'**
  String studentSaved(String name);

  /// No description provided for @studentAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String studentAdded(String name);

  /// No description provided for @studentWarnOverCapacity.
  ///
  /// In en, this message translates to:
  /// **'The section is now over its capacity.'**
  String get studentWarnOverCapacity;

  /// No description provided for @studentWarnAadhaarElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Another Institution of the Society holds this Aadhaar number.'**
  String get studentWarnAadhaarElsewhere;

  /// No description provided for @studentFormNoPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up a class first'**
  String get studentFormNoPlacesTitle;

  /// No description provided for @studentFormNoPlacesMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an academic year, a class and a section before adding students.'**
  String get studentFormNoPlacesMessage;

  /// No description provided for @errorStudentFormNotFound.
  ///
  /// In en, this message translates to:
  /// **'The Institution, year, class, section or photo could not be found. It may have been deactivated.'**
  String get errorStudentFormNotFound;

  /// No description provided for @errorAdmissionNoTaken.
  ///
  /// In en, this message translates to:
  /// **'Another student of this Institution has this Admission ID.'**
  String get errorAdmissionNoTaken;

  /// No description provided for @errorRollNumberTaken.
  ///
  /// In en, this message translates to:
  /// **'Another student in this section has this roll number.'**
  String get errorRollNumberTaken;

  /// No description provided for @errorAadhaarDuplicateInInstitution.
  ///
  /// In en, this message translates to:
  /// **'A student of this Institution already has this Aadhaar number.'**
  String get errorAadhaarDuplicateInInstitution;

  /// No description provided for @errorTargetClassBelowSource.
  ///
  /// In en, this message translates to:
  /// **'The student cannot be put in a class below the one they came from.'**
  String get errorTargetClassBelowSource;

  /// No description provided for @errorClassUnchanged.
  ///
  /// In en, this message translates to:
  /// **'The student is in this class already. Change the section instead.'**
  String get errorClassUnchanged;

  /// No description provided for @errorNoCurrentPlacement.
  ///
  /// In en, this message translates to:
  /// **'The student is not in a class this year.'**
  String get errorNoCurrentPlacement;

  /// No description provided for @errorSectionNotInClass.
  ///
  /// In en, this message translates to:
  /// **'This section is not in the class chosen.'**
  String get errorSectionNotInClass;

  /// No description provided for @errorStudentYearNotActive.
  ///
  /// In en, this message translates to:
  /// **'This academic year is not active.'**
  String get errorStudentYearNotActive;

  /// No description provided for @errorInactiveSection.
  ///
  /// In en, this message translates to:
  /// **'This section is deactivated.'**
  String get errorInactiveSection;

  /// No description provided for @errorPrimaryGuardianRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose exactly one primary guardian.'**
  String get errorPrimaryGuardianRequired;

  /// No description provided for @errorGuardianRoleConflict.
  ///
  /// In en, this message translates to:
  /// **'A guardian\'s email belongs to a platform account, which can\'t also be a parent.'**
  String get errorGuardianRoleConflict;

  /// No description provided for @studentMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Change class or section'**
  String get studentMoveTitle;

  /// No description provided for @studentMoveSince.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String studentMoveSince(String date);

  /// No description provided for @studentMoveFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get studentMoveFrom;

  /// No description provided for @studentMoveCorrectHelper.
  ///
  /// In en, this message translates to:
  /// **'The class is corrected for the whole year, as if the student had been in it from the start. To change only from a day, keep the class and choose another section.'**
  String get studentMoveCorrectHelper;

  /// No description provided for @studentMoveFromHelper.
  ///
  /// In en, this message translates to:
  /// **'The first day in the new section or with the new roll number. Today when left empty, or the first day of the placement when that comes later.'**
  String get studentMoveFromHelper;

  /// No description provided for @studentMoved.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s placement was changed.'**
  String studentMoved(String name);

  /// No description provided for @studentProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentProfileTitle;

  /// No description provided for @studentProfileDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get studentProfileDeactivated;

  /// No description provided for @studentProfileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get studentProfileNotSet;

  /// No description provided for @studentProfileNoContact.
  ///
  /// In en, this message translates to:
  /// **'No contact details are recorded for the student. Their guardians\' are below.'**
  String get studentProfileNoContact;

  /// No description provided for @studentsMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get studentsMove;

  /// No description provided for @studentsPromote.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get studentsPromote;

  /// No description provided for @studentsPromoteClass.
  ///
  /// In en, this message translates to:
  /// **'Promote a class'**
  String get studentsPromoteClass;

  /// No description provided for @promotionTitleOne.
  ///
  /// In en, this message translates to:
  /// **'Promote student'**
  String get promotionTitleOne;

  /// No description provided for @promotionTitleGroup.
  ///
  /// In en, this message translates to:
  /// **'Promote a class'**
  String get promotionTitleGroup;

  /// No description provided for @promotionFrom.
  ///
  /// In en, this message translates to:
  /// **'Promote from'**
  String get promotionFrom;

  /// No description provided for @promotionTo.
  ///
  /// In en, this message translates to:
  /// **'Promote to'**
  String get promotionTo;

  /// No description provided for @promotionAllSections.
  ///
  /// In en, this message translates to:
  /// **'Every section'**
  String get promotionAllSections;

  /// No description provided for @promotionCompletes.
  ///
  /// In en, this message translates to:
  /// **'Completes the final class'**
  String get promotionCompletes;

  /// No description provided for @promotionCompletesHelper.
  ///
  /// In en, this message translates to:
  /// **'They leave the school. Each is deactivated as completed, and their guardians lose the child. Only for the last class of the Institution.'**
  String get promotionCompletesHelper;

  /// No description provided for @promotionKeepRollNumbers.
  ///
  /// In en, this message translates to:
  /// **'Keep roll numbers'**
  String get promotionKeepRollNumbers;

  /// No description provided for @promotionKeepRollNumbersHelper.
  ///
  /// In en, this message translates to:
  /// **'When off, the students are numbered again in the new section, after the highest number there.'**
  String get promotionKeepRollNumbersHelper;

  /// No description provided for @promotionRollNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave it as it is to keep the roll number.'**
  String get promotionRollNumberHelper;

  /// No description provided for @promotionAction.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get promotionAction;

  /// No description provided for @promotionDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get promotionDoneAction;

  /// No description provided for @promotionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote to {target}?'**
  String promotionConfirmTitle(String target);

  /// No description provided for @promotionConfirmGroup.
  ///
  /// In en, this message translates to:
  /// **'Every active student of the class or section chosen is promoted together, all or none. A student who already has a place in the new year is left where they are.'**
  String get promotionConfirmGroup;

  /// No description provided for @promotionConfirmCompletesTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete the final class?'**
  String get promotionConfirmCompletesTitle;

  /// No description provided for @promotionConfirmCompletes.
  ///
  /// In en, this message translates to:
  /// **'Each student leaves the school: they are deactivated as completed, and their guardians lose the child. Their records stay readable.'**
  String get promotionConfirmCompletes;

  /// No description provided for @promotionDoneOne.
  ///
  /// In en, this message translates to:
  /// **'{name} promoted to {target}'**
  String promotionDoneOne(String name, String target);

  /// No description provided for @promotionDoneOneCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} completed the final class'**
  String promotionDoneOneCompleted(String name);

  /// No description provided for @promotionDoneGroup.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No student was promoted} =1{1 student promoted to {target}} other{{count} students promoted to {target}}}'**
  String promotionDoneGroup(int count, String target);

  /// No description provided for @promotionDoneCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No student completed the final class} =1{1 student completed the final class} other{{count} students completed the final class}}'**
  String promotionDoneCompleted(int count);

  /// No description provided for @promotionSkippedNotInSource.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student is not an active student of this class or section, and was left.} other{{count} students are not active students of this class or section, and were left.}}'**
  String promotionSkippedNotInSource(int count);

  /// No description provided for @promotionSkippedAlreadyEnrolled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student already has a place in the new year, and was left where they are.} other{{count} students already have a place in the new year, and were left where they are.}}'**
  String promotionSkippedAlreadyEnrolled(int count);

  /// No description provided for @errorPromotionYearNotAfter.
  ///
  /// In en, this message translates to:
  /// **'The new year must begin after the year the students are in now.'**
  String get errorPromotionYearNotAfter;

  /// No description provided for @errorPromotionClassBelow.
  ///
  /// In en, this message translates to:
  /// **'Students cannot go to a class below the one they are in. Choose the same class to repeat it.'**
  String get errorPromotionClassBelow;

  /// No description provided for @errorPromotionNotFinalClass.
  ///
  /// In en, this message translates to:
  /// **'Only the last class of the Institution can be completed.'**
  String get errorPromotionNotFinalClass;

  /// No description provided for @errorPromotionAlreadyEnrolled.
  ///
  /// In en, this message translates to:
  /// **'The student already has a place in the new year.'**
  String get errorPromotionAlreadyEnrolled;

  /// No description provided for @errorPromotionTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That is more than 500 students at once. Promote one section at a time.'**
  String get errorPromotionTooLarge;

  /// No description provided for @errorPromotionNotFound.
  ///
  /// In en, this message translates to:
  /// **'The student, class, year or section could not be found. It may have been deactivated.'**
  String get errorPromotionNotFound;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import students'**
  String get importTitle;

  /// No description provided for @studentsImport.
  ///
  /// In en, this message translates to:
  /// **'Import from a file'**
  String get studentsImport;

  /// No description provided for @importIntro.
  ///
  /// In en, this message translates to:
  /// **'Add many students at once from a CSV file. Each row is one student with one guardian. Rows that cannot be added are skipped, and listed when the import is done.'**
  String get importIntro;

  /// No description provided for @importColumns.
  ///
  /// In en, this message translates to:
  /// **'The first row of the file must be exactly these columns, in this order:'**
  String get importColumns;

  /// No description provided for @importShowSample.
  ///
  /// In en, this message translates to:
  /// **'Show a sample file'**
  String get importShowSample;

  /// No description provided for @importSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample file'**
  String get importSampleTitle;

  /// No description provided for @importYear.
  ///
  /// In en, this message translates to:
  /// **'Add the students to the year'**
  String get importYear;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'The file'**
  String get importFile;

  /// No description provided for @importStart.
  ///
  /// In en, this message translates to:
  /// **'Start import'**
  String get importStart;

  /// No description provided for @importRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing students'**
  String get importRunningTitle;

  /// No description provided for @importWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the import to start.'**
  String get importWaiting;

  /// No description provided for @importReading.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} rows done'**
  String importReading(int done, int total);

  /// No description provided for @importLeave.
  ///
  /// In en, this message translates to:
  /// **'You can leave this screen. The import carries on, and the students appear in the list.'**
  String get importLeave;

  /// No description provided for @importCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get importCheckAgain;

  /// No description provided for @importDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Import finished'**
  String get importDoneTitle;

  /// No description provided for @importDoneSummary.
  ///
  /// In en, this message translates to:
  /// **'{imported, plural, =1{1 student imported} other{{imported} students imported}}, {skipped, plural, =1{1 row skipped} other{{skipped} rows skipped}}'**
  String importDoneSummary(int imported, int skipped);

  /// No description provided for @importOverCapacity.
  ///
  /// In en, this message translates to:
  /// **'Some sections now hold more students than their capacity.'**
  String get importOverCapacity;

  /// No description provided for @importRowErrorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rows that were skipped'**
  String get importRowErrorsTitle;

  /// No description provided for @importRowError.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {message}'**
  String importRowError(int row, String message);

  /// No description provided for @importRowErrorsMore.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {shown} of {total} skipped rows.'**
  String importRowErrorsMore(int shown, int total);

  /// No description provided for @importDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get importDoneAction;

  /// No description provided for @importFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'The import could not run'**
  String get importFailedTitle;

  /// No description provided for @importStoppedTitle.
  ///
  /// In en, this message translates to:
  /// **'The import stopped part-way'**
  String get importStoppedTitle;

  /// No description provided for @importStoppedSummary.
  ///
  /// In en, this message translates to:
  /// **'{imported, plural, =1{1 student was imported} other{{imported} students were imported}} and {skipped, plural, =1{1 row was skipped} other{{skipped} rows were skipped}} before it stopped. Import only the rows of the file that were not added, or you will get the same students skipped again.'**
  String importStoppedSummary(int imported, int skipped);

  /// No description provided for @errorImportHeaderInvalid.
  ///
  /// In en, this message translates to:
  /// **'The first row of the file is not the columns above. Fix it and choose the file again.'**
  String get errorImportHeaderInvalid;

  /// No description provided for @errorImportTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file has more than 5,000 students. Split it into parts and import them one after the other.'**
  String get errorImportTooLarge;

  /// No description provided for @errorImportUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read. Save it as a CSV file in UTF-8 and choose it again.'**
  String get errorImportUnreadable;

  /// No description provided for @errorImportFailed.
  ///
  /// In en, this message translates to:
  /// **'The import stopped because of a problem on our side. Check the students list, then try again.'**
  String get errorImportFailed;

  /// No description provided for @errorImportFileNotReady.
  ///
  /// In en, this message translates to:
  /// **'The file is not ready. Choose it again.'**
  String get errorImportFileNotReady;

  /// No description provided for @errorImportAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'Another import of this school is still running. Try again when it has finished.'**
  String get errorImportAlreadyRunning;

  /// No description provided for @errorImportNotFound.
  ///
  /// In en, this message translates to:
  /// **'The file or the academic year could not be found.'**
  String get errorImportNotFound;

  /// No description provided for @starSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get starSilver;

  /// No description provided for @starGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get starGold;

  /// No description provided for @starPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get starPlatinum;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get achievementsTitle;

  /// No description provided for @achievementsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No stars yet} =1{1 star} other{{count} stars}}'**
  String achievementsTotal(int count);

  /// No description provided for @achievementsGiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Give a star'**
  String get achievementsGiveTitle;

  /// No description provided for @achievementsDescription.
  ///
  /// In en, this message translates to:
  /// **'Why the student earned it'**
  String get achievementsDescription;

  /// No description provided for @achievementsGive.
  ///
  /// In en, this message translates to:
  /// **'Give star'**
  String get achievementsGive;

  /// No description provided for @achievementsRemove.
  ///
  /// In en, this message translates to:
  /// **'Take back'**
  String get achievementsRemove;

  /// No description provided for @achievementsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Take back this star?'**
  String get achievementsRemoveTitle;

  /// No description provided for @achievementsRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'The star leaves the student\'s list and their count.'**
  String get achievementsRemoveMessage;

  /// No description provided for @errorNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'This student is not in one of your sections.'**
  String get errorNotAssigned;

  /// No description provided for @errorAchievementNotFound.
  ///
  /// In en, this message translates to:
  /// **'The student or the star could not be found. The student may have been deactivated.'**
  String get errorAchievementNotFound;

  /// No description provided for @errorImportRunGone.
  ///
  /// In en, this message translates to:
  /// **'This import is no longer available. Imports are kept for 7 days. Check the students list for what was added.'**
  String get errorImportRunGone;

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTitle;

  /// No description provided for @attendanceDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get attendanceDate;

  /// No description provided for @attendanceClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get attendanceClearTooltip;

  /// No description provided for @attendanceNoSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No classes to mark yet'**
  String get attendanceNoSectionsTitle;

  /// No description provided for @attendanceNoSectionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add classes and sections in School setup, and their students appear here to be marked.'**
  String get attendanceNoSectionsMessage;

  /// No description provided for @attendancePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a class and a section'**
  String get attendancePickTitle;

  /// No description provided for @attendancePickMessage.
  ///
  /// In en, this message translates to:
  /// **'The students of the section appear here for you to mark.'**
  String get attendancePickMessage;

  /// No description provided for @attendanceNoStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No students on this day'**
  String get attendanceNoStudentsTitle;

  /// No description provided for @attendanceNoStudentsMessage.
  ///
  /// In en, this message translates to:
  /// **'No student is placed in this section on this day.'**
  String get attendanceNoStudentsMessage;

  /// No description provided for @attendancePresentCount.
  ///
  /// In en, this message translates to:
  /// **'Present: {present} / {total}'**
  String attendancePresentCount(int present, int total);

  /// No description provided for @attendanceMarkPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendanceMarkPresent;

  /// No description provided for @attendanceMarkPresentShort.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get attendanceMarkPresentShort;

  /// No description provided for @attendanceMarkAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceMarkAbsent;

  /// No description provided for @attendanceMarkAbsentShort.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get attendanceMarkAbsentShort;

  /// No description provided for @attendanceMarkLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceMarkLate;

  /// No description provided for @attendanceMarkLateShort.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get attendanceMarkLateShort;

  /// No description provided for @attendanceMarkHalfDay.
  ///
  /// In en, this message translates to:
  /// **'Half day'**
  String get attendanceMarkHalfDay;

  /// No description provided for @attendanceMarkHalfDayShort.
  ///
  /// In en, this message translates to:
  /// **'HD'**
  String get attendanceMarkHalfDayShort;

  /// No description provided for @attendanceMarkLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get attendanceMarkLeave;

  /// No description provided for @attendanceMarkLeaveShort.
  ///
  /// In en, this message translates to:
  /// **'LV'**
  String get attendanceMarkLeaveShort;

  /// No description provided for @attendanceStudentMark.
  ///
  /// In en, this message translates to:
  /// **'{name}, roll {roll}'**
  String attendanceStudentMark(String name, String roll);

  /// No description provided for @attendanceSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Submit Attendance'**
  String get attendanceSubmit;

  /// No description provided for @attendanceSaveCorrections.
  ///
  /// In en, this message translates to:
  /// **'Save corrections'**
  String get attendanceSaveCorrections;

  /// No description provided for @attendanceVoid.
  ///
  /// In en, this message translates to:
  /// **'Void this register'**
  String get attendanceVoid;

  /// No description provided for @attendanceTakenBy.
  ///
  /// In en, this message translates to:
  /// **'Taken by {name} on {time}'**
  String attendanceTakenBy(String name, String time);

  /// No description provided for @attendanceHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday: {title}'**
  String attendanceHoliday(String title);

  /// No description provided for @attendanceHolidayUntitled.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get attendanceHolidayUntitled;

  /// No description provided for @attendanceNotYet.
  ///
  /// In en, this message translates to:
  /// **'This day has not come yet, so it cannot be marked.'**
  String get attendanceNotYet;

  /// No description provided for @attendanceViewOnly.
  ///
  /// In en, this message translates to:
  /// **'You can see this register, but you mark attendance only at your own Institution.'**
  String get attendanceViewOnly;

  /// No description provided for @attendanceClosed.
  ///
  /// In en, this message translates to:
  /// **'Attendance cannot be taken for this day. It may be outside the current academic year.'**
  String get attendanceClosed;

  /// No description provided for @attendanceSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Attendance submitted} =1{Attendance submitted for 1 student} other{Attendance submitted for {count} students}}'**
  String attendanceSubmitted(int count);

  /// No description provided for @attendanceCorrected.
  ///
  /// In en, this message translates to:
  /// **'Attendance corrected'**
  String get attendanceCorrected;

  /// No description provided for @attendanceVoided.
  ///
  /// In en, this message translates to:
  /// **'Register voided. The day can be marked again.'**
  String get attendanceVoided;

  /// No description provided for @attendanceVoidTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this register?'**
  String get attendanceVoidTitle;

  /// No description provided for @attendanceVoidMessage.
  ///
  /// In en, this message translates to:
  /// **'The day can then be marked again. Parents who were told about an absence keep that alert.'**
  String get attendanceVoidMessage;

  /// No description provided for @attendanceVoidReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (at least 5 characters)'**
  String get attendanceVoidReason;

  /// No description provided for @attendanceVoidReasonShort.
  ///
  /// In en, this message translates to:
  /// **'At least 5 characters.'**
  String get attendanceVoidReasonShort;

  /// No description provided for @attendanceVoidConfirm.
  ///
  /// In en, this message translates to:
  /// **'Void register'**
  String get attendanceVoidConfirm;

  /// No description provided for @errorAttendanceNotFound.
  ///
  /// In en, this message translates to:
  /// **'This section could not be found. It may have been closed.'**
  String get errorAttendanceNotFound;

  /// No description provided for @errorAttendanceNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'You mark attendance only at your own Institution.'**
  String get errorAttendanceNotAssigned;

  /// No description provided for @errorAttendanceNoYear.
  ///
  /// In en, this message translates to:
  /// **'No current academic year has been set up yet, so attendance cannot be taken.'**
  String get errorAttendanceNoYear;

  /// No description provided for @errorAttendanceFuture.
  ///
  /// In en, this message translates to:
  /// **'This day has not come yet, so it cannot be marked.'**
  String get errorAttendanceFuture;

  /// No description provided for @errorAttendanceOutsideYear.
  ///
  /// In en, this message translates to:
  /// **'This day is outside the current academic year.'**
  String get errorAttendanceOutsideYear;

  /// No description provided for @errorAttendanceHoliday.
  ///
  /// In en, this message translates to:
  /// **'This day is a holiday for the class, so it cannot be marked.'**
  String get errorAttendanceHoliday;

  /// No description provided for @errorAttendanceTaken.
  ///
  /// In en, this message translates to:
  /// **'Attendance for this day was taken meanwhile. The register is shown.'**
  String get errorAttendanceTaken;

  /// No description provided for @errorAttendanceRosterChanged.
  ///
  /// In en, this message translates to:
  /// **'A student joined or left the section meanwhile. The list is read again: check the marks and submit once more.'**
  String get errorAttendanceRosterChanged;

  /// No description provided for @errorAttendanceNotInSection.
  ///
  /// In en, this message translates to:
  /// **'A student is no longer in this section. The list is read again.'**
  String get errorAttendanceNotInSection;

  /// No description provided for @errorAttendanceVersion.
  ///
  /// In en, this message translates to:
  /// **'Someone else changed this register meanwhile. The latest is shown: check it and correct again.'**
  String get errorAttendanceVersion;

  /// No description provided for @errorAttendanceVoided.
  ///
  /// In en, this message translates to:
  /// **'This register was voided meanwhile. The day is shown as it is now.'**
  String get errorAttendanceVoided;

  /// No description provided for @errorAttendanceOlderYear.
  ///
  /// In en, this message translates to:
  /// **'Only an Owner or an Admin can correct a register of an earlier year.'**
  String get errorAttendanceOlderYear;

  /// No description provided for @errorStudentMoveAttendanceTaken.
  ///
  /// In en, this message translates to:
  /// **'Attendance was taken for the old section on {date} with this student in it. Choose a later day, or void that register and take it again.'**
  String errorStudentMoveAttendanceTaken(String date);

  /// No description provided for @errorStudentMoveAttendanceTakenNoDay.
  ///
  /// In en, this message translates to:
  /// **'Attendance was already taken for the old section with this student in it. Choose a later day, or void that register and take it again.'**
  String get errorStudentMoveAttendanceTakenNoDay;
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
