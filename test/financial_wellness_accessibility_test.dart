import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/services/offline_cache_service.dart';
import 'package:udyogasethu/core/services/voice_hints_helper.dart';
import 'package:udyogasethu/core/widgets/offline_banner_wrapper.dart';
import 'package:udyogasethu/core/widgets/simple_mode_action_dock.dart';
import 'package:udyogasethu/features/account/domain/user_settings.dart';
import 'package:udyogasethu/features/account/presentation/settings_controller.dart';
import 'package:udyogasethu/features/account/presentation/settings_screen.dart';
import 'package:udyogasethu/features/farmer/domain/ai_assist_models.dart';
import 'package:udyogasethu/features/trust/data/trust_repository.dart';
import 'package:udyogasethu/features/trust/domain/favourite_item.dart';
import 'package:udyogasethu/features/trust/domain/repeat_client.dart';
import 'package:udyogasethu/features/trust/presentation/favourites_screen.dart';
import 'trust_reviews_favourites_disputes_test.dart';
import 'package:udyogasethu/features/wallet/data/credit_readiness_repository.dart';
import 'package:udyogasethu/features/wallet/domain/credit_readiness_profile.dart';
import 'package:udyogasethu/features/wallet/presentation/credit_readiness_screen.dart';
import 'package:udyogasethu/features/wellness/data/wellness_repository.dart';
import 'package:udyogasethu/features/wellness/domain/wellness_models.dart';
import 'package:udyogasethu/features/wellness/presentation/wellness_benefits_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

// ----------------------------------------------------------------------
// Mock Repositories & Notifiers
// ----------------------------------------------------------------------

class MockCreditReadinessRepository implements CreditReadinessRepository {
  final CreditReadinessProfile profile;

  MockCreditReadinessRepository([CreditReadinessProfile? profile])
      : profile = profile ??
            CreditReadinessProfile.fromMetrics(
              identityVerified: true,
              bankLinked: true,
              ratingAvg: 4.8,
              ratingCount: 15,
              completedJobsCount: 12,
              totalEarnedPaise: 7200000,
              accountTenureDays: 45,
              disputesCount: 0,
            );

  @override
  Future<CreditReadinessProfile> fetchReadinessProfile([String? userId]) async {
    return profile;
  }
}

class MockWellnessRepository implements WellnessRepository {
  final List<GovernmentScheme> schemes;

  MockWellnessRepository([List<GovernmentScheme>? schemes])
      : schemes = schemes ??
            [
              const GovernmentScheme(
                id: 's-1',
                slug: 'pmsby',
                nameEn: 'Pradhan Mantri Suraksha Bima Yojana',
                nameKn: 'ಪ್ರಧಾನಮಂತ್ರಿ ಸುರಕ್ಷಾ ಬಿಮಾ ಯೋಜನೆ',
                nameHi: 'प्रधानमंत्री सुरक्षा बीमा योजना',
                nameTe: 'ಪ್ರಧಾನ ಮಂತ್ರಿ ಸುರಕ್ಷಾ ಬೀಮಾ ಯೋಜನಾ',
                nameTa: 'பிரதம மந்திரி சுரக்ஷா பீமா யோஜனா',
                shortDescriptionEn: 'Accidental death and disability insurance coverage of ₹2 Lakhs.',
                shortDescriptionKn: 'ಆಕಸ್ಮಿಕ ಸಾವು ಮತ್ತು ಅಂಗವೈಕಲ್ಯ ವಿಮೆ ₹2 ಲಕ್ಷ.',
                shortDescriptionHi: '₹2 लाख का दुर्घटना मृत्यु और विकलांगता बीमा।',
                shortDescriptionTe: '₹2 లక్షల ప్రమాద మరణ మరియు వైకల్య బీమా.',
                shortDescriptionTa: '₹2 லட்சம் விபத்து மற்றும் இயலாமை காப்பீடு.',
                officialUrl: 'https://financialservices.gov.in/beta/en/pmsby',
                category: 'insurance',
                benefitsSummary: '₹2,00,000 for accidental death or permanent total disability.',
                documentsRequired: ['Aadhaar Card', 'Bank Passbook'],
              ),
              const GovernmentScheme(
                id: 's-2',
                slug: 'pm-jay',
                nameEn: 'Ayushman Bharat PM-JAY',
                nameKn: 'ಆಯುಷ್ಮಾನ್ ಭಾರತ್',
                nameHi: 'आयुष्मान भारत',
                nameTe: 'ఆయుష్మాన్ భారత్',
                nameTa: 'ஆயுஷ்மான் பாரத்',
                shortDescriptionEn: 'Cashless healthcare cover up to ₹5 Lakhs per family per year.',
                shortDescriptionKn: 'ವರ್ಷಕ್ಕೆ ₹5 ಲಕ್ಷದವರೆಗೆ ನಗದು ರಹಿತ ಚಿಕಿತ್ಸೆ.',
                shortDescriptionHi: 'प्रति परिवार प्रति वर्ष ₹5 लाख तक का कैशलेस स्वास्थ्य कवर।',
                shortDescriptionTe: 'కుటుంబానికి ఏడాదికి ₹5 లక్షల వరకు ఉచిత వైద్యం.',
                shortDescriptionTa: 'ஆண்டுக்கு ₹5 லட்சம் வரை கட்டணமில்லா மருத்துவ சிகிச்சை.',
                officialUrl: 'https://pmjay.gov.in',
                category: 'health',
                benefitsSummary: 'Up to ₹5,00,000 per family per year for secondary and tertiary care.',
                documentsRequired: ['Aadhaar Card', 'Ration Card'],
              ),
            ];

  @override
  Future<List<GovernmentScheme>> fetchSchemes({String? category}) async {
    if (category != null && category.isNotEmpty && category != 'all') {
      return schemes.where((s) => s.category == category).toList();
    }
    return schemes;
  }

  @override
  List<EmergencyHelplineItem> getHelplines() {
    return const [
      EmergencyHelplineItem(
        name: 'National Emergency Helpline',
        subtitle: 'Police, Fire, Ambulance 24x7',
        number: '112',
        badge: 'Toll-free',
        icon: Icons.emergency_rounded,
      ),
      EmergencyHelplineItem(
        name: 'e-Shram Workers Helpline',
        subtitle: 'Unorganized worker welfare & registration assistance',
        number: '14434',
        badge: 'MoLE Toll-free',
        icon: Icons.support_agent_rounded,
      ),
    ];
  }

  @override
  List<SafetyGuidelineItem> getSafetyGuidelines() {
    return const [
      SafetyGuidelineItem(
        title: 'Personal Protective Equipment (PPE)',
        category: 'Worksite Safety',
        summary: 'Essential gear requirements across construction, electrical, and plumbing tasks.',
        tips: [
          'Wear ISI-marked safety helmet on active construction and scaffolding zones.',
          'Always use non-conductive rubber sole shoes for electrical installations.',
        ],
        icon: Icons.health_and_safety_rounded,
      ),
    ];
  }
}

class FakeSettingsNotifier extends SettingsNotifier {
  final UserSettings _initial;
  FakeSettingsNotifier([this._initial = const UserSettings()]);

  @override
  UserSettings build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('P8.5 — Credit Readiness Guidance Tests', () {
    test('Calculates Strong Readiness band for fully verified profile', () {
      final profile = CreditReadinessProfile.fromMetrics(
        identityVerified: true,
        bankLinked: true,
        ratingAvg: 4.9,
        ratingCount: 20,
        completedJobsCount: 15,
        totalEarnedPaise: 8500000,
        accountTenureDays: 60,
        disputesCount: 0,
      );

      expect(profile.band, CreditReadinessBand.strong);
      expect(profile.conceptualScore, greaterThanOrEqualTo(75));
      expect(profile.pillars.length, 4);

      // Identity Pillar check
      final idPillar = profile.pillars.firstWhere((p) => p.id == 'identity');
      expect(idPillar.isCompleted, isTrue);
      expect(idPillar.scorePoints, 25);

      // Bank Pillar check
      final bankPillar = profile.pillars.firstWhere((p) => p.id == 'bank');
      expect(bankPillar.isCompleted, isTrue);

      // Actionable steps should not ask for identity verification
      expect(profile.actionableNextSteps.any((s) => s.contains('Verify your government ID')), isFalse);
    });

    test('Calculates Building band for unverified profile with missing data', () {
      final profile = CreditReadinessProfile.fromMetrics(
        identityVerified: false,
        bankLinked: false,
        ratingAvg: 0.0,
        ratingCount: 0,
        completedJobsCount: 0,
        totalEarnedPaise: 0,
        accountTenureDays: 2,
        disputesCount: 0,
      );

      expect(profile.band, CreditReadinessBand.building);
      expect(profile.conceptualScore, lessThan(40));
      expect(profile.actionableNextSteps.isNotEmpty, isTrue);
      expect(profile.actionableNextSteps.any((s) => s.contains('Aadhaar')), isTrue);
      expect(profile.actionableNextSteps.any((s) => s.contains('bank account')), isTrue);
    });

    test('Creates offline fallback profile correctly', () {
      final offlineProfile = CreditReadinessProfile.offline();
      expect(offlineProfile.conceptualScore, 0);
      expect(offlineProfile.band, CreditReadinessBand.building);
      expect(
        offlineProfile.actionableNextSteps.first.toLowerCase(),
        anyOf(contains('offline'), contains('internet')),
      );
    });

    testWidgets('CreditReadinessScreen renders exact mandatory disclaimer and no loan promises',
        (tester) async {
      final mockRepo = MockCreditReadinessRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            creditReadinessRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CreditReadinessScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mandatory disclaimer MUST be displayed prominently
      expect(
        find.textContaining('This is guidance only. It does not guarantee any loan.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Future links to regulated financial partners would need your consent.'),
        findsOneWidget,
      );

      // Verify pillars are present
      expect(find.text('Verified Identity', skipOffstage: false), findsOneWidget);
      expect(find.text('Bank Account & UPI', skipOffstage: false), findsOneWidget);
      expect(find.text('Income & Work Consistency', skipOffstage: false), findsOneWidget);
      expect(find.text('Ratings & Dispute Record', skipOffstage: false), findsOneWidget);

      // Verify educational footer after scrolling down
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('How Does UdyogaSethu Use This Guidance?'), findsOneWidget);

      // Verify NO illegal loan promises exist anywhere in screen
      expect(find.textContaining('Guaranteed Loan'), findsNothing);
      expect(find.textContaining('Pre-approved Loan'), findsNothing);
      expect(find.textContaining('Low Interest Rate'), findsNothing);
    });
  });

  group('P8.5 — Wellness and Benefits Tests', () {
    test('MockWellnessRepository returns welfare schemes and helplines', () async {
      final repo = MockWellnessRepository();
      final allSchemes = await repo.fetchSchemes();
      expect(allSchemes.length, 2);

      final helplines = repo.getHelplines();
      expect(helplines.length, 2);
      expect(helplines.any((h) => h.number == '112'), isTrue);
      expect(helplines.any((h) => h.number == '14434'), isTrue);

      final safety = repo.getSafetyGuidelines();
      expect(safety.length, 1);
      expect(safety.first.title, contains('Personal Protective Equipment'));
    });

    testWidgets('WellnessBenefitsScreen displays schemes, safety guidelines, and helplines tabs',
        (tester) async {
      final mockRepo = MockWellnessRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wellnessRepositoryProvider.overrideWithValue(mockRepo),
            governmentSchemesProvider.overrideWith((ref, cat) => mockRepo.fetchSchemes(category: cat)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WellnessBenefitsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title and tabs
      expect(find.text('Wellness & Benefits'), findsOneWidget);
      expect(find.text('Welfare Schemes'), findsOneWidget);
      expect(find.text('Safety Guidelines'), findsOneWidget);
      expect(find.text('Helplines'), findsOneWidget);

      // Welfare schemes tab is initial
      expect(find.text('Pradhan Mantri Suraksha Bima Yojana'), findsOneWidget);
      expect(find.text('Ayushman Bharat PM-JAY'), findsOneWidget);

      // Switch to Safety Guidelines tab
      await tester.tap(find.text('Safety Guidelines'));
      await tester.pumpAndSettle();
      expect(find.text('Personal Protective Equipment (PPE)'), findsOneWidget);

      // Switch to Helplines tab
      await tester.tap(find.text('Helplines'));
      await tester.pumpAndSettle();
      expect(find.text('National Emergency Helpline'), findsOneWidget);
      expect(find.text('112'), findsOneWidget);
      expect(find.text('e-Shram Workers Helpline'), findsOneWidget);
      expect(find.text('14434'), findsOneWidget);
    });
  });

  group('P8.5 — Trust Circles and Repeat Clients Tests', () {
    testWidgets('FavouritesScreen displays marketplace fairness banner and repeat clients',
        (tester) async {
      final mockFavourites = <FavouriteItem>[
        FavouriteItem(
          targetId: 'w-1',
          fullName: 'Anand Kumar',
          role: 'seeker',
          headline: 'Expert Plumber & Pipe Fitter',
          ratingAvg: 4.9,
          ratingCount: 30,
          jobsCompleted: 45,
          isVerified: true,
          dailyRatePaise: 75000,
          skills: const ['Plumbing'],
          favouritedAt: DateTime.now(),
        ),
      ];

      final mockRepeatClients = <RepeatClientItem>[
        RepeatClientItem(
          clientId: 'client-101',
          clientName: 'Sunita Sharma (Homeowner)',
          clientPhone: '+919845012345',
          completedJobsCount: 4,
          lastJobDate: DateTime.now().subtract(const Duration(days: 3)),
          isFavourite: true,
        ),
      ];

      final mockRepo = MockTrustRepository(
        favouriteItems: mockFavourites,
        repeatClientItems: mockRepeatClients,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trustRepositoryProvider.overrideWithValue(mockRepo),
            favouritesListProvider.overrideWith((ref) => mockRepo.fetchFavourites()),
            repeatClientsProvider.overrideWith((ref, workerId) => mockRepo.fetchRepeatClients(workerId)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FavouritesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title and fairness banner
      expect(find.text('Favourites & Trust Circles'), findsOneWidget);
      expect(
        find.textContaining('Trust Circles prioritize familiar connections for convenience without hiding other eligible workers in search.'),
        findsOneWidget,
      );

      // First tab shows saved favourites
      expect(find.text('Anand Kumar'), findsOneWidget);
      expect(find.text('Expert Plumber & Pipe Fitter'), findsOneWidget);
      expect(find.text('₹750/day'), findsOneWidget);

      // Switch to Repeat Clients tab
      await tester.tap(find.text('Repeat Clients'));
      await tester.pumpAndSettle();

      expect(find.text('Sunita Sharma (Homeowner)'), findsOneWidget);
      expect(find.textContaining('repeat jobs'), findsOneWidget);
    });
  });

  group('P8.6 — Simple Mode Tests', () {
    testWidgets('SimpleModeActionDock renders 6 essential actions and tactile grid',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SimpleModeActionDock(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and 6 action tiles
      expect(find.text('SIMPLE MODE'), findsOneWidget);
      expect(find.text('Essential Actions'), findsOneWidget);
      expect(find.text('Accept Job'), findsOneWidget);
      expect(find.text('Start Work'), findsOneWidget);
      expect(find.text('Complete Job'), findsOneWidget);
      expect(find.text('Book Worker'), findsOneWidget);
      expect(find.text('Pay / Wallet'), findsOneWidget);
      expect(find.text('Ask for Help'), findsOneWidget);

      // Exit button is present
      expect(find.text('Exit Simple Mode'), findsOneWidget);
    });
  });

  group('P8.6 — Low-Data Mode and Voice Hints Tests', () {
    testWidgets('SettingsScreen displays low-data savings banner when lowDataMode is active',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSettingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const UserSettings(
                  lowDataMode: true,
                  simpleMode: false,
                  voiceHints: true,
                  textScale: 1.0,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Low-data banner should be rendered
      expect(find.textContaining('Low-Data active • Estimated ~2.4 MB data saved'), findsOneWidget);
    });

    testWidgets('VoiceHintSpeakerButton renders without error and handles tap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VoiceHintSpeakerButton(
                hintText: 'Welcome to UdyogaSethu.',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(VoiceHintSpeakerButton), findsOneWidget);
      await tester.tap(find.byType(VoiceHintSpeakerButton));
      await tester.pump();
    });
  });

  group('P8.6 — Offline Cache Service & Prohibited Action Blocking Tests', () {
    late OfflineCacheService service;

    setUp(() {
      service = OfflineCacheService();
    });

    test('Caches and retrieves sanitized jobs, orders, and emergency contacts', () async {
      final sampleJobs = <CachedJobSummary>[
        CachedJobSummary(
          id: 'job-1',
          title: 'Daily Plumbing Shift',
          wageRupees: 750,
          status: 'assigned',
          address: 'HSR Layout Sector 2',
          employerName: 'Ramesh Builders',
          scheduledAt: DateTime.now(),
        ),
      ];

      final sampleOrders = <CachedOrderSummary>[
        CachedOrderSummary(
          id: 'order-1',
          status: 'confirmed',
          totalRupees: 1200,
          counterpartyName: 'Sri Lakshmi Farm',
          itemsSummary: '2x Organic Honey Jars',
          createdAt: DateTime.now(),
        ),
      ];

      final sampleContacts = <CachedContactSummary>[
        const CachedContactSummary(
          name: 'Sunita Sharma',
          phone: '+919845012345',
          relationship: 'Spouse',
        ),
      ];

      await service.cacheTodayJobs(sampleJobs);
      await service.cacheActiveOrders(sampleOrders);
      await service.cacheEmergencyContacts(sampleContacts);

      final retrievedJobs = await service.getCachedTodayJobs();
      expect(retrievedJobs.length, 1);
      expect(retrievedJobs.first.title, 'Daily Plumbing Shift');

      final retrievedOrders = await service.getCachedActiveOrders();
      expect(retrievedOrders.length, 1);
      expect(retrievedOrders.first.counterpartyName, 'Sri Lakshmi Farm');

      final retrievedContacts = await service.getCachedEmergencyContacts();
      expect(retrievedContacts.length, 1);
      expect(retrievedContacts.first.name, 'Sunita Sharma');

      final lastSync = await service.getLastSyncTimestamp();
      expect(lastSync, isNotNull);

      // Test clearing all cache
      await service.clearAllCache();
      final clearedJobs = await service.getCachedTodayJobs();
      expect(clearedJobs, isEmpty);
    });

    test('Enqueues safe non-sensitive actions and skips duplicates', () async {
      await service.enqueueAction(
        actionType: 'toggle_favourite',
        payload: {'target_id': 'user-101', 'is_fav': true},
      );

      var queue = await service.getQueuedActions();
      expect(queue.length, 1);
      expect(queue.first.actionType, 'toggle_favourite');

      // Attempt duplicate enqueue of identical target_id
      await service.enqueueAction(
        actionType: 'toggle_favourite',
        payload: {'target_id': 'user-101', 'is_fav': true},
      );

      queue = await service.getQueuedActions();
      expect(queue.length, 1, reason: 'Duplicate action should be skipped to prevent double submission');

      // Dequeue/remove
      await service.removeQueuedAction(queue.first.id);
      queue = await service.getQueuedActions();
      expect(queue, isEmpty);
    });

    test('STRICTLY BLOCKS financial, payment, QR, and verification actions from offline queue', () async {
      const prohibitedActions = [
        'payment',
        'escrow_release',
        'upi_checkout',
        'verify_qr',
        'scan_ticket',
        'attendance_selfie',
        'ekyc_verify',
        'payout_withdrawal',
      ];

      for (final action in prohibitedActions) {
        expect(
          () => service.enqueueAction(
            actionType: action,
            payload: {'amount': 1000},
          ),
          throwsA(isA<BlockedOfflineActionException>()),
          reason: 'Prohibited offline action "$action" must immediately throw BlockedOfflineActionException',
        );
      }
    });
  });

  group('P8.6 — Offline Banner Wrapper Tests', () {
    testWidgets('Displays offline banner when isOnline is false', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => Stream.value(false)),
          ],
          child: const MaterialApp(
            home: OfflineBannerWrapper(
              child: Scaffold(
                body: Center(child: Text('Main Content Screen')),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Main Content Screen'), findsOneWidget);
      expect(find.textContaining('Offline Mode'), findsOneWidget);
    });
  });

  group('P8.6 — Zero Layout Overflow Safety Matrix (1.0x to 1.6x scales)', () {
    const testWidths = [320.0, 360.0, 412.0, 600.0];
    const testScales = [1.0, 1.3, 1.6];
    const testLocales = [
      Locale('en'),
      Locale('kn'),
      Locale('hi'),
      Locale('ta'),
      Locale('te'),
    ];

    Future<void> runMatrixCheck({
      required WidgetTester tester,
      required String componentName,
      required Widget Function(BuildContext context) builder,
      List<dynamic> overrides = const [],
    }) async {
      for (final width in testWidths) {
        for (final scale in testScales) {
          for (final loc in testLocales) {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            String? detectedOverflow;
            final prevOnError = FlutterError.onError;
            FlutterError.onError = (details) {
              final msg = details.exceptionAsString();
              if (msg.contains('overflowed by') || msg.contains('RenderFlex overflowed')) {
                detectedOverflow = details.toString();
              }
            };

            try {
              await tester.pumpWidget(
                ProviderScope(
                  overrides: overrides.cast(),
                  child: MaterialApp(
                    locale: loc,
                    localizationsDelegates: AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: Scaffold(
                      body: Builder(
                        builder: (ctx) {
                          return MediaQuery(
                            data: MediaQueryData(
                              size: Size(width, 900),
                              textScaler: TextScaler.linear(scale),
                            ),
                            child: builder(ctx),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump();
            } finally {
              FlutterError.onError = prevOnError;
            }

            final exc = tester.takeException();
            if (exc != null && detectedOverflow == null) {
              if (exc.toString().contains('overflowed')) {
                detectedOverflow = exc.toString();
              }
            }

            expect(
              detectedOverflow,
              isNull,
              reason: '$componentName OVERFLOWED at width ${width.toInt()}dp, scale $scale, locale ${loc.languageCode}:\n$detectedOverflow',
            );
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    testWidgets('SimpleModeActionDock zero layout overflow matrix check', (tester) async {
      await runMatrixCheck(
        tester: tester,
        componentName: 'SimpleModeActionDock',
        builder: (ctx) => const SingleChildScrollView(
          child: SimpleModeActionDock(),
        ),
      );
    });

    testWidgets('CreditReadinessScreen zero layout overflow matrix check', (tester) async {
      final mockRepo = MockCreditReadinessRepository();
      await runMatrixCheck(
        tester: tester,
        componentName: 'CreditReadinessScreen',
        overrides: [
          creditReadinessRepositoryProvider.overrideWithValue(mockRepo),
        ],
        builder: (ctx) => const CreditReadinessScreen(),
      );
    });

    testWidgets('WellnessBenefitsScreen zero layout overflow matrix check', (tester) async {
      final mockRepo = MockWellnessRepository();
      await runMatrixCheck(
        tester: tester,
        componentName: 'WellnessBenefitsScreen',
        overrides: [
          wellnessRepositoryProvider.overrideWithValue(mockRepo),
          governmentSchemesProvider.overrideWith((ref, cat) => mockRepo.fetchSchemes(category: cat)),
        ],
        builder: (ctx) => const WellnessBenefitsScreen(),
      );
    });

    testWidgets('FavouritesScreen zero layout overflow matrix check', (tester) async {
      final mockRepo = MockTrustRepository(
        favouriteItems: [
          FavouriteItem(
            targetId: 'w-1',
            fullName: 'Anand Kumar Senior Technician',
            role: 'seeker',
            headline: 'Expert Plumber & Pipe Fitter',
            ratingAvg: 4.9,
            ratingCount: 30,
            jobsCompleted: 45,
            isVerified: true,
            dailyRatePaise: 75000,
            skills: const ['Plumbing'],
            favouritedAt: DateTime.now(),
          ),
        ],
        repeatClientItems: [
          RepeatClientItem(
            clientId: 'client-1',
            clientName: 'Sunita Sharma Homeowner Residency',
            clientPhone: '+919845012345',
            completedJobsCount: 3,
            lastJobDate: DateTime.now(),
            isFavourite: true,
          ),
        ],
      );

      await runMatrixCheck(
        tester: tester,
        componentName: 'FavouritesScreen',
        overrides: [
          trustRepositoryProvider.overrideWithValue(mockRepo),
          favouritesListProvider.overrideWith((ref) => mockRepo.fetchFavourites()),
          repeatClientsProvider.overrideWith((ref, workerId) => mockRepo.fetchRepeatClients(workerId)),
        ],
        builder: (ctx) => const FavouritesScreen(),
      );
    });
  });
}
