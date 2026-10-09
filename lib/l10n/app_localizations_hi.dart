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
  String get walletBalance => 'वॉलेट बैलेंस';

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

  @override
  String get farmerWizardTitle => 'किसान प्रोफाइल सेटअप';

  @override
  String get farmerStep1Title => 'मूल बातें';

  @override
  String get farmerStep1Subtitle =>
      'अपना नाम, फोटो और बोली जाने वाली भाषाएं दर्ज करें।';

  @override
  String get farmerStep2Title => 'खेत का विवरण';

  @override
  String get farmerStep2Subtitle =>
      'खेत का नाम, स्थान, एकड़, मिट्टी का प्रकार और फसलें चुनें।';

  @override
  String get farmerStep3Title => 'पंजीकरण और बैज';

  @override
  String get farmerStep3Subtitle =>
      'बैज प्राप्त करने के लिए सरकारी पंजीकरण और प्रमाण पत्र जोड़ें।';

  @override
  String get farmerStep4Title => 'बिक्री विकल्प';

  @override
  String get farmerStep4Subtitle =>
      'पिकअप उपलब्धता, डिलीवरी दायरा और समय निर्धारित करें।';

  @override
  String get farmerStep5Title => 'समीक्षा और समाप्त';

  @override
  String get farmerStep5Subtitle =>
      'समाप्त करने से पहले अपने किसान प्रोफाइल विवरण की जांच करें।';

  @override
  String get farmNameLabel => 'खेत का नाम';

  @override
  String get farmNameHint => 'उदा. ग्रीन वैली ऑर्गेनिक फार्म';

  @override
  String get villageClusterLabel => 'गांव / क्लस्टर का नाम';

  @override
  String get villageClusterHint => 'उदा. देवनाहल्ली, बेंगलुरु देहात';

  @override
  String get farmLocationLabel => 'मानचित्र पर खेत का स्थान';

  @override
  String get acresLabel => 'खेत का क्षेत्रफल (एकड़)';

  @override
  String get soilTypeLabel => 'मिट्टी का प्रकार';

  @override
  String get soilPhLabel => 'मिट्टी का pH (वैकल्पिक)';

  @override
  String get primaryCropsLabel => 'मुख्य फसलें';

  @override
  String get farmingMethodLabel => 'खेती की पद्धति';

  @override
  String get methodOrganic => 'जैविक (Organic)';

  @override
  String get methodNatural => 'प्राकृतिक (Natural)';

  @override
  String get methodConventional => 'पारंपरिक (Conventional)';

  @override
  String get apmcRegLabel => 'APMC पंजीकरण संख्या (वैकल्पिक)';

  @override
  String get apmcRegHint => 'उदा. APMC-KA-2024-889';

  @override
  String get kccStatusLabel => 'किसान क्रेडिट कार्ड (KCC) स्थिति';

  @override
  String get kccNone => 'आवेदन नहीं किया';

  @override
  String get kccApplied => 'आवेदन किया गया';

  @override
  String get kccApproved => 'केसीसी स्वीकृत ✓';

  @override
  String get organicCertLabel => 'जैविक प्रमाण पत्र अपलोड (वैकल्पिक)';

  @override
  String get organicCertHelper =>
      'अपलोड की गई फ़ाइलें सुरक्षित निजी स्टोरेज में रखी जाती हैं।';

  @override
  String get farmBadgesTitle => 'फार्म प्रोफाइल बैज';

  @override
  String get deliveryAvailableLabel => 'डिलीवरी उपलब्ध है';

  @override
  String get pickupAvailableLabel => 'पिकअप उपलब्ध है';

  @override
  String deliveryRadiusLabel(Object radius) {
    return 'डिलीवरी दायरा: $radius किमी';
  }

  @override
  String get leadTimeLabel => 'सामान्य आपूर्ति समय';

  @override
  String get apmcBadgeTitle => 'APMC पंजीकृत';

  @override
  String get kccBadgeTitle => 'किसान क्रेडिट कार्ड';

  @override
  String get organicBadgeTitle => 'जैविक प्रमाण पत्र (समीक्षाधीन)';

  @override
  String get uploadCertButton => 'जैविक प्रमाण पत्र अपलोड करें (PDF / Photo)';

  @override
  String get certUploadedPending => 'प्रमाण पत्र अपलोड हुआ (समीक्षाधीन)';

  @override
  String get providerWizardTitle => 'जॉब प्रदाता सेटअप';

  @override
  String get providerStep1Title => 'मूल बातें';

  @override
  String get providerStep1Subtitle =>
      'अपना पूरा नाम, फोटो और भाषाएं दर्ज करें।';

  @override
  String get providerStep2Title => 'प्रदाता श्रेणी';

  @override
  String get providerStep2Subtitle =>
      'चुनें कि आप घरेलू या ठेकेदार/व्यवसाय के रूप में काम देते हैं।';

  @override
  String get providerStep3HouseholdTitle => 'घर का पता और डिलीवरी';

  @override
  String get providerStep3HouseholdSubtitle =>
      'मुख्य डिलीवरी पता और प्राथमिकताएं सेट करें।';

  @override
  String get providerStep3EmployerTitle => 'संस्था और साइट विवरण';

  @override
  String get providerStep3EmployerSubtitle =>
      'संस्था का नाम, मुख्य साइट पता, कार्य श्रेणी और टीम का आकार दर्ज करें।';

  @override
  String get providerStep4Title => 'अनुमतियां और सहमति';

  @override
  String get providerStep4Subtitle =>
      'स्थान और अधिसूचना अनुमतियों की समीक्षा करें।';

  @override
  String get providerStep5Title => 'समीक्षा और समाप्त करें';

  @override
  String get providerStep5Subtitle =>
      'समाप्त करने से पहले अपनी प्रोफ़ाइल विवरण की जांच करें।';

  @override
  String get doorstepAddressLabel => 'फ़्लैट / मकान नंबर और गली';

  @override
  String get doorstepAddressHint => 'उदा. #402, सनशाइन अपार्टमेंट्स';

  @override
  String get landmarkLabel => 'लैंडमार्क';

  @override
  String get landmarkHint => 'उदा. मेट्रो स्टेशन के पास';

  @override
  String get deliveryInstructionsLabel => 'डिलीवरी प्राथमिकताएं और निर्देश';

  @override
  String get deliveryInstructionsHint => 'उदा. गेट पर सुरक्षा गार्ड को दें';

  @override
  String get gateCodeLabel => 'गेट कोड / इंटरकॉम (वैकल्पिक)';

  @override
  String get gateCodeHint => 'उदा. 1234';

  @override
  String get orgNameLabel => 'संस्था / व्यवसाय का नाम';

  @override
  String get orgNameHint => 'उदा. सेतु कंस्ट्रक्शन';

  @override
  String get primarySiteAddressLabel => 'मुख्य साइट का पता';

  @override
  String get primarySiteAddressHint => 'उदा. साइट 45, इलेक्ट्रॉनिक्स सिटी';

  @override
  String get categoriesHiringLabel => 'हायर की जाने वाली श्रेणियां';

  @override
  String get typicalCrewSizeLabel => 'आवश्यक श्रमिकों की संख्या';

  @override
  String crewSizeWorkers(Object count) {
    return '$count श्रमिक';
  }

  @override
  String get gpsConsentExplanation =>
      'साइट डिलीवरी पते और स्थानीय श्रमिकों की उपलब्धता दिखाने के लिए GPS स्थान आवश्यक है।';

  @override
  String get notificationsConsentExplanation =>
      'श्रमिकों के आवेदन और डिलीवरी अपडेट प्राप्त करने के लिए नोटिफिकेशन सक्षम करें।';

  @override
  String get grantGpsPermission => 'स्थान अनुमति दें';

  @override
  String get grantNotificationsPermission => 'नोटिफिकेशन अनुमति दें';

  @override
  String get permissionGranted => 'अनुमति दी गई';

  @override
  String get providerHomeTitle => 'प्रदाता होम';

  @override
  String get roleConflictTitle => 'खाता भूमिका संघर्ष';

  @override
  String roleConflictMessage(Object chosenRole, Object existingRole) {
    return 'यह नंबर पहले से ही $existingRole के रूप में पंजीकृत है। आप इसे $chosenRole के रूप में उपयोग नहीं कर सकते। किसी अन्य भूमिका का उपयोग करने के लिए, $existingRole के रूप में लॉग इन करें, प्रोफ़ाइल > सेटिंग्स > खाता हटाएं पर जाएं, और फिर नया खाता बनाएं।';
  }

  @override
  String roleConflictLoginAs(Object existingRole) {
    return '$existingRole के रूप में लॉग इन करें';
  }

  @override
  String get roleConflictBack => 'पीछे जाएं';

  @override
  String get privacyCentreTitle => 'गोपनीयता केंद्र';

  @override
  String get privacyCentreSubtitle =>
      'अपनी डेटा सहमति, गोपनीयता अधिकारों और सिस्टम अनुमति को प्रबंधित करें।';

  @override
  String get consentSheetTitle => 'डेटा प्रसंस्करण सहमति';

  @override
  String get consentWhatCollected => 'क्या एकत्र किया जाता है';

  @override
  String get consentWhyCollected => 'यह क्यों एकत्र किया जाता है';

  @override
  String get consentHowLongKept => 'इसे कब तक रखा जाता है';

  @override
  String get consentWhoCanSee => 'इसे कौन देख सकता है';

  @override
  String get consentHowToWithdraw => 'सहमति कैसे वापस लें';

  @override
  String get consentAgreeButton => 'मैं सहमत हूं और सहमति देता हूं';

  @override
  String get consentNotNowButton => 'अभी नहीं';

  @override
  String get consentGrantedStatus => 'सहमति दी गई';

  @override
  String get consentRevokedStatus => 'सहमति नहीं दी गई / वापस ली गई';

  @override
  String get withdrawConsentButton => 'सहमति वापस लें';

  @override
  String get withdrawFaceConsentTitle => 'चेहरा सत्यापन सहमति वापस लें?';

  @override
  String get withdrawFaceConsentMessage =>
      'चेहरा सहमति वापस लेने से आपका चेहरा संदर्भ डेटा स्थायी रूप से हटा दिया जाएगा।';

  @override
  String get confirmWithdrawButton => 'वापस लें और डेटा हटाएं';

  @override
  String get cancelButton => 'रद्द करें';

  @override
  String get profileTitle => 'मेरी प्रोफ़ाइल';

  @override
  String get termsAndPrivacyTitle => 'नियम एवं गोपनीयता नीति';

  @override
  String get termsDraftNotice =>
      'ड्राफ्ट - वास्तविक लॉन्च से पहले इसकी समीक्षा कराएं';

  @override
  String get systemPermissionsTitle => 'सिस्टम अनुमतियां';

  @override
  String get openSystemSettings => 'ऐप सेटिंग्स खोलें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get faceVerificationCheck => 'चेहरा सत्यापन जांच';

  @override
  String get faceCheckSubtext => 'फेस लाइवनेस चेक से अपनी पहचान सत्यापित करें';

  @override
  String get faceMatchSuccess => 'चेहरे की पहचान सत्यापित';

  @override
  String get faceMatchFailedTitle => 'चेहरा मिलान विफल';

  @override
  String get faceMatchFailedBody =>
      'अच्छी रोशनी में अपने चेहरे को स्पष्ट रखें और पुनः प्रयास करें।';

  @override
  String get manualReviewRequiredTitle => '3 सत्यापन प्रयास विफल';

  @override
  String get manualReviewRequiredBody =>
      'आपका चेहरा सत्यापन मैन्युअल समीक्षा के लिए भेजा गया है। आप सीमित पहुंच के साथ जारी रख सकते हैं।';

  @override
  String get requestManualReview => 'मैन्युअल समीक्षा का अनुरोध करें';

  @override
  String get retryVerification => 'पुनः सत्यापन का प्रयास करें';

  @override
  String get demoSimulatePass => 'डेमो: सफल सत्यापन';

  @override
  String get demoSimulateFail => 'डेमो: विफल सत्यापन';

  @override
  String get seekerHomeTitle => 'रोजगार साधक होम';

  @override
  String get searchJobsPlaceholder => 'नौकरियां, सेवाएं खोजें...';

  @override
  String get todaysGoal => 'आज का लक्ष्य';

  @override
  String get viewWallet => 'वॉलेट देखें >';

  @override
  String get locationSharingActive =>
      'सुरक्षा निगरानी के लिए स्थान साझाकरण सक्रिय है';

  @override
  String get changeLocation => 'बदलें >';

  @override
  String get quickActionsHeader => 'त्वरित क्रियाएं';

  @override
  String get actionNearbyJobs => 'पास की नौकरियां';

  @override
  String get actionAiAssistant => 'एआई सहायक';

  @override
  String get actionWallet => 'वॉलेट';

  @override
  String get actionSafetyHub => 'सुरक्षा हब';

  @override
  String get tagSponsored => 'प्रायोजित';

  @override
  String get whyAmISeeingThis => 'मुझे यह क्यों दिख रहा है?';

  @override
  String get recommendedForYou => 'आपके लिए अनुशंसित';

  @override
  String get applyNow => 'अभी आवेदन करें';

  @override
  String get applied => 'आवेदन किया गया ✓';

  @override
  String get noJobsNearYou => 'आपके पास अभी कोई नौकरी नहीं है';

  @override
  String get widenRadiusAction => 'खोज दायरा बढ़ाएं';

  @override
  String get sosEmergencyPill => 'आपातकालीन एसओएस';

  @override
  String get selectLocationArea => 'स्थान क्षेत्र चुनें';

  @override
  String get goodMorning => 'शुभ प्रभात';

  @override
  String get goodAfternoon => 'शुभ दोपहर';

  @override
  String get goodEvening => 'शुभ संध्या';

  @override
  String get studentsWelcomeChip => 'छात्रों का स्वागत है';

  @override
  String get flexibleShiftChip => 'लचीली शिफ्ट';

  @override
  String get nearbyJobsMapTitle => 'निकटवर्ती दैनिक मजदूरी कार्य और कार्यस्थल';

  @override
  String livePinsCount(Object count) {
    return '$count लाइव पिन';
  }

  @override
  String nearbyGpsPinListings(Object count) {
    return 'निकटवर्ती जीपीएस पिन सूचियां ($count)';
  }

  @override
  String get tapPinOrCardToInspect =>
      'विवरण देखने के लिए पिन या कार्ड पर टैप करें';

  @override
  String get applyButton => 'आवेदन करें';

  @override
  String get categoryFilterAll => 'सभी';

  @override
  String get recenterMap => 'जीपीएस पुनः केंद्रित करें';

  @override
  String get zoomIn => 'ज़ूम इन';

  @override
  String get zoomOut => 'ज़ूम आउट';

  @override
  String get gpsDisabledBanner =>
      'जीपीएस बंद है। सटीक दूरी के लिए लोकेशन चालू करें।';

  @override
  String get locationPermissionDeniedBanner =>
      'लोकेशन अनुमति नहीं मिली। डिफ़ॉल्ट क्षेत्र दिखाया जा रहा है।';

  @override
  String get noJobsInArea => 'इस दायरे में कोई कार्यस्थल नहीं मिला';

  @override
  String get searchRadius => 'खोज दायरा';

  @override
  String radiusKm(Object radius) {
    return '$radius किमी';
  }

  @override
  String get openLocationSettings => 'सेटिंग्स';

  @override
  String get loadJobsError =>
      'निकटवर्ती कार्य लोड करने में असमर्थ। कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get retryAction => 'पुनः प्रयास करें';

  @override
  String get openStreetMapAttribution => '© OpenStreetMap contributors';

  @override
  String get cameraPermissionTitle => 'कैमरा एक्सेस';

  @override
  String get cameraPermissionSubtitle =>
      'चेहरे के सत्यापन और आईडी स्कैनिंग के लिए उपयोग किया जाता है।';

  @override
  String get locationPermissionTitle => 'डिवाइस स्थान (जीपीएस)';

  @override
  String get locationPermissionSubtitle =>
      'पास के काम, मार्ग मानचित्र और उपस्थिति दिखाने के लिए उपयोग किया जाता है।';

  @override
  String get notificationPermissionTitle => 'सूचनाएं';

  @override
  String get notificationPermissionSubtitle =>
      'तुरंत काम की सूचना, भुगतान और सुरक्षा अपडेट के लिए उपयोग किया जाता है।';

  @override
  String get permissionAllowedStatus => 'अनुमति है';

  @override
  String get permissionBlockedStatus => 'अवरुद्ध / बंद';

  @override
  String get refreshConsentsTooltip => 'स्थिति ताज़ा करें';

  @override
  String get tabOverview => 'अवलोकन';

  @override
  String get tabWorkShowcase => 'काम का प्रदर्शन';

  @override
  String get tabSafetyStatus => 'सुरक्षा स्थिति';

  @override
  String get verifiedJobsStat => 'सत्यापित काम';

  @override
  String get ratingStat => 'रेटिंग';

  @override
  String get totalEarningsStat => 'कुल कमाई';

  @override
  String categoryPrefix(Object category) {
    return 'श्रेणी: $category';
  }

  @override
  String get roleCredentialsTitle => 'भूमिका क्रेडेंशियल्स और श्रेणी बैज';

  @override
  String get changeCategoryBtn => 'श्रेणी बदलें';

  @override
  String get changeCategoryTitle => 'कार्यकर्ता श्रेणी बदलें';

  @override
  String get changeCategorySubtitle =>
      'नौकरियों और सत्यापन को निजीकृत करने के लिए अपना कार्य प्रकार चुनें';

  @override
  String get categoryInformalTitle => 'अनौपचारिक / कुशल कार्यकर्ता';

  @override
  String get categoryInformalDesc => 'शिल्प कौशल, गृह सेवाएं और कृषि कार्य';

  @override
  String get categoryStudentTitle => 'छात्र गिग कार्यकर्ता';

  @override
  String get categoryStudentDesc =>
      'कैंपस गिग्स, ट्यूशन, डिज़ाइन और ऑनलाइन कार्य';

  @override
  String get categoryPartTimeTitle => 'अंशकालिक कार्यकर्ता';

  @override
  String get categoryPartTimeDesc => 'रिटेल, रेस्टोरेंट सेवा और लचीली शिफ्ट';

  @override
  String get mySkillsTitle => 'मेरे कौशल';

  @override
  String get addSkillBtn => '+ कौशल जोड़ें';

  @override
  String get addSkillDialogTitle => 'एक कौशल चुनें';

  @override
  String get addSkillDialogSubtitle =>
      'अपनी प्रोफ़ाइल से मेल खाने वाले कौशल चुनें';

  @override
  String get languageAccessibilityTitle => 'भाषा और पहुंच';

  @override
  String get verificationStatusTitle => 'सत्यापन स्थिति';

  @override
  String get accountAndSafetyTitle => 'खाता और सुरक्षा';

  @override
  String get emptyShowcaseTitle =>
      'आपके पूरे किए गए काम, फ़ोटो और रेटिंग यहां दिखाई देंगे';

  @override
  String get emptyShowcaseSubtitle =>
      'जब आप उद्योगसेतु के माध्यम से काम पूरा करेंगे, तो नियोक्ताओं की समीक्षाएं, फ़ोटो और कमाई यहां प्रदर्शित की जाएगी।';

  @override
  String get browseJobsAction => 'नौकरियां ब्राउज़ करें';

  @override
  String get safetyLifecycleTitle => 'सुरक्षा ऑनबोर्डिंग और बैज';

  @override
  String get notVerifiedYet => 'अभी सत्यापित नहीं है';

  @override
  String get verifiedWorkerBadge => 'उद्योगसेतु सत्यापित ✓';

  @override
  String get dlVerified => 'ड्राइविंग लाइसेंस सत्यापित ✓';

  @override
  String get dlPending => 'ड्राइविंग लाइसेंस जोड़ें';

  @override
  String get studentBadgeVerified => 'छात्र स्थिति सत्यापित ✓';

  @override
  String get studentBadgePending => 'छात्र स्थिति सत्यापित करें';

  @override
  String get bankUpiVerified => 'बैंक / यूपीआई लिंक है ✓';

  @override
  String get bankUpiPending => 'बैंक / यूपीआई लिंक करें';

  @override
  String get bgCheckVerified => 'बैकग्राउंड जांच पूरी ✓';

  @override
  String get bgCheckPending => 'बैकग्राउंड जांच लंबित';

  @override
  String get aadhaarVerified => 'आधार ई-केवाईसी सत्यापित ✓';

  @override
  String get faceLivenessVerified => 'चेहरा बायोमेट्रिक सत्यापित ✓';

  @override
  String get safetyTrainingVerified => '1-दिवसीय सुरक्षा प्रशिक्षण पूर्ण ✓';

  @override
  String categoryUpdatedSnackbar(Object category) {
    return 'श्रेणी को $category में अपडेट किया गया! फ़ीड और कौशल ताज़ा किए गए।';
  }

  @override
  String get providerMyJobsTitle => 'मेरे काम';

  @override
  String get providerTabOpen => 'खुले';

  @override
  String get providerTabFilled => 'भरे हुए';

  @override
  String get providerTabCompleted => 'पूर्ण';

  @override
  String providerSlotsCounter(int filled, int total) {
    return '$filled / $total स्थान भरे गए';
  }

  @override
  String providerSlotsOpenCount(int count) {
    return '$count खाली';
  }

  @override
  String get providerPostNewJob => 'नौकरी पोस्ट करें';

  @override
  String get providerNoJobsTitle => 'कोई नौकरी नहीं मिली';

  @override
  String get providerNoOpenJobsDesc =>
      'आपके पास कोई खुली नौकरी पोस्टिंग नहीं है। सत्यापित श्रमिकों को नियुक्त करने के लिए एक बनाएं।';

  @override
  String get providerNoFilledJobsDesc => 'वर्तमान में कोई नौकरी भरी नहीं है।';

  @override
  String get providerNoCompletedJobsDesc =>
      'अभी तक कोई नौकरी पूर्ण नहीं हुई है।';

  @override
  String get providerViewApplicants => 'आवेदक देखें';

  @override
  String providerApplicantsBadge(int count) {
    return '$count आवेदक';
  }

  @override
  String get providerJobPaused => 'रोका गया';

  @override
  String get providerJobDraft => 'ड्राफ्ट';

  @override
  String get providerJobCancelled => 'रद्द';

  @override
  String get providerActionEdit => 'पोस्टिंग संपादित करें';

  @override
  String get providerActionPause => 'पोस्टिंग रोकें';

  @override
  String get providerActionResume => 'पोस्टिंग फिर से शुरू करें';

  @override
  String get providerActionCancel => 'नौकरी रद्द करें';

  @override
  String get providerCancelWarningTitle => 'क्या नौकरी पोस्टिंग रद्द करें?';

  @override
  String providerCancelWarningHiredDesc(int count) {
    return 'चेतावनी: इस नौकरी में $count श्रमिक नियुक्त हैं। रद्द करने से उन्हें तुरंत सूचित किया जाएगा और कार्य रद्द हो जाएगा।';
  }

  @override
  String get providerCancelStandardDesc =>
      'क्या आप वाकई इस नौकरी पोस्टिंग को रद्द करना चाहते हैं?';

  @override
  String get providerConfirmCancel => 'रद्दीकरण की पुष्टि करें';

  @override
  String get providerJobCancelledSuccess => 'नौकरी रद्द कर दी गई है।';

  @override
  String get providerJobPausedSuccess => 'नौकरी पोस्टिंग रोक दी गई है।';

  @override
  String get providerJobResumedSuccess => 'नौकरी पोस्टिंग अब सक्रिय है।';

  @override
  String get postJobWizardTitle => 'दैनिक वेतन नौकरी पोस्ट करें';

  @override
  String get editJobWizardTitle => 'नौकरी पोस्टिंग संपादित करें';

  @override
  String get postJobStep1 => 'श्रेणी और शीर्षक';

  @override
  String get postJobStepAudience => 'लक्षित श्रमिक';

  @override
  String get postJobAudienceTitle => 'यह काम किसके लिए है?';

  @override
  String get postJobAudienceSubtitle =>
      'इस काम को देखने और आवेदन करने के लिए उपयुक्त श्रमिक प्रकार चुनें।';

  @override
  String get postJobAudienceInformal => 'दैनिक वेतन / असंगठित श्रमिक';

  @override
  String get postJobAudienceInformalHint =>
      'दैनिक मजदूर, निर्माण, लोडिंग, घरेलू सहायक';

  @override
  String get postJobAudienceStudent => 'छात्र';

  @override
  String get postJobAudienceStudentHint =>
      'शाम या सप्ताहांत के छोटे और लचीले काम चाहने वाले छात्र';

  @override
  String get postJobAudiencePartTime => 'अंशकालिक / लचीला श्रमिक';

  @override
  String get postJobAudiencePartTimeHint =>
      'कम समय या लचीले घंटों में काम करने के इच्छुक श्रमिक';

  @override
  String get postJobAudienceRequired => 'कृपया कम से कम एक श्रमिक प्रकार चुनें';

  @override
  String get hubConfirmedBookingEmptyTitle => 'कोई सक्रिय बुकिंग नहीं';

  @override
  String get hubConfirmedBookingEmptyDesc =>
      'आपकी कन्फर्म बुकिंग और लाइव ट्रैकिंग यहाँ दिखाई देगी।';

  @override
  String get hubLocationNotSet => 'स्थान सेट नहीं है';

  @override
  String get postJobStep2 => 'वेतन और समय';

  @override
  String get postJobStep3 => 'स्थान और भुगतान';

  @override
  String get postJobStep4 => 'आवश्यकताएं और पता';

  @override
  String get postJobStep5 => 'पूर्वावलोकन और प्रकाशित करें';

  @override
  String get postJobSelectCategory => 'कार्य श्रेणी चुनें';

  @override
  String get postJobTitleLabel => 'नौकरी का शीर्षक';

  @override
  String get postJobTitleHint => 'उदा., निर्माण सहायक, इलेक्ट्रीशियन, प्लंबर';

  @override
  String get postJobDescLabel => 'नौकरी विवरण';

  @override
  String get postJobDescHint =>
      'विशिष्ट कार्य, आवश्यक उपकरण या स्थान विवरण लिखें...';

  @override
  String get postJobWageType => 'वेतन प्रकार';

  @override
  String get postJobWageDaily => 'दैनिक';

  @override
  String get postJobWageHourly => 'प्रति घंटा';

  @override
  String get postJobWageFixed => 'निश्चित';

  @override
  String get postJobAmountLabel => 'वेतन राशि (₹)';

  @override
  String get postJobFairWageBandTitle => 'उचित वेतन सीमा:';

  @override
  String postJobFairWageBandRange(int min, int max, String unit) {
    return '₹$min - ₹$max / $unit';
  }

  @override
  String postJobBelowFairWageWarning(int min, int max) {
    return 'वेतन अनुशंसित उचित वेतन सीमा (₹$min - ₹$max) से कम है। श्रमिक आवेदन करने में धीमे हो सकते हैं, लेकिन आप आगे बढ़ सकते हैं।';
  }

  @override
  String get postJobDurationLabel => 'अनुमानित अवधि';

  @override
  String postJobDurationHours(int hours) {
    return '$hours घंटे';
  }

  @override
  String get postJobStartDateLabel => 'प्रारंभ तिथि और समय';

  @override
  String get postJobSelectDateTime => 'तिथि और समय चुनें';

  @override
  String get postJobSlotsTotalLabel => 'आवश्यक श्रमिकों की संख्या';

  @override
  String get postJobMaterialsLabel => 'सामग्री और उपकरण';

  @override
  String get postJobMaterialsProvided =>
      'मैं सभी उपकरण और सामग्री प्रदान करूँगा';

  @override
  String get postJobMaterialsWorkerBrings => 'श्रमिक को अपने उपकरण लाने चाहिए';

  @override
  String get postJobPaymentModeLabel => 'भुगतान सुरक्षा मोड';

  @override
  String get postJobPaymentEscrow => 'सुरक्षित एस्क्रो (अनुशंसित)';

  @override
  String get postJobPaymentEscrowDesc =>
      'कार्य सत्यापित और स्वीकृत होने तक धनराशि सुरक्षित रखी जाती है';

  @override
  String get postJobPaymentUpi => 'कार्य पूरा होने पर सीधा UPI';

  @override
  String get postJobPaymentUpiDesc =>
      'साइट पर सीधे कार्यकर्ता के UPI QR पर भुगतान करें';

  @override
  String get postJobPaymentCash => 'साइट पर दैनिक नकद';

  @override
  String get postJobPaymentCashDesc =>
      'शिफ्ट समाप्त होने के बाद नकद भुगतान करें';

  @override
  String get postJobRequirementsLabel => 'श्रमिक आवश्यकताएं';

  @override
  String get postJobReqVerifiedOnly => 'केवल पृष्ठभूमि और पहचान सत्यापित';

  @override
  String get postJobReqLicence => 'ड्राइविंग लाइसेंस आवश्यक';

  @override
  String get postJobReqStudents => 'छात्र और अंशकालिक अनुकूल';

  @override
  String get postJobLocationLabel => 'कार्य स्थल';

  @override
  String get postJobAddressHint => 'साइट का पता या लैंडमार्क दर्ज करें';

  @override
  String get postJobGeofenceRadiusLabel => 'जियोफेंस चेक-इन त्रिज्या';

  @override
  String postJobGeofenceMeters(int meters) {
    return '$meters मीटर';
  }

  @override
  String get postJobPublishButton => 'नौकरी प्रकाशित करें';

  @override
  String get postJobSaveEditButton => 'परिवर्तन सहेजें';

  @override
  String get postJobPublishSuccess => 'नौकरी सफलतापूर्वक पोस्ट की गई!';

  @override
  String applicantsScreenTitle(int count) {
    return 'आवेदक ($count)';
  }

  @override
  String get applicantsNoApplicantsTitle => 'अभी तक कोई आवेदन नहीं';

  @override
  String get applicantsNoApplicantsDesc =>
      'आस-पास के श्रमिकों को सूचित किया जा रहा है। आवेदन करने पर वे यहाँ दिखाई देंगे।';

  @override
  String applicantCardJobsDone(int count) {
    return '$count काम पूरे हुए';
  }

  @override
  String applicantCardRating(double rating, int count) {
    return '$rating ($count)';
  }

  @override
  String applicantCardLanguages(String langs) {
    return 'भाषाएं: $langs';
  }

  @override
  String applicantCardSkills(String skills) {
    return 'कौशल: $skills';
  }

  @override
  String get applicantActionHire => 'नियुक्त करें';

  @override
  String get applicantActionShortlist => 'शॉर्टलिस्ट';

  @override
  String get applicantActionReject => 'अस्वीकार करें';

  @override
  String get applicantActionChat => 'चैट';

  @override
  String get applicantActionProfile => 'प्रोफ़ाइल देखें';

  @override
  String get applicantStatusApplied => 'आवेदित';

  @override
  String get applicantStatusShortlisted => 'शॉर्टलिस्टेड';

  @override
  String get applicantStatusHired => 'नियुक्त';

  @override
  String get applicantStatusRejected => 'अस्वीकृत';

  @override
  String get applicantHireConfirmTitle => 'श्रमिक को नियुक्त करें?';

  @override
  String applicantHireConfirmDesc(String name) {
    return '$name को नियुक्त करने से उन्हें इस नौकरी में 1 स्थान दिया जाएगा।';
  }

  @override
  String get applicantHiredSuccess => 'श्रमिक को सफलतापूर्वक नियुक्त किया गया!';

  @override
  String get applicantShortlistedSuccess =>
      'आवेदक को शॉर्टलिस्ट में ले जाया गया।';

  @override
  String get applicantRejectedSuccess => 'आवेदन अस्वीकार कर दिया गया।';

  @override
  String get applicantJobFullNotice => 'इस नौकरी के सभी स्थान भर चुके हैं।';

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
  String get hubActionScanQr => 'क्यूआर स्कैन';

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
  String get bookingWizardTitle => 'सीधी बुकिंग';

  @override
  String get bookingStepService => 'सेवा';

  @override
  String get bookingStepDateTime => 'तारीख और समय';

  @override
  String get bookingStepAddress => 'पता';

  @override
  String get bookingStepPayment => 'मूल्य और भुगतान';

  @override
  String get bookingStepNotice => 'सूचना';

  @override
  String get bookingStepTicket => 'बुकिंग पास';

  @override
  String get bookingWorkerDetails => 'श्रमिक विवरण';

  @override
  String get bookingServiceTitleLabel => 'सेवा का शीर्षक / विवरण';

  @override
  String get bookingServiceTitleHint => 'उदा. लिविंग रूम पंखा वायरिंग मरम्मत';

  @override
  String get bookingSpecialNotes => 'विशेष निर्देश / टिप्पणियां';

  @override
  String get bookingSpecialNotesHint =>
      'उदा. अतिरिक्त 2.5 मिमी तार लाएं, सीढ़ी उपलब्ध है';

  @override
  String get bookingDuration => 'अनुमानित अवधि';

  @override
  String get bookingDurationHalfDay => 'आधा दिन (4 घंटे)';

  @override
  String get bookingDurationFullDay => 'पूरा दिन (8 घंटे)';

  @override
  String bookingDurationCustom(int hours) {
    return 'कस्टम ($hours घंटे)';
  }

  @override
  String get bookingSelectDate => 'तारीख चुनें';

  @override
  String get bookingSelectTimeSlot => 'समय स्लॉट चुनें';

  @override
  String get bookingSlotAvailable => 'उपलब्ध';

  @override
  String get bookingSlotBooked => 'बुक किया हुआ';

  @override
  String get bookingScheduleConflictAlert =>
      'यह श्रमिक इस समय स्लॉट में पहले से बुक है। कृपया कोई अन्य स्लॉट चुनें।';

  @override
  String get bookingAddressTitle => 'सेवा स्थल';

  @override
  String get bookingSavedAddresses => 'सहेजे गए पते';

  @override
  String get bookingAddNewAddress => 'नया पता जोड़ें';

  @override
  String get bookingAddressLabel => 'पता लेबल';

  @override
  String get bookingAddressLine1 => 'मकान/फ्लैट नं. व सड़क';

  @override
  String get bookingLandmark => 'लैंडमार्क (वैकल्पिक)';

  @override
  String get bookingCity => 'शहर';

  @override
  String get bookingPincode => 'पिनकोड';

  @override
  String get bookingSaveAsDefault => 'डिफ़ॉल्ट पते के रूप में सहेजें';

  @override
  String get bookingPriceBreakdown => 'मूल्य विवरण';

  @override
  String get bookingAgreedWage => 'सहमत श्रमिक मजदूरी';

  @override
  String get bookingPlatformFee => 'प्लेटफ़ॉर्म सुविधा शुल्क';

  @override
  String get bookingProtectionCoverFee => 'जॉब सुरक्षा कवर';

  @override
  String get bookingTotalPrice => 'कुल राशि';

  @override
  String get bookingFairWageVerified => 'उचित मजदूरी दायरे में';

  @override
  String get bookingFairWageBelow => 'मानक उचित मजदूरी से कम';

  @override
  String get bookingPaymentMethod => 'भुगतान विधि';

  @override
  String get bookingPaymentCash => 'काम पूरा होने पर नकद';

  @override
  String get bookingPaymentUpi => 'त्वरित यूपीआई (UPI)';

  @override
  String get bookingPaymentEscrow => 'सुरक्षित एस्क्रो (अनुशंसित)';

  @override
  String get bookingPaymentPlaceholder => 'भुगतान गेटवे एकीकरण (P5.2)';

  @override
  String get bookingRecurringOption => 'दोहराई जाने वाली सेवा अनुसूची';

  @override
  String get bookingRecurringToggle => 'इसे नियमित दोहराई जाने वाली सेवा बनाएं';

  @override
  String get bookingRecurringWeekly => 'साप्ताहिक दोहराव';

  @override
  String get bookingRecurringMonthly => 'मासिक दोहराव';

  @override
  String get bookingUnverifiedNoticeTitle => 'उद्योगसेतु सत्यापित नहीं';

  @override
  String get bookingUnverifiedNoticeSubtitle =>
      'इस श्रमिक ने उद्योगसेतु प्रशिक्षण और सत्यापन पूरा नहीं किया है।';

  @override
  String get bookingUnverifiedNoticeDesc =>
      'श्रमिक की पहचान पंजीकृत है, लेकिन उन्होंने आधिकारिक विश्वास बैज प्राप्त नहीं किया है। नीचे अपनी पसंदीदा बुकिंग विधि चुनें:';

  @override
  String get bookingProtectionCoverTitle => '₹40 जॉब सुरक्षा कवर जोड़ें';

  @override
  String get bookingProtectionCoverDesc =>
      'आकस्मिक संपत्ति क्षति सुरक्षा (₹10,000 तक) और विवाद दावा सहायता।';

  @override
  String get bookingBookWithoutProtection => 'बिना सुरक्षा के बुक करें';

  @override
  String get bookingBookWithoutProtectionDesc =>
      'बिना संपत्ति क्षति कवर के सीधे नकद/एस्क्रो शर्तों के साथ आगे बढ़ें।';

  @override
  String get bookingProceedToTicket => 'पुष्टि करें और बुकिंग पास पर आगे बढ़ें';

  @override
  String get bookingTicketTitle => 'बुकिंग पास टिकट';

  @override
  String get bookingStatusWaiting => 'श्रमिक की प्रतीक्षा है';

  @override
  String get bookingCodeLabel => 'बुकिंग कोड';

  @override
  String get bookingSuccessMessage =>
      'बुकिंग अनुरोध श्रमिक को भेजा गया। स्वीकार होने पर आपको सूचना मिलेगी।';

  @override
  String get bookingViewMyJobs => 'मेरी नौकरियों में देखें';

  @override
  String get bookingReturnHome => 'ग्राहक हब पर लौटें';

  @override
  String get recurringManageTitle => 'दोहराई जाने वाली सेवाएं';

  @override
  String get recurringNoBookings =>
      'कोई सक्रिय दोहराई जाने वाली बुकिंग नहीं मिली।';

  @override
  String get recurringPause => 'अनुसूची रोकें';

  @override
  String get recurringResume => 'अनुसूची फिर से शुरू करें';

  @override
  String get recurringCancel => 'अनुसूची रद्द करें';

  @override
  String get recurringSkipDate => 'अगली तारीख छोड़ें';

  @override
  String get recurringDateSkipped => 'अगली निर्धारित सेवा छोड़ दी गई।';

  @override
  String get recurringStatusActive => 'सक्रिय';

  @override
  String get recurringStatusPaused => 'रोका गया';

  @override
  String get recurringStatusCancelled => 'रद्द किया गया';

  @override
  String get demoModeBadge => 'डेमो मोड';

  @override
  String get timelineTitle => 'कार्य प्रगति समयरेखा';

  @override
  String get timelineLiveDot => 'लाइव';

  @override
  String get timelineDisputeActive => 'विवाद समीक्षाधीन है';

  @override
  String get timelineDisputeSub => 'मध्यस्थता टीम साक्ष्यों की जांच कर रही है।';

  @override
  String get timelineCurrentBadge => 'वर्तमान';

  @override
  String get stageRequestCreated => 'अनुरोध बनाया गया';

  @override
  String get stageAccepted => 'स्वीकृत';

  @override
  String get stageTicketIssued => 'टिकट जारी किया गया';

  @override
  String get stageWorkerArrived => 'श्रमिक पहुंच गए';

  @override
  String get stageVerificationCompleted => 'सत्यापन पूर्ण हुआ';

  @override
  String get stageJobInProgress => 'कार्य प्रगति पर है';

  @override
  String get stageCompleted => 'पूर्ण हुआ';

  @override
  String get stagePaymentReleased => 'भुगतान जारी किया गया';

  @override
  String get stageDisputeRaised => 'विवाद दर्ज किया गया';

  @override
  String get activeJobTitle => 'सक्रिय कार्य प्रगति';

  @override
  String get actionAcceptJob => 'कार्य स्वीकार करें';

  @override
  String get actionWorkerArrived => 'मैं पहुंच गया हूं';

  @override
  String get actionStartWork => 'काम शुरू करें';

  @override
  String get actionCompleteJob => 'काम पूरा करें';

  @override
  String get actionAwaitingPayment => 'भुगतान जारी होने की प्रतीक्षा';

  @override
  String get actionJobFinished => 'काम पूरी तरह समाप्त';

  @override
  String get actionDisputeMediation => 'विवाद समीक्षाधीन';

  @override
  String get actionWaitingAcceptance => 'श्रमिक की स्वीकृति की प्रतीक्षा';

  @override
  String get actionConfirmArrival => 'श्रमिक के आगमन की पुष्टि करें';

  @override
  String get actionConfirmCompletion => 'काम पूरा होने की पुष्टि करें';

  @override
  String get actionReleasePayment => 'भुगतान जारी करें';

  @override
  String get actionPaymentDone => 'भुगतान संपन्न';

  @override
  String get actionAskForHelp => 'मदद मांगें';

  @override
  String get actionDispute => 'विवाद दर्ज करें';

  @override
  String get simpleModeSpokenLabel => 'बोलने और निष्पादित करने के लिए टैप करें';

  @override
  String get routeAndEtaTitle => 'मार्ग और अनुमानित यात्रा समय';

  @override
  String get openInMapsBtn => 'मानचित्र में खोलें';

  @override
  String get demoModeChip => 'डेमो मोड';

  @override
  String get scheduleTitle => 'श्रमिक कार्यक्रम और यात्रा';

  @override
  String get scheduleDayView => 'दिन';

  @override
  String get scheduleWeekView => 'सप्ताह';

  @override
  String get scheduleWeeklyTotal => 'सप्ताह की अनुमानित कमाई';

  @override
  String get ticketScreenTitle => 'डिजिटल कार्य टिकट';

  @override
  String get refreshTicketTooltip => 'टिकट क्यूआर रीफ्रेश करें';

  @override
  String get ticketOfflineNotice =>
      'सुरक्षा टोकन रीफ्रेश करने के लिए इंटरनेट कनेक्शन आवश्यक है। कृपया नियोक्ता के स्कैन करने से पहले पुनः कनेक्ट करें।';

  @override
  String get ticketBookingPassHeader => 'बुकिंग पास';

  @override
  String get ticketScanInstructions =>
      'कार्यस्थल पर पहुंचने पर यह क्यूआर पास अपने नियोक्ता को दिखाएं';

  @override
  String get ticketAutoRefreshesIn => 'रीफ्रेश होगा';

  @override
  String get ticketReplayShieldTitle => 'रीप्ले सुरक्षा सक्षम';

  @override
  String get ticketReplayShieldBody =>
      'यह सुरक्षा पास एकल उपयोग है और हर 2 मिनट में बदलता है। स्क्रीनशॉट को दोबारा स्कैन नहीं किया जा सकता।';

  @override
  String get attendanceScannerTitle => 'श्रमिक क्यूआर स्कैन करें';

  @override
  String get attendanceScannerInstructions =>
      'उपस्थिति दर्ज करने के लिए श्रमिक के डिजिटल टिकट क्यूआर कोड को फ्रेम में रखें।';

  @override
  String get ticketReplayRefusedTitle => 'रीप्ले अस्वीकृत';

  @override
  String get ticketExpiredTitle => 'टिकट समाप्त हो गया';

  @override
  String get attendanceScanFailedTitle => 'उपस्थिति स्कैन विफल';

  @override
  String get attendanceConfirmedTitle => 'उपस्थिति की पुष्टि हो गई!';

  @override
  String get workerMarkedArrived =>
      'श्रमिक को कार्यस्थल पर पहुंचा हुआ चिन्हित किया गया';

  @override
  String get scanAgain => 'फिर से स्कैन करें';

  @override
  String get scanDone => 'पूर्ण';

  @override
  String get viewActiveJob => 'सक्रिय कार्य देखें';

  @override
  String get actionShowTicket => 'क्यूआर टिकट दिखाएं';

  @override
  String get actionScanWorkerQr => 'श्रमिक क्यूआर स्कैन करें';

  @override
  String get openSettings => 'सेटिंग्स खोलें';

  @override
  String get bookingCodeCopied => 'बुकिंग कोड क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get verifyYourPresence => 'अपनी उपस्थिति सत्यापित करें';

  @override
  String get verifyPresenceSubtitle =>
      'कार्य शुरू करने से पहले चेहरा मिलान और स्थान भू-बाड़ जांच आवश्यक है';

  @override
  String get gpsPerimeterCheck => 'जीपीएस कार्यस्थल सीमा जांच';

  @override
  String get withinPerimeter => 'कार्यस्थल सीमा के भीतर';

  @override
  String get outsidePerimeter => 'कार्यस्थल सीमा से बाहर';

  @override
  String distanceFromSite(String distance, String radius) {
    return 'कार्यस्थल से दूरी: $distanceमी (अनुमत: $radiusमी)';
  }

  @override
  String get mockLocationDetected =>
      'नकली / मॉक जीपीएस का पता चला। शुरुआत अस्वीकार की गई और जांच के लिए दर्ज की गई।';

  @override
  String get faceSelfieCheck => 'सामने कैमरे से चेहरा सत्यापन';

  @override
  String get takeSelfieBtn => 'सत्यापन सेल्फी लें';

  @override
  String get retakeSelfieBtn => 'फिर से सेल्फी लें';

  @override
  String get verifyAndStartJob => 'उपस्थिति सत्यापित करें और कार्य शुरू करें';

  @override
  String get verificationFailed => 'सत्यापन अस्वीकृत';

  @override
  String outOfGeofenceMessage(String distance, String radius) {
    return 'आप कार्यस्थल से $distanceमी दूर हैं। कार्य शुरू करने के लिए आपको $radiusमी के भीतर होना चाहिए।';
  }

  @override
  String get getHelpOrSupport => 'सहायता प्राप्त करें';

  @override
  String get completionTitle => 'कार्य पूर्णता और साक्ष्य';

  @override
  String get completionSubtitle =>
      'समाप्ति सत्यापित करने के लिए सेल्फी और कार्य की तस्वीरें जमा करें';

  @override
  String get workResultPhotos => 'कार्य प्रमाण तस्वीरें (निजी)';

  @override
  String get addWorkPhoto => 'तस्वीर जोड़ें';

  @override
  String get completeAndSubmit => 'पूर्णता जमा करें और टाइमर रोकें';

  @override
  String get midJobCheckTitle => 'मध्य-कार्य सत्यापन आवश्यक';

  @override
  String get midJobCheckSubtitle =>
      'उच्च मूल्य कार्य सुरक्षा जांच (वेतन >= ₹2,000)';

  @override
  String get midJobConfirmSelfie => 'मध्य-शिफ्ट सेल्फी लें';

  @override
  String get midJobCustomerConfirm => 'पुष्टि करें कि श्रमिक स्थल पर मौजूद है';

  @override
  String get timerTitle => 'लाइव कार्य टाइमर';

  @override
  String get timerRunning => 'टाइमर चल रहा है';

  @override
  String get timerPaused => 'टाइमर रुका हुआ है';

  @override
  String get elapsedTime => 'बीता हुआ समय';

  @override
  String get smartNoShowEngineHeader => 'स्मार्ट नो-शो रिकवरी इंजन';

  @override
  String get arrivalGraceExpiredAlert => '⚠️ आगमन रियायत अवधि समाप्त';

  @override
  String get workerHasNotArrivedTitle => 'श्रमिक नहीं पहुंचे हैं';

  @override
  String workerHasNotArrivedSubtitle(
    String workerName,
    int minutesLate,
    String jobTitle,
  ) {
    return '$workerName $jobTitle के लिए निर्धारित समय से $minutesLate मिनट देर से हैं।';
  }

  @override
  String get wait10MinutesAction => '10 मिनट प्रतीक्षा करें';

  @override
  String get callWorkerDirectlyAction => '📞 श्रमिक को सीधे कॉल करें';

  @override
  String get findSmartReplacementAction => '⚡ स्मार्ट प्रतिस्थापन श्रमिक खोजें';

  @override
  String get gracePeriodExtendedMsg =>
      '+10 मिनट प्रतीक्षा समय जोड़ा गया। टाइमर रोका गया।';

  @override
  String get maskedCallDemoMsg =>
      'श्रमिक को कॉल किया जा रहा है... (डेमो मोड: मास्क्ड कॉल P7.2 में आएगी)';

  @override
  String replacementBookedMsg(String workerName) {
    return '$workerName के साथ प्रतिस्थापन बुक किया गया! मूल को नो-शो चिह्नित किया गया।';
  }

  @override
  String get rankedReplacementsTitle => 'वरीयता प्राप्त नजदीकी श्रमिक';

  @override
  String get noReplacementsFoundMsg =>
      'अभी कोई नजदीकी प्रतिस्थापन श्रमिक उपलब्ध नहीं है।';

  @override
  String get requestReplacementOneTap => 'प्रतिस्थापन अनुरोध करें (1-टैप)';

  @override
  String get smartNoShowTrustNote =>
      'नो-शो पर शून्य-दंड रिफंड। प्रतिस्थापन श्रमिकों का बैकग्राउंड सत्यापित है।';

  @override
  String get openRecoveryEngineAction => 'नो-शो रिकवरी इंजन खोलें';

  @override
  String get runningLateQuestionAction => 'देरी हो रही है? ETA साझा करें';

  @override
  String runningLateReportedBadge(int minutes) {
    return 'देरी की सूचना दी गई (+$minutes मि)। टाइमर रोका गया।';
  }

  @override
  String get runningLateDialogTitle => 'देरी हो रही है?';

  @override
  String get runningLateDialogSubtitle =>
      'अपने आगमन में संभावित देरी चुनें। यह नियोक्ता को सूचित करेगा और ग्रेस टाइमर को एक बार रोकेगा।';

  @override
  String get sendEtaAction => 'ETA भेजें';

  @override
  String runningLateSuccessMsg(int minutes) {
    return '+$minutes मिनट की देरी की सूचना दी गई। नियोक्ता को सूचित किया गया।';
  }

  @override
  String get jobHistoryTitle => 'कार्य इतिहास और रेटिंग';

  @override
  String get jobHistoryHeader => 'कार्य इतिहास';

  @override
  String get favouritesTitle => 'पसंदीदा और विश्वास मंडल';

  @override
  String get rateJobTitle => 'कार्य को रेट और समीक्षा करें';

  @override
  String get quickTagsLabel => 'त्वरित टैग';

  @override
  String get reviewCommentLabel => 'प्रतिक्रिया और समीक्षा (वैकल्पिक)';

  @override
  String get reviewCommentHint =>
      'समुदाय की सहायता के लिए अपना अनुभव साझा करें...';

  @override
  String get submitReviewBtn => 'सत्यापित समीक्षा सबमिट करें';

  @override
  String get reportDisputeTitle => 'कार्य विवाद की रिपोर्ट करें';

  @override
  String get disputeFreezeNotice =>
      'विवाद दर्ज करने से एस्क्रो भुगतान रुक जाता है और ट्रस्ट टीम को समीक्षा के लिए भेजा जाता है।';

  @override
  String get disputeIssueTypeLabel => 'समस्या का प्रकार चुनें';

  @override
  String get disputeDetailsLabel => 'समस्या का विवरण और समय';

  @override
  String get disputeDetailsHint => 'कृपया स्पष्ट रूप से बताएं कि क्या हुआ...';

  @override
  String get disputeEvidenceLabel => 'सबूत तस्वीरें (वैकल्पिक)';

  @override
  String get submitDisputeBtn => 'औपचारिक विवाद दर्ज करें';

  @override
  String get disputeTypeNoShow => 'नहीं पहुंचे / अनुपस्थिति';

  @override
  String get disputeTypeIncompleteWork => 'अधूरा काम / जल्दी चले गए';

  @override
  String get disputeTypePoorQuality => 'खराब गुणवत्ता का काम';

  @override
  String get disputeTypeWrongProduct => 'गलत उत्पाद / गुणवत्ता बेमेल';

  @override
  String get disputeTypePaymentIssue => 'भुगतान समस्या / एस्क्रो विवाद';

  @override
  String get disputeTypeUnsafeConduct => 'असुरक्षित आचरण / दुर्व्यवहार';

  @override
  String get disputeTypeVerificationProblem => 'सत्यापन / पहचान बेमेल';

  @override
  String get disputeTrackingTitle => 'विवाद स्थिति ट्रैकिंग';

  @override
  String get settingsSectionHeader => 'सेटिंग्स';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterCompleted => 'पूर्ण';

  @override
  String get filterDisputed => 'विवादित';

  @override
  String get filterInProgress => 'प्रगति पर';

  @override
  String get filterCancelled => 'रद्द';

  @override
  String get walletTitle => 'वॉलेट और एस्क्रो';

  @override
  String get walletBalanceHeader => 'वॉलेट बैलेंस';

  @override
  String get escrowProtected => 'एस्क्रो सुरक्षित';

  @override
  String get todaysReleased => 'आज का जारी भुगतान';

  @override
  String get pendingEscrow => 'लंबित एस्क्रो';

  @override
  String get withdrawAction => 'निकासी';

  @override
  String get scanUpiQr => 'UPI QR स्कैन करें';

  @override
  String get recentTransactions => 'हाल के लेनदेन';

  @override
  String get withdrawEarningsTitle => 'कमाई निकालें';

  @override
  String get demoWithdrawNote =>
      'डेमो मोड: बैंकिंग भागीदार उपलब्ध होने तक सिम्युलेटेड भुगतान लेज़र डेबिट।';

  @override
  String get transferToUpi => 'स्थानांतरण (UPI VPA / बैंक)';

  @override
  String get confirmPayoutWithdrawal => 'निकासी की पुष्टि करें';

  @override
  String get demoPayoutCompleted => 'डेमो भुगतान पूरा हुआ';

  @override
  String get demoUpiScanner => 'डेमो मोड: सिम्युलेटेड UPI स्कैनर';

  @override
  String get demoUpiNote =>
      'कोई वास्तविक धन हस्तांतरित नहीं होगा। चरण 5.2 में भुगतान रेल जुड़ेगी।';

  @override
  String get noTransactionsFound => 'कोई लेन-देन नहीं मिला';

  @override
  String get noTransactionsSubtitle =>
      'पूरा हुआ दैनिक वेतन और स्थानांतरण यहां दिखाई देगा।';

  @override
  String get paymentTitle => 'भुगतान और एस्क्रो सुरक्षा';

  @override
  String get paymentBillSummary => 'बिल सारांश';

  @override
  String get paymentServiceWage => 'सेवा / मजदूरी राशि';

  @override
  String get paymentPlatformFee => 'प्लेटफ़ॉर्म शुल्क और जीएसटी';

  @override
  String get paymentProtectionAddon => 'सुरक्षा और बचाव ऐड-ऑन';

  @override
  String get paymentTotalPayable => 'कुल देय राशि';

  @override
  String get paymentEscrowNotice =>
      'सत्यापित कार्य पूरा होने तक सुरक्षित। धनराशि सुरक्षित एस्क्रो में रखी गई है।';

  @override
  String get paymentChooseMethod => 'भुगतान विधि चुनें';

  @override
  String get paymentUpi => 'यूपीआई (GPay / PhonePe / Paytm)';

  @override
  String get paymentCard => 'क्रेडिट / डेबिट कार्ड';

  @override
  String get paymentWallet => 'उद्योगसेतु वॉलेट';

  @override
  String get paymentCash => 'काम पूरा होने पर नकद';

  @override
  String get paymentPaySecurely => 'सुरक्षित भुगतान करें';

  @override
  String get paymentConfirmCash => 'नकद बुकिंग की पुष्टि करें';

  @override
  String get paymentStatus => 'भुगतान स्थिति';

  @override
  String get paymentSuccessful => 'भुगतान सफल और पुष्ट';

  @override
  String get paymentSuccessSubtitle =>
      'आपका भुगतान पुष्ट हो चुका है और एस्क्रो में सुरक्षित है।';

  @override
  String get paymentConfirmingBank => 'बैंक से पुष्टि की जा रही है...';

  @override
  String get paymentConfirmingSubtitle =>
      'रेज़रपे और बैंकिंग नेटवर्क से पुष्टि की प्रतीक्षा की जा रही है। स्क्रीन स्वचालित रूप से अपडेट होगी।';

  @override
  String get paymentFailed => 'भुगतान विफल';

  @override
  String get paymentFailedSubtitle =>
      'बैंक द्वारा आपका लेन-देन पूरा नहीं किया जा सका। कोई राशि नहीं काटी गई।';

  @override
  String get paymentReceiptNo => 'रसीद संख्या';

  @override
  String get paymentDownloadPdf => 'पीडीएफ रसीद साझा / डाउनलोड करें';

  @override
  String get paymentContinueJob => 'कार्य / ऑर्डर जारी रखें';

  @override
  String get paymentTryAgain => 'पुनः प्रयास करें';

  @override
  String get pendingEscrowRelease => 'एस्क्रो रिलीज लंबित';

  @override
  String get protectedBadge => 'सुरक्षित';

  @override
  String get releaseEscrowPayment => 'एस्क्रो भुगतान जारी करें';

  @override
  String get confirmAndRelease => 'पुष्टि करें और भुगतान जारी करें';

  @override
  String get workerPayout => 'श्रमिक भुगतान (उपलब्ध शेष राशि)';

  @override
  String get escrowAutoReleaseNotice =>
      'नियोक्ता द्वारा पुष्टि करने पर तुरंत, या विवाद न होने पर 24 घंटे में भुगतान अपने आप जारी हो जाएगा।';

  @override
  String get escrowEarningsSecured => 'आपकी कमाई एस्क्रो में 100% सुरक्षित है';

  @override
  String get releaseEscrowSuccess =>
      'भुगतान सफलतापूर्वक श्रमिक के वॉलेट में जारी किया गया!';

  @override
  String get earningsDashboardTitle => 'कमाई और प्रदर्शन';

  @override
  String get earningsToday => 'आज की कमाई';

  @override
  String get earningsThisWeek => 'इस सप्ताह';

  @override
  String get earningsThisMonth => 'इस महीने';

  @override
  String get earningsTotal => 'कुल जीवनकाल कमाई';

  @override
  String get earningsCompletedJobs => 'पूर्ण किए गए कार्य';

  @override
  String get earningsFarmOrders => 'कृषि ऑर्डर';

  @override
  String get earningsAverageRating => 'औसत रेटिंग';

  @override
  String get earningsDailyGoal => 'दैनिक लक्ष्य';

  @override
  String get earningsDailyGoalProgress => 'आज के लक्ष्य की प्रगति';

  @override
  String get earningsPayoutTrends => 'भुगतान रुझान';

  @override
  String get earningsTimeframe14Days => '14 दिन';

  @override
  String get earningsTimeframe6Months => '6 महीने';

  @override
  String get earningsBestDayTitle => 'सर्वश्रेष्ठ कमाई का दिन';

  @override
  String earningsBestDaySubtitle(Object amount, Object date) {
    return 'आपने $date को $amount कमाए!';
  }

  @override
  String get earningsSetDailyGoal => 'दैनिक लक्ष्य सेट करें';

  @override
  String get earningsSaveGoal => 'लक्ष्य सहेजें';

  @override
  String get savingsGoalsTitle => 'बचत लक्ष्य योजनाकार';

  @override
  String get savingsGoalsSubtitle =>
      'सपनों को ट्रैक करें। लक्ष्य आभासी हैं और आपका पैसा लॉक नहीं करते।';

  @override
  String get savingsGoalsVirtualNotice =>
      'आभासी लक्ष्य ट्रैकर: लक्ष्य आपके बजट की योजना बनाने में मदद करते हैं। आपका पैसा हमेशा वॉलेट में उपलब्ध रहता है।';

  @override
  String get savingsGoalNew => 'नया बचत लक्ष्य';

  @override
  String get savingsGoalCreate => 'बचत लक्ष्य बनाएं';

  @override
  String get savingsGoalTarget => 'लक्ष्य राशि';

  @override
  String get savingsGoalSaved => 'अब तक की बचत';

  @override
  String get savingsGoalDeadline => 'अंतिम तिथि';

  @override
  String get savingsGoalCategory => 'श्रेणी';

  @override
  String get savingsGoalSuggestedPlan => 'सुझाई गई बचत योजना';

  @override
  String get savingsGoalAddSavings => 'बचत प्रगति दर्ज करें';

  @override
  String get savingsGoalAddAmount => 'बचत राशि';

  @override
  String get savingsGoalCompletedBadge => 'लक्ष्य पूरा हुआ! 🎉';

  @override
  String get savingsGoalActiveBadge => 'प्रगति पर है';

  @override
  String get savingsGoalCategorySchoolFees => 'स्कूल की फीस';

  @override
  String get savingsGoalCategoryEquipment => 'काम के उपकरण';

  @override
  String get savingsGoalCategoryScooter => 'स्कूटर / वाहन';

  @override
  String get savingsGoalCategorySeeds => 'बीज और खाद';

  @override
  String get savingsGoalCategoryEmergency => 'आपातकालीन फंड';

  @override
  String get savingsGoalCategoryHome => 'घर की मरम्मत';

  @override
  String get savingsGoalCategoryCustom => 'कस्टम लक्ष्य';

  @override
  String get savingsGoalDelete => 'लक्ष्य हटाएं';

  @override
  String get savingsGoalDeleteConfirm =>
      'क्या आप इस बचत लक्ष्य को हटाना चाहते हैं?';

  @override
  String get savingsGoalEmptyState =>
      'बचत लक्ष्य निर्धारित करके अपना अगला पड़ाव प्लान करें।';

  @override
  String get savingsGoalsPlanGoals => 'लक्ष्य प्लान करें';

  @override
  String get farmerWorkspace => 'किसान कार्यस्थल';

  @override
  String get farmerEmpoweredNetwork =>
      'उद्योगसेतु डायरेक्ट एग्री-नेटवर्क द्वारा संचालित';

  @override
  String get farmerProduceSold => 'बेची गई उपज';

  @override
  String get farmerThisMonth => 'इस महीने';

  @override
  String get farmerDirectEarnings => 'सीधी कमाई';

  @override
  String get farmerZeroMiddlemen => 'बिना बिचौलियों के';

  @override
  String get farmerActiveLabor => 'सक्रिय मजदूर';

  @override
  String get farmerHarvestShiftPlaceholder => 'कटाई शिफ्ट (P6.3)';

  @override
  String farmerBooked(int count) {
    return '$count बुक किए गए';
  }

  @override
  String get farmerWeatherAdvisoryRadar => 'मौसम परामर्श रडार';

  @override
  String get farmerSimulatedForecast => 'सिम्युलेटेड पूर्वानुमान';

  @override
  String farmerRainProbability(int percent) {
    return '$percent% बारिश की संभावना';
  }

  @override
  String get farmerBookHarvestHelpers => 'कटाई मजदूर बुक करें';

  @override
  String get farmerViewIrrigationGuide => 'सिंचाई गाइड देखें';

  @override
  String get farmerLiveMandiPrices => 'लाइव मंडी भाव व मांग';

  @override
  String get farmerLiveFeed => 'लाइव फीड';

  @override
  String get farmerAllCrops => 'सभी फसलें';

  @override
  String get farmerVegetables => 'सब्जियां';

  @override
  String get farmerGrainsAndPulses => 'अनाज और दालें';

  @override
  String get farmerNoPricesInCategory => 'इस श्रेणी में कोई मंडी भाव नहीं है';

  @override
  String get farmerSelectAllCropsHint =>
      'कर्नाटक APMC के सभी भाव देखने के लिए \"सभी फसलें\" चुनें।';

  @override
  String farmerUpdatedDate(String date) {
    return 'अपडेट किया गया $date';
  }

  @override
  String get farmerApmcKarnatakaFeed => 'कर्नाटक APMC फीड';

  @override
  String get farmerEssentialSuite => 'किसान जरूरी सुविधाएं';

  @override
  String get farmerRentTractor => 'ट्रैक्टर किराए पर लें';

  @override
  String get farmerHireWorkers => 'मजदूर बुलाएं';

  @override
  String get farmerSoilAiTest => 'मिट्टी AI जांच';

  @override
  String get farmerSellProduce => 'उपज बेचें';

  @override
  String get farmerPestAiDoc => 'कीट AI डॉक्टर';

  @override
  String get farmerGovtSchemes => 'सरकारी योजनाएं';

  @override
  String get farmerAgriDrone => 'एग्री ड्रोन';

  @override
  String get farmerIrrigationAi => 'सिंचाई AI';

  @override
  String farmerComingInPhase(String phase) {
    return '$phase में उपलब्ध होगा';
  }

  @override
  String get farmerUnderstood => 'समझ गया';

  @override
  String get farmerGotIt => 'ठीक है';

  @override
  String get farmerHireWorkersDesc =>
      'किसान अपने खाते से सीधे कृषि मजदूरी की मांग पोस्ट कर सकेंगे और सत्यापित कामगारों को बुला सकेंगे।';

  @override
  String get farmerRentTractorDesc =>
      'नजदीकी कृषि केंद्रों से ट्रैक्टर और कटाई मशीनें किराए पर बुक करें।';

  @override
  String get farmerSoilAiTestDesc =>
      'मिट्टी जांच रिपोर्ट अपलोड करें और तुरंत खाद की AI सिफारिशें पाएं।';

  @override
  String get farmerSellProduceDesc =>
      'बिना बिचौलियों के सीधे थोक खरीदारों को अपनी फसल बेचें।';

  @override
  String get farmerPestAiDocDesc =>
      'कीट व बीमारी की तस्वीर खींचकर तुरंत AI उपचार पाएं।';

  @override
  String get farmerGovtSchemesDesc =>
      'पीएम-किसान, सौर पंप और फसल बीमा योजनाओं की जानकारी लें।';

  @override
  String get farmerAgriDroneDesc =>
      'स्प्रे के लिए प्रमाणित एग्री-ड्रोन पायलट बुक करें।';

  @override
  String get farmerIrrigationAiDesc =>
      'मौसम व नमी के आधार पर स्मार्ट सिंचाई योजना।';

  @override
  String get farmerHomeTitle => 'किसान होम';

  @override
  String get farmerSimulateRainDev => 'बारिश पूर्वानुमान सिमुलेशन (डेव)';

  @override
  String get farmerFailedLoadMandi => 'मंडी भाव लोड करने में विफल';

  @override
  String get farmerHighDemand => 'उच्च मांग';

  @override
  String get farmerStable => 'स्थिर';

  @override
  String get farmerFrpGuaranteed => 'FRP गारंटीकृत';

  @override
  String get farmerMspProtected => 'MSP संरक्षित';

  @override
  String get farmerOversupply => 'अत्यधिक आवक';

  @override
  String get farmerModerate => 'सामान्य';

  @override
  String get farmerProfileTitle => 'किसान प्रोफ़ाइल';

  @override
  String get verifiedFarmer => 'सत्यापित किसान ✓';

  @override
  String get organicLand => 'जैविक भूमि';

  @override
  String get soldThisMonth => 'इस महीने की बिक्री';

  @override
  String get directSales => 'प्रत्यक्ष बिक्री';

  @override
  String get farmInfrastructureAndBadges => 'कृषि अवसंरचना एवं फसल बैज';

  @override
  String get soilClassification => 'मृदा वर्गीकरण';

  @override
  String get primaryCrops => 'प्रमुख फसलें';

  @override
  String get apmcRegistration => 'एपीएमसी पंजीकरण';

  @override
  String get kisanCreditCard => 'किसान क्रेडिट कार्ड';

  @override
  String get zeroPesticideOrganicCertificate =>
      'शून्य कीटनाशक जैविक प्रमाणपत्र';

  @override
  String get verifiedByKarnatakaOrganicBoard =>
      'कर्नाटक जैविक किसान बोर्ड द्वारा सत्यापित';

  @override
  String get validatedStatus => 'सत्यापित ✓';

  @override
  String get underReviewStatus => 'समीक्षाधीन';

  @override
  String get languageMode => 'भाषा मोड';

  @override
  String get manageProduceListings => 'उपज सूची प्रबंधित करें';

  @override
  String get produceListingsTitle => 'कृषि उपज सूची';

  @override
  String get addNewProduce => 'नई उपज जोड़ें';

  @override
  String get editProduceListing => 'उपज सूची संपादित करें';

  @override
  String get produceName => 'उपज का नाम';

  @override
  String get category => 'श्रेणी';

  @override
  String pricePerUnit(String unit) {
    return 'प्रति $unit मूल्य';
  }

  @override
  String get stockQuantity => 'स्टॉक मात्रा';

  @override
  String get unit => 'इकाई';

  @override
  String get harvestDate => 'कटाई की तारीख';

  @override
  String get qualityNotes => 'गुणवत्ता विवरण';

  @override
  String get farmingMethod => 'खेती की विधि';

  @override
  String get deliveryAvailable => 'डिलीवरी उपलब्ध';

  @override
  String get pickupAvailable => 'खेत से पिकअप उपलब्ध';

  @override
  String get availabilityMode => 'उपलब्धता मोड';

  @override
  String get sameDayDelivery => 'उसी दिन डिलीवरी';

  @override
  String get nextDayDelivery => 'अगले दिन डिलीवरी';

  @override
  String get harvestPreOrder => 'फसल पूर्व-ऑर्डर';

  @override
  String get farmerSetsFinalPrice => 'किसान हमेशा अंतिम मूल्य तय करता है';

  @override
  String get statusLowStock => 'कम स्टॉक';

  @override
  String get statusSoldOut => 'बिक चुका है';

  @override
  String get statusPaused => 'रोका गया';

  @override
  String get pauseListing => 'रोकें';

  @override
  String get activateListing => 'सक्रिय करें';

  @override
  String get updateStock => 'स्टॉक अपडेट करें';

  @override
  String stockInStock(String stock) {
    return '$stock स्टॉक में उपलब्ध';
  }

  @override
  String get buyerProduceMarket => 'ताज़ा खेत उपज';

  @override
  String get buyerSearchProduceHint =>
      'ताज़ा खेत उपज खोजें (जैसे टमाटर, चावल)...';

  @override
  String get noProduceAvailable => 'कोई उपज उपलब्ध नहीं है';

  @override
  String get orderDirect => 'सीधा ऑर्डर करें';

  @override
  String get uploadProducePhotos => 'फसल फोटो (produce-images)';

  @override
  String get addPhoto => 'फोटो जोड़ें';

  @override
  String get farmerMapHeader =>
      'किसानों के लिए आवश्यक उत्पाद, बीज, मशीनरी और सेवाएं';

  @override
  String get farmerNearbyRentals => 'पास के उपकरण और ड्रोन किराए पर';

  @override
  String get farmerEscrowGuaranteed => 'एस्क्रो गारंटीकृत';

  @override
  String get farmerBookNow => 'अभी बुक करें';

  @override
  String get farmerBookItem => 'आइटम बुक करें';

  @override
  String get farmerViewAllEquipmentMap => 'सभी कृषि संसाधन और लाइव मैप देखें →';

  @override
  String get farmerEquipmentBooked => 'उपकरण बुक हो गया!';

  @override
  String get farmerBookingQuantity => 'बुकिंग अवधि / मात्रा';

  @override
  String get farmerDeliveryAddress => 'खेत वितरण / कार्य स्थल का पता';

  @override
  String get farmerSpecialNotes => 'कार्य निर्देश / फसल नोट्स (वैकल्पिक)';

  @override
  String get farmerVendorHubTitle => 'उपकरण और मशीनरी वेंडर हब';

  @override
  String get farmerAddEquipment => 'उपकरण जोड़ें';
}
