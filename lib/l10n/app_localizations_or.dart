// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oriya (`or`).
class AppLocalizationsOr extends AppLocalizations {
  AppLocalizationsOr([String locale = 'or']) : super(locale);

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
  String get walletBalance => 'ୱାଲେଟ୍ ବାଲାନ୍ସ';

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
  String get farmNameLabel => 'ଫାର୍ମ / ବଗିଚା ନାମ';

  @override
  String get farmNameHint => 'e.g. Green Valley Organic Farm';

  @override
  String get villageClusterLabel => 'Village / Cluster Name';

  @override
  String get villageClusterHint => 'e.g. Devanahalli, Bengaluru Rural';

  @override
  String get farmLocationLabel => 'Farm Location on Map';

  @override
  String get acresLabel => 'ମୋଟ ଜମି (ଏକର)';

  @override
  String get soilTypeLabel => 'ମୃତ୍ତିକା ବର୍ଗୀକରଣ';

  @override
  String get soilPhLabel => 'Soil pH (Optional)';

  @override
  String get primaryCropsLabel => 'ମୁଖ୍ୟ ଫସଲ';

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
  String get kccApproved => 'KCC ଅନୁମୋଦିତ ✓';

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
  String get roleConflictTitle => 'ଭୂମିକା ଆକାଉଣ୍ଟ୍ ବିଦ୍ୟମାନ ଅଛି';

  @override
  String roleConflictMessage(Object chosenRole, Object existingRole) {
    return 'ଆପଣଙ୍କ ଆକାଉଣ୍ଟ୍ ପୂର୍ବରୁ $existingRole ଭାବରେ ପଞ୍ଜିକୃତ ହୋଇଛି।';
  }

  @override
  String roleConflictLoginAs(Object existingRole) {
    return '$existingRole ଭାବରେ ଲଗ୍ ଇନ୍ କରନ୍ତୁ';
  }

  @override
  String get roleConflictBack => 'ଫେରି ଯାଆନ୍ତୁ';

  @override
  String get privacyCentreTitle => 'ଗୋପନୀୟତା କେନ୍ଦ୍ର';

  @override
  String get privacyCentreSubtitle =>
      'ଆପଣଙ୍କର ଡାଟା ସମ୍ମତି ଏବଂ ଅନୁମତି ପରିଚାଳନା କରନ୍ତୁ।';

  @override
  String get consentSheetTitle => 'ଡାଟା ପ୍ରକ୍ରିୟାକରଣ ସମ୍ମତି';

  @override
  String get consentWhatCollected => 'କ’ଣ ସଂଗ୍ରହ କରାଯାଏ';

  @override
  String get consentWhyCollected => 'କାହିଁକି ସଂଗ୍ରହ କରାଯାଏ';

  @override
  String get consentHowLongKept => 'କେତେ ସମୟ ରଖାଯାଏ';

  @override
  String get consentWhoCanSee => 'କିଏ ଦେଖିପାରିବେ';

  @override
  String get consentHowToWithdraw => 'କିପରି ପ୍ରତ୍ୟାହାର କରିବେ';

  @override
  String get consentAgreeButton => 'ମୁଁ ସହମତ ଏବଂ ସମ୍ମତି ଦେଉଛି';

  @override
  String get consentNotNowButton => 'ବର୍ତ୍ତମାନ ନୁହେଁ';

  @override
  String get consentGrantedStatus => 'ସମ୍ମତି ଦିଆଗଲା';

  @override
  String get consentRevokedStatus => 'ସମ୍ମତି ପ୍ରତ୍ୟାହୃତ ହୋଇଛି';

  @override
  String get withdrawConsentButton => 'ସମ୍ମତି ପ୍ରତ୍ୟାହାର କରନ୍ତୁ';

  @override
  String get withdrawFaceConsentTitle => 'ମୁଖ ଯାଞ୍ଚ ସମ୍ମତି ପ୍ରତ୍ୟାହାର କରିବେ?';

  @override
  String get withdrawFaceConsentMessage =>
      'ମୁଖ ସମ୍ମତି ପ୍ରତ୍ୟାହାର କଲେ ଆପଣଙ୍କ ରେଫରେନ୍ସ ଡାଟା ସ୍ଥାୟୀ ଭାବରେ ଲିଭିଯିବ।';

  @override
  String get confirmWithdrawButton => 'ପ୍ରତ୍ୟାହାର କରନ୍ତୁ ଏବଂ ଡାଟା ଲିଭାନ୍ତୁ';

  @override
  String get cancelButton => 'ବାତିଲ କରନ୍ତୁ';

  @override
  String get profileTitle => 'ମୋର ପ୍ରୋଫାଇଲ୍';

  @override
  String get termsAndPrivacyTitle => 'ସର୍ତ୍ତାବଳୀ ଏବଂ ଗୋପନୀୟତା ନୀତି';

  @override
  String get termsDraftNotice =>
      'ଚିଠା - ପ୍ରକୃତ ଶୁଭାରମ୍ଭ ପୂର୍ବରୁ ସମୀକ୍ଷା କରନ୍ତୁ';

  @override
  String get systemPermissionsTitle => 'ସିଷ୍ଟମ୍ ଅନୁମତି';

  @override
  String get openSystemSettings => 'ଆପ୍ ସେଟିଂସ ଖୋଲନ୍ତୁ';

  @override
  String get settingsTitle => 'ସେଟିଂସ';

  @override
  String get faceVerificationCheck => 'ମୁଖ ଯାଞ୍ଚ ପରୀକ୍ଷା';

  @override
  String get faceCheckSubtext =>
      'ଫେସ୍ ଲାଇଭନେସ୍ ଯାଞ୍ଚ ସାହାଯ୍ୟରେ ଆପଣଙ୍କ ପରିଚୟ ଯାଞ୍ଚ କରନ୍ତୁ';

  @override
  String get faceMatchSuccess => 'ମୁଖ ପରିଚୟ ଯାଞ୍ଚ ହୋଇଛି';

  @override
  String get faceMatchFailedTitle => 'ମୁଖ ମେଳକ ବିଫଳ ହୋଇଛି';

  @override
  String get faceMatchFailedBody =>
      'ଭଲ ଆଲୋକରେ ଆପଣଙ୍କ ମୁଖ ସ୍ପଷ୍ଟ ରଖି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।';

  @override
  String get manualReviewRequiredTitle => '3 ଟି ଯାଞ୍ଚ ଚେଷ୍ଟା ବିଫଳ ହୋଇଛି';

  @override
  String get manualReviewRequiredBody =>
      'ଆପଣଙ୍କ ମୁଖ ଯାଞ୍ଚ ମାନୁଆଲ ସମୀକ୍ଷା ପାଇଁ ପଠାଯାଇଛି। ଆପଣ ସୀମିତ ଆକ୍ସେସ୍ ସହିତ ଜାରି ରଖିପାରିବେ।';

  @override
  String get requestManualReview => 'ମାନୁଆଲ ସମୀକ୍ଷା ପାଇଁ ଅନୁରୋଧ କରନ୍ତୁ';

  @override
  String get retryVerification => 'ପୁଣି ଯାଞ୍ଚ ପାଇଁ ଚେଷ୍ଟା କରନ୍ତୁ';

  @override
  String get demoSimulatePass => 'ଡେମୋ: ସଫଳ ଯାଞ୍ଚ';

  @override
  String get demoSimulateFail => 'ଡେମୋ: ବିଫଳ ଯାଞ୍ଚ';

  @override
  String get seekerHomeTitle => 'କର୍ମସନ୍ଧାନୀ ହୋମ୍';

  @override
  String get searchJobsPlaceholder => 'କାର୍ଯ୍ୟ, ସେବା ସନ୍ଧାନ କରନ୍ତୁ...';

  @override
  String get todaysGoal => 'ଆଜିର ଲକ୍ଷ୍ୟ';

  @override
  String get viewWallet => 'ୱାଲେଟ୍ ଦେଖନ୍ତୁ >';

  @override
  String get locationSharingActive =>
      'ସୁରକ୍ଷା ନିରୀକ୍ଷଣ ପାଇଁ ଅବସ୍ଥିତି ଅଂଶୀଦାର ସକ୍ରିୟ ଅଛି';

  @override
  String get changeLocation => 'ପରିବର୍ତ୍ତନ >';

  @override
  String get quickActionsHeader => 'ଦ୍ରୁତ କାର୍ଯ୍ୟ';

  @override
  String get actionNearbyJobs => 'ନିକଟସ୍ଥ କାର୍ଯ୍ୟ';

  @override
  String get actionAiAssistant => 'ଏଆଇ ସହାୟକ';

  @override
  String get actionWallet => 'ୱାଲେଟ୍';

  @override
  String get actionSafetyHub => 'ସୁରକ୍ଷା କେନ୍ଦ୍ର';

  @override
  String get tagSponsored => 'ପ୍ରାୟୋଜିତ';

  @override
  String get whyAmISeeingThis => 'ମୁଁ ଏହା କାହିଁକି ଦେଖୁଛି?';

  @override
  String get recommendedForYou => 'ଆପଣଙ୍କ ପାଇଁ ସୁପାରିଶ';

  @override
  String get applyNow => 'ବର୍ତ୍ତମାନ ଆବେଦନ କରନ୍ତୁ';

  @override
  String get applied => 'ଆବେଦନ କରାଯାଇଛି ✓';

  @override
  String get noJobsNearYou => 'ଆପଣଙ୍କ ନିକଟରେ ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି କାର୍ଯ୍ୟ ନାହିଁ';

  @override
  String get widenRadiusAction => 'ସନ୍ଧାନ ପରିସର ବଢ଼ାନ୍ତୁ';

  @override
  String get sosEmergencyPill => 'ଜରୁରୀକାଳୀନ ଏସଓଏସ';

  @override
  String get selectLocationArea => 'ଅବସ୍ଥିତି ଅଞ୍ଚଳ ଚୟନ କରନ୍ତୁ';

  @override
  String get goodMorning => 'ଶୁଭ ସକାଳ';

  @override
  String get goodAfternoon => 'ଶୁଭ ଅପରାହ୍ନ';

  @override
  String get goodEvening => 'ଶୁଭ ସନ୍ଧ୍ୟା';

  @override
  String get studentsWelcomeChip => 'ଛାତ୍ରମାନଙ୍କୁ ସ୍ୱାଗତ';

  @override
  String get flexibleShiftChip => 'ନମନୀୟ ଶିଫ୍ଟ';

  @override
  String get nearbyJobsMapTitle =>
      'ନିକଟସ୍ଥ ଦୈନିକ ମଜୁରୀ କାର୍ଯ୍ୟ ଏବଂ କାର୍ଯ୍ୟସ୍ଥଳ';

  @override
  String livePinsCount(Object count) {
    return '$count ଲାଇଭ୍ ପିନ୍';
  }

  @override
  String nearbyGpsPinListings(Object count) {
    return 'ନିକଟସ୍ଥ ଜିପିଏସ୍ ପିନ୍ ତାଲିକା ($count)';
  }

  @override
  String get tapPinOrCardToInspect =>
      'ପରୀକ୍ଷା କରିବାକୁ ପିନ୍ କିମ୍ବା କାର୍ଡ ଟ୍ୟାପ୍ କରନ୍ତୁ';

  @override
  String get applyButton => 'ଆବେଦନ କରନ୍ତୁ';

  @override
  String get categoryFilterAll => 'ସମସ୍ତ';

  @override
  String get recenterMap => 'ଜିପିଏସ୍ ପୁନଃ କେନ୍ଦ୍ରୀଭୂତ କରନ୍ତୁ';

  @override
  String get zoomIn => 'ଜୁମ୍ ଇନ୍';

  @override
  String get zoomOut => 'ଜୁମ୍ ଆଉଟ୍';

  @override
  String get gpsDisabledBanner =>
      'ଜିପିଏସ୍ ବନ୍ଦ ଅଛି। ସଠିକ୍ ଦୂରତା ପାଇଁ ସ୍ଥାନ ଚାଲୁ କରନ୍ତୁ।';

  @override
  String get locationPermissionDeniedBanner =>
      'ସ୍ଥାନ ଅନୁମତି ମିଳିନାହିଁ। ଡିଫଲ୍ଟ ଅଞ୍ଚଳ ଦେଖାଯାଉଛି।';

  @override
  String get noJobsInArea =>
      'ଏହି ବ୍ୟାସାର୍ଦ୍ଧ ମଧ୍ୟରେ କୌଣସି କାର୍ଯ୍ୟସ୍ଥଳ ମିଳିଲା ନାହିଁ';

  @override
  String get searchRadius => 'ସନ୍ଧାନ ବ୍ୟାସାର୍ଦ୍ଧ';

  @override
  String radiusKm(Object radius) {
    return '$radius କିମି';
  }

  @override
  String get openLocationSettings => 'ସେଟିଂସ୍';

  @override
  String get loadJobsError =>
      'ନିକଟସ୍ଥ କାର୍ଯ୍ୟ ଲୋଡ୍ କରିବାରେ ଅସମର୍ଥ। ସଂଯୋଗ ଯାଞ୍ଚ କରି ପୁନଃ ଚେଷ୍ଟା କରନ୍ତୁ।';

  @override
  String get retryAction => 'ପୁନଃ ଚେଷ୍ଟା କରନ୍ତୁ';

  @override
  String get openStreetMapAttribution => '© OpenStreetMap contributors';

  @override
  String get cameraPermissionTitle => 'କ୍ୟାମେରା ପ୍ରବେଶ';

  @override
  String get cameraPermissionSubtitle =>
      'ଚେହେରା ଯାଞ୍ଚ ଏବଂ ଆଇଡି ସ୍କାନିଂ ପାଇଁ ବ୍ୟବହୃତ ହୁଏ।';

  @override
  String get locationPermissionTitle => 'ଡିଭାଇସ୍ ସ୍ଥାନ (ଜିପିଏସ୍)';

  @override
  String get locationPermissionSubtitle =>
      'ନିକଟସ୍ଥ କାମ, ମାନଚିତ୍ର ଏବଂ କାର୍ଯ୍ୟସ୍ଥଳ ଉପସ୍ଥିତି ଦେଖାଇବା ପାଇଁ ବ୍ୟବହୃତ ହୁଏ।';

  @override
  String get notificationPermissionTitle => 'ବିଜ୍ଞପ୍ତି';

  @override
  String get notificationPermissionSubtitle =>
      'ତୁରନ୍ତ କାର୍ଯ୍ୟ ସତର୍କତା, ଦେୟ ଏବଂ ସୁରକ୍ଷା ଅଦ୍ୟତନ ପାଇଁ ବ୍ୟବହୃତ ହୁଏ।';

  @override
  String get permissionAllowedStatus => 'ଅନୁମୋଦିତ';

  @override
  String get permissionBlockedStatus => 'ଅବରୋଧିତ / ବନ୍ଦ';

  @override
  String get refreshConsentsTooltip => 'ସ୍ଥିତି ସତେଜ କରନ୍ତୁ';

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
  String get postJobStepAudience => 'ଲକ୍ଷ୍ୟ ଶ୍ରମିକ';

  @override
  String get postJobAudienceTitle => 'ଏହି କାମ କାହା ପାଇଁ?';

  @override
  String get postJobAudienceSubtitle =>
      'ଏହି କାମ ଦେଖିବା ଏବଂ ଆବେଦନ କରିବା ପାଇଁ ଉପଯୁକ୍ତ ଶ୍ରମିକ ବର୍ଗ ଚୟନ କରନ୍ତୁ।';

  @override
  String get postJobAudienceInformal => 'ଦୈନିକ ମଜୁରୀ / ଅଣସଂଗଠିତ ଶ୍ରମିକ';

  @override
  String get postJobAudienceInformalHint =>
      'ଦୈନିକ ଶ୍ରମିକ, ନିର୍ମାଣ, ଲୋଡିଂ, ଘରୋଇ ସହାୟକ';

  @override
  String get postJobAudienceStudent => 'ଛାତ୍ରଛାତ୍ରୀ';

  @override
  String get postJobAudienceStudentHint =>
      'ସନ୍ଧ୍ୟା କିମ୍ବା ସପ୍ତାହାନ୍ତର ଫ୍ଲେକ୍ସିବଲ୍ କାମ ଖୋଜୁଥିବା କଲେଜ ଛାତ୍ର';

  @override
  String get postJobAudiencePartTime => 'ଅଂଶକାଳୀନ / ଫ୍ଲେକ୍ସିବଲ୍ ଶ୍ରମିକ';

  @override
  String get postJobAudiencePartTimeHint =>
      'କମ୍ ସମୟ କିମ୍ବା ଫ୍ଲେକ୍ସିବଲ୍ ସମୟରେ କାମ କରିବାକୁ ଚାହୁଁଥିବା ଶ୍ରମିକ';

  @override
  String get postJobAudienceRequired =>
      'ଦୟାକରି ଅନ୍ତତଃ ଗୋଟିଏ ଶ୍ରମିକ ବର୍ଗ ଚୟନ କରନ୍ତୁ';

  @override
  String get hubConfirmedBookingEmptyTitle => 'କୌଣସି ସକ୍ରିୟ ବୁକିଂ ନାହିଁ';

  @override
  String get hubConfirmedBookingEmptyDesc =>
      'ଆପଣଙ୍କର ନିଶ୍ଚିତ ବୁକିଂ ଏବଂ ଟ୍ରାକିଂ ଏଠାରେ ଦେଖାଯିବ।';

  @override
  String get hubLocationNotSet => 'ସ୍ଥାନ ସେଟ୍ ହୋଇନାହିଁ';

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
  String get hubActionScanQr => 'QR ସ୍କାନ';

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
  String get demoModeBadge => 'ଡେମୋ ମୋଡ୍';

  @override
  String get timelineTitle => 'କାର୍ଯ୍ୟ ଅଗ୍ରଗତି ସମୟରେଖା';

  @override
  String get timelineLiveDot => 'ଲାଇଭ୍';

  @override
  String get timelineDisputeActive => 'ବିବାଦ ସମୀକ୍ଷାଧୀନ ରହିଛି';

  @override
  String get timelineDisputeSub => 'ମଧ୍ୟସ୍ଥତା ଦଳ ପ୍ରମାଣ ଯାଞ୍ଚ କରୁଛନ୍ତି।';

  @override
  String get timelineCurrentBadge => 'ବର୍ତ୍ତମାନ';

  @override
  String get stageRequestCreated => 'ଅନୁରୋଧ ସୃଷ୍ଟି ହୋଇଛି';

  @override
  String get stageAccepted => 'ଗ୍ରହଣ କରାଯାଇଛି';

  @override
  String get stageTicketIssued => 'ଟିକେଟ୍ ପ୍ରଦାନ କରାଯାଇଛି';

  @override
  String get stageWorkerArrived => 'କର୍ମଚାରୀ ପହଞ୍ଚିଛନ୍ତି';

  @override
  String get stageVerificationCompleted => 'ଯାଞ୍ଚ ସମ୍ପୂର୍ଣ୍ଣ ହୋଇଛି';

  @override
  String get stageJobInProgress => 'କାର୍ଯ୍ୟ ଚାଲୁଅଛି';

  @override
  String get stageCompleted => 'ସମ୍ପୂର୍ଣ୍ଣ ହୋଇଛି';

  @override
  String get stagePaymentReleased => 'ଦେୟ ମୁକ୍ତ କରାଯାଇଛି';

  @override
  String get stageDisputeRaised => 'ବିବାଦ ଉଠାଯାଇଛି';

  @override
  String get activeJobTitle => 'ସକ୍ରିୟ କାର୍ଯ୍ୟ ଅଗ୍ରଗତି';

  @override
  String get actionAcceptJob => 'କାର୍ଯ୍ୟ ଗ୍ରହଣ କରନ୍ତୁ';

  @override
  String get actionWorkerArrived => 'ମୁଁ ପହଞ୍ଚିଛି';

  @override
  String get actionStartWork => 'କାର୍ଯ୍ୟ ଆରମ୍ଭ କରନ୍ତୁ';

  @override
  String get actionCompleteJob => 'କାର୍ଯ୍ୟ ଶେଷ କରନ୍ତୁ';

  @override
  String get actionAwaitingPayment => 'ଦେୟ ମୁକ୍ତିକୁ ଅପେକ୍ଷା';

  @override
  String get actionJobFinished => 'କାର୍ଯ୍ୟ ସମ୍ପୂର୍ଣ୍ଣ ଶେଷ ହୋଇଛି';

  @override
  String get actionDisputeMediation => 'ବିବାଦ ସମୀକ୍ଷାଧୀନ';

  @override
  String get actionWaitingAcceptance => 'କର୍ମଚାରୀଙ୍କ ସ୍ୱୀକୃତିକୁ ଅପେକ୍ଷା';

  @override
  String get actionConfirmArrival => 'ଆଗମନ ନିଶ୍ଚିତ କରନ୍ତୁ';

  @override
  String get actionConfirmCompletion => 'କାର୍ଯ୍ୟ ସମାପ୍ତି ନିଶ୍ଚିତ କରନ୍ତୁ';

  @override
  String get actionReleasePayment => 'ଦେୟ ମୁକ୍ତ କରନ୍ତୁ';

  @override
  String get actionPaymentDone => 'ଦେୟ ସମ୍ପନ୍ନ ହୋଇଛି';

  @override
  String get actionAskForHelp => 'ସାହାଯ୍ୟ ମାଗନ୍ତୁ';

  @override
  String get actionDispute => 'ବିବାଦ ଦାଖଲ କରନ୍ତୁ';

  @override
  String get simpleModeSpokenLabel =>
      'କହିବା ଏବଂ କାର୍ଯ୍ୟକାରୀ କରିବା ପାଇଁ ଟ୍ୟାପ୍ କରନ୍ତୁ';

  @override
  String get routeAndEtaTitle => 'ମାର୍ଗ ଏବଂ ଯାତ୍ରା ସମୟ';

  @override
  String get openInMapsBtn => 'ମାନଚିତ୍ରରେ ଖୋଲନ୍ତୁ';

  @override
  String get demoModeChip => 'ଡେମୋ ମୋଡ୍';

  @override
  String get scheduleTitle => 'କର୍ମଚାରୀ କାର୍ଯ୍ୟସୂଚୀ ଏବଂ ଯାତ୍ରା';

  @override
  String get scheduleDayView => 'ଦିନ';

  @override
  String get scheduleWeekView => 'ସପ୍ତାହ';

  @override
  String get scheduleWeeklyTotal => 'ସପ୍ତାହର ଆନୁମାନିକ ଆୟ';

  @override
  String get ticketScreenTitle => 'ଡିଜିଟାଲ୍ କାର୍ଯ୍ୟ ଟିକେଟ୍';

  @override
  String get refreshTicketTooltip => 'ଟିକେଟ୍ କ୍ୟୁଆର୍ ରିଫ୍ରେସ୍ କରନ୍ତୁ';

  @override
  String get ticketOfflineNotice =>
      'ସୁରକ୍ଷା ଟୋକନ୍ ରିଫ୍ରେସ୍ ପାଇଁ ଇଣ୍ଟରନେଟ୍ ଆବଶ୍ୟକ। ଦୟାକରି ସ୍କାନ୍ ପୂର୍ବରୁ ପୁନଃ ସଂଯୋଗ କରନ୍ତୁ।';

  @override
  String get ticketBookingPassHeader => 'ବୁକିଂ ପାସ୍';

  @override
  String get ticketScanInstructions =>
      'କାର୍ଯ୍ୟସ୍ଥଳରେ ପହଞ୍ଚିବା ପରେ ଏହି କ୍ୟୁଆର୍ ପାସ୍ ନିଯୁକ୍ତିଦାତାଙ୍କୁ ଦେଖାନ୍ତୁ';

  @override
  String get ticketAutoRefreshesIn => 'ରିଫ୍ରେସ୍ ହେବ';

  @override
  String get ticketReplayShieldTitle => 'ରିପ୍ଲେ ସୁରକ୍ଷା ସକ୍ରିୟ';

  @override
  String get ticketReplayShieldBody =>
      'ଏହି ସୁରକ୍ଷା ପାସ୍ କେବଳ ଥରେ ବ୍ୟବହାରଯୋଗ୍ୟ ଏବଂ ପ୍ରତି ୨ ମିନିଟରେ ବଦଳିଥାଏ। ସ୍କ୍ରିନସଟ୍ ପୁନଃ ବ୍ୟବହାର ହୋଇପାରିବ ନାହିଁ।';

  @override
  String get attendanceScannerTitle => 'ଶ୍ରମିକ କ୍ୟୁଆର୍ ସ୍କାନ୍ କରନ୍ତୁ';

  @override
  String get attendanceScannerInstructions =>
      'ଉପସ୍ଥିତି ଦର୍ଜ କରିବା ପାଇଁ ଶ୍ରମିକଙ୍କ ଡିଜିଟାଲ୍ ଟିକେଟ୍ କ୍ୟୁଆର୍ କୋଡ୍ ଫ୍ରେମ୍ ଭିତରେ ରଖନ୍ତୁ।';

  @override
  String get ticketReplayRefusedTitle => 'ରିପ୍ଲେ ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଯାଇଛି';

  @override
  String get ticketExpiredTitle => 'ଟିକେଟ୍ ଅବଧି ସମାପ୍ତ';

  @override
  String get attendanceScanFailedTitle => 'ଉପସ୍ଥିତି ସ୍କାନ୍ ବିଫଳ';

  @override
  String get attendanceConfirmedTitle => 'ଉପସ୍ଥିତି ନିଶ୍ଚିତ ହୋଇଛି!';

  @override
  String get workerMarkedArrived => 'ଶ୍ରମିକ ପହଞ୍ଚିଥିବା ଚିହ୍ନିତ ହୋଇଛନ୍ତି';

  @override
  String get scanAgain => 'ପୁଣି ସ୍କାନ୍ କରନ୍ତୁ';

  @override
  String get scanDone => 'ସମ୍ପନ୍ନ';

  @override
  String get viewActiveJob => 'ସକ୍ରିୟ କାର୍ଯ୍ୟ ଦେଖନ୍ତୁ';

  @override
  String get actionShowTicket => 'କ୍ୟୁଆର୍ ଟିକେଟ୍ ଦେଖାନ୍ତୁ';

  @override
  String get actionScanWorkerQr => 'ଶ୍ରମିକ କ୍ୟୁଆର୍ ସ୍କାନ୍ କରନ୍ତୁ';

  @override
  String get openSettings => 'ସେଟିଙ୍ଗସ୍ ଖୋଲନ୍ତୁ';

  @override
  String get bookingCodeCopied => 'ବୁକିଂ କୋଡ୍ କପି ହୋଇଛି';

  @override
  String get verifyYourPresence => 'ଆପଣଙ୍କ ଉପସ୍ଥିତି ଯାଞ୍ଚ କରନ୍ତୁ';

  @override
  String get verifyPresenceSubtitle =>
      'କାର୍ଯ୍ୟ ଆରମ୍ଭ ପୂର୍ବରୁ ଚେହେରା ମେଳ ଏବଂ ସାଇଟ୍ ଜିଓଫେନ୍ସ ଯାଞ୍ଚ ଆବଶ୍ୟକ';

  @override
  String get gpsPerimeterCheck => 'ଜିପିଏସ୍ କାର୍ଯ୍ୟସ୍ଥଳୀ ଜିଓଫେନ୍ସ ଯାଞ୍ଚ';

  @override
  String get withinPerimeter => 'କାର୍ଯ୍ୟସ୍ଥଳୀ ସୀମା ଭିତରେ';

  @override
  String get outsidePerimeter => 'କାର୍ଯ୍ୟସ୍ଥଳୀ ସୀମା ବାହାରେ';

  @override
  String distanceFromSite(String distance, String radius) {
    return 'କାର୍ଯ୍ୟସ୍ଥଳୀରୁ ଦୂରତା: $distanceମି (ଅନୁମୋଦିତ: $radiusମି)';
  }

  @override
  String get mockLocationDetected =>
      'ନକଲି / ମକ୍ ଜିପିଏସ୍ ଚିହ୍ନଟ ହୋଇଛି। ଆରମ୍ଭ ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଯାଇଛି ଏବଂ ସମୀକ୍ଷା ପାଇଁ ଲଗ୍ କରାଯାଇଛି।';

  @override
  String get faceSelfieCheck => 'ସାମ୍ନା କ୍ୟାମେରା ଚେହେରା ଯାଞ୍ଚ';

  @override
  String get takeSelfieBtn => 'ଯାଞ୍ଚ ସେଲଫି ନିଅନ୍ତୁ';

  @override
  String get retakeSelfieBtn => 'ପୁନର୍ବାର ସେଲଫି ନିଅନ୍ତୁ';

  @override
  String get verifyAndStartJob =>
      'ଉପସ୍ଥିତି ଯାଞ୍ଚ କରନ୍ତୁ ଏବଂ କାର୍ଯ୍ୟ ଆରମ୍ଭ କରନ୍ତୁ';

  @override
  String get verificationFailed => 'ଯାଞ୍ଚ ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଯାଇଛି';

  @override
  String outOfGeofenceMessage(String distance, String radius) {
    return 'ଆପଣ କାର୍ଯ୍ୟସ୍ଥଳୀରୁ $distanceମି ଦୂରରେ ଅଛନ୍ତି। ଆରମ୍ଭ କରିବା ପାଇଁ ଆପଣଙ୍କୁ $radiusମି ଭିତରେ ରହିବାକୁ ହେବ।';
  }

  @override
  String get getHelpOrSupport => 'ସହାୟତା ପାଆନ୍ତୁ';

  @override
  String get completionTitle => 'କାର୍ଯ୍ୟ ସମାପ୍ତି ଏବଂ ପ୍ରମାଣ';

  @override
  String get completionSubtitle =>
      'ସମାପ୍ତି ଯାଞ୍ଚ ପାଇଁ ସେଲଫି ଏବଂ କାର୍ଯ୍ୟର ଫଟୋ ଦାଖଲ କରନ୍ତୁ';

  @override
  String get workResultPhotos => 'କାର୍ଯ୍ୟ ପ୍ରମାଣ ଫଟୋ (ବ୍ୟକ୍ତିଗତ)';

  @override
  String get addWorkPhoto => 'ଫଟୋ ଯୋଡନ୍ତୁ';

  @override
  String get completeAndSubmit => 'ସମାପ୍ତି ଦାଖଲ କରନ୍ତୁ ଏବଂ ଟାଇମର୍ ବନ୍ଦ କରନ୍ତୁ';

  @override
  String get midJobCheckTitle => 'ମଧ୍ୟବର୍ତ୍ତୀ କାର୍ଯ୍ୟ ଯାଞ୍ଚ ଆବଶ୍ୟକ';

  @override
  String get midJobCheckSubtitle =>
      'ଉଚ୍ଚ ମୂଲ୍ୟ କାର୍ଯ୍ୟ ସୁରକ୍ଷା ଯାଞ୍ଚ (ମଜୁରୀ >= ₹୨,୦୦୦)';

  @override
  String get midJobConfirmSelfie => 'ମଧ୍ୟବର୍ତ୍ତୀ ସେଲଫି ନିଅନ୍ତୁ';

  @override
  String get midJobCustomerConfirm =>
      'ଶ୍ରମିକ ସାଇଟରେ ଉପସ୍ଥିତ ଥିବା ନିଶ୍ଚିତ କରନ୍ତୁ';

  @override
  String get timerTitle => 'ଲାଇଭ୍ କାର୍ଯ୍ୟ ଟାଇମର୍';

  @override
  String get timerRunning => 'ଟାଇମର୍ ଚାଲୁଅଛି';

  @override
  String get timerPaused => 'ଟାଇମର୍ ବନ୍ଦ ଅଛି';

  @override
  String get elapsedTime => 'ଅତିବାହିତ ସମୟ';

  @override
  String get smartNoShowEngineHeader => 'ସ୍ମାର୍ଟ ନୋ-ଶୋ ରିକଭରୀ ଇଞ୍ଜିନ';

  @override
  String get arrivalGraceExpiredAlert => '⚠️ ଆଗମନ ରିହାତି ସମୟ ସମାପ୍ତ';

  @override
  String get workerHasNotArrivedTitle => 'ଶ୍ରମିକ ଆସିନାହାଁନ୍ତି';

  @override
  String workerHasNotArrivedSubtitle(
    String workerName,
    int minutesLate,
    String jobTitle,
  ) {
    return '$workerName $jobTitle ପାଇଁ ଧାର୍ଯ୍ୟ ସମୟଠାରୁ $minutesLate ମିନିଟ୍ ବିଳମ୍ବରେ ଅଛନ୍ତି।';
  }

  @override
  String get wait10MinutesAction => '10 ମିନିଟ୍ ଅପେକ୍ଷା କରନ୍ତୁ';

  @override
  String get callWorkerDirectlyAction => '📞 ଶ୍ରମିକଙ୍କୁ ସିଧାସଳଖ କଲ୍ କରନ୍ତୁ';

  @override
  String get findSmartReplacementAction => '⚡ ସ୍ମାର୍ଟ ବିକଳ୍ପ ଶ୍ରମିକ ଖୋଜନ୍ତୁ';

  @override
  String get gracePeriodExtendedMsg =>
      '+10 ମିନିଟ୍ ଅପେକ୍ଷା ସମୟ ଯୋଡ଼ାଗଲା। ଟାଇମର୍ ବନ୍ଦ ରହିଛି।';

  @override
  String get maskedCallDemoMsg =>
      'କଲ୍ କରାଯାଉଛି... (ଡେମୋ ମୋଡ୍: ମାସ୍କଡ୍ କଲ୍ P7.2 ରେ ଆସିବ)';

  @override
  String replacementBookedMsg(String workerName) {
    return '$workerName ଙ୍କ ସହିତ ବିକଳ୍ପ ବୁକ୍ ହେଲା! ମୂଳକୁ ନୋ-ଶୋ ଚିହ୍ନିତ କରାଗଲା।';
  }

  @override
  String get rankedReplacementsTitle => 'ନିକଟସ୍ଥ ଯୋଗ୍ୟ ଶ୍ରମିକ ତାଲିକା';

  @override
  String get noReplacementsFoundMsg =>
      'ବର୍ତ୍ତମାନ କୌଣସି ନିକଟସ୍ଥ ବିକଳ୍ପ ଶ୍ରମିକ ଉପଲବ୍ଧ ନାହାଁନ୍ତି।';

  @override
  String get requestReplacementOneTap => 'ବିକଳ୍ପ ଅନୁରୋଧ କରନ୍ତୁ (1-ଟ୍ୟାପ୍)';

  @override
  String get smartNoShowTrustNote =>
      'ନୋ-ଶୋ ରେ ସମ୍ପୂର୍ଣ୍ଣ ଫେରସ୍ତ। ବିକଳ୍ପ ଶ୍ରମିକମାନଙ୍କ ପୃଷ୍ଠଭୂମି ଯାଞ୍ଚ ହୋଇଛି।';

  @override
  String get openRecoveryEngineAction => 'ନୋ-ଶୋ ରିକଭରୀ ଇଞ୍ଜିନ ଖୋଲନ୍ତୁ';

  @override
  String get runningLateQuestionAction => 'ଡେରି ହେଉଛି କି? ETA ଜଣାନ୍ତୁ';

  @override
  String runningLateReportedBadge(int minutes) {
    return 'ବିଳମ୍ବ ବିଷୟରେ ଜଣାଇ ଦିଆଗଲା (+$minutesମି)। ଟାଇମର୍ ବନ୍ଦ ରହିଛି।';
  }

  @override
  String get runningLateDialogTitle => 'ବିଳମ୍ବ ହେଉଛି କି?';

  @override
  String get runningLateDialogSubtitle =>
      'ଆପଣଙ୍କ ସମ୍ଭାବ୍ୟ ବିଳମ୍ବ ସମୟ ବାଛନ୍ତୁ। ଏହା ନିୟୋକ୍ତାଙ୍କୁ ଜଣାଇବ ଏବଂ ଟାଇମର୍‌କୁ ଥରେ ବନ୍ଦ ରଖିବ।';

  @override
  String get sendEtaAction => 'ETA ପଠାନ୍ତୁ';

  @override
  String runningLateSuccessMsg(int minutes) {
    return '+$minutes ମିନିଟ୍ ବିଳମ୍ବ ଜଣାଇ ଦିଆଗଲା। ନିୟୋକ୍ତାଙ୍କୁ ସୂଚନା ମିଳିଲା।';
  }

  @override
  String get jobHistoryTitle => 'କାର୍ଯ୍ୟ ଇତିହାସ ଏବଂ ରେଟିଂ';

  @override
  String get jobHistoryHeader => 'କାର୍ଯ୍ୟ ଇତିହାସ';

  @override
  String get favouritesTitle => 'ପସନ୍ଦ ଏବଂ ବିଶ୍ୱାସ ମଣ୍ଡଳ';

  @override
  String get rateJobTitle => 'କାର୍ଯ୍ୟକୁ ରେଟ୍ ଏବଂ ସମୀକ୍ଷା କରନ୍ତୁ';

  @override
  String get quickTagsLabel => 'ଦ୍ରୁତ ଟ୍ୟାଗ୍';

  @override
  String get reviewCommentLabel => 'ମତାମତ ଏବଂ ସମୀକ୍ଷା (ବୈକଳ୍ପିକ)';

  @override
  String get reviewCommentHint =>
      'ସମୁଦାୟକୁ ସାହାଯ୍ୟ କରିବାକୁ ଆପଣଙ୍କ ଅଭିଜ୍ଞତା ବାଣ୍ଟନ୍ତୁ...';

  @override
  String get submitReviewBtn => 'ଯାଞ୍ଚ ହୋଇଥିବା ସମୀକ୍ଷା ଦାଖଲ କରନ୍ତୁ';

  @override
  String get reportDisputeTitle => 'କାର୍ଯ୍ୟ ବିବାଦ ରିପୋର୍ଟ କରନ୍ତୁ';

  @override
  String get disputeFreezeNotice =>
      'ବିବାଦ ଦାଖଲ କରିବା ଦ୍ୱାରା ଏସ୍କ୍ରୋ ଟଙ୍କା ପ୍ରଦାନ ସ୍ଥଗିତ ରହେ ଏବଂ ସମୀକ୍ଷା ପାଇଁ ପଠାଯାଏ |';

  @override
  String get disputeIssueTypeLabel => 'ସମସ୍ୟା ପ୍ରକାର ବାଛନ୍ତୁ';

  @override
  String get disputeDetailsLabel => 'ସମସ୍ୟା ବିବରଣୀ ଏବଂ ସମୟସୀମା';

  @override
  String get disputeDetailsHint => 'କଣ ଘଟିଲା ସ୍ପଷ୍ଟ ଭାବରେ ବର୍ଣ୍ଣନା କରନ୍ତୁ...';

  @override
  String get disputeEvidenceLabel => 'ପ୍ରମାଣ ଫଟୋ (ବୈକଳ୍ପିକ)';

  @override
  String get submitDisputeBtn => 'ଆନୁଷ୍ଠାନିକ ବିବାଦ ଦାଖଲ କରନ୍ତୁ';

  @override
  String get disputeTypeNoShow => 'ଉପସ୍ଥିତ ହେଲେ ନାହିଁ / ଅନୁପସ୍ଥିତି';

  @override
  String get disputeTypeIncompleteWork => 'ଅସମ୍ପୂର୍ଣ୍ଣ କାମ / ଶୀଘ୍ର ଚାଲିଗଲେ';

  @override
  String get disputeTypePoorQuality => 'ନିମ୍ନ ମାନର କାମ';

  @override
  String get disputeTypeWrongProduct => 'ଭୁଲ୍ ଉତ୍ପାଦ / ଗୁଣବତ୍ତା ଅମେଳ';

  @override
  String get disputeTypePaymentIssue => 'ପେମେଣ୍ଟ ସମସ୍ୟା / ଏସ୍କ୍ରୋ ବିବାଦ';

  @override
  String get disputeTypeUnsafeConduct => 'ଅସୁରକ୍ଷିତ ଆଚରଣ';

  @override
  String get disputeTypeVerificationProblem => 'ଯାଞ୍ଚ / ପରିଚୟ ଅମେଳ';

  @override
  String get disputeTrackingTitle => 'ବିବାଦ ସ୍ଥିତି ଟ୍ରାକିଂ';

  @override
  String get settingsSectionHeader => 'ସେଟିଙ୍ଗ୍ସ';

  @override
  String get filterAll => 'ସମସ୍ତ';

  @override
  String get filterCompleted => 'ସମ୍ପନ୍ନ';

  @override
  String get filterDisputed => 'ବିବାଦିତ';

  @override
  String get filterInProgress => 'ଚାଲୁଅଛି';

  @override
  String get filterCancelled => 'ବାତିଲ';

  @override
  String get walletTitle => 'ୱାଲେଟ୍ ଏବଂ ଏସ୍କ୍ରୋ';

  @override
  String get walletBalanceHeader => 'ୱାଲେଟ୍ ବାଲାନ୍ସ';

  @override
  String get escrowProtected => 'ଏସ୍କ୍ରୋ ସୁରକ୍ଷିତ';

  @override
  String get todaysReleased => 'ଆଜିର ମୁକ୍ତ';

  @override
  String get pendingEscrow => 'ବାକି ଥିବା ଏସ୍କ୍ରୋ';

  @override
  String get withdrawAction => 'ଉଠାଣ କରନ୍ତୁ';

  @override
  String get scanUpiQr => 'UPI QR ସ୍କାନ୍ କରନ୍ତୁ';

  @override
  String get recentTransactions => 'ସାମ୍ପ୍ରତିକ କାରବାର';

  @override
  String get withdrawEarningsTitle => 'ଆୟ ଉଠାଣ କରନ୍ତୁ';

  @override
  String get demoWithdrawNote =>
      'ଡେମୋ ମୋଡ୍: ବ୍ୟାଙ୍କିଂ ପାର୍ଟନର ମିଳିବା ପର୍ଯ୍ୟନ୍ତ ସିମୁଲେଟେଡ୍ ପେଆଉଟ୍ ଲେଜର ଡେବିଟ୍।';

  @override
  String get transferToUpi => 'ସ୍ଥାନାନ୍ତର (UPI VPA / ବ୍ୟାଙ୍କ)';

  @override
  String get confirmPayoutWithdrawal => 'ଉଠାଣ ନିଶ୍ଚିତ କରନ୍ତୁ';

  @override
  String get demoPayoutCompleted => 'ଡେମୋ ପେଆଉଟ୍ ସମ୍ପୂର୍ଣ୍ଣ ହେଲା';

  @override
  String get demoUpiScanner => 'ଡେମୋ ମୋଡ୍: ସିମୁଲେଟେଡ୍ UPI ସ୍କାନର୍';

  @override
  String get demoUpiNote =>
      'କୌଣସି ପ୍ରକୃତ ଟଙ୍କା ସ୍ଥାନାନ୍ତରିତ ହେବ ନାହିଁ। ପର୍ଯ୍ୟାୟ 5.2 ରେ ପେମେଣ୍ଟ ରେଳ ସଂଯୋଗ ହେବ।';

  @override
  String get noTransactionsFound => 'କୌଣସି କାରବାର ମିଳିଲା ନାହିଁ';

  @override
  String get noTransactionsSubtitle =>
      'ସମ୍ପୂର୍ଣ୍ଣ ହୋଇଥିବା ଦୈନିକ ମଜୁରୀ ଏବଂ ସ୍ଥାନାନ୍ତର ଏଠାରେ ଦେଖାଯିବ।';

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
  String get pendingEscrowRelease => 'ଏସ୍କ୍ରୋ ରିଲିଜ୍ ବାକି ଅଛି';

  @override
  String get protectedBadge => 'ସୁରକ୍ଷିତ';

  @override
  String get releaseEscrowPayment => 'ଏସ୍କ୍ରୋ ପେମେଣ୍ଟ ରିଲିଜ୍ କରନ୍ତୁ';

  @override
  String get confirmAndRelease => 'ନିଶ୍ଚିତ କରନ୍ତୁ ଏବଂ ପେମେଣ୍ଟ ରିଲିଜ୍ କରନ୍ତୁ';

  @override
  String get workerPayout => 'ଶ୍ରମିକ ପେଆଉଟ୍ (ଉପଲବ୍ଧ ବାଲାନ୍ସ)';

  @override
  String get escrowAutoReleaseNotice =>
      'ନିୟୋଜକ ନିଶ୍ଚିତ କଲା ମାତ୍ରେ କିମ୍ବା କୌଣସି ବିବାଦ ନଥିଲେ ୨୪ ଘଣ୍ଟା ମଧ୍ୟରେ ପେମେଣ୍ଟ ଆପେ ଆପେ ରିଲିଜ୍ ହେବ।';

  @override
  String get escrowEarningsSecured => 'ଆପଣଙ୍କ ରୋଜଗାର ଏସ୍କ୍ରୋରେ ୧୦୦% ସୁରକ୍ଷିତ';

  @override
  String get releaseEscrowSuccess =>
      'ଶ୍ରମିକ ୱାଲେଟକୁ ପେମେଣ୍ଟ ସଫଳତାର ସହ ରିଲିଜ୍ ହେଲା!';

  @override
  String get earningsDashboardTitle => 'ରୋଜଗାର ଏବଂ କାର୍ଯ୍ୟଦକ୍ଷତା';

  @override
  String get earningsToday => 'ଆଜିର ରୋଜଗାର';

  @override
  String get earningsThisWeek => 'ଏହି ସପ୍ତାହ';

  @override
  String get earningsThisMonth => 'ଏହି ମାସ';

  @override
  String get earningsTotal => 'ସମୁଦାୟ ରୋଜଗାର';

  @override
  String get earningsCompletedJobs => 'ସମ୍ପୂର୍ଣ୍ଣ ହୋଇଥିବା କାର୍ଯ୍ୟ';

  @override
  String get earningsFarmOrders => 'କୃଷି ଅର୍ଡର';

  @override
  String get earningsAverageRating => 'ହାରାହାରି ରେଟିଂ';

  @override
  String get earningsDailyGoal => 'ଦୈନିକ ଲକ୍ଷ୍ୟ';

  @override
  String get earningsDailyGoalProgress => 'ଆଜିର ଲକ୍ଷ୍ୟ ଅଗ୍ରଗତି';

  @override
  String get earningsPayoutTrends => 'ପେଆଉଟ୍ ଟ୍ରେଣ୍ଡ';

  @override
  String get earningsTimeframe14Days => '୧୪ ଦିନ';

  @override
  String get earningsTimeframe6Months => '୬ ମାସ';

  @override
  String get earningsBestDayTitle => 'ସର୍ବୋତ୍ତମ ରୋଜଗାର ଦିନ';

  @override
  String earningsBestDaySubtitle(Object amount, Object date) {
    return 'ଆପଣ $date ରେ $amount ରୋଜଗାର କରିଛନ୍ତି!';
  }

  @override
  String get earningsSetDailyGoal => 'ଦୈନିକ ଲକ୍ଷ୍ୟ ସେଟ୍ କରନ୍ତୁ';

  @override
  String get earningsSaveGoal => 'ଲକ୍ଷ୍ୟ ସଂରକ୍ଷଣ କରନ୍ତୁ';

  @override
  String get savingsGoalsTitle => 'ସଞ୍ଚୟ ଲକ୍ଷ୍ୟ ଯୋଜନାକାରୀ';

  @override
  String get savingsGoalsSubtitle =>
      'ନିଜର ସ୍ୱପ୍ନକୁ ଟ୍ରାକ୍ କରନ୍ତୁ। ଲକ୍ଷ୍ୟଗୁଡ଼ିକ ଟଙ୍କା ଲକ୍ କରେ ନାହିଁ।';

  @override
  String get savingsGoalsVirtualNotice =>
      'ଭର୍ଚୁଆଲ୍ ଲକ୍ଷ୍ୟ ଟ୍ରାକର୍: ଲକ୍ଷ୍ୟଗୁଡ଼ିକ ଯୋଜନା ପାଇଁ ସାହାଯ୍ୟ କରେ। ଆପଣଙ୍କ ଟଙ୍କା ସର୍ବଦା ୱାଲେଟରେ ଉପଲବ୍ଧ ଥାଏ।';

  @override
  String get savingsGoalNew => 'ନୂତନ ସଞ୍ଚୟ ଲକ୍ଷ୍ୟ';

  @override
  String get savingsGoalCreate => 'ଲକ୍ଷ୍ୟ ତିଆରି କରନ୍ତୁ';

  @override
  String get savingsGoalTarget => 'ଲକ୍ଷ୍ୟ ରାଶି';

  @override
  String get savingsGoalSaved => 'ଏପର୍ଯ୍ୟନ୍ତ ସଞ୍ଚୟ';

  @override
  String get savingsGoalDeadline => 'ଶେଷ ତାରିଖ';

  @override
  String get savingsGoalCategory => 'ବର୍ଗ';

  @override
  String get savingsGoalSuggestedPlan => 'ପରାମର୍ଶିତ ସଞ୍ଚୟ ଯୋଜନା';

  @override
  String get savingsGoalAddSavings => 'ସଞ୍ଚୟ ଅଗ୍ରଗତି ରେକର୍ଡ କରନ୍ତୁ';

  @override
  String get savingsGoalAddAmount => 'ସଞ୍ଚୟ ରାଶି';

  @override
  String get savingsGoalCompletedBadge => 'ଲକ୍ଷ୍ୟ ହାସଲ ହୋଇଛି! 🎉';

  @override
  String get savingsGoalActiveBadge => 'ଚାଲୁ ରହିଛି';

  @override
  String get savingsGoalCategorySchoolFees => 'ସ୍କୁଲ ଫିସ୍';

  @override
  String get savingsGoalCategoryEquipment => 'କାମ ଉପକରଣ';

  @override
  String get savingsGoalCategoryScooter => 'ସ୍କୁଟର / ଗାଡ଼ି';

  @override
  String get savingsGoalCategorySeeds => 'ବିହନ ଏବଂ ଖତ';

  @override
  String get savingsGoalCategoryEmergency => 'ଜରୁରୀକାଳୀନ ପାଣ୍ଠି';

  @override
  String get savingsGoalCategoryHome => 'ଘର ମରାମତି';

  @override
  String get savingsGoalCategoryCustom => 'କଷ୍ଟମ୍ ଲକ୍ଷ୍ୟ';

  @override
  String get savingsGoalDelete => 'ଲକ୍ଷ୍ୟ ଡିଲିଟ୍ କରନ୍ତୁ';

  @override
  String get savingsGoalDeleteConfirm =>
      'ଆପଣ ନିଶ୍ଚିତ ଏହି ସଞ୍ଚୟ ଲକ୍ଷ୍ୟକୁ ହଟାଇବାକୁ ଚାହାଁନ୍ତି କି?';

  @override
  String get savingsGoalEmptyState =>
      'ସଞ୍ଚୟ ଲକ୍ଷ୍ୟ ସ୍ଥିର କରି ନିଜର ପରବର୍ତ୍ତୀ ଯୋଜନା କରନ୍ତୁ।';

  @override
  String get savingsGoalsPlanGoals => 'ଲକ୍ଷ୍ୟ ଯୋଜନା କରନ୍ତୁ';

  @override
  String get farmerWorkspace => 'କୃଷକ କାର୍ଯ୍ୟକ୍ଷେତ୍ର';

  @override
  String get farmerEmpoweredNetwork =>
      'ଉଦ୍ୟୋଗସେତୁ ଡାଇରେକ୍ଟ ଏଗ୍ରି-ନେଟୱାର୍କ ଦ୍ୱାରା ପରିଚାଳିତ';

  @override
  String get farmerProduceSold => 'ବିକ୍ରି ହୋଇଥିବା ଫସଲ';

  @override
  String get farmerThisMonth => 'ଏହି ମାସରେ';

  @override
  String get farmerDirectEarnings => 'ସିଧାସଳଖ ଆୟ';

  @override
  String get farmerZeroMiddlemen => 'ମଧ୍ୟସ୍ଥିମୁକ୍ତ';

  @override
  String get farmerActiveLabor => 'ସକ୍ରିୟ ଶ୍ରମିକ';

  @override
  String get farmerHarvestShiftPlaceholder => 'ଅମଳ ଶିଫ୍ଟ (P6.3)';

  @override
  String farmerBooked(int count) {
    return '$count ବୁକ୍ ହୋଇଛି';
  }

  @override
  String get farmerWeatherAdvisoryRadar => 'ପାଣିପାଗ ପରାମର୍ଶ ରାଡାର';

  @override
  String get farmerSimulatedForecast => 'ସିମୁଲେଟେଡ୍ ପୂର୍ବାନୁମାନ';

  @override
  String farmerRainProbability(int percent) {
    return '$percent% ବର୍ଷା ସମ୍ଭାବନା';
  }

  @override
  String get farmerBookHarvestHelpers => 'ଅମଳ ଶ୍ରମିକ ବୁକ୍ କରନ୍ତୁ';

  @override
  String get farmerViewIrrigationGuide => 'ଜଳସେଚନ ଗାଇଡ୍ ଦେଖନ୍ତୁ';

  @override
  String get farmerLiveMandiPrices => 'ଲାଇଭ୍ ମଣ୍ଡି ଦର ଏବଂ ଚାହିଦା';

  @override
  String get farmerLiveFeed => 'ଲାଇଭ୍ ଫିଡ୍';

  @override
  String get farmerAllCrops => 'ସମସ୍ତ ଫସଲ';

  @override
  String get farmerVegetables => 'ପନିପରିବା';

  @override
  String get farmerGrainsAndPulses => 'ଶସ୍ୟ ଏବଂ ଡାଲି';

  @override
  String get farmerNoPricesInCategory => 'ଏହି ବର୍ଗରେ ମଣ୍ଡି ଦର ଉପଲବ୍ଧ ନାହିଁ';

  @override
  String get farmerSelectAllCropsHint =>
      'କର୍ଣ୍ଣାଟକ APMC ର ସମସ୍ତ ଦର ଦେଖିବାକୁ ସମସ୍ତ ଫସଲ ଚୟନ କରନ୍ତୁ।';

  @override
  String farmerUpdatedDate(String date) {
    return 'ଅପଡେଟ୍ ହୋଇଛି $date';
  }

  @override
  String get farmerApmcKarnatakaFeed => 'କର୍ଣ୍ଣାଟକ APMC ଫିଡ୍';

  @override
  String get farmerEssentialSuite => 'କୃଷକ ଆବଶ୍ୟକୀୟ ସେବା';

  @override
  String get farmerRentTractor => 'ଟ୍ରାକ୍ଟର ଭଡ଼ା ନିଅନ୍ତୁ';

  @override
  String get farmerHireWorkers => 'ଶ୍ରମିକ ନିୟୋଜିତ କରନ୍ତୁ';

  @override
  String get farmerSoilAiTest => 'ମାଟି AI ପରୀକ୍ଷା';

  @override
  String get farmerSellProduce => 'ଫସଲ ବିକ୍ରି କରନ୍ତୁ';

  @override
  String get farmerPestAiDoc => 'କୀଟ AI ଡାକ୍ତର';

  @override
  String get farmerGovtSchemes => 'ସରକାରୀ ଯୋଜନା';

  @override
  String get farmerAgriDrone => 'କୃଷି ଡ୍ରୋନ୍';

  @override
  String get farmerIrrigationAi => 'ଜଳସେଚନ AI';

  @override
  String farmerComingInPhase(String phase) {
    return '$phase ରେ ଉପଲବ୍ଧ ହେବ';
  }

  @override
  String get farmerUnderstood => 'ବୁଝିଲି';

  @override
  String get farmerGotIt => 'ଠିକ୍ ଅଛି';

  @override
  String get farmerHireWorkersDesc =>
      'କୃଷକମାନେ ସିଧାସଳଖ ଶ୍ରମିକ ଆବଶ୍ୟକତା ପୋଷ୍ଟ କରି ନିକଟସ୍ଥ ଯାଞ୍ଚ ହୋଇଥିବା ଶ୍ରମିକଙ୍କୁ ନିୟୋଜିତ କରିପାରିବେ।';

  @override
  String get farmerRentTractorDesc =>
      'ନିକଟସ୍ଥ ହବ୍‌ରୁ ଟ୍ରାକ୍ଟର ଏବଂ ହାର୍ଭେଷ୍ଟର ଭଡ଼ାରେ ନିଅନ୍ତୁ।';

  @override
  String get farmerSoilAiTestDesc =>
      'ମାଟି ପରୀକ୍ଷା ରିପୋର୍ଟ ଅପଲୋଡ୍ କରି ତୁରନ୍ତ AI ସାର ସୁପାରିଶ ପାଆନ୍ତୁ।';

  @override
  String get farmerSellProduceDesc =>
      'ମଧ୍ୟସ୍ଥି ବିନା ସିଧାସଳଖ ବ୍ୟବସାୟୀଙ୍କୁ ଫସଲ ବିକ୍ରି କରନ୍ତୁ।';

  @override
  String get farmerPestAiDocDesc =>
      'ପୋକ ବା ରୋଗର ଫଟୋ ଉଠାଇ ତୁରନ୍ତ AI ଉପଚାର ପାଆନ୍ତୁ।';

  @override
  String get farmerGovtSchemesDesc =>
      'ପିଏମ୍-କିଷାନ୍ ଏବଂ ଫସଲ ବୀମା ଯୋଜନା ସମ୍ପର୍କରେ ଜାଣନ୍ତୁ।';

  @override
  String get farmerAgriDroneDesc =>
      'ସ୍ପ୍ରେ ପାଇଁ କୃଷି ଡ୍ରୋନ୍ ପାଇଲଟ୍ ବୁକ୍ କରନ୍ତୁ।';

  @override
  String get farmerIrrigationAiDesc => 'ପାଣିପାଗ ଅନୁଯାୟୀ ସ୍ମାର୍ଟ ଜଳସେଚନ ଯୋଜନା।';

  @override
  String get farmerHomeTitle => 'କୃଷକ ହୋମ୍';

  @override
  String get farmerSimulateRainDev => 'ବର୍ଷା ପୂର୍ବାନୁମାନ ସିମୁଲେସନ୍ (Dev)';

  @override
  String get farmerFailedLoadMandi => 'ମଣ୍ଡି ଦର ଲୋଡ୍ କରିବାରେ ବିଫଳ ହେଲା';

  @override
  String get farmerHighDemand => 'ଅଧିକ ଚାହିଦା';

  @override
  String get farmerStable => 'ସ୍ଥିର';

  @override
  String get farmerFrpGuaranteed => 'FRP ନିଶ୍ଚିତ';

  @override
  String get farmerMspProtected => 'MSP ସୁରକ୍ଷିତ';

  @override
  String get farmerOversupply => 'ଅଧିକ ଆବକ';

  @override
  String get farmerModerate => 'ମଧ୍ୟମ';

  @override
  String get farmerProfileTitle => 'କୃଷକ ପ୍ରୋଫାଇଲ୍';

  @override
  String get verifiedFarmer => 'ଯାଞ୍ଚ ହୋଇଥିବା କୃଷକ ✓';

  @override
  String get organicLand => 'ଜୈବିକ ଜମି';

  @override
  String get soldThisMonth => 'ଏହି ମାସର ବିକ୍ରୟ';

  @override
  String get directSales => 'ସିଧାସଳଖ ବିକ୍ରୟ';

  @override
  String get farmInfrastructureAndBadges => 'କୃଷି ଭିତ୍ତିଭୂମି ଓ ଫସଲ ବ୍ୟାଜ୍';

  @override
  String get soilClassification => 'ମାଟି ବର୍ଗୀକରଣ';

  @override
  String get primaryCrops => 'ପ୍ରମୁଖ ଫସଲ';

  @override
  String get apmcRegistration => 'APMC ପଞ୍ଜୀକରଣ';

  @override
  String get kisanCreditCard => 'କିଷାନ କ୍ରେଡିଟ୍ କାର୍ଡ';

  @override
  String get zeroPesticideOrganicCertificate =>
      'ଶୂନ୍ୟ କୀଟନାଶକ ଜୈବିକ ପ୍ରମାଣପତ୍ର';

  @override
  String get verifiedByKarnatakaOrganicBoard =>
      'କର୍ଣ୍ଣାଟକ ଜୈବିକ କୃଷକ ବୋର୍ଡ ଦ୍ୱାରା ଯାଞ୍ଚିତ';

  @override
  String get validatedStatus => 'ଯାଞ୍ଚିତ ✓';

  @override
  String get underReviewStatus => 'ସମୀକ୍ଷାଧୀନ';

  @override
  String get languageMode => 'ଭାଷା ମୋଡ୍';

  @override
  String get manageProduceListings => 'ଉତ୍ପାଦ ତାଲିକା ପରିଚାଳନା କରନ୍ତୁ';

  @override
  String get produceListingsTitle => 'କୃଷି ଉତ୍ପାଦ ତାଲିକା';

  @override
  String get addNewProduce => 'ନୂତନ ଉତ୍ପାଦ ଯୋଡନ୍ତୁ';

  @override
  String get editProduceListing => 'ଉତ୍ପାଦ ସମ୍ପାଦନ କରନ୍ତୁ';

  @override
  String get produceName => 'ଉତ୍ପାଦର ନାମ';

  @override
  String get category => 'ବିଭାଗ';

  @override
  String pricePerUnit(String unit) {
    return 'ପ୍ରତି $unit ମୂଲ୍ୟ';
  }

  @override
  String get stockQuantity => 'ଷ୍ଟକ୍ ପରିମାଣ';

  @override
  String get unit => 'ୟୁନିଟ୍';

  @override
  String get harvestDate => 'ଅମଳ ତାରିଖ';

  @override
  String get qualityNotes => 'ଗୁଣବତ୍ତା ବିବରଣୀ';

  @override
  String get farmingMethod => 'ଚାଷ ପ୍ରଣାଳୀ';

  @override
  String get deliveryAvailable => 'ଡେଲିଭରୀ ଉପଲବ୍ଧ';

  @override
  String get pickupAvailable => 'ଫାର୍ମରୁ ସିଧାସଳଖ ନେବା ଉପଲବ୍ଧ';

  @override
  String get availabilityMode => 'ଉପଲବ୍ଧତା ମୋଡ୍';

  @override
  String get sameDayDelivery => 'ସେହିଦିନ ଡେଲିଭରୀ';

  @override
  String get nextDayDelivery => 'ପରଦିନ ଡେଲିଭରୀ';

  @override
  String get harvestPreOrder => 'ଅମଳ ପୂର୍ବ ଅର୍ଡର';

  @override
  String get farmerSetsFinalPrice => 'କୃଷକ ସର୍ବଦା ଚୂଡ଼ାନ୍ତ ମୂଲ୍ୟ ସ୍ଥିର କରନ୍ତି';

  @override
  String get statusLowStock => 'କମ୍ ଷ୍ଟକ୍';

  @override
  String get statusSoldOut => 'ଶେଷ ହୋଇଯାଇଛି';

  @override
  String get statusPaused => 'ସ୍ଥଗିତ';

  @override
  String get pauseListing => 'ସ୍ଥଗିତ କରନ୍ତୁ';

  @override
  String get activateListing => 'ସକ୍ରିୟ କରନ୍ତୁ';

  @override
  String get updateStock => 'ଷ୍ଟକ୍ ଅଦ୍ୟତନ କରନ୍ତୁ';

  @override
  String stockInStock(String stock) {
    return '$stock ଷ୍ଟକ୍ରେ ଅଛି';
  }

  @override
  String get buyerProduceMarket => 'ସତେଜ କୃଷି ଉତ୍ପାଦ';

  @override
  String get buyerSearchProduceHint =>
      'ସତେଜ କୃଷି ଉତ୍ପାଦ ଖୋଜନ୍ତୁ (ଯଥା ଟମାଟୋ, ଚାଉଳ)...';

  @override
  String get noProduceAvailable => 'କୌଣସି ଉତ୍ପାଦ ଉପଲବ୍ଧ ନାହିଁ';

  @override
  String get orderDirect => 'ସିଧାସଳଖ ଅର୍ଡର କରନ୍ତୁ';

  @override
  String get uploadProducePhotos => 'ଫସଲ ଫଟୋ (produce-images)';

  @override
  String get addPhoto => 'ଫଟୋ ଯୋଡ଼ନ୍ତୁ';

  @override
  String get farmerMapHeader =>
      'କୃଷକମାନଙ୍କ ପାଇଁ ଆବଶ୍ୟକ ସାମଗ୍ରୀ, ବିହନ, ଯନ୍ତ୍ରପାତି ଏବଂ ସେବା';

  @override
  String get farmerNearbyRentals => 'ନିକଟସ୍ଥ ଯନ୍ତ୍ରପାତି ଏବଂ ଡ୍ରୋନ ଭଡ଼ା';

  @override
  String get farmerEscrowGuaranteed => 'ଏସ୍କ୍ରୋ ଗ୍ୟାରେଣ୍ଟି';

  @override
  String get farmerBookNow => 'ବର୍ତ୍ତମାନ ବୁକ୍ କରନ୍ତୁ';

  @override
  String get farmerBookItem => 'ଆଇଟମ୍ ବୁକ୍ କରନ୍ତୁ';

  @override
  String get farmerViewAllEquipmentMap =>
      'ସମସ୍ତ କୃଷି ଉତ୍ସ ଏବଂ ଲାଇଭ୍ ମ୍ୟାପ୍ ଦେଖନ୍ତୁ →';

  @override
  String get farmerEquipmentBooked => 'ଯନ୍ତ୍ରପାତି ବୁକ୍ ହୋଇଛି!';

  @override
  String get farmerBookingQuantity => 'ବୁକିଂ ଅବଧି / ପରିମାଣ';

  @override
  String get farmerDeliveryAddress => 'ଫାର୍ମ ବିତରଣ / କାର୍ଯ୍ୟ ସ୍ଥଳ ଠିକଣା';

  @override
  String get farmerSpecialNotes =>
      'କାର୍ଯ୍ୟ ନିର୍ଦ୍ଦେଶାବଳୀ / ଫସଲ ନୋଟ୍ (ଇଚ୍ଛାଧୀନ)';

  @override
  String get farmerVendorHubTitle => 'ଯନ୍ତ୍ରପାତି ବିକ୍ରେତା କେନ୍ଦ୍ର';

  @override
  String get farmerAddEquipment => 'ଯନ୍ତ୍ରପାତି ଯୋଡନ୍ତୁ';

  @override
  String get farmTraceabilityTitle => 'ଫାର୍ମ ଗୁଣବତ୍ତା ଉତ୍ସ ଯାଞ୍ଚ ହୋଇଛି';

  @override
  String get traceabilityCropItem => 'ଫସଲ ବିବରଣୀ:';

  @override
  String get traceabilityFarmerOrigin => 'କୃଷକଙ୍କ ଉତ୍ସ:';

  @override
  String get traceabilityHarvestTime => 'ଅମଳ ସମୟ:';

  @override
  String get traceabilityCertification => 'ଜୈବିକ ପ୍ରମାଣପତ୍ର:';

  @override
  String get traceabilityFarmingMethod => 'ଚାଷ ପ୍ରଣାଳୀ:';

  @override
  String get traceabilityQualityNotes => 'ଗୁଣବତ୍ତା ନୋଟ୍:';

  @override
  String get closeTraceability => 'ବିବରଣୀ ବନ୍ଦ କରନ୍ତୁ';

  @override
  String get produceFiltersTitle => 'ଫିଲ୍ଟର୍ ଏବଂ ସଜାନ୍ତୁ';

  @override
  String get clearFilters => 'ରିସେଟ୍ କରନ୍ତୁ';

  @override
  String get sortBy => 'ସଜାଇବା କ୍ରମ';

  @override
  String get maxDistance => 'ସର୍ବାଧିକ ଦୂରତା';

  @override
  String get minFarmerRating => 'କୃଷକ ରେଟିଂ';

  @override
  String get freshnessFilter => 'ଅମଳର ସତେଜତା';

  @override
  String get fulfillmentOptions => 'ବିତରଣ ଏବଂ ଉପଲବ୍ଧତା';

  @override
  String get deliveryAvailableOnly => 'ହୋମ୍ ଡେଲିଭରୀ ଉପଲବ୍ଧ';

  @override
  String get walkInStoreOnly => 'ଫାର୍ମ ଡିପୋ / ଷ୍ଟୋର୍ ପିକଅପ୍';

  @override
  String get organicCertifiedOnly => 'କେବଳ ଜୈବିକ ପ୍ରମାଣିତ';

  @override
  String get applyFilters => 'ଫିଲ୍ଟର୍ ପ୍ରୟୋଗ କରନ୍ତୁ';

  @override
  String get customerProduceMapTitle =>
      'ମୋ ନିକଟରେ ଥିବା କୃଷି ଉତ୍ପାଦ, ଜୈବିକ ବିକ୍ରେତା ଏବଂ ଆଉଟଲେଟ୍';

  @override
  String get orderNow => 'ବର୍ତ୍ତମାନ ଅର୍ଡର କରନ୍ତୁ';

  @override
  String get cartTitle => 'Shopping Cart';

  @override
  String get cartClear => 'Clear';

  @override
  String get clearCartConfirmTitle => 'Clear Cart?';

  @override
  String get clearCartConfirmBody =>
      'Are you sure you want to remove all items from your cart?';

  @override
  String get cartEmptyTitle => 'Your Cart is Empty';

  @override
  String get cartEmptySubtitle =>
      'Explore fresh organic vegetables, fruits, and dairy directly from local verified farmers.';

  @override
  String get exploreProduce => 'Explore Farm Produce';

  @override
  String get multiFarmerSplitNotice =>
      'Items from multiple farmers will be placed as separate direct orders for fresh dispatch.';

  @override
  String get farmerOrderHeader => 'Direct Farm Order';

  @override
  String get subtotalLabel => 'Farm Order Subtotal';

  @override
  String get redeemRewardCredits => 'Reward Credits (Demo mode)';

  @override
  String get rewardDiscountDesc => 'Apply 5% loyalty discount (up to ₹50)';

  @override
  String get billSummary => 'Bill Summary';

  @override
  String get itemTotal => 'Items Total';

  @override
  String get rewardCreditsDiscount => 'Reward Discount';

  @override
  String get escrowProtectionBadge => 'Escrow Protection Guarantee';

  @override
  String get includedLabel => 'Included';

  @override
  String get totalPayable => 'Total Amount';

  @override
  String get proceedToCheckout => 'Checkout';

  @override
  String get checkoutTitle => 'Direct Farm Checkout';

  @override
  String get stepSlot => '1. Delivery Slot';

  @override
  String get stepAddress => '2. Address';

  @override
  String get stepPayment => '3. Payment';

  @override
  String get doorstepDelivery => 'Doorstep Delivery';

  @override
  String get farmPickup => 'Farm Pickup';

  @override
  String get selectDeliveryWindow =>
      'Select your preferred harvest and arrival window';

  @override
  String get noSlotsAvailable => 'No active slots available for this farm.';

  @override
  String get slotSameDay => 'Same Day';

  @override
  String get slotNextDay => 'Next Day';

  @override
  String get slotPreOrder => 'Pre-Order';

  @override
  String get slotFullLabel => 'Slot Full (0 remaining)';

  @override
  String get slotsRemaining => 'slots available';

  @override
  String get farmPickupLocation => 'Farm Pickup Location';

  @override
  String get deliveryAddressHeader => 'Delivery Address';

  @override
  String get farmPickupNotice =>
      'Pick up directly at the farm packhouse. Bring your order confirmation code.';

  @override
  String get fullAddressLabel => 'Street Address / Door No.';

  @override
  String get deliveryNotesLabel => 'Delivery instructions (Optional)';

  @override
  String get contactPhoneLabel => 'Contact Phone Number';

  @override
  String get paymentDemoModeNotice =>
      'Demo mode — Simulated payment checkout with instant verification.';

  @override
  String get escrowProtectionTitle => '100% Escrow Protection Guarantee';

  @override
  String get escrowProtectionSubtitle =>
      'Payment is held safely until you receive and verify produce quality.';

  @override
  String get paymentMethodHeader => 'Select Payment Method';

  @override
  String get itemsTotal => 'Items Total';

  @override
  String get rewardDiscount => 'Reward Discount';

  @override
  String get escrowFeeLabel => 'Escrow Protection Fee';

  @override
  String get backButton => 'Back';

  @override
  String get nextStep => 'Continue';

  @override
  String get confirmOrder => 'Place Order';

  @override
  String get orderConfirmedTitle => 'Order Confirmed';

  @override
  String get orderPlacedSuccessfully => 'Order Placed Successfully!';

  @override
  String get escrowProtectedHeader => 'Escrow Protected Payment';

  @override
  String get escrowProtectedNotice =>
      'Your payment remains safely locked in platform escrow until you inspect and verify freshness upon delivery.';

  @override
  String get backToMarketplace => 'Back to Produce Marketplace';

  @override
  String get pendingFarmerConfirmation => 'Pending Farmer Confirmation';

  @override
  String get orderCodeLabel => 'Order Code';

  @override
  String get farmerDeliverySlotsTitle => 'Farm Delivery & Pickup Slots';

  @override
  String get addSlotButton => '+ Add Delivery Slot';

  @override
  String get noSlotsConfiguredTitle => 'No Delivery Slots Configured';

  @override
  String get noSlotsConfiguredSubtitle =>
      'Create delivery or pickup windows so buyers can select convenient harvest delivery times.';

  @override
  String get createFirstSlot => 'Create First Slot';

  @override
  String get createDeliverySlotModalTitle => 'Add Delivery Window Slot';

  @override
  String get saveSlotButton => 'Save Delivery Slot';

  @override
  String get addedToCart => 'Added to Cart';

  @override
  String get viewCart => 'View Cart';

  @override
  String get liveOrderTimeline => 'ଲାଇଭ ଅର୍ଡର ଟାଇମଲାଇନ';

  @override
  String get orderCancelledRefundedNotice =>
      'ଅର୍ଡର ବାତିଲ ହୋଇଛି। ଟଙ୍କା ଫେରସ୍ତ କରାଯାଇଛି।';

  @override
  String get orderDisputeNotice =>
      'ବିବାଦ ଚାଲିଛି। ସମାଧାନ ପର୍ଯ୍ୟନ୍ତ ଟଙ୍କା ରଖାଯାଇଛି।';

  @override
  String get orderStagePlaced => 'ଅର୍ଡର ହୋଇଛି';

  @override
  String get orderStagePlacedSub => 'ଟଙ୍କା ସୁରକ୍ଷିତ ଅଛି';

  @override
  String get orderStageAccepted => 'ଚାଷୀ ଗ୍ରହଣ କଲେ';

  @override
  String get orderStageAcceptedSub => 'ଅମଳ ଏବଂ ସଜଡା ଚାଲିଛି';

  @override
  String get orderStagePacked => 'ପ୍ୟାକ ଏବଂ ଓଜନ ହୋଇଛି';

  @override
  String get orderStagePackedSub => 'ଯାଞ୍ଚ ସରିଛି';

  @override
  String get orderStageReadyPickup => 'ପିକଅପ ପାଇଁ ପ୍ରସ୍ତୁତ';

  @override
  String get orderStageReadyPickupSub => 'ପିକଅପ କୋଡ଼ ସହ ଚାଷ ଜମିକୁ ଯାଆନ୍ତୁ';

  @override
  String get orderStageOutForDelivery => 'ଡେଲିଭରି ପାଇଁ ବାହାରିଛି';

  @override
  String get orderStageOutForDeliverySub => 'ଆପଣଙ୍କ ଠିକଣାକୁ ଆସୁଛି';

  @override
  String get orderStagePickedUp => 'ପିକଅପ ହୋଇଛି';

  @override
  String get orderStageDelivered => 'ଡେଲିଭର ହୋଇଛି';

  @override
  String get orderStageDeliveredSub => 'ଚାଷୀଙ୍କୁ ଟଙ୍କା ଦିଆଗଲା';

  @override
  String get statusReadyForPickup => 'ପିକଅପ ପାଇଁ ପ୍ରସ୍ତୁତ';

  @override
  String get statusOutForDelivery => 'ଡେଲିଭରି ପାଇଁ ବାହାରିଛି';

  @override
  String get rateOrderTitle => 'ରେଟିଂ ଦିଅନ୍ତୁ';

  @override
  String get selectProduceTags => 'ଉତ୍ପାଦ ଗୁଣବତ୍ତା:';

  @override
  String get orderReviewHint => 'ତାଜାପଣ ଏବଂ ପ୍ୟାକିଂ ବିଷୟରେ ଲେଖନ୍ତୁ...';

  @override
  String get submitReviewButton => 'ମତାମତ ଦିଅନ୍ତୁ';

  @override
  String get reportOrderIssue => 'ଅଭିଯୋଗ କରନ୍ତୁ';

  @override
  String get disputeEscrowFreezeNotice => 'ତଦନ୍ତ ସରିବା ଯାଏଁ ଟଙ୍କା ଅଟକି ରହିବ।';

  @override
  String get selectIssueType => 'ସମସ୍ୟା ବାଛନ୍ତୁ:';

  @override
  String get describeIssueDetails => 'ବିସ୍ତୃତ ଭାବେ ଲେଖନ୍ତୁ:';

  @override
  String get disputeDetailsPlaceholder => 'ଯଥା: ୨ କିଲୋ ଟମାଟୋ ନଷ୍ଟ ହୋଇ ଆସିଛି...';

  @override
  String get submitDisputeCTA => 'ଅଭିଯୋଗ ଦାଖଲ କରନ୍ତୁ';

  @override
  String get orderTrackingTitle => 'ଅର୍ଡର ଟ୍ରାକିଂ';

  @override
  String get confirmDeliveryTitle => 'ଡେଲିଭରି ନିଶ୍ଚିତ କରିବେ?';

  @override
  String get confirmDeliveryPrompt =>
      'ସବୁକିଛି ଠିକ ମିଳିଛି ତ? ଏହା ଚାଷୀଙ୍କୁ ଟଙ୍କା ଦେବ।';

  @override
  String get confirmReceivedButton => 'ହଁ, ପାଇଲି';

  @override
  String get cancelOrderTitle => 'ଅର୍ଡର ବାତିଲ କରିବେ?';

  @override
  String get cancelOrderPrompt => 'ଅର୍ଡର ବାତିଲ କଲେ ଟଙ୍କା ଫେରସ୍ତ ହେବ।';

  @override
  String get noKeepOrder => 'ନା, ଥାଉ';

  @override
  String get yesCancelOrder => 'ହଁ, ବାତିଲ କରନ୍ତୁ';

  @override
  String get orderNotFound => 'ଅର୍ଡର ମିଳିଲା ନାହିଁ।';

  @override
  String get farmPickupCodeHeader => 'ପିକଅପ କୋଡ଼';

  @override
  String get deliveryPinHeader => 'ଡେଲିଭରି ପିନ';

  @override
  String get showPickupCodeFarmerNote => 'ଚାଷୀଙ୍କୁ ଏହି ୪ ଅଙ୍କର କୋଡ଼ ଦେଖାନ୍ତୁ।';

  @override
  String get showDeliveryPinDriverNote =>
      'ଡେଲିଭରି ବେଳେ ଡ୍ରାଇଭରଙ୍କୁ ଏହି କୋଡ଼ କୁହନ୍ତୁ।';

  @override
  String get estimatedArrivalHeader => 'ଆସିବା ସମୟ';

  @override
  String get orderItemsHeader => 'ଅର୍ଡର ସାମଗ୍ରୀ';

  @override
  String get totalAmount => 'ଦିଆଯାଇଥିବା ମୋଟ ଟଙ୍କା:';

  @override
  String get confirmDeliveryReceivedButton =>
      'ଡେଲିଭରି ନିଶ୍ଚିତ କରି ଟଙ୍କା ଦିଅନ୍ତୁ';

  @override
  String get releaseFundsNotice => 'ନିଶ୍ଚିତ କଲେ ଚାଷୀଙ୍କୁ ଟଙ୍କା ମିଳିବ।';

  @override
  String get reorderItemsButton => 'ପୁଣି ଅର୍ଡର କରନ୍ତୁ';

  @override
  String get rateProduceButton => 'ରେଟିଂ ଦିଅନ୍ତୁ';

  @override
  String get myFarmOrdersTitle => 'ମୋର କୃଷି ଅର୍ଡର';

  @override
  String get allOrdersFilter => 'ସବୁ ଅର୍ଡର';

  @override
  String get activeFilter => 'ସକ୍ରିୟ';

  @override
  String get completedFilter => 'ଡେଲିଭର ହୋଇଛି';

  @override
  String get cancelledFilter => 'ବାତିଲ ହୋଇଛି';

  @override
  String get reorderButton => 'ପୁନଃ ଅର୍ଡର';

  @override
  String get noOrdersFoundTitle => 'କୌଣସି ଅର୍ଡର ନାହିଁ';

  @override
  String get noOrdersFoundSub => 'ଆପଣ ଏଯାଏଁ କୌଣସି ଅର୍ଡର କରିନାହାଁନ୍ତି।';

  @override
  String get exploreProduceButton => 'ସାମଗ୍ରୀ ଦେଖନ୍ତୁ';

  @override
  String get farmerOrderBoardTitle => 'ଚାଷୀ ଅର୍ଡର ବୋର୍ଡ';

  @override
  String get trackOrderButton => 'ଟ୍ରାକ କରନ୍ତୁ';

  @override
  String get cancelOrderButton => 'ଅର୍ଡର ବାତିଲ କରନ୍ତୁ ଏବଂ ରିଫଣ୍ଡ ପାଆନ୍ତୁ';

  @override
  String get disputeButton => 'ସମସ୍ୟା ରିପୋର୍ଟ କରନ୍ତୁ';

  @override
  String get statusAccepted => 'ଗ୍ରହଣ କରାଯାଇଛି';

  @override
  String get statusPacked => 'ପ୍ୟାକ୍ ହୋଇଛି';

  @override
  String get statusDelivered => 'ବିତରଣ କରାଯାଇଛି';

  @override
  String get statusDisputed => 'ବିବାଦୀୟ';

  @override
  String get editFarmDetails => 'କୃଷି ବିବରଣୀ ସମ୍ପାଦନ କରନ୍ତୁ';

  @override
  String get editFarmDetailsSubtitle =>
      'ଜମି କ୍ଷେତ୍ର, ମାଟି ଏବଂ ଫସଲ ବିବରଣୀ ଅପଡେଟ୍ କରନ୍ତୁ';

  @override
  String get clusterVillageLabel => 'କ୍ଲଷ୍ଟର / ଗ୍ରାମ ଅବସ୍ଥିତି';

  @override
  String get apmcMandiLabel => 'ପଞ୍ଜୀକୃତ ଏପିଏମସି ମଣ୍ଡି';

  @override
  String get farmDetailsUpdatedSuccess =>
      'କୃଷି ବିବରଣୀ ସଫଳତାର ସହିତ ଅପଡେଟ୍ ହୋଇଛି';

  @override
  String get selfDeclaredProfile => 'ସ୍ୱୟଂ ଘୋଷିତ ପ୍ରୋଫାଇଲ୍';

  @override
  String get locationPinNotice =>
      'ଜିପିଏସ ପିନ୍ ବିନା କାର୍ଯ୍ୟସ୍ଥଳୀ ଠିକଣା ପ୍ରଦାନ କରାଯାଇଛି';

  @override
  String get safetyHubTitle => 'Safety & Emergency Hub';

  @override
  String get emergencyContactsTitle => 'Emergency Contacts';

  @override
  String get jobProtectionClaimTitle => 'Job Protection Claim';

  @override
  String get notificationCentreTitle => 'Notification Centre';

  @override
  String get notifNewApplicantTitle => 'New Job Applicant';

  @override
  String notifNewApplicantBody(String worker, String job) {
    return '$worker applied for $job';
  }

  @override
  String get notifApplicationStatusTitle => 'Application Update';

  @override
  String notifApplicationStatusBody(String job, String status) {
    return 'Your application for $job was updated to $status';
  }

  @override
  String get notifAssignmentStatusTitle => 'Booking Status Update';

  @override
  String notifAssignmentStatusBody(String code, String status) {
    return '$code is now $status';
  }

  @override
  String get notifNewOrderTitle => 'New Farm Produce Order';

  @override
  String notifNewOrderBody(String code) {
    return 'New farm produce order $code received';
  }

  @override
  String get notifOrderStatusTitle => 'Produce Order Update';

  @override
  String notifOrderStatusBody(String code, String status) {
    return '$code status updated to $status';
  }

  @override
  String get notifPaymentReceivedTitle => 'Payment Received';

  @override
  String notifPaymentReceivedBody(String amount) {
    return 'Payment received: $amount';
  }

  @override
  String get notifSosAlertTitle => 'EMERGENCY SOS ALERT';

  @override
  String get notifSosAlertBody =>
      'Emergency SOS incident registered. Safety team alerted.';

  @override
  String get notifClaimSubmittedTitle => 'Job Protection Claim';

  @override
  String notifClaimSubmittedBody(String type) {
    return 'Your claim for $type was registered for review.';
  }

  @override
  String get notifGeneralTitle => 'Notification';

  @override
  String get notifGeneralBody => 'You have a new update in UdyogaSethu.';

  @override
  String get voiceAssistantTitle => 'AI MULTILINGUAL VOICE ASSISTANT';

  @override
  String get voiceExampleCommandsTitle =>
      'TAP EXAMPLE COMMAND TO DIRECT SEARCH';

  @override
  String get voiceListening => 'Listening to your voice...';

  @override
  String get voiceInstruction =>
      'Tap mic and speak in Kannada, Hindi, Telugu, Tamil or English';

  @override
  String get voiceProcessing => 'Understanding command...';

  @override
  String get voiceListeningStop => '🎙 Listening... (Tap to stop)';

  @override
  String get voiceTapToSpeak => '🎙 Tap to Speak';
}
