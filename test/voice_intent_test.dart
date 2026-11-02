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
    // Expanded In-App Voice Commands (100% Offline, Zero API Key)
    // -------------------------------------------------------------------------
    test('Offline Command: Open Profile (Multi-lingual & Role-aware)', () {
      final resKn = IntentEngine.parse('ನನ್ನ ಪ್ರೊಫೈಲ್ ತೆರೆಯಿರಿ', language: 'kn');
      expect(resKn.type, VoiceIntentType.openProfile);
      expect(resKn.targetRoute, contains('/seeker/profile'));
      expect(resKn.spokenReply, contains('ಪ್ರೊಫೈಲ್'));

      final resHi = IntentEngine.parse('मेरी प्रोफाइल खोलो', language: 'hi', userRole: 'provider');
      expect(resHi.type, VoiceIntentType.openProfile);
      expect(resHi.targetRoute, contains('/provider/profile'));

      final resEn = IntentEngine.parse('open my profile', language: 'en', userRole: 'farmer');
      expect(resEn.type, VoiceIntentType.openProfile);
      expect(resEn.targetRoute, contains('/farmer/profile'));
    });

    test('Offline Command: Post a Job (Multi-lingual)', () {
      final resEn = IntentEngine.parse('post a new job for plumber', language: 'en');
      expect(resEn.type, VoiceIntentType.postJob);
      expect(resEn.targetRoute, '/provider/jobs/new');

      final resKn = IntentEngine.parse('ಹೊಸ ಕೆಲಸ ಪೋಸ್ಟ್ ಮಾಡಿ', language: 'kn');
      expect(resKn.type, VoiceIntentType.postJob);
      expect(resKn.targetRoute, '/provider/jobs/new');

      final resHi = IntentEngine.parse('नौकरी पोस्ट करो', language: 'hi');
      expect(resHi.type, VoiceIntentType.postJob);
      expect(resHi.targetRoute, '/provider/jobs/new');
    });

    test('Offline Command: Mandi Prices / APMC (Multi-lingual)', () {
      final resKn = IntentEngine.parse('ಇಂದಿನ ಮಂಡಿ ದರ ನೋಡಿ', language: 'kn');
      expect(resKn.type, VoiceIntentType.checkMandi);
      expect(resKn.targetRoute, '/farmer/market');

      final resHi = IntentEngine.parse('आज का मंडी भाव क्या है', language: 'hi');
      expect(resHi.type, VoiceIntentType.checkMandi);
      expect(resHi.targetRoute, '/farmer/market');

      final resEn = IntentEngine.parse('check mandi prices today', language: 'en');
      expect(resEn.type, VoiceIntentType.checkMandi);
      expect(resEn.targetRoute, '/farmer/market');
    });

    test('Offline Command: Active Jobs & My Jobs (Multi-lingual)', () {
      final resEn = IntentEngine.parse('show my active jobs', language: 'en');
      expect(resEn.type, VoiceIntentType.viewActiveJobs);
      expect(resEn.targetRoute, '/seeker/jobs');

      final resKn = IntentEngine.parse('ಸಕ್ರಿಯ ಕೆಲಸಗಳು ತೋರಿಸಿ', language: 'kn');
      expect(resKn.type, VoiceIntentType.viewActiveJobs);
      expect(resKn.targetRoute, '/seeker/jobs');
    });

    test('Offline Command: Schedule & Timetable (Multi-lingual)', () {
      final resEn = IntentEngine.parse('my schedule and shifts', language: 'en');
      expect(resEn.type, VoiceIntentType.viewSchedule);
      expect(resEn.targetRoute, '/seeker/schedule');

      final resKn = IntentEngine.parse('ನನ್ನ ವೇಳಾಪಟ್ಟಿ ನೋಡಿ', language: 'kn');
      expect(resKn.type, VoiceIntentType.viewSchedule);
      expect(resKn.targetRoute, '/seeker/schedule');
    });

    test('Offline Command: Digital ID & QR Ticket (Multi-lingual)', () {
      final resEn = IntentEngine.parse('show my digital id and attendance qr', language: 'en');
      expect(resEn.type, VoiceIntentType.digitalId);
      expect(resEn.targetRoute, '/trust/digital-id');

      final resKn = IntentEngine.parse('ನನ್ನ ಡಿಜಿಟಲ್ ಐಡಿ ತೋರಿಸಿ', language: 'kn');
      expect(resKn.type, VoiceIntentType.digitalId);
      expect(resKn.targetRoute, '/trust/digital-id');
    });

    test('Offline Command: Scan QR & Attendance Scanner', () {
      final res = IntentEngine.parse('scan qr code', language: 'en');
      expect(res.type, VoiceIntentType.scanVerify);
      expect(res.targetRoute, '/trust/scan-verify');
    });

    test('Offline Command: Chat, Messages & Inbox', () {
      final res = IntentEngine.parse('open chat and messages', language: 'en', userRole: 'seeker');
      expect(res.type, VoiceIntentType.openChat);
      expect(res.targetRoute, '/seeker/chat');
    });

    test('Offline Command: Notifications & Alerts', () {
      final res = IntentEngine.parse('show my notifications', language: 'en');
      expect(res.type, VoiceIntentType.openNotifications);
      expect(res.targetRoute, '/notifications');
    });

    test('Offline Command: Farm AI Crop Doctor & Pest Diagnosis', () {
      final res = IntentEngine.parse('help me diagnose a crop problem', language: 'en');
      expect(res.type, VoiceIntentType.farmAi);
      expect(res.targetRoute, '/farmer/pest-ai');
    });

    test('Offline Command: Home Dashboard & Favourites', () {
      final resHome = IntentEngine.parse('go to home dashboard', language: 'en', userRole: 'provider');
      expect(resHome.type, VoiceIntentType.goHome);
      expect(resHome.targetRoute, '/provider/home');

      final resFav = IntentEngine.parse('open my favourites saved jobs', language: 'en');
      expect(resFav.type, VoiceIntentType.viewFavourites);
      expect(resFav.targetRoute, '/favourites');
    });
  });
}
