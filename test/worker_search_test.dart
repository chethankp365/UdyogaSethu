import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/provider/data/worker_search_repository.dart';
import 'package:udyogasethu/features/provider/domain/nearby_worker.dart';
import 'package:udyogasethu/features/provider/domain/provider_active_booking.dart';
import 'package:udyogasethu/features/provider/domain/worker_detail_profile.dart';
import 'package:udyogasethu/features/provider/domain/worker_filter_criteria.dart';
import 'package:udyogasethu/features/provider/presentation/worker_profile_screen.dart';
import 'package:udyogasethu/features/provider/presentation/worker_search_screen.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeWorkerSearchRepository implements WorkerSearchRepository {
  List<NearbyWorker> mockWorkers = [
    const NearbyWorker(
      userId: 'w-1',
      fullName: 'Ravi Kumar',
      headline: 'Certified Electrician',
      bio: '10 years experience in residential and commercial wiring',
      seekerType: 'informal',
      dailyRatePaise: 90000,
      hourlyRatePaise: 15000,
      ratingAvg: 4.8,
      ratingCount: 34,
      jobsCompleted: 48,
      isVerifiedBadge: true,
      distanceM: 1200,
      languages: ['Kannada', 'English', 'Hindi'],
      skills: [
        WorkerSkillItem(id: 's1', name: 'Wiring'),
        WorkerSkillItem(id: 's2', name: 'Appliance Repair'),
      ],
      availability: 'available',
      gender: 'male',
      experienceYears: 8.5,
    ),
    const NearbyWorker(
      userId: 'w-2',
      fullName: 'Lakshmi Devi',
      headline: 'Plumbing Specialist',
      bio: 'Expert in pipeline repair and water heater installation',
      seekerType: 'informal',
      dailyRatePaise: 80000,
      hourlyRatePaise: 12000,
      ratingAvg: 4.9,
      ratingCount: 52,
      jobsCompleted: 65,
      isVerifiedBadge: true,
      distanceM: 850,
      languages: ['Kannada', 'Telugu'],
      skills: [
        WorkerSkillItem(id: 's3', name: 'Pipe Fitting'),
      ],
      availability: 'available',
      gender: 'female',
      experienceYears: 6.0,
    ),
  ];

  @override
  Future<List<NearbyWorker>> searchNearbyWorkers({
    required double lat,
    required double lng,
    required WorkerFilterCriteria criteria,
  }) async {
    return mockWorkers.where((w) {
      if (criteria.verifiedOnly && !w.isVerifiedBadge) return false;
      if (criteria.language != null && !w.speaksLanguage(criteria.language!)) return false;
      if (criteria.genderPreference != null &&
          criteria.genderPreference!.toLowerCase() != 'all' &&
          w.gender?.toLowerCase() != criteria.genderPreference!.toLowerCase()) {
        return false;
      }
      if (criteria.minRating != null && w.ratingAvg < criteria.minRating!) return false;
      if (criteria.searchQuery != null && criteria.searchQuery!.isNotEmpty) {
        final q = criteria.searchQuery!.toLowerCase();
        final match = w.fullName.toLowerCase().contains(q) ||
            w.headline.toLowerCase().contains(q) ||
            w.skills.any((s) => s.name.toLowerCase().contains(q));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<WorkerDetailProfile> getWorkerProfileDetail(
    String workerId, {
    double? callerLat,
    double? callerLng,
  }) async {
    return WorkerDetailProfile(
      userId: workerId,
      fullName: 'Ravi Kumar',
      phone: '+91 98765 43210',
      headline: 'Certified Electrician',
      gender: 'male',
      experienceYears: 8.5,
      dailyRatePaise: 90000,
      hourlyRatePaise: 15000,
      ratingAvg: 4.8,
      ratingCount: 34,
      jobsCompleted: 48,
      isVerifiedBadge: true,
      distanceM: 1200,
      languages: const ['Kannada', 'English', 'Hindi'],
      skills: const [
        WorkerSkillItem(id: 's1', name: 'Wiring'),
        WorkerSkillItem(id: 's2', name: 'Appliance Repair'),
      ],
      trustBadges: const [
        TrustBadgeItem(code: 'aadhaar_face', title: 'Aadhaar Face Verified', verified: true),
        TrustBadgeItem(code: 'police_check', title: 'Police Record Verified', verified: true),
      ],
      reviews: const [
        WorkerReviewItem(id: 'r1', raterName: 'Karthik Rao', stars: 5, comment: 'Punctual and neat work!'),
      ],
      isFavourite: false,
    );
  }

  @override
  Future<ProviderActiveBooking?> getActiveBooking({String? providerId}) async {
    return ProviderActiveBooking.demoBooking();
  }

  @override
  Future<bool> toggleFavourite(String targetId) async => true;

  @override
  Future<List<ServiceCategoryItem>> getCategories() async {
    return const [
      ServiceCategoryItem(
        id: 'cat-elec',
        slug: 'electrician',
        names: {'en': 'Electrician', 'kn': 'ಎಲೆಕ್ಟ್ರಿಷಿಯನ್'},
        icon: 'electrical_services',
      ),
      ServiceCategoryItem(
        id: 'cat-plumb',
        slug: 'plumbing',
        names: {'en': 'Plumbing', 'kn': 'ಪ್ಲಂಬಿಂಗ್'},
        icon: 'plumbing',
      ),
    ];
  }
}

Widget createTestApp(Widget child, [FakeWorkerSearchRepository? fakeRepo]) {
  final repo = fakeRepo ?? FakeWorkerSearchRepository();
  return ProviderScope(
    overrides: [
      workerSearchRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P4.5 Domain Models & Logic', () {
    test('NearbyWorker computes formatted rate and distance correctly', () {
      const worker = NearbyWorker(
        userId: 'w-1',
        fullName: 'Ravi Kumar',
        headline: 'Electrician',
        dailyRatePaise: 90000,
        distanceM: 750,
        languages: ['Kannada', 'English'],
      );

      expect(worker.formattedRate, '₹900/day');
      expect(worker.formattedDistance, '750 m away');
      expect(worker.speaksLanguage('Kannada'), isTrue);
      expect(worker.speaksLanguage('Hindi'), isFalse);
    });

    test('NearbyWorker distance formatting formats kilometers above 1000m', () {
      const worker = NearbyWorker(
        userId: 'w-2',
        fullName: 'Lakshmi Devi',
        headline: 'Plumber',
        dailyRatePaise: 80000,
        distanceM: 2500,
      );

      expect(worker.formattedDistance, '2.5 km away');
      expect(worker.formattedRate, '₹800/day');
    });

    test('WorkerFilterCriteria copyWith updates properties accurately', () {
      const criteria = WorkerFilterCriteria();
      expect(criteria.radiusKm, 10.0);
      expect(criteria.verifiedOnly, isFalse);

      final updated = criteria.copyWith(
        radiusKm: 25.0,
        verifiedOnly: true,
        language: 'Kannada',
      );

      expect(updated.radiusKm, 25.0);
      expect(updated.verifiedOnly, isTrue);
      expect(updated.language, 'Kannada');
    });

    test('ProviderActiveBooking calculates active status properties correctly', () {
      final booking = ProviderActiveBooking.demoBooking();
      expect(booking.bookingCode, 'BOOK-7842');
      expect(booking.jobTitle, 'Commercial Electrical Repair');
      expect(booking.roleName, 'Electrician');
      expect(booking.workerName, 'Chethan Kumar');
      expect(booking.formattedEscrowWage, '₹880/day Escrow Held');
      expect(booking.formattedScheduledTime, contains('Shift'));
      expect(booking.status, 'accepted');
    });
  });

  group('P4.5 Worker Search & Profile UI', () {
    testWidgets('WorkerSearchScreen renders header, search field, chips, and worker list', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeWorkerSearchRepository();
      await tester.pumpWidget(createTestApp(const WorkerSearchScreen(), fakeRepo));
      await tester.pumpAndSettle();

      // Check header and search bar
      expect(find.text('Search Workers'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Check filter row buttons
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.text('10 km'), findsOneWidget);

      // Check worker cards
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Lakshmi Devi'), findsOneWidget);
      expect(find.text('Certified Electrician'), findsOneWidget);
      expect(find.text('Plumbing Specialist'), findsOneWidget);
      expect(find.text('₹900/day'), findsOneWidget);
      expect(find.text('₹800/day'), findsOneWidget);
      expect(find.text('1.2 km away'), findsOneWidget);
      expect(find.text('850 m away'), findsOneWidget);
    });

    testWidgets('WorkerProfileScreen renders profile header, badges, reviews, and action buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeWorkerSearchRepository();
      await tester.pumpWidget(createTestApp(const WorkerProfileScreen(workerId: 'w-1'), fakeRepo));
      await tester.pumpAndSettle();

      // Check profile header details
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Certified Electrician'), findsOneWidget);
      expect(find.text('₹900/day'), findsOneWidget);
      expect(find.text('• 1.2 km away'), findsOneWidget);
      expect(find.text('48'), findsOneWidget); // jobs completed
      expect(find.text('8.5 yrs'), findsOneWidget); // experience

      // Check trust credentials
      expect(find.text('Aadhaar Face Verified'), findsOneWidget);
      expect(find.text('Police Record Verified'), findsOneWidget);

      // Check action buttons in bottom bar
      expect(find.text('Protected Chat'), findsOneWidget);
      expect(find.text('Book Worker'), findsOneWidget);
    });
  });
}
