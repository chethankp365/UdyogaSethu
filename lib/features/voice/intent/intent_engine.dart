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
  static VoiceIntentResult parse(String text, {String language = 'en'}) {
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
