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
  String get farmNameLabel => 'பண்ணை / தோட்டத்தின் பெயர்';

  @override
  String get farmNameHint => 'எ.கா. கிரீன் வேலி ஆர்கானிக் ஃபார்ம்';

  @override
  String get villageClusterLabel => 'கிராமம் / கிளஸ்டர் பெயர்';

  @override
  String get villageClusterHint => 'எ.கா. தேவநஹள்ளி, பெங்களூரு கிராமப்புறம்';

  @override
  String get farmLocationLabel => 'வரைபடத்தில் பண்ணை இடம்';

  @override
  String get acresLabel => 'மொத்த நிலம் (ஏக்கர்)';

  @override
  String get soilTypeLabel => 'மண் வகைப்பாடு';

  @override
  String get soilPhLabel => 'மண் pH (விருப்பத்தேர்வு)';

  @override
  String get primaryCropsLabel => 'முக்கிய பயிர்கள்';

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
  String get kccApproved => 'KCC அங்கீகரிக்கப்பட்டது ✓';

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
  String get postJobStepAudience => 'இலக்கு தொழிலாளர்கள்';

  @override
  String get postJobAudienceTitle => 'இந்த வேலை யாருக்கானது?';

  @override
  String get postJobAudienceSubtitle =>
      'இந்த வேலையைப் பார்க்கவும் விண்ணப்பிக்கவும் பொருத்தமான தொழிலாளர் வகைகளைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get postJobAudienceInformal => 'தினக்கூலி / அமைப்புசாரா தொழிலாளி';

  @override
  String get postJobAudienceInformalHint =>
      'தினக்கூலிகள், கட்டுமானம், ஏற்றுதல், வீட்டு உதவியாளர்கள்';

  @override
  String get postJobAudienceStudent => 'மாணவர்';

  @override
  String get postJobAudienceStudentHint =>
      'மாலை அல்லது வார இறுதி குறுகிய பணிகளைத் தேடும் கல்லூரி மாணவர்கள்';

  @override
  String get postJobAudiencePartTime => 'பகுதி நேர / நெகிழ்வான தொழிலாளி';

  @override
  String get postJobAudiencePartTimeHint =>
      'குறைந்த நேர ஷிப்ட் அல்லது நெகிழ்வான வேலை நேரத்தை விரும்பும் தொழிலாளர்கள்';

  @override
  String get postJobAudienceRequired =>
      'குறைந்தது ஒரு தொழிலாளர் வகையையாவது தேர்ந்தெடுக்கவும்';

  @override
  String get hubConfirmedBookingEmptyTitle => 'செயலில் உள்ள முன்பதிவுகள் இல்லை';

  @override
  String get hubConfirmedBookingEmptyDesc =>
      'உறுதிசெய்யப்பட்ட தொழிலாளர் பணிகள் மற்றும் கண்காணிப்பு இங்கே தோன்றும்.';

  @override
  String get hubLocationNotSet => 'இடம் அமைக்கப்படவில்லை';

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
  String get hubActionScanQr => 'QR-ஐ ஸ்கேன் செய்';

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

  @override
  String get timelineTitle => 'வேலை முன்னேற்ற காலக்கோடு';

  @override
  String get timelineLiveDot => 'நேரலை';

  @override
  String get timelineDisputeActive => 'சர்ச்சை பரிசீலனையில் உள்ளது';

  @override
  String get timelineDisputeSub => 'மத்தியஸ்த குழு ஆதாரங்களை ஆய்வு செய்கிறது.';

  @override
  String get timelineCurrentBadge => 'தற்போதைய';

  @override
  String get stageRequestCreated => 'கோரிக்கை உருவாக்கப்பட்டது';

  @override
  String get stageAccepted => 'ஏற்றுக்கொள்ளப்பட்டது';

  @override
  String get stageTicketIssued => 'டிக்கெட் வழங்கப்பட்டது';

  @override
  String get stageWorkerArrived => 'பணியாளர் வந்துவிட்டார்';

  @override
  String get stageVerificationCompleted => 'சரிபார்ப்பு முடிந்தது';

  @override
  String get stageJobInProgress => 'வேலை நடைபெறுகிறது';

  @override
  String get stageCompleted => 'முடிந்தது';

  @override
  String get stagePaymentReleased => 'பணம் விடுவிக்கப்பட்டது';

  @override
  String get stageDisputeRaised => 'சர்ச்சை எழுப்பப்பட்டது';

  @override
  String get activeJobTitle => 'செயலில் உள்ள வேலை முன்னேற்றம்';

  @override
  String get actionAcceptJob => 'வேலையை ஏற்றுக்கொள்';

  @override
  String get actionWorkerArrived => 'நான் வந்துவிட்டேன்';

  @override
  String get actionStartWork => 'வேலையைத் தொடங்கு';

  @override
  String get actionCompleteJob => 'வேலையை முடி';

  @override
  String get actionAwaitingPayment => 'பணம் விடுவிப்பிற்காக காத்திருக்கிறது';

  @override
  String get actionJobFinished => 'வேலை முழுமையாக முடிந்தது';

  @override
  String get actionDisputeMediation => 'சர்ச்சை ஆய்வில் உள்ளது';

  @override
  String get actionWaitingAcceptance => 'பணியாளர் ஏற்புக்காக காத்திருக்கிறது';

  @override
  String get actionConfirmArrival => 'வருகையை உறுதிப்படுத்து';

  @override
  String get actionConfirmCompletion => 'வேலை முடிவை உறுதிப்படுத்து';

  @override
  String get actionReleasePayment => 'பணத்தை விடுவி';

  @override
  String get actionPaymentDone => 'பணம் செலுத்தப்பட்டது';

  @override
  String get actionAskForHelp => 'உதவி கேளுங்கள்';

  @override
  String get actionDispute => 'சர்ச்சையை எழுப்பு';

  @override
  String get simpleModeSpokenLabel => 'பேசவும் இயக்கவும் தட்டவும்';

  @override
  String get routeAndEtaTitle => 'பாதை மற்றும் பயண நேரம்';

  @override
  String get openInMapsBtn => 'வரைபடத்தில் திற';

  @override
  String get demoModeChip => 'டெமோ பயன்முறை';

  @override
  String get scheduleTitle => 'பணியாளர் அட்டவணை மற்றும் பயணம்';

  @override
  String get scheduleDayView => 'நாள்';

  @override
  String get scheduleWeekView => 'வாரம்';

  @override
  String get scheduleWeeklyTotal => 'வாரத்தின் மதிப்பிடப்பட்ட வருமானம்';

  @override
  String get ticketScreenTitle => 'டிஜிட்டல் வேலை டிக்கெட்';

  @override
  String get refreshTicketTooltip => 'டிக்கெட் QR-ஐ புதுப்பிக்கவும்';

  @override
  String get ticketOfflineNotice =>
      'பாதுகாப்பு டோக்கனை புதுப்பிக்க இணைய இணைப்பு தேவை. முதலாளி ஸ்கேன் செய்வதற்கு முன் இணைக்கவும்.';

  @override
  String get ticketBookingPassHeader => 'முன்பதிவு பாஸ்';

  @override
  String get ticketScanInstructions =>
      'பணிக்கு வந்தவுடன் இந்த QR பாஸை உங்கள் முதலாளியிடம் காட்டவும்';

  @override
  String get ticketAutoRefreshesIn => 'புதுப்பிக்கப்படும்';

  @override
  String get ticketReplayShieldTitle =>
      'மறுபயன்பாட்டு பாதுகாப்பு இயக்கப்பட்டது';

  @override
  String get ticketReplayShieldBody =>
      'இந்த பாதுகாப்பு பாஸ் ஒரு முறை மட்டுமே செல்லுபடியாகும், மேலும் ஒவ்வொரு 2 நிமிடங்களுக்கும் மாறும். ஸ்கிரீன்ஷாட்களை மீண்டும் பயன்படுத்த முடியாது.';

  @override
  String get attendanceScannerTitle => 'பணியாளர் QR-ஐ ஸ்கேன் செய்யவும்';

  @override
  String get attendanceScannerInstructions =>
      'வருகையை பதிவு செய்ய பணியாளரின் டிஜிட்டல் டிக்கெட் QR குறியீட்டை சட்டத்திற்குள் வைக்கவும்.';

  @override
  String get ticketReplayRefusedTitle => 'மறுபயன்பாடு நிராகரிக்கப்பட்டது';

  @override
  String get ticketExpiredTitle => 'டிக்கெட் காலாவதியானது';

  @override
  String get attendanceScanFailedTitle => 'வருகை ஸ்கேன் தோல்வியடைந்தது';

  @override
  String get attendanceConfirmedTitle => 'வருகை உறுதி செய்யப்பட்டது!';

  @override
  String get workerMarkedArrived =>
      'பணியாளர் பணி இடத்திற்கு வந்துவிட்டதாக குறிக்கப்பட்டது';

  @override
  String get scanAgain => 'மீண்டும் ஸ்கேன் செய்';

  @override
  String get scanDone => 'முடிந்தது';

  @override
  String get viewActiveJob => 'செயலில் உள்ள வேலையைப் பார்க்கவும்';

  @override
  String get actionShowTicket => 'QR டிக்கெட்டை காட்டவும்';

  @override
  String get actionScanWorkerQr => 'பணியாளர் QR-ஐ ஸ்கேன் செய்யவும்';

  @override
  String get openSettings => 'அமைப்புகளைத் திறக்கவும்';

  @override
  String get bookingCodeCopied => 'முன்பதிவு குறியீடு நகலெடுக்கப்பட்டது';

  @override
  String get verifyYourPresence => 'உங்கள் இருப்பை சரிபார்க்கவும்';

  @override
  String get verifyPresenceSubtitle =>
      'தொடங்குவதற்கு முன் முக பொருத்தம் மற்றும் தள புவி எல்லை சரிபார்ப்பு தேவை';

  @override
  String get gpsPerimeterCheck => 'ஜிபிஎஸ் பணித்தள புவி எல்லை சரிபார்ப்பு';

  @override
  String get withinPerimeter => 'பணித்தள எல்லைக்குள் உள்ளது';

  @override
  String get outsidePerimeter => 'பணித்தள எல்லைக்கு வெளியே உள்ளது';

  @override
  String distanceFromSite(String distance, String radius) {
    return 'தளத்திலிருந்து தூரம்: $distanceமீ (அனுமதிக்கப்பட்டது: $radiusமீ)';
  }

  @override
  String get mockLocationDetected =>
      'போலி ஜிபிஎஸ் கண்டறியப்பட்டது. வேலை தொடங்குவது மறுக்கப்பட்டு மதிப்பாய்வுக்காக பதிவு செய்யப்பட்டது.';

  @override
  String get faceSelfieCheck => 'முன் கேமரா முக சரிபார்ப்பு';

  @override
  String get takeSelfieBtn => 'சரிபார்ப்பு செல்ஃபி எடுக்கவும்';

  @override
  String get retakeSelfieBtn => 'மீண்டும் செல்ஃபி எடுக்கவும்';

  @override
  String get verifyAndStartJob => 'இருப்பை சரிபார்த்து வேலையைத் தொடங்கவும்';

  @override
  String get verificationFailed => 'சரிபார்ப்பு மறுக்கப்பட்டது';

  @override
  String outOfGeofenceMessage(String distance, String radius) {
    return 'நீங்கள் பணித்தளத்திலிருந்து $distanceமீ தொலைவில் உள்ளீர்கள். தொடங்க $radiusமீ எல்லைக்குள் இருக்க வேண்டும்.';
  }

  @override
  String get getHelpOrSupport => 'உதவி பெறவும்';

  @override
  String get completionTitle => 'பணி நிறைவு மற்றும் சான்றுகள்';

  @override
  String get completionSubtitle =>
      'நிறைவை சரிபார்க்க செல்ஃபி மற்றும் பணி புகைப்படங்களை சமர்ப்பிக்கவும்';

  @override
  String get workResultPhotos => 'பணி ஆதார புகைப்படங்கள் (தனியார்)';

  @override
  String get addWorkPhoto => 'புகைப்படம் சேர்க்கவும்';

  @override
  String get completeAndSubmit => 'நிறைவை சமர்ப்பித்து டைமரை நிறுத்தவும்';

  @override
  String get midJobCheckTitle => 'இடைக்கால பணி சரிபார்ப்பு தேவை';

  @override
  String get midJobCheckSubtitle =>
      'உயர் மதிப்பு பணி பாதுகாப்பு சரிபார்ப்பு (ஊதியம் >= ₹2,000)';

  @override
  String get midJobConfirmSelfie => 'இடைக்கால செல்ஃபி எடுக்கவும்';

  @override
  String get midJobCustomerConfirm =>
      'பணியாளர் தளத்தில் இருப்பதை உறுதிப்படுத்தவும்';

  @override
  String get timerTitle => 'நேரடி வேலை டைமர்';

  @override
  String get timerRunning => 'டைமர் இயங்குகிறது';

  @override
  String get timerPaused => 'டைமர் இடைநிறுத்தப்பட்டுள்ளது';

  @override
  String get elapsedTime => 'கடந்த நேரம்';

  @override
  String get smartNoShowEngineHeader => 'ஸ்மார்ட் நோ-ஷோ மீட்பு என்ஜின்';

  @override
  String get arrivalGraceExpiredAlert => '⚠️ வருகை சலுகைக் காலம் முடிந்தது';

  @override
  String get workerHasNotArrivedTitle => 'பணியாளர் வரவில்லை';

  @override
  String workerHasNotArrivedSubtitle(
    String workerName,
    int minutesLate,
    String jobTitle,
  ) {
    return '$workerName $jobTitle பணிக்காக திட்டமிடப்பட்ட நேரத்தை விட $minutesLate நிமிடங்கள் தாமதமாக உள்ளார்.';
  }

  @override
  String get wait10MinutesAction => '10 நிமிடங்கள் காத்திருங்கள்';

  @override
  String get callWorkerDirectlyAction => '📞 பணியாளரை நேரடியாக அழைக்கவும்';

  @override
  String get findSmartReplacementAction =>
      '⚡ ஸ்மார்ட் மாற்றுப் பணியாளரைக் கண்டறியவும்';

  @override
  String get gracePeriodExtendedMsg =>
      '+10 நிமிடங்கள் காத்திருப்பு சலுகை சேர்க்கப்பட்டது. டைமர் இடைநிறுத்தப்பட்டது.';

  @override
  String get maskedCallDemoMsg =>
      'அழைக்கப்படுகிறது... (டெமோ பயன்முறை: முகமூடி அழைப்பு P7.2 இல் வரும்)';

  @override
  String replacementBookedMsg(String workerName) {
    return '$workerName உடன் மாற்றுப் பணியாளர் புக் செய்யப்பட்டார்! முந்தையவர் வரவில்லை எனக் குறிக்கப்பட்டது.';
  }

  @override
  String get rankedReplacementsTitle =>
      'வரிசைப்படுத்தப்பட்ட அருகிலுள்ள பணியாளர்கள்';

  @override
  String get noReplacementsFoundMsg =>
      'தற்போது அருகில் மாற்றுப் பணியாளர்கள் யாரும் கிடைக்கவில்லை.';

  @override
  String get requestReplacementOneTap =>
      'மாற்றுப் பணியாளரைக் கோருங்கள் (1-தட்டல்)';

  @override
  String get smartNoShowTrustNote =>
      'நோ-ஷோ ஏற்பட்டால் முழு பணத்தைத் திரும்பப் பெறுதல். மாற்றுப் பணியாளர்கள் சரிபார்க்கப்பட்டவர்கள்.';

  @override
  String get openRecoveryEngineAction => 'நோ-ஷோ மீட்பு என்ஜினைத் திறக்கவும்';

  @override
  String get runningLateQuestionAction => 'தாமதமாகிறதா? ETA பகிர தட்டவும்';

  @override
  String runningLateReportedBadge(int minutes) {
    return 'தாமதம் தெரிவிக்கப்பட்டது (+$minutesநி). டைமர் இடைநிறுத்தப்பட்டது.';
  }

  @override
  String get runningLateDialogTitle => 'தாமதமாகிறதா?';

  @override
  String get runningLateDialogSubtitle =>
      'உங்கள் எதிர்பார்க்கப்படும் தாமதத்தைத் தேர்ந்தெடுக்கவும். இது முதலாளிக்குத் தெரிவிக்கும் மற்றும் டைமரை ஒருமுறை இடைநிறுத்தும்.';

  @override
  String get sendEtaAction => 'ETA அனுப்பவும்';

  @override
  String runningLateSuccessMsg(int minutes) {
    return '+$minutes நிமிடங்கள் தாமதம் தெரிவிக்கப்பட்டது. முதலாளிக்கு அறிவிக்கப்பட்டது.';
  }

  @override
  String get jobHistoryTitle => 'பணி வரலாறு மற்றும் மதிப்பீடுகள்';

  @override
  String get jobHistoryHeader => 'பணி வரலாறு';

  @override
  String get favouritesTitle => 'விருப்பமானவை மற்றும் நம்பிக்கை வட்டங்கள்';

  @override
  String get rateJobTitle => 'வேலைக்கு மதிப்பீடு மற்றும் கருத்து வழங்கவும்';

  @override
  String get quickTagsLabel => 'விரைவு குறிச்சொற்கள்';

  @override
  String get reviewCommentLabel => 'கருத்து மற்றும் மதிப்புரை (விருப்பமானது)';

  @override
  String get reviewCommentHint =>
      'சமூகத்திற்கு உதவ உங்கள் அனுபவத்தைப் பகிரவும்...';

  @override
  String get submitReviewBtn =>
      'சரிபார்க்கப்பட்ட மதிப்புரையைச் சமர்ப்பிக்கவும்';

  @override
  String get reportDisputeTitle => 'வேலை சர்ச்சையைப் புகாரளிக்கவும்';

  @override
  String get disputeFreezeNotice =>
      'சர்ச்சையைப் பதிவு செய்வது எஸ்க்ரோ கட்டண வெளியீட்டை நிறுத்தி வைக்கும்.';

  @override
  String get disputeIssueTypeLabel => 'பிரச்சனை வகையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get disputeDetailsLabel => 'பிரச்சனை விவரங்கள் மற்றும் காலவரிசை';

  @override
  String get disputeDetailsHint =>
      'என்ன நடந்தது என்பதைத் தெளிவாக விளக்கவும்...';

  @override
  String get disputeEvidenceLabel => 'ஆதாரப் புகைப்படங்கள் (விருப்பமானது)';

  @override
  String get submitDisputeBtn => 'முறையான சர்ச்சையைப் பதிவு செய்யவும்';

  @override
  String get disputeTypeNoShow => 'வரவில்லை / வருகை இல்லை';

  @override
  String get disputeTypeIncompleteWork =>
      'முழுமையடையாத வேலை / முன்கூட்டியே சென்றார்';

  @override
  String get disputeTypePoorQuality => 'மோசமான தரமான வேலை';

  @override
  String get disputeTypeWrongProduct => 'தவறான தயாரிப்பு / தரப் பொருந்தாமை';

  @override
  String get disputeTypePaymentIssue =>
      'பணம் செலுத்துவதில் பிரச்சனை / எஸ்க்ரோ சர்ச்சை';

  @override
  String get disputeTypeUnsafeConduct => 'பாதுகாப்பற்ற நடத்தை';

  @override
  String get disputeTypeVerificationProblem =>
      'சரிபார்ப்பு / அடையாளப் பொருந்தாமை';

  @override
  String get disputeTrackingTitle => 'சர்ச்சை நிலை கண்காணிப்பு';

  @override
  String get settingsSectionHeader => 'அமைப்புகள்';

  @override
  String get filterAll => 'அனைத்தும்';

  @override
  String get filterCompleted => 'முடிந்தது';

  @override
  String get filterDisputed => 'சர்ச்சைக்குரியது';

  @override
  String get filterInProgress => 'செயலில் உள்ளது';

  @override
  String get filterCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get walletTitle => 'வாலட் மற்றும் எஸ்க்ரோ';

  @override
  String get walletBalanceHeader => 'வாலட் இருப்பு';

  @override
  String get escrowProtected => 'எஸ்க்ரோ பாதுகாப்பானது';

  @override
  String get todaysReleased => 'இன்றைய வெளியீடு';

  @override
  String get pendingEscrow => 'நிலுவையில் உள்ள எஸ்க்ரோ';

  @override
  String get withdrawAction => 'திரும்பப் பெறு';

  @override
  String get scanUpiQr => 'UPI QR ஐ ஸ்கேன் செய்யவும்';

  @override
  String get recentTransactions => 'சமீபத்திய பரிவர்த்தனைகள்';

  @override
  String get withdrawEarningsTitle => 'வருமானத்தை திரும்பப் பெறுக';

  @override
  String get demoWithdrawNote =>
      'டெமோ பயன்முறை: வங்கி கூட்டாளர் கிடைக்கும் வரை உருவகப்படுத்தப்பட்ட பேஅவுட் லெட்ஜர் டெபிட்.';

  @override
  String get transferToUpi => 'பரிமாற்றம் (UPI VPA / வங்கி)';

  @override
  String get confirmPayoutWithdrawal => 'திரும்பப் பெறுவதை உறுதிப்படுத்தவும்';

  @override
  String get demoPayoutCompleted => 'டெமோ கட்டணம் முடிந்தது';

  @override
  String get demoUpiScanner => 'டெமோ பயன்முறை: உருவகப்படுத்தப்பட்ட UPI ஸ்கேனர்';

  @override
  String get demoUpiNote =>
      'உண்மையான பணம் மாற்றப்படாது. பேமெண்ட் ரெயில்கள் கட்டம் 5.2 இல் இணையும்.';

  @override
  String get noTransactionsFound => 'பரிவர்த்தனைகள் எதுவும் இல்லை';

  @override
  String get noTransactionsSubtitle =>
      'முடிக்கப்பட்ட தினசரி ஊதியம் மற்றும் இடமாற்றங்கள் இங்கே தோன்றும்.';

  @override
  String get paymentTitle => 'பணம் செலுத்துதல் & எஸ்க்ரோ பாதுகாப்பு';

  @override
  String get paymentBillSummary => 'பில் சுருக்கம்';

  @override
  String get paymentServiceWage => 'சேவை / கூலித் தொகை';

  @override
  String get paymentPlatformFee => 'தளக் கட்டணம் & ஜிஎஸ்டி';

  @override
  String get paymentProtectionAddon => 'பாதுகாப்பு கூடுதல் திட்டம்';

  @override
  String get paymentTotalPayable => 'மொத்தம் செலுத்த வேண்டியது';

  @override
  String get paymentEscrowNotice =>
      'சரிபார்க்கப்பட்ட பணி முடியும் வரை பாதுகாக்கப்பட்டது. பணம் பாதுகாப்பான எஸ்க்ரோவில் வைக்கப்பட்டுள்ளது.';

  @override
  String get paymentChooseMethod =>
      'பணம் செலுத்தும் முறையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get paymentUpi => 'யுபிஐ (GPay / PhonePe / Paytm)';

  @override
  String get paymentCard => 'கிரெடிட் / டெபிட் கார்டு';

  @override
  String get paymentWallet => 'உத்யோகசேது வாலட்';

  @override
  String get paymentCash => 'வேலை முடிந்ததும் ரொக்கம்';

  @override
  String get paymentPaySecurely => 'பாதுகாப்பாக பணம் செலுத்துங்கள்';

  @override
  String get paymentConfirmCash => 'ரொக்க முன்பதிவை உறுதிப்படுத்தவும்';

  @override
  String get paymentStatus => 'பணம் செலுத்திய நிலை';

  @override
  String get paymentSuccessful =>
      'பணம் செலுத்துதல் வெற்றிகரமாக முடிந்தது & உறுதி செய்யப்பட்டது';

  @override
  String get paymentSuccessSubtitle =>
      'உங்கள் கட்டணம் உறுதி செய்யப்பட்டு எஸ்க்ரோவில் பாதுகாக்கப்பட்டுள்ளது.';

  @override
  String get paymentConfirmingBank => 'வங்கியுடன் உறுதி செய்யப்படுகிறது...';

  @override
  String get paymentConfirmingSubtitle =>
      'ரேஸர்பே மற்றும் வங்கி நெட்வொர்க்கிலிருந்து உறுதிப்படுத்தலுக்காக காத்திருக்கிறது. திரை தானாகவே புதுப்பிக்கப்படும்.';

  @override
  String get paymentFailed => 'பணம் செலுத்துதல் தோல்வியடைந்தது';

  @override
  String get paymentFailedSubtitle =>
      'வங்கியால் உங்கள் பரிவர்த்தனையை முடிக்க முடியவில்லை. பணம் கழிக்கப்படவில்லை.';

  @override
  String get paymentReceiptNo => 'ரசீது எண்';

  @override
  String get paymentDownloadPdf => 'PDF ரசீதைப் பகிரவும் / பதிவிறக்கவும்';

  @override
  String get paymentContinueJob => 'வேலை / ஆர்டருக்கு தொடரவும்';

  @override
  String get paymentTryAgain => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get pendingEscrowRelease => 'எஸ்க்ரோ வெளியீடு நிலுவையில் உள்ளது';

  @override
  String get protectedBadge => 'பாதுகாக்கப்பட்டது';

  @override
  String get releaseEscrowPayment => 'எஸ்க்ரோ கட்டணத்தை விடுவிக்கவும்';

  @override
  String get confirmAndRelease => 'உறுதிசெய்து பணம் விடுவிக்கவும்';

  @override
  String get workerPayout => 'தொழிலாளி கட்டணம் (இருப்பு தொகை)';

  @override
  String get escrowAutoReleaseNotice =>
      'முதலாளி உறுதிசெய்தவுடன் அல்லது எந்த தகராறும் இல்லாவிட்டால் 24 மணி நேரத்திற்குள் பணம் தானாக விடுவிக்கப்படும்.';

  @override
  String get escrowEarningsSecured =>
      'உங்கள் வருமானம் எஸ்க்ரோவில் 100% பாதுகாப்பானது';

  @override
  String get releaseEscrowSuccess =>
      'தொழிலாளி வாலட்டுக்கு பணம் வெற்றிகரமாக விடுவிக்கப்பட்டது!';

  @override
  String get earningsDashboardTitle => 'வருமானம் மற்றும் செயல்திறன்';

  @override
  String get earningsToday => 'இன்றைய வருமானம்';

  @override
  String get earningsThisWeek => 'இந்த வாரம்';

  @override
  String get earningsThisMonth => 'இந்த மாதம்';

  @override
  String get earningsTotal => 'மொத்த வருமானம்';

  @override
  String get earningsCompletedJobs => 'முடிக்கப்பட்ட வேலைகள்';

  @override
  String get earningsFarmOrders => 'விவசாய ஆர்டர்கள்';

  @override
  String get earningsAverageRating => 'சராசரி மதிப்பீடு';

  @override
  String get earningsDailyGoal => 'தினசரி இலக்கு';

  @override
  String get earningsDailyGoalProgress => 'இன்றைய இலக்கு முன்னேற்றம்';

  @override
  String get earningsPayoutTrends => 'பணம் செலுத்தும் போக்கு';

  @override
  String get earningsTimeframe14Days => '14 நாட்கள்';

  @override
  String get earningsTimeframe6Months => '6 மாதங்கள்';

  @override
  String get earningsBestDayTitle => 'சிறந்த வருவாய் நாள்';

  @override
  String earningsBestDaySubtitle(Object amount, Object date) {
    return '$date அன்று நீங்கள் $amount சம்பாதித்துள்ளீர்கள்!';
  }

  @override
  String get earningsSetDailyGoal => 'தினசரி இலக்கை அமைக்கவும்';

  @override
  String get earningsSaveGoal => 'இலக்கைச் சேமிக்கவும்';

  @override
  String get savingsGoalsTitle => 'சேமிப்பு இலக்கு திட்டமிடுபவர்';

  @override
  String get savingsGoalsSubtitle =>
      'உங்கள் கனவுகளைத் திட்டமிடுங்கள். இலக்குகள் உங்கள் பணத்தைப் பூட்டாது.';

  @override
  String get savingsGoalsVirtualNotice =>
      'மெய்நிகர் இலக்கு டிராக்கர்: இலக்குகள் திட்டமிடலுக்கு மட்டுமே. உங்கள் பணம் எப்போதும் உங்கள் வாலட்டில் கிடைக்கும்.';

  @override
  String get savingsGoalNew => 'புதிய சேமிப்பு இலக்கு';

  @override
  String get savingsGoalCreate => 'இலக்கை உருவாக்கவும்';

  @override
  String get savingsGoalTarget => 'இலக்கு தொகை';

  @override
  String get savingsGoalSaved => 'இதுவரை சேமிக்கப்பட்டது';

  @override
  String get savingsGoalDeadline => 'இலக்கு தேதி';

  @override
  String get savingsGoalCategory => 'வகை';

  @override
  String get savingsGoalSuggestedPlan =>
      'பரிந்துரைக்கப்பட்ட சேமிப்புத் திட்டம்';

  @override
  String get savingsGoalAddSavings => 'சேமிப்பு முன்னேற்றத்தைப் பதிவுசெய்க';

  @override
  String get savingsGoalAddAmount => 'சேமித்த தொகை';

  @override
  String get savingsGoalCompletedBadge => 'இலக்கு அடையப்பட்டது! 🎉';

  @override
  String get savingsGoalActiveBadge => 'செயலில் உள்ளது';

  @override
  String get savingsGoalCategorySchoolFees => 'பள்ளி கட்டணம்';

  @override
  String get savingsGoalCategoryEquipment => 'வேலைக் கருவிகள்';

  @override
  String get savingsGoalCategoryScooter => 'ஸ்கூட்டர் / வாகனம்';

  @override
  String get savingsGoalCategorySeeds => 'விதைகள் & உரங்கள்';

  @override
  String get savingsGoalCategoryEmergency => 'அவசர நிதி';

  @override
  String get savingsGoalCategoryHome => 'வீடு சீரமைப்பு';

  @override
  String get savingsGoalCategoryCustom => 'தனிப்பயன் இலக்கு';

  @override
  String get savingsGoalDelete => 'இலக்கை நீக்கு';

  @override
  String get savingsGoalDeleteConfirm =>
      'இந்த சேமிப்பு இலக்கை நிச்சயமாக நீக்க விரும்புகிறீர்களா?';

  @override
  String get savingsGoalEmptyState =>
      'சேமிப்பு இலக்கை அமைத்து உங்கள் அடுத்த மைல்கல்லைத் திட்டமிடுங்கள்.';

  @override
  String get savingsGoalsPlanGoals => 'இலக்குகளைத் திட்டமிடுங்கள்';

  @override
  String get farmerWorkspace => 'விவசாயி பணியிடம்';

  @override
  String get farmerEmpoweredNetwork => 'உத்யோகசேது நேரடி வேளாண் கட்டமைப்பு';

  @override
  String get farmerProduceSold => 'விற்பனையான விளைச்சல்';

  @override
  String get farmerThisMonth => 'இந்த மாதம்';

  @override
  String get farmerDirectEarnings => 'நேரடி வருவாய்';

  @override
  String get farmerZeroMiddlemen => 'இடைத்தரகர் இல்லை';

  @override
  String get farmerActiveLabor => 'தொழிலாளர்கள்';

  @override
  String get farmerHarvestShiftPlaceholder => 'அறுவடை ஷிப்ட் (P6.3)';

  @override
  String farmerBooked(int count) {
    return '$count முன்பதிவு';
  }

  @override
  String get farmerWeatherAdvisoryRadar => 'வானிலை ஆலோசனை ரேடார்';

  @override
  String get farmerSimulatedForecast => 'மாதிரி கணிப்பு';

  @override
  String farmerRainProbability(int percent) {
    return '$percent% மழை வாய்ப்பு';
  }

  @override
  String get farmerBookHarvestHelpers => 'அறுவடை தொழிலாளர்களை புக் செய்யவும்';

  @override
  String get farmerViewIrrigationGuide =>
      'நீர்ப்பாசன வழிகாட்டியைப் பார்க்கவும்';

  @override
  String get farmerLiveMandiPrices => 'நேரடி மண்டி விலை & தேவை';

  @override
  String get farmerLiveFeed => 'நேரலை ஃபீட்';

  @override
  String get farmerAllCrops => 'அனைத்துப் பயிர்கள்';

  @override
  String get farmerVegetables => 'காய்கறிகள்';

  @override
  String get farmerGrainsAndPulses => 'தானியங்கள் & பருப்புகள்';

  @override
  String get farmerNoPricesInCategory => 'இப்பிரிவில் மண்டி விலைகள் இல்லை';

  @override
  String get farmerSelectAllCropsHint =>
      'கர்நாடக APMC விலைகளைப் பார்க்க அனைத்துப் பயிர்களையும் தேர்ந்தெடுக்கவும்.';

  @override
  String farmerUpdatedDate(String date) {
    return 'புதுப்பிக்கப்பட்டது $date';
  }

  @override
  String get farmerApmcKarnatakaFeed => 'கர்நாடக APMC ஃபீட்';

  @override
  String get farmerEssentialSuite => 'விவசாயியின் அத்தியாவசிய சேவைகள்';

  @override
  String get farmerRentTractor => 'டிராக்டர் வாடகை';

  @override
  String get farmerHireWorkers => 'தொழிலாளர்களை நியமிக்கவும்';

  @override
  String get farmerSoilAiTest => 'மண் AI பரிசோதனை';

  @override
  String get farmerSellProduce => 'விளைச்சல் விற்பனை';

  @override
  String get farmerPestAiDoc => 'பூச்சி AI மருத்துவர்';

  @override
  String get farmerGovtSchemes => 'அரசுத் திட்டங்கள்';

  @override
  String get farmerAgriDrone => 'வேளாண் ட்ரோன்';

  @override
  String get farmerIrrigationAi => 'நீர்ப்பாசன AI';

  @override
  String farmerComingInPhase(String phase) {
    return '$phase இல் வரும்';
  }

  @override
  String get farmerUnderstood => 'புரிந்தது';

  @override
  String get farmerGotIt => 'சரி';

  @override
  String get farmerHireWorkersDesc =>
      'விவசாயிகள் அறுவடைத் தேவைகளைப் பதிவிட்டு அருகிலுள்ள தொழிலாளர்களை நேரடியாக நியமிக்கலாம்.';

  @override
  String get farmerRentTractorDesc =>
      'டிராக்டர் மற்றும் அறுவடை இயந்திரங்களை எளிதாக வாடகைக்கு எடுக்கவும்.';

  @override
  String get farmerSoilAiTestDesc =>
      'மண் பரிசோதனை புகைப்படத்தை பதிவேற்றி AI உர பரிந்துரைகளைப் பெறவும்.';

  @override
  String get farmerSellProduceDesc =>
      'இடைத்தரகர்கள் இன்றி விளைபொருட்களை மொத்த வியாபாரிகளுக்கு விற்கவும்.';

  @override
  String get farmerPestAiDocDesc =>
      'பூச்சித் தாக்குதலை படம் பிடித்து உடனடி AI தீர்வுகளைப் பெறவும்.';

  @override
  String get farmerGovtSchemesDesc =>
      'பிஎம்-கிசான் மற்றும் பயிர் காப்பீட்டுத் திட்டங்களை அறியவும்.';

  @override
  String get farmerAgriDroneDesc =>
      'உர தெளிப்புக்கு வேளாண் ட்ரோன் பைலட்டுகளை புக் செய்யவும்.';

  @override
  String get farmerIrrigationAiDesc =>
      'மண் ஈரப்பதத்திற்கு ஏற்ப ஸ்மார்ட் பாசன அட்டவணை.';

  @override
  String get farmerHomeTitle => 'விவசாயி முகப்பு';

  @override
  String get farmerSimulateRainDev => 'மழை கணிப்பு மாதிரி (Dev)';

  @override
  String get farmerFailedLoadMandi => 'மண்டி விலைகளை ஏற்றுவதில் தோல்வி';

  @override
  String get farmerHighDemand => 'அதிக தேவை';

  @override
  String get farmerStable => 'நிலையானது';

  @override
  String get farmerFrpGuaranteed => 'FRP உத்தரவாதம்';

  @override
  String get farmerMspProtected => 'MSP பாதுகாப்பானது';

  @override
  String get farmerOversupply => 'அதிக வரத்து';

  @override
  String get farmerModerate => 'மிதமான';

  @override
  String get farmerProfileTitle => 'விவசாயி சுயவிவரம்';

  @override
  String get verifiedFarmer => 'சரிபார்க்கப்பட்ட விவசாயி ✓';

  @override
  String get organicLand => 'இயற்கை விவசாய நிலம்';

  @override
  String get soldThisMonth => 'இந்த மாதம் விற்பனையானது';

  @override
  String get directSales => 'நேரடி விற்பனை';

  @override
  String get farmInfrastructureAndBadges =>
      'பண்ணை உள்கட்டமைப்பு & பயிர் பேட்ஜ்கள்';

  @override
  String get soilClassification => 'மண் வகைப்பாடு';

  @override
  String get primaryCrops => 'முக்கிய பயிர்கள்';

  @override
  String get apmcRegistration => 'APMC பதிவு';

  @override
  String get kisanCreditCard => 'கிசான் கடன் அட்டை';

  @override
  String get zeroPesticideOrganicCertificate =>
      'பூச்சிக்கொல்லி இல்லாத இயற்கை சான்றிதழ்';

  @override
  String get verifiedByKarnatakaOrganicBoard =>
      'கர்நாடக இயற்கை விவசாயிகள் வாரியத்தால் சரிபார்க்கப்பட்டது';

  @override
  String get validatedStatus => 'சரிபார்க்கப்பட்டது ✓';

  @override
  String get underReviewStatus => 'மதிப்பாய்வில் உள்ளது';

  @override
  String get languageMode => 'மொழி முறை';

  @override
  String get manageProduceListings => 'விளைபொருட்கள் பட்டியலை நிர்வகி';

  @override
  String get produceListingsTitle => 'விளைபொருட்கள் பட்டியல்';

  @override
  String get addNewProduce => 'புதிய விளைபொருள் சேர்';

  @override
  String get editProduceListing => 'விளைபொருள் விவரத்தை திருத்து';

  @override
  String get produceName => 'விளைபொருள் பெயர்';

  @override
  String get category => 'வகை';

  @override
  String pricePerUnit(String unit) {
    return '$unit விலை';
  }

  @override
  String get stockQuantity => 'இருப்பு அளவு';

  @override
  String get unit => 'அலகு';

  @override
  String get harvestDate => 'அறுவடை தேதி';

  @override
  String get qualityNotes => 'தரக் குறிப்புகள்';

  @override
  String get farmingMethod => 'விவசாய முறை';

  @override
  String get deliveryAvailable => 'டெலிவரி உள்ளது';

  @override
  String get pickupAvailable => 'பண்ணை வாயில் பிக்அப் உள்ளது';

  @override
  String get availabilityMode => 'கிடைக்கும் முறை';

  @override
  String get sameDayDelivery => 'அன்றைய தின டெலிவரி';

  @override
  String get nextDayDelivery => 'மறுநாள் டெலிவரி';

  @override
  String get harvestPreOrder => 'முன்பதிவு';

  @override
  String get farmerSetsFinalPrice => 'விவசாயியே இறுதி விலையை நிர்ணயிக்கிறார்';

  @override
  String get statusLowStock => 'குறைந்த இருப்பு';

  @override
  String get statusSoldOut => 'விற்றுத் தீர்ந்தது';

  @override
  String get statusPaused => 'நிறுத்தப்பட்டது';

  @override
  String get pauseListing => 'நிறுத்து';

  @override
  String get activateListing => 'இயக்கு';

  @override
  String get updateStock => 'இருப்பை புதுப்பி';

  @override
  String stockInStock(String stock) {
    return '$stock இருப்பு உள்ளது';
  }

  @override
  String get buyerProduceMarket => 'புதிய பண்ணை விளைபொருட்கள்';

  @override
  String get buyerSearchProduceHint =>
      'விளைபொருட்களைத் தேடுங்கள் (எ.கா. தக்காளி, அரிசி)...';

  @override
  String get noProduceAvailable => 'விளைபொருட்கள் எதுவும் கிடைக்கவில்லை';

  @override
  String get orderDirect => 'நேரடியாக ஆர்டர் செய்';

  @override
  String get uploadProducePhotos => 'பயிர் புகைப்படங்கள் (produce-images)';

  @override
  String get addPhoto => 'புகைப்படம் சேர்க்க';

  @override
  String get farmerMapHeader =>
      'விவசாயிகளுக்கு தேவையான பொருட்கள், விதைகள், இயந்திரங்கள் மற்றும் சேவைகள்';

  @override
  String get farmerNearbyRentals =>
      'அருகிலுள்ள இயந்திரங்கள் மற்றும் ட்ரோன் வாடகை';

  @override
  String get farmerEscrowGuaranteed => 'எஸ்க்ரோ உத்தரவாதம்';

  @override
  String get farmerBookNow => 'இப்போது முன்பதிவு செய்க';

  @override
  String get farmerBookItem => 'பொருளை முன்பதிவு செய்க';

  @override
  String get farmerViewAllEquipmentMap =>
      'அனைத்து பண்ணை வளங்கள் & நேரடி வரைபடத்தைக் காண்க →';

  @override
  String get farmerEquipmentBooked => 'இயந்திரம் முன்பதிவு செய்யப்பட்டது!';

  @override
  String get farmerBookingQuantity => 'முன்பதிவு காலம் / அளவு';

  @override
  String get farmerDeliveryAddress => 'பண்ணை விநியோகம் / வேலை தள முகவரி';

  @override
  String get farmerSpecialNotes =>
      'பணி வழிமுறைகள் / பயிர் குறிப்புகள் (விருப்பத்தேர்வு)';

  @override
  String get farmerVendorHubTitle => 'இயந்திர விற்பனையாளர் மையம்';

  @override
  String get farmerAddEquipment => 'இயந்திரத்தைச் சேர்க்கவும்';

  @override
  String get farmTraceabilityTitle =>
      'பண்ணைத் தரத்தின் தோற்றம் சரிபார்க்கப்பட்டது';

  @override
  String get traceabilityCropItem => 'பயிர் விவரம்:';

  @override
  String get traceabilityFarmerOrigin => 'விவசாயி தோற்றம்:';

  @override
  String get traceabilityHarvestTime => 'அறுவடை செய்த நேரம்:';

  @override
  String get traceabilityCertification => 'இயற்கை சான்றிதழ்:';

  @override
  String get traceabilityFarmingMethod => 'விவசாய முறை:';

  @override
  String get traceabilityQualityNotes => 'தரக் குறிப்புகள்:';

  @override
  String get closeTraceability => 'சரிபார்ப்பு விவரங்களை மூடு';

  @override
  String get produceFiltersTitle => 'வடிகட்டிகள் & வரிசைப்படுத்து';

  @override
  String get clearFilters => 'அனைத்தையும் மீட்டமை';

  @override
  String get sortBy => 'வரிசைப்படுத்து';

  @override
  String get maxDistance => 'அதிகபட்ச தூரம்';

  @override
  String get minFarmerRating => 'விவசாயி மதிப்பீடு';

  @override
  String get freshnessFilter => 'அறுவடை புத்துணர்ச்சி';

  @override
  String get fulfillmentOptions => 'டெலிவரி மற்றும் கிடைக்கும் தன்மை';

  @override
  String get deliveryAvailableOnly => 'வீட்டுக்கே டெலிவரி கிடைக்கும்';

  @override
  String get walkInStoreOnly => 'நேரடி கடை / பண்ணை கொள்முதல்';

  @override
  String get organicCertifiedOnly => 'இயற்கை சான்றளிக்கப்பட்டது மட்டும்';

  @override
  String get applyFilters => 'வடிகட்டிகளைப் பயன்படுத்து';

  @override
  String get customerProduceMapTitle =>
      'அருகிலுள்ள பண்ணை விளைபொருட்கள், இயற்கை விற்பனையாளர்கள் & கடைகள்';

  @override
  String get orderNow => 'இப்போது ஆர்டர் செய்';

  @override
  String get cartTitle => 'ஷாப்பிங் கார்ட்';

  @override
  String get cartClear => 'அழிக்க';

  @override
  String get clearCartConfirmTitle => 'கார்ட்டை அழிக்கவா?';

  @override
  String get clearCartConfirmBody =>
      'உங்கள் கார்ட்டில் உள்ள அனைத்து பொருட்களையும் நீக்க விரும்புகிறீர்களா?';

  @override
  String get cartEmptyTitle => 'உங்கள் கார்ட் காலியாக உள்ளது';

  @override
  String get cartEmptySubtitle =>
      'உள்ளூர் சரிபார்க்கப்பட்ட விவசாயிகளிடமிருந்து புதிய இயற்கை காய்கறிகள், பழங்கள் மற்றும் பால் பொருட்களைப் பார்க்கவும்.';

  @override
  String get exploreProduce => 'விவசாய விளைபொருட்களை ஆராய்க';

  @override
  String get multiFarmerSplitNotice =>
      'புதிய விநியோகத்திற்காக பல விவசாயிகளின் பொருட்கள் தனித்தனி நேரடி ஆர்டர்களாக வைக்கப்படும்.';

  @override
  String get farmerOrderHeader => 'நேரடி பண்ணை ஆர்டர்';

  @override
  String get subtotalLabel => 'பண்ணை ஆர்டர் துணை மொத்தம்';

  @override
  String get redeemRewardCredits => 'வெகுமதி கிரெடிட்கள் (டெமோ பயன்முறை)';

  @override
  String get rewardDiscountDesc => '5% தள்ளுபடியைப் பயன்படுத்துங்கள் (₹50 வரை)';

  @override
  String get billSummary => 'பில் சுருக்கம்';

  @override
  String get itemTotal => 'பொருட்களின் மொத்தம்';

  @override
  String get rewardCreditsDiscount => 'வெகுமதி தள்ளுபடி';

  @override
  String get escrowProtectionBadge => 'எஸ்க்ரோ பாதுகாப்பு உத்தரவாதம்';

  @override
  String get includedLabel => 'சேர்க்கப்பட்டுள்ளது';

  @override
  String get totalPayable => 'மொத்த தொகை';

  @override
  String get proceedToCheckout => 'செக்அவுட்';

  @override
  String get checkoutTitle => 'நேரடி பண்ணை செக்அவுட்';

  @override
  String get stepSlot => '1. டெலிவரி நேரம்';

  @override
  String get stepAddress => '2. முகவரி';

  @override
  String get stepPayment => '3. கட்டணம்';

  @override
  String get doorstepDelivery => 'வீட்டு வாசல் டெலிவரி';

  @override
  String get farmPickup => 'பண்ணை பிக்கப்';

  @override
  String get selectDeliveryWindow =>
      'உங்களுக்கு விருப்பமான அறுவடை மற்றும் டெலிவரி நேரத்தைத் தேர்வுசெய்க';

  @override
  String get noSlotsAvailable => 'இந்த பண்ணைக்கு நேரங்கள் கிடைக்கவில்லை.';

  @override
  String get slotSameDay => 'அதே நாள்';

  @override
  String get slotNextDay => 'அடுத்த நாள்';

  @override
  String get slotPreOrder => 'முன்பதிவு';

  @override
  String get slotFullLabel => 'நேரம் நிரம்பியது (0 மீதமுள்ளது)';

  @override
  String get slotsRemaining => 'நேரங்கள் உள்ளன';

  @override
  String get farmPickupLocation => 'பண்ணை பிக்கப் இடம்';

  @override
  String get deliveryAddressHeader => 'டெலிவரி முகவரி';

  @override
  String get farmPickupNotice =>
      'பண்ணையிலிருந்து நேரடியாக பிக்கப் செய்யவும். உங்கள் ஆர்டர் குறியீட்டைக் கொண்டு வாருங்கள்.';

  @override
  String get fullAddressLabel => 'தெரு முகவரி / கதவு எண்';

  @override
  String get deliveryNotesLabel => 'டெலிவரி வழிமுறைகள் (விருப்பத்தேர்வு)';

  @override
  String get contactPhoneLabel => 'தொடர்பு தொலைபேசி எண்';

  @override
  String get paymentDemoModeNotice =>
      'டெமோ பயன்முறை — உடனடி சரிபார்ப்புடன் கூடிய மாதிரி கட்டணம்.';

  @override
  String get escrowProtectionTitle => '100% எஸ்க்ரோ பாதுகாப்பு உத்தரவாதம்';

  @override
  String get escrowProtectionSubtitle =>
      'டெலிவரியில் தரம் சரிபார்க்கப்படும் வரை கட்டணம் பாதுகாப்பாக வைக்கப்படும்.';

  @override
  String get paymentMethodHeader => 'கட்டண முறையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get itemsTotal => 'பொருட்களின் மொத்தம்';

  @override
  String get rewardDiscount => 'வெகுமதி தள்ளுபடி';

  @override
  String get escrowFeeLabel => 'எஸ்க்ரோ பாதுகாப்புக் கட்டணம்';

  @override
  String get backButton => 'பின்செல்';

  @override
  String get nextStep => 'தொடர்க';

  @override
  String get confirmOrder => 'ஆர்டர் செய்';

  @override
  String get orderConfirmedTitle => 'ஆர்டர் உறுதிப்படுத்தப்பட்டது';

  @override
  String get orderPlacedSuccessfully => 'ஆர்டர் வெற்றிகரமாக வைக்கப்பட்டது!';

  @override
  String get escrowProtectedHeader => 'எஸ்க்ரோ பாதுகாக்கப்பட்ட கட்டணம்';

  @override
  String get escrowProtectedNotice =>
      'டெலிவரியின் போது புத்துணர்ச்சியை நீங்கள் சரிபார்க்கும் வரை உங்கள் கட்டணம் பாதுகாப்பாக இருக்கும்.';

  @override
  String get backToMarketplace => 'சந்தைக்குத் திரும்பு';

  @override
  String get pendingFarmerConfirmation =>
      'விவசாயி உறுதிப்படுத்தல் நிலுவையில் உள்ளது';

  @override
  String get orderCodeLabel => 'ஆர்டர் குறியீடு';

  @override
  String get farmerDeliverySlotsTitle => 'பண்ணை டெலிவரி & பிக்கப் நேரங்கள்';

  @override
  String get addSlotButton => '+ டெலிவரி நேரத்தைச் சேர்';

  @override
  String get noSlotsConfiguredTitle => 'டெலிவரி நேரங்கள் அமைக்கப்படவில்லை';

  @override
  String get noSlotsConfiguredSubtitle =>
      'வாங்குபவர்கள் வசதியான அறுவடை நேரத்தைத் தேர்ந்தெடுக்க டெலிவரி சாளரங்களை உருவாக்கவும்.';

  @override
  String get createFirstSlot => 'முதல் நேர சாளரத்தை உருவாக்கு';

  @override
  String get createDeliverySlotModalTitle => 'டெலிவரி நேர சாளரத்தைச் சேர்';

  @override
  String get saveSlotButton => 'டெலிவரி நேரத்தைச் சேமி';

  @override
  String get addedToCart => 'கார்ட்டில் சேர்க்கப்பட்டது';

  @override
  String get viewCart => 'கார்ட்டைப் பார்';

  @override
  String get liveOrderTimeline => 'நேரலை ஆர்டர் காலவரிசை';

  @override
  String get orderCancelledRefundedNotice =>
      'ஆர்டர் ரத்து செய்யப்பட்டது. பணம் உங்கள் பணப்பையில் திருப்பித் தரப்பட்டது.';

  @override
  String get orderDisputeNotice =>
      'பிரச்சினை நிலுவையில் உள்ளது. தீர்வு காணும் வரை பணம் நிறுத்தி வைக்கப்பட்டுள்ளது.';

  @override
  String get orderStagePlaced => 'ஆர்டர் செய்யப்பட்டது';

  @override
  String get orderStagePlacedSub => 'பணம் பாதுகாப்பாக வைக்கப்பட்டுள்ளது';

  @override
  String get orderStageAccepted => 'விவசாயி ஏற்றுக்கொண்டார்';

  @override
  String get orderStageAcceptedSub => 'அறுவடை மற்றும் தரம் பிரித்தல் நடக்கிறது';

  @override
  String get orderStagePacked => 'பேக் செய்யப்பட்டு எடையிடப்பட்டது';

  @override
  String get orderStagePackedSub => 'தர பரிசோதனை முடிந்தது';

  @override
  String get orderStageReadyPickup => 'பண்ணை பிக்கப்பிற்கு தயார்';

  @override
  String get orderStageReadyPickupSub =>
      'பிக்கப் குறியீட்டுடன் பண்ணைக்குச் செல்லவும்';

  @override
  String get orderStageOutForDelivery => 'டெலிவரிக்கு புறப்பட்டது';

  @override
  String get orderStageOutForDeliverySub => 'உங்கள் முகவரிக்கு வருகிறது';

  @override
  String get orderStagePickedUp => 'பெறப்பட்டது மற்றும் சரிபார்க்கப்பட்டது';

  @override
  String get orderStageDelivered => 'டெலிவரி செய்யப்பட்டது';

  @override
  String get orderStageDeliveredSub => 'விவசாயிக்கு பணம் விடுவிக்கப்பட்டது';

  @override
  String get statusReadyForPickup => 'பிக்கப்பிற்கு தயார்';

  @override
  String get statusOutForDelivery => 'டெலிவரிக்கு புறப்பட்டது';

  @override
  String get rateOrderTitle => 'விவசாய விளைபொருளை மதிப்பிடுங்கள்';

  @override
  String get selectProduceTags => 'விளைபொருளின் சிறப்பம்சங்கள்:';

  @override
  String get orderReviewHint =>
      'புத்துணர்ச்சி, சுவை மற்றும் பேக்கிங் பற்றி பகிருங்கள்...';

  @override
  String get submitReviewButton => 'மதிப்பாய்வை சமர்ப்பிக்கவும்';

  @override
  String get reportOrderIssue => 'புகார் பதிவு செய்யவும்';

  @override
  String get disputeEscrowFreezeNotice =>
      'விசாரணை முடியும் வரை பணம் விடுவிப்பது நிறுத்தப்படும்.';

  @override
  String get selectIssueType => 'பிரச்சனை வகையைத் தேர்ந்தெடுக்கவும்:';

  @override
  String get describeIssueDetails => 'விவரங்களை விவரிக்கவும்:';

  @override
  String get disputeDetailsPlaceholder =>
      'எ.கா: 2 கிலோ தக்காளி சேதமடைந்து வந்தது...';

  @override
  String get submitDisputeCTA => 'பணத்தை நிறுத்தி புகாரைப் பதிவு செய்யவும்';

  @override
  String get orderTrackingTitle => 'ஆர்டர் கண்காணிப்பு';

  @override
  String get confirmDeliveryTitle => 'டெலிவரியை உறுதிப்படுத்துகிறீர்களா?';

  @override
  String get confirmDeliveryPrompt =>
      'ஆர்டர் நல்ல நிலையில் கிடைத்ததா? இது விவசாயிக்கு பணத்தை விடுவிக்கும்.';

  @override
  String get confirmReceivedButton => 'ஆம், கிடைத்தது';

  @override
  String get cancelOrderTitle => 'ஆர்டரை ரத்து செய்யவா?';

  @override
  String get cancelOrderPrompt =>
      'நிச்சயமாக ரத்து செய்ய விரும்புகிறீர்களா? பணம் திருப்பித் தரப்படும்.';

  @override
  String get noKeepOrder => 'இல்லை, ஆர்டர் தொடரட்டும்';

  @override
  String get yesCancelOrder => 'ஆம், ரத்து செய்';

  @override
  String get orderNotFound => 'ஆர்டர் கிடைக்கவில்லை.';

  @override
  String get farmPickupCodeHeader => 'பண்ணை பிக்கப் குறியீடு';

  @override
  String get deliveryPinHeader => 'டெலிவரி பின் எண்';

  @override
  String get showPickupCodeFarmerNote =>
      'பொருட்களைப் பெறும்போது இந்த 4 இலக்க குறியீட்டை விவசாயியிடம் காட்டுங்கள்.';

  @override
  String get showDeliveryPinDriverNote =>
      'டெலிவரியின் போது ஓட்டுநரிடம் இந்த பின்னைப் பகிரவும்.';

  @override
  String get estimatedArrivalHeader => 'எதிர்பார்க்கப்படும் நேரம்';

  @override
  String get orderItemsHeader => 'ஆர்டர் பொருட்கள்';

  @override
  String get totalAmount => 'செலுத்தப்பட்ட மொத்த தொகை:';

  @override
  String get confirmDeliveryReceivedButton =>
      'டெலிவரியை உறுதிசெய்து பணத்தை விடுவிக்கவும்';

  @override
  String get releaseFundsNotice =>
      'உறுதிசெய்தவுடன் விவசாயிக்கு பணம் கிடைக்கும்.';

  @override
  String get reorderItemsButton => 'மீண்டும் ஆர்டர் செய்யவும்';

  @override
  String get rateProduceButton => 'மதிப்பிடவும்';

  @override
  String get myFarmOrdersTitle => 'எனது பண்ணை ஆர்டர்கள்';

  @override
  String get allOrdersFilter => 'அனைத்து ஆர்டர்கள்';

  @override
  String get activeFilter => 'செயலில் உள்ளவை';

  @override
  String get completedFilter => 'டெலிவரி செய்யப்பட்டவை';

  @override
  String get cancelledFilter => 'ரத்து செய்யப்பட்டவை';

  @override
  String get reorderButton => 'மறுஆர்டர்';

  @override
  String get noOrdersFoundTitle => 'ஆர்டர்கள் எதுவும் இல்லை';

  @override
  String get noOrdersFoundSub => 'நீங்கள் இன்னும் எந்த ஆர்டரையும் செய்யவில்லை.';

  @override
  String get exploreProduceButton => 'பொருட்களைப் பார்க்கவும்';

  @override
  String get farmerOrderBoardTitle => 'விவசாயி ஆர்டர் பலகை';

  @override
  String get trackOrderButton => 'கண்காணிக்கவும்';

  @override
  String get cancelOrderButton => 'ஆர்டரை ரத்துசெய்து எஸ்க்ரோ ரீஃபண்ட் பெறவும்';

  @override
  String get disputeButton => 'சிக்கலைப் புகாரளிக்கவும்';

  @override
  String get statusAccepted => 'ஏற்றுக்கொள்ளப்பட்டது';

  @override
  String get statusPacked => 'பேக் செய்யப்பட்டது';

  @override
  String get statusDelivered => 'டெலிவரி செய்யப்பட்டது';

  @override
  String get statusDisputed => 'சர்ச்சையில் உள்ளது';

  @override
  String get editFarmDetails => 'பண்ணை விவரங்களைத் திருத்துக';

  @override
  String get editFarmDetailsSubtitle =>
      'நிலப்பரப்பு, மண் மற்றும் பயிர் விவரங்களை புதுப்பிக்கவும்';

  @override
  String get clusterVillageLabel => 'கிளஸ்டர் / கிராமத்தின் இருப்பிடம்';

  @override
  String get apmcMandiLabel => 'பதிவுசெய்யப்பட்ட ஏபிஎம்சி மண்டி';

  @override
  String get farmDetailsUpdatedSuccess =>
      'பண்ணை விவரங்கள் வெற்றிகரமாக புதுப்பிக்கப்பட்டன';

  @override
  String get selfDeclaredProfile => 'சுய அறிவிப்பு சுயவிவரம்';
}
