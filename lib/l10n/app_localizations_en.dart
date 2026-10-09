// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'UdyogaSethu';

  @override
  String get taglinePart1 => 'Bridging Work.';

  @override
  String get taglinePart2 => 'Empowering Lives.';

  @override
  String get splashInitializing => 'Initializing UdyogaSethu...';

  @override
  String get chipAiMatching => 'AI Matching';

  @override
  String get chipSecure => 'Secure';

  @override
  String get chipVerified => 'Verified';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get introSkip => 'Skip';

  @override
  String get introHeadline => 'Built for India. For Every Worker.';

  @override
  String get introSubtitle =>
      'Find jobs, grow skills, earn better and live with dignity.';

  @override
  String get introFeature1Title => 'Find Jobs Near You';

  @override
  String get introFeature2Title => 'Secure Payments';

  @override
  String get introFeature3Title => 'AI Voice Assistant';

  @override
  String get introNext => 'Next ->';

  @override
  String get introGetStarted => 'Get Started ->';

  @override
  String get languageScreenTitle => 'Choose your language';

  @override
  String get languageScreenSubtitle =>
      'We will show everything in your language';

  @override
  String listenToWelcomeIn(Object language) {
    return 'Listen to welcome in $language';
  }

  @override
  String ttsVoiceMissingHint(Object language) {
    return 'Voice engine for $language is not installed. Tap to open Text-to-Speech settings.';
  }

  @override
  String get welcomeSpeechSentence =>
      'Welcome to UdyogaSethu. Connecting work and empowering lives.';

  @override
  String get continueButton => 'Continue ->';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get retry => 'Retry';

  @override
  String get apply => 'Apply';

  @override
  String get submit => 'Submit';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get logout => 'Log Out';

  @override
  String get navHome => 'Home';

  @override
  String get navJobs => 'Jobs';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get navWorkers => 'Workers';

  @override
  String get navMarketplace => 'Marketplace';

  @override
  String get navMandi => 'Mandi';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navSettings => 'Settings';

  @override
  String get navSafety => 'Safety';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusBusy => 'Busy';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusNotStarted => 'Not Started';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusReviewRequired => 'Review Required';

  @override
  String get statusActive => 'Active';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get roleSeeker => 'Job Seeker';

  @override
  String get roleProvider => 'Job Provider';

  @override
  String get roleFarmer => 'Farmer';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get seekerTypeInformal => 'Informal Worker';

  @override
  String get seekerTypeStudent => 'Student';

  @override
  String get seekerTypePartTime => 'Part-Time Worker';

  @override
  String get providerTypeHousehold => 'Household';

  @override
  String get providerTypeEmployer => 'Business / Employer';

  @override
  String get docTypeAadhaar => 'Aadhaar Card';

  @override
  String get docTypePan => 'PAN Card';

  @override
  String get docTypeDrivingLicence => 'Driving Licence';

  @override
  String get docTypeBankAccount => 'Bank Account / UPI';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhone => 'Enter your 10-digit mobile number';

  @override
  String get otpCode => 'Verification Code';

  @override
  String enterOtp(Object phone) {
    return 'Enter the 6-digit OTP sent to $phone';
  }

  @override
  String get fullName => 'Full Name';

  @override
  String get enterName => 'Enter your full name';

  @override
  String get city => 'City';

  @override
  String get pincode => 'PIN Code';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidPhone => 'Please enter a valid 10-digit mobile number';

  @override
  String get invalidOtp => 'Please enter a valid 6-digit OTP';

  @override
  String get errorNetworkOffline =>
      'No internet connection. Please check your network.';

  @override
  String get errorTimeout => 'Request timed out. Please try again.';

  @override
  String get errorAuthGeneral => 'Authentication failed. Please try again.';

  @override
  String get errorDatabase => 'Database error occurred.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get errorEdgeFunction => 'Service request failed.';

  @override
  String amountRupees(Object amount) {
    return '₹$amount';
  }

  @override
  String wagePerDay(Object amount) {
    return '₹$amount/day';
  }

  @override
  String wagePerHour(Object amount) {
    return '₹$amount/hr';
  }

  @override
  String get wageTypeDaily => 'Daily Wage';

  @override
  String get wageTypeHourly => 'Hourly Wage';

  @override
  String get wageTypeFixed => 'Fixed Payment';

  @override
  String get walletBalance => 'Wallet Balance';

  @override
  String jobsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs found',
      one: '1 job found',
      zero: 'No jobs found',
    );
    return '$_temp0';
  }

  @override
  String applicantsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applicants',
      one: '1 applicant',
      zero: 'No applicants',
    );
    return '$_temp0';
  }

  @override
  String distanceKm(Object distance) {
    return '$distance km away';
  }

  @override
  String get todayGoal => 'Today\'s Goal';

  @override
  String get activeJobs => 'Active Jobs';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get viewAll => 'View All';

  @override
  String get roleTreeTitleStep1 => 'Who are you?';

  @override
  String get roleTreeSubtitleStep1 =>
      'Select your account category to get started.';

  @override
  String get roleTreeTitleStep2 => 'What do you want to do?';

  @override
  String get roleTreeSubtitleStep2 => 'Choose your role on UdyogaSethu.';

  @override
  String get roleTreeTitleStep3 => 'Tell us about you';

  @override
  String get roleTreeSubtitleStep3 =>
      'Select the type of work that matches your schedule.';

  @override
  String get roleCategoryWorker => 'Worker';

  @override
  String get roleCategoryWorkerDesc =>
      'Find daily-wage work, part-time jobs, or hire workers';

  @override
  String get roleCategoryFarmer => 'Farmer';

  @override
  String get roleCategoryFarmerDesc =>
      'Sell crops directly to buyers without middleman cuts';

  @override
  String get roleSeekerTitle => 'Job Seeker';

  @override
  String get roleSeekerDesc =>
      'Find daily-wage and part-time work with instant pay';

  @override
  String get roleProviderTitle => 'Job Provider';

  @override
  String get roleProviderDesc =>
      'Post jobs, hire verified workers, buy fresh produce';

  @override
  String get seekerTypeInformalTitle => 'Informal / Daily-wage Worker';

  @override
  String get seekerTypeInformalDesc =>
      'Find construction, delivery, plumbing jobs & instant UPI pay';

  @override
  String get seekerTypeStudentTitle => 'Student';

  @override
  String get seekerTypeStudentDesc =>
      'Part-time shifts fitted around study schedule';

  @override
  String get seekerTypePartTimeTitle => 'Part-time / Flexible Worker';

  @override
  String get seekerTypePartTimeDesc => 'Flexible daily or weekend shifts';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginLink => 'Log in';

  @override
  String listenToStepOptions(Object language) {
    return 'Listen to options in $language';
  }

  @override
  String get breadcrumbWorker => 'Worker';

  @override
  String get breadcrumbSeeker => 'Worker > Job Seeker';

  @override
  String get loginTitle => 'Mobile Number Login';

  @override
  String get loginSubtitle =>
      'Enter 10-digit mobile number for instant SMS login.';

  @override
  String get phoneInputLabel => 'MOBILE PHONE NUMBER';

  @override
  String get phonePrefix => 'IN +91';

  @override
  String get getOtpCode => 'Get SMS OTP Verification Code';

  @override
  String get agreeTermsDisclaimer =>
      'I agree to the Terms of Service and Privacy Policy';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleSignInNotice =>
      'Google sign-in will be enabled in Phase 2.5';

  @override
  String get otpTitle => 'Enter Verification Code';

  @override
  String otpSubtitle(Object maskedPhone) {
    return 'Enter 6-digit OTP sent to +91 $maskedPhone';
  }

  @override
  String get verifyAndLogin => 'Verify & Login';

  @override
  String resendCodeIn(Object seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get resendCode => 'Resend Code';

  @override
  String get maxResendsReached => 'Maximum 3 resends reached for this session.';

  @override
  String get changeNumber => 'Change number';

  @override
  String get invalidOtpError =>
      'Invalid or expired verification code. Please check the 6-digit code and try again.';

  @override
  String get rateLimitError =>
      'Too many OTP requests. Please wait a moment before trying again.';

  @override
  String get termsRequiredError =>
      'Please accept the Terms of Service to proceed.';

  @override
  String get googleSignInFailed => 'Google sign-in failed. Please try again.';

  @override
  String get googleEmailAlreadyLinked =>
      'This email is already linked to another number.';

  @override
  String get verifyPhoneTitle => 'Verify your mobile number';

  @override
  String get verifyPhoneSubtitle =>
      'Add a verified mobile number to complete your registration.';

  @override
  String get linkGoogleAccount => 'Link Google Account';

  @override
  String get googleAccountLinked => 'Google account linked successfully.';

  @override
  String get googlePlayServicesMissing =>
      'Google Play Services is unavailable on this device.';

  @override
  String wizardStepProgress(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get wizardStep1Title => 'Basics';

  @override
  String get wizardStep1Subtitle =>
      'Enter your name, photo, gender, and languages.';

  @override
  String get wizardStep2Title => 'Skills & Interests';

  @override
  String get wizardStep2Subtitle => 'Select your skills or academic interests.';

  @override
  String get wizardStep3Title => 'Experience & Rate';

  @override
  String get wizardStep3Subtitle =>
      'Set your experience years and expected rates.';

  @override
  String get wizardStep4Title => 'Availability';

  @override
  String get wizardStep4Subtitle => 'Set your status, working days, and hours.';

  @override
  String get wizardStep5Title => 'Location';

  @override
  String get wizardStep5Subtitle =>
      'Grant location access and set your service radius.';

  @override
  String get wizardStep6Title => 'Type Specific Details';

  @override
  String get wizardStep6Subtitle =>
      'Enter details for your worker profile type.';

  @override
  String get wizardStep7Title => 'Review & Finish';

  @override
  String get wizardStep7Subtitle =>
      'Review your profile details before finishing.';

  @override
  String get takePhotoCamera => 'Take Photo (Camera)';

  @override
  String get chooseGallery => 'Choose from Gallery';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get uploadingPhoto => 'Uploading photo...';

  @override
  String get uploadPhotoError => 'Photo upload failed. Tap to retry.';

  @override
  String get genderLabel => 'Gender (Optional)';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get genderPreferNot => 'Prefer not to say';

  @override
  String get languagesLabel => 'Languages Spoken';

  @override
  String get selectCategories => 'Select Categories';

  @override
  String get selectSkills => 'Select Skills';

  @override
  String get informalSkillRequired =>
      'Informal workers must select at least 1 skill.';

  @override
  String get addSubjectOrInterest => 'Add Subject / Interest';

  @override
  String get subjectsInterestsLabel => 'Subjects or Interests';

  @override
  String get experienceYearsLabel => 'Years of Experience';

  @override
  String get dailyRateLabel => 'Expected Daily Rate (₹)';

  @override
  String get hourlyRateLabel => 'Expected Hourly Rate (₹)';

  @override
  String wageBandHint(Object max, Object min, Object unit) {
    return 'Suggested fair wage band: ₹$min - ₹$max / $unit';
  }

  @override
  String get workingDaysLabel => 'Working Days';

  @override
  String get workHoursLabel => 'Working Hours';

  @override
  String get studentWeeklyHoursLabel => 'Preferred Weekly Hours';

  @override
  String get partTimeShiftLabel => 'Preferred Shift Slot';

  @override
  String get shiftMorning => 'Morning Shift (6 AM - 2 PM)';

  @override
  String get shiftEvening => 'Evening Shift (2 PM - 10 PM)';

  @override
  String get shiftFlexible => 'Flexible Shift';

  @override
  String get locationConsentTitle => 'Just-in-Time Location Access';

  @override
  String get locationConsentText =>
      'UdyogaSethu uses your GPS location to match you with nearby jobs, calculate distance, and ensure site safety. Your location is logged only when active.';

  @override
  String get allowLocationAccess => 'Allow Location Access';

  @override
  String get locationPermissionDenied =>
      'Location permission denied. Please grant permission in settings or pick on map.';

  @override
  String get addressLabel => 'Home Address / Locality';

  @override
  String serviceRadiusLabel(Object radius) {
    return 'Service Radius: $radius km';
  }

  @override
  String get collegeNameLabel => 'College / University Name';

  @override
  String get courseNameLabel => 'Course / Degree';

  @override
  String get regNoLabel => 'Registration / USN No. (Stored Masked)';

  @override
  String get doYouDriveToggle => 'Do you drive a vehicle?';

  @override
  String get drivingLicenceExplanation =>
      'Note: A valid driving licence will be required for driving and delivery jobs in Phase 3.';

  @override
  String get reviewSummaryTitle => 'Profile Summary';

  @override
  String get finishProfileButton => 'Finish Profile & Go to Home';

  @override
  String get verifyIdentityPrompt =>
      'Please complete identity verification to unlock high-pay jobs!';

  @override
  String get quitAndResumeNotice =>
      'Draft saved automatically. You can resume anytime.';

  @override
  String get farmerWizardTitle => 'Farmer Profile Setup';

  @override
  String get farmerStep1Title => 'Basics';

  @override
  String get farmerStep1Subtitle =>
      'Enter your full name, photo, and spoken languages.';

  @override
  String get farmerStep2Title => 'Farm Details';

  @override
  String get farmerStep2Subtitle =>
      'Set your farm name, location, acres, soil type, and primary crops.';

  @override
  String get farmerStep3Title => 'Registrations & Badges';

  @override
  String get farmerStep3Subtitle =>
      'Add optional government registrations and certificates for profile badges.';

  @override
  String get farmerStep4Title => 'Selling Options';

  @override
  String get farmerStep4Subtitle =>
      'Set your produce pickup availability, delivery radius, and lead time.';

  @override
  String get farmerStep5Title => 'Review & Finish';

  @override
  String get farmerStep5Subtitle =>
      'Verify your farm profile details before completing setup.';

  @override
  String get farmNameLabel => 'Farm Name';

  @override
  String get farmNameHint => 'e.g. Green Valley Organic Farm';

  @override
  String get villageClusterLabel => 'Village / Cluster Name';

  @override
  String get villageClusterHint => 'e.g. Devanahalli, Bengaluru Rural';

  @override
  String get farmLocationLabel => 'Farm Location on Map';

  @override
  String get acresLabel => 'Farm Area (Acres)';

  @override
  String get soilTypeLabel => 'Soil Type';

  @override
  String get soilPhLabel => 'Soil pH (Optional)';

  @override
  String get primaryCropsLabel => 'Primary Crops';

  @override
  String get farmingMethodLabel => 'Farming Method';

  @override
  String get methodOrganic => 'Organic';

  @override
  String get methodNatural => 'Natural / Zero Budget';

  @override
  String get methodConventional => 'Conventional';

  @override
  String get apmcRegLabel => 'APMC Registration Number (Optional)';

  @override
  String get apmcRegHint => 'e.g. APMC-KA-2024-889';

  @override
  String get kccStatusLabel => 'Kisan Credit Card (KCC) Status';

  @override
  String get kccNone => 'Not Applied';

  @override
  String get kccApplied => 'Applied';

  @override
  String get kccApproved => 'KCC Approved ✓';

  @override
  String get organicCertLabel => 'Organic Certificate Upload (Optional)';

  @override
  String get organicCertHelper =>
      'Uploaded files are saved in private secure storage and marked as pending review.';

  @override
  String get farmBadgesTitle => 'Farm Profile Badges';

  @override
  String get deliveryAvailableLabel => 'Delivery Available';

  @override
  String get pickupAvailableLabel => 'Pickup Available';

  @override
  String deliveryRadiusLabel(Object radius) {
    return 'Delivery Radius: $radius km';
  }

  @override
  String get leadTimeLabel => 'Typical Lead Time';

  @override
  String get apmcBadgeTitle => 'APMC Registered';

  @override
  String get kccBadgeTitle => 'Kisan Credit Card';

  @override
  String get organicBadgeTitle => 'Organic Certificate (Pending Review)';

  @override
  String get uploadCertButton => 'Upload Organic Certificate (PDF / Image)';

  @override
  String get certUploadedPending => 'Certificate uploaded (Pending Review)';

  @override
  String get providerWizardTitle => 'Job Provider Setup';

  @override
  String get providerStep1Title => 'Basics';

  @override
  String get providerStep1Subtitle =>
      'Enter your full name, photo, and spoken languages.';

  @override
  String get providerStep2Title => 'Provider Category';

  @override
  String get providerStep2Subtitle =>
      'Select whether you hire as a Household or Employer/Contractor.';

  @override
  String get providerStep3HouseholdTitle => 'Doorstep Address & Delivery';

  @override
  String get providerStep3HouseholdSubtitle =>
      'Set default doorstep delivery address and delivery preferences.';

  @override
  String get providerStep3EmployerTitle => 'Organisation & Site Details';

  @override
  String get providerStep3EmployerSubtitle =>
      'Set organisation name, primary site address, hiring categories, and crew size.';

  @override
  String get providerStep4Title => 'Permissions & Consents';

  @override
  String get providerStep4Subtitle =>
      'Review location and notification permissions with just-in-time explanations.';

  @override
  String get providerStep5Title => 'Review & Finish';

  @override
  String get providerStep5Subtitle =>
      'Verify your job provider profile details before completing setup.';

  @override
  String get doorstepAddressLabel => 'Flat / Door No. & Street';

  @override
  String get doorstepAddressHint => 'e.g. #402, Sunshine Apartments, 5th Cross';

  @override
  String get landmarkLabel => 'Landmark';

  @override
  String get landmarkHint => 'e.g. Near Metro Station';

  @override
  String get deliveryInstructionsLabel => 'Delivery Preferences & Instructions';

  @override
  String get deliveryInstructionsHint => 'e.g. Leave with security at gate';

  @override
  String get gateCodeLabel => 'Gate Code / Intercom (Optional)';

  @override
  String get gateCodeHint => 'e.g. 1234';

  @override
  String get orgNameLabel => 'Organisation / Business Name';

  @override
  String get orgNameHint => 'e.g. Sethu Construction & Infra Ltd';

  @override
  String get primarySiteAddressLabel => 'Primary Site Address';

  @override
  String get primarySiteAddressHint =>
      'e.g. Site 45, Peripheral Ring Road, Electronics City';

  @override
  String get categoriesHiringLabel => 'Categories Usually Hired For';

  @override
  String get typicalCrewSizeLabel => 'Typical Crew Size Needed';

  @override
  String crewSizeWorkers(Object count) {
    return '$count workers';
  }

  @override
  String get gpsConsentExplanation =>
      'UdyogaSethu needs GPS location to locate site delivery addresses and display local worker availability.';

  @override
  String get notificationsConsentExplanation =>
      'Enable push notifications to receive real-time updates on job applicants, worker arrivals, and delivery tracking.';

  @override
  String get grantGpsPermission => 'Grant Location Permission';

  @override
  String get grantNotificationsPermission => 'Grant Notifications Permission';

  @override
  String get permissionGranted => 'Permission Granted';

  @override
  String get providerHomeTitle => 'Provider Home';

  @override
  String get roleConflictTitle => 'Account Role Conflict';

  @override
  String roleConflictMessage(Object chosenRole, Object existingRole) {
    return 'This number is already registered as $existingRole. You cannot use it as $chosenRole. To use a different role, log in as $existingRole, go to Profile > Settings > Delete account, and then create a new account.';
  }

  @override
  String roleConflictLoginAs(Object existingRole) {
    return 'Log in as $existingRole';
  }

  @override
  String get roleConflictBack => 'Back';

  @override
  String get privacyCentreTitle => 'Privacy Centre';

  @override
  String get privacyCentreSubtitle =>
      'Manage your data consents, privacy rights, and system permissions.';

  @override
  String get consentSheetTitle => 'Data Processing Consent';

  @override
  String get consentWhatCollected => 'What is collected';

  @override
  String get consentWhyCollected => 'Why it is collected';

  @override
  String get consentHowLongKept => 'How long it is kept';

  @override
  String get consentWhoCanSee => 'Who can see it';

  @override
  String get consentHowToWithdraw => 'How to withdraw';

  @override
  String get consentAgreeButton => 'I Agree & Consent';

  @override
  String get consentNotNowButton => 'Not Now';

  @override
  String get consentGrantedStatus => 'Consent Granted';

  @override
  String get consentRevokedStatus => 'Not Granted / Withdrawn';

  @override
  String get withdrawConsentButton => 'Withdraw Consent';

  @override
  String get withdrawFaceConsentTitle => 'Withdraw Face Verification Consent?';

  @override
  String get withdrawFaceConsentMessage =>
      'Withdrawing face consent will permanently erase your face reference vector and matcher records. You will need to re-enroll to use face-verified login.';

  @override
  String get confirmWithdrawButton => 'Withdraw & Erase Data';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get termsAndPrivacyTitle => 'Terms & Privacy Policy';

  @override
  String get termsDraftNotice =>
      'Draft - Have this reviewed before real launch';

  @override
  String get systemPermissionsTitle => 'System Permissions';

  @override
  String get openSystemSettings => 'Open App Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get faceVerificationCheck => 'Face Verification Check';

  @override
  String get faceCheckSubtext =>
      'Verify your identity using face liveness check';

  @override
  String get faceMatchSuccess => 'Face Identity Verified';

  @override
  String get faceMatchFailedTitle => 'Face Match Failed';

  @override
  String get faceMatchFailedBody =>
      'Position your face clearly in good lighting and try again.';

  @override
  String get manualReviewRequiredTitle => '3 Verification Attempts Failed';

  @override
  String get manualReviewRequiredBody =>
      'Your face verification has been submitted for manual review. You may continue with limited access.';

  @override
  String get requestManualReview => 'Request Manual Review';

  @override
  String get retryVerification => 'Try Verification Again';

  @override
  String get demoSimulatePass => 'Demo: Pass Verification';

  @override
  String get demoSimulateFail => 'Demo: Fail Verification';

  @override
  String get seekerHomeTitle => 'Seeker Home';

  @override
  String get searchJobsPlaceholder => 'Search jobs, services...';

  @override
  String get todaysGoal => 'Today\'s Goal';

  @override
  String get viewWallet => 'View Wallet >';

  @override
  String get locationSharingActive =>
      'Location sharing active for safety monitoring';

  @override
  String get changeLocation => 'Change >';

  @override
  String get quickActionsHeader => 'QUICK ACTIONS';

  @override
  String get actionNearbyJobs => 'Nearby Jobs';

  @override
  String get actionAiAssistant => 'AI Assistant';

  @override
  String get actionWallet => 'Wallet';

  @override
  String get actionSafetyHub => 'Safety Hub';

  @override
  String get tagSponsored => 'SPONSORED';

  @override
  String get whyAmISeeingThis => 'Why am I seeing this?';

  @override
  String get recommendedForYou => 'RECOMMENDED FOR YOU';

  @override
  String get applyNow => 'Apply Now';

  @override
  String get applied => 'Applied ✓';

  @override
  String get noJobsNearYou => 'No jobs near you yet';

  @override
  String get widenRadiusAction => 'Widen Search Radius';

  @override
  String get sosEmergencyPill => 'SOS';

  @override
  String get selectLocationArea => 'Select Location Area';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get studentsWelcomeChip => 'Students Welcome';

  @override
  String get flexibleShiftChip => 'Flexible Shift';

  @override
  String get nearbyJobsMapTitle => 'NEARBY DAILY WAGE JOBS & WORK SITES';

  @override
  String livePinsCount(Object count) {
    return '$count Live Pins';
  }

  @override
  String nearbyGpsPinListings(Object count) {
    return 'NEARBY GPS PIN LISTINGS ($count)';
  }

  @override
  String get tapPinOrCardToInspect => 'Tap pin or card to inspect';

  @override
  String get applyButton => 'Apply';

  @override
  String get categoryFilterAll => 'All';

  @override
  String get recenterMap => 'Recenter GPS';

  @override
  String get zoomIn => 'Zoom In';

  @override
  String get zoomOut => 'Zoom Out';

  @override
  String get gpsDisabledBanner =>
      'GPS is turned off. Turn on location for accurate distances.';

  @override
  String get locationPermissionDeniedBanner =>
      'Location permission not granted. Showing default area.';

  @override
  String get noJobsInArea => 'No work sites found in this radius';

  @override
  String get searchRadius => 'Search Radius';

  @override
  String radiusKm(Object radius) {
    return '$radius km';
  }

  @override
  String get openLocationSettings => 'Settings';

  @override
  String get loadJobsError =>
      'Unable to load nearby jobs. Check connection and tap Retry.';

  @override
  String get retryAction => 'Retry';

  @override
  String get openStreetMapAttribution => '© OpenStreetMap contributors';

  @override
  String get cameraPermissionTitle => 'Camera Access';

  @override
  String get cameraPermissionSubtitle =>
      'Used for face liveness verification and worker ID scanning.';

  @override
  String get locationPermissionTitle => 'Device Location (GPS)';

  @override
  String get locationPermissionSubtitle =>
      'Used to show nearby jobs, job route map, and work site attendance.';

  @override
  String get notificationPermissionTitle => 'Notifications';

  @override
  String get notificationPermissionSubtitle =>
      'Used for instant job alerts, payment updates, and safety alerts.';

  @override
  String get permissionAllowedStatus => 'Allowed';

  @override
  String get permissionBlockedStatus => 'Blocked / Off';

  @override
  String get refreshConsentsTooltip => 'Refresh Status';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabWorkShowcase => 'Work Showcase';

  @override
  String get tabSafetyStatus => 'Safety Status';

  @override
  String get verifiedJobsStat => 'Verified Jobs';

  @override
  String get ratingStat => 'Rating';

  @override
  String get totalEarningsStat => 'Total Earnings';

  @override
  String categoryPrefix(Object category) {
    return 'Category: $category';
  }

  @override
  String get roleCredentialsTitle => 'ROLE CREDENTIALS & CATEGORY BADGES';

  @override
  String get changeCategoryBtn => 'Change Category';

  @override
  String get changeCategoryTitle => 'Change Worker Category';

  @override
  String get changeCategorySubtitle =>
      'Select your work type to personalize jobs and verification';

  @override
  String get categoryInformalTitle => 'Informal / Skilled Worker';

  @override
  String get categoryInformalDesc =>
      'Trades, craftsmanship, home services & agricultural work';

  @override
  String get categoryStudentTitle => 'Student Gig Worker';

  @override
  String get categoryStudentDesc =>
      'Campus gigs, tutoring, creative design & online tasks';

  @override
  String get categoryPartTimeTitle => 'Part-Time Worker';

  @override
  String get categoryPartTimeDesc =>
      'Retail, restaurant service, flexible evening & weekend shifts';

  @override
  String get mySkillsTitle => 'MY SKILLS';

  @override
  String get addSkillBtn => '+ Add Skill';

  @override
  String get addSkillDialogTitle => 'Select a Skill';

  @override
  String get addSkillDialogSubtitle =>
      'Choose skills matching your work profile';

  @override
  String get languageAccessibilityTitle => 'LANGUAGE & ACCESSIBILITY';

  @override
  String get verificationStatusTitle => 'VERIFICATION STATUS';

  @override
  String get accountAndSafetyTitle => 'Account & Safety';

  @override
  String get emptyShowcaseTitle =>
      'Your completed jobs, photos and ratings will appear here';

  @override
  String get emptyShowcaseSubtitle =>
      'Once you complete jobs through UdyogaSethu, verified employer reviews, photos, and earnings will be showcased here.';

  @override
  String get browseJobsAction => 'Browse Jobs';

  @override
  String get safetyLifecycleTitle => 'Safety Onboarding & Badges';

  @override
  String get notVerifiedYet => 'Not verified yet';

  @override
  String get verifiedWorkerBadge => 'UDYOGASETHU VERIFIED ✓';

  @override
  String get dlVerified => 'Driving Licence Verified ✓';

  @override
  String get dlPending => 'Add Driving Licence';

  @override
  String get studentBadgeVerified => 'Student Status Verified ✓';

  @override
  String get studentBadgePending => 'Verify Student Status';

  @override
  String get bankUpiVerified => 'Bank / UPI Linked ✓';

  @override
  String get bankUpiPending => 'Link Bank / UPI';

  @override
  String get bgCheckVerified => 'Background Check Clear ✓';

  @override
  String get bgCheckPending => 'Pending Background Check';

  @override
  String get aadhaarVerified => 'Aadhaar eKYC Verified ✓';

  @override
  String get faceLivenessVerified => 'Face Liveness Verified ✓';

  @override
  String get safetyTrainingVerified => '1-Day Safety Training Completed ✓';

  @override
  String categoryUpdatedSnackbar(Object category) {
    return 'Category updated to $category! Feed and skills refreshed.';
  }

  @override
  String get providerMyJobsTitle => 'My Jobs';

  @override
  String get providerTabOpen => 'Open';

  @override
  String get providerTabFilled => 'Filled';

  @override
  String get providerTabCompleted => 'Completed';

  @override
  String providerSlotsCounter(int filled, int total) {
    return '$filled / $total Slots Filled';
  }

  @override
  String providerSlotsOpenCount(int count) {
    return '$count Open';
  }

  @override
  String get providerPostNewJob => 'Post a Job';

  @override
  String get providerNoJobsTitle => 'No Jobs Found';

  @override
  String get providerNoOpenJobsDesc =>
      'You don\'t have any open job postings. Create one to hire verified local workers.';

  @override
  String get providerNoFilledJobsDesc => 'No jobs are currently filled.';

  @override
  String get providerNoCompletedJobsDesc => 'No completed jobs yet.';

  @override
  String get providerViewApplicants => 'View Applicants';

  @override
  String providerApplicantsBadge(int count) {
    return '$count Applicants';
  }

  @override
  String get providerJobPaused => 'Paused';

  @override
  String get providerJobDraft => 'Draft';

  @override
  String get providerJobCancelled => 'Cancelled';

  @override
  String get providerActionEdit => 'Edit Posting';

  @override
  String get providerActionPause => 'Pause Posting';

  @override
  String get providerActionResume => 'Resume Posting';

  @override
  String get providerActionCancel => 'Cancel Job';

  @override
  String get providerCancelWarningTitle => 'Cancel Job Posting?';

  @override
  String providerCancelWarningHiredDesc(int count) {
    return 'Warning: This job has $count hired worker(s). Cancelling will immediately notify workers, cancel their assignments, and release escrow holds. This may negatively impact your employer reliability rating.';
  }

  @override
  String get providerCancelStandardDesc =>
      'Are you sure you want to cancel this job posting? Open slots will be removed.';

  @override
  String get providerConfirmCancel => 'Confirm Cancellation';

  @override
  String get providerJobCancelledSuccess => 'Job has been cancelled.';

  @override
  String get providerJobPausedSuccess => 'Job posting has been paused.';

  @override
  String get providerJobResumedSuccess => 'Job posting is now active.';

  @override
  String get postJobWizardTitle => 'Post a Daily Wage Job';

  @override
  String get editJobWizardTitle => 'Edit Job Posting';

  @override
  String get postJobStep1 => 'Category & Title';

  @override
  String get postJobStepAudience => 'Target Workers';

  @override
  String get postJobAudienceTitle => 'Who is this job for?';

  @override
  String get postJobAudienceSubtitle =>
      'Select matching worker categories who can see and apply for this job.';

  @override
  String get postJobAudienceInformal => 'Informal / Daily-wage Worker';

  @override
  String get postJobAudienceInformalHint =>
      'Day labourers, masons, loaders, construction, field hands';

  @override
  String get postJobAudienceStudent => 'Student';

  @override
  String get postJobAudienceStudentHint =>
      'College students looking for short, flexible evening or weekend tasks';

  @override
  String get postJobAudiencePartTime => 'Part-time / Flexible Worker';

  @override
  String get postJobAudiencePartTimeHint =>
      'Workers available for partial shifts or flexible timing';

  @override
  String get postJobAudienceRequired =>
      'Please select at least one worker type';

  @override
  String get hubConfirmedBookingEmptyTitle => 'No active bookings';

  @override
  String get hubConfirmedBookingEmptyDesc =>
      'Your confirmed worker assignments and live tracking will appear here.';

  @override
  String get hubLocationNotSet => 'Location not set';

  @override
  String get postJobStep2 => 'Wages & Schedule';

  @override
  String get postJobStep3 => 'Slots & Payment';

  @override
  String get postJobStep4 => 'Requirements & Location';

  @override
  String get postJobStep5 => 'Preview & Publish';

  @override
  String get postJobSelectCategory => 'Select Work Category';

  @override
  String get postJobTitleLabel => 'Job Title';

  @override
  String get postJobTitleHint =>
      'e.g., Construction Helper, Electrician, Plumber';

  @override
  String get postJobDescLabel => 'Job Description';

  @override
  String get postJobDescHint =>
      'Describe specific tasks, tools needed, or location details...';

  @override
  String get postJobWageType => 'Wage Type';

  @override
  String get postJobWageDaily => 'Daily';

  @override
  String get postJobWageHourly => 'Hourly';

  @override
  String get postJobWageFixed => 'Fixed';

  @override
  String get postJobAmountLabel => 'Wage Amount (₹)';

  @override
  String get postJobFairWageBandTitle => 'Fair Wage Band:';

  @override
  String postJobFairWageBandRange(int min, int max, String unit) {
    return '₹$min - ₹$max / $unit';
  }

  @override
  String postJobBelowFairWageWarning(int min, int max) {
    return 'Wage is below the recommended fair wage band (₹$min - ₹$max). Workers may be slower to apply, but you can still proceed.';
  }

  @override
  String get postJobDurationLabel => 'Estimated Duration';

  @override
  String postJobDurationHours(int hours) {
    return '$hours hours';
  }

  @override
  String get postJobStartDateLabel => 'Start Date & Time';

  @override
  String get postJobSelectDateTime => 'Select Date & Time';

  @override
  String get postJobSlotsTotalLabel => 'Number of Workers Needed (Slots)';

  @override
  String get postJobMaterialsLabel => 'Materials & Tools';

  @override
  String get postJobMaterialsProvided =>
      'I will provide all tools and materials';

  @override
  String get postJobMaterialsWorkerBrings =>
      'Worker should bring their own tools';

  @override
  String get postJobPaymentModeLabel => 'Payment Protection Mode';

  @override
  String get postJobPaymentEscrow => 'Protected Escrow (Recommended)';

  @override
  String get postJobPaymentEscrowDesc =>
      'Funds held securely until work is verified and approved';

  @override
  String get postJobPaymentUpi => 'Direct UPI on Completion';

  @override
  String get postJobPaymentUpiDesc => 'Pay directly to worker UPI QR on site';

  @override
  String get postJobPaymentCash => 'Daily Cash at Site';

  @override
  String get postJobPaymentCashDesc => 'Pay physical cash after shift ends';

  @override
  String get postJobRequirementsLabel => 'Worker Requirements';

  @override
  String get postJobReqVerifiedOnly => 'Background & Identity Verified Only';

  @override
  String get postJobReqLicence => 'Driving Licence Required';

  @override
  String get postJobReqStudents => 'Students & Part-Time Friendly';

  @override
  String get postJobLocationLabel => 'Work Site Location';

  @override
  String get postJobAddressHint => 'Enter site address or landmark';

  @override
  String get postJobGeofenceRadiusLabel => 'Geofence Check-in Radius';

  @override
  String postJobGeofenceMeters(int meters) {
    return '$meters meters';
  }

  @override
  String get postJobPublishButton => 'Publish Job Posting';

  @override
  String get postJobSaveEditButton => 'Save Changes';

  @override
  String get postJobPublishSuccess => 'Job posted successfully!';

  @override
  String applicantsScreenTitle(int count) {
    return 'Applicants ($count)';
  }

  @override
  String get applicantsNoApplicantsTitle => 'No Applications Yet';

  @override
  String get applicantsNoApplicantsDesc =>
      'Workers nearby are being notified. Applicants will appear here once they apply.';

  @override
  String applicantCardJobsDone(int count) {
    return '$count jobs done';
  }

  @override
  String applicantCardRating(double rating, int count) {
    return '$rating ($count)';
  }

  @override
  String applicantCardLanguages(String langs) {
    return 'Languages: $langs';
  }

  @override
  String applicantCardSkills(String skills) {
    return 'Skills: $skills';
  }

  @override
  String get applicantActionHire => 'Hire';

  @override
  String get applicantActionShortlist => 'Shortlist';

  @override
  String get applicantActionReject => 'Reject';

  @override
  String get applicantActionChat => 'Chat';

  @override
  String get applicantActionProfile => 'View Profile';

  @override
  String get applicantStatusApplied => 'Applied';

  @override
  String get applicantStatusShortlisted => 'Shortlisted';

  @override
  String get applicantStatusHired => 'Hired';

  @override
  String get applicantStatusRejected => 'Rejected';

  @override
  String get applicantHireConfirmTitle => 'Hire Worker?';

  @override
  String applicantHireConfirmDesc(String name) {
    return 'Hiring $name will assign them 1 slot on this job. They will receive a booking notification.';
  }

  @override
  String get applicantHiredSuccess =>
      'Worker hired successfully! Assignment created.';

  @override
  String get applicantShortlistedSuccess => 'Applicant moved to shortlist.';

  @override
  String get applicantRejectedSuccess => 'Application rejected.';

  @override
  String get applicantJobFullNotice => 'All slots for this job are filled.';

  @override
  String get hubTitle => 'Customer Hub';

  @override
  String get hubVerifiedAccount => 'Verified Account';

  @override
  String get hubTagline => 'Farm-Fresh Goods and Verified On-Demand Workers';

  @override
  String hubGreeting(String name) {
    return 'Hello, $name! 👋';
  }

  @override
  String get hubTabWorkers => 'Workers & Services';

  @override
  String get hubTabProduce => '🌾 Farm Produce';

  @override
  String get hubTabSubscriptions => 'Subscriptions';

  @override
  String get hubProduceComingSoon => 'Farm-Direct Produce Marketplace';

  @override
  String get hubProduceComingSoonDesc =>
      'Direct farm-fresh vegetables, organic produce, and pure dairy coming in Phase 6.';

  @override
  String get hubSubscriptionsComingSoon => 'Farm Produce & Milk Subscriptions';

  @override
  String get hubSubscriptionsComingSoonDesc =>
      'Daily milk deliveries and weekly organic vegetable baskets straight to your doorstep coming in Phase 6.';

  @override
  String get hubActionScanQr => 'Scan QR';

  @override
  String get hubActionNoShowHelp => 'No-Show Help';

  @override
  String get hubActionMilkBasket => 'Milk / Basket';

  @override
  String get hubActionFarmerChat => 'Farmer Chat';

  @override
  String hubConfirmedBooking(String code) {
    return 'CONFIRMED BOOKING • $code';
  }

  @override
  String get hubWorkerNotArrived => 'Worker Has Not Arrived';

  @override
  String get hubProtectedChat => 'Protected Chat';

  @override
  String get hubVerifiedWorkersTitle => 'VERIFIED ON-DEMAND LOCAL WORKERS';

  @override
  String get hub100AadhaarVerified => '100% Aadhaar Verified';

  @override
  String get hubBookWorker => 'Book Worker';

  @override
  String get hubSearchWorkers => 'Search Workers';

  @override
  String get hubSearchHint => 'Search by skill, distance, language...';

  @override
  String get hubViewAllWorkers => 'View All Workers';

  @override
  String get hubNoActiveBooking => 'No Active Booking Right Now';

  @override
  String get hubNoActiveBookingDesc =>
      'Book a verified worker or post a job to see active shift status here.';

  @override
  String get workerFilterTitle => 'Filter Workers';

  @override
  String get workerFilterCategory => 'Service Category';

  @override
  String get workerFilterAllCategories => 'All Categories';

  @override
  String get workerFilterDistance => 'Maximum Distance';

  @override
  String get workerFilterLanguage => 'Language Spoken';

  @override
  String get workerFilterAllLanguages => 'All Languages';

  @override
  String get workerFilterAvailability => 'Availability';

  @override
  String get workerFilterAllAvailability => 'All Statuses';

  @override
  String get workerFilterRateRange => 'Daily Wage Range';

  @override
  String get workerFilterGender => 'Gender Preference (Optional)';

  @override
  String get workerFilterAnyGender => 'Any Gender';

  @override
  String get workerFilterMinRating => 'Minimum Rating';

  @override
  String get workerFilterAnyRating => 'Any Rating';

  @override
  String get workerFilterMinJobs => 'Minimum Completed Jobs';

  @override
  String get workerFilterAnyJobs => 'Any Experience';

  @override
  String get workerFilterVerifiedOnly => 'Verified Workers Only';

  @override
  String get workerFilterApply => 'Apply Filters';

  @override
  String get workerFilterReset => 'Reset Filters';

  @override
  String get workerUnverifiedNotice => 'Unverified Worker';

  @override
  String get workerProfileTitle => 'Worker Profile';

  @override
  String get workerProfileBio => 'About Worker';

  @override
  String get workerProfileSkills => 'Skills & Specializations';

  @override
  String get workerProfileExperience => 'Work Experience';

  @override
  String get workerProfileRates => 'Standard Wage Rates';

  @override
  String get workerProfileLanguages => 'Languages Spoken';

  @override
  String get workerProfileServiceRadius => 'Service Radius';

  @override
  String get workerProfileTrustBadges => 'Trust & Verification Badges';

  @override
  String get workerProfileReviews => 'Employer Reviews & Ratings';

  @override
  String get workerProfileRecentlyViewed => 'Recently Viewed';

  @override
  String get workerProfileFavourite => 'Favourite';

  @override
  String get workerProfileFavouriteAdded => 'Worker added to favourites.';

  @override
  String get workerProfileFavouriteRemoved => 'Worker removed from favourites.';

  @override
  String get workerProfileBookNow => 'Book Worker';

  @override
  String get workerProfileChat => 'Protected Chat';

  @override
  String workerSearchResultsCount(int count) {
    return 'Found $count workers nearby';
  }

  @override
  String get workerSearchNoResults => 'No workers match your filter criteria';

  @override
  String get workerSearchNoResultsDesc =>
      'Try increasing the search distance, resetting filters, or switching language preference.';

  @override
  String get workerSearchToggleList => 'List View';

  @override
  String get workerSearchToggleMap => 'Map View';

  @override
  String get noShowHelpTitle => 'Worker Attendance & No-Show Support';

  @override
  String get noShowHelpDesc =>
      'If your booked worker has not arrived by the scheduled shift time, our safety system protects you with an instant replacement or a 100% escrow refund.';

  @override
  String get noShowReportButton => 'Report No-Show Now';

  @override
  String get noShowReportSuccess =>
      'No-show report received. Support and backup workers are being mobilized.';

  @override
  String get bookingWizardTitle => 'Direct Booking';

  @override
  String get bookingStepService => 'Service';

  @override
  String get bookingStepDateTime => 'Date & Time';

  @override
  String get bookingStepAddress => 'Address';

  @override
  String get bookingStepPayment => 'Price & Pay';

  @override
  String get bookingStepNotice => 'Notice';

  @override
  String get bookingStepTicket => 'Booking Pass';

  @override
  String get bookingWorkerDetails => 'Worker Details';

  @override
  String get bookingServiceTitleLabel => 'Service Title / Description';

  @override
  String get bookingServiceTitleHint => 'e.g. Living room fan wiring repair';

  @override
  String get bookingSpecialNotes => 'Special Instructions / Notes';

  @override
  String get bookingSpecialNotesHint =>
      'e.g. Bring extra 2.5mm wire, ladder available';

  @override
  String get bookingDuration => 'Estimated Duration';

  @override
  String get bookingDurationHalfDay => 'Half Day (4 hrs)';

  @override
  String get bookingDurationFullDay => 'Full Day (8 hrs)';

  @override
  String bookingDurationCustom(int hours) {
    return 'Custom ($hours hrs)';
  }

  @override
  String get bookingSelectDate => 'Select Date';

  @override
  String get bookingSelectTimeSlot => 'Select Time Slot';

  @override
  String get bookingSlotAvailable => 'Available';

  @override
  String get bookingSlotBooked => 'Booked';

  @override
  String get bookingScheduleConflictAlert =>
      'This worker is already booked during this time window. Please pick an alternative slot.';

  @override
  String get bookingAddressTitle => 'Service Location';

  @override
  String get bookingSavedAddresses => 'Saved Addresses';

  @override
  String get bookingAddNewAddress => 'Add New Address';

  @override
  String get bookingAddressLabel => 'Address Label';

  @override
  String get bookingAddressLine1 => 'Flat / House No. & Street';

  @override
  String get bookingLandmark => 'Landmark (optional)';

  @override
  String get bookingCity => 'City';

  @override
  String get bookingPincode => 'Pincode';

  @override
  String get bookingSaveAsDefault => 'Save as default address';

  @override
  String get bookingPriceBreakdown => 'Price Breakdown';

  @override
  String get bookingAgreedWage => 'Agreed Worker Wage';

  @override
  String get bookingPlatformFee => 'Platform Convenience Fee';

  @override
  String get bookingProtectionCoverFee => 'Job Protection Cover';

  @override
  String get bookingTotalPrice => 'Total Amount';

  @override
  String get bookingFairWageVerified => 'Within Fair Wage Band';

  @override
  String get bookingFairWageBelow => 'Below Standard Fair Wage';

  @override
  String get bookingPaymentMethod => 'Payment Method';

  @override
  String get bookingPaymentCash => 'Cash on Completion';

  @override
  String get bookingPaymentUpi => 'UPI Instant';

  @override
  String get bookingPaymentEscrow => 'Protected Escrow (Recommended)';

  @override
  String get bookingPaymentPlaceholder => 'Payment Gateway Integration (P5.2)';

  @override
  String get bookingRecurringOption => 'Repeat Service Schedule';

  @override
  String get bookingRecurringToggle => 'Make this a recurring repeat service';

  @override
  String get bookingRecurringWeekly => 'Weekly Repeat';

  @override
  String get bookingRecurringMonthly => 'Monthly Repeat';

  @override
  String get bookingUnverifiedNoticeTitle => 'Not UdyogaSethu Verified';

  @override
  String get bookingUnverifiedNoticeSubtitle =>
      'This worker has not completed UdyogaSethu training & verification.';

  @override
  String get bookingUnverifiedNoticeDesc =>
      'While the worker is registered, they have not yet earned the official trust and skill badge. Choose your preferred booking mode below:';

  @override
  String get bookingProtectionCoverTitle => 'Add ₹40 Job Protection Cover';

  @override
  String get bookingProtectionCoverDesc =>
      'Simulated property damage coverage (up to ₹10,000) and verified dispute claim assistance.';

  @override
  String get bookingBookWithoutProtection => 'Book without protection';

  @override
  String get bookingBookWithoutProtectionDesc =>
      'Proceed with direct cash/escrow terms without accidental damage coverage.';

  @override
  String get bookingProceedToTicket =>
      'Confirm & Proceed to Booking Pass Ticket';

  @override
  String get bookingTicketTitle => 'Booking Pass Ticket';

  @override
  String get bookingStatusWaiting => 'Waiting for worker';

  @override
  String get bookingCodeLabel => 'Booking Code';

  @override
  String get bookingSuccessMessage =>
      'Booking request sent to worker. You will receive an alert once accepted.';

  @override
  String get bookingViewMyJobs => 'View in My Jobs';

  @override
  String get bookingReturnHome => 'Return to Customer Hub';

  @override
  String get recurringManageTitle => 'Recurring Services';

  @override
  String get recurringNoBookings => 'No active recurring bookings found.';

  @override
  String get recurringPause => 'Pause Schedule';

  @override
  String get recurringResume => 'Resume Schedule';

  @override
  String get recurringCancel => 'Cancel Schedule';

  @override
  String get recurringSkipDate => 'Skip Next Date';

  @override
  String get recurringDateSkipped => 'Next scheduled service skipped.';

  @override
  String get recurringStatusActive => 'Active';

  @override
  String get recurringStatusPaused => 'Paused';

  @override
  String get recurringStatusCancelled => 'Cancelled';

  @override
  String get demoModeBadge => 'Demo mode';

  @override
  String get timelineTitle => 'Assignment Lifecycle Timeline';

  @override
  String get timelineLiveDot => 'LIVE';

  @override
  String get timelineDisputeActive => 'Dispute Raised Under Mediation';

  @override
  String get timelineDisputeSub =>
      'Resolution team is reviewing job evidence and logs.';

  @override
  String get timelineCurrentBadge => 'Current';

  @override
  String get stageRequestCreated => 'Request Created';

  @override
  String get stageAccepted => 'Accepted';

  @override
  String get stageTicketIssued => 'Ticket Issued';

  @override
  String get stageWorkerArrived => 'Worker Arrived';

  @override
  String get stageVerificationCompleted => 'Verification Completed';

  @override
  String get stageJobInProgress => 'Job In Progress';

  @override
  String get stageCompleted => 'Completed';

  @override
  String get stagePaymentReleased => 'Payment Released';

  @override
  String get stageDisputeRaised => 'Dispute Raised';

  @override
  String get activeJobTitle => 'Active Job Execution';

  @override
  String get actionAcceptJob => 'Accept Job';

  @override
  String get actionWorkerArrived => 'I Have Arrived';

  @override
  String get actionStartWork => 'Start Work';

  @override
  String get actionCompleteJob => 'Complete Job';

  @override
  String get actionAwaitingPayment => 'Awaiting Payment Release';

  @override
  String get actionJobFinished => 'Job Fully Completed';

  @override
  String get actionDisputeMediation => 'In Dispute Review';

  @override
  String get actionWaitingAcceptance => 'Waiting for Worker to Accept';

  @override
  String get actionConfirmArrival => 'Confirm Worker Arrival';

  @override
  String get actionConfirmCompletion => 'Confirm Job Completion';

  @override
  String get actionReleasePayment => 'Release Payment';

  @override
  String get actionPaymentDone => 'Payment Settled';

  @override
  String get actionAskForHelp => 'Ask for Help';

  @override
  String get actionDispute => 'Raise Dispute';

  @override
  String get simpleModeSpokenLabel => 'Tap to Speak & Execute';

  @override
  String get routeAndEtaTitle => 'Route & Travel ETA';

  @override
  String get openInMapsBtn => 'Open in Maps';

  @override
  String get demoModeChip => 'Demo mode';

  @override
  String get scheduleTitle => 'Worker Schedule & Travel';

  @override
  String get scheduleDayView => 'Day';

  @override
  String get scheduleWeekView => 'Week';

  @override
  String get scheduleWeeklyTotal => 'Week Projected Earnings';

  @override
  String get ticketScreenTitle => 'Digital Job Ticket';

  @override
  String get refreshTicketTooltip => 'Refresh Ticket QR';

  @override
  String get ticketOfflineNotice =>
      'Online connection required to refresh security token. Please reconnect before employer scan.';

  @override
  String get ticketBookingPassHeader => 'BOOKING PASS';

  @override
  String get ticketScanInstructions =>
      'Present this QR pass to your employer upon site arrival';

  @override
  String get ticketAutoRefreshesIn => 'Refreshes in';

  @override
  String get ticketReplayShieldTitle => 'Replay Protection Enabled';

  @override
  String get ticketReplayShieldBody =>
      'This dynamic security pass is single-use and auto-refreshes every 2 minutes. Screenshots cannot be replayed or scanned more than once.';

  @override
  String get attendanceScannerTitle => 'Scan Worker QR';

  @override
  String get attendanceScannerInstructions =>
      'Align worker\'s digital ticket QR code within the frame to verify arrival.';

  @override
  String get ticketReplayRefusedTitle => 'Replay Refused';

  @override
  String get ticketExpiredTitle => 'Ticket Expired';

  @override
  String get attendanceScanFailedTitle => 'Attendance Scan Failed';

  @override
  String get attendanceConfirmedTitle => 'Attendance Confirmed!';

  @override
  String get workerMarkedArrived => 'Worker marked as Arrived on site';

  @override
  String get scanAgain => 'Scan Again';

  @override
  String get scanDone => 'Done';

  @override
  String get viewActiveJob => 'View Active Job';

  @override
  String get actionShowTicket => 'Show QR Ticket';

  @override
  String get actionScanWorkerQr => 'Scan Worker QR';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get bookingCodeCopied => 'Booking code copied to clipboard';

  @override
  String get verifyYourPresence => 'Verify Your Presence';

  @override
  String get verifyPresenceSubtitle =>
      'Face match and site geofence check required before start';

  @override
  String get gpsPerimeterCheck => 'GPS Site Geofence Check';

  @override
  String get withinPerimeter => 'Within Job Site Geofence';

  @override
  String get outsidePerimeter => 'Outside Job Site Geofence';

  @override
  String distanceFromSite(String distance, String radius) {
    return 'Distance from site: ${distance}m (Allowed: ${radius}m)';
  }

  @override
  String get mockLocationDetected =>
      'Mock / Fake GPS detected. Start refused and logged for review.';

  @override
  String get faceSelfieCheck => 'Front-Camera Face Check';

  @override
  String get takeSelfieBtn => 'Take Verification Selfie';

  @override
  String get retakeSelfieBtn => 'Retake Selfie';

  @override
  String get verifyAndStartJob => 'Verify Presence & Start Job';

  @override
  String get verificationFailed => 'Verification Refused';

  @override
  String outOfGeofenceMessage(String distance, String radius) {
    return 'You appear to be ${distance}m away from the job site. You must be within ${radius}m to start.';
  }

  @override
  String get getHelpOrSupport => 'Get Help / Support';

  @override
  String get completionTitle => 'Job Completion & Evidence';

  @override
  String get completionSubtitle =>
      'Submit completion selfie and optional work photos to verify finish';

  @override
  String get workResultPhotos => 'Work Evidence Photos (Private)';

  @override
  String get addWorkPhoto => 'Add Photo';

  @override
  String get completeAndSubmit => 'Submit Completion & Stop Timer';

  @override
  String get midJobCheckTitle => 'Mid-Job Verification Required';

  @override
  String get midJobCheckSubtitle =>
      'High-value job safety check (wage >= ₹2,000)';

  @override
  String get midJobConfirmSelfie => 'Take Mid-Shift Selfie';

  @override
  String get midJobCustomerConfirm => 'Confirm Worker On-Site';

  @override
  String get timerTitle => 'Live Work Timer';

  @override
  String get timerRunning => 'Timer Running';

  @override
  String get timerPaused => 'Timer Paused';

  @override
  String get elapsedTime => 'Elapsed Time';

  @override
  String get smartNoShowEngineHeader => 'SMART NO-SHOW RECOVERY ENGINE';

  @override
  String get arrivalGraceExpiredAlert => '⚠️ ARRIVAL GRACE PERIOD EXPIRED';

  @override
  String get workerHasNotArrivedTitle => 'Worker Has Not Arrived';

  @override
  String workerHasNotArrivedSubtitle(
    String workerName,
    int minutesLate,
    String jobTitle,
  ) {
    return '$workerName is $minutesLate minutes past the scheduled arrival time for $jobTitle.';
  }

  @override
  String get wait10MinutesAction => 'Wait 10 Minutes';

  @override
  String get callWorkerDirectlyAction => '📞 Call Worker Directly';

  @override
  String get findSmartReplacementAction => '⚡ Find Smart Replacement Worker';

  @override
  String get gracePeriodExtendedMsg =>
      'Added +10 minutes wait grace. Timer paused.';

  @override
  String get maskedCallDemoMsg =>
      'Dialing worker... (Demo mode: Masked call arrives in P7.2)';

  @override
  String replacementBookedMsg(String workerName) {
    return 'Replacement booked with $workerName! Original marked as no-show.';
  }

  @override
  String get rankedReplacementsTitle => 'RANKED NEARBY WORKERS';

  @override
  String get noReplacementsFoundMsg =>
      'No nearby replacement candidates available right now.';

  @override
  String get requestReplacementOneTap => 'Request Replacement (1-Tap)';

  @override
  String get smartNoShowTrustNote =>
      'Zero-penalty refund on no-shows. Replacement workers are background-screened.';

  @override
  String get openRecoveryEngineAction => 'Open No-Show Recovery Engine';

  @override
  String get runningLateQuestionAction => 'Running late? Tap to share ETA';

  @override
  String runningLateReportedBadge(int minutes) {
    return 'Reported running late (+${minutes}m). Timer paused.';
  }

  @override
  String get runningLateDialogTitle => 'Running Late?';

  @override
  String get runningLateDialogSubtitle =>
      'Select your expected arrival delay. This notifies your employer and pauses the arrival grace timer once.';

  @override
  String get sendEtaAction => 'Send ETA';

  @override
  String runningLateSuccessMsg(int minutes) {
    return 'Reported +$minutes minutes ETA. Employer notified.';
  }

  @override
  String get jobHistoryTitle => 'Job History & Ratings';

  @override
  String get jobHistoryHeader => 'Job History';

  @override
  String get favouritesTitle => 'Favourites & Trust Circles';

  @override
  String get rateJobTitle => 'Rate & Review Job';

  @override
  String get quickTagsLabel => 'Quick Tags';

  @override
  String get reviewCommentLabel => 'Feedback & Review (Optional)';

  @override
  String get reviewCommentHint =>
      'Share your experience to help the community...';

  @override
  String get submitReviewBtn => 'Submit Verified Review';

  @override
  String get reportDisputeTitle => 'Report Job Dispute';

  @override
  String get disputeFreezeNotice =>
      'Filing a dispute pauses automatic escrow release and assigns the case to UdyogaSethu Trust & Safety for review.';

  @override
  String get disputeIssueTypeLabel => 'Select Issue Type';

  @override
  String get disputeDetailsLabel => 'Issue Details & Timeline';

  @override
  String get disputeDetailsHint =>
      'Please explain what happened clearly, including timestamps and any verbal agreements...';

  @override
  String get disputeEvidenceLabel => 'Evidence Photos (Optional)';

  @override
  String get submitDisputeBtn => 'Raise Formal Dispute';

  @override
  String get disputeTypeNoShow => 'No-Show / Unreported Absence';

  @override
  String get disputeTypeIncompleteWork => 'Incomplete Work / Left Early';

  @override
  String get disputeTypePoorQuality => 'Poor Quality / Substandard Work';

  @override
  String get disputeTypeWrongProduct => 'Wrong Product / Quality Mismatch';

  @override
  String get disputeTypePaymentIssue => 'Payment Issue / Escrow Dispute';

  @override
  String get disputeTypeUnsafeConduct => 'Unsafe Conduct / Behaviour Violation';

  @override
  String get disputeTypeVerificationProblem =>
      'Verification / Identity Mismatch';

  @override
  String get disputeTrackingTitle => 'Dispute Status Tracking';

  @override
  String get settingsSectionHeader => 'Settings';

  @override
  String get filterAll => 'All';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get filterDisputed => 'Disputed';

  @override
  String get filterInProgress => 'In Progress';

  @override
  String get filterCancelled => 'Cancelled';

  @override
  String get walletTitle => 'Wallet & Escrow';

  @override
  String get walletBalanceHeader => 'WALLET BALANCE';

  @override
  String get escrowProtected => 'Escrow Protected';

  @override
  String get todaysReleased => 'Today\'s Released';

  @override
  String get pendingEscrow => 'Pending Escrow';

  @override
  String get withdrawAction => 'Withdraw';

  @override
  String get scanUpiQr => 'Scan UPI QR';

  @override
  String get recentTransactions => 'RECENT TRANSACTIONS';

  @override
  String get withdrawEarningsTitle => 'Withdraw Earnings';

  @override
  String get demoWithdrawNote =>
      'Demo mode: Simulated payout ledger debit until banking partner exists.';

  @override
  String get transferToUpi => 'Transfer To (UPI VPA / Bank)';

  @override
  String get confirmPayoutWithdrawal => 'Confirm Payout Withdrawal';

  @override
  String get demoPayoutCompleted => 'Demo Payout Completed';

  @override
  String get demoUpiScanner => 'Demo mode: Simulated UPI Scanner';

  @override
  String get demoUpiNote =>
      'No real money will be transferred. Payment rails connect in Phase 5.2.';

  @override
  String get noTransactionsFound => 'No Transactions Found';

  @override
  String get noTransactionsSubtitle =>
      'Completed daily wages and transfers will appear here.';

  @override
  String get paymentTitle => 'Payment & Escrow Protection';

  @override
  String get paymentBillSummary => 'Bill Summary';

  @override
  String get paymentServiceWage => 'Service / Wage Amount';

  @override
  String get paymentPlatformFee => 'Platform Fee & GST';

  @override
  String get paymentProtectionAddon => 'Protection & Safety Add-on';

  @override
  String get paymentTotalPayable => 'Total Payable';

  @override
  String get paymentEscrowNotice =>
      'Protected until verified completion. Money held in safe Escrow.';

  @override
  String get paymentChooseMethod => 'Choose Payment Method';

  @override
  String get paymentUpi => 'UPI (GPay / PhonePe / Paytm)';

  @override
  String get paymentCard => 'Credit / Debit Card';

  @override
  String get paymentWallet => 'UdyogaSethu Wallet';

  @override
  String get paymentCash => 'Cash on Completion';

  @override
  String get paymentPaySecurely => 'Pay Securely';

  @override
  String get paymentConfirmCash => 'Confirm Cash Booking';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get paymentSuccessful => 'Payment Successful and Confirmed';

  @override
  String get paymentSuccessSubtitle =>
      'Your payment is confirmed and safely held in escrow.';

  @override
  String get paymentConfirmingBank => 'Confirming with Bank...';

  @override
  String get paymentConfirmingSubtitle =>
      'Awaiting confirmation from Razorpay and banking network. Your screen will update automatically.';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get paymentFailedSubtitle =>
      'Your transaction could not be completed by the bank. No money was deducted.';

  @override
  String get paymentReceiptNo => 'Receipt No';

  @override
  String get paymentDownloadPdf => 'Share / Download PDF Receipt';

  @override
  String get paymentContinueJob => 'Continue to Job / Order';

  @override
  String get paymentTryAgain => 'Try Again';

  @override
  String get pendingEscrowRelease => 'Pending Escrow Release';

  @override
  String get protectedBadge => 'Protected';

  @override
  String get releaseEscrowPayment => 'Release Escrow Payment';

  @override
  String get confirmAndRelease => 'Confirm & Release Payment';

  @override
  String get workerPayout => 'Worker Payout (Available Balance)';

  @override
  String get escrowAutoReleaseNotice =>
      'Payment will be released as soon as the employer confirms, or automatically within 24 hours if no dispute is raised.';

  @override
  String get escrowEarningsSecured =>
      'Your earnings are 100% secured in escrow';

  @override
  String get releaseEscrowSuccess =>
      'Payment successfully released to worker wallet!';

  @override
  String get earningsDashboardTitle => 'Earnings & Performance';

  @override
  String get earningsToday => 'Today\'s Earnings';

  @override
  String get earningsThisWeek => 'This Week';

  @override
  String get earningsThisMonth => 'This Month';

  @override
  String get earningsTotal => 'Total Lifetime Earnings';

  @override
  String get earningsCompletedJobs => 'Completed Jobs';

  @override
  String get earningsFarmOrders => 'Farm Orders';

  @override
  String get earningsAverageRating => 'Average Rating';

  @override
  String get earningsDailyGoal => 'Daily Goal';

  @override
  String get earningsDailyGoalProgress => 'Today\'s Goal Progress';

  @override
  String get earningsPayoutTrends => 'Payout Trend';

  @override
  String get earningsTimeframe14Days => '14 Days';

  @override
  String get earningsTimeframe6Months => '6 Months';

  @override
  String get earningsBestDayTitle => 'Best Earning Day';

  @override
  String earningsBestDaySubtitle(Object amount, Object date) {
    return 'You earned $amount on $date!';
  }

  @override
  String get earningsSetDailyGoal => 'Set Daily Goal';

  @override
  String get earningsSaveGoal => 'Save Goal';

  @override
  String get savingsGoalsTitle => 'Savings Goal Planner';

  @override
  String get savingsGoalsSubtitle =>
      'Track your dreams. Goals are virtual trackers and do not lock your money.';

  @override
  String get savingsGoalsVirtualNotice =>
      'Virtual Goal Trackers: Goals help you budget and plan towards your dreams. They do not freeze or lock your wallet money.';

  @override
  String get savingsGoalNew => 'New Savings Goal';

  @override
  String get savingsGoalCreate => 'Create Savings Goal';

  @override
  String get savingsGoalTarget => 'Target Amount';

  @override
  String get savingsGoalSaved => 'Saved So Far';

  @override
  String get savingsGoalDeadline => 'Target Deadline';

  @override
  String get savingsGoalCategory => 'Category';

  @override
  String get savingsGoalSuggestedPlan => 'Suggested Savings Plan';

  @override
  String get savingsGoalAddSavings => 'Record Savings Progress';

  @override
  String get savingsGoalAddAmount => 'Amount Saved';

  @override
  String get savingsGoalCompletedBadge => 'Goal Achieved! 🎉';

  @override
  String get savingsGoalActiveBadge => 'In Progress';

  @override
  String get savingsGoalCategorySchoolFees => 'School Fees';

  @override
  String get savingsGoalCategoryEquipment => 'Work Equipment';

  @override
  String get savingsGoalCategoryScooter => 'Scooter / Vehicle';

  @override
  String get savingsGoalCategorySeeds => 'Seeds & Fertilizer';

  @override
  String get savingsGoalCategoryEmergency => 'Emergency Fund';

  @override
  String get savingsGoalCategoryHome => 'Home Renovation';

  @override
  String get savingsGoalCategoryCustom => 'Custom Goal';

  @override
  String get savingsGoalDelete => 'Delete Goal';

  @override
  String get savingsGoalDeleteConfirm =>
      'Are you sure you want to delete this savings goal tracker?';

  @override
  String get savingsGoalEmptyState =>
      'Plan your next big milestone by setting a savings goal.';

  @override
  String get savingsGoalsPlanGoals => 'Plan Goals';

  @override
  String get farmerWorkspace => 'FARMER WORKSPACE';

  @override
  String get farmerEmpoweredNetwork =>
      'Empowered by UdyogaSethu Direct Agri-Network';

  @override
  String get farmerProduceSold => 'PRODUCE SOLD';

  @override
  String get farmerThisMonth => 'This Month';

  @override
  String get farmerDirectEarnings => 'DIRECT EARNINGS';

  @override
  String get farmerZeroMiddlemen => 'Zero Middlemen';

  @override
  String get farmerActiveLabor => 'ACTIVE LABOR';

  @override
  String get farmerHarvestShiftPlaceholder => 'Harvest Shift (P6.3)';

  @override
  String farmerBooked(int count) {
    return '$count Booked';
  }

  @override
  String get farmerWeatherAdvisoryRadar => 'WEATHER ADVISORY RADAR';

  @override
  String get farmerSimulatedForecast => 'Simulated Forecast';

  @override
  String farmerRainProbability(int percent) {
    return '$percent% Rain';
  }

  @override
  String get farmerBookHarvestHelpers => 'Book Harvest Helpers';

  @override
  String get farmerViewIrrigationGuide => 'View Irrigation Guide';

  @override
  String get farmerLiveMandiPrices => 'LIVE MANDI PRICES & DEMAND';

  @override
  String get farmerLiveFeed => 'Live Feed';

  @override
  String get farmerAllCrops => 'All Crops';

  @override
  String get farmerVegetables => 'Vegetables';

  @override
  String get farmerGrainsAndPulses => 'Grains & Pulses';

  @override
  String get farmerNoPricesInCategory => 'No Mandi Prices in this Category';

  @override
  String get farmerSelectAllCropsHint =>
      'Select All Crops to view all Karnataka APMC market prices.';

  @override
  String farmerUpdatedDate(String date) {
    return 'Updated $date';
  }

  @override
  String get farmerApmcKarnatakaFeed => 'APMC Karnataka Feed';

  @override
  String get farmerEssentialSuite => 'FARMER ESSENTIAL SUITE';

  @override
  String get farmerRentTractor => 'Rent Tractor';

  @override
  String get farmerHireWorkers => 'Hire Workers';

  @override
  String get farmerSoilAiTest => 'Soil AI Test';

  @override
  String get farmerSellProduce => 'Sell Produce';

  @override
  String get farmerPestAiDoc => 'Pest AI Doc';

  @override
  String get farmerGovtSchemes => 'Govt Schemes';

  @override
  String get farmerAgriDrone => 'Agri Drone';

  @override
  String get farmerIrrigationAi => 'Irrigation AI';

  @override
  String farmerComingInPhase(String phase) {
    return 'Coming in $phase';
  }

  @override
  String get farmerUnderstood => 'Understood';

  @override
  String get farmerGotIt => 'Got it';

  @override
  String get farmerHireWorkersDesc =>
      'Farmers will be able to post agricultural labour requests, specify shifts, and hire verified nearby workers directly from their farmer account with escrow protection.';

  @override
  String get farmerRentTractorDesc =>
      'Book nearby tractors, rotavators, and harvesters directly from verified agri-machinery hubs.';

  @override
  String get farmerSoilAiTestDesc =>
      'Upload soil test report or photograph to get instant AI N-P-K recommendations and fertilizer dosages.';

  @override
  String get farmerSellProduceDesc =>
      'List your harvested crops for direct bulk sale to mandi traders and commercial buyers with zero middlemen.';

  @override
  String get farmerPestAiDocDesc =>
      'Snap a picture of leaf damage or crop pests for immediate AI diagnosis and organic treatment remedies.';

  @override
  String get farmerGovtSchemesDesc =>
      'Explore PM-Kisan, Raitha Siri, solar pump subsidies, and crop insurance schemes tailored to your land.';

  @override
  String get farmerAgriDroneDesc =>
      'Book certified agri-drone pilots for precision nano-urea and organic pest spray within 24 hours.';

  @override
  String get farmerIrrigationAiDesc =>
      'Smart irrigation scheduling based on local evapotranspiration and soil moisture retention curves.';

  @override
  String get farmerHomeTitle => 'Farmer Home';

  @override
  String get farmerSimulateRainDev => 'Simulate Rain Forecast (Dev)';

  @override
  String get farmerFailedLoadMandi => 'Failed to load Mandi prices';

  @override
  String get farmerHighDemand => 'High Demand';

  @override
  String get farmerStable => 'Stable';

  @override
  String get farmerFrpGuaranteed => 'FRP Guaranteed';

  @override
  String get farmerMspProtected => 'MSP Protected';

  @override
  String get farmerOversupply => 'Oversupply';

  @override
  String get farmerModerate => 'Moderate';

  @override
  String get farmerProfileTitle => 'Farmer Profile';

  @override
  String get verifiedFarmer => 'VERIFIED FARMER ✓';

  @override
  String get organicLand => 'Organic Land';

  @override
  String get soldThisMonth => 'Sold This Month';

  @override
  String get directSales => 'Direct Sales';

  @override
  String get farmInfrastructureAndBadges => 'FARM INFRASTRUCTURE & CROP BADGES';

  @override
  String get soilClassification => 'SOIL CLASSIFICATION';

  @override
  String get primaryCrops => 'PRIMARY CROPS';

  @override
  String get apmcRegistration => 'APMC REGISTRATION';

  @override
  String get kisanCreditCard => 'KISAN CREDIT CARD';

  @override
  String get zeroPesticideOrganicCertificate =>
      'Zero-Pesticide Organic Certificate';

  @override
  String get verifiedByKarnatakaOrganicBoard =>
      'Verified by Karnataka Organic Farmers Board';

  @override
  String get validatedStatus => 'VALIDATED ✓';

  @override
  String get underReviewStatus => 'UNDER REVIEW';

  @override
  String get languageMode => 'LANGUAGE MODE';

  @override
  String get manageProduceListings => 'Manage Produce Listings';

  @override
  String get produceListingsTitle => 'Produce Listings';

  @override
  String get addNewProduce => 'Add New Produce';

  @override
  String get editProduceListing => 'Edit Produce Listing';

  @override
  String get produceName => 'Produce Name';

  @override
  String get category => 'Category';

  @override
  String pricePerUnit(String unit) {
    return 'Price per $unit';
  }

  @override
  String get stockQuantity => 'Stock Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get harvestDate => 'Harvest Date';

  @override
  String get qualityNotes => 'Quality Notes';

  @override
  String get farmingMethod => 'Farming Method';

  @override
  String get deliveryAvailable => 'Delivery Available';

  @override
  String get pickupAvailable => 'Pickup Available';

  @override
  String get availabilityMode => 'Availability Mode';

  @override
  String get sameDayDelivery => 'Same Day Delivery';

  @override
  String get nextDayDelivery => 'Next Day Delivery';

  @override
  String get harvestPreOrder => 'Harvest Pre-Order';

  @override
  String get farmerSetsFinalPrice => 'The farmer always sets the final price';

  @override
  String get statusLowStock => 'Low Stock';

  @override
  String get statusSoldOut => 'Sold Out';

  @override
  String get statusPaused => 'Paused';

  @override
  String get pauseListing => 'Pause Listing';

  @override
  String get activateListing => 'Activate Listing';

  @override
  String get updateStock => 'Update Stock';

  @override
  String stockInStock(String stock) {
    return '$stock in stock';
  }

  @override
  String get buyerProduceMarket => 'Farm Fresh Produce';

  @override
  String get buyerSearchProduceHint =>
      'Search fresh farm produce (e.g., Tomato, Rice)...';

  @override
  String get noProduceAvailable => 'No Produce Listings Available';

  @override
  String get orderDirect => 'Order Direct';

  @override
  String get uploadProducePhotos => 'Produce Photos (produce-images)';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get farmerMapHeader =>
      'FARMERS REQUIRED PRODUCTS, SEEDS, MACHINERY & SERVICES NEAR ME';

  @override
  String get farmerNearbyRentals => 'NEARBY EQUIPMENT & DRONE RENTALS';

  @override
  String get farmerEscrowGuaranteed => 'Escrow Guaranteed';

  @override
  String get farmerBookNow => 'Book Now';

  @override
  String get farmerBookItem => 'Book Item';

  @override
  String get farmerViewAllEquipmentMap =>
      'View All Farm Resources & Live Map →';

  @override
  String get farmerEquipmentBooked => 'Equipment Booked!';

  @override
  String get farmerBookingQuantity => 'Booking Duration / Quantity';

  @override
  String get farmerDeliveryAddress => 'Farm Delivery / Work Site Address';

  @override
  String get farmerSpecialNotes => 'Work Instructions / Crop Notes (Optional)';

  @override
  String get farmerVendorHubTitle => 'Equipment & Machinery Vendor Hub';

  @override
  String get farmerAddEquipment => 'Add Equipment';

  @override
  String get farmTraceabilityTitle => 'Farm Quality Traceability Verified';

  @override
  String get traceabilityCropItem => 'Crop Item:';

  @override
  String get traceabilityFarmerOrigin => 'Farmer Origin:';

  @override
  String get traceabilityHarvestTime => 'Harvest Time:';

  @override
  String get traceabilityCertification => 'Organic Certification:';

  @override
  String get traceabilityFarmingMethod => 'Farming Method:';

  @override
  String get traceabilityQualityNotes => 'Quality Notes:';

  @override
  String get closeTraceability => 'Close Traceability Details';

  @override
  String get produceFiltersTitle => 'Filters & Sorting';

  @override
  String get clearFilters => 'Reset All';

  @override
  String get sortBy => 'Sort By';

  @override
  String get maxDistance => 'Maximum Distance';

  @override
  String get minFarmerRating => 'Farmer Rating';

  @override
  String get freshnessFilter => 'Harvest Freshness';

  @override
  String get fulfillmentOptions => 'Fulfillment & Availability';

  @override
  String get deliveryAvailableOnly => 'Doorstep Delivery Available';

  @override
  String get walkInStoreOnly => 'Walk-in Store / Farm Depot Pickup';

  @override
  String get organicCertifiedOnly => 'Organic Certificate Validated Only';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get customerProduceMapTitle =>
      'CUSTOMER REQUIRED FARM PRODUCE, ORGANIC SELLERS & OUTLETS NEAR ME';

  @override
  String get orderNow => 'Order Now';
}
