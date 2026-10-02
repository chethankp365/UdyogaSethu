// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'उद्योगसेतु';

  @override
  String get taglinePart1 => 'काम को जोड़ना।';

  @override
  String get taglinePart2 => 'जीवन को सशक्त बनाना।';

  @override
  String get splashInitializing => 'उद्योगसेतु शुरू हो रहा है...';

  @override
  String get chipAiMatching => 'एआई मैचिंग';

  @override
  String get chipSecure => 'सुरक्षित';

  @override
  String get chipVerified => 'सत्यापित';

  @override
  String versionLabel(Object version) {
    return 'संस्करण $version';
  }

  @override
  String get introSkip => 'छोड़ें';

  @override
  String get introHeadline => 'भारत के लिए निर्मित। हर श्रमिक के लिए।';

  @override
  String get introSubtitle =>
      'पास के काम खोजें, कौशल बढ़ाएं, बेहतर कमाएं और गरिमा के साथ जिएं।';

  @override
  String get introFeature1Title => 'अपने पास काम खोजें';

  @override
  String get introFeature2Title => 'सुरक्षित भुगतान';

  @override
  String get introFeature3Title => 'एआई वॉयस असिस्टेंट';

  @override
  String get introNext => 'आगे ->';

  @override
  String get introGetStarted => 'शुरू करें ->';

  @override
  String get languageScreenTitle => 'अपनी भाषा चुनें';

  @override
  String get languageScreenSubtitle => 'हम सब कुछ आपकी भाषा में दिखाएंगे';

  @override
  String listenToWelcomeIn(Object language) {
    return '$language में स्वागत सुनें';
  }

  @override
  String ttsVoiceMissingHint(Object language) {
    return '$language वॉइस इंजन उपलब्ध नहीं है। टीटीएस सेटिंग्स खोलने के लिए टैप करें।';
  }

  @override
  String get welcomeSpeechSentence =>
      'उद्योगसेतु में आपका स्वागत है। काम जोड़ना और जीवन सशक्त बनाना।';

  @override
  String get continueButton => 'आगे बढ़ें ->';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get back => 'वापस';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get apply => 'आवेदन करें';

  @override
  String get submit => 'जमा करें';

  @override
  String get search => 'खोजें';

  @override
  String get filter => 'फ़िल्टर';

  @override
  String get edit => 'संपादित करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get navHome => 'मुख्य पृष्ठ';

  @override
  String get navJobs => 'कार्य';

  @override
  String get navMessages => 'संदेश';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get navWorkers => 'श्रमिक';

  @override
  String get navMarketplace => 'बाजार';

  @override
  String get navMandi => 'मंडी';

  @override
  String get navWallet => 'वॉलेट';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get navSafety => 'सुरक्षा';

  @override
  String get statusAvailable => 'उपलब्ध';

  @override
  String get statusBusy => 'व्यस्त';

  @override
  String get statusOffline => 'ऑफ़लाइन';

  @override
  String get statusVerified => 'सत्यापित';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusNotStarted => 'शुरू नहीं हुआ';

  @override
  String get statusRejected => 'अस्वीकृत';

  @override
  String get statusReviewRequired => 'समीक्षा आवश्यक';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusCompleted => 'पूरा हुआ';

  @override
  String get statusCancelled => 'रद्द किया गया';

  @override
  String get statusInProgress => 'प्रगति पर है';

  @override
  String get roleSeeker => 'कार्य चाहने वाला';

  @override
  String get roleProvider => 'कार्य देने वाला';

  @override
  String get roleFarmer => 'किसान';

  @override
  String get roleAdmin => 'एडमिन';

  @override
  String get seekerTypeInformal => 'अनौपचारिक श्रमिक';

  @override
  String get seekerTypeStudent => 'छात्र';

  @override
  String get seekerTypePartTime => 'अंशकालिक श्रमिक';

  @override
  String get providerTypeHousehold => 'घरेलू';

  @override
  String get providerTypeEmployer => 'व्यापार / नियोक्ता';

  @override
  String get docTypeAadhaar => 'आधार कार्ड';

  @override
  String get docTypePan => 'पैन कार्ड';

  @override
  String get docTypeDrivingLicence => 'ड्राइविंग लाइसेंस';

  @override
  String get docTypeBankAccount => 'बैंक खाता / यूपीआई';

  @override
  String get phoneNumber => 'मोबाइल नंबर';

  @override
  String get enterPhone => 'अपना 10-अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get otpCode => 'ओटीपी कोड';

  @override
  String enterOtp(Object phone) {
    return '$phone पर भेजा गया 6-अंकों का ओटीपी दर्ज करें';
  }

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get enterName => 'अपना पूरा नाम दर्ज करें';

  @override
  String get city => 'शहर';

  @override
  String get pincode => 'पिन कोड';

  @override
  String get requiredField => 'यह क्षेत्र आवश्यक है';

  @override
  String get invalidPhone => 'कृपया एक मान्य 10-अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get invalidOtp => 'कृपया एक मान्य 6-अंकों का ओटीपी दर्ज करें';

  @override
  String get errorNetworkOffline =>
      'कोई इंटरनेट कनेक्शन नहीं है। नेटवर्क जांचें।';

  @override
  String get errorTimeout => 'अनुरोध का समय समाप्त हो गया।';

  @override
  String get errorAuthGeneral => 'प्रमाणीकरण विफल रहा।';

  @override
  String get errorDatabase => 'डेटाबेस त्रुटि हुई।';

  @override
  String get errorUnknown => 'एक अनपेक्षित त्रुटि हुई।';

  @override
  String get errorEdgeFunction => 'सेवा अनुरोध विफल रहा।';

  @override
  String amountRupees(Object amount) {
    return '₹$amount';
  }

  @override
  String wagePerDay(Object amount) {
    return '₹$amount/दिन';
  }

  @override
  String wagePerHour(Object amount) {
    return '₹$amount/घंटा';
  }

  @override
  String get wageTypeDaily => 'दैनिक मजदूरी';

  @override
  String get wageTypeHourly => 'प्रति घंटा मजदूरी';

  @override
  String get wageTypeFixed => 'निश्चित भुगतान';

  @override
  String walletBalance(Object balance) {
    return 'वॉलेट शेष: ₹$balance';
  }

  @override
  String jobsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count काम मिले',
      one: '1 काम मिला',
      zero: 'कोई काम नहीं मिला',
    );
    return '$_temp0';
  }

  @override
  String applicantsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आवेदक',
      one: '1 आवेदक',
      zero: 'कोई आवेदक नहीं',
    );
    return '$_temp0';
  }

  @override
  String distanceKm(Object distance) {
    return '$distance किमी दूर';
  }

  @override
  String get todayGoal => 'आज का लक्ष्य';

  @override
  String get activeJobs => 'सक्रिय कार्य';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get roleTreeTitleStep1 => 'आप कौन हैं?';

  @override
  String get roleTreeSubtitleStep1 => 'शुरू करने के लिए अपनी श्रेणी चुनें।';

  @override
  String get roleTreeTitleStep2 => 'आप क्या करना चाहते हैं?';

  @override
  String get roleTreeSubtitleStep2 => 'उद्योगसेतु पर अपनी भूमिका चुनें।';

  @override
  String get roleTreeTitleStep3 => 'अपने बारे में बताएं';

  @override
  String get roleTreeSubtitleStep3 =>
      'अपने समय के अनुसार कार्य का प्रकार चुनें।';

  @override
  String get roleCategoryWorker => 'श्रमिक / कार्यकर्ता';

  @override
  String get roleCategoryWorkerDesc =>
      'दैनिक मजदूरी, पार्ट-टाइम काम खोजें या श्रमिकों को रखें';

  @override
  String get roleCategoryFarmer => 'किसान';

  @override
  String get roleCategoryFarmerDesc =>
      'बिना बिचौलियों के सीधे खरीदारों को फसल बेचें';

  @override
  String get roleSeekerTitle => 'नौकरी चाहने वाले';

  @override
  String get roleSeekerDesc =>
      'दैनिक मजदूरी और पार्ट-टाइम काम और तुरंत भुगतान पाएं';

  @override
  String get roleProviderTitle => 'काम देने वाले';

  @override
  String get roleProviderDesc =>
      'काम पोस्ट करें, सत्यापित श्रमिकों को रखें, ताजी उपज खरीदें';

  @override
  String get seekerTypeInformalTitle => 'अनौपचारिक / दैनिक मजदूरी श्रमिक';

  @override
  String get seekerTypeInformalDesc =>
      'निर्माण, डिलीवरी, प्लंबिंग काम और तुरंत यूपीआई भुगतान पाएं';

  @override
  String get seekerTypeStudentTitle => 'छात्र';

  @override
  String get seekerTypeStudentDesc => 'पढ़ाई के समय के साथ पार्ट-टाइम काम';

  @override
  String get seekerTypePartTimeTitle => 'पार्ट-टाइम / लकीला काम';

  @override
  String get seekerTypePartTimeDesc => 'लचीली दैनिक या सप्ताहांत शिफ्ट';

  @override
  String get alreadyHaveAccount => 'क्या आपके पास पहले से खाता है?';

  @override
  String get loginLink => 'लॉग इन करें';

  @override
  String listenToStepOptions(Object language) {
    return '$language में विकल्प सुनें';
  }

  @override
  String get breadcrumbWorker => 'श्रमिक';

  @override
  String get breadcrumbSeeker => 'श्रमिक > नौकरी चाहने वाले';

  @override
  String get loginTitle => 'मोबाइल नंबर लॉगिन';

  @override
  String get loginSubtitle =>
      'तत्काल SMS लॉगिन के लिए 10 अंकों का मोबाइल नंबर दर्ज करें।';

  @override
  String get phoneInputLabel => 'मोबाइल फोन नंबर';

  @override
  String get phonePrefix => 'IN +91';

  @override
  String get getOtpCode => 'SMS OTP सत्यापन कोड प्राप्त करें';

  @override
  String get agreeTermsDisclaimer =>
      'मैं सेवा की शर्तों और गोपनीयता नीति से सहमत हूं';

  @override
  String get continueWithGoogle => 'Google के साथ जारी रखें';

  @override
  String get googleSignInNotice => 'Google साइन-इन अगले चरण में सक्षम होगा';

  @override
  String get otpTitle => 'सत्यापन कोड दर्ज करें';

  @override
  String otpSubtitle(Object maskedPhone) {
    return '+91 $maskedPhone पर भेजा गया 6-अंकीय OTP दर्ज करें';
  }

  @override
  String get verifyAndLogin => 'सत्यापित करें और लॉगिन करें';

  @override
  String resendCodeIn(Object seconds) {
    return '$seconds सेकंड में कोड पुनः भेजें';
  }

  @override
  String get resendCode => 'कोड पुनः भेजें';

  @override
  String get maxResendsReached =>
      'इस सत्र के लिए अधिकतम 3 पुनः भेजने की सीमा समाप्त हो गई है।';

  @override
  String get changeNumber => 'नंबर बदलें';

  @override
  String get invalidOtpError =>
      'अमान्य या समाप्त हो चुका OTP। कृपया 6-अंकीय कोड की जांच करें।';

  @override
  String get rateLimitError =>
      'बहुत सारे OTP अनुरोध। कृपया थोड़ी देर बाद प्रयास करें।';

  @override
  String get termsRequiredError =>
      'आगे बढ़ने के लिए कृपया सेवा की शर्तों को स्वीकार करें।';

  @override
  String get googleSignInFailed =>
      'Google साइन-इन विफल रहा। कृपया पुनः प्रयास करें।';

  @override
  String get googleEmailAlreadyLinked =>
      'यह ईमेल पहले से ही किसी अन्य मोबाइल नंबर से जुड़ा हुआ है।';

  @override
  String get verifyPhoneTitle => 'अपना मोबाइल नंबर सत्यापित करें';

  @override
  String get verifyPhoneSubtitle =>
      'अपना पंजीकरण पूरा करने के लिए एक सत्यापित मोबाइल नंबर जोड़ें।';

  @override
  String get linkGoogleAccount => 'Google खाता लिंक करें';

  @override
  String get googleAccountLinked => 'Google खाता सफलतापूर्वक लिंक हो गया।';

  @override
  String get googlePlayServicesMissing =>
      'इस डिवाइस पर Google Play सेवाएं उपलब्ध नहीं हैं。';

  @override
  String wizardStepProgress(Object current, Object total) {
    return 'चरण $current / $total';
  }

  @override
  String get wizardStep1Title => 'मूल विवरण';

  @override
  String get wizardStep1Subtitle => 'अपना नाम, फोटो, लिंग और भाषाएं दर्ज करें।';

  @override
  String get wizardStep2Title => 'कौशल और रुचियां';

  @override
  String get wizardStep2Subtitle =>
      'अपने कौशल या शैक्षणिक रुचियों का चयन करें।';

  @override
  String get wizardStep3Title => 'अनुभव और दर';

  @override
  String get wizardStep3Subtitle =>
      'अपने अनुभव के वर्ष और अपेक्षित दर निर्धारित करें।';

  @override
  String get wizardStep4Title => 'उपलब्धता';

  @override
  String get wizardStep4Subtitle =>
      'अपनी स्थिति, कार्य दिवस और समय निर्धारित करें।';

  @override
  String get wizardStep5Title => 'स्थान';

  @override
  String get wizardStep5Subtitle =>
      'स्थान अनुमति दें और अपनी सेवा त्रिज्या सेट करें।';

  @override
  String get wizardStep6Title => 'विशेष विवरण';

  @override
  String get wizardStep6Subtitle =>
      'अपने कार्यकर्ता प्रोफाइल प्रकार के विवरण दर्ज करें।';

  @override
  String get wizardStep7Title => 'समीक्षा और समाप्त करें';

  @override
  String get wizardStep7Subtitle =>
      'समाप्त करने से पहले अपने प्रोफाइल विवरण की समीक्षा करें।';

  @override
  String get takePhotoCamera => 'फोटो लें (कैमरा)';

  @override
  String get chooseGallery => 'गैलरी से चुनें';

  @override
  String get changePhoto => 'फोटो बदलें';

  @override
  String get uploadingPhoto => 'फोटो अपलोड हो रहा है...';

  @override
  String get uploadPhotoError =>
      'फोटो अपलोड विफल रहा। पुनः प्रयास करने के लिए टैप करें।';

  @override
  String get genderLabel => 'लिंग (वैकल्पिक)';

  @override
  String get genderMale => 'पुरुष';

  @override
  String get genderFemale => 'महिला';

  @override
  String get genderOther => 'अन्य';

  @override
  String get genderPreferNot => 'बताना नहीं चाहते';

  @override
  String get languagesLabel => 'बोली जाने वाली भाषाएं';

  @override
  String get selectCategories => 'श्रेणियां चुनें';

  @override
  String get selectSkills => 'कौशल चुनें';

  @override
  String get informalSkillRequired =>
      'अनौपचारिक श्रमिकों को कम से कम 1 कौशल चुनना होगा।';

  @override
  String get addSubjectOrInterest => 'विषय या रुचि जोड़ें';

  @override
  String get subjectsInterestsLabel => 'विषय या रुचियां';

  @override
  String get experienceYearsLabel => 'अनुभव के वर्ष';

  @override
  String get dailyRateLabel => 'अपेक्षित दैनिक दर (₹)';

  @override
  String get hourlyRateLabel => 'अपेक्षित प्रति घंटा दर (₹)';

  @override
  String wageBandHint(Object max, Object min, Object unit) {
    return 'सुझाव योग्य उचित वेतन बैंड: ₹$min - ₹$max / $unit';
  }

  @override
  String get workingDaysLabel => 'कार्य दिवस';

  @override
  String get workHoursLabel => 'कार्य समय';

  @override
  String get studentWeeklyHoursLabel => 'पसंदीदा साप्ताहिक घंटे';

  @override
  String get partTimeShiftLabel => 'पसंदीदा शिफ्ट स्लॉट';

  @override
  String get shiftMorning => 'सुबह की शिफ्ट (6 AM - 2 PM)';

  @override
  String get shiftEvening => 'शाम की शिफ्ट (2 PM - 10 PM)';

  @override
  String get shiftFlexible => 'लचीली शिफ्ट';

  @override
  String get locationConsentTitle => 'आवश्यकता पड़ने पर स्थान पहुंच';

  @override
  String get locationConsentText =>
      'उद्योगसेतु आपके स्थान का उपयोग नजदीकी नौकरियों से मिलाने और सुरक्षा के लिए करता है।';

  @override
  String get allowLocationAccess => 'स्थान पहुंच की अनुमति दें';

  @override
  String get locationPermissionDenied => 'स्थान अनुमति अस्वीकार कर दी गई।';

  @override
  String get addressLabel => 'घर का पता / इलाका';

  @override
  String serviceRadiusLabel(Object radius) {
    return 'सेवा त्रिज्या: $radius किमी';
  }

  @override
  String get collegeNameLabel => 'कॉलेज / विश्वविद्यालय का नाम';

  @override
  String get courseNameLabel => 'कोर्स / डिग्री';

  @override
  String get regNoLabel => 'पंजीकरण / USN नंबर';

  @override
  String get doYouDriveToggle => 'क्या आप वाहन चलाते हैं?';

  @override
  String get drivingLicenceExplanation =>
      'नोट: ड्राइविंग और डिलीवरी नौकरियों के लिए वैध ड्राइविंग लाइसेंस की आवश्यकता होगी।';

  @override
  String get reviewSummaryTitle => 'प्रोफाइल सारांश';

  @override
  String get finishProfileButton => 'प्रोफाइल पूरा करें और होम पर जाएं';

  @override
  String get verifyIdentityPrompt =>
      'उच्च भुगतान वाली नौकरियां अनलॉक करने के लिए पहचान सत्यापन पूरा करें!';

  @override
  String get quitAndResumeNotice =>
      'ड्राफ्ट स्वचालित रूप से सहेजा गया है। आप कभी भी जारी रख सकते हैं।';
}
