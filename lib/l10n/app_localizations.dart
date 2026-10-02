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
  /// **'Wallet Balance: ₹{balance}'**
  String walletBalance(Object balance);

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
