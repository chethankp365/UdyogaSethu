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
  /// **'Farm Name'**
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
  /// **'Farm Area (Acres)'**
  String get acresLabel;

  /// No description provided for @soilTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Soil Type'**
  String get soilTypeLabel;

  /// No description provided for @soilPhLabel.
  ///
  /// In en, this message translates to:
  /// **'Soil pH (Optional)'**
  String get soilPhLabel;

  /// No description provided for @primaryCropsLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Crops'**
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
  /// **'Approved / Active'**
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
