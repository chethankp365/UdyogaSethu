import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('mr'),
    Locale('or'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'UdyogaSethu'**
  String get appName;

  /// No description provided for @taglinePart1.
  ///
  /// In en, this message translates to:
  /// **'Bridging Work.'**
  String get taglinePart1;

  /// No description provided for @taglinePart2.
  ///
  /// In en, this message translates to:
  /// **'Empowering Lives.'**
  String get taglinePart2;

  /// No description provided for @splashInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing UdyogaSethu...'**
  String get splashInitializing;

  /// No description provided for @chipAiMatching.
  ///
  /// In en, this message translates to:
  /// **'AI Matching'**
  String get chipAiMatching;

  /// No description provided for @chipSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get chipSecure;

  /// No description provided for @chipVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get chipVerified;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(Object version);

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introHeadline.
  ///
  /// In en, this message translates to:
  /// **'Built for India. For Every Worker.'**
  String get introHeadline;

  /// No description provided for @introSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find jobs, grow skills, earn better and live with dignity.'**
  String get introSubtitle;

  /// No description provided for @introFeature1Title.
  ///
  /// In en, this message translates to:
  /// **'Find Jobs Near You'**
  String get introFeature1Title;

  /// No description provided for @introFeature2Title.
  ///
  /// In en, this message translates to:
  /// **'Secure Payments'**
  String get introFeature2Title;

  /// No description provided for @introFeature3Title.
  ///
  /// In en, this message translates to:
  /// **'AI Voice Assistant'**
  String get introFeature3Title;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next ->'**
  String get introNext;

  /// No description provided for @introGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started ->'**
  String get introGetStarted;

  /// No description provided for @languageScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageScreenTitle;

  /// No description provided for @languageScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will show everything in your language'**
  String get languageScreenSubtitle;

  /// No description provided for @listenToWelcomeIn.
  ///
  /// In en, this message translates to:
  /// **'Listen to welcome in {language}'**
  String listenToWelcomeIn(Object language);

  /// No description provided for @ttsVoiceMissingHint.
  ///
  /// In en, this message translates to:
  /// **'Voice engine for {language} is not installed. Tap to open Text-to-Speech settings.'**
  String ttsVoiceMissingHint(Object language);

  /// No description provided for @welcomeSpeechSentence.
  ///
  /// In en, this message translates to:
  /// **'Welcome to UdyogaSethu. Connecting work and empowering lives.'**
  String get welcomeSpeechSentence;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue ->'**
  String get continueButton;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get navJobs;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navWorkers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get navWorkers;

  /// No description provided for @navMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get navMarketplace;

  /// No description provided for @navMandi.
  ///
  /// In en, this message translates to:
  /// **'Mandi'**
  String get navMandi;

  /// No description provided for @navWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get navSafety;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get statusBusy;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get statusNotStarted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review Required'**
  String get statusReviewRequired;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @roleSeeker.
  ///
  /// In en, this message translates to:
  /// **'Job Seeker'**
  String get roleSeeker;

  /// No description provided for @roleProvider.
  ///
  /// In en, this message translates to:
  /// **'Job Provider'**
  String get roleProvider;

  /// No description provided for @roleFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleFarmer;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @seekerTypeInformal.
  ///
  /// In en, this message translates to:
  /// **'Informal Worker'**
  String get seekerTypeInformal;

  /// No description provided for @seekerTypeStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get seekerTypeStudent;

  /// No description provided for @seekerTypePartTime.
  ///
  /// In en, this message translates to:
  /// **'Part-Time Worker'**
  String get seekerTypePartTime;

  /// No description provided for @providerTypeHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get providerTypeHousehold;

  /// No description provided for @providerTypeEmployer.
  ///
  /// In en, this message translates to:
  /// **'Business / Employer'**
  String get providerTypeEmployer;

  /// No description provided for @docTypeAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card'**
  String get docTypeAadhaar;

  /// No description provided for @docTypePan.
  ///
  /// In en, this message translates to:
  /// **'PAN Card'**
  String get docTypePan;

  /// No description provided for @docTypeDrivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving Licence'**
  String get docTypeDrivingLicence;

  /// No description provided for @docTypeBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account / UPI'**
  String get docTypeBankAccount;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your 10-digit mobile number'**
  String get enterPhone;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get otpCode;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP sent to {phone}'**
  String enterOtp(Object phone);

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterName;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @pincode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pincode;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit mobile number'**
  String get invalidPhone;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP'**
  String get invalidOtp;

  /// No description provided for @errorNetworkOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNetworkOffline;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorAuthGeneral.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get errorAuthGeneral;

  /// No description provided for @errorDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database error occurred.'**
  String get errorDatabase;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnknown;

  /// No description provided for @errorEdgeFunction.
  ///
  /// In en, this message translates to:
  /// **'Service request failed.'**
  String get errorEdgeFunction;

  /// No description provided for @amountRupees.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}'**
  String amountRupees(Object amount);

  /// No description provided for @wagePerDay.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}/day'**
  String wagePerDay(Object amount);

  /// No description provided for @wagePerHour.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}/hr'**
  String wagePerHour(Object amount);

  /// No description provided for @wageTypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Wage'**
  String get wageTypeDaily;

  /// No description provided for @wageTypeHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly Wage'**
  String get wageTypeHourly;

  /// No description provided for @wageTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed Payment'**
  String get wageTypeFixed;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @jobsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs found} =1{1 job found} other{{count} jobs found}}'**
  String jobsCount(num count);

  /// No description provided for @applicantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No applicants} =1{1 applicant} other{{count} applicants}}'**
  String applicantsCount(num count);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String distanceKm(Object distance);

  /// No description provided for @todayGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal'**
  String get todayGoal;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @roleTreeTitleStep1.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get roleTreeTitleStep1;

  /// No description provided for @roleTreeSubtitleStep1.
  ///
  /// In en, this message translates to:
  /// **'Select your account category to get started.'**
  String get roleTreeSubtitleStep1;

  /// No description provided for @roleTreeTitleStep2.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get roleTreeTitleStep2;

  /// No description provided for @roleTreeSubtitleStep2.
  ///
  /// In en, this message translates to:
  /// **'Choose your role on UdyogaSethu.'**
  String get roleTreeSubtitleStep2;

  /// No description provided for @roleTreeTitleStep3.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get roleTreeTitleStep3;

  /// No description provided for @roleTreeSubtitleStep3.
  ///
  /// In en, this message translates to:
  /// **'Select the type of work that matches your schedule.'**
  String get roleTreeSubtitleStep3;

  /// No description provided for @roleCategoryWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get roleCategoryWorker;

  /// No description provided for @roleCategoryWorkerDesc.
  ///
  /// In en, this message translates to:
  /// **'Find daily-wage work, part-time jobs, or hire workers'**
  String get roleCategoryWorkerDesc;

  /// No description provided for @roleCategoryFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleCategoryFarmer;

  /// No description provided for @roleCategoryFarmerDesc.
  ///
  /// In en, this message translates to:
  /// **'Sell crops directly to buyers without middleman cuts'**
  String get roleCategoryFarmerDesc;

  /// No description provided for @roleSeekerTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Seeker'**
  String get roleSeekerTitle;

  /// No description provided for @roleSeekerDesc.
  ///
  /// In en, this message translates to:
  /// **'Find daily-wage and part-time work with instant pay'**
  String get roleSeekerDesc;

  /// No description provided for @roleProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Provider'**
  String get roleProviderTitle;

  /// No description provided for @roleProviderDesc.
  ///
  /// In en, this message translates to:
  /// **'Post jobs, hire verified workers, buy fresh produce'**
  String get roleProviderDesc;

  /// No description provided for @seekerTypeInformalTitle.
  ///
  /// In en, this message translates to:
  /// **'Informal / Daily-wage Worker'**
  String get seekerTypeInformalTitle;

  /// No description provided for @seekerTypeInformalDesc.
  ///
  /// In en, this message translates to:
  /// **'Find construction, delivery, plumbing jobs & instant UPI pay'**
  String get seekerTypeInformalDesc;

  /// No description provided for @seekerTypeStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get seekerTypeStudentTitle;

  /// No description provided for @seekerTypeStudentDesc.
  ///
  /// In en, this message translates to:
  /// **'Part-time shifts fitted around study schedule'**
  String get seekerTypeStudentDesc;

  /// No description provided for @seekerTypePartTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Part-time / Flexible Worker'**
  String get seekerTypePartTimeTitle;

  /// No description provided for @seekerTypePartTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Flexible daily or weekend shifts'**
  String get seekerTypePartTimeDesc;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginLink;

  /// No description provided for @listenToStepOptions.
  ///
  /// In en, this message translates to:
  /// **'Listen to options in {language}'**
  String listenToStepOptions(Object language);

  /// No description provided for @breadcrumbWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get breadcrumbWorker;

  /// No description provided for @breadcrumbSeeker.
  ///
  /// In en, this message translates to:
  /// **'Worker > Job Seeker'**
  String get breadcrumbSeeker;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number Login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number for instant SMS login.'**
  String get loginSubtitle;

  /// No description provided for @phoneInputLabel.
  ///
  /// In en, this message translates to:
  /// **'MOBILE PHONE NUMBER'**
  String get phoneInputLabel;

  /// No description provided for @phonePrefix.
  ///
  /// In en, this message translates to:
  /// **'IN +91'**
  String get phonePrefix;

  /// No description provided for @getOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Get SMS OTP Verification Code'**
  String get getOtpCode;

  /// No description provided for @agreeTermsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get agreeTermsDisclaimer;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @googleSignInNotice.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in will be enabled in Phase 2.5'**
  String get googleSignInNotice;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP sent to +91 {maskedPhone}'**
  String otpSubtitle(Object maskedPhone);

  /// No description provided for @verifyAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get verifyAndLogin;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(Object seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @maxResendsReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 resends reached for this session.'**
  String get maxResendsReached;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @invalidOtpError.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired verification code. Please check the 6-digit code and try again.'**
  String get invalidOtpError;

  /// No description provided for @rateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Too many OTP requests. Please wait a moment before trying again.'**
  String get rateLimitError;

  /// No description provided for @termsRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Service to proceed.'**
  String get termsRequiredError;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get googleSignInFailed;

  /// No description provided for @googleEmailAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This email is already linked to another number.'**
  String get googleEmailAlreadyLinked;

  /// No description provided for @verifyPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your mobile number'**
  String get verifyPhoneTitle;

  /// No description provided for @verifyPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a verified mobile number to complete your registration.'**
  String get verifyPhoneSubtitle;

  /// No description provided for @linkGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Link Google Account'**
  String get linkGoogleAccount;

  /// No description provided for @googleAccountLinked.
  ///
  /// In en, this message translates to:
  /// **'Google account linked successfully.'**
  String get googleAccountLinked;

  /// No description provided for @googlePlayServicesMissing.
  ///
  /// In en, this message translates to:
  /// **'Google Play Services is unavailable on this device.'**
  String get googlePlayServicesMissing;

  /// No description provided for @wizardStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String wizardStepProgress(Object current, Object total);

  /// No description provided for @wizardStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get wizardStep1Title;

  /// No description provided for @wizardStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your name, photo, gender, and languages.'**
  String get wizardStep1Subtitle;

  /// No description provided for @wizardStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Skills & Interests'**
  String get wizardStep2Title;

  /// No description provided for @wizardStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your skills or academic interests.'**
  String get wizardStep2Subtitle;

  /// No description provided for @wizardStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Experience & Rate'**
  String get wizardStep3Title;

  /// No description provided for @wizardStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your experience years and expected rates.'**
  String get wizardStep3Subtitle;

  /// No description provided for @wizardStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get wizardStep4Title;

  /// No description provided for @wizardStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your status, working days, and hours.'**
  String get wizardStep4Subtitle;

  /// No description provided for @wizardStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get wizardStep5Title;

  /// No description provided for @wizardStep5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Grant location access and set your service radius.'**
  String get wizardStep5Subtitle;

  /// No description provided for @wizardStep6Title.
  ///
  /// In en, this message translates to:
  /// **'Type Specific Details'**
  String get wizardStep6Title;

  /// No description provided for @wizardStep6Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter details for your worker profile type.'**
  String get wizardStep6Subtitle;

  /// No description provided for @wizardStep7Title.
  ///
  /// In en, this message translates to:
  /// **'Review & Finish'**
  String get wizardStep7Title;

  /// No description provided for @wizardStep7Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your profile details before finishing.'**
  String get wizardStep7Subtitle;

  /// No description provided for @takePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take Photo (Camera)'**
  String get takePhotoCamera;

  /// No description provided for @chooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseGallery;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get uploadingPhoto;

  /// No description provided for @uploadPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed. Tap to retry.'**
  String get uploadPhotoError;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender (Optional)'**
  String get genderLabel;

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

  /// No description provided for @genderPreferNot.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderPreferNot;

  /// No description provided for @languagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages Spoken'**
  String get languagesLabel;

  /// No description provided for @selectCategories.
  ///
  /// In en, this message translates to:
  /// **'Select Categories'**
  String get selectCategories;

  /// No description provided for @selectSkills.
  ///
  /// In en, this message translates to:
  /// **'Select Skills'**
  String get selectSkills;

  /// No description provided for @informalSkillRequired.
  ///
  /// In en, this message translates to:
  /// **'Informal workers must select at least 1 skill.'**
  String get informalSkillRequired;

  /// No description provided for @addSubjectOrInterest.
  ///
  /// In en, this message translates to:
  /// **'Add Subject / Interest'**
  String get addSubjectOrInterest;

  /// No description provided for @subjectsInterestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Subjects or Interests'**
  String get subjectsInterestsLabel;

  /// No description provided for @experienceYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get experienceYearsLabel;

  /// No description provided for @dailyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Daily Rate (₹)'**
  String get dailyRateLabel;

  /// No description provided for @hourlyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Hourly Rate (₹)'**
  String get hourlyRateLabel;

  /// No description provided for @wageBandHint.
  ///
  /// In en, this message translates to:
  /// **'Suggested fair wage band: ₹{min} - ₹{max} / {unit}'**
  String wageBandHint(Object max, Object min, Object unit);

  /// No description provided for @workingDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get workingDaysLabel;

  /// No description provided for @workHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workHoursLabel;

  /// No description provided for @studentWeeklyHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Weekly Hours'**
  String get studentWeeklyHoursLabel;

  /// No description provided for @partTimeShiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Shift Slot'**
  String get partTimeShiftLabel;

  /// No description provided for @shiftMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning Shift (6 AM - 2 PM)'**
  String get shiftMorning;

  /// No description provided for @shiftEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening Shift (2 PM - 10 PM)'**
  String get shiftEvening;

  /// No description provided for @shiftFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible Shift'**
  String get shiftFlexible;

  /// No description provided for @locationConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Just-in-Time Location Access'**
  String get locationConsentTitle;

  /// No description provided for @locationConsentText.
  ///
  /// In en, this message translates to:
  /// **'UdyogaSethu uses your GPS location to match you with nearby jobs, calculate distance, and ensure site safety. Your location is logged only when active.'**
  String get locationConsentText;

  /// No description provided for @allowLocationAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow Location Access'**
  String get allowLocationAccess;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please grant permission in settings or pick on map.'**
  String get locationPermissionDenied;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Home Address / Locality'**
  String get addressLabel;

  /// No description provided for @serviceRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Radius: {radius} km'**
  String serviceRadiusLabel(Object radius);

  /// No description provided for @collegeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'College / University Name'**
  String get collegeNameLabel;

  /// No description provided for @courseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Course / Degree'**
  String get courseNameLabel;

  /// No description provided for @regNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration / USN No. (Stored Masked)'**
  String get regNoLabel;

  /// No description provided for @doYouDriveToggle.
  ///
  /// In en, this message translates to:
  /// **'Do you drive a vehicle?'**
  String get doYouDriveToggle;

  /// No description provided for @drivingLicenceExplanation.
  ///
  /// In en, this message translates to:
  /// **'Note: A valid driving licence will be required for driving and delivery jobs in Phase 3.'**
  String get drivingLicenceExplanation;

  /// No description provided for @reviewSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Summary'**
  String get reviewSummaryTitle;

  /// No description provided for @finishProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Finish Profile & Go to Home'**
  String get finishProfileButton;

  /// No description provided for @verifyIdentityPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please complete identity verification to unlock high-pay jobs!'**
  String get verifyIdentityPrompt;

  /// No description provided for @quitAndResumeNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft saved automatically. You can resume anytime.'**
  String get quitAndResumeNotice;

  /// No description provided for @farmerWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile Setup'**
  String get farmerWizardTitle;

  /// No description provided for @farmerStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get farmerStep1Title;

  /// No description provided for @farmerStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name, photo, and spoken languages.'**
  String get farmerStep1Subtitle;

  /// No description provided for @farmerStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Farm Details'**
  String get farmerStep2Title;

  /// No description provided for @farmerStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your farm name, location, acres, soil type, and primary crops.'**
  String get farmerStep2Subtitle;

  /// No description provided for @farmerStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Registrations & Badges'**
  String get farmerStep3Title;

  /// No description provided for @farmerStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add optional government registrations and certificates for profile badges.'**
  String get farmerStep3Subtitle;

  /// No description provided for @farmerStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Selling Options'**
  String get farmerStep4Title;

  /// No description provided for @farmerStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your produce pickup availability, delivery radius, and lead time.'**
  String get farmerStep4Subtitle;

  /// No description provided for @farmerStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Review & Finish'**
  String get farmerStep5Title;

  /// No description provided for @farmerStep5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your farm profile details before completing setup.'**
  String get farmerStep5Subtitle;

  /// No description provided for @farmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm / Plantation Name'**
  String get farmNameLabel;

  /// No description provided for @farmNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Green Valley Organic Farm'**
  String get farmNameHint;

  /// No description provided for @villageClusterLabel.
  ///
  /// In en, this message translates to:
  /// **'Village / Cluster Name'**
  String get villageClusterLabel;

  /// No description provided for @villageClusterHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Devanahalli, Bengaluru Rural'**
  String get villageClusterHint;

  /// No description provided for @farmLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm Location on Map'**
  String get farmLocationLabel;

  /// No description provided for @acresLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Land (Acres)'**
  String get acresLabel;

  /// No description provided for @soilTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Soil Classification'**
  String get soilTypeLabel;

  /// No description provided for @soilPhLabel.
  ///
  /// In en, this message translates to:
  /// **'Soil pH (Optional)'**
  String get soilPhLabel;

  /// No description provided for @primaryCropsLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Crops Grown'**
  String get primaryCropsLabel;

  /// No description provided for @farmingMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Farming Method'**
  String get farmingMethodLabel;

  /// No description provided for @methodOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get methodOrganic;

  /// No description provided for @methodNatural.
  ///
  /// In en, this message translates to:
  /// **'Natural / Zero Budget'**
  String get methodNatural;

  /// No description provided for @methodConventional.
  ///
  /// In en, this message translates to:
  /// **'Conventional'**
  String get methodConventional;

  /// No description provided for @apmcRegLabel.
  ///
  /// In en, this message translates to:
  /// **'APMC Registration Number (Optional)'**
  String get apmcRegLabel;

  /// No description provided for @apmcRegHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. APMC-KA-2024-889'**
  String get apmcRegHint;

  /// No description provided for @kccStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Kisan Credit Card (KCC) Status'**
  String get kccStatusLabel;

  /// No description provided for @kccNone.
  ///
  /// In en, this message translates to:
  /// **'Not Applied'**
  String get kccNone;

  /// No description provided for @kccApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get kccApplied;

  /// No description provided for @kccApproved.
  ///
  /// In en, this message translates to:
  /// **'KCC Approved ✓'**
  String get kccApproved;

  /// No description provided for @organicCertLabel.
  ///
  /// In en, this message translates to:
  /// **'Organic Certificate Upload (Optional)'**
  String get organicCertLabel;

  /// No description provided for @organicCertHelper.
  ///
  /// In en, this message translates to:
  /// **'Uploaded files are saved in private secure storage and marked as pending review.'**
  String get organicCertHelper;

  /// No description provided for @farmBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm Profile Badges'**
  String get farmBadgesTitle;

  /// No description provided for @deliveryAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Available'**
  String get deliveryAvailableLabel;

  /// No description provided for @pickupAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup Available'**
  String get pickupAvailableLabel;

  /// No description provided for @deliveryRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Radius: {radius} km'**
  String deliveryRadiusLabel(Object radius);

  /// No description provided for @leadTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Typical Lead Time'**
  String get leadTimeLabel;

  /// No description provided for @apmcBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'APMC Registered'**
  String get apmcBadgeTitle;

  /// No description provided for @kccBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Kisan Credit Card'**
  String get kccBadgeTitle;

  /// No description provided for @organicBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Organic Certificate (Pending Review)'**
  String get organicBadgeTitle;

  /// No description provided for @uploadCertButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Organic Certificate (PDF / Image)'**
  String get uploadCertButton;

  /// No description provided for @certUploadedPending.
  ///
  /// In en, this message translates to:
  /// **'Certificate uploaded (Pending Review)'**
  String get certUploadedPending;

  /// No description provided for @providerWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Provider Setup'**
  String get providerWizardTitle;

  /// No description provided for @providerStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get providerStep1Title;

  /// No description provided for @providerStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name, photo, and spoken languages.'**
  String get providerStep1Subtitle;

  /// No description provided for @providerStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Provider Category'**
  String get providerStep2Title;

  /// No description provided for @providerStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select whether you hire as a Household or Employer/Contractor.'**
  String get providerStep2Subtitle;

  /// No description provided for @providerStep3HouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Doorstep Address & Delivery'**
  String get providerStep3HouseholdTitle;

  /// No description provided for @providerStep3HouseholdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set default doorstep delivery address and delivery preferences.'**
  String get providerStep3HouseholdSubtitle;

  /// No description provided for @providerStep3EmployerTitle.
  ///
  /// In en, this message translates to:
  /// **'Organisation & Site Details'**
  String get providerStep3EmployerTitle;

  /// No description provided for @providerStep3EmployerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set organisation name, primary site address, hiring categories, and crew size.'**
  String get providerStep3EmployerSubtitle;

  /// No description provided for @providerStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Permissions & Consents'**
  String get providerStep4Title;

  /// No description provided for @providerStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Review location and notification permissions with just-in-time explanations.'**
  String get providerStep4Subtitle;

  /// No description provided for @providerStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Review & Finish'**
  String get providerStep5Title;

  /// No description provided for @providerStep5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your job provider profile details before completing setup.'**
  String get providerStep5Subtitle;

  /// No description provided for @doorstepAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Flat / Door No. & Street'**
  String get doorstepAddressLabel;

  /// No description provided for @doorstepAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. #402, Sunshine Apartments, 5th Cross'**
  String get doorstepAddressHint;

  /// No description provided for @landmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmarkLabel;

  /// No description provided for @landmarkHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Near Metro Station'**
  String get landmarkHint;

  /// No description provided for @deliveryInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Preferences & Instructions'**
  String get deliveryInstructionsLabel;

  /// No description provided for @deliveryInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Leave with security at gate'**
  String get deliveryInstructionsHint;

  /// No description provided for @gateCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Gate Code / Intercom (Optional)'**
  String get gateCodeLabel;

  /// No description provided for @gateCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234'**
  String get gateCodeHint;

  /// No description provided for @orgNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Organisation / Business Name'**
  String get orgNameLabel;

  /// No description provided for @orgNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sethu Construction & Infra Ltd'**
  String get orgNameHint;

  /// No description provided for @primarySiteAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Site Address'**
  String get primarySiteAddressLabel;

  /// No description provided for @primarySiteAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Site 45, Peripheral Ring Road, Electronics City'**
  String get primarySiteAddressHint;

  /// No description provided for @categoriesHiringLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories Usually Hired For'**
  String get categoriesHiringLabel;

  /// No description provided for @typicalCrewSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Typical Crew Size Needed'**
  String get typicalCrewSizeLabel;

  /// No description provided for @crewSizeWorkers.
  ///
  /// In en, this message translates to:
  /// **'{count} workers'**
  String crewSizeWorkers(Object count);

  /// No description provided for @gpsConsentExplanation.
  ///
  /// In en, this message translates to:
  /// **'UdyogaSethu needs GPS location to locate site delivery addresses and display local worker availability.'**
  String get gpsConsentExplanation;

  /// No description provided for @notificationsConsentExplanation.
  ///
  /// In en, this message translates to:
  /// **'Enable push notifications to receive real-time updates on job applicants, worker arrivals, and delivery tracking.'**
  String get notificationsConsentExplanation;

  /// No description provided for @grantGpsPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Location Permission'**
  String get grantGpsPermission;

  /// No description provided for @grantNotificationsPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Notifications Permission'**
  String get grantNotificationsPermission;

  /// No description provided for @permissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Permission Granted'**
  String get permissionGranted;

  /// No description provided for @providerHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Home'**
  String get providerHomeTitle;

  /// No description provided for @roleConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Role Conflict'**
  String get roleConflictTitle;

  /// No description provided for @roleConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'This number is already registered as {existingRole}. You cannot use it as {chosenRole}. To use a different role, log in as {existingRole}, go to Profile > Settings > Delete account, and then create a new account.'**
  String roleConflictMessage(Object chosenRole, Object existingRole);

  /// No description provided for @roleConflictLoginAs.
  ///
  /// In en, this message translates to:
  /// **'Log in as {existingRole}'**
  String roleConflictLoginAs(Object existingRole);

  /// No description provided for @roleConflictBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get roleConflictBack;

  /// No description provided for @privacyCentreTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Centre'**
  String get privacyCentreTitle;

  /// No description provided for @privacyCentreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your data consents, privacy rights, and system permissions.'**
  String get privacyCentreSubtitle;

  /// No description provided for @consentSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Processing Consent'**
  String get consentSheetTitle;

  /// No description provided for @consentWhatCollected.
  ///
  /// In en, this message translates to:
  /// **'What is collected'**
  String get consentWhatCollected;

  /// No description provided for @consentWhyCollected.
  ///
  /// In en, this message translates to:
  /// **'Why it is collected'**
  String get consentWhyCollected;

  /// No description provided for @consentHowLongKept.
  ///
  /// In en, this message translates to:
  /// **'How long it is kept'**
  String get consentHowLongKept;

  /// No description provided for @consentWhoCanSee.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get consentWhoCanSee;

  /// No description provided for @consentHowToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'How to withdraw'**
  String get consentHowToWithdraw;

  /// No description provided for @consentAgreeButton.
  ///
  /// In en, this message translates to:
  /// **'I Agree & Consent'**
  String get consentAgreeButton;

  /// No description provided for @consentNotNowButton.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get consentNotNowButton;

  /// No description provided for @consentGrantedStatus.
  ///
  /// In en, this message translates to:
  /// **'Consent Granted'**
  String get consentGrantedStatus;

  /// No description provided for @consentRevokedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not Granted / Withdrawn'**
  String get consentRevokedStatus;

  /// No description provided for @withdrawConsentButton.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Consent'**
  String get withdrawConsentButton;

  /// No description provided for @withdrawFaceConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Face Verification Consent?'**
  String get withdrawFaceConsentTitle;

  /// No description provided for @withdrawFaceConsentMessage.
  ///
  /// In en, this message translates to:
  /// **'Withdrawing face consent will permanently erase your face reference vector and matcher records. You will need to re-enroll to use face-verified login.'**
  String get withdrawFaceConsentMessage;

  /// No description provided for @confirmWithdrawButton.
  ///
  /// In en, this message translates to:
  /// **'Withdraw & Erase Data'**
  String get confirmWithdrawButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @termsAndPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy Policy'**
  String get termsAndPrivacyTitle;

  /// No description provided for @termsDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft - Have this reviewed before real launch'**
  String get termsDraftNotice;

  /// No description provided for @systemPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'System Permissions'**
  String get systemPermissionsTitle;

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get openSystemSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @faceVerificationCheck.
  ///
  /// In en, this message translates to:
  /// **'Face Verification Check'**
  String get faceVerificationCheck;

  /// No description provided for @faceCheckSubtext.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity using face liveness check'**
  String get faceCheckSubtext;

  /// No description provided for @faceMatchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Face Identity Verified'**
  String get faceMatchSuccess;

  /// No description provided for @faceMatchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Face Match Failed'**
  String get faceMatchFailedTitle;

  /// No description provided for @faceMatchFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Position your face clearly in good lighting and try again.'**
  String get faceMatchFailedBody;

  /// No description provided for @manualReviewRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'3 Verification Attempts Failed'**
  String get manualReviewRequiredTitle;

  /// No description provided for @manualReviewRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your face verification has been submitted for manual review. You may continue with limited access.'**
  String get manualReviewRequiredBody;

  /// No description provided for @requestManualReview.
  ///
  /// In en, this message translates to:
  /// **'Request Manual Review'**
  String get requestManualReview;

  /// No description provided for @retryVerification.
  ///
  /// In en, this message translates to:
  /// **'Try Verification Again'**
  String get retryVerification;

  /// No description provided for @demoSimulatePass.
  ///
  /// In en, this message translates to:
  /// **'Demo: Pass Verification'**
  String get demoSimulatePass;

  /// No description provided for @demoSimulateFail.
  ///
  /// In en, this message translates to:
  /// **'Demo: Fail Verification'**
  String get demoSimulateFail;

  /// No description provided for @seekerHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Seeker Home'**
  String get seekerHomeTitle;

  /// No description provided for @searchJobsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search jobs, services...'**
  String get searchJobsPlaceholder;

  /// No description provided for @todaysGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal'**
  String get todaysGoal;

  /// No description provided for @viewWallet.
  ///
  /// In en, this message translates to:
  /// **'View Wallet >'**
  String get viewWallet;

  /// No description provided for @locationSharingActive.
  ///
  /// In en, this message translates to:
  /// **'Location sharing active for safety monitoring'**
  String get locationSharingActive;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change >'**
  String get changeLocation;

  /// No description provided for @quickActionsHeader.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get quickActionsHeader;

  /// No description provided for @actionNearbyJobs.
  ///
  /// In en, this message translates to:
  /// **'Nearby Jobs'**
  String get actionNearbyJobs;

  /// No description provided for @actionAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get actionAiAssistant;

  /// No description provided for @actionWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get actionWallet;

  /// No description provided for @actionSafetyHub.
  ///
  /// In en, this message translates to:
  /// **'Safety Hub'**
  String get actionSafetyHub;

  /// No description provided for @tagSponsored.
  ///
  /// In en, this message translates to:
  /// **'SPONSORED'**
  String get tagSponsored;

  /// No description provided for @whyAmISeeingThis.
  ///
  /// In en, this message translates to:
  /// **'Why am I seeing this?'**
  String get whyAmISeeingThis;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED FOR YOU'**
  String get recommendedForYou;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @applied.
  ///
  /// In en, this message translates to:
  /// **'Applied ✓'**
  String get applied;

  /// No description provided for @noJobsNearYou.
  ///
  /// In en, this message translates to:
  /// **'No jobs near you yet'**
  String get noJobsNearYou;

  /// No description provided for @widenRadiusAction.
  ///
  /// In en, this message translates to:
  /// **'Widen Search Radius'**
  String get widenRadiusAction;

  /// No description provided for @sosEmergencyPill.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosEmergencyPill;

  /// No description provided for @selectLocationArea.
  ///
  /// In en, this message translates to:
  /// **'Select Location Area'**
  String get selectLocationArea;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @studentsWelcomeChip.
  ///
  /// In en, this message translates to:
  /// **'Students Welcome'**
  String get studentsWelcomeChip;

  /// No description provided for @flexibleShiftChip.
  ///
  /// In en, this message translates to:
  /// **'Flexible Shift'**
  String get flexibleShiftChip;

  /// No description provided for @nearbyJobsMapTitle.
  ///
  /// In en, this message translates to:
  /// **'NEARBY DAILY WAGE JOBS & WORK SITES'**
  String get nearbyJobsMapTitle;

  /// No description provided for @livePinsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Live Pins'**
  String livePinsCount(Object count);

  /// No description provided for @nearbyGpsPinListings.
  ///
  /// In en, this message translates to:
  /// **'NEARBY GPS PIN LISTINGS ({count})'**
  String nearbyGpsPinListings(Object count);

  /// No description provided for @tapPinOrCardToInspect.
  ///
  /// In en, this message translates to:
  /// **'Tap pin or card to inspect'**
  String get tapPinOrCardToInspect;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @categoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryFilterAll;

  /// No description provided for @recenterMap.
  ///
  /// In en, this message translates to:
  /// **'Recenter GPS'**
  String get recenterMap;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;

  /// No description provided for @gpsDisabledBanner.
  ///
  /// In en, this message translates to:
  /// **'GPS is turned off. Turn on location for accurate distances.'**
  String get gpsDisabledBanner;

  /// No description provided for @locationPermissionDeniedBanner.
  ///
  /// In en, this message translates to:
  /// **'Location permission not granted. Showing default area.'**
  String get locationPermissionDeniedBanner;

  /// No description provided for @noJobsInArea.
  ///
  /// In en, this message translates to:
  /// **'No work sites found in this radius'**
  String get noJobsInArea;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get searchRadius;

  /// No description provided for @radiusKm.
  ///
  /// In en, this message translates to:
  /// **'{radius} km'**
  String radiusKm(Object radius);

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openLocationSettings;

  /// No description provided for @loadJobsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load nearby jobs. Check connection and tap Retry.'**
  String get loadJobsError;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @openStreetMapAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get openStreetMapAttribution;

  /// No description provided for @cameraPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Access'**
  String get cameraPermissionTitle;

  /// No description provided for @cameraPermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for face liveness verification and worker ID scanning.'**
  String get cameraPermissionSubtitle;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Location (GPS)'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used to show nearby jobs, job route map, and work site attendance.'**
  String get locationPermissionSubtitle;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for instant job alerts, payment updates, and safety alerts.'**
  String get notificationPermissionSubtitle;

  /// No description provided for @permissionAllowedStatus.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get permissionAllowedStatus;

  /// No description provided for @permissionBlockedStatus.
  ///
  /// In en, this message translates to:
  /// **'Blocked / Off'**
  String get permissionBlockedStatus;

  /// No description provided for @refreshConsentsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refreshConsentsTooltip;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabWorkShowcase.
  ///
  /// In en, this message translates to:
  /// **'Work Showcase'**
  String get tabWorkShowcase;

  /// No description provided for @tabSafetyStatus.
  ///
  /// In en, this message translates to:
  /// **'Safety Status'**
  String get tabSafetyStatus;

  /// No description provided for @verifiedJobsStat.
  ///
  /// In en, this message translates to:
  /// **'Verified Jobs'**
  String get verifiedJobsStat;

  /// No description provided for @ratingStat.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingStat;

  /// No description provided for @totalEarningsStat.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarningsStat;

  /// No description provided for @categoryPrefix.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String categoryPrefix(Object category);

  /// No description provided for @roleCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'ROLE CREDENTIALS & CATEGORY BADGES'**
  String get roleCredentialsTitle;

  /// No description provided for @changeCategoryBtn.
  ///
  /// In en, this message translates to:
  /// **'Change Category'**
  String get changeCategoryBtn;

  /// No description provided for @changeCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Worker Category'**
  String get changeCategoryTitle;

  /// No description provided for @changeCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your work type to personalize jobs and verification'**
  String get changeCategorySubtitle;

  /// No description provided for @categoryInformalTitle.
  ///
  /// In en, this message translates to:
  /// **'Informal / Skilled Worker'**
  String get categoryInformalTitle;

  /// No description provided for @categoryInformalDesc.
  ///
  /// In en, this message translates to:
  /// **'Trades, craftsmanship, home services & agricultural work'**
  String get categoryInformalDesc;

  /// No description provided for @categoryStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Gig Worker'**
  String get categoryStudentTitle;

  /// No description provided for @categoryStudentDesc.
  ///
  /// In en, this message translates to:
  /// **'Campus gigs, tutoring, creative design & online tasks'**
  String get categoryStudentDesc;

  /// No description provided for @categoryPartTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Part-Time Worker'**
  String get categoryPartTimeTitle;

  /// No description provided for @categoryPartTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Retail, restaurant service, flexible evening & weekend shifts'**
  String get categoryPartTimeDesc;

  /// No description provided for @mySkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'MY SKILLS'**
  String get mySkillsTitle;

  /// No description provided for @addSkillBtn.
  ///
  /// In en, this message translates to:
  /// **'+ Add Skill'**
  String get addSkillBtn;

  /// No description provided for @addSkillDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a Skill'**
  String get addSkillDialogTitle;

  /// No description provided for @addSkillDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose skills matching your work profile'**
  String get addSkillDialogSubtitle;

  /// No description provided for @languageAccessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE & ACCESSIBILITY'**
  String get languageAccessibilityTitle;

  /// No description provided for @verificationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'VERIFICATION STATUS'**
  String get verificationStatusTitle;

  /// No description provided for @accountAndSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & Safety'**
  String get accountAndSafetyTitle;

  /// No description provided for @emptyShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Your completed jobs, photos and ratings will appear here'**
  String get emptyShowcaseTitle;

  /// No description provided for @emptyShowcaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Once you complete jobs through UdyogaSethu, verified employer reviews, photos, and earnings will be showcased here.'**
  String get emptyShowcaseSubtitle;

  /// No description provided for @browseJobsAction.
  ///
  /// In en, this message translates to:
  /// **'Browse Jobs'**
  String get browseJobsAction;

  /// No description provided for @safetyLifecycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Onboarding & Badges'**
  String get safetyLifecycleTitle;

  /// No description provided for @notVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get notVerifiedYet;

  /// No description provided for @verifiedWorkerBadge.
  ///
  /// In en, this message translates to:
  /// **'UDYOGASETHU VERIFIED ✓'**
  String get verifiedWorkerBadge;

  /// No description provided for @dlVerified.
  ///
  /// In en, this message translates to:
  /// **'Driving Licence Verified ✓'**
  String get dlVerified;

  /// No description provided for @dlPending.
  ///
  /// In en, this message translates to:
  /// **'Add Driving Licence'**
  String get dlPending;

  /// No description provided for @studentBadgeVerified.
  ///
  /// In en, this message translates to:
  /// **'Student Status Verified ✓'**
  String get studentBadgeVerified;

  /// No description provided for @studentBadgePending.
  ///
  /// In en, this message translates to:
  /// **'Verify Student Status'**
  String get studentBadgePending;

  /// No description provided for @bankUpiVerified.
  ///
  /// In en, this message translates to:
  /// **'Bank / UPI Linked ✓'**
  String get bankUpiVerified;

  /// No description provided for @bankUpiPending.
  ///
  /// In en, this message translates to:
  /// **'Link Bank / UPI'**
  String get bankUpiPending;

  /// No description provided for @bgCheckVerified.
  ///
  /// In en, this message translates to:
  /// **'Background Check Clear ✓'**
  String get bgCheckVerified;

  /// No description provided for @bgCheckPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Background Check'**
  String get bgCheckPending;

  /// No description provided for @aadhaarVerified.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar eKYC Verified ✓'**
  String get aadhaarVerified;

  /// No description provided for @faceLivenessVerified.
  ///
  /// In en, this message translates to:
  /// **'Face Liveness Verified ✓'**
  String get faceLivenessVerified;

  /// No description provided for @safetyTrainingVerified.
  ///
  /// In en, this message translates to:
  /// **'1-Day Safety Training Completed ✓'**
  String get safetyTrainingVerified;

  /// No description provided for @categoryUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Category updated to {category}! Feed and skills refreshed.'**
  String categoryUpdatedSnackbar(Object category);

  /// No description provided for @providerMyJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get providerMyJobsTitle;

  /// No description provided for @providerTabOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get providerTabOpen;

  /// No description provided for @providerTabFilled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get providerTabFilled;

  /// No description provided for @providerTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get providerTabCompleted;

  /// No description provided for @providerSlotsCounter.
  ///
  /// In en, this message translates to:
  /// **'{filled} / {total} Slots Filled'**
  String providerSlotsCounter(int filled, int total);

  /// No description provided for @providerSlotsOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Open'**
  String providerSlotsOpenCount(int count);

  /// No description provided for @providerPostNewJob.
  ///
  /// In en, this message translates to:
  /// **'Post a Job'**
  String get providerPostNewJob;

  /// No description provided for @providerNoJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Jobs Found'**
  String get providerNoJobsTitle;

  /// No description provided for @providerNoOpenJobsDesc.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any open job postings. Create one to hire verified local workers.'**
  String get providerNoOpenJobsDesc;

  /// No description provided for @providerNoFilledJobsDesc.
  ///
  /// In en, this message translates to:
  /// **'No jobs are currently filled.'**
  String get providerNoFilledJobsDesc;

  /// No description provided for @providerNoCompletedJobsDesc.
  ///
  /// In en, this message translates to:
  /// **'No completed jobs yet.'**
  String get providerNoCompletedJobsDesc;

  /// No description provided for @providerViewApplicants.
  ///
  /// In en, this message translates to:
  /// **'View Applicants'**
  String get providerViewApplicants;

  /// No description provided for @providerApplicantsBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} Applicants'**
  String providerApplicantsBadge(int count);

  /// No description provided for @providerJobPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get providerJobPaused;

  /// No description provided for @providerJobDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get providerJobDraft;

  /// No description provided for @providerJobCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get providerJobCancelled;

  /// No description provided for @providerActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Posting'**
  String get providerActionEdit;

  /// No description provided for @providerActionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause Posting'**
  String get providerActionPause;

  /// No description provided for @providerActionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume Posting'**
  String get providerActionResume;

  /// No description provided for @providerActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Job'**
  String get providerActionCancel;

  /// No description provided for @providerCancelWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Job Posting?'**
  String get providerCancelWarningTitle;

  /// No description provided for @providerCancelWarningHiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Warning: This job has {count} hired worker(s). Cancelling will immediately notify workers, cancel their assignments, and release escrow holds. This may negatively impact your employer reliability rating.'**
  String providerCancelWarningHiredDesc(int count);

  /// No description provided for @providerCancelStandardDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this job posting? Open slots will be removed.'**
  String get providerCancelStandardDesc;

  /// No description provided for @providerConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get providerConfirmCancel;

  /// No description provided for @providerJobCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job has been cancelled.'**
  String get providerJobCancelledSuccess;

  /// No description provided for @providerJobPausedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job posting has been paused.'**
  String get providerJobPausedSuccess;

  /// No description provided for @providerJobResumedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job posting is now active.'**
  String get providerJobResumedSuccess;

  /// No description provided for @postJobWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a Daily Wage Job'**
  String get postJobWizardTitle;

  /// No description provided for @editJobWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Job Posting'**
  String get editJobWizardTitle;

  /// No description provided for @postJobStep1.
  ///
  /// In en, this message translates to:
  /// **'Category & Title'**
  String get postJobStep1;

  /// No description provided for @postJobStepAudience.
  ///
  /// In en, this message translates to:
  /// **'Target Workers'**
  String get postJobStepAudience;

  /// No description provided for @postJobAudienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is this job for?'**
  String get postJobAudienceTitle;

  /// No description provided for @postJobAudienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select matching worker categories who can see and apply for this job.'**
  String get postJobAudienceSubtitle;

  /// No description provided for @postJobAudienceInformal.
  ///
  /// In en, this message translates to:
  /// **'Informal / Daily-wage Worker'**
  String get postJobAudienceInformal;

  /// No description provided for @postJobAudienceInformalHint.
  ///
  /// In en, this message translates to:
  /// **'Day labourers, masons, loaders, construction, field hands'**
  String get postJobAudienceInformalHint;

  /// No description provided for @postJobAudienceStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get postJobAudienceStudent;

  /// No description provided for @postJobAudienceStudentHint.
  ///
  /// In en, this message translates to:
  /// **'College students looking for short, flexible evening or weekend tasks'**
  String get postJobAudienceStudentHint;

  /// No description provided for @postJobAudiencePartTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time / Flexible Worker'**
  String get postJobAudiencePartTime;

  /// No description provided for @postJobAudiencePartTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Workers available for partial shifts or flexible timing'**
  String get postJobAudiencePartTimeHint;

  /// No description provided for @postJobAudienceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one worker type'**
  String get postJobAudienceRequired;

  /// No description provided for @hubConfirmedBookingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active bookings'**
  String get hubConfirmedBookingEmptyTitle;

  /// No description provided for @hubConfirmedBookingEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your confirmed worker assignments and live tracking will appear here.'**
  String get hubConfirmedBookingEmptyDesc;

  /// No description provided for @hubLocationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get hubLocationNotSet;

  /// No description provided for @postJobStep2.
  ///
  /// In en, this message translates to:
  /// **'Wages & Schedule'**
  String get postJobStep2;

  /// No description provided for @postJobStep3.
  ///
  /// In en, this message translates to:
  /// **'Slots & Payment'**
  String get postJobStep3;

  /// No description provided for @postJobStep4.
  ///
  /// In en, this message translates to:
  /// **'Requirements & Location'**
  String get postJobStep4;

  /// No description provided for @postJobStep5.
  ///
  /// In en, this message translates to:
  /// **'Preview & Publish'**
  String get postJobStep5;

  /// No description provided for @postJobSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Work Category'**
  String get postJobSelectCategory;

  /// No description provided for @postJobTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get postJobTitleLabel;

  /// No description provided for @postJobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Construction Helper, Electrician, Plumber'**
  String get postJobTitleHint;

  /// No description provided for @postJobDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get postJobDescLabel;

  /// No description provided for @postJobDescHint.
  ///
  /// In en, this message translates to:
  /// **'Describe specific tasks, tools needed, or location details...'**
  String get postJobDescHint;

  /// No description provided for @postJobWageType.
  ///
  /// In en, this message translates to:
  /// **'Wage Type'**
  String get postJobWageType;

  /// No description provided for @postJobWageDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get postJobWageDaily;

  /// No description provided for @postJobWageHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get postJobWageHourly;

  /// No description provided for @postJobWageFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get postJobWageFixed;

  /// No description provided for @postJobAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Wage Amount (₹)'**
  String get postJobAmountLabel;

  /// No description provided for @postJobFairWageBandTitle.
  ///
  /// In en, this message translates to:
  /// **'Fair Wage Band:'**
  String get postJobFairWageBandTitle;

  /// No description provided for @postJobFairWageBandRange.
  ///
  /// In en, this message translates to:
  /// **'₹{min} - ₹{max} / {unit}'**
  String postJobFairWageBandRange(int min, int max, String unit);

  /// No description provided for @postJobBelowFairWageWarning.
  ///
  /// In en, this message translates to:
  /// **'Wage is below the recommended fair wage band (₹{min} - ₹{max}). Workers may be slower to apply, but you can still proceed.'**
  String postJobBelowFairWageWarning(int min, int max);

  /// No description provided for @postJobDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration'**
  String get postJobDurationLabel;

  /// No description provided for @postJobDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String postJobDurationHours(int hours);

  /// No description provided for @postJobStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date & Time'**
  String get postJobStartDateLabel;

  /// No description provided for @postJobSelectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get postJobSelectDateTime;

  /// No description provided for @postJobSlotsTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Workers Needed (Slots)'**
  String get postJobSlotsTotalLabel;

  /// No description provided for @postJobMaterialsLabel.
  ///
  /// In en, this message translates to:
  /// **'Materials & Tools'**
  String get postJobMaterialsLabel;

  /// No description provided for @postJobMaterialsProvided.
  ///
  /// In en, this message translates to:
  /// **'I will provide all tools and materials'**
  String get postJobMaterialsProvided;

  /// No description provided for @postJobMaterialsWorkerBrings.
  ///
  /// In en, this message translates to:
  /// **'Worker should bring their own tools'**
  String get postJobMaterialsWorkerBrings;

  /// No description provided for @postJobPaymentModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Protection Mode'**
  String get postJobPaymentModeLabel;

  /// No description provided for @postJobPaymentEscrow.
  ///
  /// In en, this message translates to:
  /// **'Protected Escrow (Recommended)'**
  String get postJobPaymentEscrow;

  /// No description provided for @postJobPaymentEscrowDesc.
  ///
  /// In en, this message translates to:
  /// **'Funds held securely until work is verified and approved'**
  String get postJobPaymentEscrowDesc;

  /// No description provided for @postJobPaymentUpi.
  ///
  /// In en, this message translates to:
  /// **'Direct UPI on Completion'**
  String get postJobPaymentUpi;

  /// No description provided for @postJobPaymentUpiDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay directly to worker UPI QR on site'**
  String get postJobPaymentUpiDesc;

  /// No description provided for @postJobPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Daily Cash at Site'**
  String get postJobPaymentCash;

  /// No description provided for @postJobPaymentCashDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay physical cash after shift ends'**
  String get postJobPaymentCashDesc;

  /// No description provided for @postJobRequirementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker Requirements'**
  String get postJobRequirementsLabel;

  /// No description provided for @postJobReqVerifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Background & Identity Verified Only'**
  String get postJobReqVerifiedOnly;

  /// No description provided for @postJobReqLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving Licence Required'**
  String get postJobReqLicence;

  /// No description provided for @postJobReqStudents.
  ///
  /// In en, this message translates to:
  /// **'Students & Part-Time Friendly'**
  String get postJobReqStudents;

  /// No description provided for @postJobLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Site Location'**
  String get postJobLocationLabel;

  /// No description provided for @postJobAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter site address or landmark'**
  String get postJobAddressHint;

  /// No description provided for @postJobGeofenceRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Geofence Check-in Radius'**
  String get postJobGeofenceRadiusLabel;

  /// No description provided for @postJobGeofenceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} meters'**
  String postJobGeofenceMeters(int meters);

  /// No description provided for @postJobPublishButton.
  ///
  /// In en, this message translates to:
  /// **'Publish Job Posting'**
  String get postJobPublishButton;

  /// No description provided for @postJobSaveEditButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get postJobSaveEditButton;

  /// No description provided for @postJobPublishSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job posted successfully!'**
  String get postJobPublishSuccess;

  /// No description provided for @applicantsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Applicants ({count})'**
  String applicantsScreenTitle(int count);

  /// No description provided for @applicantsNoApplicantsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Applications Yet'**
  String get applicantsNoApplicantsTitle;

  /// No description provided for @applicantsNoApplicantsDesc.
  ///
  /// In en, this message translates to:
  /// **'Workers nearby are being notified. Applicants will appear here once they apply.'**
  String get applicantsNoApplicantsDesc;

  /// No description provided for @applicantCardJobsDone.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs done'**
  String applicantCardJobsDone(int count);

  /// No description provided for @applicantCardRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count})'**
  String applicantCardRating(double rating, int count);

  /// No description provided for @applicantCardLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages: {langs}'**
  String applicantCardLanguages(String langs);

  /// No description provided for @applicantCardSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills: {skills}'**
  String applicantCardSkills(String skills);

  /// No description provided for @applicantActionHire.
  ///
  /// In en, this message translates to:
  /// **'Hire'**
  String get applicantActionHire;

  /// No description provided for @applicantActionShortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get applicantActionShortlist;

  /// No description provided for @applicantActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get applicantActionReject;

  /// No description provided for @applicantActionChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get applicantActionChat;

  /// No description provided for @applicantActionProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get applicantActionProfile;

  /// No description provided for @applicantStatusApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get applicantStatusApplied;

  /// No description provided for @applicantStatusShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get applicantStatusShortlisted;

  /// No description provided for @applicantStatusHired.
  ///
  /// In en, this message translates to:
  /// **'Hired'**
  String get applicantStatusHired;

  /// No description provided for @applicantStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get applicantStatusRejected;

  /// No description provided for @applicantHireConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Hire Worker?'**
  String get applicantHireConfirmTitle;

  /// No description provided for @applicantHireConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Hiring {name} will assign them 1 slot on this job. They will receive a booking notification.'**
  String applicantHireConfirmDesc(String name);

  /// No description provided for @applicantHiredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Worker hired successfully! Assignment created.'**
  String get applicantHiredSuccess;

  /// No description provided for @applicantShortlistedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Applicant moved to shortlist.'**
  String get applicantShortlistedSuccess;

  /// No description provided for @applicantRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Application rejected.'**
  String get applicantRejectedSuccess;

  /// No description provided for @applicantJobFullNotice.
  ///
  /// In en, this message translates to:
  /// **'All slots for this job are filled.'**
  String get applicantJobFullNotice;

  /// No description provided for @hubTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Hub'**
  String get hubTitle;

  /// No description provided for @hubVerifiedAccount.
  ///
  /// In en, this message translates to:
  /// **'Verified Account'**
  String get hubVerifiedAccount;

  /// No description provided for @hubTagline.
  ///
  /// In en, this message translates to:
  /// **'Farm-Fresh Goods and Verified On-Demand Workers'**
  String get hubTagline;

  /// No description provided for @hubGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}! 👋'**
  String hubGreeting(String name);

  /// No description provided for @hubTabWorkers.
  ///
  /// In en, this message translates to:
  /// **'Workers & Services'**
  String get hubTabWorkers;

  /// No description provided for @hubTabProduce.
  ///
  /// In en, this message translates to:
  /// **'🌾 Farm Produce'**
  String get hubTabProduce;

  /// No description provided for @hubTabSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get hubTabSubscriptions;

  /// No description provided for @hubProduceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Farm-Direct Produce Marketplace'**
  String get hubProduceComingSoon;

  /// No description provided for @hubProduceComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct farm-fresh vegetables, organic produce, and pure dairy coming in Phase 6.'**
  String get hubProduceComingSoonDesc;

  /// No description provided for @hubSubscriptionsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Farm Produce & Milk Subscriptions'**
  String get hubSubscriptionsComingSoon;

  /// No description provided for @hubSubscriptionsComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily milk deliveries and weekly organic vegetable baskets straight to your doorstep coming in Phase 6.'**
  String get hubSubscriptionsComingSoonDesc;

  /// No description provided for @hubActionScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get hubActionScanQr;

  /// No description provided for @hubActionNoShowHelp.
  ///
  /// In en, this message translates to:
  /// **'No-Show Help'**
  String get hubActionNoShowHelp;

  /// No description provided for @hubActionMilkBasket.
  ///
  /// In en, this message translates to:
  /// **'Milk / Basket'**
  String get hubActionMilkBasket;

  /// No description provided for @hubActionFarmerChat.
  ///
  /// In en, this message translates to:
  /// **'Farmer Chat'**
  String get hubActionFarmerChat;

  /// No description provided for @hubConfirmedBooking.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED BOOKING • {code}'**
  String hubConfirmedBooking(String code);

  /// No description provided for @hubWorkerNotArrived.
  ///
  /// In en, this message translates to:
  /// **'Worker Has Not Arrived'**
  String get hubWorkerNotArrived;

  /// No description provided for @hubProtectedChat.
  ///
  /// In en, this message translates to:
  /// **'Protected Chat'**
  String get hubProtectedChat;

  /// No description provided for @hubVerifiedWorkersTitle.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED ON-DEMAND LOCAL WORKERS'**
  String get hubVerifiedWorkersTitle;

  /// No description provided for @hub100AadhaarVerified.
  ///
  /// In en, this message translates to:
  /// **'100% Aadhaar Verified'**
  String get hub100AadhaarVerified;

  /// No description provided for @hubBookWorker.
  ///
  /// In en, this message translates to:
  /// **'Book Worker'**
  String get hubBookWorker;

  /// No description provided for @hubSearchWorkers.
  ///
  /// In en, this message translates to:
  /// **'Search Workers'**
  String get hubSearchWorkers;

  /// No description provided for @hubSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by skill, distance, language...'**
  String get hubSearchHint;

  /// No description provided for @hubViewAllWorkers.
  ///
  /// In en, this message translates to:
  /// **'View All Workers'**
  String get hubViewAllWorkers;

  /// No description provided for @hubNoActiveBooking.
  ///
  /// In en, this message translates to:
  /// **'No Active Booking Right Now'**
  String get hubNoActiveBooking;

  /// No description provided for @hubNoActiveBookingDesc.
  ///
  /// In en, this message translates to:
  /// **'Book a verified worker or post a job to see active shift status here.'**
  String get hubNoActiveBookingDesc;

  /// No description provided for @workerFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Workers'**
  String get workerFilterTitle;

  /// No description provided for @workerFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Service Category'**
  String get workerFilterCategory;

  /// No description provided for @workerFilterAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get workerFilterAllCategories;

  /// No description provided for @workerFilterDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance'**
  String get workerFilterDistance;

  /// No description provided for @workerFilterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language Spoken'**
  String get workerFilterLanguage;

  /// No description provided for @workerFilterAllLanguages.
  ///
  /// In en, this message translates to:
  /// **'All Languages'**
  String get workerFilterAllLanguages;

  /// No description provided for @workerFilterAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get workerFilterAvailability;

  /// No description provided for @workerFilterAllAvailability.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get workerFilterAllAvailability;

  /// No description provided for @workerFilterRateRange.
  ///
  /// In en, this message translates to:
  /// **'Daily Wage Range'**
  String get workerFilterRateRange;

  /// No description provided for @workerFilterGender.
  ///
  /// In en, this message translates to:
  /// **'Gender Preference (Optional)'**
  String get workerFilterGender;

  /// No description provided for @workerFilterAnyGender.
  ///
  /// In en, this message translates to:
  /// **'Any Gender'**
  String get workerFilterAnyGender;

  /// No description provided for @workerFilterMinRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get workerFilterMinRating;

  /// No description provided for @workerFilterAnyRating.
  ///
  /// In en, this message translates to:
  /// **'Any Rating'**
  String get workerFilterAnyRating;

  /// No description provided for @workerFilterMinJobs.
  ///
  /// In en, this message translates to:
  /// **'Minimum Completed Jobs'**
  String get workerFilterMinJobs;

  /// No description provided for @workerFilterAnyJobs.
  ///
  /// In en, this message translates to:
  /// **'Any Experience'**
  String get workerFilterAnyJobs;

  /// No description provided for @workerFilterVerifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified Workers Only'**
  String get workerFilterVerifiedOnly;

  /// No description provided for @workerFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get workerFilterApply;

  /// No description provided for @workerFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get workerFilterReset;

  /// No description provided for @workerUnverifiedNotice.
  ///
  /// In en, this message translates to:
  /// **'Unverified Worker'**
  String get workerUnverifiedNotice;

  /// No description provided for @workerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker Profile'**
  String get workerProfileTitle;

  /// No description provided for @workerProfileBio.
  ///
  /// In en, this message translates to:
  /// **'About Worker'**
  String get workerProfileBio;

  /// No description provided for @workerProfileSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills & Specializations'**
  String get workerProfileSkills;

  /// No description provided for @workerProfileExperience.
  ///
  /// In en, this message translates to:
  /// **'Work Experience'**
  String get workerProfileExperience;

  /// No description provided for @workerProfileRates.
  ///
  /// In en, this message translates to:
  /// **'Standard Wage Rates'**
  String get workerProfileRates;

  /// No description provided for @workerProfileLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages Spoken'**
  String get workerProfileLanguages;

  /// No description provided for @workerProfileServiceRadius.
  ///
  /// In en, this message translates to:
  /// **'Service Radius'**
  String get workerProfileServiceRadius;

  /// No description provided for @workerProfileTrustBadges.
  ///
  /// In en, this message translates to:
  /// **'Trust & Verification Badges'**
  String get workerProfileTrustBadges;

  /// No description provided for @workerProfileReviews.
  ///
  /// In en, this message translates to:
  /// **'Employer Reviews & Ratings'**
  String get workerProfileReviews;

  /// No description provided for @workerProfileRecentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed'**
  String get workerProfileRecentlyViewed;

  /// No description provided for @workerProfileFavourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get workerProfileFavourite;

  /// No description provided for @workerProfileFavouriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Worker added to favourites.'**
  String get workerProfileFavouriteAdded;

  /// No description provided for @workerProfileFavouriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Worker removed from favourites.'**
  String get workerProfileFavouriteRemoved;

  /// No description provided for @workerProfileBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Worker'**
  String get workerProfileBookNow;

  /// No description provided for @workerProfileChat.
  ///
  /// In en, this message translates to:
  /// **'Protected Chat'**
  String get workerProfileChat;

  /// No description provided for @workerSearchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count} workers nearby'**
  String workerSearchResultsCount(int count);

  /// No description provided for @workerSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No workers match your filter criteria'**
  String get workerSearchNoResults;

  /// No description provided for @workerSearchNoResultsDesc.
  ///
  /// In en, this message translates to:
  /// **'Try increasing the search distance, resetting filters, or switching language preference.'**
  String get workerSearchNoResultsDesc;

  /// No description provided for @workerSearchToggleList.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get workerSearchToggleList;

  /// No description provided for @workerSearchToggleMap.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get workerSearchToggleMap;

  /// No description provided for @noShowHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker Attendance & No-Show Support'**
  String get noShowHelpTitle;

  /// No description provided for @noShowHelpDesc.
  ///
  /// In en, this message translates to:
  /// **'If your booked worker has not arrived by the scheduled shift time, our safety system protects you with an instant replacement or a 100% escrow refund.'**
  String get noShowHelpDesc;

  /// No description provided for @noShowReportButton.
  ///
  /// In en, this message translates to:
  /// **'Report No-Show Now'**
  String get noShowReportButton;

  /// No description provided for @noShowReportSuccess.
  ///
  /// In en, this message translates to:
  /// **'No-show report received. Support and backup workers are being mobilized.'**
  String get noShowReportSuccess;

  /// No description provided for @bookingWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Booking'**
  String get bookingWizardTitle;

  /// No description provided for @bookingStepService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get bookingStepService;

  /// No description provided for @bookingStepDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get bookingStepDateTime;

  /// No description provided for @bookingStepAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bookingStepAddress;

  /// No description provided for @bookingStepPayment.
  ///
  /// In en, this message translates to:
  /// **'Price & Pay'**
  String get bookingStepPayment;

  /// No description provided for @bookingStepNotice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get bookingStepNotice;

  /// No description provided for @bookingStepTicket.
  ///
  /// In en, this message translates to:
  /// **'Booking Pass'**
  String get bookingStepTicket;

  /// No description provided for @bookingWorkerDetails.
  ///
  /// In en, this message translates to:
  /// **'Worker Details'**
  String get bookingWorkerDetails;

  /// No description provided for @bookingServiceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Title / Description'**
  String get bookingServiceTitleLabel;

  /// No description provided for @bookingServiceTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Living room fan wiring repair'**
  String get bookingServiceTitleHint;

  /// No description provided for @bookingSpecialNotes.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions / Notes'**
  String get bookingSpecialNotes;

  /// No description provided for @bookingSpecialNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bring extra 2.5mm wire, ladder available'**
  String get bookingSpecialNotesHint;

  /// No description provided for @bookingDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration'**
  String get bookingDuration;

  /// No description provided for @bookingDurationHalfDay.
  ///
  /// In en, this message translates to:
  /// **'Half Day (4 hrs)'**
  String get bookingDurationHalfDay;

  /// No description provided for @bookingDurationFullDay.
  ///
  /// In en, this message translates to:
  /// **'Full Day (8 hrs)'**
  String get bookingDurationFullDay;

  /// No description provided for @bookingDurationCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom ({hours} hrs)'**
  String bookingDurationCustom(int hours);

  /// No description provided for @bookingSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get bookingSelectDate;

  /// No description provided for @bookingSelectTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Select Time Slot'**
  String get bookingSelectTimeSlot;

  /// No description provided for @bookingSlotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get bookingSlotAvailable;

  /// No description provided for @bookingSlotBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get bookingSlotBooked;

  /// No description provided for @bookingScheduleConflictAlert.
  ///
  /// In en, this message translates to:
  /// **'This worker is already booked during this time window. Please pick an alternative slot.'**
  String get bookingScheduleConflictAlert;

  /// No description provided for @bookingAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Location'**
  String get bookingAddressTitle;

  /// No description provided for @bookingSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get bookingSavedAddresses;

  /// No description provided for @bookingAddNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get bookingAddNewAddress;

  /// No description provided for @bookingAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address Label'**
  String get bookingAddressLabel;

  /// No description provided for @bookingAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Flat / House No. & Street'**
  String get bookingAddressLine1;

  /// No description provided for @bookingLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark (optional)'**
  String get bookingLandmark;

  /// No description provided for @bookingCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get bookingCity;

  /// No description provided for @bookingPincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get bookingPincode;

  /// No description provided for @bookingSaveAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Save as default address'**
  String get bookingSaveAsDefault;

  /// No description provided for @bookingPriceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price Breakdown'**
  String get bookingPriceBreakdown;

  /// No description provided for @bookingAgreedWage.
  ///
  /// In en, this message translates to:
  /// **'Agreed Worker Wage'**
  String get bookingAgreedWage;

  /// No description provided for @bookingPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Convenience Fee'**
  String get bookingPlatformFee;

  /// No description provided for @bookingProtectionCoverFee.
  ///
  /// In en, this message translates to:
  /// **'Job Protection Cover'**
  String get bookingProtectionCoverFee;

  /// No description provided for @bookingTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get bookingTotalPrice;

  /// No description provided for @bookingFairWageVerified.
  ///
  /// In en, this message translates to:
  /// **'Within Fair Wage Band'**
  String get bookingFairWageVerified;

  /// No description provided for @bookingFairWageBelow.
  ///
  /// In en, this message translates to:
  /// **'Below Standard Fair Wage'**
  String get bookingFairWageBelow;

  /// No description provided for @bookingPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get bookingPaymentMethod;

  /// No description provided for @bookingPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash on Completion'**
  String get bookingPaymentCash;

  /// No description provided for @bookingPaymentUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI Instant'**
  String get bookingPaymentUpi;

  /// No description provided for @bookingPaymentEscrow.
  ///
  /// In en, this message translates to:
  /// **'Protected Escrow (Recommended)'**
  String get bookingPaymentEscrow;

  /// No description provided for @bookingPaymentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Payment Gateway Integration (P5.2)'**
  String get bookingPaymentPlaceholder;

  /// No description provided for @bookingRecurringOption.
  ///
  /// In en, this message translates to:
  /// **'Repeat Service Schedule'**
  String get bookingRecurringOption;

  /// No description provided for @bookingRecurringToggle.
  ///
  /// In en, this message translates to:
  /// **'Make this a recurring repeat service'**
  String get bookingRecurringToggle;

  /// No description provided for @bookingRecurringWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly Repeat'**
  String get bookingRecurringWeekly;

  /// No description provided for @bookingRecurringMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Repeat'**
  String get bookingRecurringMonthly;

  /// No description provided for @bookingUnverifiedNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Not UdyogaSethu Verified'**
  String get bookingUnverifiedNoticeTitle;

  /// No description provided for @bookingUnverifiedNoticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This worker has not completed UdyogaSethu training & verification.'**
  String get bookingUnverifiedNoticeSubtitle;

  /// No description provided for @bookingUnverifiedNoticeDesc.
  ///
  /// In en, this message translates to:
  /// **'While the worker is registered, they have not yet earned the official trust and skill badge. Choose your preferred booking mode below:'**
  String get bookingUnverifiedNoticeDesc;

  /// No description provided for @bookingProtectionCoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Add ₹40 Job Protection Cover'**
  String get bookingProtectionCoverTitle;

  /// No description provided for @bookingProtectionCoverDesc.
  ///
  /// In en, this message translates to:
  /// **'Simulated property damage coverage (up to ₹10,000) and verified dispute claim assistance.'**
  String get bookingProtectionCoverDesc;

  /// No description provided for @bookingBookWithoutProtection.
  ///
  /// In en, this message translates to:
  /// **'Book without protection'**
  String get bookingBookWithoutProtection;

  /// No description provided for @bookingBookWithoutProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Proceed with direct cash/escrow terms without accidental damage coverage.'**
  String get bookingBookWithoutProtectionDesc;

  /// No description provided for @bookingProceedToTicket.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Proceed to Booking Pass Ticket'**
  String get bookingProceedToTicket;

  /// No description provided for @bookingTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Pass Ticket'**
  String get bookingTicketTitle;

  /// No description provided for @bookingStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for worker'**
  String get bookingStatusWaiting;

  /// No description provided for @bookingCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking Code'**
  String get bookingCodeLabel;

  /// No description provided for @bookingSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking request sent to worker. You will receive an alert once accepted.'**
  String get bookingSuccessMessage;

  /// No description provided for @bookingViewMyJobs.
  ///
  /// In en, this message translates to:
  /// **'View in My Jobs'**
  String get bookingViewMyJobs;

  /// No description provided for @bookingReturnHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Customer Hub'**
  String get bookingReturnHome;

  /// No description provided for @recurringManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring Services'**
  String get recurringManageTitle;

  /// No description provided for @recurringNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No active recurring bookings found.'**
  String get recurringNoBookings;

  /// No description provided for @recurringPause.
  ///
  /// In en, this message translates to:
  /// **'Pause Schedule'**
  String get recurringPause;

  /// No description provided for @recurringResume.
  ///
  /// In en, this message translates to:
  /// **'Resume Schedule'**
  String get recurringResume;

  /// No description provided for @recurringCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Schedule'**
  String get recurringCancel;

  /// No description provided for @recurringSkipDate.
  ///
  /// In en, this message translates to:
  /// **'Skip Next Date'**
  String get recurringSkipDate;

  /// No description provided for @recurringDateSkipped.
  ///
  /// In en, this message translates to:
  /// **'Next scheduled service skipped.'**
  String get recurringDateSkipped;

  /// No description provided for @recurringStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringStatusActive;

  /// No description provided for @recurringStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringStatusPaused;

  /// No description provided for @recurringStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get recurringStatusCancelled;

  /// No description provided for @demoModeBadge.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoModeBadge;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignment Lifecycle Timeline'**
  String get timelineTitle;

  /// No description provided for @timelineLiveDot.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get timelineLiveDot;

  /// No description provided for @timelineDisputeActive.
  ///
  /// In en, this message translates to:
  /// **'Dispute Raised Under Mediation'**
  String get timelineDisputeActive;

  /// No description provided for @timelineDisputeSub.
  ///
  /// In en, this message translates to:
  /// **'Resolution team is reviewing job evidence and logs.'**
  String get timelineDisputeSub;

  /// No description provided for @timelineCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get timelineCurrentBadge;

  /// No description provided for @stageRequestCreated.
  ///
  /// In en, this message translates to:
  /// **'Request Created'**
  String get stageRequestCreated;

  /// No description provided for @stageAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get stageAccepted;

  /// No description provided for @stageTicketIssued.
  ///
  /// In en, this message translates to:
  /// **'Ticket Issued'**
  String get stageTicketIssued;

  /// No description provided for @stageWorkerArrived.
  ///
  /// In en, this message translates to:
  /// **'Worker Arrived'**
  String get stageWorkerArrived;

  /// No description provided for @stageVerificationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Verification Completed'**
  String get stageVerificationCompleted;

  /// No description provided for @stageJobInProgress.
  ///
  /// In en, this message translates to:
  /// **'Job In Progress'**
  String get stageJobInProgress;

  /// No description provided for @stageCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get stageCompleted;

  /// No description provided for @stagePaymentReleased.
  ///
  /// In en, this message translates to:
  /// **'Payment Released'**
  String get stagePaymentReleased;

  /// No description provided for @stageDisputeRaised.
  ///
  /// In en, this message translates to:
  /// **'Dispute Raised'**
  String get stageDisputeRaised;

  /// No description provided for @activeJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Job Execution'**
  String get activeJobTitle;

  /// No description provided for @actionAcceptJob.
  ///
  /// In en, this message translates to:
  /// **'Accept Job'**
  String get actionAcceptJob;

  /// No description provided for @actionWorkerArrived.
  ///
  /// In en, this message translates to:
  /// **'I Have Arrived'**
  String get actionWorkerArrived;

  /// No description provided for @actionStartWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get actionStartWork;

  /// No description provided for @actionCompleteJob.
  ///
  /// In en, this message translates to:
  /// **'Complete Job'**
  String get actionCompleteJob;

  /// No description provided for @actionAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Payment Release'**
  String get actionAwaitingPayment;

  /// No description provided for @actionJobFinished.
  ///
  /// In en, this message translates to:
  /// **'Job Fully Completed'**
  String get actionJobFinished;

  /// No description provided for @actionDisputeMediation.
  ///
  /// In en, this message translates to:
  /// **'In Dispute Review'**
  String get actionDisputeMediation;

  /// No description provided for @actionWaitingAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Worker to Accept'**
  String get actionWaitingAcceptance;

  /// No description provided for @actionConfirmArrival.
  ///
  /// In en, this message translates to:
  /// **'Confirm Worker Arrival'**
  String get actionConfirmArrival;

  /// No description provided for @actionConfirmCompletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Job Completion'**
  String get actionConfirmCompletion;

  /// No description provided for @actionReleasePayment.
  ///
  /// In en, this message translates to:
  /// **'Release Payment'**
  String get actionReleasePayment;

  /// No description provided for @actionPaymentDone.
  ///
  /// In en, this message translates to:
  /// **'Payment Settled'**
  String get actionPaymentDone;

  /// No description provided for @actionAskForHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask for Help'**
  String get actionAskForHelp;

  /// No description provided for @actionDispute.
  ///
  /// In en, this message translates to:
  /// **'Raise Dispute'**
  String get actionDispute;

  /// No description provided for @simpleModeSpokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to Speak & Execute'**
  String get simpleModeSpokenLabel;

  /// No description provided for @routeAndEtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Route & Travel ETA'**
  String get routeAndEtaTitle;

  /// No description provided for @openInMapsBtn.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMapsBtn;

  /// No description provided for @demoModeChip.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoModeChip;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker Schedule & Travel'**
  String get scheduleTitle;

  /// No description provided for @scheduleDayView.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get scheduleDayView;

  /// No description provided for @scheduleWeekView.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get scheduleWeekView;

  /// No description provided for @scheduleWeeklyTotal.
  ///
  /// In en, this message translates to:
  /// **'Week Projected Earnings'**
  String get scheduleWeeklyTotal;

  /// No description provided for @ticketScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Job Ticket'**
  String get ticketScreenTitle;

  /// No description provided for @refreshTicketTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh Ticket QR'**
  String get refreshTicketTooltip;

  /// No description provided for @ticketOfflineNotice.
  ///
  /// In en, this message translates to:
  /// **'Online connection required to refresh security token. Please reconnect before employer scan.'**
  String get ticketOfflineNotice;

  /// No description provided for @ticketBookingPassHeader.
  ///
  /// In en, this message translates to:
  /// **'BOOKING PASS'**
  String get ticketBookingPassHeader;

  /// No description provided for @ticketScanInstructions.
  ///
  /// In en, this message translates to:
  /// **'Present this QR pass to your employer upon site arrival'**
  String get ticketScanInstructions;

  /// No description provided for @ticketAutoRefreshesIn.
  ///
  /// In en, this message translates to:
  /// **'Refreshes in'**
  String get ticketAutoRefreshesIn;

  /// No description provided for @ticketReplayShieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay Protection Enabled'**
  String get ticketReplayShieldTitle;

  /// No description provided for @ticketReplayShieldBody.
  ///
  /// In en, this message translates to:
  /// **'This dynamic security pass is single-use and auto-refreshes every 2 minutes. Screenshots cannot be replayed or scanned more than once.'**
  String get ticketReplayShieldBody;

  /// No description provided for @attendanceScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Worker QR'**
  String get attendanceScannerTitle;

  /// No description provided for @attendanceScannerInstructions.
  ///
  /// In en, this message translates to:
  /// **'Align worker\'s digital ticket QR code within the frame to verify arrival.'**
  String get attendanceScannerInstructions;

  /// No description provided for @ticketReplayRefusedTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay Refused'**
  String get ticketReplayRefusedTitle;

  /// No description provided for @ticketExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket Expired'**
  String get ticketExpiredTitle;

  /// No description provided for @attendanceScanFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance Scan Failed'**
  String get attendanceScanFailedTitle;

  /// No description provided for @attendanceConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance Confirmed!'**
  String get attendanceConfirmedTitle;

  /// No description provided for @workerMarkedArrived.
  ///
  /// In en, this message translates to:
  /// **'Worker marked as Arrived on site'**
  String get workerMarkedArrived;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// No description provided for @scanDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get scanDone;

  /// No description provided for @viewActiveJob.
  ///
  /// In en, this message translates to:
  /// **'View Active Job'**
  String get viewActiveJob;

  /// No description provided for @actionShowTicket.
  ///
  /// In en, this message translates to:
  /// **'Show QR Ticket'**
  String get actionShowTicket;

  /// No description provided for @actionScanWorkerQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Worker QR'**
  String get actionScanWorkerQr;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @bookingCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Booking code copied to clipboard'**
  String get bookingCodeCopied;

  /// No description provided for @verifyYourPresence.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Presence'**
  String get verifyYourPresence;

  /// No description provided for @verifyPresenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Face match and site geofence check required before start'**
  String get verifyPresenceSubtitle;

  /// No description provided for @gpsPerimeterCheck.
  ///
  /// In en, this message translates to:
  /// **'GPS Site Geofence Check'**
  String get gpsPerimeterCheck;

  /// No description provided for @withinPerimeter.
  ///
  /// In en, this message translates to:
  /// **'Within Job Site Geofence'**
  String get withinPerimeter;

  /// No description provided for @outsidePerimeter.
  ///
  /// In en, this message translates to:
  /// **'Outside Job Site Geofence'**
  String get outsidePerimeter;

  /// No description provided for @distanceFromSite.
  ///
  /// In en, this message translates to:
  /// **'Distance from site: {distance}m (Allowed: {radius}m)'**
  String distanceFromSite(String distance, String radius);

  /// No description provided for @mockLocationDetected.
  ///
  /// In en, this message translates to:
  /// **'Mock / Fake GPS detected. Start refused and logged for review.'**
  String get mockLocationDetected;

  /// No description provided for @faceSelfieCheck.
  ///
  /// In en, this message translates to:
  /// **'Front-Camera Face Check'**
  String get faceSelfieCheck;

  /// No description provided for @takeSelfieBtn.
  ///
  /// In en, this message translates to:
  /// **'Take Verification Selfie'**
  String get takeSelfieBtn;

  /// No description provided for @retakeSelfieBtn.
  ///
  /// In en, this message translates to:
  /// **'Retake Selfie'**
  String get retakeSelfieBtn;

  /// No description provided for @verifyAndStartJob.
  ///
  /// In en, this message translates to:
  /// **'Verify Presence & Start Job'**
  String get verifyAndStartJob;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification Refused'**
  String get verificationFailed;

  /// No description provided for @outOfGeofenceMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be {distance}m away from the job site. You must be within {radius}m to start.'**
  String outOfGeofenceMessage(String distance, String radius);

  /// No description provided for @getHelpOrSupport.
  ///
  /// In en, this message translates to:
  /// **'Get Help / Support'**
  String get getHelpOrSupport;

  /// No description provided for @completionTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Completion & Evidence'**
  String get completionTitle;

  /// No description provided for @completionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit completion selfie and optional work photos to verify finish'**
  String get completionSubtitle;

  /// No description provided for @workResultPhotos.
  ///
  /// In en, this message translates to:
  /// **'Work Evidence Photos (Private)'**
  String get workResultPhotos;

  /// No description provided for @addWorkPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addWorkPhoto;

  /// No description provided for @completeAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Completion & Stop Timer'**
  String get completeAndSubmit;

  /// No description provided for @midJobCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Mid-Job Verification Required'**
  String get midJobCheckTitle;

  /// No description provided for @midJobCheckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'High-value job safety check (wage >= ₹2,000)'**
  String get midJobCheckSubtitle;

  /// No description provided for @midJobConfirmSelfie.
  ///
  /// In en, this message translates to:
  /// **'Take Mid-Shift Selfie'**
  String get midJobConfirmSelfie;

  /// No description provided for @midJobCustomerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Worker On-Site'**
  String get midJobCustomerConfirm;

  /// No description provided for @timerTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Work Timer'**
  String get timerTitle;

  /// No description provided for @timerRunning.
  ///
  /// In en, this message translates to:
  /// **'Timer Running'**
  String get timerRunning;

  /// No description provided for @timerPaused.
  ///
  /// In en, this message translates to:
  /// **'Timer Paused'**
  String get timerPaused;

  /// No description provided for @elapsedTime.
  ///
  /// In en, this message translates to:
  /// **'Elapsed Time'**
  String get elapsedTime;

  /// No description provided for @smartNoShowEngineHeader.
  ///
  /// In en, this message translates to:
  /// **'SMART NO-SHOW RECOVERY ENGINE'**
  String get smartNoShowEngineHeader;

  /// No description provided for @arrivalGraceExpiredAlert.
  ///
  /// In en, this message translates to:
  /// **'⚠️ ARRIVAL GRACE PERIOD EXPIRED'**
  String get arrivalGraceExpiredAlert;

  /// No description provided for @workerHasNotArrivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker Has Not Arrived'**
  String get workerHasNotArrivedTitle;

  /// No description provided for @workerHasNotArrivedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{workerName} is {minutesLate} minutes past the scheduled arrival time for {jobTitle}.'**
  String workerHasNotArrivedSubtitle(
    String workerName,
    int minutesLate,
    String jobTitle,
  );

  /// No description provided for @wait10MinutesAction.
  ///
  /// In en, this message translates to:
  /// **'Wait 10 Minutes'**
  String get wait10MinutesAction;

  /// No description provided for @callWorkerDirectlyAction.
  ///
  /// In en, this message translates to:
  /// **'📞 Call Worker Directly'**
  String get callWorkerDirectlyAction;

  /// No description provided for @findSmartReplacementAction.
  ///
  /// In en, this message translates to:
  /// **'⚡ Find Smart Replacement Worker'**
  String get findSmartReplacementAction;

  /// No description provided for @gracePeriodExtendedMsg.
  ///
  /// In en, this message translates to:
  /// **'Added +10 minutes wait grace. Timer paused.'**
  String get gracePeriodExtendedMsg;

  /// No description provided for @maskedCallDemoMsg.
  ///
  /// In en, this message translates to:
  /// **'Dialing worker... (Demo mode: Masked call arrives in P7.2)'**
  String get maskedCallDemoMsg;

  /// No description provided for @replacementBookedMsg.
  ///
  /// In en, this message translates to:
  /// **'Replacement booked with {workerName}! Original marked as no-show.'**
  String replacementBookedMsg(String workerName);

  /// No description provided for @rankedReplacementsTitle.
  ///
  /// In en, this message translates to:
  /// **'RANKED NEARBY WORKERS'**
  String get rankedReplacementsTitle;

  /// No description provided for @noReplacementsFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'No nearby replacement candidates available right now.'**
  String get noReplacementsFoundMsg;

  /// No description provided for @requestReplacementOneTap.
  ///
  /// In en, this message translates to:
  /// **'Request Replacement (1-Tap)'**
  String get requestReplacementOneTap;

  /// No description provided for @smartNoShowTrustNote.
  ///
  /// In en, this message translates to:
  /// **'Zero-penalty refund on no-shows. Replacement workers are background-screened.'**
  String get smartNoShowTrustNote;

  /// No description provided for @openRecoveryEngineAction.
  ///
  /// In en, this message translates to:
  /// **'Open No-Show Recovery Engine'**
  String get openRecoveryEngineAction;

  /// No description provided for @runningLateQuestionAction.
  ///
  /// In en, this message translates to:
  /// **'Running late? Tap to share ETA'**
  String get runningLateQuestionAction;

  /// No description provided for @runningLateReportedBadge.
  ///
  /// In en, this message translates to:
  /// **'Reported running late (+{minutes}m). Timer paused.'**
  String runningLateReportedBadge(int minutes);

  /// No description provided for @runningLateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Running Late?'**
  String get runningLateDialogTitle;

  /// No description provided for @runningLateDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your expected arrival delay. This notifies your employer and pauses the arrival grace timer once.'**
  String get runningLateDialogSubtitle;

  /// No description provided for @sendEtaAction.
  ///
  /// In en, this message translates to:
  /// **'Send ETA'**
  String get sendEtaAction;

  /// No description provided for @runningLateSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Reported +{minutes} minutes ETA. Employer notified.'**
  String runningLateSuccessMsg(int minutes);

  /// No description provided for @jobHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Job History & Ratings'**
  String get jobHistoryTitle;

  /// No description provided for @jobHistoryHeader.
  ///
  /// In en, this message translates to:
  /// **'Job History'**
  String get jobHistoryHeader;

  /// No description provided for @favouritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favourites & Trust Circles'**
  String get favouritesTitle;

  /// No description provided for @rateJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate & Review Job'**
  String get rateJobTitle;

  /// No description provided for @quickTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick Tags'**
  String get quickTagsLabel;

  /// No description provided for @reviewCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Review (Optional)'**
  String get reviewCommentLabel;

  /// No description provided for @reviewCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience to help the community...'**
  String get reviewCommentHint;

  /// No description provided for @submitReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit Verified Review'**
  String get submitReviewBtn;

  /// No description provided for @reportDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Job Dispute'**
  String get reportDisputeTitle;

  /// No description provided for @disputeFreezeNotice.
  ///
  /// In en, this message translates to:
  /// **'Filing a dispute pauses automatic escrow release and assigns the case to UdyogaSethu Trust & Safety for review.'**
  String get disputeFreezeNotice;

  /// No description provided for @disputeIssueTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Issue Type'**
  String get disputeIssueTypeLabel;

  /// No description provided for @disputeDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue Details & Timeline'**
  String get disputeDetailsLabel;

  /// No description provided for @disputeDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Please explain what happened clearly, including timestamps and any verbal agreements...'**
  String get disputeDetailsHint;

  /// No description provided for @disputeEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence Photos (Optional)'**
  String get disputeEvidenceLabel;

  /// No description provided for @submitDisputeBtn.
  ///
  /// In en, this message translates to:
  /// **'Raise Formal Dispute'**
  String get submitDisputeBtn;

  /// No description provided for @disputeTypeNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-Show / Unreported Absence'**
  String get disputeTypeNoShow;

  /// No description provided for @disputeTypeIncompleteWork.
  ///
  /// In en, this message translates to:
  /// **'Incomplete Work / Left Early'**
  String get disputeTypeIncompleteWork;

  /// No description provided for @disputeTypePoorQuality.
  ///
  /// In en, this message translates to:
  /// **'Poor Quality / Substandard Work'**
  String get disputeTypePoorQuality;

  /// No description provided for @disputeTypeWrongProduct.
  ///
  /// In en, this message translates to:
  /// **'Wrong Product / Quality Mismatch'**
  String get disputeTypeWrongProduct;

  /// No description provided for @disputeTypePaymentIssue.
  ///
  /// In en, this message translates to:
  /// **'Payment Issue / Escrow Dispute'**
  String get disputeTypePaymentIssue;

  /// No description provided for @disputeTypeUnsafeConduct.
  ///
  /// In en, this message translates to:
  /// **'Unsafe Conduct / Behaviour Violation'**
  String get disputeTypeUnsafeConduct;

  /// No description provided for @disputeTypeVerificationProblem.
  ///
  /// In en, this message translates to:
  /// **'Verification / Identity Mismatch'**
  String get disputeTypeVerificationProblem;

  /// No description provided for @disputeTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute Status Tracking'**
  String get disputeTrackingTitle;

  /// No description provided for @settingsSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSectionHeader;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @filterDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get filterDisputed;

  /// No description provided for @filterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get filterInProgress;

  /// No description provided for @filterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get filterCancelled;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Escrow'**
  String get walletTitle;

  /// No description provided for @walletBalanceHeader.
  ///
  /// In en, this message translates to:
  /// **'WALLET BALANCE'**
  String get walletBalanceHeader;

  /// No description provided for @escrowProtected.
  ///
  /// In en, this message translates to:
  /// **'Escrow Protected'**
  String get escrowProtected;

  /// No description provided for @todaysReleased.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Released'**
  String get todaysReleased;

  /// No description provided for @pendingEscrow.
  ///
  /// In en, this message translates to:
  /// **'Pending Escrow'**
  String get pendingEscrow;

  /// No description provided for @withdrawAction.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawAction;

  /// No description provided for @scanUpiQr.
  ///
  /// In en, this message translates to:
  /// **'Scan UPI QR'**
  String get scanUpiQr;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'RECENT TRANSACTIONS'**
  String get recentTransactions;

  /// No description provided for @withdrawEarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Earnings'**
  String get withdrawEarningsTitle;

  /// No description provided for @demoWithdrawNote.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: Simulated payout ledger debit until banking partner exists.'**
  String get demoWithdrawNote;

  /// No description provided for @transferToUpi.
  ///
  /// In en, this message translates to:
  /// **'Transfer To (UPI VPA / Bank)'**
  String get transferToUpi;

  /// No description provided for @confirmPayoutWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payout Withdrawal'**
  String get confirmPayoutWithdrawal;

  /// No description provided for @demoPayoutCompleted.
  ///
  /// In en, this message translates to:
  /// **'Demo Payout Completed'**
  String get demoPayoutCompleted;

  /// No description provided for @demoUpiScanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: Simulated UPI Scanner'**
  String get demoUpiScanner;

  /// No description provided for @demoUpiNote.
  ///
  /// In en, this message translates to:
  /// **'No real money will be transferred. Payment rails connect in Phase 5.2.'**
  String get demoUpiNote;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No Transactions Found'**
  String get noTransactionsFound;

  /// No description provided for @noTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed daily wages and transfers will appear here.'**
  String get noTransactionsSubtitle;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment & Escrow Protection'**
  String get paymentTitle;

  /// No description provided for @paymentBillSummary.
  ///
  /// In en, this message translates to:
  /// **'Bill Summary'**
  String get paymentBillSummary;

  /// No description provided for @paymentServiceWage.
  ///
  /// In en, this message translates to:
  /// **'Service / Wage Amount'**
  String get paymentServiceWage;

  /// No description provided for @paymentPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee & GST'**
  String get paymentPlatformFee;

  /// No description provided for @paymentProtectionAddon.
  ///
  /// In en, this message translates to:
  /// **'Protection & Safety Add-on'**
  String get paymentProtectionAddon;

  /// No description provided for @paymentTotalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get paymentTotalPayable;

  /// No description provided for @paymentEscrowNotice.
  ///
  /// In en, this message translates to:
  /// **'Protected until verified completion. Money held in safe Escrow.'**
  String get paymentEscrowNotice;

  /// No description provided for @paymentChooseMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose Payment Method'**
  String get paymentChooseMethod;

  /// No description provided for @paymentUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI (GPay / PhonePe / Paytm)'**
  String get paymentUpi;

  /// No description provided for @paymentCard.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get paymentCard;

  /// No description provided for @paymentWallet.
  ///
  /// In en, this message translates to:
  /// **'UdyogaSethu Wallet'**
  String get paymentWallet;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash on Completion'**
  String get paymentCash;

  /// No description provided for @paymentPaySecurely.
  ///
  /// In en, this message translates to:
  /// **'Pay Securely'**
  String get paymentPaySecurely;

  /// No description provided for @paymentConfirmCash.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cash Booking'**
  String get paymentConfirmCash;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful and Confirmed'**
  String get paymentSuccessful;

  /// No description provided for @paymentSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your payment is confirmed and safely held in escrow.'**
  String get paymentSuccessSubtitle;

  /// No description provided for @paymentConfirmingBank.
  ///
  /// In en, this message translates to:
  /// **'Confirming with Bank...'**
  String get paymentConfirmingBank;

  /// No description provided for @paymentConfirmingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation from Razorpay and banking network. Your screen will update automatically.'**
  String get paymentConfirmingSubtitle;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @paymentFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your transaction could not be completed by the bank. No money was deducted.'**
  String get paymentFailedSubtitle;

  /// No description provided for @paymentReceiptNo.
  ///
  /// In en, this message translates to:
  /// **'Receipt No'**
  String get paymentReceiptNo;

  /// No description provided for @paymentDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Share / Download PDF Receipt'**
  String get paymentDownloadPdf;

  /// No description provided for @paymentContinueJob.
  ///
  /// In en, this message translates to:
  /// **'Continue to Job / Order'**
  String get paymentContinueJob;

  /// No description provided for @paymentTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get paymentTryAgain;

  /// No description provided for @pendingEscrowRelease.
  ///
  /// In en, this message translates to:
  /// **'Pending Escrow Release'**
  String get pendingEscrowRelease;

  /// No description provided for @protectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get protectedBadge;

  /// No description provided for @releaseEscrowPayment.
  ///
  /// In en, this message translates to:
  /// **'Release Escrow Payment'**
  String get releaseEscrowPayment;

  /// No description provided for @confirmAndRelease.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Release Payment'**
  String get confirmAndRelease;

  /// No description provided for @workerPayout.
  ///
  /// In en, this message translates to:
  /// **'Worker Payout (Available Balance)'**
  String get workerPayout;

  /// No description provided for @escrowAutoReleaseNotice.
  ///
  /// In en, this message translates to:
  /// **'Payment will be released as soon as the employer confirms, or automatically within 24 hours if no dispute is raised.'**
  String get escrowAutoReleaseNotice;

  /// No description provided for @escrowEarningsSecured.
  ///
  /// In en, this message translates to:
  /// **'Your earnings are 100% secured in escrow'**
  String get escrowEarningsSecured;

  /// No description provided for @releaseEscrowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successfully released to worker wallet!'**
  String get releaseEscrowSuccess;

  /// No description provided for @earningsDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings & Performance'**
  String get earningsDashboardTitle;

  /// No description provided for @earningsToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get earningsToday;

  /// No description provided for @earningsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get earningsThisWeek;

  /// No description provided for @earningsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get earningsThisMonth;

  /// No description provided for @earningsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Lifetime Earnings'**
  String get earningsTotal;

  /// No description provided for @earningsCompletedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed Jobs'**
  String get earningsCompletedJobs;

  /// No description provided for @earningsFarmOrders.
  ///
  /// In en, this message translates to:
  /// **'Farm Orders'**
  String get earningsFarmOrders;

  /// No description provided for @earningsAverageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get earningsAverageRating;

  /// No description provided for @earningsDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get earningsDailyGoal;

  /// No description provided for @earningsDailyGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal Progress'**
  String get earningsDailyGoalProgress;

  /// No description provided for @earningsPayoutTrends.
  ///
  /// In en, this message translates to:
  /// **'Payout Trend'**
  String get earningsPayoutTrends;

  /// No description provided for @earningsTimeframe14Days.
  ///
  /// In en, this message translates to:
  /// **'14 Days'**
  String get earningsTimeframe14Days;

  /// No description provided for @earningsTimeframe6Months.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get earningsTimeframe6Months;

  /// No description provided for @earningsBestDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Best Earning Day'**
  String get earningsBestDayTitle;

  /// No description provided for @earningsBestDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You earned {amount} on {date}!'**
  String earningsBestDaySubtitle(Object amount, Object date);

  /// No description provided for @earningsSetDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Daily Goal'**
  String get earningsSetDailyGoal;

  /// No description provided for @earningsSaveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save Goal'**
  String get earningsSaveGoal;

  /// No description provided for @savingsGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings Goal Planner'**
  String get savingsGoalsTitle;

  /// No description provided for @savingsGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your dreams. Goals are virtual trackers and do not lock your money.'**
  String get savingsGoalsSubtitle;

  /// No description provided for @savingsGoalsVirtualNotice.
  ///
  /// In en, this message translates to:
  /// **'Virtual Goal Trackers: Goals help you budget and plan towards your dreams. They do not freeze or lock your wallet money.'**
  String get savingsGoalsVirtualNotice;

  /// No description provided for @savingsGoalNew.
  ///
  /// In en, this message translates to:
  /// **'New Savings Goal'**
  String get savingsGoalNew;

  /// No description provided for @savingsGoalCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Savings Goal'**
  String get savingsGoalCreate;

  /// No description provided for @savingsGoalTarget.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get savingsGoalTarget;

  /// No description provided for @savingsGoalSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved So Far'**
  String get savingsGoalSaved;

  /// No description provided for @savingsGoalDeadline.
  ///
  /// In en, this message translates to:
  /// **'Target Deadline'**
  String get savingsGoalDeadline;

  /// No description provided for @savingsGoalCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get savingsGoalCategory;

  /// No description provided for @savingsGoalSuggestedPlan.
  ///
  /// In en, this message translates to:
  /// **'Suggested Savings Plan'**
  String get savingsGoalSuggestedPlan;

  /// No description provided for @savingsGoalAddSavings.
  ///
  /// In en, this message translates to:
  /// **'Record Savings Progress'**
  String get savingsGoalAddSavings;

  /// No description provided for @savingsGoalAddAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount Saved'**
  String get savingsGoalAddAmount;

  /// No description provided for @savingsGoalCompletedBadge.
  ///
  /// In en, this message translates to:
  /// **'Goal Achieved! 🎉'**
  String get savingsGoalCompletedBadge;

  /// No description provided for @savingsGoalActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get savingsGoalActiveBadge;

  /// No description provided for @savingsGoalCategorySchoolFees.
  ///
  /// In en, this message translates to:
  /// **'School Fees'**
  String get savingsGoalCategorySchoolFees;

  /// No description provided for @savingsGoalCategoryEquipment.
  ///
  /// In en, this message translates to:
  /// **'Work Equipment'**
  String get savingsGoalCategoryEquipment;

  /// No description provided for @savingsGoalCategoryScooter.
  ///
  /// In en, this message translates to:
  /// **'Scooter / Vehicle'**
  String get savingsGoalCategoryScooter;

  /// No description provided for @savingsGoalCategorySeeds.
  ///
  /// In en, this message translates to:
  /// **'Seeds & Fertilizer'**
  String get savingsGoalCategorySeeds;

  /// No description provided for @savingsGoalCategoryEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency Fund'**
  String get savingsGoalCategoryEmergency;

  /// No description provided for @savingsGoalCategoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home Renovation'**
  String get savingsGoalCategoryHome;

  /// No description provided for @savingsGoalCategoryCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Goal'**
  String get savingsGoalCategoryCustom;

  /// No description provided for @savingsGoalDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get savingsGoalDelete;

  /// No description provided for @savingsGoalDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this savings goal tracker?'**
  String get savingsGoalDeleteConfirm;

  /// No description provided for @savingsGoalEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Plan your next big milestone by setting a savings goal.'**
  String get savingsGoalEmptyState;

  /// No description provided for @savingsGoalsPlanGoals.
  ///
  /// In en, this message translates to:
  /// **'Plan Goals'**
  String get savingsGoalsPlanGoals;

  /// No description provided for @farmerWorkspace.
  ///
  /// In en, this message translates to:
  /// **'FARMER WORKSPACE'**
  String get farmerWorkspace;

  /// No description provided for @farmerEmpoweredNetwork.
  ///
  /// In en, this message translates to:
  /// **'Empowered by UdyogaSethu Direct Agri-Network'**
  String get farmerEmpoweredNetwork;

  /// No description provided for @farmerProduceSold.
  ///
  /// In en, this message translates to:
  /// **'PRODUCE SOLD'**
  String get farmerProduceSold;

  /// No description provided for @farmerThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get farmerThisMonth;

  /// No description provided for @farmerDirectEarnings.
  ///
  /// In en, this message translates to:
  /// **'DIRECT EARNINGS'**
  String get farmerDirectEarnings;

  /// No description provided for @farmerZeroMiddlemen.
  ///
  /// In en, this message translates to:
  /// **'Zero Middlemen'**
  String get farmerZeroMiddlemen;

  /// No description provided for @farmerActiveLabor.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE LABOR'**
  String get farmerActiveLabor;

  /// No description provided for @farmerHarvestShiftPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Harvest Shift (P6.3)'**
  String get farmerHarvestShiftPlaceholder;

  /// No description provided for @farmerBooked.
  ///
  /// In en, this message translates to:
  /// **'{count} Booked'**
  String farmerBooked(int count);

  /// No description provided for @farmerWeatherAdvisoryRadar.
  ///
  /// In en, this message translates to:
  /// **'WEATHER ADVISORY RADAR'**
  String get farmerWeatherAdvisoryRadar;

  /// No description provided for @farmerSimulatedForecast.
  ///
  /// In en, this message translates to:
  /// **'Simulated Forecast'**
  String get farmerSimulatedForecast;

  /// No description provided for @farmerRainProbability.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Rain'**
  String farmerRainProbability(int percent);

  /// No description provided for @farmerBookHarvestHelpers.
  ///
  /// In en, this message translates to:
  /// **'Book Harvest Helpers'**
  String get farmerBookHarvestHelpers;

  /// No description provided for @farmerViewIrrigationGuide.
  ///
  /// In en, this message translates to:
  /// **'View Irrigation Guide'**
  String get farmerViewIrrigationGuide;

  /// No description provided for @farmerLiveMandiPrices.
  ///
  /// In en, this message translates to:
  /// **'LIVE MANDI PRICES & DEMAND'**
  String get farmerLiveMandiPrices;

  /// No description provided for @farmerLiveFeed.
  ///
  /// In en, this message translates to:
  /// **'Live Feed'**
  String get farmerLiveFeed;

  /// No description provided for @farmerAllCrops.
  ///
  /// In en, this message translates to:
  /// **'All Crops'**
  String get farmerAllCrops;

  /// No description provided for @farmerVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get farmerVegetables;

  /// No description provided for @farmerGrainsAndPulses.
  ///
  /// In en, this message translates to:
  /// **'Grains & Pulses'**
  String get farmerGrainsAndPulses;

  /// No description provided for @farmerNoPricesInCategory.
  ///
  /// In en, this message translates to:
  /// **'No Mandi Prices in this Category'**
  String get farmerNoPricesInCategory;

  /// No description provided for @farmerSelectAllCropsHint.
  ///
  /// In en, this message translates to:
  /// **'Select All Crops to view all Karnataka APMC market prices.'**
  String get farmerSelectAllCropsHint;

  /// No description provided for @farmerUpdatedDate.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String farmerUpdatedDate(String date);

  /// No description provided for @farmerApmcKarnatakaFeed.
  ///
  /// In en, this message translates to:
  /// **'APMC Karnataka Feed'**
  String get farmerApmcKarnatakaFeed;

  /// No description provided for @farmerEssentialSuite.
  ///
  /// In en, this message translates to:
  /// **'FARMER ESSENTIAL SUITE'**
  String get farmerEssentialSuite;

  /// No description provided for @farmerRentTractor.
  ///
  /// In en, this message translates to:
  /// **'Rent Tractor'**
  String get farmerRentTractor;

  /// No description provided for @farmerHireWorkers.
  ///
  /// In en, this message translates to:
  /// **'Hire Workers'**
  String get farmerHireWorkers;

  /// No description provided for @farmerSoilAiTest.
  ///
  /// In en, this message translates to:
  /// **'Soil AI Test'**
  String get farmerSoilAiTest;

  /// No description provided for @farmerSellProduce.
  ///
  /// In en, this message translates to:
  /// **'Sell Produce'**
  String get farmerSellProduce;

  /// No description provided for @farmerPestAiDoc.
  ///
  /// In en, this message translates to:
  /// **'Pest AI Doc'**
  String get farmerPestAiDoc;

  /// No description provided for @farmerGovtSchemes.
  ///
  /// In en, this message translates to:
  /// **'Govt Schemes'**
  String get farmerGovtSchemes;

  /// No description provided for @farmerAgriDrone.
  ///
  /// In en, this message translates to:
  /// **'Agri Drone'**
  String get farmerAgriDrone;

  /// No description provided for @farmerIrrigationAi.
  ///
  /// In en, this message translates to:
  /// **'Irrigation AI'**
  String get farmerIrrigationAi;

  /// No description provided for @farmerComingInPhase.
  ///
  /// In en, this message translates to:
  /// **'Coming in {phase}'**
  String farmerComingInPhase(String phase);

  /// No description provided for @farmerUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get farmerUnderstood;

  /// No description provided for @farmerGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get farmerGotIt;

  /// No description provided for @farmerHireWorkersDesc.
  ///
  /// In en, this message translates to:
  /// **'Farmers will be able to post agricultural labour requests, specify shifts, and hire verified nearby workers directly from their farmer account with escrow protection.'**
  String get farmerHireWorkersDesc;

  /// No description provided for @farmerRentTractorDesc.
  ///
  /// In en, this message translates to:
  /// **'Book nearby tractors, rotavators, and harvesters directly from verified agri-machinery hubs.'**
  String get farmerRentTractorDesc;

  /// No description provided for @farmerSoilAiTestDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload soil test report or photograph to get instant AI N-P-K recommendations and fertilizer dosages.'**
  String get farmerSoilAiTestDesc;

  /// No description provided for @farmerSellProduceDesc.
  ///
  /// In en, this message translates to:
  /// **'List your harvested crops for direct bulk sale to mandi traders and commercial buyers with zero middlemen.'**
  String get farmerSellProduceDesc;

  /// No description provided for @farmerPestAiDocDesc.
  ///
  /// In en, this message translates to:
  /// **'Snap a picture of leaf damage or crop pests for immediate AI diagnosis and organic treatment remedies.'**
  String get farmerPestAiDocDesc;

  /// No description provided for @farmerGovtSchemesDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore PM-Kisan, Raitha Siri, solar pump subsidies, and crop insurance schemes tailored to your land.'**
  String get farmerGovtSchemesDesc;

  /// No description provided for @farmerAgriDroneDesc.
  ///
  /// In en, this message translates to:
  /// **'Book certified agri-drone pilots for precision nano-urea and organic pest spray within 24 hours.'**
  String get farmerAgriDroneDesc;

  /// No description provided for @farmerIrrigationAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart irrigation scheduling based on local evapotranspiration and soil moisture retention curves.'**
  String get farmerIrrigationAiDesc;

  /// No description provided for @farmerHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Home'**
  String get farmerHomeTitle;

  /// No description provided for @farmerSimulateRainDev.
  ///
  /// In en, this message translates to:
  /// **'Simulate Rain Forecast (Dev)'**
  String get farmerSimulateRainDev;

  /// No description provided for @farmerFailedLoadMandi.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Mandi prices'**
  String get farmerFailedLoadMandi;

  /// No description provided for @farmerHighDemand.
  ///
  /// In en, this message translates to:
  /// **'High Demand'**
  String get farmerHighDemand;

  /// No description provided for @farmerStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get farmerStable;

  /// No description provided for @farmerFrpGuaranteed.
  ///
  /// In en, this message translates to:
  /// **'FRP Guaranteed'**
  String get farmerFrpGuaranteed;

  /// No description provided for @farmerMspProtected.
  ///
  /// In en, this message translates to:
  /// **'MSP Protected'**
  String get farmerMspProtected;

  /// No description provided for @farmerOversupply.
  ///
  /// In en, this message translates to:
  /// **'Oversupply'**
  String get farmerOversupply;

  /// No description provided for @farmerModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get farmerModerate;

  /// No description provided for @farmerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile'**
  String get farmerProfileTitle;

  /// No description provided for @verifiedFarmer.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED FARMER ✓'**
  String get verifiedFarmer;

  /// No description provided for @organicLand.
  ///
  /// In en, this message translates to:
  /// **'Organic Land'**
  String get organicLand;

  /// No description provided for @soldThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Sold This Month'**
  String get soldThisMonth;

  /// No description provided for @directSales.
  ///
  /// In en, this message translates to:
  /// **'Direct Sales'**
  String get directSales;

  /// No description provided for @farmInfrastructureAndBadges.
  ///
  /// In en, this message translates to:
  /// **'FARM INFRASTRUCTURE & CROP BADGES'**
  String get farmInfrastructureAndBadges;

  /// No description provided for @soilClassification.
  ///
  /// In en, this message translates to:
  /// **'SOIL CLASSIFICATION'**
  String get soilClassification;

  /// No description provided for @primaryCrops.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY CROPS'**
  String get primaryCrops;

  /// No description provided for @apmcRegistration.
  ///
  /// In en, this message translates to:
  /// **'APMC REGISTRATION'**
  String get apmcRegistration;

  /// No description provided for @kisanCreditCard.
  ///
  /// In en, this message translates to:
  /// **'KISAN CREDIT CARD'**
  String get kisanCreditCard;

  /// No description provided for @zeroPesticideOrganicCertificate.
  ///
  /// In en, this message translates to:
  /// **'Zero-Pesticide Organic Certificate'**
  String get zeroPesticideOrganicCertificate;

  /// No description provided for @verifiedByKarnatakaOrganicBoard.
  ///
  /// In en, this message translates to:
  /// **'Verified by Karnataka Organic Farmers Board'**
  String get verifiedByKarnatakaOrganicBoard;

  /// No description provided for @validatedStatus.
  ///
  /// In en, this message translates to:
  /// **'VALIDATED ✓'**
  String get validatedStatus;

  /// No description provided for @underReviewStatus.
  ///
  /// In en, this message translates to:
  /// **'UNDER REVIEW'**
  String get underReviewStatus;

  /// No description provided for @languageMode.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE MODE'**
  String get languageMode;

  /// No description provided for @manageProduceListings.
  ///
  /// In en, this message translates to:
  /// **'Manage Produce Listings'**
  String get manageProduceListings;

  /// No description provided for @produceListingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Produce Listings'**
  String get produceListingsTitle;

  /// No description provided for @addNewProduce.
  ///
  /// In en, this message translates to:
  /// **'Add New Produce'**
  String get addNewProduce;

  /// No description provided for @editProduceListing.
  ///
  /// In en, this message translates to:
  /// **'Edit Produce Listing'**
  String get editProduceListing;

  /// No description provided for @produceName.
  ///
  /// In en, this message translates to:
  /// **'Produce Name'**
  String get produceName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @pricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price per {unit}'**
  String pricePerUnit(String unit);

  /// No description provided for @stockQuantity.
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get stockQuantity;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @harvestDate.
  ///
  /// In en, this message translates to:
  /// **'Harvest Date'**
  String get harvestDate;

  /// No description provided for @qualityNotes.
  ///
  /// In en, this message translates to:
  /// **'Quality Notes'**
  String get qualityNotes;

  /// No description provided for @farmingMethod.
  ///
  /// In en, this message translates to:
  /// **'Farming Method'**
  String get farmingMethod;

  /// No description provided for @deliveryAvailable.
  ///
  /// In en, this message translates to:
  /// **'Delivery Available'**
  String get deliveryAvailable;

  /// No description provided for @pickupAvailable.
  ///
  /// In en, this message translates to:
  /// **'Pickup Available'**
  String get pickupAvailable;

  /// No description provided for @availabilityMode.
  ///
  /// In en, this message translates to:
  /// **'Availability Mode'**
  String get availabilityMode;

  /// No description provided for @sameDayDelivery.
  ///
  /// In en, this message translates to:
  /// **'Same Day Delivery'**
  String get sameDayDelivery;

  /// No description provided for @nextDayDelivery.
  ///
  /// In en, this message translates to:
  /// **'Next Day Delivery'**
  String get nextDayDelivery;

  /// No description provided for @harvestPreOrder.
  ///
  /// In en, this message translates to:
  /// **'Harvest Pre-Order'**
  String get harvestPreOrder;

  /// No description provided for @farmerSetsFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'The farmer always sets the final price'**
  String get farmerSetsFinalPrice;

  /// No description provided for @statusLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get statusLowStock;

  /// No description provided for @statusSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold Out'**
  String get statusSoldOut;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @pauseListing.
  ///
  /// In en, this message translates to:
  /// **'Pause Listing'**
  String get pauseListing;

  /// No description provided for @activateListing.
  ///
  /// In en, this message translates to:
  /// **'Activate Listing'**
  String get activateListing;

  /// No description provided for @updateStock.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get updateStock;

  /// No description provided for @stockInStock.
  ///
  /// In en, this message translates to:
  /// **'{stock} in stock'**
  String stockInStock(String stock);

  /// No description provided for @buyerProduceMarket.
  ///
  /// In en, this message translates to:
  /// **'Farm Fresh Produce'**
  String get buyerProduceMarket;

  /// No description provided for @buyerSearchProduceHint.
  ///
  /// In en, this message translates to:
  /// **'Search fresh farm produce (e.g., Tomato, Rice)...'**
  String get buyerSearchProduceHint;

  /// No description provided for @noProduceAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Produce Listings Available'**
  String get noProduceAvailable;

  /// No description provided for @orderDirect.
  ///
  /// In en, this message translates to:
  /// **'Order Direct'**
  String get orderDirect;

  /// No description provided for @uploadProducePhotos.
  ///
  /// In en, this message translates to:
  /// **'Produce Photos (produce-images)'**
  String get uploadProducePhotos;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @farmerMapHeader.
  ///
  /// In en, this message translates to:
  /// **'FARMERS REQUIRED PRODUCTS, SEEDS, MACHINERY & SERVICES NEAR ME'**
  String get farmerMapHeader;

  /// No description provided for @farmerNearbyRentals.
  ///
  /// In en, this message translates to:
  /// **'NEARBY EQUIPMENT & DRONE RENTALS'**
  String get farmerNearbyRentals;

  /// No description provided for @farmerEscrowGuaranteed.
  ///
  /// In en, this message translates to:
  /// **'Escrow Guaranteed'**
  String get farmerEscrowGuaranteed;

  /// No description provided for @farmerBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get farmerBookNow;

  /// No description provided for @farmerBookItem.
  ///
  /// In en, this message translates to:
  /// **'Book Item'**
  String get farmerBookItem;

  /// No description provided for @farmerViewAllEquipmentMap.
  ///
  /// In en, this message translates to:
  /// **'View All Farm Resources & Live Map →'**
  String get farmerViewAllEquipmentMap;

  /// No description provided for @farmerEquipmentBooked.
  ///
  /// In en, this message translates to:
  /// **'Equipment Booked!'**
  String get farmerEquipmentBooked;

  /// No description provided for @farmerBookingQuantity.
  ///
  /// In en, this message translates to:
  /// **'Booking Duration / Quantity'**
  String get farmerBookingQuantity;

  /// No description provided for @farmerDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Farm Delivery / Work Site Address'**
  String get farmerDeliveryAddress;

  /// No description provided for @farmerSpecialNotes.
  ///
  /// In en, this message translates to:
  /// **'Work Instructions / Crop Notes (Optional)'**
  String get farmerSpecialNotes;

  /// No description provided for @farmerVendorHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Equipment & Machinery Vendor Hub'**
  String get farmerVendorHubTitle;

  /// No description provided for @farmerAddEquipment.
  ///
  /// In en, this message translates to:
  /// **'Add Equipment'**
  String get farmerAddEquipment;

  /// No description provided for @farmTraceabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm Quality Traceability Verified'**
  String get farmTraceabilityTitle;

  /// No description provided for @traceabilityCropItem.
  ///
  /// In en, this message translates to:
  /// **'Crop Item:'**
  String get traceabilityCropItem;

  /// No description provided for @traceabilityFarmerOrigin.
  ///
  /// In en, this message translates to:
  /// **'Farmer Origin:'**
  String get traceabilityFarmerOrigin;

  /// No description provided for @traceabilityHarvestTime.
  ///
  /// In en, this message translates to:
  /// **'Harvest Time:'**
  String get traceabilityHarvestTime;

  /// No description provided for @traceabilityCertification.
  ///
  /// In en, this message translates to:
  /// **'Organic Certification:'**
  String get traceabilityCertification;

  /// No description provided for @traceabilityFarmingMethod.
  ///
  /// In en, this message translates to:
  /// **'Farming Method:'**
  String get traceabilityFarmingMethod;

  /// No description provided for @traceabilityQualityNotes.
  ///
  /// In en, this message translates to:
  /// **'Quality Notes:'**
  String get traceabilityQualityNotes;

  /// No description provided for @closeTraceability.
  ///
  /// In en, this message translates to:
  /// **'Close Traceability Details'**
  String get closeTraceability;

  /// No description provided for @produceFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters & Sorting'**
  String get produceFiltersTitle;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get clearFilters;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @maxDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance'**
  String get maxDistance;

  /// No description provided for @minFarmerRating.
  ///
  /// In en, this message translates to:
  /// **'Farmer Rating'**
  String get minFarmerRating;

  /// No description provided for @freshnessFilter.
  ///
  /// In en, this message translates to:
  /// **'Harvest Freshness'**
  String get freshnessFilter;

  /// No description provided for @fulfillmentOptions.
  ///
  /// In en, this message translates to:
  /// **'Fulfillment & Availability'**
  String get fulfillmentOptions;

  /// No description provided for @deliveryAvailableOnly.
  ///
  /// In en, this message translates to:
  /// **'Doorstep Delivery Available'**
  String get deliveryAvailableOnly;

  /// No description provided for @walkInStoreOnly.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Store / Farm Depot Pickup'**
  String get walkInStoreOnly;

  /// No description provided for @organicCertifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Organic Certificate Validated Only'**
  String get organicCertifiedOnly;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @customerProduceMapTitle.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER REQUIRED FARM PRODUCE, ORGANIC SELLERS & OUTLETS NEAR ME'**
  String get customerProduceMapTitle;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cartTitle;

  /// No description provided for @cartClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get cartClear;

  /// No description provided for @clearCartConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart?'**
  String get clearCartConfirmTitle;

  /// No description provided for @clearCartConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all items from your cart?'**
  String get clearCartConfirmBody;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Cart is Empty'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore fresh organic vegetables, fruits, and dairy directly from local verified farmers.'**
  String get cartEmptySubtitle;

  /// No description provided for @exploreProduce.
  ///
  /// In en, this message translates to:
  /// **'Explore Farm Produce'**
  String get exploreProduce;

  /// No description provided for @multiFarmerSplitNotice.
  ///
  /// In en, this message translates to:
  /// **'Items from multiple farmers will be placed as separate direct orders for fresh dispatch.'**
  String get multiFarmerSplitNotice;

  /// No description provided for @farmerOrderHeader.
  ///
  /// In en, this message translates to:
  /// **'Direct Farm Order'**
  String get farmerOrderHeader;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm Order Subtotal'**
  String get subtotalLabel;

  /// No description provided for @redeemRewardCredits.
  ///
  /// In en, this message translates to:
  /// **'Reward Credits (Demo mode)'**
  String get redeemRewardCredits;

  /// No description provided for @rewardDiscountDesc.
  ///
  /// In en, this message translates to:
  /// **'Apply 5% loyalty discount (up to ₹50)'**
  String get rewardDiscountDesc;

  /// No description provided for @billSummary.
  ///
  /// In en, this message translates to:
  /// **'Bill Summary'**
  String get billSummary;

  /// No description provided for @itemTotal.
  ///
  /// In en, this message translates to:
  /// **'Items Total'**
  String get itemTotal;

  /// No description provided for @rewardCreditsDiscount.
  ///
  /// In en, this message translates to:
  /// **'Reward Discount'**
  String get rewardCreditsDiscount;

  /// No description provided for @escrowProtectionBadge.
  ///
  /// In en, this message translates to:
  /// **'Escrow Protection Guarantee'**
  String get escrowProtectionBadge;

  /// No description provided for @includedLabel.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get includedLabel;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalPayable;

  /// No description provided for @proceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get proceedToCheckout;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Farm Checkout'**
  String get checkoutTitle;

  /// No description provided for @stepSlot.
  ///
  /// In en, this message translates to:
  /// **'1. Delivery Slot'**
  String get stepSlot;

  /// No description provided for @stepAddress.
  ///
  /// In en, this message translates to:
  /// **'2. Address'**
  String get stepAddress;

  /// No description provided for @stepPayment.
  ///
  /// In en, this message translates to:
  /// **'3. Payment'**
  String get stepPayment;

  /// No description provided for @doorstepDelivery.
  ///
  /// In en, this message translates to:
  /// **'Doorstep Delivery'**
  String get doorstepDelivery;

  /// No description provided for @farmPickup.
  ///
  /// In en, this message translates to:
  /// **'Farm Pickup'**
  String get farmPickup;

  /// No description provided for @selectDeliveryWindow.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred harvest and arrival window'**
  String get selectDeliveryWindow;

  /// No description provided for @noSlotsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No active slots available for this farm.'**
  String get noSlotsAvailable;

  /// No description provided for @slotSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same Day'**
  String get slotSameDay;

  /// No description provided for @slotNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next Day'**
  String get slotNextDay;

  /// No description provided for @slotPreOrder.
  ///
  /// In en, this message translates to:
  /// **'Pre-Order'**
  String get slotPreOrder;

  /// No description provided for @slotFullLabel.
  ///
  /// In en, this message translates to:
  /// **'Slot Full (0 remaining)'**
  String get slotFullLabel;

  /// No description provided for @slotsRemaining.
  ///
  /// In en, this message translates to:
  /// **'slots available'**
  String get slotsRemaining;

  /// No description provided for @farmPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Farm Pickup Location'**
  String get farmPickupLocation;

  /// No description provided for @deliveryAddressHeader.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddressHeader;

  /// No description provided for @farmPickupNotice.
  ///
  /// In en, this message translates to:
  /// **'Pick up directly at the farm packhouse. Bring your order confirmation code.'**
  String get farmPickupNotice;

  /// No description provided for @fullAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Street Address / Door No.'**
  String get fullAddressLabel;

  /// No description provided for @deliveryNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery instructions (Optional)'**
  String get deliveryNotesLabel;

  /// No description provided for @contactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone Number'**
  String get contactPhoneLabel;

  /// No description provided for @paymentDemoModeNotice.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — Simulated payment checkout with instant verification.'**
  String get paymentDemoModeNotice;

  /// No description provided for @escrowProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'100% Escrow Protection Guarantee'**
  String get escrowProtectionTitle;

  /// No description provided for @escrowProtectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payment is held safely until you receive and verify produce quality.'**
  String get escrowProtectionSubtitle;

  /// No description provided for @paymentMethodHeader.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get paymentMethodHeader;

  /// No description provided for @itemsTotal.
  ///
  /// In en, this message translates to:
  /// **'Items Total'**
  String get itemsTotal;

  /// No description provided for @rewardDiscount.
  ///
  /// In en, this message translates to:
  /// **'Reward Discount'**
  String get rewardDiscount;

  /// No description provided for @escrowFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Escrow Protection Fee'**
  String get escrowFeeLabel;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get nextStep;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get confirmOrder;

  /// No description provided for @orderConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed'**
  String get orderConfirmedTitle;

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order Placed Successfully!'**
  String get orderPlacedSuccessfully;

  /// No description provided for @escrowProtectedHeader.
  ///
  /// In en, this message translates to:
  /// **'Escrow Protected Payment'**
  String get escrowProtectedHeader;

  /// No description provided for @escrowProtectedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your payment remains safely locked in platform escrow until you inspect and verify freshness upon delivery.'**
  String get escrowProtectedNotice;

  /// No description provided for @backToMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Back to Produce Marketplace'**
  String get backToMarketplace;

  /// No description provided for @pendingFarmerConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Pending Farmer Confirmation'**
  String get pendingFarmerConfirmation;

  /// No description provided for @orderCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Code'**
  String get orderCodeLabel;

  /// No description provided for @farmerDeliverySlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm Delivery & Pickup Slots'**
  String get farmerDeliverySlotsTitle;

  /// No description provided for @addSlotButton.
  ///
  /// In en, this message translates to:
  /// **'+ Add Delivery Slot'**
  String get addSlotButton;

  /// No description provided for @noSlotsConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'No Delivery Slots Configured'**
  String get noSlotsConfiguredTitle;

  /// No description provided for @noSlotsConfiguredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create delivery or pickup windows so buyers can select convenient harvest delivery times.'**
  String get noSlotsConfiguredSubtitle;

  /// No description provided for @createFirstSlot.
  ///
  /// In en, this message translates to:
  /// **'Create First Slot'**
  String get createFirstSlot;

  /// No description provided for @createDeliverySlotModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Delivery Window Slot'**
  String get createDeliverySlotModalTitle;

  /// No description provided for @saveSlotButton.
  ///
  /// In en, this message translates to:
  /// **'Save Delivery Slot'**
  String get saveSlotButton;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to Cart'**
  String get addedToCart;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get viewCart;

  /// No description provided for @liveOrderTimeline.
  ///
  /// In en, this message translates to:
  /// **'Live Order Timeline'**
  String get liveOrderTimeline;

  /// No description provided for @orderCancelledRefundedNotice.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled. Escrow payment has been refunded to your wallet.'**
  String get orderCancelledRefundedNotice;

  /// No description provided for @orderDisputeNotice.
  ///
  /// In en, this message translates to:
  /// **'Dispute open. Escrow release is frozen pending resolution.'**
  String get orderDisputeNotice;

  /// No description provided for @orderStagePlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderStagePlaced;

  /// No description provided for @orderStagePlacedSub.
  ///
  /// In en, this message translates to:
  /// **'Escrow funds held safely'**
  String get orderStagePlacedSub;

  /// No description provided for @orderStageAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted by Farmer'**
  String get orderStageAccepted;

  /// No description provided for @orderStageAcceptedSub.
  ///
  /// In en, this message translates to:
  /// **'Harvesting & sorting produce'**
  String get orderStageAcceptedSub;

  /// No description provided for @orderStagePacked.
  ///
  /// In en, this message translates to:
  /// **'Packed & Weighed'**
  String get orderStagePacked;

  /// No description provided for @orderStagePackedSub.
  ///
  /// In en, this message translates to:
  /// **'Quality checked & prepared for dispatch'**
  String get orderStagePackedSub;

  /// No description provided for @orderStageReadyPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Farm Pickup'**
  String get orderStageReadyPickup;

  /// No description provided for @orderStageReadyPickupSub.
  ///
  /// In en, this message translates to:
  /// **'Visit farm with your pickup code'**
  String get orderStageReadyPickupSub;

  /// No description provided for @orderStageOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get orderStageOutForDelivery;

  /// No description provided for @orderStageOutForDeliverySub.
  ///
  /// In en, this message translates to:
  /// **'On the way to your delivery address'**
  String get orderStageOutForDeliverySub;

  /// No description provided for @orderStagePickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up & Verified'**
  String get orderStagePickedUp;

  /// No description provided for @orderStageDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered & Verified'**
  String get orderStageDelivered;

  /// No description provided for @orderStageDeliveredSub.
  ///
  /// In en, this message translates to:
  /// **'Escrow released to farmer wallet'**
  String get orderStageDeliveredSub;

  /// No description provided for @statusReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get statusReadyForPickup;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get statusOutForDelivery;

  /// No description provided for @rateOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Fresh Produce'**
  String get rateOrderTitle;

  /// No description provided for @selectProduceTags.
  ///
  /// In en, this message translates to:
  /// **'Produce Quality Highlights:'**
  String get selectProduceTags;

  /// No description provided for @orderReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about the freshness, taste, and packaging...'**
  String get orderReviewHint;

  /// No description provided for @submitReviewButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Produce Review'**
  String get submitReviewButton;

  /// No description provided for @reportOrderIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Order Issue / Dispute'**
  String get reportOrderIssue;

  /// No description provided for @disputeEscrowFreezeNotice.
  ///
  /// In en, this message translates to:
  /// **'Escrow fund release will be frozen until our support team verifies the produce quality issue.'**
  String get disputeEscrowFreezeNotice;

  /// No description provided for @selectIssueType.
  ///
  /// In en, this message translates to:
  /// **'Select Issue Category:'**
  String get selectIssueType;

  /// No description provided for @describeIssueDetails.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened:'**
  String get describeIssueDetails;

  /// No description provided for @disputeDetailsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 kg tomatoes arrived crushed and leaking...'**
  String get disputeDetailsPlaceholder;

  /// No description provided for @submitDisputeCTA.
  ///
  /// In en, this message translates to:
  /// **'Freeze Escrow & Open Dispute'**
  String get submitDisputeCTA;

  /// No description provided for @orderTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Tracking'**
  String get orderTrackingTitle;

  /// No description provided for @confirmDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery Receipt?'**
  String get confirmDeliveryTitle;

  /// No description provided for @confirmDeliveryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Have you received your complete produce order in good condition? This will release the escrow payment to the farmer.'**
  String get confirmDeliveryPrompt;

  /// No description provided for @confirmReceivedButton.
  ///
  /// In en, this message translates to:
  /// **'Yes, I Received It'**
  String get confirmReceivedButton;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Produce Order?'**
  String get cancelOrderTitle;

  /// No description provided for @cancelOrderPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order? Any reserved stock will be released and held escrow will be refunded to your wallet.'**
  String get cancelOrderPrompt;

  /// No description provided for @noKeepOrder.
  ///
  /// In en, this message translates to:
  /// **'No, Keep Order'**
  String get noKeepOrder;

  /// No description provided for @yesCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel Order'**
  String get yesCancelOrder;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get orderNotFound;

  /// No description provided for @farmPickupCodeHeader.
  ///
  /// In en, this message translates to:
  /// **'Farm Pickup Verification Code'**
  String get farmPickupCodeHeader;

  /// No description provided for @deliveryPinHeader.
  ///
  /// In en, this message translates to:
  /// **'Delivery Handover PIN'**
  String get deliveryPinHeader;

  /// No description provided for @showPickupCodeFarmerNote.
  ///
  /// In en, this message translates to:
  /// **'Show this 4-digit code to the farmer when picking up your crate.'**
  String get showPickupCodeFarmerNote;

  /// No description provided for @showDeliveryPinDriverNote.
  ///
  /// In en, this message translates to:
  /// **'Share this code with the driver upon delivery to verify handoff.'**
  String get showDeliveryPinDriverNote;

  /// No description provided for @estimatedArrivalHeader.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival & Window'**
  String get estimatedArrivalHeader;

  /// No description provided for @orderItemsHeader.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItemsHeader;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount Paid:'**
  String get totalAmount;

  /// No description provided for @confirmDeliveryReceivedButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order Received & Release Funds'**
  String get confirmDeliveryReceivedButton;

  /// No description provided for @releaseFundsNotice.
  ///
  /// In en, this message translates to:
  /// **'Tapping confirm immediately releases funds from escrow to the farmer.'**
  String get releaseFundsNotice;

  /// No description provided for @reorderItemsButton.
  ///
  /// In en, this message translates to:
  /// **'Reorder All Items'**
  String get reorderItemsButton;

  /// No description provided for @rateProduceButton.
  ///
  /// In en, this message translates to:
  /// **'Rate Produce'**
  String get rateProduceButton;

  /// No description provided for @myFarmOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Farm Produce Orders'**
  String get myFarmOrdersTitle;

  /// No description provided for @allOrdersFilter.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get allOrdersFilter;

  /// No description provided for @activeFilter.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeFilter;

  /// No description provided for @completedFilter.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get completedFilter;

  /// No description provided for @cancelledFilter.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledFilter;

  /// No description provided for @reorderButton.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorderButton;

  /// No description provided for @noOrdersFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No Farm Orders Found'**
  String get noOrdersFoundTitle;

  /// No description provided for @noOrdersFoundSub.
  ///
  /// In en, this message translates to:
  /// **'You have not placed any produce orders in this view yet.'**
  String get noOrdersFoundSub;

  /// No description provided for @exploreProduceButton.
  ///
  /// In en, this message translates to:
  /// **'Explore Farm Produce'**
  String get exploreProduceButton;

  /// No description provided for @farmerOrderBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Order Board'**
  String get farmerOrderBoardTitle;

  /// No description provided for @trackOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrderButton;

  /// No description provided for @cancelOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order & Refund Escrow'**
  String get cancelOrderButton;

  /// No description provided for @disputeButton.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get disputeButton;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get statusPacked;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get statusDisputed;

  /// No description provided for @editFarmDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Farm Details'**
  String get editFarmDetails;

  /// No description provided for @editFarmDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update land area, soil, and crop specializations'**
  String get editFarmDetailsSubtitle;

  /// No description provided for @clusterVillageLabel.
  ///
  /// In en, this message translates to:
  /// **'Cluster / Village Location'**
  String get clusterVillageLabel;

  /// No description provided for @apmcMandiLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered APMC Mandi'**
  String get apmcMandiLabel;

  /// No description provided for @farmDetailsUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Farm details updated successfully'**
  String get farmDetailsUpdatedSuccess;

  /// No description provided for @selfDeclaredProfile.
  ///
  /// In en, this message translates to:
  /// **'SELF-DECLARED PROFILE'**
  String get selfDeclaredProfile;

  /// No description provided for @locationPinNotice.
  ///
  /// In en, this message translates to:
  /// **'Site address provided without GPS pin'**
  String get locationPinNotice;

  /// No description provided for @safetyHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety & Emergency Hub'**
  String get safetyHubTitle;

  /// No description provided for @emergencyContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContactsTitle;

  /// No description provided for @jobProtectionClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Protection Claim'**
  String get jobProtectionClaimTitle;

  /// No description provided for @notificationCentreTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Centre'**
  String get notificationCentreTitle;

  /// No description provided for @notifNewApplicantTitle.
  ///
  /// In en, this message translates to:
  /// **'New Job Applicant'**
  String get notifNewApplicantTitle;

  /// No description provided for @notifNewApplicantBody.
  ///
  /// In en, this message translates to:
  /// **'{worker} applied for {job}'**
  String notifNewApplicantBody(String worker, String job);

  /// No description provided for @notifApplicationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Update'**
  String get notifApplicationStatusTitle;

  /// No description provided for @notifApplicationStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Your application for {job} was updated to {status}'**
  String notifApplicationStatusBody(String job, String status);

  /// No description provided for @notifAssignmentStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Status Update'**
  String get notifAssignmentStatusTitle;

  /// No description provided for @notifAssignmentStatusBody.
  ///
  /// In en, this message translates to:
  /// **'{code} is now {status}'**
  String notifAssignmentStatusBody(String code, String status);

  /// No description provided for @notifNewOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'New Farm Produce Order'**
  String get notifNewOrderTitle;

  /// No description provided for @notifNewOrderBody.
  ///
  /// In en, this message translates to:
  /// **'New farm produce order {code} received'**
  String notifNewOrderBody(String code);

  /// No description provided for @notifOrderStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Produce Order Update'**
  String get notifOrderStatusTitle;

  /// No description provided for @notifOrderStatusBody.
  ///
  /// In en, this message translates to:
  /// **'{code} status updated to {status}'**
  String notifOrderStatusBody(String code, String status);

  /// No description provided for @notifPaymentReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get notifPaymentReceivedTitle;

  /// No description provided for @notifPaymentReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'Payment received: {amount}'**
  String notifPaymentReceivedBody(String amount);

  /// No description provided for @notifSosAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY SOS ALERT'**
  String get notifSosAlertTitle;

  /// No description provided for @notifSosAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS incident registered. Safety team alerted.'**
  String get notifSosAlertBody;

  /// No description provided for @notifClaimSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Protection Claim'**
  String get notifClaimSubmittedTitle;

  /// No description provided for @notifClaimSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Your claim for {type} was registered for review.'**
  String notifClaimSubmittedBody(String type);

  /// No description provided for @notifGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notifGeneralTitle;

  /// No description provided for @notifGeneralBody.
  ///
  /// In en, this message translates to:
  /// **'You have a new update in UdyogaSethu.'**
  String get notifGeneralBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'hi',
    'kn',
    'mr',
    'or',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
