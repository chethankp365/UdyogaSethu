// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

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
  String get walletBalance => 'वॉलेट शिल्लक';

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
  String get kccApproved => 'Approved / Active';

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
  String get providerWizardTitle => 'जॉब प्रदाता सेटअप';

  @override
  String get providerStep1Title => 'मूलभूत माहिती';

  @override
  String get providerStep1Subtitle =>
      'तुमचे पूर्ण नाव, फोटो आणि भाषा प्रविष्ट करा.';

  @override
  String get providerStep2Title => 'प्रदाता वर्ग';

  @override
  String get providerStep2Subtitle =>
      'तुम्ही घरगुती की व्यावसायिक म्हणून काम देता ते निवडा.';

  @override
  String get providerStep3HouseholdTitle => 'घरचा पत्ता आणि डिलिव्हरी';

  @override
  String get providerStep3HouseholdSubtitle =>
      'मुख्य डिलिव्हरी पत्ता आणि प्राधान्ये सेट करा.';

  @override
  String get providerStep3EmployerTitle => 'संस्था आणि साइट तपशील';

  @override
  String get providerStep3EmployerSubtitle =>
      'संस्थेचे नाव, मुख्य साइट पत्ता आणि टीमची संख्या प्रविष्ट करा.';

  @override
  String get providerStep4Title => 'परवानग्या आणि संमती';

  @override
  String get providerStep4Subtitle => 'स्थान आणि सूचना परवानग्या तपासा.';

  @override
  String get providerStep5Title => 'तपासा आणि पूर्ण करा';

  @override
  String get providerStep5Subtitle =>
      'पूर्ण करण्यापूर्वी प्रोफाइल तपशील तपासा.';

  @override
  String get doorstepAddressLabel => 'फ्लॅट / घर क्र. आणि रस्ता';

  @override
  String get doorstepAddressHint => 'उदा. #402, सनशाईन अपार्टमेंट्स';

  @override
  String get landmarkLabel => 'लँडमार्क';

  @override
  String get landmarkHint => 'उदा. मेट्रो स्टेशन जवळ';

  @override
  String get deliveryInstructionsLabel => 'डिलिव्हरी प्राधान्ये आणि सूचना';

  @override
  String get deliveryInstructionsHint => 'उदा. गेटवर सुरक्षा रक्षकाकडे द्या';

  @override
  String get gateCodeLabel => 'गेट कोड (पर्यायी)';

  @override
  String get gateCodeHint => 'उदा. 1234';

  @override
  String get orgNameLabel => 'संस्था / व्यवसायाचे नाव';

  @override
  String get orgNameHint => 'उदा. सेतू कन्स्ट्रक्शन';

  @override
  String get primarySiteAddressLabel => 'मुख्य साइट पत्ता';

  @override
  String get primarySiteAddressHint => 'उदा. साइट 45, इलेक्ट्रॉनिक्स सिटी';

  @override
  String get categoriesHiringLabel => 'कामाचे वर्ग';

  @override
  String get typicalCrewSizeLabel => 'आवश्यक कामगारांची संख्या';

  @override
  String crewSizeWorkers(Object count) {
    return '$count कामगार';
  }

  @override
  String get gpsConsentExplanation =>
      'साइट पत्ता आणि कामगारांची उपलब्धता दाखवण्यासाठी GPS आवश्यक आहे.';

  @override
  String get notificationsConsentExplanation =>
      'कामगारांचे अर्ज आणि अपडेट्स मिळवण्यासाठी सूचना सक्षम करा.';

  @override
  String get grantGpsPermission => 'स्थान परवानगी द्या';

  @override
  String get grantNotificationsPermission => 'सूचना परवानगी द्या';

  @override
  String get permissionGranted => 'परवानगी दिली';

  @override
  String get providerHomeTitle => 'प्रदाता होम';

  @override
  String get roleConflictTitle => 'भूमिका खाते आधीच अस्तित्वात आहे';

  @override
  String roleConflictMessage(Object chosenRole, Object existingRole) {
    return 'तुमचे खाते आधीच $existingRole म्हणून नोंदणीकृत आहे.';
  }

  @override
  String roleConflictLoginAs(Object existingRole) {
    return '$existingRole म्हणून लॉग इन करा';
  }

  @override
  String get roleConflictBack => 'मागे जा';

  @override
  String get privacyCentreTitle => 'गोपनीयता केंद्र';

  @override
  String get privacyCentreSubtitle =>
      'तुमच्या डेटा संमती आणि परवानग्या व्यवस्थापित करा.';

  @override
  String get consentSheetTitle => 'डेटा प्रक्रिया संमती';

  @override
  String get consentWhatCollected => 'काय गोळा केले जाते';

  @override
  String get consentWhyCollected => 'का गोळा केले जाते';

  @override
  String get consentHowLongKept => 'किती वेळ ठेवले जाते';

  @override
  String get consentWhoCanSee => 'कोण पाहू शकते';

  @override
  String get consentHowToWithdraw => 'मागे कसे घ्यायचे';

  @override
  String get consentAgreeButton => 'मी सहमत आहे आणि संमती देतो';

  @override
  String get consentNotNowButton => 'आत्ता नाही';

  @override
  String get consentGrantedStatus => 'संमती दिली';

  @override
  String get consentRevokedStatus => 'संमती नाकारली / काढून घेतली';

  @override
  String get withdrawConsentButton => 'संमती मागे घ्या';

  @override
  String get withdrawFaceConsentTitle => 'चेहरा पडताळणी संमती मागे घ्यायची?';

  @override
  String get withdrawFaceConsentMessage =>
      'चेहरा संमती मागे घेतल्यास तुमचा संदर्भ डेटा कायमचा हटवला जाईल.';

  @override
  String get confirmWithdrawButton => 'मागे घ्या आणि डेटा हटवा';

  @override
  String get cancelButton => 'रद्द करा';

  @override
  String get profileTitle => 'माझे प्रोफाईल';

  @override
  String get termsAndPrivacyTitle => 'अटी आणि गोपनीयता धोरण';

  @override
  String get termsDraftNotice => 'मसुदा - लॉन्चपूर्वी त्याचे पुनरावलोकन करा';

  @override
  String get systemPermissionsTitle => 'सिस्टम परवानग्या';

  @override
  String get openSystemSettings => 'ॲप सेटिंग्ज उघडा';

  @override
  String get settingsTitle => 'सेटिंग्ज';

  @override
  String get faceVerificationCheck => 'चेहरा पडताळणी तपासणी';

  @override
  String get faceCheckSubtext => 'फेस लाईव्हनेस चेक वापरून तुमची ओळख पडताळा';

  @override
  String get faceMatchSuccess => 'चेहरा ओळख पडताळली';

  @override
  String get faceMatchFailedTitle => 'चेहरा जुळणी अयशस्वी';

  @override
  String get faceMatchFailedBody =>
      'चांगल्या प्रकाशात तुमचा चेहरा स्पष्ट ठेवा आणि पुन्हा प्रयत्न करा.';

  @override
  String get manualReviewRequiredTitle => '3 पडताळणी प्रयत्न अयशस्वी';

  @override
  String get manualReviewRequiredBody =>
      'तुमची चेहरा पडताळणी मॅन्युअल पुनरावलोकनासाठी पाठवली गेली आहे. तुम्ही मर्यादित प्रवेशासह सुरू ठेवू शकता.';

  @override
  String get requestManualReview => 'मॅन्युअल पुनरावलोकनाची विनंती करा';

  @override
  String get retryVerification => 'पुन्हा पडताळणीचा प्रयत्न करा';

  @override
  String get demoSimulatePass => 'डेमो: यशस्वी पडताळणी';

  @override
  String get demoSimulateFail => 'डेमो: अयशस्वी पडताळणी';

  @override
  String get seekerHomeTitle => 'रोजगार शोधक मुख्यपृष्ठ';

  @override
  String get searchJobsPlaceholder => 'नोकऱ्या, सेवा शोधा...';

  @override
  String get todaysGoal => 'आजचे ध्येय';

  @override
  String get viewWallet => 'वॉलेट पहा >';

  @override
  String get locationSharingActive =>
      'सुरक्षा देखरेखीसाठी स्थान सामायिकरण सक्रिय आहे';

  @override
  String get changeLocation => 'बदला >';

  @override
  String get quickActionsHeader => 'द्रुत कृती';

  @override
  String get actionNearbyJobs => 'जवळपासच्या नोकऱ्या';

  @override
  String get actionAiAssistant => 'एआय सहाय्यक';

  @override
  String get actionWallet => 'वॉलेट';

  @override
  String get actionSafetyHub => 'सुरक्षा केंद्र';

  @override
  String get tagSponsored => 'प्रायोजित';

  @override
  String get whyAmISeeingThis => 'मला हे का दिसत आहे?';

  @override
  String get recommendedForYou => 'तुमच्यासाठी शिफारस केलेले';

  @override
  String get applyNow => 'आता अर्ज करा';

  @override
  String get applied => 'अर्ज केला ✓';

  @override
  String get noJobsNearYou => 'तुमच्या जवळ अजून नोकऱ्या नाहीत';

  @override
  String get widenRadiusAction => 'शोध त्रिज्या वाढवा';

  @override
  String get sosEmergencyPill => 'तातडीचे एसओएस';

  @override
  String get selectLocationArea => 'स्थान क्षेत्र निवडा';

  @override
  String get goodMorning => 'शुभ सकाळ';

  @override
  String get goodAfternoon => 'शुभ दुपार';

  @override
  String get goodEvening => 'शुभ संध्याकाळ';

  @override
  String get studentsWelcomeChip => 'विद्यार्थ्यांचे स्वागत आहे';

  @override
  String get flexibleShiftChip => 'लवचिक शिफ्ट';
}
