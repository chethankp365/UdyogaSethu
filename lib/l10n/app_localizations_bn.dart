// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

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
  String get walletBalance => 'ওয়ালেট ব্যালেন্স';

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
  String get kccApproved => 'কেসিসি অনুমোদিত ✓';

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
  String get providerWizardTitle => 'জব প্রোভাইডার সেটআপ';

  @override
  String get providerStep1Title => 'মৌলিক তথ্য';

  @override
  String get providerStep1Subtitle => 'আপনার পুরো নাম, ছবি এবং ভাষা লিখুন।';

  @override
  String get providerStep2Title => 'প্রোভাইডার টাইপ';

  @override
  String get providerStep2Subtitle =>
      'আপনি গৃহস্থালি নাকি নিয়োগকর্তা হিসেবে কাজ দিচ্ছেন নির্বাচন করুন।';

  @override
  String get providerStep3HouseholdTitle => 'বাড়ির ঠিকানা ও ডেলিভারি';

  @override
  String get providerStep3HouseholdSubtitle =>
      'ডিফল্ট ডেলিভারি ঠিকানা ও পছন্দ সেট করুন।';

  @override
  String get providerStep3EmployerTitle => 'সংস্থা ও সাইটের বিবরণ';

  @override
  String get providerStep3EmployerSubtitle =>
      'সংস্থার নাম, সাইটের ঠিকানা ও কর্মী সংখ্যা লিখুন।';

  @override
  String get providerStep4Title => 'অনুমতি ও সম্মতি';

  @override
  String get providerStep4Subtitle =>
      'লোকেশন এবং নোটিফিকেশন অনুমতি যাচাই করুন।';

  @override
  String get providerStep5Title => 'যাচাই করুন ও শেষ করুন';

  @override
  String get providerStep5Subtitle =>
      'শেষ করার আগে প্রোফাইল বিবরণ পরীক্ষা করুন।';

  @override
  String get doorstepAddressLabel => 'ফ্ল্যাট / বাড়ি নং এবং রাস্তা';

  @override
  String get doorstepAddressHint => 'যেমন #402, সানশাইন অ্যাপার্টমেন্ট';

  @override
  String get landmarkLabel => 'ল্যান্ডমার্ক';

  @override
  String get landmarkHint => 'যেমন মেট্রো স্টেশনের কাছে';

  @override
  String get deliveryInstructionsLabel => 'ডেলিভারি নির্দেশাবলী';

  @override
  String get deliveryInstructionsHint => 'যেমন গেটে সিকিউরিটিকে দিন';

  @override
  String get gateCodeLabel => 'গেট কোড (ঐচ্ছিক)';

  @override
  String get gateCodeHint => 'যেমন 1234';

  @override
  String get orgNameLabel => 'সংস্থা / ব্যবসার নাম';

  @override
  String get orgNameHint => 'যেমন সেতু কনস্ট্রাকশন';

  @override
  String get primarySiteAddressLabel => 'প্রধান সাইটের ঠিকানা';

  @override
  String get primarySiteAddressHint => 'যেমন সাইট 45, ইলেকট্রনিক্স সিটি';

  @override
  String get categoriesHiringLabel => 'কাজের ক্যাটাগরি';

  @override
  String get typicalCrewSizeLabel => 'প্রয়োজনীয় কর্মী সংখ্যা';

  @override
  String crewSizeWorkers(Object count) {
    return '$count জন কর্মী';
  }

  @override
  String get gpsConsentExplanation =>
      'সাইটের ঠিকানা ও কর্মী উপস্থিতি দেখাতে GPS প্রয়োজন।';

  @override
  String get notificationsConsentExplanation =>
      'কর্মী আবেদন ও ডেলিভারি আপডেট পেতে নোটিফিকেশন অন করুন।';

  @override
  String get grantGpsPermission => 'লোকেশন অনুমতি দিন';

  @override
  String get grantNotificationsPermission => 'নোটিফিকেশন অনুমতি দিন';

  @override
  String get permissionGranted => 'অনুমতি প্রাপ্ত';

  @override
  String get providerHomeTitle => 'প্রোভাইডার হোম';

  @override
  String get roleConflictTitle => 'ভূমিকা অ্যাকাউন্টের অস্তিত্ব রয়েছে';

  @override
  String roleConflictMessage(Object chosenRole, Object existingRole) {
    return 'আপনার অ্যাকাউন্ট ইতিমধ্যে $existingRole হিসেবে নিবন্ধিত।';
  }

  @override
  String roleConflictLoginAs(Object existingRole) {
    return '$existingRole হিসেবে লগ ইন করুন';
  }

  @override
  String get roleConflictBack => 'ফিরে যান';

  @override
  String get privacyCentreTitle => 'গোপনীয়তা কেন্দ্র';

  @override
  String get privacyCentreSubtitle =>
      'আপনার তথ্য সম্মতি এবং অনুমতিগুলি পরিচালনা করুন।';

  @override
  String get consentSheetTitle => 'তথ্য প্রক্রিয়াকরণ সম্মতি';

  @override
  String get consentWhatCollected => 'কী সংগ্রহ করা হয়';

  @override
  String get consentWhyCollected => 'কেন সংগ্রহ করা হয়';

  @override
  String get consentHowLongKept => 'কতক্ষণ রাখা হয়';

  @override
  String get consentWhoCanSee => 'কারা দেখতে পারবে';

  @override
  String get consentHowToWithdraw => 'কীভাবে প্রত্যাহার করবেন';

  @override
  String get consentAgreeButton => 'আমি সম্মত এবং অনুমোদন দিচ্ছি';

  @override
  String get consentNotNowButton => 'এখন নয়';

  @override
  String get consentGrantedStatus => 'সম্মতি দেওয়া হয়েছে';

  @override
  String get consentRevokedStatus => 'সম্মতি প্রত্যাহার করা হয়েছে';

  @override
  String get withdrawConsentButton => 'সম্মতি প্রত্যাহার করুন';

  @override
  String get withdrawFaceConsentTitle =>
      'ফেস ভেরিফিকেশন সম্মতি প্রত্যাহার করবেন?';

  @override
  String get withdrawFaceConsentMessage =>
      'ফেস সম্মতি প্রত্যাহার করলে আপনার রেফারেন্স রেকর্ড স্থায়ীভাবে মুছে যাবে।';

  @override
  String get confirmWithdrawButton => 'প্রত্যাহার করুন ও ডেটা মুছুন';

  @override
  String get cancelButton => 'বাতিল';

  @override
  String get profileTitle => 'আমার প্রোফাইল';

  @override
  String get termsAndPrivacyTitle => 'শর্তাবলী ও গোপনীয়তা নীতি';

  @override
  String get termsDraftNotice => 'খসড়া - চালুর আগে পরীক্ষা করুন';

  @override
  String get systemPermissionsTitle => 'সিস্টেমের অনুমতি';

  @override
  String get openSystemSettings => 'অ্যাপ সেটিংস খুলুন';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get faceVerificationCheck => 'ফেস ভেরিফিকেশন পরীক্ষা';

  @override
  String get faceCheckSubtext =>
      'ফেস লাইভনেস চেকের মাধ্যমে আপনার পরিচয় যাচাই করুন';

  @override
  String get faceMatchSuccess => 'ফেস পরিচয় যাচাই করা হয়েছে';

  @override
  String get faceMatchFailedTitle => 'ফেস ম্যাচ ব্যর্থ হয়েছে';

  @override
  String get faceMatchFailedBody =>
      'ভালো আলোতে আপনার মুখ পরিষ্কারভাবে রেখে পুনরায় চেষ্টা করুন।';

  @override
  String get manualReviewRequiredTitle =>
      '৩ টি ভেরিফিকেশন চেষ্টা ব্যর্থ হয়েছে';

  @override
  String get manualReviewRequiredBody =>
      'আপনার ফেস ভেরিফিকেশন ম্যানুয়াল পর্যালোচনার জন্য পাঠানো হয়েছে। আপনি সীমিত অ্যাক্সেস সহ চালিয়ে যেতে পারেন।';

  @override
  String get requestManualReview => 'ম্যানুয়াল পর্যালোচনার অনুরোধ করুন';

  @override
  String get retryVerification => 'পুনরায় চেষ্টা করুন';

  @override
  String get demoSimulatePass => 'ডেমো: সফল ভেরিফিকেশন';

  @override
  String get demoSimulateFail => 'ডেমো: ব্যর্থ ভেরিফিকেশন';

  @override
  String get seekerHomeTitle => 'চাকরিপ্রার্থী হোম';

  @override
  String get searchJobsPlaceholder => 'কাজ, সেবা খুঁজুন...';

  @override
  String get todaysGoal => 'আজকের লক্ষ্য';

  @override
  String get viewWallet => 'ওয়ালেট দেখুন >';

  @override
  String get locationSharingActive =>
      'সুরক্ষা পর্যবেক্ষণের জন্য অবস্থান ভাগ সক্রিয় রয়েছে';

  @override
  String get changeLocation => 'পরিবর্তন >';

  @override
  String get quickActionsHeader => 'দ্রুত কাজ';

  @override
  String get actionNearbyJobs => 'কাছের কাজ';

  @override
  String get actionAiAssistant => 'এআই সহকারী';

  @override
  String get actionWallet => 'ওয়ালেট';

  @override
  String get actionSafetyHub => 'সুরক্ষা কেন্দ্র';

  @override
  String get tagSponsored => 'বিজ্ঞাপন';

  @override
  String get whyAmISeeingThis => 'আমি এটি কেন দেখছি?';

  @override
  String get recommendedForYou => 'আপনার জন্য প্রস্তাবিত';

  @override
  String get applyNow => 'এখনই আবেদন করুন';

  @override
  String get applied => 'আবেদন করা হয়েছে ✓';

  @override
  String get noJobsNearYou => 'আপনার কাছাকাছি এখনও কোনও কাজ নেই';

  @override
  String get widenRadiusAction => 'অনুসন্ধানের পরিধি বাড়ান';

  @override
  String get sosEmergencyPill => 'জরুরি এসওএস';

  @override
  String get selectLocationArea => 'অবস্থান এলাকা নির্বাচন করুন';

  @override
  String get goodMorning => 'সুপ্রভাত';

  @override
  String get goodAfternoon => 'শুভ অপরাহ্ন';

  @override
  String get goodEvening => 'শুভ সন্ধ্যা';

  @override
  String get studentsWelcomeChip => 'শিক্ষার্থীদের স্বাগত';

  @override
  String get flexibleShiftChip => 'নমনীয় শিফট';

  @override
  String get nearbyJobsMapTitle => 'কাছাকাছি দৈনিক মজুরি কাজ এবং কর্মক্ষেত্র';

  @override
  String livePinsCount(Object count) {
    return '$count লাইভ পিন';
  }

  @override
  String nearbyGpsPinListings(Object count) {
    return 'কাছাকাছি জিপিএস পিন তালিকা ($count)';
  }

  @override
  String get tapPinOrCardToInspect => 'যাচাই করতে পিন বা কার্ডে আলতো চাপুন';

  @override
  String get applyButton => 'আবেদন করুন';

  @override
  String get categoryFilterAll => 'সব';

  @override
  String get recenterMap => 'জিপিএস পুনরায় কেন্দ্র করুন';

  @override
  String get zoomIn => 'জুম ইন';

  @override
  String get zoomOut => 'জুম আউট';

  @override
  String get gpsDisabledBanner =>
      'জিপিএস বন্ধ আছে। সঠিক দূরত্বের জন্য লোকেশন চালু করুন।';

  @override
  String get locationPermissionDeniedBanner =>
      'লোকেশন অনুমতি দেওয়া হয়নি। ডিফল্ট এলাকা দেখানো হচ্ছে।';

  @override
  String get noJobsInArea =>
      'এই ব্যাসার্ধের মধ্যে কোনো কর্মক্ষেত্র পাওয়া যায়নি';

  @override
  String get searchRadius => 'অনুসন্ধান ব্যাসার্ধ';

  @override
  String radiusKm(Object radius) {
    return '$radius কিমি';
  }

  @override
  String get openLocationSettings => 'সেটিংস';

  @override
  String get loadJobsError =>
      'কাছাকাছি কাজ লোড করা সম্ভব হচ্ছে না। সংযোগ পরীক্ষা করে পুনরায় চেষ্টা করুন।';

  @override
  String get retryAction => 'আবার চেষ্টা করুন';

  @override
  String get openStreetMapAttribution => '© OpenStreetMap contributors';

  @override
  String get cameraPermissionTitle => 'ক্যামেরা অ্যাক্সেস';

  @override
  String get cameraPermissionSubtitle =>
      'ফেস যাচাইকরণ এবং আইডি স্ক্যানিংয়ের জন্য ব্যবহৃত হয়।';

  @override
  String get locationPermissionTitle => 'ডিভাইসের অবস্থান (জিপিএস)';

  @override
  String get locationPermissionSubtitle =>
      'কাছাকাছি চাকরি, মানচিত্র এবং কাজের উপস্থিতি দেখানোর জন্য ব্যবহৃত হয়।';

  @override
  String get notificationPermissionTitle => 'বিজ্ঞপ্তি';

  @override
  String get notificationPermissionSubtitle =>
      'তাত্ক্ষণিক কাজের সতর্কতা, পেমেন্ট এবং নিরাপত্তা আপডেটের জন্য ব্যবহৃত হয়।';

  @override
  String get permissionAllowedStatus => 'অনুমোদিত';

  @override
  String get permissionBlockedStatus => 'ব্লকড / বন্ধ';

  @override
  String get refreshConsentsTooltip => 'স্ট্যাটাস রিফ্রেশ করুন';

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
  String get postJobStepAudience => 'উদ্দিষ্ট শ্রমিক';

  @override
  String get postJobAudienceTitle => 'এই কাজটি কাদের জন্য?';

  @override
  String get postJobAudienceSubtitle =>
      'এই কাজ দেখার এবং আবেদন করার উপযুক্ত শ্রমিকের ধরন নির্বাচন করুন।';

  @override
  String get postJobAudienceInformal => 'দৈনিক মজুরি / অসংগঠিত কর্মী';

  @override
  String get postJobAudienceInformalHint =>
      'দৈনিক দিনমজুর, নির্মাণ, লোডিং, গৃহকর্মী';

  @override
  String get postJobAudienceStudent => 'ছাত্র / ছাত্রী';

  @override
  String get postJobAudienceStudentHint =>
      'সন্ধ্যা বা সপ্তাহান্তের নমনীয় কাজের সন্ধানকারী কলেজ শিক্ষার্থীরা';

  @override
  String get postJobAudiencePartTime => 'খণ্ডকালীন / নমনীয় কর্মী';

  @override
  String get postJobAudiencePartTimeHint =>
      'কম শিফট বা নমনীয় সময়ে কাজ করতে আগ্রহী কর্মীরা';

  @override
  String get postJobAudienceRequired =>
      'অনুগ্রহ করে কমপক্ষে একটি শ্রমিকের ধরন নির্বাচন করুন';

  @override
  String get hubConfirmedBookingEmptyTitle => 'কোনও সক্রিয় বুকিং নেই';

  @override
  String get hubConfirmedBookingEmptyDesc =>
      'আপনার নিশ্চিত করা বুকিং এবং ট্র্যাকিং এখানে প্রদর্শিত হবে।';

  @override
  String get hubLocationNotSet => 'অবস্থান সেট করা নেই';

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
  String get hubActionScanQr => 'QR স্ক্যান';

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
  String get demoModeBadge => 'ডেমো মোড';

  @override
  String get timelineTitle => 'কাজের অগ্রগতি সময়রেখা';

  @override
  String get timelineLiveDot => 'লাইভ';

  @override
  String get timelineDisputeActive => 'বিরোধ পর্যালোচনার অধীনে রয়েছে';

  @override
  String get timelineDisputeSub => 'সালিশ দল প্রমাণ খতিয়ে দেখছে।';

  @override
  String get timelineCurrentBadge => 'বর্তমান';

  @override
  String get stageRequestCreated => 'অনুরোধ তৈরি করা হয়েছে';

  @override
  String get stageAccepted => 'গৃহীত';

  @override
  String get stageTicketIssued => 'টিকিট জারি করা হয়েছে';

  @override
  String get stageWorkerArrived => 'কর্মী পৌঁছেছেন';

  @override
  String get stageVerificationCompleted => 'যাচাইকরণ সম্পন্ন হয়েছে';

  @override
  String get stageJobInProgress => 'কাজ চলছে';

  @override
  String get stageCompleted => 'সম্পন্ন হয়েছে';

  @override
  String get stagePaymentReleased => 'পেমেন্ট প্রদান করা হয়েছে';

  @override
  String get stageDisputeRaised => 'বিরোধ উত্থাপন করা হয়েছে';

  @override
  String get activeJobTitle => 'সক্রিয় কাজের অগ্রগতি';

  @override
  String get actionAcceptJob => 'কাজ গ্রহণ করুন';

  @override
  String get actionWorkerArrived => 'আমি পৌঁছে গেছি';

  @override
  String get actionStartWork => 'কাজ শুরু করুন';

  @override
  String get actionCompleteJob => 'কাজ সম্পন্ন করুন';

  @override
  String get actionAwaitingPayment => 'পেমেন্ট প্রকাশের অপেক্ষায়';

  @override
  String get actionJobFinished => 'কাজ সম্পূর্ণরূপে শেষ';

  @override
  String get actionDisputeMediation => 'বিরোধ পর্যালোচনাধীন';

  @override
  String get actionWaitingAcceptance => 'কর্মীর সম্মতির অপেক্ষায়';

  @override
  String get actionConfirmArrival => 'আগমন নিশ্চিত করুন';

  @override
  String get actionConfirmCompletion => 'কাজ সমাপ্তি নিশ্চিত করুন';

  @override
  String get actionReleasePayment => 'পেমেন্ট প্রদান করুন';

  @override
  String get actionPaymentDone => 'পেমেন্ট নিষ্পত্তি হয়েছে';

  @override
  String get actionAskForHelp => 'সাহায্য চান';

  @override
  String get actionDispute => 'বিরোধ উত্থাপন করুন';

  @override
  String get simpleModeSpokenLabel => 'কথা বলতে এবং কার্যকর করতে ট্যাপ করুন';

  @override
  String get routeAndEtaTitle => 'রুট এবং ভ্রমণের সময়';

  @override
  String get openInMapsBtn => 'মানচিত্রে খুলুন';

  @override
  String get demoModeChip => 'ডেমো মোড';

  @override
  String get scheduleTitle => 'কর্মীর সময়সূচী এবং ভ্রমণ';

  @override
  String get scheduleDayView => 'দিন';

  @override
  String get scheduleWeekView => 'সপ্তাহ';

  @override
  String get scheduleWeeklyTotal => 'সপ্তাহের আনুমানিক আয়';

  @override
  String get ticketScreenTitle => 'ডিজিটাল কাজের টিকিট';

  @override
  String get refreshTicketTooltip => 'টিকিট কিউআর রিফ্রেশ করুন';

  @override
  String get ticketOfflineNotice =>
      'সুরক্ষা টোকেন রিফ্রেশ করতে ইন্টারনেট প্রয়োজন। নিয়োগকর্তা স্ক্যান করার আগে অনুগ্রহ করে সংযোগ করুন।';

  @override
  String get ticketBookingPassHeader => 'বুকিং পাস';

  @override
  String get ticketScanInstructions =>
      'কাজের জায়গায় পৌঁছে এই কিউআর পাসটি নিয়োগকর্তাকে দেখান';

  @override
  String get ticketAutoRefreshesIn => 'রিফ্রেশ হবে';

  @override
  String get ticketReplayShieldTitle => 'রিপ্লে সুরক্ষা সক্রিয়';

  @override
  String get ticketReplayShieldBody =>
      'এই নিরাপত্তা পাসটি একক ব্যবহারের এবং প্রতি ২ মিনিটে পরিবর্তন হয়। স্ক্রিনশট পুনরায় স্ক্যান করা যাবে না।';

  @override
  String get attendanceScannerTitle => 'কর্মীর কিউআর স্ক্যান করুন';

  @override
  String get attendanceScannerInstructions =>
      'উপস্থিতি নিশ্চিত করতে কর্মীর ডিজিটাল টিকিট কিউআর কোডটি ফ্রেমে রাখুন।';

  @override
  String get ticketReplayRefusedTitle => 'রিপ্লে প্রত্যাখ্যান করা হয়েছে';

  @override
  String get ticketExpiredTitle => 'টিকিটের মেয়াদ শেষ';

  @override
  String get attendanceScanFailedTitle => 'উপস্থিতি স্ক্যান ব্যর্থ হয়েছে';

  @override
  String get attendanceConfirmedTitle => 'উপস্থিতি নিশ্চিত হয়েছে!';

  @override
  String get workerMarkedArrived =>
      'কর্মী কাজের জায়গায় উপস্থিত হিসেবে চিহ্নিত';

  @override
  String get scanAgain => 'আবার স্ক্যান করুন';

  @override
  String get scanDone => 'সম্পন্ন';

  @override
  String get viewActiveJob => 'সক্রিয় কাজ দেখুন';

  @override
  String get actionShowTicket => 'কিউআর টিকিট দেখান';

  @override
  String get actionScanWorkerQr => 'কর্মীর কিউআর স্ক্যান করুন';

  @override
  String get openSettings => 'সেটিংস খুলুন';

  @override
  String get bookingCodeCopied => 'বুকিং কোড কপি করা হয়েছে';

  @override
  String get verifyYourPresence => 'আপনার উপস্থিতি যাচাই করুন';

  @override
  String get verifyPresenceSubtitle =>
      'কাজ শুরু করার আগে মুখমণ্ডল মেলানো এবং সাইট জিওফেন্স পরীক্ষা আবশ্যক';

  @override
  String get gpsPerimeterCheck => 'জিপিএস কাজের সাইট জিওফেন্স পরীক্ষা';

  @override
  String get withinPerimeter => 'কাজের সাইটের সীমানার মধ্যে';

  @override
  String get outsidePerimeter => 'কাজের সাইটের সীমানার বাইরে';

  @override
  String distanceFromSite(String distance, String radius) {
    return 'কাজের জায়গা থেকে দূরত্ব: $distanceমি (অনুমোদিত: $radiusমি)';
  }

  @override
  String get mockLocationDetected =>
      'নকল / মক জিপিএস সনাক্ত করা হয়েছে। কাজ শুরু প্রত্যাখ্যান করা হয়েছে এবং পর্যালোচনার জন্য নথিভুক্ত করা হয়েছে।';

  @override
  String get faceSelfieCheck => 'সামনের ক্যামেরা মুখমণ্ডল যাচাই';

  @override
  String get takeSelfieBtn => 'যাচাইকরণ সেলফি তুলুন';

  @override
  String get retakeSelfieBtn => 'আবার সেলফি তুলুন';

  @override
  String get verifyAndStartJob => 'উপস্থিতি যাচাই করুন এবং কাজ শুরু করুন';

  @override
  String get verificationFailed => 'যাচাইকরণ প্রত্যাখ্যাত';

  @override
  String outOfGeofenceMessage(String distance, String radius) {
    return 'আপনি কাজের সাইট থেকে $distanceমি দূরে আছেন। শুরু করতে আপনাকে $radiusমি এর মধ্যে থাকতে হবে।';
  }

  @override
  String get getHelpOrSupport => 'সহায়তা পান';

  @override
  String get completionTitle => 'কাজ সমাপ্তি এবং প্রমাণ';

  @override
  String get completionSubtitle =>
      'সমাপ্তি যাচাইয়ের জন্য সেলফি এবং কাজের ছবি জমা দিন';

  @override
  String get workResultPhotos => 'কাজের প্রমাণ ছবি (ব্যক্তিগত)';

  @override
  String get addWorkPhoto => 'ছবি যোগ করুন';

  @override
  String get completeAndSubmit => 'সমাপ্তি জমা দিন এবং টাইমার থামান';

  @override
  String get midJobCheckTitle => 'কাজের মধ্যবর্তী যাচাইকরণ প্রয়োজন';

  @override
  String get midJobCheckSubtitle =>
      'উচ্চ মূল্যের কাজের নিরাপত্তা পরীক্ষা (মজুরি >= ₹২,০০০)';

  @override
  String get midJobConfirmSelfie => 'মধ্যবর্তী সেলফি তুলুন';

  @override
  String get midJobCustomerConfirm => 'কর্মী সাইটে আছেন তা নিশ্চিত করুন';

  @override
  String get timerTitle => 'লাইভ কাজের টাইমার';

  @override
  String get timerRunning => 'টাইমার চলছে';

  @override
  String get timerPaused => 'টাইমার থামানো হয়েছে';

  @override
  String get elapsedTime => 'অতিক্রান্ত সময়';

  @override
  String get smartNoShowEngineHeader => 'স্মার্ট নো-শো রিকভারি ইঞ্জিন';

  @override
  String get arrivalGraceExpiredAlert => '⚠️ আগমনের গ্রেস পিরিয়ড শেষ হয়েছে';

  @override
  String get workerHasNotArrivedTitle => 'কর্মী আসেননি';

  @override
  String workerHasNotArrivedSubtitle(
    String workerName,
    int minutesLate,
    String jobTitle,
  ) {
    return '$workerName $jobTitle কাজের জন্য নির্ধারিত সময়ের চেয়ে $minutesLate মিনিট দেরিতে আছেন।';
  }

  @override
  String get wait10MinutesAction => '10 মিনিট অপেক্ষা করুন';

  @override
  String get callWorkerDirectlyAction => '📞 কর্মীকে সরাসরি কল করুন';

  @override
  String get findSmartReplacementAction => '⚡ স্মার্ট বিকল্প কর্মী খুঁজুন';

  @override
  String get gracePeriodExtendedMsg =>
      '+10 মিনিট অপেক্ষার সময় যোগ করা হয়েছে। টাইমার থামানো হয়েছে।';

  @override
  String get maskedCallDemoMsg =>
      'কল করা হচ্ছে... (ডেমো মোড: মাস্কড কল P7.2 এ আসবে)';

  @override
  String replacementBookedMsg(String workerName) {
    return '$workerName-এর সাথে বিকল্প কর্মী বুক করা হয়েছে! মূল কর্মীকে নো-শো চিহ্নিত করা হয়েছে।';
  }

  @override
  String get rankedReplacementsTitle => 'র‌্যাঙ্কযুক্ত নিকটবর্তী কর্মী';

  @override
  String get noReplacementsFoundMsg =>
      'বর্তমানে কাছাকাছি কোনো বিকল্প কর্মী উপলব্ধ নেই।';

  @override
  String get requestReplacementOneTap => 'বিকল্প অনুরোধ করুন (১-ট্যাপ)';

  @override
  String get smartNoShowTrustNote =>
      'নো-শোতে শূন্য জরিমানা ফেরত। বিকল্প কর্মীদের ব্যাকগ্রাউন্ড যাচাইকৃত।';

  @override
  String get openRecoveryEngineAction => 'নো-শো রিকভারি ইঞ্জিন খুলুন';

  @override
  String get runningLateQuestionAction => 'দেরি হচ্ছে? আগমনের সময় জানান';

  @override
  String runningLateReportedBadge(int minutes) {
    return 'দেরির তথ্য জানানো হয়েছে (+$minutesমি)। টাইমার স্থগিত।';
  }

  @override
  String get runningLateDialogTitle => 'দেরি হচ্ছে?';

  @override
  String get runningLateDialogSubtitle =>
      'আপনার প্রত্যাশিত বিলম্ব নির্বাচন করুন। এটি নিয়োগকর্তাকে অবহিত করবে এবং গ্রেস টাইমার একবার স্থগিত করবে।';

  @override
  String get sendEtaAction => 'ETA পাঠান';

  @override
  String runningLateSuccessMsg(int minutes) {
    return '+$minutes মিনিট বিলম্বের তথ্য পাঠানো হয়েছে। নিয়োগকর্তা অবহিত।';
  }

  @override
  String get jobHistoryTitle => 'কাজের ইতিহাস এবং রেটিং';

  @override
  String get jobHistoryHeader => 'কাজের ইতিহাস';

  @override
  String get favouritesTitle => 'পছন্দের তালিকা এবং ট্রাস্ট সার্কেল';

  @override
  String get rateJobTitle => 'কাজে রেটিং এবং পর্যালোচনা দিন';

  @override
  String get quickTagsLabel => 'দ্রুত ট্যাগ';

  @override
  String get reviewCommentLabel => 'মতামত এবং পর্যালোচনা (ঐচ্ছিক)';

  @override
  String get reviewCommentHint =>
      'সম্প্রদায়কে সাহায্য করতে আপনার অভিজ্ঞতা শেয়ার করুন...';

  @override
  String get submitReviewBtn => 'যাচাইকৃত পর্যালোচনা জমা দিন';

  @override
  String get reportDisputeTitle => 'কাজের বিরোধ রিপোর্ট করুন';

  @override
  String get disputeFreezeNotice =>
      'বিরোধ দায়ের করলে এসক্রো অর্থ প্রদান স্থগিত করা হয় এবং পর্যালোচনার জন্য পাঠানো হয়।';

  @override
  String get disputeIssueTypeLabel => 'সমস্যার ধরন নির্বাচন করুন';

  @override
  String get disputeDetailsLabel => 'সমস্যার বিবরণ এবং সময়রেখা';

  @override
  String get disputeDetailsHint => 'কী ঘটেছে তা স্পষ্টভাবে ব্যাখ্যা করুন...';

  @override
  String get disputeEvidenceLabel => 'প্রমাণের ছবি (ঐচ্ছিক)';

  @override
  String get submitDisputeBtn => 'আনুষ্ঠানিক বিরোধ উত্থাপন করুন';

  @override
  String get disputeTypeNoShow => 'উপস্থিত হননি / অনুপস্থিতি';

  @override
  String get disputeTypeIncompleteWork =>
      'অসম্পূর্ণ কাজ / তাড়াতাড়ি চলে গেছেন';

  @override
  String get disputeTypePoorQuality => 'নিম্নমানের কাজ';

  @override
  String get disputeTypeWrongProduct => 'ভুল পণ্য / মানের অমিল';

  @override
  String get disputeTypePaymentIssue => 'পেমেন্ট সমস্যা / এসক্রো বিরোধ';

  @override
  String get disputeTypeUnsafeConduct => 'নিরাপত্তাহীন আচরণ';

  @override
  String get disputeTypeVerificationProblem => 'যাচাইকরণ / পরিচয়ের অমিল';

  @override
  String get disputeTrackingTitle => 'বিরোধের অবস্থা ট্র্যাকিং';

  @override
  String get settingsSectionHeader => 'সেটিংস';

  @override
  String get filterAll => 'সব';

  @override
  String get filterCompleted => 'সম্পন্ন';

  @override
  String get filterDisputed => 'বিরোধপূর্ণ';

  @override
  String get filterInProgress => 'চলমান';

  @override
  String get filterCancelled => 'বাতিল';

  @override
  String get walletTitle => 'ওয়ালেট ও এসক্রো';

  @override
  String get walletBalanceHeader => 'ওয়ালেট ব্যালেন্স';

  @override
  String get escrowProtected => 'এসক্রো সুরক্ষিত';

  @override
  String get todaysReleased => 'আজকের মুক্তিপ্রাপ্ত';

  @override
  String get pendingEscrow => 'মুলতুবি এসক্রো';

  @override
  String get withdrawAction => 'উত্তোলন';

  @override
  String get scanUpiQr => 'UPI QR স্ক্যান করুন';

  @override
  String get recentTransactions => 'সাম্প্রতিক লেনদেন';

  @override
  String get withdrawEarningsTitle => 'উপার্জন উত্তোলন করুন';

  @override
  String get demoWithdrawNote =>
      'ডেমো মোড: ব্যাঙ্কিং অংশীদার পাওয়া পর্যন্ত সিমুলেটেড পেআউট লেজার ডেবিট।';

  @override
  String get transferToUpi => 'স্থানান্তর (UPI VPA / ব্যাংক)';

  @override
  String get confirmPayoutWithdrawal => 'উত্তোলন নিশ্চিত করুন';

  @override
  String get demoPayoutCompleted => 'ডেমো পেআউট সম্পন্ন হয়েছে';

  @override
  String get demoUpiScanner => 'ডেমো মোড: সিমুলেটেড UPI স্ক্যানার';

  @override
  String get demoUpiNote =>
      'কোন আসল টাকা স্থানান্তরিত হবে না। পর্যায় 5.2-এ পেমেন্ট রেল সংযুক্ত হবে।';

  @override
  String get noTransactionsFound => 'কোন লেনদেন পাওয়া যায়নি';

  @override
  String get noTransactionsSubtitle =>
      'সম্পন্ন দৈনিক মজুরি এবং স্থানান্তর এখানে উপস্থিত হবে।';

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
  String get pendingEscrowRelease => 'এসক্রো রিলিজ পেন্ডিং';

  @override
  String get protectedBadge => 'সুরক্ষিত';

  @override
  String get releaseEscrowPayment => 'এসক্রো পেমেন্ট রিলিজ করুন';

  @override
  String get confirmAndRelease => 'নিশ্চিত করুন এবং পেমেন্ট রিলিজ করুন';

  @override
  String get workerPayout => 'কর্মী পেআউট (উপলব্ধ ব্যালেন্স)';

  @override
  String get escrowAutoReleaseNotice =>
      'নিয়োগকর্তা নিশ্চিত করার সাথে সাথে বা কোনো বিরোধ না থাকলে ২৪ ঘণ্টার মধ্যে পেমেন্ট স্বয়ংক্রিয়ভাবে রিলিজ হবে।';

  @override
  String get escrowEarningsSecured => 'আপনার উপার্জন এসক্রোতে ১০০% সুরক্ষিত';

  @override
  String get releaseEscrowSuccess =>
      'পেমেন্ট সফলভাবে কর্মীর ওয়ালেটে রিলিজ করা হয়েছে!';

  @override
  String get earningsDashboardTitle => 'উপার্জন ও কর্মক্ষমতা';

  @override
  String get earningsToday => 'আজকের উপার্জন';

  @override
  String get earningsThisWeek => 'এই সপ্তাহে';

  @override
  String get earningsThisMonth => 'এই মাসে';

  @override
  String get earningsTotal => 'মোট উপার্জন';

  @override
  String get earningsCompletedJobs => 'সম্পন্ন কাজ';

  @override
  String get earningsFarmOrders => 'খামার অর্ডার';

  @override
  String get earningsAverageRating => 'গড় রেটিং';

  @override
  String get earningsDailyGoal => 'দৈনিক লক্ষ্য';

  @override
  String get earningsDailyGoalProgress => 'আজকের লক্ষ্যের অগ্রগতি';

  @override
  String get earningsPayoutTrends => 'পেআউট ট্রেন্ড';

  @override
  String get earningsTimeframe14Days => '১৪ দিন';

  @override
  String get earningsTimeframe6Months => '৬ মাস';

  @override
  String get earningsBestDayTitle => 'সেরা উপার্জনের দিন';

  @override
  String earningsBestDaySubtitle(Object amount, Object date) {
    return 'আপনি $date-এ $amount উপার্জন করেছেন!';
  }

  @override
  String get earningsSetDailyGoal => 'দৈনিক লক্ষ্য নির্ধারণ করুন';

  @override
  String get earningsSaveGoal => 'লক্ষ্য সংরক্ষণ করুন';

  @override
  String get savingsGoalsTitle => 'সঞ্চয় লক্ষ্য পরিকল্পনাকারী';

  @override
  String get savingsGoalsSubtitle =>
      'স্বপ্নগুলো ট্র্যাক করুন। লক্ষ্যগুলো ভার্চুয়াল এবং টাকা লক করে না।';

  @override
  String get savingsGoalsVirtualNotice =>
      'ভার্চুয়াল লক্ষ্য ট্র্যাকার: লক্ষ্যগুলো বাজেটের পরিকল্পনার জন্য। আপনার টাকা সবসময় ওয়ালেটে উপলব্ধ থাকে।';

  @override
  String get savingsGoalNew => 'নতুন সঞ্চয় লক্ষ্য';

  @override
  String get savingsGoalCreate => 'লক্ষ্য তৈরি করুন';

  @override
  String get savingsGoalTarget => 'লক্ষ্য পরিমাণ';

  @override
  String get savingsGoalSaved => 'এ পর্যন্ত সঞ্চিত';

  @override
  String get savingsGoalDeadline => 'নির্দিষ্ট সময়সীমা';

  @override
  String get savingsGoalCategory => 'বিভাগ';

  @override
  String get savingsGoalSuggestedPlan => 'প্রস্তাবিত সঞ্চয় পরিকল্পনা';

  @override
  String get savingsGoalAddSavings => 'সঞ্চয়ের অগ্রগতি রেকর্ড করুন';

  @override
  String get savingsGoalAddAmount => 'সঞ্চিত পরিমাণ';

  @override
  String get savingsGoalCompletedBadge => 'লক্ষ্য অর্জিত হয়েছে! 🎉';

  @override
  String get savingsGoalActiveBadge => 'চলমান';

  @override
  String get savingsGoalCategorySchoolFees => 'স্কুলের ফি';

  @override
  String get savingsGoalCategoryEquipment => 'কাজের সরঞ্জাম';

  @override
  String get savingsGoalCategoryScooter => 'স্কুটার / যানবাহন';

  @override
  String get savingsGoalCategorySeeds => 'বীজ ও সার';

  @override
  String get savingsGoalCategoryEmergency => 'জরুরী তহবিল';

  @override
  String get savingsGoalCategoryHome => 'বাড়ি সংস্কার';

  @override
  String get savingsGoalCategoryCustom => 'কাস্টম লক্ষ্য';

  @override
  String get savingsGoalDelete => 'লক্ষ্য মুছুন';

  @override
  String get savingsGoalDeleteConfirm =>
      'আপনি কি নিশ্চিতভাবে এই সঞ্চয় লক্ষ্যটি মুছে ফেলতে চান?';

  @override
  String get savingsGoalEmptyState =>
      'সঞ্চয় লক্ষ্য নির্ধারণ করে পরবর্তী লক্ষ্যের পরিকল্পনা করুন।';

  @override
  String get savingsGoalsPlanGoals => 'লক্ষ্য পরিকল্পনা করুন';

  @override
  String get farmerWorkspace => 'কৃষক ওয়ার্কস্পেস';

  @override
  String get farmerEmpoweredNetwork =>
      'উদ্যোগসেতু ডিরেক্ট এগ্রি-নেটওয়ার্ক দ্বারা চালিত';

  @override
  String get farmerProduceSold => 'বিক্রিত ফসল';

  @override
  String get farmerThisMonth => 'এই মাসে';

  @override
  String get farmerDirectEarnings => 'সরাসরি আয়';

  @override
  String get farmerZeroMiddlemen => 'দালালমুক্ত';

  @override
  String get farmerActiveLabor => 'সক্রিয় শ্রমিক';

  @override
  String get farmerHarvestShiftPlaceholder => 'ফসল কাটা শিফট (P6.3)';

  @override
  String farmerBooked(int count) {
    return '$count বুক করা হয়েছে';
  }

  @override
  String get farmerWeatherAdvisoryRadar => 'আবহাওয়া পরামর্শ রাডার';

  @override
  String get farmerSimulatedForecast => 'সিমুলেটেড পূর্বাভাস';

  @override
  String farmerRainProbability(int percent) {
    return '$percent% বৃষ্টির সম্ভাবনা';
  }

  @override
  String get farmerBookHarvestHelpers => 'ফসল কাটার শ্রমিক বুক করুন';

  @override
  String get farmerViewIrrigationGuide => 'সেচ নির্দেশিকা দেখুন';

  @override
  String get farmerLiveMandiPrices => 'লাইভ মান্ডি দর ও চাহিদা';

  @override
  String get farmerLiveFeed => 'লাইভ ফিড';

  @override
  String get farmerAllCrops => 'সমস্ত ফসল';

  @override
  String get farmerVegetables => 'শাকসবজি';

  @override
  String get farmerGrainsAndPulses => 'শস্য ও ডাল';

  @override
  String get farmerNoPricesInCategory => 'এই বিভাগে মান্ডি দর নেই';

  @override
  String get farmerSelectAllCropsHint =>
      'কর্ণাটক APMC-এর সমস্ত দর দেখতে সমস্ত ফসল নির্বাচন করুন।';

  @override
  String farmerUpdatedDate(String date) {
    return 'আপডেট করা হয়েছে $date';
  }

  @override
  String get farmerApmcKarnatakaFeed => 'কর্ণাটক APMC ফিড';

  @override
  String get farmerEssentialSuite => 'কৃষকের প্রয়োজনীয় সেবা';

  @override
  String get farmerRentTractor => 'ট্রাক্টর ভাড়া নিন';

  @override
  String get farmerHireWorkers => 'শ্রমিক নিয়োগ করুন';

  @override
  String get farmerSoilAiTest => 'মাটি AI পরীক্ষা';

  @override
  String get farmerSellProduce => 'ফসল বিক্রি করুন';

  @override
  String get farmerPestAiDoc => 'কীটপতঙ্গ AI ডাক্তার';

  @override
  String get farmerGovtSchemes => 'সরকারি প্রকল্প';

  @override
  String get farmerAgriDrone => 'কৃষি ড্রোন';

  @override
  String get farmerIrrigationAi => 'সেচ AI';

  @override
  String farmerComingInPhase(String phase) {
    return '$phase-এ আসছে';
  }

  @override
  String get farmerUnderstood => 'বুঝেছি';

  @override
  String get farmerGotIt => 'ঠিক আছে';

  @override
  String get farmerHireWorkersDesc =>
      'কৃষকরা সরাসরি শ্রমিকদের প্রয়োজন পোস্ট করতে পারবেন এবং যাচাইকৃত শ্রমিক নিয়োগ করতে পারবেন।';

  @override
  String get farmerRentTractorDesc =>
      'কাছাকাছি হাব থেকে ট্রাক্টর এবং হার্ভেস্টার ভাড়া বুক করুন।';

  @override
  String get farmerSoilAiTestDesc =>
      'মাটি পরীক্ষার ছবি আপলোড করে তাৎক্ষণিক AI সারের পরামর্শ পান।';

  @override
  String get farmerSellProduceDesc =>
      'মধ্যস্বত্বভোগী ছাড়াই পাইকারি ক্রেতাদের কাছে সরাসরি ফসল বিক্রি করুন।';

  @override
  String get farmerPestAiDocDesc =>
      'রোগ বা পোকার ছবি তুলে সঙ্গে সঙ্গে AI প্রতিকার পান।';

  @override
  String get farmerGovtSchemesDesc =>
      'পিএম-কিষাণ এবং ফসল বিমা প্রকল্প সম্পর্কে জানুন।';

  @override
  String get farmerAgriDroneDesc =>
      'স্প্রে করার জন্য প্রত্যয়িত কৃষি ড্রোন পাইলট বুক করুন।';

  @override
  String get farmerIrrigationAiDesc =>
      'আবহাওয়া এবং মাটির আর্দ্রতার উপর ভিত্তি করে স্মার্ট সেচ পরিকল্পনা।';

  @override
  String get farmerHomeTitle => 'কৃষক হোম';

  @override
  String get farmerSimulateRainDev => 'বৃষ্টির পূর্বাভাস সিমুলেশন (Dev)';

  @override
  String get farmerFailedLoadMandi => 'মান্ডি দর লোড করতে ব্যর্থ হয়েছে';

  @override
  String get farmerHighDemand => 'উচ্চ চাহিদা';

  @override
  String get farmerStable => 'স্থিতিশীল';

  @override
  String get farmerFrpGuaranteed => 'FRP নিশ্চিত';

  @override
  String get farmerMspProtected => 'MSP সুরক্ষিত';

  @override
  String get farmerOversupply => 'অতিরিক্ত সরবরাহ';

  @override
  String get farmerModerate => 'মাঝারি';

  @override
  String get farmerProfileTitle => 'কৃষকের প্রোফাইল';

  @override
  String get verifiedFarmer => 'যাচাইকৃত কৃষক ✓';

  @override
  String get organicLand => 'জৈব জমি';

  @override
  String get soldThisMonth => 'এই মাসে বিক্রি';

  @override
  String get directSales => 'সরাসরি বিক্রয়';

  @override
  String get farmInfrastructureAndBadges => 'খামার পরিকাঠামো ও ফসলের ব্যাজ';

  @override
  String get soilClassification => 'মাটির শ্রেণীবিভাগ';

  @override
  String get primaryCrops => 'প্রধান ফসল';

  @override
  String get apmcRegistration => 'এপিএমসি নিবন্ধন';

  @override
  String get kisanCreditCard => 'কিসান ক্রেডিট কার্ড';

  @override
  String get zeroPesticideOrganicCertificate => 'কীটনাশকমুক্ত জৈব শংসাপত্র';

  @override
  String get verifiedByKarnatakaOrganicBoard =>
      'কর্ণাটক জৈব কৃষক বোর্ড দ্বারা যাচাইকৃত';

  @override
  String get validatedStatus => 'যাচাইকৃত ✓';

  @override
  String get underReviewStatus => 'পর্যালোচনাধীন';

  @override
  String get languageMode => 'ভাষা মোড';

  @override
  String get manageProduceListings => 'ফসলের তালিকা পরিচালনা করুন';

  @override
  String get produceListingsTitle => 'ফসলের তালিকা';

  @override
  String get addNewProduce => 'নতুন ফসল যোগ করুন';

  @override
  String get editProduceListing => 'ফসলের বিবরণ সম্পাদনা করুন';

  @override
  String get produceName => 'ফসলের নাম';

  @override
  String get category => 'বিভাগ';

  @override
  String pricePerUnit(String unit) {
    return 'প্রতি $unit মূল্য';
  }

  @override
  String get stockQuantity => 'মজুত পরিমাণ';

  @override
  String get unit => 'একক';

  @override
  String get harvestDate => 'ফসল কাটার তারিখ';

  @override
  String get qualityNotes => 'গুণমানের বিবরণ';

  @override
  String get farmingMethod => 'চাষের পদ্ধতি';

  @override
  String get deliveryAvailable => 'ডেলিভারি উপলব্ধ';

  @override
  String get pickupAvailable => 'খামার থেকে পিকআপ উপলব্ধ';

  @override
  String get availabilityMode => 'প্রাপ্যতা মোড';

  @override
  String get sameDayDelivery => 'একই দিনে ডেলিভারি';

  @override
  String get nextDayDelivery => 'পরের দিন ডেলিভারি';

  @override
  String get harvestPreOrder => 'ফসল প্রাক-অর্ডার';

  @override
  String get farmerSetsFinalPrice => 'কৃষক সর্বদা চূড়ান্ত মূল্য নির্ধারণ করে';

  @override
  String get statusLowStock => 'কম স্টক';

  @override
  String get statusSoldOut => 'শেষ হয়ে গেছে';

  @override
  String get statusPaused => 'স্থগিত';

  @override
  String get pauseListing => 'স্থগিত করুন';

  @override
  String get activateListing => 'সক্রিয় করুন';

  @override
  String get updateStock => 'স্টক আপডেট করুন';

  @override
  String stockInStock(String stock) {
    return '$stock স্টকে আছে';
  }

  @override
  String get buyerProduceMarket => 'তাজা খামারের ফসল';

  @override
  String get buyerSearchProduceHint =>
      'তাজা খামারের ফসল অনুসন্ধান করুন (যেমন টমেটো, চাল)...';

  @override
  String get noProduceAvailable => 'কোনো ফসল উপলব্ধ নেই';

  @override
  String get orderDirect => 'সরাসরি অর্ডার করুন';

  @override
  String get uploadProducePhotos => 'ফসলের ছবি (produce-images)';

  @override
  String get addPhoto => 'ছবি যোগ করুন';
}
