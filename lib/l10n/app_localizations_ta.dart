// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'உத்யோகசேது';

  @override
  String get taglinePart1 => 'வேலை இணைப்பு.';

  @override
  String get taglinePart2 => 'வாழ்க்கை மேம்பாடு.';

  @override
  String get splashInitializing => 'உத்யோகசேது தொடங்குகிறது...';

  @override
  String get chipAiMatching => 'AI பொருத்தம்';

  @override
  String get chipSecure => 'பாதுகாப்பானது';

  @override
  String get chipVerified => 'சரிபார்க்கப்பட்டது';

  @override
  String versionLabel(Object version) {
    return 'பதிப்பு $version';
  }

  @override
  String get introSkip => 'தவிர்';

  @override
  String get introHeadline =>
      'இந்தியாவிற்காக உருவாக்கப்பட்டது. ஒவ்வொரு தொழிலாளிக்கும்.';

  @override
  String get introSubtitle =>
      'அருகிலுள்ள வேலைகளைக் கண்டறியவும், திறன்களை வளர்க்கவும், சிறப்பாகச் சம்பாதிக்கவும்.';

  @override
  String get introFeature1Title => 'அருகிலுள்ள வேலைகளைக் கண்டறியவும்';

  @override
  String get introFeature2Title => 'பாதுகாப்பான கொடுப்பனவுகள்';

  @override
  String get introFeature3Title => 'AI குரல் உதவியாளர்';

  @override
  String get introNext => 'அடுத்து ->';

  @override
  String get introGetStarted => 'தொடங்கு ->';

  @override
  String get languageScreenTitle => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get languageScreenSubtitle =>
      'நாங்கள் அனைத்தையும் உங்கள் மொழியில் காண்பிப்போம்';

  @override
  String listenToWelcomeIn(Object language) {
    return '$language மொழியில் வரவேற்பைக் கேட்கவும்';
  }

  @override
  String ttsVoiceMissingHint(Object language) {
    return '$language குரல் எஞ்சின் இல்லை. குரல் அமைப்புகளைத் திறக்க தட்டவும்.';
  }

  @override
  String get welcomeSpeechSentence =>
      'உத்யோகசேதுவிற்கு நல்வரவு. வேலையை இணைத்து வாழ்க்கையை வளப்படுத்துகிறோம்.';

  @override
  String get continueButton => 'தொடரவும் ->';

  @override
  String get save => 'சேமிக்க';

  @override
  String get cancel => 'ரத்துசெய்';

  @override
  String get back => 'பின்னால்';

  @override
  String get retry => 'மீண்டும் முயற்சி செய்';

  @override
  String get apply => 'விண்ணப்பிக்கவும்';

  @override
  String get submit => 'சமர்ப்பிக்கவும்';

  @override
  String get search => 'தேடுக';

  @override
  String get filter => 'வடிகட்டி';

  @override
  String get edit => 'திருத்து';

  @override
  String get delete => 'அழி';

  @override
  String get confirm => 'உறுதிசெய்';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navJobs => 'வேலைகள்';

  @override
  String get navMessages => 'செய்திகள்';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String get navWorkers => 'தொழிலாளர்கள்';

  @override
  String get navMarketplace => 'சந்தை';

  @override
  String get navMandi => 'மண்டி';

  @override
  String get navWallet => 'வாலட்';

  @override
  String get navSettings => 'அமைப்புகள்';

  @override
  String get navSafety => 'பாதுகாப்பு';

  @override
  String get statusAvailable => 'கிடைக்கிறது';

  @override
  String get statusBusy => 'வேலையில் உள்ளார்';

  @override
  String get statusOffline => 'ஆஃப்லைன்';

  @override
  String get statusVerified => 'சரிபார்க்கப்பட்டது';

  @override
  String get statusPending => 'நிலுவையில் உள்ளது';

  @override
  String get statusNotStarted => 'தொடங்கப்படவில்லை';

  @override
  String get statusRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get statusReviewRequired => 'ஆய்வு தேவை';

  @override
  String get statusActive => 'செயலில் உள்ளது';

  @override
  String get statusCompleted => 'முடிந்தது';

  @override
  String get statusCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get statusInProgress => 'செயல்பாட்டில் உள்ளது';

  @override
  String get roleSeeker => 'வேலை தேடுபவர்';

  @override
  String get roleProvider => 'வேலை அளிப்பவர்';

  @override
  String get roleFarmer => 'விவசாயி';

  @override
  String get roleAdmin => 'நிர்வாகி';

  @override
  String get seekerTypeInformal => 'முறைசாரா தொழிலாளி';

  @override
  String get seekerTypeStudent => 'மாணவர்';

  @override
  String get seekerTypePartTime => 'பகுதிநேர தொழிலாளி';

  @override
  String get providerTypeHousehold => 'வீட்டு உபயோகம்';

  @override
  String get providerTypeEmployer => 'வணிகம் / முதலாளி';

  @override
  String get docTypeAadhaar => 'ஆதார் கார்டு';

  @override
  String get docTypePan => 'பான் கார்டு';

  @override
  String get docTypeDrivingLicence => 'ஓட்டுநர் உரிமம்';

  @override
  String get docTypeBankAccount => 'வங்கி கணக்கு / யுபிஐ';

  @override
  String get phoneNumber => 'தொலைபேசி எண்';

  @override
  String get enterPhone => 'உங்கள் 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்';

  @override
  String get otpCode => 'OTP குறியீடு';

  @override
  String enterOtp(Object phone) {
    return '$phone க்கு அனுப்பப்பட்ட 6 இலக்க OTP ஐ உள்ளிடவும்';
  }

  @override
  String get fullName => 'முழு பெயர்';

  @override
  String get enterName => 'உங்கள் முழு பெயரை உள்ளிடவும்';

  @override
  String get city => 'நகரம்';

  @override
  String get pincode => 'பின்கோடு';

  @override
  String get requiredField => 'இந்த புலம் கட்டாயமாகும்';

  @override
  String get invalidPhone => 'சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்';

  @override
  String get invalidOtp => 'சரியான 6 இலக்க OTP ஐ உள்ளிடவும்';

  @override
  String get errorNetworkOffline => 'இணைய இணைப்பு இல்லை.';

  @override
  String get errorTimeout => 'நேரம் முடிந்தது.';

  @override
  String get errorAuthGeneral => 'அனுமதி தோல்வியடைந்தது.';

  @override
  String get errorDatabase => 'தரவுத்தள பிழை ஏற்பட்டது.';

  @override
  String get errorUnknown => 'எதிர்பாராத பிழை ஏற்பட்டது.';

  @override
  String get errorEdgeFunction => 'சேவை கோரிக்கை தோல்வியடைந்தது.';

  @override
  String amountRupees(Object amount) {
    return '₹$amount';
  }

  @override
  String wagePerDay(Object amount) {
    return '₹$amount/நாள்';
  }

  @override
  String wagePerHour(Object amount) {
    return '₹$amount/மணிநேரம்';
  }

  @override
  String get wageTypeDaily => 'தினசரி கூலி';

  @override
  String get wageTypeHourly => 'மணிநேர கூலி';

  @override
  String get wageTypeFixed => 'நிலையான கட்டணம்';

  @override
  String get walletBalance => 'வாலட் இருப்பு';

  @override
  String jobsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count வேலைகள் கிடைத்தன',
      one: '1 வேலை கிடைத்தது',
      zero: 'வேலைகள் எதுவும் கிடைக்கவில்லை',
    );
    return '$_temp0';
  }

  @override
  String applicantsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count விண்ணப்பதாரர்கள்',
      one: '1 விண்ணப்பதாரர்',
      zero: 'விண்ணப்பதாரர்கள் இல்லை',
    );
    return '$_temp0';
  }

  @override
  String distanceKm(Object distance) {
    return '$distance கி.மீ தொலைவில்';
  }

  @override
  String get todayGoal => 'இன்றைய இலக்கு';

  @override
  String get activeJobs => 'செயலில் உள்ள வேலைகள்';

  @override
  String get recentActivity => 'சமீபத்திய நடவடிக்கைகள்';

  @override
  String get viewAll => 'அனைத்தையும் பார்';

  @override
  String get roleTreeTitleStep1 => 'நீங்கள் யார்?';

  @override
  String get roleTreeSubtitleStep1 =>
      'தொடங்க உங்கள் கணக்கு வகையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get roleTreeTitleStep2 => 'நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்?';

  @override
  String get roleTreeSubtitleStep2 =>
      'உத்யோகசேதுவில் உங்கள் பங்கைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get roleTreeTitleStep3 => 'உங்களைப் பற்றி கூறுங்கள்';

  @override
  String get roleTreeSubtitleStep3 =>
      'உங்கள் நேரத்திற்கு ஏற்ற வேலை வகையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get roleCategoryWorker => 'பணியாளர் / தொழிலாளி';

  @override
  String get roleCategoryWorkerDesc =>
      'தினசரி கூலி வேலை, பகுதி நேர வேலைகளைக் கண்டறியவும் அல்லது பணியாளர்களை நியமிக்கவும்';

  @override
  String get roleCategoryFarmer => 'விவசாயி';

  @override
  String get roleCategoryFarmerDesc =>
      'தரகர்கள் இன்றி நேரடியாக பயிர்களை விற்கவும்';

  @override
  String get roleSeekerTitle => 'வேலை தேடுபவர்';

  @override
  String get roleSeekerDesc =>
      'தினசரி கூலி மற்றும் பகுதி நேர வேலைகள் மற்றும் உடனடி கட்டணம் பெறவும்';

  @override
  String get roleProviderTitle => 'வேலை வழங்குபவர்';

  @override
  String get roleProviderDesc =>
      'வேலைகளைப் பதிவிடவும், சரிபார்க்கப்பட்ட பணியாளர்களை நியமிக்கவும்';

  @override
  String get seekerTypeInformalTitle => 'அமைப்பசாரா / தினசரி கூலி தொழிலாளி';

  @override
  String get seekerTypeInformalDesc =>
      'கட்டுமானம், டெலிவரி, பிளம்பிங் வேலைகள் மற்றும் உடனடி யுபிஐ கட்டணம் பெறவும்';

  @override
  String get seekerTypeStudentTitle => 'மாணவர்';

  @override
  String get seekerTypeStudentDesc => 'படிப்பு நேரத்துடன் பகுதி நேர வேலைகள்';

  @override
  String get seekerTypePartTimeTitle => 'பகுதி நேர / ஃப்ளெக்சிபிள் தொழிலாளி';

  @override
  String get seekerTypePartTimeDesc =>
      'ஃப்ளெக்சிபிள் தினசரி அல்லது வார இறுதி ஷிப்டுகள்';

  @override
  String get alreadyHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா?';

  @override
  String get loginLink => 'லாகின் செய்யவும்';

  @override
  String listenToStepOptions(Object language) {
    return '$language இல் விருப்பங்களைக் கேட்கவும்';
  }

  @override
  String get breadcrumbWorker => 'தொழிலாளி';

  @override
  String get breadcrumbSeeker => 'தொழிலாளி > வேலை தேடுபவர்';

  @override
  String get loginTitle => 'மொபைல் எண் லாகின்';

  @override
  String get loginSubtitle =>
      'உடனடி SMS லாகினுக்கு 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்.';

  @override
  String get phoneInputLabel => 'மொபைல் போன் எண்';

  @override
  String get phonePrefix => 'IN +91';

  @override
  String get getOtpCode => 'SMS OTP சரிபார்ப்பு குறியீட்டைப் பெறவும்';

  @override
  String get agreeTermsDisclaimer =>
      'சேவை விதிமுறைகள் மற்றும் தனியுரிமைக் கொள்கையை ஏற்கிறேன்';

  @override
  String get continueWithGoogle => 'Google மூலம் தொடரவும்';

  @override
  String get googleSignInNotice => 'Google லாகின் அடுத்த கட்டத்தில் இயங்கும்';

  @override
  String get otpTitle => 'சரிபார்ப்பு குறியீட்டை உள்ளிடவும்';

  @override
  String otpSubtitle(Object maskedPhone) {
    return '+91 $maskedPhone க்கு அனுப்பப்பட்ட 6 இலக்க OTP ஐ உள்ளிடவும்';
  }

  @override
  String get verifyAndLogin => 'சரிபார்த்து லாகின் செய்யவும்';

  @override
  String resendCodeIn(Object seconds) {
    return '$seconds வினாடிகளில் குறியீட்டை மீண்டும் அனுப்பவும்';
  }

  @override
  String get resendCode => 'குறியீட்டை மீண்டும் அனுப்பு';

  @override
  String get maxResendsReached =>
      'இந்த அமர்வுக்கு அதிகபட்சம் 3 முறை மீண்டும் அனுப்பப்பட்டுள்ளது.';

  @override
  String get changeNumber => 'எண்ணை மாற்றவும்';

  @override
  String get invalidOtpError =>
      'தவறான அல்லது காலாவதியான OTP. 6 இலக்க குறியீட்டை சரிபார்க்கவும்.';

  @override
  String get rateLimitError =>
      'அதிகமான OTP கோரிக்கைகள். சிறிது நேரம் கழித்து முயற்சிக்கவும்.';

  @override
  String get termsRequiredError => 'தொடர சேவை விதிமுறைகளை ஏற்கவும்.';

  @override
  String get googleSignInFailed =>
      'Google உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get googleEmailAlreadyLinked =>
      'இந்த மின்னஞ்சல் ஏற்கனவே வேறொரு கைபேசி எண்ணுடன் இணைக்கப்பட்டுள்ளது.';

  @override
  String get verifyPhoneTitle => 'உங்கள் கைபேசி எண்ணை உறுதிப்படுத்தவும்';

  @override
  String get verifyPhoneSubtitle =>
      'பதிவை முடிக்க சரிபார்க்கப்பட்ட கைபேசி எண்ணைச் சேர்க்கவும்.';

  @override
  String get linkGoogleAccount => 'Google கணக்கை இணைக்கவும்';

  @override
  String get googleAccountLinked => 'Google கணக்கு வெற்றிகரமாக இணைக்கப்பட்டது.';

  @override
  String get googlePlayServicesMissing =>
      'இந்தச் சாதனத்தில் Google Play சேவைகள் இல்லை.';

  @override
  String wizardStepProgress(Object current, Object total) {
    return 'படி $current / $total';
  }

  @override
  String get wizardStep1Title => 'அடிப்படை விவரங்கள்';

  @override
  String get wizardStep1Subtitle =>
      'உங்கள் பெயர், புகைப்படம், பாலினம் மற்றும் மொழிகளை உள்ளிடவும்.';

  @override
  String get wizardStep2Title => 'திறன்கள் மற்றும் ஆர்வங்கள்';

  @override
  String get wizardStep2Subtitle =>
      'உங்கள் திறன்கள் அல்லது கல்வி ஆர்வங்களைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get wizardStep3Title => 'அனுபவம் மற்றும் கட்டணம்';

  @override
  String get wizardStep3Subtitle =>
      'உங்கள் அனுபவ ஆண்டுகள் மற்றும் எதிர்பார்க்கும் கட்டணத்தை அமைக்கவும்.';

  @override
  String get wizardStep4Title => 'கிடைக்கும் தன்மை';

  @override
  String get wizardStep4Subtitle =>
      'உங்கள் நிலை, வேலை நாட்கள் மற்றும் நேரங்களை அமைக்கவும்.';

  @override
  String get wizardStep5Title => 'இருப்பிடம்';

  @override
  String get wizardStep5Subtitle =>
      'இருப்பிட அனுமதியை வழங்கி உங்கள் சேவை ஆரையை அமைக்கவும்.';

  @override
  String get wizardStep6Title => 'சிறப்பு விவரங்கள்';

  @override
  String get wizardStep6Subtitle =>
      'உங்கள் தொழிலாளி சுயவிவர வகை விவரங்களை உள்ளிடவும்.';

  @override
  String get wizardStep7Title => 'சரிபார்த்து முடிக்கவும்';

  @override
  String get wizardStep7Subtitle =>
      'முடிக்கும் முன் உங்கள் சுயவிவர விவரங்களை சரிபார்க்கவும்.';

  @override
  String get takePhotoCamera => 'புகைப்படம் எடுக்கவும் (கேமரா)';

  @override
  String get chooseGallery => 'கேலரியில் இருந்து தேர்ந்தெடுக்கவும்';

  @override
  String get changePhoto => 'புகைப்படத்தை மாற்றவும்';

  @override
  String get uploadingPhoto => 'புகைப்படம் பதிவேற்றப்படுகிறது...';

  @override
  String get uploadPhotoError =>
      'புகைப்படப் பதிவேற்றம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்க தட்டவும்.';

  @override
  String get genderLabel => 'பாலினம் (விருப்பத்தேர்வு)';

  @override
  String get genderMale => 'ஆண்';

  @override
  String get genderFemale => 'பெண்';

  @override
  String get genderOther => 'இதர';

  @override
  String get genderPreferNot => 'கூற விரும்பவில்லை';

  @override
  String get languagesLabel => 'பேசும் மொழிகள்';

  @override
  String get selectCategories => 'வகைகளைத் தேர்ந்தெடுக்கவும்';

  @override
  String get selectSkills => 'திறன்களைத் தேர்ந்தெடுக்கவும்';

  @override
  String get informalSkillRequired =>
      'முறைசாரா தொழிலாளர்கள் குறைந்தபட்சம் 1 திறனையாவது தேர்ந்தெடுக்க வேண்டும்.';

  @override
  String get addSubjectOrInterest => 'பாடம் அல்லது ஆர்வத்தைச் சேர்க்கவும்';

  @override
  String get subjectsInterestsLabel => 'பாடங்கள் அல்லது ஆர்வங்கள்';

  @override
  String get experienceYearsLabel => 'அனுபவ ஆண்டுகள்';

  @override
  String get dailyRateLabel => 'எதிர்பார்க்கும் நாள் கட்டணம் (₹)';

  @override
  String get hourlyRateLabel => 'எதிர்பார்க்கும் மணி நேரக் கட்டணம் (₹)';

  @override
  String wageBandHint(Object max, Object min, Object unit) {
    return 'பரிந்துரைக்கப்பட்ட நியாயமான கூலி வரம்பு: ₹$min - ₹$max / $unit';
  }

  @override
  String get workingDaysLabel => 'வேலை நாட்கள்';

  @override
  String get workHoursLabel => 'வேலை நேரம்';

  @override
  String get studentWeeklyHoursLabel => 'விரும்பும் வாராந்திர மணிநேரம்';

  @override
  String get partTimeShiftLabel => 'விரும்பும் ஷிஃப்ட் நேரம்';

  @override
  String get shiftMorning => 'காலை ஷிஃப்ட் (காலை 6 - மதியம் 2)';

  @override
  String get shiftEvening => 'மாலை ஷிஃப்ட் (மதியம் 2 - இரவு 10)';

  @override
  String get shiftFlexible => 'நெகிழ்வான ஷிஃப்ட்';

  @override
  String get locationConsentTitle => 'தேவைப்படும்போது மட்டும் இருப்பிட அணுகல்';

  @override
  String get locationConsentText =>
      'உத்யோகசேது உங்கள் இருப்பிடத்தை அருகிலுள்ள வேலைகளுடன் பொருத்தவும் பாதுகாப்பிற்காகவும் பயன்படுத்துகிறது.';

  @override
  String get allowLocationAccess => 'இருப்பிட அணுகலை அனுமதிக்கவும்';

  @override
  String get locationPermissionDenied => 'இருப்பிட அனுமதி மறுக்கப்பட்டது.';

  @override
  String get addressLabel => 'வீட்டு முகவரி / பகுதி';

  @override
  String serviceRadiusLabel(Object radius) {
    return 'சேவை ஆரை: $radius கி.மீ';
  }

  @override
  String get collegeNameLabel => 'கல்லூரி / பல்கலைக்கழக பெயர்';

  @override
  String get courseNameLabel => 'பாடநெறி / பட்டம்';

  @override
  String get regNoLabel => 'பதிவு / USN எண்';

  @override
  String get doYouDriveToggle => 'நீங்கள் வாகனம் ஓட்டுகிறீர்களா?';

  @override
  String get drivingLicenceExplanation =>
      'குறிப்பு: ஓட்டுநர் மற்றும் விநியோக வேலைகளுக்கு செல்லுபடியாகும் ஓட்டுநர் உரிமம் தேவைப்படும்.';

  @override
  String get reviewSummaryTitle => 'சுயவிவர சுருக்கம்';

  @override
  String get finishProfileButton =>
      'சுயவிவரத்தை முடித்து முகப்பிற்குச் செல்லவும்';

  @override
  String get verifyIdentityPrompt =>
      'அதிக சம்பள வேலைகளைப் பெற அடையாளச் சரிபார்ப்பை முடிக்கவும்!';

  @override
  String get quitAndResumeNotice =>
      'வரைவு தானாகவே சேமிக்கப்பட்டது. நீங்கள் எப்போது வேண்டுமானாலும் தொடரலாம்.';

  @override
  String get farmerWizardTitle => 'விவசாயி சுயவிவர அமைப்பு';

  @override
  String get farmerStep1Title => 'அடிப்படை விவரங்கள்';

  @override
  String get farmerStep1Subtitle =>
      'உங்கள் பெயர், புகைப்படம் மற்றும் பேசும் மொழிகளை உள்ளிடவும்.';

  @override
  String get farmerStep2Title => 'பண்ணை விவரங்கள்';

  @override
  String get farmerStep2Subtitle =>
      'பண்ணை பெயர், இடம், ஏக்கர், மண் வகை மற்றும் பயிர்களைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get farmerStep3Title => 'பதிவுகள் மற்றும் பேட்ஜ்கள்';

  @override
  String get farmerStep3Subtitle =>
      'பேட்ஜ்களைப் பெற அரசு பதிவுகள் மற்றும் சான்றிதழ்களைச் சேர்க்கவும்.';

  @override
  String get farmerStep4Title => 'விற்பனை விருப்பங்கள்';

  @override
  String get farmerStep4Subtitle =>
      'பிக்கப் கிடைக்கும் தன்மை, டெலிவரி ஆரம் மற்றும் நேரத்தை அமைக்கவும்.';

  @override
  String get farmerStep5Title => 'மதிப்பாய்வு செய்து முடிக்கவும்';

  @override
  String get farmerStep5Subtitle =>
      'முடிப்பதற்கு முன் உங்கள் விவசாயி சுயவிவர விவரங்களைச் சரிபார்க்கவும்.';

  @override
  String get farmNameLabel => 'பண்ணை பெயர்';

  @override
  String get farmNameHint => 'எ.கா. கிரீன் வேலி ஆர்கானிக் ஃபார்ம்';

  @override
  String get villageClusterLabel => 'கிராமம் / கிளஸ்டர் பெயர்';

  @override
  String get villageClusterHint => 'எ.கா. தேவநஹள்ளி, பெங்களூரு கிராமப்புறம்';

  @override
  String get farmLocationLabel => 'வரைபடத்தில் பண்ணை இடம்';

  @override
  String get acresLabel => 'பண்ணை பரப்பு (ஏக்கர்)';

  @override
  String get soilTypeLabel => 'மண் வகை';

  @override
  String get soilPhLabel => 'மண் pH (விருப்பத்தேர்வு)';

  @override
  String get primaryCropsLabel => 'முதன்மை பயிர்கள்';

  @override
  String get farmingMethodLabel => 'விவசாய முறை';

  @override
  String get methodOrganic => 'இயற்கை வழி (Organic)';

  @override
  String get methodNatural => 'இயற்கை (Natural)';

  @override
  String get methodConventional => 'பாரம்பரிய (Conventional)';

  @override
  String get apmcRegLabel => 'APMC பதிவு எண் (விருப்பத்தேர்வு)';

  @override
  String get apmcRegHint => 'எ.கா. APMC-KA-2024-889';

  @override
  String get kccStatusLabel => 'கிசான் கிரெடிட் கார்டு (KCC) நிலை';

  @override
  String get kccNone => 'விண்ணப்பிக்கவில்லை';

  @override
  String get kccApplied => 'விண்ணப்பிக்கப்பட்டது';

  @override
  String get kccApproved => 'அனுமதிக்கப்பட்டது / செயலில் உள்ளது';

  @override
  String get organicCertLabel =>
      'இயற்கைச் சான்றிதழ் பதிவேற்றம் (விருப்பத்தேர்வு)';

  @override
  String get organicCertHelper =>
      'பதிவேற்றப்பட்ட கோப்புகள் பாதுகாப்பான தனியார் சேமிப்பகத்தில் சேமிக்கப்படும்.';

  @override
  String get farmBadgesTitle => 'பண்ணை சுயவிவர பேட்ஜ்கள்';

  @override
  String get deliveryAvailableLabel => 'டெலிவரி வசதி உள்ளது';

  @override
  String get pickupAvailableLabel => 'பிக்கப் வசதி உள்ளது';

  @override
  String deliveryRadiusLabel(Object radius) {
    return 'டெலிவரி ஆரம்: $radius கி.மீ';
  }

  @override
  String get leadTimeLabel => 'வழக்கமான விநியோக நேரம்';

  @override
  String get apmcBadgeTitle => 'APMC பதிவு செய்யப்பட்டது';

  @override
  String get kccBadgeTitle => 'கிசான் கிரெடிட் கார்டு';

  @override
  String get organicBadgeTitle => 'இயற்கைச் சான்றிதழ் (பரிசீலனையில் உள்ளுது)';

  @override
  String get uploadCertButton =>
      'இயற்கைச் சான்றிதழைப் பதிவேற்றவும் (PDF / Photo)';

  @override
  String get certUploadedPending =>
      'சான்றிதழ் பதிவேற்றப்பட்டது (பரிசீலனையில் உள்ளது)';

  @override
  String get providerWizardTitle => 'வேலை வழங்குநர் அமைவு';

  @override
  String get providerStep1Title => 'அடிப்படை விவரங்கள்';

  @override
  String get providerStep1Subtitle =>
      'உங்கள் முழு பெயர், புகைப்படம் மற்றும் மொழிகளை உள்ளிடவும்.';

  @override
  String get providerStep2Title => 'வழங்குநர் வகை';

  @override
  String get providerStep2Subtitle =>
      'நீங்கள் வீட்டு உபயோகம் அல்லது முதலாளி/ஒப்பந்தக்காரராக தேர்வு செய்யவும்.';

  @override
  String get providerStep3HouseholdTitle => 'வீட்டு முகவரி & டெலிவரி';

  @override
  String get providerStep3HouseholdSubtitle =>
      'வீட்டு முகவரி மற்றும் டெலிவரி விருப்பங்களை அமைக்கவும்.';

  @override
  String get providerStep3EmployerTitle => 'நிறுவனம் & தள விவரங்கள்';

  @override
  String get providerStep3EmployerSubtitle =>
      'நிறுவனத்தின் பெயர், முதன்மை தள முகவரி மற்றும் பணியாளர் எண்ணிக்கையை உள்ளிடவும்.';

  @override
  String get providerStep4Title => 'அனுமதிகள் & சம்மதம்';

  @override
  String get providerStep4Subtitle =>
      'இருப்பிடம் மற்றும் அறிவிப்பு அனுமதிகளை மதிப்பாய்வு செய்யவும்.';

  @override
  String get providerStep5Title => 'மதிப்பாய்வு செய்து முடிக்கவும்';

  @override
  String get providerStep5Subtitle =>
      'முடிப்பதற்கு முன் சுயவிவர விவரங்களைச் சரிபார்க்கவும்.';

  @override
  String get doorstepAddressLabel => 'பிளாட் / கதவு எண் & தெரு';

  @override
  String get doorstepAddressHint => 'எ.கா. #402, சன்ஷைன் அபார்ட்மெண்ட்ஸ்';

  @override
  String get landmarkLabel => 'அடையாளம் (Landmark)';

  @override
  String get landmarkHint => 'எ.கா. மெட்ரோ நிலையம் அருகில்';

  @override
  String get deliveryInstructionsLabel => 'டெலிவரி விருப்பங்கள் & வழிமுறைகள்';

  @override
  String get deliveryInstructionsHint =>
      'எ.கா. கேட்டில் உள்ள செக்யூரிட்டியிடம் கொடுக்கவும்';

  @override
  String get gateCodeLabel => 'கேட் கோட் (விருப்பத்தேர்வு)';

  @override
  String get gateCodeHint => 'எ.கா. 1234';

  @override
  String get orgNameLabel => 'நிறுவனம் / வணிகப் பெயர்';

  @override
  String get orgNameHint => 'எ.கா. சேது கன்ஸ்ட்ரக்ஷன்';

  @override
  String get primarySiteAddressLabel => 'முதன்மை தள முகவரி';

  @override
  String get primarySiteAddressHint => 'எ.கா. சைட் 45, எலக்ட்ரானிக்ஸ் சிட்டி';

  @override
  String get categoriesHiringLabel => 'பணியமர்த்தும் வகைகள்';

  @override
  String get typicalCrewSizeLabel => 'தேவைப்படும் பணியாளர் எண்ணிக்கை';

  @override
  String crewSizeWorkers(Object count) {
    return '$count தொழிலாளர்கள்';
  }

  @override
  String get gpsConsentExplanation =>
      'தள முகவரி மற்றும் தொழிலாளர் இருப்பைக் காட்ட GPS இருப்பிடம் தேவை.';

  @override
  String get notificationsConsentExplanation =>
      'தொழிலாளர் விண்ணப்பங்கள் மற்றும் டெலிவரி தகவல்களைப் பெற அறிவிப்புகளை இயக்கவும்.';

  @override
  String get grantGpsPermission => 'இருப்பிட அனுமதி அளிக்கவும்';

  @override
  String get grantNotificationsPermission => 'அறிவிப்பு அனுமதி அளிக்கவும்';

  @override
  String get permissionGranted => 'அனுமதி அளிக்கப்பட்டது';

  @override
  String get providerHomeTitle => 'வழங்குநர் முகப்பு';

  @override
  String get roleConflictTitle => 'கணக்கு பங்கு முரண்பாடு';

  @override
  String roleConflictMessage(Object chosenRole, Object existingRole) {
    return 'இந்த எண் ஏற்கனவே $existingRole ஆக பதிவு செய்யப்பட்டுள்ளது. இதை நீங்கள் $chosenRole ஆக பயன்படுத்த முடியாது. வேறு பங்கைப் பயன்படுத்த, $existingRole ஆக உள்நுழைந்து, சுயவிவரம் > அமைப்புகள் > கணக்கை நீக்கு பகுதிக்குச் சென்று, புதிய கணக்கை உருவாக்கவும்.';
  }

  @override
  String roleConflictLoginAs(Object existingRole) {
    return '$existingRole ஆக உள்நுழைக';
  }

  @override
  String get roleConflictBack => 'பின்செல்க';

  @override
  String get privacyCentreTitle => 'தனியுரிமை மையம்';

  @override
  String get privacyCentreSubtitle =>
      'உங்கள் தரவு சம்மதங்கள் மற்றும் அனுமதிகளை நிர்வகிக்கவும்.';

  @override
  String get consentSheetTitle => 'தரவு செயலாக்க சம்மதம்';

  @override
  String get consentWhatCollected => 'என்ன சேகரிக்கப்படுகிறது';

  @override
  String get consentWhyCollected => 'ஏன் சேகரிக்கப்படுகிறது';

  @override
  String get consentHowLongKept => 'எவ்வளவு காலம் வைக்கப்படும்';

  @override
  String get consentWhoCanSee => 'யார் பார்க்கலாம்';

  @override
  String get consentHowToWithdraw => 'திரும்பப் பெறுவது எப்படி';

  @override
  String get consentAgreeButton => 'நான் ஒப்புக்கொள்கிறேன்';

  @override
  String get consentNotNowButton => 'இப்போது வேண்டாம்';

  @override
  String get consentGrantedStatus => 'சம்மதம் அளிக்கப்பட்டது';

  @override
  String get consentRevokedStatus =>
      'சம்மதம் அளிக்கப்படவில்லை / திரும்பப் பெறப்பட்டது';

  @override
  String get withdrawConsentButton => 'சம்மதத்தை திரும்பப் பெறுக';

  @override
  String get withdrawFaceConsentTitle =>
      'முக சரிபார்ப்பு சம்மதத்தை திரும்பப் பெறவா?';

  @override
  String get withdrawFaceConsentMessage =>
      'முக சம்மதத்தை திரும்பப் பெறுவது உங்கள் முக குறிப்பு தரவை நிரந்தரமாக நீக்கும்.';

  @override
  String get confirmWithdrawButton => 'திரும்பப் பெற்று தரவை நீக்கு';

  @override
  String get cancelButton => 'ரத்து செய்';

  @override
  String get profileTitle => 'என் சுயவிவரம்';

  @override
  String get termsAndPrivacyTitle => 'விதிகள் மற்றும் தனியுரிமைக் கொள்கை';

  @override
  String get termsDraftNotice =>
      'வரைவு - உண்மையான வெளியீட்டிற்கு முன் இதை சரிபார்க்கவும்';

  @override
  String get systemPermissionsTitle => 'அமைப்பின் அனுமதிகள்';

  @override
  String get openSystemSettings => 'ஆப் அமைப்புகளைத் திறக்கவும்';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get faceVerificationCheck => 'முக சரிபார்ப்பு சோதனை';

  @override
  String get faceCheckSubtext =>
      'முக நேரடி சரிபார்ப்பைப் பயன்படுத்தி உங்கள் அடையாளத்தைச் சரிபார்க்கவும்';

  @override
  String get faceMatchSuccess => 'முக அடையாளம் சரிபார்க்கப்பட்டது';

  @override
  String get faceMatchFailedTitle => 'முக பொருத்தம் தோல்வியடைந்தது';

  @override
  String get faceMatchFailedBody =>
      'நல்ல வெளிச்சத்தில் உங்கள் முகத்தை தெளிவாக வைத்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get manualReviewRequiredTitle =>
      '3 சரிபார்ப்பு முயற்சிகள் தோல்வியடைந்தன';

  @override
  String get manualReviewRequiredBody =>
      'உங்கள் முக சரிபார்ப்பு கைமுறை ஆய்வுக்கு அனுப்பப்பட்டுள்ளது. வரையறுக்கப்பட்ட அணுகலுடன் தொடரலாம்.';

  @override
  String get requestManualReview => 'கைமுறை ஆய்வைக் கோரவும்';

  @override
  String get retryVerification => 'மீண்டும் சரிபார்க்க முயற்சிக்கவும்';

  @override
  String get demoSimulatePass => 'டெமோ: வெற்றி பெற்ற சரிபார்ப்பு';

  @override
  String get demoSimulateFail => 'டெமோ: தோல்வியடைந்த சரிபார்ப்பு';

  @override
  String get seekerHomeTitle => 'வேலை தேடுபவர் முகப்பு';

  @override
  String get searchJobsPlaceholder => 'வேலைகள், சேவைகளைத் தேடுங்கள்...';

  @override
  String get todaysGoal => 'இன்றைய இலக்கு';

  @override
  String get viewWallet => 'வாலட்டைப் பார்க்கவும் >';

  @override
  String get locationSharingActive =>
      'பாதுகாப்பு கண்காணிப்புக்காக இருப்பிட பகிர்வு செயலில் உள்ளது';

  @override
  String get changeLocation => 'மாற்றவும் >';

  @override
  String get quickActionsHeader => 'விரைவு செயல்கள்';

  @override
  String get actionNearbyJobs => 'அருகிலுள்ள வேலைகள்';

  @override
  String get actionAiAssistant => 'AI உதவியாளர்';

  @override
  String get actionWallet => 'வாலட்';

  @override
  String get actionSafetyHub => 'பாதுகாப்பு மையம்';

  @override
  String get tagSponsored => 'விளம்பரம்';

  @override
  String get whyAmISeeingThis => 'இதை நான் ஏன் பார்க்கிறேன்?';

  @override
  String get recommendedForYou => 'உங்களுக்காக பரிந்துரைக்கப்படுகிறது';

  @override
  String get applyNow => 'இப்போதே விண்ணப்பிக்கவும்';

  @override
  String get applied => 'விண்ணப்பிக்கப்பட்டது ✓';

  @override
  String get noJobsNearYou => 'உங்கள் அருகில் இன்னும் வேலைகள் இல்லை';

  @override
  String get widenRadiusAction => 'தேடல் வரம்பை விரிவாக்கு';

  @override
  String get sosEmergencyPill => 'அவசர SOS';

  @override
  String get selectLocationArea => 'இருப்பிடப் பகுதியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get goodMorning => 'காலை வணக்கம்';

  @override
  String get goodAfternoon => 'மதிய வணக்கம்';

  @override
  String get goodEvening => 'மாலை வணக்கம்';

  @override
  String get studentsWelcomeChip => 'மாணவர்களுக்கு வரவேற்பு';

  @override
  String get flexibleShiftChip => 'நெகிழ்வான பணி நேரம்';

  @override
  String get nearbyJobsMapTitle =>
      'அருகிலுள்ள தினசரி கூலி வேலைகள் மற்றும் பணி தளங்கள்';

  @override
  String livePinsCount(Object count) {
    return '$count நேரடி ஊசிகள்';
  }

  @override
  String nearbyGpsPinListings(Object count) {
    return 'அருகிலுள்ள ஜிபிஎஸ் பின் பட்டியல்கள் ($count)';
  }

  @override
  String get tapPinOrCardToInspect => 'ஆராய பின் அல்லது கார்டைத் தட்டவும்';

  @override
  String get applyButton => 'விண்ணப்பிக்கவும்';

  @override
  String get categoryFilterAll => 'அனைத்தும்';

  @override
  String get recenterMap => 'ஜிபிஎஸ் மறுமையப்படுத்துக';

  @override
  String get zoomIn => 'பெரிதாக்கு';

  @override
  String get zoomOut => 'சிறிதாக்கு';

  @override
  String get gpsDisabledBanner =>
      'ஜிபிஎஸ் முடக்கப்பட்டுள்ளது. துல்லியமான தொலைவுக்கு இருப்பிடத்தை இயக்கவும்.';

  @override
  String get locationPermissionDeniedBanner =>
      'இருப்பிட அனுமதி வழங்கப்படவில்லை. இயல்புநிலை பகுதி காட்டப்படுகிறது.';

  @override
  String get noJobsInArea =>
      'இந்த ஆரத்திற்குள் எந்த பணித் தளமும் கிடைக்கவில்லை';

  @override
  String get searchRadius => 'தேடல் ஆரம்';

  @override
  String radiusKm(Object radius) {
    return '$radius கி.மீ';
  }

  @override
  String get openLocationSettings => 'அமைப்புகள்';

  @override
  String get loadJobsError =>
      'அருகிலுள்ள வேலைகளை ஏற்றுவதில் தோல்வி. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get retryAction => 'மீண்டும் முயற்சி';

  @override
  String get openStreetMapAttribution => '© OpenStreetMap contributors';

  @override
  String get cameraPermissionTitle => 'கேமரா அணுகல்';

  @override
  String get cameraPermissionSubtitle =>
      'முக சரிபார்ப்பு மற்றும் அடையாள ஸ்கேனிங்கிற்கு பயன்படுத்தப்படுகிறது.';

  @override
  String get locationPermissionTitle => 'சாதன இருப்பிடம் (ஜிபிஎஸ்)';

  @override
  String get locationPermissionSubtitle =>
      'அருகிலுள்ள வேலைகள், வரைபடம் மற்றும் வருகையைக் காட்ட பயன்படுகிறது.';

  @override
  String get notificationPermissionTitle => 'அறிவிப்புகள்';

  @override
  String get notificationPermissionSubtitle =>
      'வேலை எச்சரிக்கைகள், கட்டண மற்றும் பாதுகாப்பு புதுப்பிப்புகளுக்கு பயன்படுகிறது.';

  @override
  String get permissionAllowedStatus => 'அனுமதிக்கப்பட்டது';

  @override
  String get permissionBlockedStatus => 'தடுக்கப்பட்டது / ஆஃப்';

  @override
  String get refreshConsentsTooltip => 'நிலையைப் புதுப்பிக்கவும்';

  @override
  String get tabOverview => 'மேலோட்டம்';

  @override
  String get tabWorkShowcase => 'வேலை கண்காட்சி';

  @override
  String get tabSafetyStatus => 'பாதுகாப்பு நிலை';

  @override
  String get verifiedJobsStat => 'சரிபார்க்கப்பட்ட வேலைகள்';

  @override
  String get ratingStat => 'மதிப்பீடு';

  @override
  String get totalEarningsStat => 'மொத்த வருமானம்';

  @override
  String categoryPrefix(Object category) {
    return 'பிரிவு: $category';
  }

  @override
  String get roleCredentialsTitle => 'பணி சான்றுகள் & பிரிவு பேட்ஜ்கள்';

  @override
  String get changeCategoryBtn => 'பிரிவை மாற்றுக';

  @override
  String get changeCategoryTitle => 'தொழிலாளி பிரிவை மாற்றுக';

  @override
  String get changeCategorySubtitle =>
      'வேலைகள் மற்றும் சரிபார்ப்பை தனிப்பயனாக்க உங்கள் வேலை வகையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get categoryInformalTitle => 'முறைசாரா / திறமையான தொழிலாளி';

  @override
  String get categoryInformalDesc =>
      'கைவினைத் தொழில்கள், வீட்டுச் சேவைகள் மற்றும் விவசாயப் பணிகள்';

  @override
  String get categoryStudentTitle => 'மாணவர் கிக் தொழிலாளி';

  @override
  String get categoryStudentDesc =>
      'கேம்பஸ் கிக்ஸ், டியூஷன், வடிவமைப்பு & ஆன்லைன் பணிகள்';

  @override
  String get categoryPartTimeTitle => 'பகுதி நேரத் தொழிலாளி';

  @override
  String get categoryPartTimeDesc =>
      'சில்லறை வணிகம், உணவக சேவை, நெகிழ்வான ஷிப்டுகள்';

  @override
  String get mySkillsTitle => 'எனது திறன்கள்';

  @override
  String get addSkillBtn => '+ திறன் சேர்';

  @override
  String get addSkillDialogTitle => 'ஒரு திறனைத் தேர்ந்தெடுக்கவும்';

  @override
  String get addSkillDialogSubtitle =>
      'உங்கள் சுயவிவரத்திற்குப் பொருந்தும் திறன்களைத் தேர்வுசெய்க';

  @override
  String get languageAccessibilityTitle => 'மொழி & அணுகல்தன்மை';

  @override
  String get verificationStatusTitle => 'சரிபார்ப்பு நிலை';

  @override
  String get accountAndSafetyTitle => 'கணக்கு & பாதுகாப்பு';

  @override
  String get emptyShowcaseTitle =>
      'நீங்கள் முடித்த வேலைகள், புகைப்படங்கள் மற்றும் மதிப்பீடுகள் இங்கே தோன்றும்';

  @override
  String get emptyShowcaseSubtitle =>
      'உத்யோகசேது மூலம் வேலைகளை முடித்ததும், சரிபார்க்கப்பட்ட மதிப்புரைகள் மற்றும் வருவாய் இங்கே காட்சிப்படுத்தப்படும்.';

  @override
  String get browseJobsAction => 'வேலைகளை உலாவுக';

  @override
  String get safetyLifecycleTitle => 'பாதுகாப்பு ஆன்போர்டிங் & பேட்ஜ்கள்';

  @override
  String get notVerifiedYet => 'இன்னும் சரிபார்க்கப்படவில்லை';

  @override
  String get verifiedWorkerBadge => 'உத்யோகசேது சரிபார்க்கப்பட்டது ✓';

  @override
  String get dlVerified => 'ஓட்டுநர் உரிமம் சரிபார்க்கப்பட்டது ✓';

  @override
  String get dlPending => 'ஓட்டுநர் உரிமத்தைச் சேர்க்கவும்';

  @override
  String get studentBadgeVerified => 'மாணவர் நிலை சரிபார்க்கப்பட்டது ✓';

  @override
  String get studentBadgePending => 'மாணவர் நிலையைச் சரிபார்க்கவும்';

  @override
  String get bankUpiVerified => 'வங்கி / யுபிஐ இணைக்கப்பட்டுள்ளது ✓';

  @override
  String get bankUpiPending => 'வங்கி / யுபிஐ இணைக்கவும்';

  @override
  String get bgCheckVerified => 'பின்னணி சரிபார்ப்பு முடிந்தது ✓';

  @override
  String get bgCheckPending => 'பின்னணி சரிபார்ப்பு நிலுவையில் உள்ளது';

  @override
  String get aadhaarVerified => 'ஆதார் இ-கேஒய்சி சரிபார்க்கப்பட்டது ✓';

  @override
  String get faceLivenessVerified => 'முக பயோமெட்ரிக் சரிபார்க்கப்பட்டது ✓';

  @override
  String get safetyTrainingVerified =>
      '1-நாள் பாதுகாப்புப் பயிற்சி முடிந்தது ✓';

  @override
  String categoryUpdatedSnackbar(Object category) {
    return 'பிரிவு $category என புதுப்பிக்கப்பட்டது! ஊட்டமும் திறன்களும் புதுப்பிக்கப்பட்டன.';
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
  String get hubActionScanFarmQr => 'Scan Farm QR';

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
  String get bookingWizardTitle => 'நேரடி முன்பதிவு';

  @override
  String get bookingStepService => 'சேவை';

  @override
  String get bookingStepDateTime => 'தேதி & நேரம்';

  @override
  String get bookingStepAddress => 'முகவரி';

  @override
  String get bookingStepPayment => 'விலை & கட்டணம்';

  @override
  String get bookingStepNotice => 'அறிவிப்பு';

  @override
  String get bookingStepTicket => 'முன்பதிவு பாஸ்';

  @override
  String get bookingWorkerDetails => 'தொழிலாளர் விவரங்கள்';

  @override
  String get bookingServiceTitleLabel => 'சேவை தலைப்பு / விவரம்';

  @override
  String get bookingServiceTitleHint =>
      'எ.கா. வாழ்க்கை அறை விசிறி வயரிங் பழுது';

  @override
  String get bookingSpecialNotes => 'சிறப்பு வழிமுறைகள் / குறிப்புகள்';

  @override
  String get bookingSpecialNotesHint =>
      'எ.கா. கூடுதல் 2.5 மிமீ வயர் கொண்டு வாருங்கள், ஏணி உள்ளது';

  @override
  String get bookingDuration => 'மதிப்பிடப்பட்ட காலம்';

  @override
  String get bookingDurationHalfDay => 'அரை நாள் (4 மணி)';

  @override
  String get bookingDurationFullDay => 'முழு நாள் (8 மணி)';

  @override
  String bookingDurationCustom(int hours) {
    return 'தனிப்பயன் ($hours மணி)';
  }

  @override
  String get bookingSelectDate => 'தேதியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get bookingSelectTimeSlot => 'நேர ஸ்லாட்டைத் தேர்ந்தெடுக்கவும்';

  @override
  String get bookingSlotAvailable => 'கிடைக்கிறது';

  @override
  String get bookingSlotBooked => 'முன்பதிவு செய்யப்பட்டது';

  @override
  String get bookingScheduleConflictAlert =>
      'இந்த நேரத்தில் தொழிலாளி ஏற்கனவே பதிவு செய்யப்பட்டுள்ளார். வேறு நேரத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get bookingAddressTitle => 'சேவை இடம்';

  @override
  String get bookingSavedAddresses => 'சேமிக்கப்பட்ட முகவரிகள்';

  @override
  String get bookingAddNewAddress => 'புதிய முகவரியைச் சேர்க்கவும்';

  @override
  String get bookingAddressLabel => 'முகவரி லேபிள்';

  @override
  String get bookingAddressLine1 => 'வீட்டு எண் & தெரு';

  @override
  String get bookingLandmark => 'அடையாளம் (விருப்பமானது)';

  @override
  String get bookingCity => 'நகரம்';

  @override
  String get bookingPincode => 'பின்கோடு';

  @override
  String get bookingSaveAsDefault => 'இயல்புநிலை முகவரியாகச் சேமிக்கவும்';

  @override
  String get bookingPriceBreakdown => 'விலை விவரம்';

  @override
  String get bookingAgreedWage => 'ஒப்புக்கொள்ளப்பட்ட கூலி';

  @override
  String get bookingPlatformFee => 'தள வசதி கட்டணம்';

  @override
  String get bookingProtectionCoverFee => 'வேலை பாதுகாப்பு கவர்';

  @override
  String get bookingTotalPrice => 'மொத்தத் தொகை';

  @override
  String get bookingFairWageVerified => 'நியாயமான கூலி வரம்பிற்குள்';

  @override
  String get bookingFairWageBelow => 'நிலையான நியாயமான கூலியை விடக் குறைவு';

  @override
  String get bookingPaymentMethod => 'கட்டண முறை';

  @override
  String get bookingPaymentCash => 'பணி முடிந்ததும் பணம்';

  @override
  String get bookingPaymentUpi => 'உடனடி UPI';

  @override
  String get bookingPaymentEscrow =>
      'பாதுகாப்பான எஸ்க்ரோ (பரிந்துரைக்கப்படுகிறது)';

  @override
  String get bookingPaymentPlaceholder =>
      'கட்டண நுழைவாயில் ஒருங்கிணைப்பு (P5.2)';

  @override
  String get bookingRecurringOption => 'மீண்டும் நிகழும் சேவை அட்டவணை';

  @override
  String get bookingRecurringToggle =>
      'இதை வழக்கமான மீண்டும் நிகழும் சேவையாக்குங்கள்';

  @override
  String get bookingRecurringWeekly => 'வாராந்திர சுழற்சி';

  @override
  String get bookingRecurringMonthly => 'மாதாந்திர சுழற்சி';

  @override
  String get bookingUnverifiedNoticeTitle => 'உத்யோகசேது சரிபார்க்கப்படவில்லை';

  @override
  String get bookingUnverifiedNoticeSubtitle =>
      'இந்தத் தொழிலாளி உத்யோகசேது பயிற்சி மற்றும் சரிபார்ப்பை முடிக்கவில்லை.';

  @override
  String get bookingUnverifiedNoticeDesc =>
      'தொழிலாளியின் அடையாளம் பதிவு செய்யப்பட்டிருந்தாலும், அதிகாரப்பூர்வ நம்பிக்கை பேட்ஜை பெறவில்லை. முன்பதிவு முறையைத் தேர்ந்தெடுக்கவும்:';

  @override
  String get bookingProtectionCoverTitle =>
      '₹40 வேலை பாதுகாப்பு கவரைச் சேர்க்கவும்';

  @override
  String get bookingProtectionCoverDesc =>
      'விபத்து சொத்து சேத பாதுகாப்பு (₹10,000 வரை) மற்றும் சர்ச்சை தீர்வு ஆதரவு.';

  @override
  String get bookingBookWithoutProtection => 'பாதுகாப்பின்றி பதிவு செய்யவும்';

  @override
  String get bookingBookWithoutProtectionDesc =>
      'சொத்து சேத கவரேஜ் இல்லாமல் நேரடி ரொக்கம்/எஸ்க்ரோ விதிமுறைகளுடன் தொடரவும்.';

  @override
  String get bookingProceedToTicket =>
      'உறுதிசெய்து முன்பதிவு பாஸுக்குச் செல்லவும்';

  @override
  String get bookingTicketTitle => 'முன்பதிவு பாஸ் டிக்கெட்';

  @override
  String get bookingStatusWaiting => 'தொழிலாளருக்காக காத்திருக்கிறது';

  @override
  String get bookingCodeLabel => 'முன்பதிவு குறியீடு';

  @override
  String get bookingSuccessMessage =>
      'முன்பதிவு கோரிக்கை தொழிலாளிக்கு அனுப்பப்பட்டது. அவர்கள் ஏற்றுக்கொண்டதும் உங்களுக்குத் தகவல் கிடைக்கும்.';

  @override
  String get bookingViewMyJobs => 'எனது வேலைகளில் காண்க';

  @override
  String get bookingReturnHome => 'வாடிக்கையாளர் மையத்திற்குத் திரும்பு';

  @override
  String get recurringManageTitle => 'மீண்டும் நிகழும் சேவைகள்';

  @override
  String get recurringNoBookings =>
      'செயலில் உள்ள மீண்டும் நிகழும் முன்பதிவுகள் எதுவும் இல்லை.';

  @override
  String get recurringPause => 'அட்டவணையை இடைநிறுத்து';

  @override
  String get recurringResume => 'அட்டவணையை மீண்டும் தொடங்கு';

  @override
  String get recurringCancel => 'அட்டவணையை ரத்துசெய்';

  @override
  String get recurringSkipDate => 'அடுத்த தேதியைத் தவிர்க்கவும்';

  @override
  String get recurringDateSkipped =>
      'அடுத்த திட்டமிடப்பட்ட சேவை தவிர்க்கப்பட்டது.';

  @override
  String get recurringStatusActive => 'செயலில் உள்ளது';

  @override
  String get recurringStatusPaused => 'இடைநிறுத்தப்பட்டது';

  @override
  String get recurringStatusCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get demoModeBadge => 'டெமோ பயன்முறை';
}
