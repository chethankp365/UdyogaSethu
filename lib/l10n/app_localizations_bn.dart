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
}
