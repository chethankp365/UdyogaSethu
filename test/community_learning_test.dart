import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/community/data/community_repository.dart';
import 'package:udyogasethu/features/community/domain/community_models.dart';
import 'package:udyogasethu/features/community/presentation/community_hub_screen.dart';
import 'package:udyogasethu/features/community/presentation/learning_hub_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeCommunityRepository implements CommunityRepository {
  LocalityTrustIndex mockTrust = const LocalityTrustIndex(
    localityName: 'Bengaluru South & Rural Hub',
    level: TrustLevel.high,
    score: 4.9,
    completedJobsCount: 1420,
    activeWorkersCount: 380,
    disputeFreePercent: 99.2,
  );

  List<CommunityPost> mockPosts = [
    CommunityPost(
      id: 'p-1',
      authorId: 'auth-1',
      authorName: 'Ramesh Gowda',
      authorRole: 'Trusted Pro Farmer',
      kind: 'hero',
      title: 'Delivered 500kg Organic Tomatoes Directly with Zero Middlemen',
      body: 'Direct-to-consumer escrow payment was fast and fair.',
      locality: 'Mandya Hub',
      createdAt: DateTime.now(),
    ),
  ];

  List<TrainingEvent> mockEvents = [
    TrainingEvent(
      id: 'ev-1',
      kind: 'workshop',
      title: 'Workplace Electrical Safety Workshop',
      description: 'Hands-on session covering safety equipment and protocols.',
      startsAt: DateTime.now().add(const Duration(days: 3)),
      venue: 'Government ITI Campus, Dairy Circle, Bengaluru',
      capacity: 40,
      language: 'kn',
      isRegistered: false,
    ),
  ];

  List<LearningModule> mockModules = [
    const LearningModule(
      id: 'mod-1',
      slug: 'module_safety',
      titles: {
        'en': 'Worksite Safety & Emergency Protocols',
        'kn': 'ಕೆಲಸದ ಸ್ಥಳದ ಸುರಕ್ಷತೆ',
      },
      category: 'safety',
      summary: 'Master essential site safety and emergency SOS.',
      durationMinutes: 5,
      sections: [
        {'title': 'PPE', 'body': 'Wear helmet and gloves at all times.'},
      ],
      passPercent: 80,
      questions: [
        QuizQuestion(
          question: 'When should you wear protective equipment?',
          options: ['Never', 'At all times on worksite', 'Only on rain'],
          answerIndex: 1,
          explanation: 'Safety equipment is mandatory at all times.',
        ),
        QuizQuestion(
          question: 'What is the geofence radius for check-in?',
          options: ['150 meters', '5 kilometers', 'Anywhere'],
          answerIndex: 0,
          explanation: 'Strict 150m GPS geofence is enforced.',
        ),
        QuizQuestion(
          question: 'Who gets alerted when SOS is triggered?',
          options: ['Nobody', 'Safety team and emergency contacts', 'Client only'],
          answerIndex: 1,
          explanation: 'Safety dispatch and contacts are alerted immediately.',
        ),
      ],
      isCompleted: true,
      bestScore: 100,
    ),
  ];

  List<MicroCredential> mockCredentials = [
    MicroCredential(
      id: 'cred-1',
      userId: 'user-1',
      kind: 'worksite_safety_certified',
      sourceType: 'module',
      isVerified: true,
      title: 'Worksite Safety Certified',
      issuedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    MicroCredential(
      id: 'cred-2',
      userId: 'user-1',
      kind: 'external_credential',
      sourceType: 'uploaded_certificate',
      isVerified: false,
      title: 'ITI Electrician Diploma',
      issuingOrganization: 'National ITI Board',
      issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Future<LocalityTrustIndex> getLocalityTrustIndex() async => mockTrust;

  @override
  Future<List<CommunityPost>> getCommunityPosts({String? kind}) async => mockPosts;

  @override
  Future<List<TrainingEvent>> getTrainingEvents() async => mockEvents;

  @override
  Future<Map<String, dynamic>> registerForTrainingEvent(String eventId) async {
    return {'success': true, 'event_id': eventId, 'status': 'registered'};
  }

  @override
  Future<List<LearningModule>> getLearningModules() async => mockModules;

  @override
  Future<LearningModule?> getLearningModuleById(String id) async {
    return mockModules.firstWhere((m) => m.id == id);
  }

  @override
  Future<Map<String, dynamic>> submitLearningQuiz({
    required String moduleId,
    required int score,
  }) async {
    final passed = score >= 80;
    return {
      'passed': passed,
      'score': score,
      'credential_awarded': passed,
      'xp_awarded': passed ? 40 : 0,
    };
  }

  @override
  Future<Map<String, dynamic>> uploadExternalCertificate({
    required String kind,
    required String title,
    required String issuingOrg,
    required String certificatePath,
  }) async {
    // Strictly unverified pending admin review
    return {
      'success': true,
      'is_verified': false,
      'status': 'pending_admin_review',
    };
  }

  @override
  Future<List<MicroCredential>> getUserCredentials([String? userId]) async => mockCredentials;
}

void main() {
  group('Community & Learning Domain Tests', () {
    test('LocalityTrustIndex levels resolution', () {
      expect(TrustLevel.fromString('high'), TrustLevel.high);
      expect(TrustLevel.fromString('medium'), TrustLevel.medium);
      expect(TrustLevel.fromString('needs_improvement'), TrustLevel.needsImprovement);
      expect(TrustLevel.fromString('low'), TrustLevel.needsImprovement);
    });

    test('LearningModule quiz pass and fail calculation', () {
      final fakeRepo = FakeCommunityRepository();
      final mod = fakeRepo.mockModules.first;

      // 3/3 questions correct = 100% -> Pass
      final scorePass = ((3 / mod.questions.length) * 100).round();
      expect(scorePass, 100);
      expect(scorePass >= mod.passPercent, true);

      // 2/3 questions correct = 67% -> Fail (needs 80%)
      final scoreFail = ((2 / mod.questions.length) * 100).round();
      expect(scoreFail, 67);
      expect(scoreFail >= mod.passPercent, false);
    });

    test('MicroCredential verification status: module is verified, upload is unverified', () {
      final fakeRepo = FakeCommunityRepository();
      final creds = fakeRepo.mockCredentials;

      final moduleCred = creds.firstWhere((c) => c.sourceType == 'module');
      final uploadedCred = creds.firstWhere((c) => c.sourceType == 'uploaded_certificate');

      // Module credential is auto-verified
      expect(moduleCred.isVerified, true);

      // External certificate upload MUST be pending review and unverified
      expect(uploadedCred.isVerified, false);
    });

    test('Event registration and certificate upload RPC behavior', () async {
      final fakeRepo = FakeCommunityRepository();

      final regResult = await fakeRepo.registerForTrainingEvent('ev-1');
      expect(regResult['success'], true);
      expect(regResult['status'], 'registered');

      final uploadResult = await fakeRepo.uploadExternalCertificate(
        kind: 'diploma',
        title: 'Safety Diploma',
        issuingOrg: 'Safety Institute',
        certificatePath: 'doc.pdf',
      );
      expect(uploadResult['success'], true);
      expect(uploadResult['is_verified'], false);
      expect(uploadResult['status'], 'pending_admin_review');
    });
  });

  group('Community & Learning Screens Widget Tests', () {
    testWidgets('CommunityHubScreen renders locality trust index and upcoming events cleanly', (tester) async {
      tester.view.physicalSize = const Size(360, 800) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeCommunityRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityRepositoryProvider.overrideWithValue(fakeRepo),
            localityTrustProvider.overrideWith((ref) => Future.value(fakeRepo.mockTrust)),
            communityPostsProvider(null).overrideWith((ref) => Future.value(fakeRepo.mockPosts)),
            trainingEventsProvider.overrideWith((ref) => Future.value(fakeRepo.mockEvents)),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: CommunityHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Locality Trust Index'), findsOneWidget);
      expect(find.text('Bengaluru South & Rural Hub'), findsOneWidget);
      expect(find.text('Upcoming Training Camps & Events'), findsOneWidget);
      expect(find.text('Workplace Electrical Safety Workshop'), findsOneWidget);
      expect(find.text('Register Interest'), findsOneWidget);
    });

    testWidgets('LearningHubScreen renders micro-credentials ribbon and course cards cleanly', (tester) async {
      tester.view.physicalSize = const Size(360, 800) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeCommunityRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityRepositoryProvider.overrideWithValue(fakeRepo),
            userCredentialsProvider.overrideWith((ref) => Future.value(fakeRepo.mockCredentials)),
            learningModulesProvider.overrideWith((ref) => Future.value(fakeRepo.mockModules)),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: LearningHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Earned Micro-Credentials'), findsOneWidget);
      expect(find.text('Worksite Safety Certified'), findsOneWidget);
      expect(find.text('ITI Electrician Diploma'), findsOneWidget);
      expect(find.text('Micro-Courses (5 Mins Each)'), findsOneWidget);
      expect(find.text('Worksite Safety & Emergency Protocols'), findsOneWidget);
    });
  });
}
