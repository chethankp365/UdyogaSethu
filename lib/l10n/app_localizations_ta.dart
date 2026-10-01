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
  String walletBalance(Object balance) {
    return 'வாலட் இருப்பு: ₹$balance';
  }

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
}
