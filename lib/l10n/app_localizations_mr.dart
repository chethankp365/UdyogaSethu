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
  String get kccApproved => 'केसीसी मंजूर ✓';

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

  @override
  String get nearbyJobsMapTitle =>
      'जवळपासचे दैनंदिन रोजंदारी कामे आणि कामाची ठिकाणे';

  @override
  String livePinsCount(Object count) {
    return '$count थेट पिन';
  }

  @override
  String nearbyGpsPinListings(Object count) {
    return 'जवळपासच्या जीपीएस पिन याद्या ($count)';
  }

  @override
  String get tapPinOrCardToInspect => 'तपासण्यासाठी पिन किंवा कार्डवर टॅप करा';

  @override
  String get applyButton => 'अर्ज करा';

  @override
  String get categoryFilterAll => 'सर्व';

  @override
  String get recenterMap => 'जीपीएस पुन्हा केंद्रस्थानी करा';

  @override
  String get zoomIn => 'झूम इन';

  @override
  String get zoomOut => 'झूम आउट';

  @override
  String get gpsDisabledBanner =>
      'जीपीएस बंद आहे. अचूक अंतरासाठी स्थान चालू करा.';

  @override
  String get locationPermissionDeniedBanner =>
      'स्थान परवानगी दिली नाही. डीफॉल्ट क्षेत्र दर्शवित आहे.';

  @override
  String get noJobsInArea => 'या त्रिज्येत कोणतीही कार्यस्थळे आढळली नाहीत';

  @override
  String get searchRadius => 'शोध त्रिज्या';

  @override
  String radiusKm(Object radius) {
    return '$radius किमी';
  }

  @override
  String get openLocationSettings => 'सेटिंग्ज';

  @override
  String get loadJobsError =>
      'जवळपासच्या नोकऱ्या लोड करण्यात अक्षम. कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get retryAction => 'पुन्हा प्रयत्न करा';

  @override
  String get openStreetMapAttribution => '© OpenStreetMap contributors';

  @override
  String get cameraPermissionTitle => 'कॅमेरा प्रवेश';

  @override
  String get cameraPermissionSubtitle =>
      'चेहरा पडताळणी आणि आयडी स्कॅनिंगसाठी वापरले जाते.';

  @override
  String get locationPermissionTitle => 'डिव्हाइस स्थान (जीपीएस)';

  @override
  String get locationPermissionSubtitle =>
      'जवळपासच्या नोकऱ्या, मार्ग नकाशा आणि कामावरील उपस्थिती दर्शवण्यासाठी वापरले जाते.';

  @override
  String get notificationPermissionTitle => 'सूचना';

  @override
  String get notificationPermissionSubtitle =>
      'त्वरित नोकरी सूचना, देयक अद्यतने आणि सुरक्षा सूचनांसाठी वापरले जाते.';

  @override
  String get permissionAllowedStatus => 'परवानगी आहे';

  @override
  String get permissionBlockedStatus => 'अवरोधित / बंद';

  @override
  String get refreshConsentsTooltip => 'स्थिती रीफ्रेश करा';

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
  String get postJobStepAudience => 'लक्षित कामगार';

  @override
  String get postJobAudienceTitle => 'हे काम कोणासाठी आहे?';

  @override
  String get postJobAudienceSubtitle =>
      'या कामासाठी अर्ज करू शकणाऱ्या योग्य कामगारांचे प्रकार निवडा.';

  @override
  String get postJobAudienceInformal => 'दैनिक मजुरी / असंघटित कामगार';

  @override
  String get postJobAudienceInformalHint =>
      'दैनिक मजूर, बांधकाम, लोडिंग, घरगुती कामगार';

  @override
  String get postJobAudienceStudent => 'विद्यार्थी';

  @override
  String get postJobAudienceStudentHint =>
      'संध्याकाळच्या किंवा शनिवार-रविवारच्या लवचिक कामासाठी कॉलेज विद्यार्थी';

  @override
  String get postJobAudiencePartTime => 'अर्धवेळ / लवचिक कामगार';

  @override
  String get postJobAudiencePartTimeHint =>
      'कमी शिफ्ट किंवा लवचिक वेळेत काम करणारे कामगार';

  @override
  String get postJobAudienceRequired => 'कृपया किमान एक कामगार प्रकार निवडा';

  @override
  String get hubConfirmedBookingEmptyTitle => 'कोणतेही सक्रिय बुकिंग नाही';

  @override
  String get hubConfirmedBookingEmptyDesc =>
      'तुमची पुष्टी केलेली बुकिंग आणि ट्रॅकिंग येथे दिसेल.';

  @override
  String get hubLocationNotSet => 'स्थान सेट केलेले नाही';

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
  String get hubActionScanQr => 'QR स्कॅन';

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
  String get demoModeBadge => 'डेमो मोड';

  @override
  String get timelineTitle => 'काम प्रगती टाइमलाइन';

  @override
  String get timelineLiveDot => 'थेट';

  @override
  String get timelineDisputeActive => 'वाद पुनरावलोकनाखाली आहे';

  @override
  String get timelineDisputeSub => 'मध्यस्थी पथक पुराव्यांची तपासणी करत आहे.';

  @override
  String get timelineCurrentBadge => 'सध्याचे';

  @override
  String get stageRequestCreated => 'विनंती तयार केली';

  @override
  String get stageAccepted => 'स्वीकारले';

  @override
  String get stageTicketIssued => 'तिकीट जारी केले';

  @override
  String get stageWorkerArrived => 'कामगार पोहोचले';

  @override
  String get stageVerificationCompleted => 'सत्यापन पूर्ण झाले';

  @override
  String get stageJobInProgress => 'काम चालू आहे';

  @override
  String get stageCompleted => 'पूर्ण झाले';

  @override
  String get stagePaymentReleased => 'पेमेंट जारी केले';

  @override
  String get stageDisputeRaised => 'वाद नोंदवला';

  @override
  String get activeJobTitle => 'सक्रिय काम प्रगती';

  @override
  String get actionAcceptJob => 'काम स्वीकारा';

  @override
  String get actionWorkerArrived => 'मी पोहोचलो आहे';

  @override
  String get actionStartWork => 'काम सुरू करा';

  @override
  String get actionCompleteJob => 'काम पूर्ण करा';

  @override
  String get actionAwaitingPayment => 'पेमेंट जारी होण्याची प्रतीक्षा';

  @override
  String get actionJobFinished => 'काम पूर्ण झाले';

  @override
  String get actionDisputeMediation => 'वाद पुनरावलोकन';

  @override
  String get actionWaitingAcceptance => 'कामगाराच्या मंजुरीची प्रतीक्षा';

  @override
  String get actionConfirmArrival => 'आगमन निश्चित करा';

  @override
  String get actionConfirmCompletion => 'काम पूर्ण झाल्याची खात्री करा';

  @override
  String get actionReleasePayment => 'पेमेंट जारी करा';

  @override
  String get actionPaymentDone => 'पेमेंट पूर्ण झाले';

  @override
  String get actionAskForHelp => 'मदत मागा';

  @override
  String get actionDispute => 'वाद नोंदवा';

  @override
  String get simpleModeSpokenLabel =>
      'बोलण्यासाठी आणि कार्यान्वित करण्यासाठी टॅप करा';

  @override
  String get routeAndEtaTitle => 'मार्ग आणि प्रवास वेळ';

  @override
  String get openInMapsBtn => 'नकाशात उघडा';

  @override
  String get demoModeChip => 'डेमो मोड';

  @override
  String get scheduleTitle => 'कामगारांचे वेळापत्रक आणि प्रवास';

  @override
  String get scheduleDayView => 'दिवस';

  @override
  String get scheduleWeekView => 'आठवडा';

  @override
  String get scheduleWeeklyTotal => 'आठवड्याची अंदाजे कमाई';

  @override
  String get ticketScreenTitle => 'डिजिटल जॉब तिकीट';

  @override
  String get refreshTicketTooltip => 'तिकीट क्यूआर रीफ्रेश करा';

  @override
  String get ticketOfflineNotice =>
      'सुरक्षा टोकन रीफ्रेश करण्यासाठी इंटरनेट आवश्यक आहे. कृपया स्कॅन करण्यापूर्वी पुन्हा कनेक्ट व्हा.';

  @override
  String get ticketBookingPassHeader => 'बुकिंग पास';

  @override
  String get ticketScanInstructions =>
      'कामाच्या ठिकाणी आल्यावर हा क्यूआर पास मालकाला दाखवा';

  @override
  String get ticketAutoRefreshesIn => 'रीफ्रेश होईल';

  @override
  String get ticketReplayShieldTitle => 'रीप्ले संरक्षण सक्षम';

  @override
  String get ticketReplayShieldBody =>
      'हा सुरक्षा पास एकल वापराचा असून दर २ मिनिटांनी बदलतो. स्क्रीनशॉट पुन्हा वापरता येत नाही.';

  @override
  String get attendanceScannerTitle => 'कामगार क्यूआर स्कॅन करा';

  @override
  String get attendanceScannerInstructions =>
      'हजेरी नोंदवण्यासाठी कामगाराचा डिजिटल तिकीट क्यूआर कोड फ्रेममध्ये ठेवा.';

  @override
  String get ticketReplayRefusedTitle => 'रीप्ले नाकारला';

  @override
  String get ticketExpiredTitle => 'तिकीट संपले';

  @override
  String get attendanceScanFailedTitle => 'हजेरी स्कॅन अयशस्वी';

  @override
  String get attendanceConfirmedTitle => 'हजेरी नोंदवली गेली!';

  @override
  String get workerMarkedArrived => 'कामगार कामावर आल्याची नोंद झाली';

  @override
  String get scanAgain => 'पुन्हा स्कॅन करा';

  @override
  String get scanDone => 'पूर्ण';

  @override
  String get viewActiveJob => 'सक्रिय काम पहा';

  @override
  String get actionShowTicket => 'क्यूआर तिकीट दाखवा';

  @override
  String get actionScanWorkerQr => 'कामगार क्यूआर स्कॅन करा';

  @override
  String get openSettings => 'सेटिंग्ज उघडा';

  @override
  String get bookingCodeCopied => 'बुकिंग कोड कॉपी केला';

  @override
  String get verifyYourPresence => 'तुमची उपस्थिती पडताळा';

  @override
  String get verifyPresenceSubtitle =>
      'काम सुरू करण्यापूर्वी चेहरा जुळणी आणि कार्यस्थळ जिओफेन्स तपासणी आवश्यक आहे';

  @override
  String get gpsPerimeterCheck => 'जीपीएस कार्यस्थळ जिओफेन्स तपासणी';

  @override
  String get withinPerimeter => 'कार्यस्थळ सीमेच्या आत';

  @override
  String get outsidePerimeter => 'कार्यस्थळ सीमेच्या बाहेर';

  @override
  String distanceFromSite(String distance, String radius) {
    return 'कार्यस्थळापासून अंतर: $distanceमी (मान्य: $radiusमी)';
  }

  @override
  String get mockLocationDetected =>
      'बनावट / मॉक जीपीएस आढळले. काम सुरू करणे नाकारले आणि चौकशीसाठी नोंदवले.';

  @override
  String get faceSelfieCheck => 'समोरील कॅमेरा चेहरा तपासणी';

  @override
  String get takeSelfieBtn => 'पडताळणी सेल्फी घ्या';

  @override
  String get retakeSelfieBtn => 'पुन्हा सेल्फी घ्या';

  @override
  String get verifyAndStartJob => 'उपस्थिती पडताळा आणि काम सुरू करा';

  @override
  String get verificationFailed => 'पडताळणी नाकारली';

  @override
  String outOfGeofenceMessage(String distance, String radius) {
    return 'तुम्ही कार्यस्थळापासून $distanceमी दूर आहात. सुरू करण्यासाठी $radiusमी च्या आत असणे आवश्यक आहे.';
  }

  @override
  String get getHelpOrSupport => 'मदत मिळवा';

  @override
  String get completionTitle => 'काम पूर्ण आणि पुरावा';

  @override
  String get completionSubtitle =>
      'समाप्तीची पडताळणी करण्यासाठी सेल्फी आणि कामाचे फोटो जमा करा';

  @override
  String get workResultPhotos => 'कामाचे पुरावे फोटो (खाजगी)';

  @override
  String get addWorkPhoto => 'फोटो जोडा';

  @override
  String get completeAndSubmit => 'काम पूर्ण जमा करा आणि टायमर थांबवा';

  @override
  String get midJobCheckTitle => 'मध्यंतरी पडताळणी आवश्यक';

  @override
  String get midJobCheckSubtitle =>
      'उच्च मूल्य काम सुरक्षा तपासणी (मजुरी >= ₹२,०००)';

  @override
  String get midJobConfirmSelfie => 'मध्यंतरी सेल्फी घ्या';

  @override
  String get midJobCustomerConfirm =>
      'कामगार कामाच्या ठिकाणी असल्याची खात्री करा';

  @override
  String get timerTitle => 'थेट काम टायमर';

  @override
  String get timerRunning => 'टायमर चालू आहे';

  @override
  String get timerPaused => 'टायमर थांबवला आहे';

  @override
  String get elapsedTime => 'झालेला वेळ';

  @override
  String get smartNoShowEngineHeader => 'स्मार्ट नो-शो रिकव्हरी इंजिन';

  @override
  String get arrivalGraceExpiredAlert => '⚠️ आगमन सवलत कालावधी संपला';

  @override
  String get workerHasNotArrivedTitle => 'कामगार पोहोचलेला नाही';

  @override
  String workerHasNotArrivedSubtitle(
    String workerName,
    int minutesLate,
    String jobTitle,
  ) {
    return '$workerName $jobTitle कामासाठी ठरलेल्या वेळेपेक्षा $minutesLate मिनिटे उशिरा आहेत.';
  }

  @override
  String get wait10MinutesAction => '10 मिनिटे थांबा';

  @override
  String get callWorkerDirectlyAction => '📞 कामगाराला थेट कॉल करा';

  @override
  String get findSmartReplacementAction => '⚡ स्मार्ट पर्यायी कामगार शोधा';

  @override
  String get gracePeriodExtendedMsg =>
      '+10 मिनिटे प्रतीक्षा वेळ जोडली. टायमर थांबवला.';

  @override
  String get maskedCallDemoMsg =>
      'कॉल केला जात आहे... (डेमो मोड: मास्क केलेला कॉल P7.2 मध्ये येईल)';

  @override
  String replacementBookedMsg(String workerName) {
    return '$workerName सह पर्यायी बुकिंग झाले! मूळ बुकिंग नो-शो म्हणून चिन्हांकित.';
  }

  @override
  String get rankedReplacementsTitle => 'क्रमवारी लावलेले जवळचे कामगार';

  @override
  String get noReplacementsFoundMsg =>
      'सध्या जवळ कोणताही पर्यायी कामगार उपलब्ध नाही.';

  @override
  String get requestReplacementOneTap => 'पर्यायी कामगार विनंती करा (1-टॅप)';

  @override
  String get smartNoShowTrustNote =>
      'नो-शो वर शून्य-दंड परतावा. पर्यायी कामगारांची पार्श्वभूमी तपासलेली आहे.';

  @override
  String get openRecoveryEngineAction => 'नो-शो रिकव्हरी इंजिन उघडा';

  @override
  String get runningLateQuestionAction => 'उशीर होतोय? आगमन वेळ शेअर करा';

  @override
  String runningLateReportedBadge(int minutes) {
    return 'उशिरा पोहोचण्याची नोंद केली (+$minutesमि). टायमर थांबवला.';
  }

  @override
  String get runningLateDialogTitle => 'उशीर होतोय का?';

  @override
  String get runningLateDialogSubtitle =>
      'तुमचा अपेक्षित उशीर निवडा. यामुळे मालकाला कळवले जाईल आणि ग्रेस टायमर एकदा थांबवला जाईल.';

  @override
  String get sendEtaAction => 'ETA पाठवा';

  @override
  String runningLateSuccessMsg(int minutes) {
    return '+$minutes मिनिटे उशीर कळवला. मालकाला सूचना दिली.';
  }

  @override
  String get jobHistoryTitle => 'कामाचा इतिहास आणि रेटिंग्ज';

  @override
  String get jobHistoryHeader => 'कामाचा इतिहास';

  @override
  String get favouritesTitle => 'आवडते आणि विश्वास मंडळ';

  @override
  String get rateJobTitle => 'कामाला रेट आणि पुनरावलोकन करा';

  @override
  String get quickTagsLabel => 'द्रुत टॅग्ज';

  @override
  String get reviewCommentLabel => 'अभिप्राय आणि पुनरावलोकन (पर्यायी)';

  @override
  String get reviewCommentHint =>
      'समुदायाला मदत करण्यासाठी आपला अनुभव शेअर करा...';

  @override
  String get submitReviewBtn => 'सत्यापित पुनरावलोकन सबमिट करा';

  @override
  String get reportDisputeTitle => 'कामाच्या वादाचा अहवाल द्या';

  @override
  String get disputeFreezeNotice =>
      'वाद दाखल केल्यास एस्क्रो पैसे देणे थांबवले जाते आणि पुनरावलोकनासाठी पाठवले जाते.';

  @override
  String get disputeIssueTypeLabel => 'समस्येचा प्रकार निवडा';

  @override
  String get disputeDetailsLabel => 'समस्येचा तपशील आणि वेळ';

  @override
  String get disputeDetailsHint => 'काय घडले ते स्पष्टपणे सांगा...';

  @override
  String get disputeEvidenceLabel => 'पुराव्याचे फोटो (पर्यायी)';

  @override
  String get submitDisputeBtn => 'औपचारिक वाद दाखल करा';

  @override
  String get disputeTypeNoShow => 'हजर राहिले नाहीत / गैरहजर';

  @override
  String get disputeTypeIncompleteWork => 'अपूर्ण काम / लवकर निघून गेले';

  @override
  String get disputeTypePoorQuality => 'निकृष्ट दर्जाचे काम';

  @override
  String get disputeTypeWrongProduct => 'चुकीचे उत्पादन / गुणवत्ता जुळत नाही';

  @override
  String get disputeTypePaymentIssue => 'पेमेंट समस्या / एस्क्रो वाद';

  @override
  String get disputeTypeUnsafeConduct => 'असुरक्षित वर्तन';

  @override
  String get disputeTypeVerificationProblem => 'पडताळणी / ओळख जुळत नाही';

  @override
  String get disputeTrackingTitle => 'वाद स्थिती ट्रॅकिंग';

  @override
  String get settingsSectionHeader => 'सेटिंग्ज';

  @override
  String get filterAll => 'सर्व';

  @override
  String get filterCompleted => 'पूर्ण झाले';

  @override
  String get filterDisputed => 'वादग्रस्त';

  @override
  String get filterInProgress => 'प्रगतीपथावर';

  @override
  String get filterCancelled => 'रद्द केले';

  @override
  String get walletTitle => 'वॉलेट आणि एस्क्रो';

  @override
  String get walletBalanceHeader => 'वॉलेट शिल्लक';

  @override
  String get escrowProtected => 'एस्क्रो संरक्षित';

  @override
  String get todaysReleased => 'आजचे जारी केलेले';

  @override
  String get pendingEscrow => 'प्रलंबित एस्क्रो';

  @override
  String get withdrawAction => 'पैसे काढा';

  @override
  String get scanUpiQr => 'UPI QR स्कॅन करा';

  @override
  String get recentTransactions => 'अलीकडील व्यवहार';

  @override
  String get withdrawEarningsTitle => 'कमाई काढा';

  @override
  String get demoWithdrawNote =>
      'डेमो मोड: बँकिंग भागीदार उपलब्ध होईपर्यंत सिम्युलेटेड पेआउट लेजर डेबिट.';

  @override
  String get transferToUpi => 'हस्तांतरण (UPI VPA / बँक)';

  @override
  String get confirmPayoutWithdrawal => 'पैसे काढण्याची पुष्टी करा';

  @override
  String get demoPayoutCompleted => 'डेमो पेआउट पूर्ण झाले';

  @override
  String get demoUpiScanner => 'डेमो मोड: सिम्युलेटेड UPI स्कॅनर';

  @override
  String get demoUpiNote =>
      'कोणतेही खरे पैसे हस्तांतरित केले जाणार नाहीत. पेमेंट रेल्स टप्पा 5.2 मध्ये जोडल्या जातील.';

  @override
  String get noTransactionsFound => 'कोणतेही व्यवहार आढळले नाहीत';

  @override
  String get noTransactionsSubtitle =>
      'पूर्ण झालेली दैनंदिन मजुरी आणि हस्तांतरण येथे दिसतील.';

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
  String get pendingEscrowRelease => 'एस्क्रो रिलीज प्रलंबित';

  @override
  String get protectedBadge => 'सुरक्षित';

  @override
  String get releaseEscrowPayment => 'एस्क्रो पेमेंट रिलीज करा';

  @override
  String get confirmAndRelease => 'पुष्टी करा आणि पेमेंट रिलीज करा';

  @override
  String get workerPayout => 'कामगार पेआउट (उपलब्ध शिल्लक)';

  @override
  String get escrowAutoReleaseNotice =>
      'मालकाने पुष्टी करताच किंवा कोणताही वाद नसल्यास 24 तासांच्या आत पेमेंट आपोआप रिलीज होईल.';

  @override
  String get escrowEarningsSecured =>
      'तुमची कमाई एस्क्रोमध्ये 100% सुरक्षित आहे';

  @override
  String get releaseEscrowSuccess =>
      'पेमेंट कामगाराच्या वॉलेटमध्ये यशस्वीरित्या रिलीज झाले!';

  @override
  String get earningsDashboardTitle => 'कमाई आणि कामगिरी';

  @override
  String get earningsToday => 'आजची कमाई';

  @override
  String get earningsThisWeek => 'या आठवड्यात';

  @override
  String get earningsThisMonth => 'या महिन्यात';

  @override
  String get earningsTotal => 'एकूण कमाई';

  @override
  String get earningsCompletedJobs => 'पूर्ण झालेली कामे';

  @override
  String get earningsFarmOrders => 'शेती ऑर्डर्स';

  @override
  String get earningsAverageRating => 'सरासरी रेटिंग';

  @override
  String get earningsDailyGoal => 'दैनिक ध्येय';

  @override
  String get earningsDailyGoalProgress => 'आजच्या ध्येयाची प्रगती';

  @override
  String get earningsPayoutTrends => 'पेआउट ट्रेंड';

  @override
  String get earningsTimeframe14Days => '14 दिवस';

  @override
  String get earningsTimeframe6Months => '6 महिने';

  @override
  String get earningsBestDayTitle => 'सर्वोत्कृष्ट कमाईचा दिवस';

  @override
  String earningsBestDaySubtitle(Object amount, Object date) {
    return 'तुम्ही $date रोजी $amount कमावले!';
  }

  @override
  String get earningsSetDailyGoal => 'दैनिक ध्येय सेट करा';

  @override
  String get earningsSaveGoal => 'ध्येय जतन करा';

  @override
  String get savingsGoalsTitle => 'बचत ध्येय नियोजक';

  @override
  String get savingsGoalsSubtitle =>
      'तुमच्या स्वप्नांचा मागोवा घ्या. ध्येय आभासी आहेत आणि पैसे लॉक करत नाहीत.';

  @override
  String get savingsGoalsVirtualNotice =>
      'आभासी ध्येय ट्रॅकर: ध्येय नियोजनासाठी आहेत. तुमचे पैसे नेहमी वॉलेटमध्ये उपलब्ध राहतात.';

  @override
  String get savingsGoalNew => 'नवीन बचत ध्येय';

  @override
  String get savingsGoalCreate => 'बचत ध्येय तयार करा';

  @override
  String get savingsGoalTarget => 'ध्येय रक्कम';

  @override
  String get savingsGoalSaved => 'आतापर्यंतची बचत';

  @override
  String get savingsGoalDeadline => 'अंतिम तारीख';

  @override
  String get savingsGoalCategory => 'श्रेणी';

  @override
  String get savingsGoalSuggestedPlan => 'सुचवलेली बचत योजना';

  @override
  String get savingsGoalAddSavings => 'बचत प्रगती नोंदवा';

  @override
  String get savingsGoalAddAmount => 'बचत रक्कम';

  @override
  String get savingsGoalCompletedBadge => 'ध्येय साध्य झाले! 🎉';

  @override
  String get savingsGoalActiveBadge => 'प्रगतीपथावर';

  @override
  String get savingsGoalCategorySchoolFees => 'शालेय शुल्क';

  @override
  String get savingsGoalCategoryEquipment => 'कामाची साधने';

  @override
  String get savingsGoalCategoryScooter => 'स्कूटर / वाहन';

  @override
  String get savingsGoalCategorySeeds => 'बियाणे आणि खते';

  @override
  String get savingsGoalCategoryEmergency => 'आपत्कालीन निधी';

  @override
  String get savingsGoalCategoryHome => 'घराचे नूतनीकरण';

  @override
  String get savingsGoalCategoryCustom => 'सानुकूल ध्येय';

  @override
  String get savingsGoalDelete => 'ध्येय हटवा';

  @override
  String get savingsGoalDeleteConfirm =>
      'तुम्ही हे बचत ध्येय नक्की हटवू इच्छिता?';

  @override
  String get savingsGoalEmptyState =>
      'बचत ध्येय सेट करून पुढील टप्प्याचे नियोजन करा.';

  @override
  String get savingsGoalsPlanGoals => 'ध्येय योजना करा';

  @override
  String get farmerWorkspace => 'शेतकरी कार्यक्षेत्र';

  @override
  String get farmerEmpoweredNetwork =>
      'उद्योगसेतू थेट कृषी नेटवर्क द्वारे सक्षम';

  @override
  String get farmerProduceSold => 'विकलेला शेतमाल';

  @override
  String get farmerThisMonth => 'या महिन्यात';

  @override
  String get farmerDirectEarnings => 'थेट उत्पन्न';

  @override
  String get farmerZeroMiddlemen => 'मध्यस्थ शून्य';

  @override
  String get farmerActiveLabor => 'सक्रिय मजूर';

  @override
  String get farmerHarvestShiftPlaceholder => 'कापणी शिफ्ट (P6.3)';

  @override
  String farmerBooked(int count) {
    return '$count बुक केले';
  }

  @override
  String get farmerWeatherAdvisoryRadar => 'हवामान सल्लागार रडार';

  @override
  String get farmerSimulatedForecast => 'सिम्युलेटेड अंदाज';

  @override
  String farmerRainProbability(int percent) {
    return '$percent% पावसाची शक्यता';
  }

  @override
  String get farmerBookHarvestHelpers => 'कापणी मजूर बुक करा';

  @override
  String get farmerViewIrrigationGuide => 'सिंचन मार्गदर्शक पहा';

  @override
  String get farmerLiveMandiPrices => 'थेट बाजारभाव आणि मागणी';

  @override
  String get farmerLiveFeed => 'लाईव्ह फीड';

  @override
  String get farmerAllCrops => 'सर्व पिके';

  @override
  String get farmerVegetables => 'भाज्या';

  @override
  String get farmerGrainsAndPulses => 'धान्य आणि डाळी';

  @override
  String get farmerNoPricesInCategory => 'या श्रेणीत बाजारभाव नाहीत';

  @override
  String get farmerSelectAllCropsHint =>
      'कर्नाटक APMC चे सर्व भाव पाहण्यासाठी सर्व पिके निवडा.';

  @override
  String farmerUpdatedDate(String date) {
    return 'अपडेट केले $date';
  }

  @override
  String get farmerApmcKarnatakaFeed => 'कर्नाटक APMC फीड';

  @override
  String get farmerEssentialSuite => 'शेतकऱ्यांसाठी आवश्यक सेवा';

  @override
  String get farmerRentTractor => 'ट्रॅक्टर भाड्याने घ्या';

  @override
  String get farmerHireWorkers => 'मजूर बोलवा';

  @override
  String get farmerSoilAiTest => 'माती AI चाचणी';

  @override
  String get farmerSellProduce => 'शेतमाल विका';

  @override
  String get farmerPestAiDoc => 'कीड AI डॉक्टर';

  @override
  String get farmerGovtSchemes => 'शासकीय योजना';

  @override
  String get farmerAgriDrone => 'कृषी ड्रोन';

  @override
  String get farmerIrrigationAi => 'सिंचन AI';

  @override
  String farmerComingInPhase(String phase) {
    return '$phase मध्ये येत आहे';
  }

  @override
  String get farmerUnderstood => 'समजले';

  @override
  String get farmerGotIt => 'ठीक आहे';

  @override
  String get farmerHireWorkersDesc =>
      'शेतकरी मजुरांची मागणी पोस्ट करू शकतील आणि थेट सत्यापित कामगारांना कामावर घेऊ शकतील.';

  @override
  String get farmerRentTractorDesc =>
      'जवळच्या कृषी केंद्रांमधून ट्रॅक्टर आणि अवजारे भाड्याने बुक करा.';

  @override
  String get farmerSoilAiTestDesc =>
      'माती चाचणी अहवाल अपलोड करा आणि तत्काळ AI खत शिफारसी मिळवा.';

  @override
  String get farmerSellProduceDesc =>
      'मध्यस्थांशिवाय थेट घाऊक खरेदीदारांना आपला शेतमाल विका.';

  @override
  String get farmerPestAiDocDesc =>
      'किडीचा फोटो काढून त्वरित AI उपचार आणि उपाय मिळवा.';

  @override
  String get farmerGovtSchemesDesc =>
      'पीएम-किसान, सौर पंप आणि पीक विमा योजना तपासा.';

  @override
  String get farmerAgriDroneDesc =>
      'फवारणीसाठी प्रमाणित कृषी ड्रोन पायलट बुक करा.';

  @override
  String get farmerIrrigationAiDesc =>
      'हवामान आणि आर्द्रतेनुसार स्मार्ट सिंचन नियोजन.';

  @override
  String get farmerHomeTitle => 'शेतकरी होम';

  @override
  String get farmerSimulateRainDev => 'पाऊस अंदाज सिम्युलेशन (Dev)';

  @override
  String get farmerFailedLoadMandi => 'बाजारभाव लोड करण्यात अयशस्वी';

  @override
  String get farmerHighDemand => 'उच्च मागणी';

  @override
  String get farmerStable => 'स्थिर';

  @override
  String get farmerFrpGuaranteed => 'FRP हमी';

  @override
  String get farmerMspProtected => 'MSP संरक्षित';

  @override
  String get farmerOversupply => 'अतिरिक्त आवक';

  @override
  String get farmerModerate => 'मध्यम';

  @override
  String get farmerProfileTitle => 'शेतकरी प्रोफाइल';

  @override
  String get verifiedFarmer => 'सत्यापित शेतकरी ✓';

  @override
  String get organicLand => 'सेंद्रिय जमीन';

  @override
  String get soldThisMonth => 'या महिन्यातील विक्री';

  @override
  String get directSales => 'थेट विक्री';

  @override
  String get farmInfrastructureAndBadges => 'शेती पायाभूत सुविधा आणि पीक बॅज';

  @override
  String get soilClassification => 'मातीचे वर्गीकरण';

  @override
  String get primaryCrops => 'प्रमुख पिके';

  @override
  String get apmcRegistration => 'एपीएमसी नोंदणी';

  @override
  String get kisanCreditCard => 'किसान क्रेडिट कार्ड';

  @override
  String get zeroPesticideOrganicCertificate =>
      'शून्य कीटकनाशक सेंद्रिय प्रमाणपत्र';

  @override
  String get verifiedByKarnatakaOrganicBoard =>
      'कर्नाटक सेंद्रिय शेतकरी मंडळाद्वारे सत्यापित';

  @override
  String get validatedStatus => 'सत्यापित ✓';

  @override
  String get underReviewStatus => 'पुनरावलोकनाधीन';

  @override
  String get languageMode => 'भाषा मोड';

  @override
  String get manageProduceListings => 'शेतमाल यादी व्यवस्थापित करा';

  @override
  String get produceListingsTitle => 'शेतमाल यादी';

  @override
  String get addNewProduce => 'नवीन शेतमाल जोडा';

  @override
  String get editProduceListing => 'शेतमाल संपादित करा';

  @override
  String get produceName => 'शेतमालाचे नाव';

  @override
  String get category => 'प्रवर्ग';

  @override
  String pricePerUnit(String unit) {
    return 'प्रति $unit किंमत';
  }

  @override
  String get stockQuantity => 'साठा प्रमाण';

  @override
  String get unit => 'युनिट';

  @override
  String get harvestDate => 'कापणीची तारीख';

  @override
  String get qualityNotes => 'गुणवत्ता नोंदी';

  @override
  String get farmingMethod => 'शेती पद्धत';

  @override
  String get deliveryAvailable => 'डिलिव्हरी उपलब्ध';

  @override
  String get pickupAvailable => 'शेत दरवाजातून पिकअप उपलब्ध';

  @override
  String get availabilityMode => 'उपलब्धता पद्धत';

  @override
  String get sameDayDelivery => 'त्याच दिवशी डिलिव्हरी';

  @override
  String get nextDayDelivery => 'दुसऱ्या दिवशी डिलिव्हरी';

  @override
  String get harvestPreOrder => 'कापणी पूर्व नोंदणी';

  @override
  String get farmerSetsFinalPrice => 'शेतकरी नेहमी अंतिम किंमत ठरवतो';

  @override
  String get statusLowStock => 'कमी साठा';

  @override
  String get statusSoldOut => 'संपले';

  @override
  String get statusPaused => 'थांबवले';

  @override
  String get pauseListing => 'थांबवा';

  @override
  String get activateListing => 'सुरू करा';

  @override
  String get updateStock => 'साठा अद्ययावत करा';

  @override
  String stockInStock(String stock) {
    return '$stock साठ्यात उपलब्ध';
  }

  @override
  String get buyerProduceMarket => 'ताजी शेतमाल उत्पादने';

  @override
  String get buyerSearchProduceHint =>
      'ताजा शेतमाल शोधा (उदा. टोमॅटो, तांदूळ)...';

  @override
  String get noProduceAvailable => 'कोणतीही उत्पादने उपलब्ध नाहीत';

  @override
  String get orderDirect => 'थेट मागणी करा';

  @override
  String get uploadProducePhotos => 'पिकांचे फोटो (produce-images)';

  @override
  String get addPhoto => 'फोटो जोडा';

  @override
  String get farmerMapHeader =>
      'शेतकऱ्यांसाठी आवश्यक उत्पादने, बियाणे, यंत्रसामग्री आणि सेवा';

  @override
  String get farmerNearbyRentals => 'जवळपासची यंत्रसामग्री आणि ड्रोन भाड्याने';

  @override
  String get farmerEscrowGuaranteed => 'एस्क्रो हमी';

  @override
  String get farmerBookNow => 'आत्ताच बुक करा';

  @override
  String get farmerBookItem => 'वस्तू बुक करा';

  @override
  String get farmerViewAllEquipmentMap =>
      'सर्व कृषी संसाधने आणि थेट नकाशा पहा →';

  @override
  String get farmerEquipmentBooked => 'उपकरणे बुक झाली!';

  @override
  String get farmerBookingQuantity => 'बुकिंग कालावधी / प्रमाण';

  @override
  String get farmerDeliveryAddress => 'शेत वितरण / कामाच्या ठिकाणाचा पत्ता';

  @override
  String get farmerSpecialNotes => 'कामाच्या सूचना / पिकाच्या नोंदी (पर्यायी)';

  @override
  String get farmerVendorHubTitle => 'यंत्रसामग्री विक्रेता केंद्र';

  @override
  String get farmerAddEquipment => 'उपकरणे जोडा';

  @override
  String get farmTraceabilityTitle => 'शेती गुणवत्ता मूळ पडताळणी';

  @override
  String get traceabilityCropItem => 'पीक तपशील:';

  @override
  String get traceabilityFarmerOrigin => 'शेतकरी मूळ:';

  @override
  String get traceabilityHarvestTime => 'कापणीची वेळ:';

  @override
  String get traceabilityCertification => 'सेंद्रिय प्रमाणपत्र:';

  @override
  String get traceabilityFarmingMethod => 'शेती पद्धती:';

  @override
  String get traceabilityQualityNotes => 'गुणवत्ता नोंदी:';

  @override
  String get closeTraceability => 'तपशील बंद करा';

  @override
  String get produceFiltersTitle => 'फिल्टर आणि क्रमवारी';

  @override
  String get clearFilters => 'रीसेट करा';

  @override
  String get sortBy => 'क्रमवारी लावा';

  @override
  String get maxDistance => 'जास्तीत जास्त अंतर';

  @override
  String get minFarmerRating => 'शेतकरी रेटिंग';

  @override
  String get freshnessFilter => 'कापणीची ताजी स्थिती';

  @override
  String get fulfillmentOptions => 'वितरण आणि उपलब्धता';

  @override
  String get deliveryAvailableOnly => 'होम डिलिव्हरी उपलब्ध';

  @override
  String get walkInStoreOnly => 'शेत दुकान / थेट खरेदी केंद्र';

  @override
  String get organicCertifiedOnly => 'फक्त सेंद्रिय प्रमाणित';

  @override
  String get applyFilters => 'फिल्टर लागू करा';

  @override
  String get customerProduceMapTitle =>
      'माझ्या जवळील शेतमाल, सेंद्रिय विक्रेते आणि दुकाने';

  @override
  String get orderNow => 'आत्ताच ऑर्डर करा';

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
  String get liveOrderTimeline => 'थेट ऑर्डर टाइमलाइन';

  @override
  String get orderCancelledRefundedNotice =>
      'ऑर्डर रद्द झाली. एस्क्रो रक्कम तुमच्या खात्यात परत जमा केली आहे.';

  @override
  String get orderDisputeNotice =>
      'तक्रार सुरू आहे. तोडगा निघेपर्यंत रक्कम रोखली आहे.';

  @override
  String get orderStagePlaced => 'ऑर्डर दिली';

  @override
  String get orderStagePlacedSub => 'रक्कम सुरक्षित ठेवली आहे';

  @override
  String get orderStageAccepted => 'शेतकऱ्याने स्वीकारली';

  @override
  String get orderStageAcceptedSub => 'माल गोळा करणे व प्रतवारी सुरू आहे';

  @override
  String get orderStagePacked => 'पॅक आणि वजन केले';

  @override
  String get orderStagePackedSub => 'गुणवत्ता तपासणी पूर्ण झाली';

  @override
  String get orderStageReadyPickup => 'पिकअपसाठी तयार';

  @override
  String get orderStageReadyPickupSub => 'पिकअप कोड घेऊन शेतावर जा';

  @override
  String get orderStageOutForDelivery => 'डिलिव्हरीसाठी निघाले';

  @override
  String get orderStageOutForDeliverySub => 'तुमच्या पत्त्यावर पोहोचत आहे';

  @override
  String get orderStagePickedUp => 'पिकअप पूर्ण व सत्यापित';

  @override
  String get orderStageDelivered => 'डिलिव्हर व सत्यापित';

  @override
  String get orderStageDeliveredSub => 'शेतकऱ्याला रक्कम दिली गेली';

  @override
  String get statusReadyForPickup => 'पिकअपसाठी तयार';

  @override
  String get statusOutForDelivery => 'डिलिव्हरीसाठी निघाले';

  @override
  String get rateOrderTitle => 'उत्पादनाला रेटिंग द्या';

  @override
  String get selectProduceTags => 'उत्पादनाची वैशिष्ट्ये:';

  @override
  String get orderReviewHint => 'ताजेपणा, चव आणि पॅकिंगबद्दल सांगा...';

  @override
  String get submitReviewButton => 'अभिप्राय नोंदवा';

  @override
  String get reportOrderIssue => 'तक्रार नोंदवा';

  @override
  String get disputeEscrowFreezeNotice =>
      'तपासणी होईपर्यंत रक्कम रोखून ठेवली जाईल.';

  @override
  String get selectIssueType => 'समस्येचा प्रकार निवडा:';

  @override
  String get describeIssueDetails => 'काय घडले ते सांगा:';

  @override
  String get disputeDetailsPlaceholder => 'उदा: २ किलो टोमॅटो खराब आले आहेत...';

  @override
  String get submitDisputeCTA => 'रक्कम रोखा आणि तक्रार नोंदवा';

  @override
  String get orderTrackingTitle => 'ऑर्डर ट्रॅकिंग';

  @override
  String get confirmDeliveryTitle => 'डिलिव्हरीची खात्री करा?';

  @override
  String get confirmDeliveryPrompt =>
      'ऑर्डर चांगल्या स्थितीत मिळाली का? यामुळे शेतकऱ्याला पैसे मिळतील.';

  @override
  String get confirmReceivedButton => 'होय, मिळाली';

  @override
  String get cancelOrderTitle => 'ऑर्डर रद्द करायची का?';

  @override
  String get cancelOrderPrompt => 'ऑर्डर रद्द केल्यास रक्कम परत मिळेल.';

  @override
  String get noKeepOrder => 'नाही, राहू द्या';

  @override
  String get yesCancelOrder => 'होय, रद्द करा';

  @override
  String get orderNotFound => 'ऑर्डर आढळली नाही.';

  @override
  String get farmPickupCodeHeader => 'पिकअप पडताळणी कोड';

  @override
  String get deliveryPinHeader => 'डिलिव्हरी पिन';

  @override
  String get showPickupCodeFarmerNote => 'शेतकऱ्याला हा ४ अंकी कोड दाखवा.';

  @override
  String get showDeliveryPinDriverNote =>
      'डिलिव्हरी मिळाल्यावर चालकाला हा कोड सांगा.';

  @override
  String get estimatedArrivalHeader => 'अंदाजे वेळ';

  @override
  String get orderItemsHeader => 'वस्तूंची यादी';

  @override
  String get totalAmount => 'एकूण भरलेली रक्कम:';

  @override
  String get confirmDeliveryReceivedButton =>
      'डिलिव्हरीची खात्री करा आणि पैसे द्या';

  @override
  String get releaseFundsNotice => 'खात्री करताच शेतकऱ्याला पैसे मिळतील.';

  @override
  String get reorderItemsButton => 'पुन्हा ऑर्डर करा';

  @override
  String get rateProduceButton => 'रेटिंग द्या';

  @override
  String get myFarmOrdersTitle => 'माझ्या शेती ऑर्डर्स';

  @override
  String get allOrdersFilter => 'सर्व ऑर्डर्स';

  @override
  String get activeFilter => 'सक्रिय';

  @override
  String get completedFilter => 'पूर्ण';

  @override
  String get cancelledFilter => 'रद्द';

  @override
  String get reorderButton => 'पुन्हा ऑर्डर';

  @override
  String get noOrdersFoundTitle => 'ऑर्डर्स सापडल्या नाहीत';

  @override
  String get noOrdersFoundSub => 'अजून कोणतीही ऑर्डर केलेली नाही.';

  @override
  String get exploreProduceButton => 'उत्पादने पहा';

  @override
  String get farmerOrderBoardTitle => 'शेतकरी ऑर्डर बोर्ड';

  @override
  String get trackOrderButton => 'ट्रॅक करा';

  @override
  String get cancelOrderButton => 'ऑर्डर रद्द करा आणि एस्क्रो परतावा मिळवा';

  @override
  String get disputeButton => 'तक्रार नोंदवा';

  @override
  String get statusAccepted => 'स्वीकारले';

  @override
  String get statusPacked => 'पॅक केले';

  @override
  String get statusDelivered => 'वितरित केले';

  @override
  String get statusDisputed => 'विवादास्पद';
}
