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
  String walletBalance(Object balance) {
    return 'Wallet Balance: ₹$balance';
  }

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
}
