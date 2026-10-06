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
}
