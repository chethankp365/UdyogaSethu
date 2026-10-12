import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/voice/domain/voice_intent.dart';
import 'package:udyogasethu/features/voice/intent/intent_engine.dart';

void main() {
  group('IntentEngine - Multi-lingual Offline Voice Command Tests', () {
    // -------------------------------------------------------------------------
    // KANNADA (kn) - 8 Phrases
    // -------------------------------------------------------------------------
    test('Kannada: 1. findJobs (plumber)', () {
      final res = IntentEngine.parse('ಪ್ಲಂಬರ್ ಕೆಲಸ ಬೇಕು', language: 'kn');
      expect(res.type, VoiceIntentType.findJobs);
      expect(res.parameters.category, 'plumber');
      expect(res.targetRoute, contains('/jobs?category=plumber'));
      expect(res.spokenReply, contains('ಖಂಡಿತ'));
    });

    test('Kannada: 2. findWorkers', () {
      final res = IntentEngine.parse('ಸಮೀಪದ ಕೆಲಸಗಾರರನ್ನು ಹುಡುಕಿ', language: 'kn');
      expect(res.type, VoiceIntentType.findWorkers);
      expect(res.targetRoute, contains('/provider/workers'));
    });

    test('Kannada: 3. searchProduce (tomato)', () {
      final res = IntentEngine.parse('ಟೊಮೆಟೊ ಮಾರುವ ರೈತರು', language: 'kn');
      expect(res.type, VoiceIntentType.searchProduce);
      expect(res.parameters.produce, 'tomato');
      expect(res.targetRoute, contains('search=tomato'));
    });

    test('Kannada: 4. checkEarnings', () {
      final res = IntentEngine.parse('ಇಂದಿನ ಗಳಿಕೆ ತೋರಿಸಿ', language: 'kn');
      expect(res.type, VoiceIntentType.checkEarnings);
      expect(res.targetRoute, '/wallet');
    });

    test('Kannada: 5. viewOrders', () {
      final res = IntentEngine.parse('ನನ್ನ ಆರ್ಡರ್ ಸ್ಥಿತಿ ನೋಡಿ', language: 'kn');
      expect(res.type, VoiceIntentType.viewOrders);
      expect(res.targetRoute, '/marketplace');
    });

    test('Kannada: 6. openWallet', () {
      final res = IntentEngine.parse('ವಾಲೆಟ್ ಬ್ಯಾಲೆನ್ಸ್ ತೆರೆಯಿರಿ', language: 'kn');
      expect(res.type, VoiceIntentType.openWallet);
      expect(res.targetRoute, '/wallet');
    });

    test('Kannada: 7. openSafety', () {
      final res = IntentEngine.parse('ತುರ್ತು ಸುರಕ್ಷತೆ ಸಹಾಯ', language: 'kn');
      expect(res.type, VoiceIntentType.openSafety);
      expect(res.targetRoute, '/safety/hub');
    });

    test('Kannada: 8. openSettings', () {
      final res = IntentEngine.parse('ಆ್ಯಪ್ ಸೆಟ್ಟಿಂಗ್ಸ್ ತೆರೆಯಿರಿ', language: 'kn');
      expect(res.type, VoiceIntentType.openSettings);
      expect(res.targetRoute, '/settings');
    });

    // -------------------------------------------------------------------------
    // HINDI (hi) - 8 Phrases
    // -------------------------------------------------------------------------
    test('Hindi: 1. findJobs (plumber)', () {
      final res = IntentEngine.parse('मुझे प्लंबर का काम चाहिए', language: 'hi');
      expect(res.type, VoiceIntentType.findJobs);
      expect(res.parameters.category, 'plumber');
      expect(res.targetRoute, contains('/jobs?category=plumber'));
    });

    test('Hindi: 2. findWorkers', () {
      final res = IntentEngine.parse('मजदूर ढूंढो', language: 'hi');
      expect(res.type, VoiceIntentType.findWorkers);
      expect(res.targetRoute, contains('/provider/workers'));
    });

    test('Hindi: 3. searchProduce (tomato)', () {
      final res = IntentEngine.parse('टमाटर बेचने वाले किसान', language: 'hi');
      expect(res.type, VoiceIntentType.searchProduce);
      expect(res.parameters.produce, 'tomato');
    });

    test('Hindi: 4. checkEarnings', () {
      final res = IntentEngine.parse('आज की कमाई दिखाओ', language: 'hi');
      expect(res.type, VoiceIntentType.checkEarnings);
      expect(res.targetRoute, '/wallet');
    });

    test('Hindi: 5. viewOrders', () {
      final res = IntentEngine.parse('मेरे ऑर्डर दिखाओ', language: 'hi');
      expect(res.type, VoiceIntentType.viewOrders);
    });

    test('Hindi: 6. openWallet', () {
      final res = IntentEngine.parse('वॉलेट बैलेंस खोलो', language: 'hi');
      expect(res.type, VoiceIntentType.openWallet);
      expect(res.targetRoute, '/wallet');
    });

    test('Hindi: 7. openSafety', () {
      final res = IntentEngine.parse('सुरक्षा सहायता केंद्र', language: 'hi');
      expect(res.type, VoiceIntentType.openSafety);
      expect(res.targetRoute, '/safety/hub');
    });

    test('Hindi: 8. openSettings', () {
      final res = IntentEngine.parse('ऐप सेटिंग्स खोलो', language: 'hi');
      expect(res.type, VoiceIntentType.openSettings);
      expect(res.targetRoute, '/settings');
    });

    // -------------------------------------------------------------------------
    // TELUGU (te) - 8 Phrases
    // -------------------------------------------------------------------------
    test('Telugu: 1. findJobs (plumber)', () {
      final res = IntentEngine.parse('ప్లంబర్ పని కావాలి', language: 'te');
      expect(res.type, VoiceIntentType.findJobs);
      expect(res.parameters.category, 'plumber');
    });

    test('Telugu: 2. findWorkers', () {
      final res = IntentEngine.parse('పనివాళ్ళను వెతకండి', language: 'te');
      expect(res.type, VoiceIntentType.findWorkers);
    });

    test('Telugu: 3. searchProduce (tomato)', () {
      final res = IntentEngine.parse('రైతులు అమ్మే టమోటాలు', language: 'te');
      expect(res.type, VoiceIntentType.searchProduce);
      expect(res.parameters.produce, 'tomato');
    });

    test('Telugu: 4. checkEarnings', () {
      final res = IntentEngine.parse('ఈ రోజు సంపాదన చూపించు', language: 'te');
      expect(res.type, VoiceIntentType.checkEarnings);
      expect(res.targetRoute, '/wallet');
    });

    test('Telugu: 5. viewOrders', () {
      final res = IntentEngine.parse('నా ఆర్డర్ల స్థితి', language: 'te');
      expect(res.type, VoiceIntentType.viewOrders);
    });

    test('Telugu: 6. openWallet', () {
      final res = IntentEngine.parse('వాలెట్ బ్యాలెన్స్ తెరవండి', language: 'te');
      expect(res.type, VoiceIntentType.openWallet);
      expect(res.targetRoute, '/wallet');
    });

    test('Telugu: 7. openSafety', () {
      final res = IntentEngine.parse('అత్యవసర భద్రత మరియు రక్షణ', language: 'te');
      expect(res.type, VoiceIntentType.openSafety);
      expect(res.targetRoute, '/safety/hub');
    });

    test('Telugu: 8. openSettings', () {
      final res = IntentEngine.parse('యాప్ సెట్టింగులు మార్చు', language: 'te');
      expect(res.type, VoiceIntentType.openSettings);
      expect(res.targetRoute, '/settings');
    });

    // -------------------------------------------------------------------------
    // TAMIL (ta) - 8 Phrases
    // -------------------------------------------------------------------------
    test('Tamil: 1. findJobs (plumber)', () {
      final res = IntentEngine.parse('பிளம்பர் வேலை வேண்டும்', language: 'ta');
      expect(res.type, VoiceIntentType.findJobs);
      expect(res.parameters.category, 'plumber');
    });

    test('Tamil: 2. findWorkers', () {
      final res = IntentEngine.parse('வேலையாட்களை தேடுங்கள்', language: 'ta');
      expect(res.type, VoiceIntentType.findWorkers);
    });

    test('Tamil: 3. searchProduce (tomato)', () {
      final res = IntentEngine.parse('தக்காளி விற்கும் விவசாயிகள்', language: 'ta');
      expect(res.type, VoiceIntentType.searchProduce);
      expect(res.parameters.produce, 'tomato');
    });

    test('Tamil: 4. checkEarnings', () {
      final res = IntentEngine.parse('இன்றைய வருமானம் காட்டு', language: 'ta');
      expect(res.type, VoiceIntentType.checkEarnings);
      expect(res.targetRoute, '/wallet');
    });

    test('Tamil: 5. viewOrders', () {
      final res = IntentEngine.parse('என் ஆர்டர்கள் நிலை', language: 'ta');
      expect(res.type, VoiceIntentType.viewOrders);
    });

    test('Tamil: 6. openWallet', () {
      final res = IntentEngine.parse('வாலட் இருப்பு திற', language: 'ta');
      expect(res.type, VoiceIntentType.openWallet);
      expect(res.targetRoute, '/wallet');
    });

    test('Tamil: 7. openSafety', () {
      final res = IntentEngine.parse('பாதுகாப்பு அவசர உதவி', language: 'ta');
      expect(res.type, VoiceIntentType.openSafety);
      expect(res.targetRoute, '/safety/hub');
    });

    test('Tamil: 8. openSettings', () {
      final res = IntentEngine.parse('செயலி அமைப்புகள் திற', language: 'ta');
      expect(res.type, VoiceIntentType.openSettings);
      expect(res.targetRoute, '/settings');
    });

    // -------------------------------------------------------------------------
    // ENGLISH (en) - 8 Phrases
    // -------------------------------------------------------------------------
    test('English: 1. findJobs (plumber)', () {
      final res = IntentEngine.parse('find plumber jobs near me', language: 'en');
      expect(res.type, VoiceIntentType.findJobs);
      expect(res.parameters.category, 'plumber');
    });

    test('English: 2. findWorkers (electrician)', () {
      final res = IntentEngine.parse('hire nearby electrician worker', language: 'en');
      expect(res.type, VoiceIntentType.findWorkers);
      expect(res.parameters.category, 'electrician');
    });

    test('English: 3. searchProduce (tomato)', () {
      final res = IntentEngine.parse('farmers selling fresh tomatoes', language: 'en');
      expect(res.type, VoiceIntentType.searchProduce);
      expect(res.parameters.produce, 'tomato');
    });

    test('English: 4. checkEarnings', () {
      final res = IntentEngine.parse('show my today earnings', language: 'en');
      expect(res.type, VoiceIntentType.checkEarnings);
      expect(res.targetRoute, '/wallet');
    });

    test('English: 5. viewOrders', () {
      final res = IntentEngine.parse('track my orders delivery status', language: 'en');
      expect(res.type, VoiceIntentType.viewOrders);
    });

    test('English: 6. openWallet', () {
      final res = IntentEngine.parse('open wallet balance', language: 'en');
      expect(res.type, VoiceIntentType.openWallet);
      expect(res.targetRoute, '/wallet');
    });

    test('English: 7. openSafety', () {
      final res = IntentEngine.parse('emergency sos safety hub', language: 'en');
      expect(res.type, VoiceIntentType.openSafety);
      expect(res.targetRoute, '/safety/hub');
    });

    test('English: 8. openSettings', () {
      final res = IntentEngine.parse('open account settings preferences', language: 'en');
      expect(res.type, VoiceIntentType.openSettings);
      expect(res.targetRoute, '/settings');
    });

    // -------------------------------------------------------------------------
    // Numbers, distances, empty speech & unknown command handling
    // -------------------------------------------------------------------------
    test('Price and Distance extraction', () {
      final res = IntentEngine.parse('construction job paying 850 within 5 km', language: 'en');
      expect(res.type, VoiceIntentType.findJobs);
      expect(res.parameters.category, 'construction');
      expect(res.parameters.minPrice, 850);
      expect(res.parameters.radiusKm, 5.0);
    });

    test('Empty speech returns polite prompt', () {
      final res = IntentEngine.parse('', language: 'kn');
      expect(res.type, VoiceIntentType.unknown);
      expect(res.spokenReply, contains('ದಯವಿಟ್ಟು'));
    });

    test('Unrecognized gibberish command', () {
      final res = IntentEngine.parse('xyzzy abracadabra 123456789', language: 'en');
      expect(res.type, VoiceIntentType.unknown);
      expect(res.targetRoute, '');
      expect(res.isRecognized, false);
      expect(res.spokenReply, contains('could not understand'));
    });
  });
}
