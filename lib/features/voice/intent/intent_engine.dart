import 'package:udyogasethu/features/voice/domain/voice_intent.dart';

/// Pure Dart, 100% offline intent parser supporting Kannada, Hindi, Telugu, Tamil, and English.
class IntentEngine {
  /// Category keywords mapping across languages
  static const Map<String, List<String>> categoryKeywords = {
    'plumber': [
      'plumber', 'plumbing', 'pipe', 'tap', 'leakage',
      'ಪ್ಲಂಬರ್', 'ಕೊಳವೆ', 'ನಲ್ಲಿ', 'ನೀರಿನ ಪೈಪ್',
      'प्लंबर', 'प्लम्बर', 'नल', 'पाइप', 'पानी का पाइप',
      'ప్లంబర్', 'పైపు', 'నల్లా',
      'பிளம்பர்', 'குழாய்', 'தண்ணீர் குழாய்',
    ],
    'electrician': [
      'electrician', 'electrical', 'wire', 'wiring', 'switch', 'current',
      'ಎಲೆಕ್ಟ್ರಿಷಿಯನ್', 'ವೈರಿಂಗ್', 'ವಿದ್ಯುತ್', 'ಕರೆಂಟ್',
      'इलेक्ट्रीशियन', 'बिजली', 'वायरिंग', 'करंट',
      'ఎలక్ట్రీషియన్', 'వైరింగ్', 'కరెంట్', 'విద్యుత్',
      'எலக்ட்ரீஷியன்', 'மின்சாரம்', 'வயரிங்',
    ],
    'carpenter': [
      'carpenter', 'wood', 'furniture', 'door', 'table',
      'ಬಡಗಿ', 'ಮರಗೆಲಸ', 'ಪೀಠೋಪಕರಣ', 'ಕಾರ್ಪೆಂಟರ್',
      'बढ़ई', 'कारपेंटर', 'लकड़ी', 'फर्नीचर',
      'వడ్రంగి', 'కార్పెంటర్', 'చెక్క పని',
      'தச்சர்', 'மரவேலை', 'கார்பெண்டர்',
    ],
    'construction': [
      'construction', 'mason', 'helper', 'building', 'brick', 'cement',
      'ಕಟ್ಟಡ', 'ಮೇಸ್ತ್ರಿ', 'ನಿರ್ಮಾಣ', 'ಹೆಲ್ಪರ್', 'ಗಾರೆ ಕೆಲಸ',
      'निर्माण', 'मिस्त्री', 'मजदूर', 'हेल्पर', 'भवन',
      'నిర్మాణం', 'మేస్త్రీ', 'హెల్పర్', 'భవనం',
      'கட்டுமானம்', 'மேஸ்திரி', 'ஹெல்ப்பர்', 'கட்டிட வேலை',
    ],
    'painter': [
      'painter', 'painting', 'wall paint', 'color',
      'ಪೇಂಟರ್', 'ಬಣ್ಣ ಬಳಿಯುವುದು', 'ಬಣ್ಣ',
      'पेंटर', 'रंगाई', 'पुताई', 'पेंटिंग',
      'పెయింటర్', 'రంగులు', 'పెయింటింగ్',
      'பெயிண்டர்', 'வண்ணம்', 'பெயிண்டிங்',
    ],
    'driver': [
      'driver', 'driving', 'car driver', 'auto', 'cab',
      'ಡ್ರೈವರ್', 'ಚಾಲಕ', 'ಕಾರು ಡ್ರೈವರ್',
      'ड्राइवर', 'चालक', 'गाड़ी चालक',
      'డ్రైవర్', 'వాహన డ్రైవర్',
      'டிரைவர்', 'ஓட்டுநர்',
    ],
    'cleaner': [
      'cleaner', 'cleaning', 'house cleaning', 'sweep',
      'ಸ್ವಚ್ಛತೆ', 'ಕ್ಲೀನರ್', 'ಮನೆ ಸ್ವಚ್ಛ',
      'सफाई', 'क्लीनर', 'सफाई कर्मचारी',
      'క్లీనర్', 'శుభ్రం',
      'துப்புரவு', 'சுத்தம் செய்பவர்', 'கிளீனர்',
    ],
    'agri_labour': [
      'farm', 'farmer', 'harvest', 'agriculture', 'field worker', 'agri',
      'ಕೃಷಿ ಕೆಲಸ', 'ರೈತ ಕೆಲಸ', 'ಕೂಲಿ', 'ಕೊಯ್ಲು',
      'खेती', 'मजदूरी', 'कृषि', 'कटाई',
      'వ్యవసాయం', 'కూలీ', 'కోత పని',
      'விவசாயம்', 'கூலி வேலை', 'அறுவடை',
    ],
    'delivery': [
      'delivery', 'courier', 'parcel',
      'ಡೆಲಿವರಿ', 'ಪಾರ್ಸೆಲ್',
      'डिलीवरी', 'पार्सल',
      'డెలివరీ', 'పార్శిల్',
      'டெலிவரி', 'பார்சல்',
    ],
    'domestic_help': [
      'maid', 'cook', 'domestic', 'house help',
      'ಮನೆಕೆಲಸ', 'ಅಡುಗೆ',
      'कामवाली', 'रसोइया', 'घरेलू काम',
      'ఇంటి పని', 'వంట మనిషి',
      'வீட்டு வேலை', 'சமையல்காரர்',
    ],
  };

  /// Commodity keywords mapping
  static const Map<String, List<String>> produceKeywords = {
    'tomato': ['tomato', 'tomatoes', 'ಟೊಮೆಟೊ', 'ಟೊಮೇಟೊ', 'ಟೊಮಾಟೊ', 'टमाटर', 'టమోటా', 'టమోటాలు', 'தக்காளி'],
    'onion': ['onion', 'onions', 'ಈರುಳ್ಳಿ', 'ಉಳ್ಳಾಗಡ್ಡಿ', 'प्याज', 'ఉల్లిపాయ', 'ఉల్లిపాయలు', 'வெங்காயம்'],
    'potato': ['potato', 'potatoes', 'ಆಲೂಗಡ್ಡೆ', 'ಆಲೂಗೆಡ್ಡೆ', 'ಆಲೂ', 'आलू', 'బంగాళాదుంప', 'బంగాళదుంప', 'உருளைக்கிழங்கு'],
    'chilli': ['chilli', 'chili', 'ಮೆಣಸಿನಕಾಯಿ', 'ಮೆಣಸು', 'मिर्च', 'మిర్చి', 'మిరపకాయ', 'மிளகாய்'],
    'rice': ['rice', 'paddy', 'ಅಕ್ಕಿ', 'ಭತ್ತ', 'चावल', 'धान', 'వరి', 'బియ్యం', 'அரிசி', 'நெல்'],
    'milk': ['milk', 'dairy', 'ಹಾಲು', 'ಹಾಲಿನ ಉತ್ಪನ್ನ', 'दूध', 'పాలు', 'பால்'],
    'banana': ['banana', 'ಬಾಳೆಹಣ್ಣು', 'ಬಾಳೆ', 'केला', 'అరటిపండు', 'వాళైప్పళం', 'வாழைப்பழம்'],
    'mango': ['mango', 'ಮಾವಿನಹಣ್ಣು', 'ಮಾವು', 'आम', 'మామిడిపండు', 'மாம்பழம்'],
  };

  /// Match spoken text to a [VoiceIntentResult]
  static VoiceIntentResult parse(String text, {String language = 'en', String? userRole}) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return VoiceIntentResult.unrecognized(text, customReply: _getEmptySpeechReply(language));
    }

    // 1. Check Earnings
    if (_matchesEarnings(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.checkEarnings,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/wallet',
        spokenReply: _getReply(VoiceIntentType.checkEarnings, language),
      );
    }

    // 2. Open Wallet
    if (_matchesWallet(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.openWallet,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/wallet',
        spokenReply: _getReply(VoiceIntentType.openWallet, language),
      );
    }

    // 2.1 Farm AI / Crop Doctor / Pest diagnosis
    if (_matchesFarmAi(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.farmAi,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/farmer/pest-ai',
        spokenReply: _getReply(VoiceIntentType.farmAi, language),
      );
    }

    // 3. Open Safety / SOS
    if (_matchesSafety(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.openSafety,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/safety/hub',
        spokenReply: _getReply(VoiceIntentType.openSafety, language),
      );
    }

    // 3.1 Digital ID / QR Ticket
    if (_matchesDigitalId(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.digitalId,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/trust/digital-id',
        spokenReply: _getReply(VoiceIntentType.digitalId, language),
      );
    }

    // 3.2 Scan QR / Attendance Scanner
    if (_matchesScanQr(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.scanVerify,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/trust/scan-verify',
        spokenReply: _getReply(VoiceIntentType.scanVerify, language),
      );
    }

    // 4. Open Settings
    if (_matchesSettings(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.openSettings,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/settings',
        spokenReply: _getReply(VoiceIntentType.openSettings, language),
      );
    }

    // 4.1. Open Profile
    if (_matchesProfile(normalized)) {
      final target = userRole == 'provider'
          ? '/provider/profile'
          : userRole == 'farmer'
              ? '/farmer/profile'
              : '/seeker/profile';
      return VoiceIntentResult(
        type: VoiceIntentType.openProfile,
        rawText: text,
        confidence: 0.95,
        targetRoute: target,
        spokenReply: _getReply(VoiceIntentType.openProfile, language),
      );
    }

    // 4.2 Post a Job
    if (_matchesPostJob(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.postJob,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/provider/jobs/new',
        spokenReply: _getReply(VoiceIntentType.postJob, language),
      );
    }

    // 4.3 Mandi Prices / APMC
    if (_matchesMandi(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.checkMandi,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/farmer/market',
        spokenReply: _getReply(VoiceIntentType.checkMandi, language),
      );
    }

    // 4.4 Active Jobs & My Jobs
    if (_matchesActiveJobs(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.viewActiveJobs,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/seeker/jobs',
        spokenReply: _getReply(VoiceIntentType.viewActiveJobs, language),
      );
    }

    // 4.5 Schedule & Timetable
    if (_matchesSchedule(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.viewSchedule,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/seeker/schedule',
        spokenReply: _getReply(VoiceIntentType.viewSchedule, language),
      );
    }

    // 4.6 Chat & Messages
    if (_matchesChat(normalized)) {
      final target = userRole == 'provider'
          ? '/provider/chat'
          : userRole == 'farmer'
              ? '/farmer/chat'
              : '/seeker/chat';
      return VoiceIntentResult(
        type: VoiceIntentType.openChat,
        rawText: text,
        confidence: 0.95,
        targetRoute: target,
        spokenReply: _getReply(VoiceIntentType.openChat, language),
      );
    }

    // 4.7 Notifications
    if (_matchesNotifications(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.openNotifications,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/notifications',
        spokenReply: _getReply(VoiceIntentType.openNotifications, language),
      );
    }

    // 4.8 Home Dashboard
    if (_matchesHome(normalized)) {
      final target = userRole == 'provider'
          ? '/provider/home'
          : userRole == 'farmer'
              ? '/farmer/home'
              : '/seeker/home';
      return VoiceIntentResult(
        type: VoiceIntentType.goHome,
        rawText: text,
        confidence: 0.95,
        targetRoute: target,
        spokenReply: _getReply(VoiceIntentType.goHome, language),
      );
    }

    // 4.9 Favourites
    if (_matchesFavourites(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.viewFavourites,
        rawText: text,
        confidence: 0.95,
        targetRoute: '/favourites',
        spokenReply: _getReply(VoiceIntentType.viewFavourites, language),
      );
    }

    // 5. View Orders / Order status
    if (_matchesOrders(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.viewOrders,
        rawText: text,
        confidence: 0.92,
        targetRoute: '/marketplace',
        spokenReply: _getReply(VoiceIntentType.viewOrders, language),
      );
    }

    // 6. Search Produce / Farmers
    final detectedProduce = _extractProduce(normalized);
    if (_matchesProduce(normalized) || detectedProduce != null) {
      final route = detectedProduce != null ? '/marketplace?search=$detectedProduce' : '/marketplace';
      return VoiceIntentResult(
        type: VoiceIntentType.searchProduce,
        rawText: text,
        confidence: 0.90,
        parameters: VoiceIntentParameters(produce: detectedProduce, query: detectedProduce),
        targetRoute: route,
        spokenReply: _getReply(VoiceIntentType.searchProduce, language, detail: detectedProduce),
      );
    }

    // 7. Find Jobs (worker looking for jobs / daily wage)
    final detectedCategory = _extractCategory(normalized);
    if (_matchesJobs(normalized)) {
      final categoryParam = detectedCategory ?? '';
      final route = categoryParam.isNotEmpty ? '/jobs?category=$categoryParam' : '/jobs';
      return VoiceIntentResult(
        type: VoiceIntentType.findJobs,
        rawText: text,
        confidence: 0.92,
        parameters: VoiceIntentParameters(
          category: detectedCategory,
          query: detectedCategory,
          minPrice: _extractPrice(normalized),
          radiusKm: _extractDistance(normalized),
        ),
        targetRoute: route,
        spokenReply: _getReply(VoiceIntentType.findJobs, language, detail: detectedCategory),
      );
    }

    // 8. Find Nearby Workers by Category (employer/customer hiring)
    if (_matchesWorkers(normalized) || (_containsWorkerIntent(normalized) && detectedCategory != null)) {
      final categoryParam = detectedCategory ?? 'all';
      final route = '/provider/workers?category=$categoryParam';
      return VoiceIntentResult(
        type: VoiceIntentType.findWorkers,
        rawText: text,
        confidence: 0.92,
        parameters: VoiceIntentParameters(category: detectedCategory),
        targetRoute: route,
        spokenReply: _getReply(VoiceIntentType.findWorkers, language, detail: detectedCategory),
      );
    }

    // Fallback category detection defaults to jobs
    if (detectedCategory != null) {
      return VoiceIntentResult(
        type: VoiceIntentType.findJobs,
        rawText: text,
        confidence: 0.88,
        parameters: VoiceIntentParameters(category: detectedCategory, query: detectedCategory),
        targetRoute: '/jobs?category=$detectedCategory',
        spokenReply: _getReply(VoiceIntentType.findJobs, language, detail: detectedCategory),
      );
    }

    // Unrecognized command
    return VoiceIntentResult.unrecognized(text, customReply: _getUnrecognizedReply(language));
  }

  // Helper matching methods
  static bool _matchesEarnings(String text) {
    const triggers = [
      'earnings', 'earning', 'income', 'daily income', 'today earnings', 'how much i earned',
      'ಗಳಿಕೆ', 'ಆದಾಯ', 'ಇಂದಿನ ಗಳಿಕೆ', 'ಎಷ್ಟು ಗಳಿಸಿದ್ದೇನೆ', 'ಸಂಪಾದನೆ',
      'कमाई', 'आमदनी', 'आज की कमाई', 'कितना कमाया', 'इनकम',
      'సంపాదన', 'ఆదాయం', 'ఈ రోజు సంపాదన', 'ఎంత వచ్చింది',
      'வருமானம்', 'சம்பாத்தியம்', 'இன்றைய வருமானம்', 'எவ்வளவு சம்பாதித்தேன்',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesWallet(String text) {
    const triggers = [
      'wallet', 'balance', 'my balance', 'open wallet', 'check balance', 'passbook',
      'ವಾಲೆಟ್', 'ಬ್ಯಾಲೆನ್ಸ್', 'ಖಾತೆ ಬ್ಯಾಲೆನ್ಸ್', 'ಪರ್ಸ್',
      'वॉलेट', 'बैलेंस', 'खाता', 'पर्स',
      'వాలెట్', 'బ్యాలెన్స్', 'నా బ్యాలెన్స్',
      'வாலட்', 'இருப்பு', 'பேலன்ஸ்',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesSafety(String text) {
    const triggers = [
      'safety', 'sos', 'emergency', 'help me', 'danger', 'police', 'support', 'protection',
      'ಸುರಕ್ಷತೆ', 'ತುರ್ತು', 'ಸಹಾಯ', 'ಎಸ್ಒಎಸ್', 'ಅಪಾಯ', 'ಭದ್ರತೆ',
      'सुरक्षा', 'आपातकाल', 'मदद', 'एसओएस', 'खतरा', 'सपोर्ट',
      'భద్రత', 'రక్షణ', 'సహాయం', 'అత్యవసరం', 'ఆపద',
      'பாதுகாப்பு', 'அவசரம்', 'உதவி', 'ஆபத்து', 'எஸ்ஓஎஸ்',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesSettings(String text) {
    const triggers = [
      'settings', 'setting', 'preferences', 'change language', 'profile settings', 'account settings',
      'ಸೆಟ್ಟಿಂಗ್ಸ್', 'ಸೆಟ್ಟಿಂಗ್', 'ಭಾಷೆ ಬದಲಾಯಿಸಿ', 'ಖಾತೆ ಸೆಟ್ಟಿಂಗ್',
      'सेटिंग्स', 'सेटिंग', 'भाषा बदलो', 'सेटिंग खोलो',
      'సెట్టింగులు', 'భాష మార్చు', 'సెట్టింగ్స్',
      'அமைப்புகள்', 'மொழி மாற்று', 'செட்டிங்ஸ்',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesProfile(String text) {
    const triggers = [
      'profile', 'my profile', 'account', 'my account',
      'ಪ್ರೊಫೈಲ್', 'ನನ್ನ ಪ್ರೊಫೈಲ್', 'ಖಾತೆ', 'ನನ್ನ ಖಾತೆ',
      'प्रोफाइल', 'मेरी प्रोफाइल', 'खाता', 'मेरा खाता',
      'ప్రొఫైల్', 'నా ప్రొఫైల్', 'ఖాతా',
      'சுயவிவரம்', 'என் சுயவிவரம்', 'கணக்கு',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesFarmAi(String text) {
    const triggers = [
      'crop problem', 'diagnose', 'crop doctor', 'pest problem', 'soil test', 'plant disease',
      'ಬೆಳೆ ರೋಗ', 'ಕೀಟ', 'ಬೆಳೆ ಸಮಸ್ಯೆ',
      'फसल', 'कीट', 'फसल बीमारी',
      'పంట సమస్య', 'తెగుళ్లు',
      'பயிர் நோய்', 'பூச்சி',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesDigitalId(String text) {
    const triggers = [
      'digital id', 'attendance qr', 'my id card',
      'ಡಿಜಿಟಲ್ ಐಡಿ', 'ಹಾಜರಾತಿ ಕ್ಯೂಆರ್',
      'डिजिटल पहचान', 'डिजिटल आईडी',
      'డిజిటల్ ఐడి',
      'டிஜிட்டல் ஐடி',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesScanQr(String text) {
    const triggers = [
      'scan qr', 'scan qr code', 'attendance scanner', 'scan code',
      'ಕ್ಯೂಆರ್ ಸ್ಕ್ಯಾನ್', 'ಕೋಡ್ ಸ್ಕ್ಯಾನ್',
      'क्यूआर स्कैन', 'स्कैन करो',
      'క్యూఆర్ స్కాన్',
      'ஸ்கேன்',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesPostJob(String text) {
    const triggers = [
      'post a new job', 'post a job', 'post job', 'post new job',
      'ಕೆಲಸ ಪೋಸ್ಟ್', 'ಹೊಸ ಕೆಲಸ ಪೋಸ್ಟ್',
      'नौकरी पोस्ट', 'काम पोस्ट',
      'పని పోస్ట్',
      'வேலை பதிவு',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesMandi(String text) {
    const triggers = [
      'mandi price', 'mandi prices', 'mandi rates', 'check mandi', 'apmc',
      'ಮಂಡಿ ದರ', 'ಮಂಡಿ ಬೆಲೆ', 'ಮಾರುಕಟ್ಟೆ ದರ',
      'मंडी भाव', 'मंडी दर', 'मंडी रेट',
      'మార్కెట్ ధరలు', 'మండీ ధర',
      'மண்டி விலை',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesActiveJobs(String text) {
    const triggers = [
      'active jobs', 'active job', 'my active', 'current job',
      'ಸಕ್ರಿಯ ಕೆಲಸ', 'ಸಕ್ರಿಯ ಕೆಲಸಗಳು',
      'सक्रिय काम', 'चालू काम',
      'ప్రస్తుత పని',
      'செயலில் உள்ள வேலை',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesSchedule(String text) {
    const triggers = [
      'schedule', 'shifts', 'shift', 'timetable',
      'ವೇಳಾಪಟ್ಟಿ', 'ಪಾಳಿ',
      'शेड्यूल', 'समय सारणी',
      'షెడ్యూల్',
      'அட்டவணை',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesChat(String text) {
    const triggers = [
      'chat', 'messages', 'message', 'inbox',
      'ಚಾಟ್', 'ಸಂದೇಶ',
      'चैट', 'संदेश', 'बातचीत',
      'సంభాషణ', 'చాట్',
      'செய்தி', 'சாட்',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesNotifications(String text) {
    const triggers = [
      'notification', 'notifications', 'alert', 'alerts',
      'ಅಧಿಸೂಚನೆ', 'ಸೂಚನೆ',
      'सूचना', 'अलर्ट',
      'నోటిఫికేషన్',
      'அறிவிப்பு',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesHome(String text) {
    const triggers = [
      'home dashboard', 'go home', 'go to home', 'home screen',
      'ಮುಖಪುಟ',
      'होम पेज', 'मुख्य पृष्ठ',
      'హోమ్ పేజీ',
      'முகப்பு',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesFavourites(String text) {
    const triggers = [
      'favourites', 'favourite', 'favorites', 'favorite', 'saved jobs',
      'ಮೆಚ್ಚಿನ', 'ಉಳಿಸಿದ',
      'पसंदीदा', 'सेव किए गए',
      'ఇష్టమైన',
      'பிடித்தவை',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesOrders(String text) {
    const triggers = [
      'orders', 'order status', 'my orders', 'delivery status', 'purchases', 'track order',
      'ಆರ್ಡರ್', 'ಆರ್ಡರ್ಗಳು', 'ನನ್ನ ಆರ್ಡರ್', 'ವಿತರಣೆ ಸ್ಥಿತಿ',
      'ऑर्डर', 'आर्डर', 'मेरे ऑर्डर', 'ऑर्डर स्थिति', 'ट्रैक',
      'ఆర్డర్లు', 'నా ఆర్డర్', 'ఆర్డర్ స్థితి',
      'ஆர்டர்கள்', 'என் ஆர்டர்', 'ஆர்டர் நிலை',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesProduce(String text) {
    const triggers = [
      'produce', 'crops', 'vegetables', 'fruits', 'mandi', 'farm produce', 'buy vegetables', 'farmers selling',
      'ತರಕಾರಿ', 'ಹಣ್ಣು', 'ಬೆಳೆ', 'ಮಂಡಿ', 'ಕೃಷಿ ಉತ್ಪನ್ನ', 'ರೈತರ ತರಕಾರಿ',
      'सब्जी', 'फल', 'फसल', 'मंडी', 'किसान बेच रहे',
      'కూరగాయలు', 'పండ్లు', 'పంటలు', 'మండీ', 'రైతులు అమ్ముతున్న',
      'காய்கறி', 'பழங்கள்', 'பயிர்கள்', 'மண்டி', 'விவசாயிகள் விற்பனை',
    ];
    return _containsAny(text, triggers);
  }

  static bool _containsWorkerIntent(String text) {
    const triggers = [
      'hire', 'need', 'find worker', 'book', 'nearby worker', 'search worker', 'want',
      'ಬೇಕು', 'ಹುಡುಕಿ', 'ಕೆಲಸಗಾರ', 'ಬುಕ್ ಮಾಡಿ',
      'चाहिए', 'ढूंढो', 'मजदूर', 'कारीगर', 'बुक करो',
      'కావాలి', 'వెతకండి', 'పనివాళ్ళు', 'బుక్ చేయండి',
      'வேண்டும்', 'தேடுங்கள்', 'வேலையாள்', 'புக் செய்',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesWorkers(String text) {
    const triggers = [
      'find workers', 'hire workers', 'nearby workers', 'call worker', 'book service',
      'workers', 'worker', 'labour', 'labourers', 'kelsa aalugalu', 'aalugalu beku',
      'majdoor', 'majdoor chahiye', 'pani vallu', 'velai aal',
      'ಕೆಲಸಗಾರರನ್ನು ಹುಡುಕಿ', 'ಕೆಲಸದವರು ಬೇಕು', 'ಸಮೀಪದ ಕೆಲಸಗಾರರು',
      'मजदूर ढूंढो', 'कारीगर ढूंढो', 'काम वाले चाहिए',
      'పనివాళ్ళను వెతకండి', 'పని మనుషులు కావాలి',
      'வேலையாட்களை தேடுங்கள்', 'தொழிலாளர்கள் வேண்டும்',
    ];
    return _containsAny(text, triggers);
  }

  static bool _matchesJobs(String text) {
    const triggers = [
      'job', 'jobs', 'find work', 'daily wage', 'look for work', 'construction work', 'search job',
      'kelsa', 'kelasa', 'kelsa beku', 'kelasa beku', 'nange kelsa beku',
      'kaam', 'kaam chahiye', 'naukri', 'kam chahiye', 'rozgar',
      'pani', 'pani kavali', 'udyogam',
      'velai', 'velai vendum',
      'ಕೆಲಸ ಹುಡುಕಿ', 'ಕೆಲಸ ಬೇಕು', 'ದೈನಂದಿನ ಕೆಲಸ', 'ಉದ್ಯೋಗ',
      'नौकरी ढूंढो', 'काम चाहिए', 'रोजगार', 'काम ढूंढो', 'मजदूरी काम',
      'ఉద్యోగాలు వెతకండి', 'పని కావాలి', 'ఉద్యోగం', 'కూలీ పని',
      'வேலை தேடுங்கள்', 'வேலை வேண்டும்', 'கூலி வேலை',
    ];
    return _containsAny(text, triggers);
  }

  static String? _extractCategory(String text) {
    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static String? _extractProduce(String text) {
    for (final entry in produceKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static int? _extractPrice(String text) {
    final regex = RegExp(r'(?:₹|rs\.?|rupees)?\s*(\d{2,6})\b', caseSensitive: false);
    final match = regex.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  static double? _extractDistance(String text) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:km|kms|kilometer|ಕಿ\.ಮೀ|किमी)', caseSensitive: false);
    final match = regex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  static bool _containsAny(String text, List<String> triggers) {
    for (final trigger in triggers) {
      if (text.contains(trigger)) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^\w\s\u0900-\u0D7F]'), ' ').trim();
  }

  static String _getEmptySpeechReply(String lang) {
    switch (_langCode(lang)) {
      case 'kn':
        return 'ದಯವಿಟ್ಟು ಮೈಕ್ ಒತ್ತಿ ಧ್ವನಿಯಲ್ಲಿ ಮಾತನಾಡಿ.';
      case 'hi':
        return 'कृपया माइक दबाकर अपनी आवाज़ में बोलें।';
      case 'te':
        return 'దయచేసి మైక్ నొక్కి మాట్లాడండి.';
      case 'ta':
        return 'தயவுசெய்து மைக் அழுத்தி குரலில் பேசுங்கள்.';
      default:
        return 'Please tap the mic and speak a command.';
    }
  }

  static String _getUnrecognizedReply(String lang) {
    switch (_langCode(lang)) {
      case 'kn':
        return 'ಕ್ಷಮಿಸಿ, ಆಜ್ಞೆ ಅರ್ಥವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೊಮ್ಮೆ ಪ್ರಯತ್ನಿಸಿ.';
      case 'hi':
        return 'माफ़ कीजिए, यह आदेश समझ नहीं आया। कृपया पुनः प्रयास करें।';
      case 'te':
        return 'క్షమించండి, మీ ఆదేశం అర్థం కాలేదు. దయచేసి మళ్ళీ ప్రయత్నించండి.';
      case 'ta':
        return 'மன்னிக்கவும், கட்டளை புரியவில்லை. மீண்டும் முயற்சிக்கவும்.';
      default:
        return 'Sorry, I could not understand that command. Please try again.';
    }
  }

  static String _getReply(VoiceIntentType type, String lang, {String? detail}) {
    final code = _langCode(lang);
    switch (type) {
      case VoiceIntentType.findJobs:
        final cat = detail != null ? ' ($detail)' : '';
        switch (code) {
          case 'kn':
            return 'ಖಂಡಿತ, ನಿಮಗಾಗಿ ಸೂಕ್ತ ಕೆಲಸಗಳನ್ನು ತೆರೆಯಲಾಗುತ್ತಿದೆ$cat.';
          case 'hi':
            return 'ज़रूर, आपके लिए उपलब्ध काम खोला जा रहा है$cat।';
          case 'te':
            return 'ఖచ్చితంగా, మీకు సరిపోయే ఉద్యోగాలు చూపబడుతున్నాయి$cat.';
          case 'ta':
            return 'நிச்சயமாக, உங்களுக்கான வேலைகள் காட்டப்படுகின்றன$cat.';
          default:
            return 'Sure, finding suitable jobs for you$cat.';
        }
      case VoiceIntentType.findWorkers:
        final cat = detail != null ? ' ($detail)' : '';
        switch (code) {
          case 'kn':
            return 'ಖಂಡಿತ, ಸಮೀಪದ ಕೆಲಸಗಾರರನ್ನು ಹುಡುಕಲಾಗುತ್ತಿದೆ$cat.';
          case 'hi':
            return 'ज़रूर, नज़दीकी कामगारों की सूची दिखाई जा रही है$cat।';
          case 'te':
            return 'ఖచ్చితంగా, సమీపంలోని వర్కర్లను వెతుకుతున్నాం$cat.';
          case 'ta':
            return 'நிச்சயமாக, அருகிலுள்ள தொழிலாளர்கள் காட்டப்படுகிறார்கள்$cat.';
          default:
            return 'Sure, finding nearby verified workers$cat.';
        }
      case VoiceIntentType.searchProduce:
        final prod = detail != null ? ' ($detail)' : '';
        switch (code) {
          case 'kn':
            return 'ರೈತರ ತಾಜಾ ಕೃಷಿ ಉತ್ಪನ್ನಗಳನ್ನು ತೋರಿಸಲಾಗುತ್ತಿದೆ$prod.';
          case 'hi':
            return 'किसानों के ताज़ा उत्पाद दिखाए जा रहे हैं$prod।';
          case 'te':
            return 'రైతుల తాజా పంట ఉత్పత్తులు చూపబడుతున్నాయి$prod.';
          case 'ta':
            return 'விவசாயிகளின் புதிய விளைபொருட்கள் காட்டப்படுகின்றன$prod.';
          default:
            return 'Sure, searching fresh farm produce$prod.';
        }
      case VoiceIntentType.checkEarnings:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ಗಳಿಕೆ ಮತ್ತು ವಹಿವಾಟು ವಿವರಗಳನ್ನು ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपकी आज की कमाई और बहीखाता खोला जा रहा है।';
          case 'te':
            return 'మీ సంపాదన మరియు లావాదేవీలు తెరవబడుతున్నాయి.';
          case 'ta':
            return 'உங்கள் வருமானம் மற்றும் பரிவர்த்தனைகள் திறக்கப்படுகின்றன.';
          default:
            return 'Opening your earnings and passbook details.';
        }
      case VoiceIntentType.openWallet:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ವಾಲೆಟ್ ಬ್ಯಾಲೆನ್ಸ್ ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपका वॉलेट और बकाया राशि खोली जा रही है।';
          case 'te':
            return 'మీ వాలెట్ వివరాలు చూపబడుతున్నాయి.';
          case 'ta':
            return 'உங்கள் பணப்பை இருப்பு திறக்கப்படுகிறது.';
          default:
            return 'Opening your wallet and escrow balance.';
        }
      case VoiceIntentType.openSafety:
        switch (code) {
          case 'kn':
            return 'ಸುರಕ್ಷತಾ ಕೇಂದ್ರ ಮತ್ತು ತುರ್ತು ಎಸ್ಒಎಸ್ ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'सुरक्षा केंद्र और आपातकालीन सहायता खोली जा रही है।';
          case 'te':
            return 'భద్రతా కేంద్రం మరియు అత్యవసర సహాయం తెరవబడుతోంది.';
          case 'ta':
            return 'பாதுகாப்பு மையம் மற்றும் அவசர உதவி திறக்கப்படுகிறது.';
          default:
            return 'Opening Safety Hub and emergency SOS support.';
        }
      case VoiceIntentType.openSettings:
        switch (code) {
          case 'kn':
            return 'ಆ್ಯಪ್ ಸೆಟ್ಟಿಂಗ್ಸ್ ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'ऐप सेटिंग्स खोली जा रही है।';
          case 'te':
            return 'యాప్ సెట్టింగులు తెరవబడుతున్నాయి.';
          case 'ta':
            return 'செயலி அமைப்புகள் திறக்கப்படுகின்றன.';
          default:
            return 'Opening application settings and controls.';
        }
      case VoiceIntentType.viewOrders:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ಆರ್ಡರ್ಗಳ ವಿವರ ಮತ್ತು ಸ್ಥಿತಿಯನ್ನು ತೋರಿಸಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपके ऑर्डर और डिलीवरी की स्थिति दिखाई जा रही है।';
          case 'te':
            return 'మీ ఆర్డర్ వివరాలు మరియు డెలివరీ స్థితి చూపబడుతోంది.';
          case 'ta':
            return 'உங்கள் ஆர்டர்கள் மற்றும் நிலை காட்டப்படுகின்றன.';
          default:
            return 'Showing your orders and delivery status.';
        }
      case VoiceIntentType.openProfile:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ಪ್ರೊಫೈಲ್ ಪುಟವನ್ನು ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपका प्रोफाइल पेज खोला जा रहा है।';
          case 'te':
            return 'మీ ప్రొఫైల్ పేజీ తెరవబడుతోంది.';
          case 'ta':
            return 'உங்கள் சுயவிவரப் பக்கம் திறக்கப்படுகிறது.';
          default:
            return 'Opening your profile page.';
        }
      case VoiceIntentType.postJob:
        switch (code) {
          case 'kn':
            return 'ಹೊಸ ಕೆಲಸದ ಪೋಸ್ಟಿಂಗ್ ಫಾರ್ಮ್ ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'नया काम पोस्ट करने का फॉर्म खोला जा रहा है।';
          case 'te':
            return 'కొత్త పని పోస్ట్ చేసే పేజీ తెరవబడుతోంది.';
          case 'ta':
            return 'புதிய வேலை பதிவு திறக்கப்படுகிறது.';
          default:
            return 'Opening post new job form.';
        }
      case VoiceIntentType.checkMandi:
        switch (code) {
          case 'kn':
            return 'ಲೈವ್ ಮಂಡಿ ಬೆಲೆಗಳನ್ನು ತೋರಿಸಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'लाइव मंडी भाव दिखाए जा रहे हैं।';
          case 'te':
            return 'ప్రత్యక్ష మార్కెట్ ధరలు చూపబడుతున్నాయి.';
          case 'ta':
            return 'நேரடி மண்டி விலைகள் காட்டப்படுகின்றன.';
          default:
            return 'Showing live mandi market prices.';
        }
      case VoiceIntentType.confirmSos:
        switch (code) {
          case 'kn':
            return 'ತುರ್ತು ಎಸ್ಒಎಸ್ ಮತ್ತು ಸುರಕ್ಷತಾ ನೆರವು ಸಕ್ರಿಯಗೊಳಿಸಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपातकालीन एसओएस और सुरक्षा सहायता सक्रिय की जा रही है।';
          case 'te':
            return 'అత్యవసర సహాయం తెరవబడుతోంది.';
          case 'ta':
            return 'அவசர உதவி திறக்கப்படுகிறது.';
          default:
            return 'Activating emergency safety assistance.';
        }
      case VoiceIntentType.answerQuestion:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ಪ್ರಶ್ನೆಗೆ ವಿವರಗಳು ಇಲ್ಲಿವೆ.';
          case 'hi':
            return 'आपके प्रश्न की जानकारी यहाँ है।';
          case 'te':
            return 'మీ ప్రశ్నకు సమాధానం ఇక్కడ ఉంది.';
          case 'ta':
            return 'உங்கள் கேள்விக்கான தகவல் இதோ.';
          default:
            return 'Here is the information for your question.';
        }
      case VoiceIntentType.viewActiveJobs:
        switch (code) {
          case 'kn':
            return 'ಪ್ರಸ್ತುತ ಸಕ್ರಿಯ ಕೆಲಸದ ವಿವರಗಳನ್ನು ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'वर्तमान सक्रिय काम की स्थिति खोली जा रही है।';
          case 'te':
            return 'ప్రస్తుతం జరుగుతున్న పని వివరాలు తెరవబడుతున్నాయి.';
          case 'ta':
            return 'செயலில் உள்ள வேலை விவரங்கள் திறக்கப்படுகின்றன.';
          default:
            return 'Opening active job execution screen.';
        }
      case VoiceIntentType.viewSchedule:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ಕೆಲಸದ ವೇಳಾಪಟ್ಟಿಯನ್ನು ತೋರಿಸಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपका काम का शेड्यूल दिखाया जा रहा है।';
          case 'te':
            return 'మీ పని షెడ్యూల్ చూపబడుతోంది.';
          case 'ta':
            return 'உங்கள் வேலை அட்டவணை காட்டப்படுகிறது.';
          default:
            return 'Opening your work schedule.';
        }
      case VoiceIntentType.viewApplicants:
        switch (code) {
          case 'kn':
            return 'ಕೆಲಸಕ್ಕೆ ಅರ್ಜಿ ಸಲ್ಲಿಸಿದವರ ವಿವರಗಳನ್ನು ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'काम के आवेदकों की सूची खोली जा रही है।';
          case 'te':
            return 'దరఖాస్తుదారుల జాబితా తెరవబడుతోంది.';
          case 'ta':
            return 'விண்ணப்பதாரர்கள் பட்டியல் திறக்கப்படுகிறது.';
          default:
            return 'Opening job applicants and candidates.';
        }
      case VoiceIntentType.digitalId:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ಡಿಜಿಟಲ್ ಗುರುತಿನ ಚೀಟಿ ಮತ್ತು ಕ್ಯೂಆರ್ ಕೋಡ್ ತೋರಿಸಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपका डिजिटल पहचान पत्र और क्यूआर कोड खोला जा रहा है।';
          case 'te':
            return 'మీ డిజిటల్ గుర్తింపు కార్డు చూపబడుతోంది.';
          case 'ta':
            return 'உங்கள் டிஜிட்டல் அடையாள அட்டை காட்டப்படுகிறது.';
          default:
            return 'Opening your digital ID badge and QR ticket.';
        }
      case VoiceIntentType.scanVerify:
        switch (code) {
          case 'kn':
            return 'ಕ್ಯೂಆರ್ ಸ್ಕ್ಯಾನರ್ ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'क्यूआर कोड स्कैनर खोला जा रहा है।';
          case 'te':
            return 'క్యూఆర్ స్కానర్ తెరవబడుతోంది.';
          case 'ta':
            return 'ஸ்கேனர் திறக்கப்படுகிறது.';
          default:
            return 'Opening QR attendance scanner.';
        }
      case VoiceIntentType.openChat:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ಸಂದೇಶಗಳು ಮತ್ತು ಚಾಟ್ ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपके संदेश और चैट खोली जा रही है।';
          case 'te':
            return 'మీ సంభాషణలు తెరవబడుతున్నాయి.';
          case 'ta':
            return 'உங்கள் செய்திகள் திறக்கப்படுகின்றன.';
          default:
            return 'Opening your chats and messages.';
        }
      case VoiceIntentType.openNotifications:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ಅಧಿಸೂಚನೆಗಳನ್ನು ತೋರಿಸಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपकी सूचनाएं खोली जा रही हैं।';
          case 'te':
            return 'మీ నోటిఫికేషన్లు చూపబడుతున్నాయి.';
          case 'ta':
            return 'உங்கள் அறிவிப்புகள் காட்டப்படுகின்றன.';
          default:
            return 'Opening notifications.';
        }
      case VoiceIntentType.farmAi:
        switch (code) {
          case 'kn':
            return 'ರೈತ ಎಐ ಸಲಹಾ ಸಾಧನಗಳನ್ನು ತೆರೆಯಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'किसान एआई फसल एवं मिट्टी सलाहकार खोला जा रहा है।';
          case 'te':
            return 'రైతు ఏఐ సలహా సాధనాలు తెరవబడుతున్నాయి.';
          case 'ta':
            return 'விவசாய AI வழிகாட்டி திறக்கப்படுகிறது.';
          default:
            return 'Opening Farmer AI advisory tools.';
        }
      case VoiceIntentType.goHome:
        switch (code) {
          case 'kn':
            return 'ಮುಖಪುಟಕ್ಕೆ ಹೋಗಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'मुख्य पृष्ठ पर जाया जा रहा है।';
          case 'te':
            return 'హోమ్ పేజీకి నావిగేట్ చేస్తున్నాం.';
          case 'ta':
            return 'முகப்புப் பக்கத்திற்கு செல்கிறது.';
          default:
            return 'Navigating to home screen.';
        }
      case VoiceIntentType.viewFavourites:
        switch (code) {
          case 'kn':
            return 'ನಿಮ್ಮ ಉಳಿಸಿದ ಮೆಚ್ಚಿನವುಗಳನ್ನು ತೋರಿಸಲಾಗುತ್ತಿದೆ.';
          case 'hi':
            return 'आपके पसंदीदा बुकमार्क दिखाए जा रहे हैं।';
          case 'te':
            return 'మీ ఇష్టమైనవి చూపబడుతున్నాయి.';
          case 'ta':
            return 'உங்களுக்கு பிடித்தவை காட்டப்படுகின்றன.';
          default:
            return 'Opening your saved favourites.';
        }
      case VoiceIntentType.unknown:
        return _getUnrecognizedReply(code);
    }
  }

  static String _langCode(String lang) {
    if (lang.startsWith('kn')) return 'kn';
    if (lang.startsWith('hi')) return 'hi';
    if (lang.startsWith('te')) return 'te';
    if (lang.startsWith('ta')) return 'ta';
    return 'en';
  }
}
