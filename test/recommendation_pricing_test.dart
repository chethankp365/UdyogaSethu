import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';
import 'package:udyogasethu/features/matching/data/recommendation_pricing_service.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

void main() {
  const service = RecommendationPricingService();

  group('RecommendationPricingService - Fair Wage Suggestions', () {
    test('Calculates base fair wage without modifiers', () {
      final sug = service.calculateWageSuggestion(
        benchmarkMinPaise: 70000,
        benchmarkMaxPaise: 100000,
        unit: 'daily',
        yearsOfExperience: 0,
        isUrgent: false,
        isHighDemand: false,
      );

      expect(sug.suggestedMinRupees, 700);
      expect(sug.suggestedMaxRupees, 1000);
      expect(sug.isBelowSuggested(65000), isTrue);
      expect(sug.isBelowSuggested(75000), isFalse);
    });

    test('Applies experience modifier (+5% per year up to 25%)', () {
      final sug = service.calculateWageSuggestion(
        benchmarkMinPaise: 80000,
        benchmarkMaxPaise: 100000,
        yearsOfExperience: 3, // +15%
      );

      expect(sug.suggestedMinRupees, 920); // 800 * 1.15
      expect(sug.suggestedMaxRupees, 1150); // 1000 * 1.15
      expect(sug.explanationFactors.any((f) => f.contains('+15% for 3 years')), isTrue);
    });

    test('Applies urgency and high-demand premiums', () {
      final sug = service.calculateWageSuggestion(
        benchmarkMinPaise: 100000,
        benchmarkMaxPaise: 120000,
        isUrgent: true, // +15%
        isHighDemand: true, // +10%
      );

      // Total multiplier = 1 + 0.15 + 0.10 = 1.25
      expect(sug.suggestedMinRupees, 1250);
      expect(sug.suggestedMaxRupees, 1500);
      expect(sug.explanationFactors.any((f) => f.contains('urgency premium')), isTrue);
      expect(sug.explanationFactors.any((f) => f.contains('demand adjustment')), isTrue);
    });
  });

  group('RecommendationPricingService - Farmer Price Suggestions', () {
    test('Calculates base mandi band with 10% direct-to-consumer margin', () {
      final sug = service.calculateFarmerPriceBand(
        commodity: 'tomato',
        mandiModalPriceRupees: 20.0,
        season: 'normal',
      );

      // Modal = 20 * 1.10 = 22
      // Min = 22 * 0.90 = 19.8 -> ~20
      // Max = 22 * 1.15 = 25.3 -> ~25
      expect(sug.suggestedModalRupees, closeTo(22.0, 0.5));
      expect(sug.mandiMarket, contains('Karnataka APMC'));
    });

    test('Off-season scarcity adds +15% premium', () {
      final sug = service.calculateFarmerPriceBand(
        commodity: 'onion',
        mandiModalPriceRupees: 30.0,
        season: 'off_season',
      );

      // Multiplier = 1.10 + 0.15 = 1.25 -> 30 * 1.25 = 37.5
      expect(sug.suggestedModalRupees, closeTo(37.5, 0.5));
      expect(sug.explanation, contains('off-season supply scarcity'));
    });

    test('High platform demand adds +5% premium', () {
      final sug = service.calculateFarmerPriceBand(
        commodity: 'potato',
        mandiModalPriceRupees: 20.0,
        recentOrdersCount: 20,
      );

      // Multiplier = 1.10 + 0.05 = 1.15 -> 20 * 1.15 = 23
      expect(sug.suggestedModalRupees, closeTo(23.0, 0.5));
      expect(sug.explanation, contains('high platform consumer demand'));
    });
  });

  group('RecommendationPricingService - Worker Route Ordering', () {
    test('Empty and single-job schedule returns trivial route plan', () {
      final emptyPlan = service.optimizeRouteOrder(jobs: const []);
      expect(emptyPlan.hasMultipleStops, isFalse);
      expect(emptyPlan.stops, isEmpty);

      final singleItem = WorkerScheduleItem(
        assignmentId: 'a1',
        jobId: 'j1',
        title: 'Morning Plumbing',
        status: 'accepted',
        bookingCode: 'BK1',
        agreedWagePaise: 80000,
        startAt: DateTime(2026, 10, 15, 9, 0),
        endAt: DateTime(2026, 10, 15, 12, 0),
        estDurationMinutes: 180,
        addressText: 'Koramangala 4th Block',
        jobLat: 12.9352,
        jobLng: 77.6245,
        categorySlug: 'plumbing',
        categoryIcon: 'plumbing',
        providerName: 'Anil Kumar',
      );

      final singlePlan = service.optimizeRouteOrder(jobs: [singleItem]);
      expect(singlePlan.stops.length, 1);
      expect(singlePlan.hasMultipleStops, isFalse);
      expect(singlePlan.totalDistanceKm, 0.0);
    });

    test('Optimizes multiple jobs respecting start times and computes travel savings', () {
      final now = DateTime.now();
      // Job 1: Koramangala (9:00 AM)
      final job1 = WorkerScheduleItem(
        assignmentId: 'a1',
        jobId: 'j1',
        title: 'Job 1 - Koramangala',
        status: 'accepted',
        bookingCode: 'BK1',
        agreedWagePaise: 85000,
        startAt: DateTime(now.year, now.month, now.day, 9, 0),
        endAt: DateTime(now.year, now.month, now.day, 11, 0),
        estDurationMinutes: 120,
        addressText: 'Koramangala 5th Block',
        jobLat: 12.9352,
        jobLng: 77.6245,
        categorySlug: 'electrician',
        categoryIcon: 'electrician',
        providerName: 'Sunil',
      );

      // Job 2: HSR Layout (Close to Koramangala, 11:30 AM)
      final job2 = WorkerScheduleItem(
        assignmentId: 'a2',
        jobId: 'j2',
        title: 'Job 2 - HSR Layout',
        status: 'accepted',
        bookingCode: 'BK2',
        agreedWagePaise: 90000,
        startAt: DateTime(now.year, now.month, now.day, 11, 30),
        endAt: DateTime(now.year, now.month, now.day, 13, 30),
        estDurationMinutes: 120,
        addressText: 'HSR Layout Sector 2',
        jobLat: 12.9116,
        jobLng: 77.6389,
        categorySlug: 'electrician',
        categoryIcon: 'electrician',
        providerName: 'Kavitha',
      );

      // Job 3: Indiranagar (Farther away, 2:30 PM)
      final job3 = WorkerScheduleItem(
        assignmentId: 'a3',
        jobId: 'j3',
        title: 'Job 3 - Indiranagar',
        status: 'accepted',
        bookingCode: 'BK3',
        agreedWagePaise: 95000,
        startAt: DateTime(now.year, now.month, now.day, 14, 30),
        endAt: DateTime(now.year, now.month, now.day, 16, 30),
        estDurationMinutes: 120,
        addressText: 'Indiranagar 100ft Road',
        jobLat: 12.9784,
        jobLng: 77.6408,
        categorySlug: 'electrician',
        categoryIcon: 'electrician',
        providerName: 'Vikram',
      );

      final plan = service.optimizeRouteOrder(
        jobs: [job3, job1, job2], // passed in random order
        startLocation: const LatLng(12.9352, 77.6245),
      );

      expect(plan.hasMultipleStops, isTrue);
      expect(plan.stops.length, 3);
      // Sequenced 1, 2, 3
      expect(plan.stops[0].sequence, 1);
      expect(plan.stops[1].sequence, 2);
      expect(plan.stops[2].sequence, 3);
      // First stop should be morning job (Job 1)
      expect(plan.stops[0].item.title, contains('Koramangala'));
      expect(plan.totalTravelMinutes, greaterThan(0));
    });
  });

  group('RecommendationPricingService - Customer Recommendations', () {
    test('Provides curated workers, bundles, and seasonal products', () {
      final recs = service.getCustomerRecommendations();

      expect(recs.workers.length, greaterThanOrEqualTo(3));
      expect(recs.bundles.length, greaterThanOrEqualTo(2));
      expect(recs.seasonalProduce.length, greaterThanOrEqualTo(3));

      // Worker attributes
      final firstWorker = recs.workers.first;
      expect(firstWorker.isVerified, isTrue);
      expect(firstWorker.rating, greaterThanOrEqualTo(4.5));
      expect(firstWorker.reason, isNotEmpty);

      // Bundle attributes
      final firstBundle = recs.bundles.first;
      expect(firstBundle.discountPercent, greaterThan(0));
      expect(firstBundle.items, isNotEmpty);
    });
  });

  group('Why This Job - Reasons Explanation', () {
    test('JobRecommendation reasons contain explainable criteria', () {
      const job = JobRecommendation(
        id: 'job-1',
        providerId: 'prov-1',
        title: 'Electrician Maintenance',
        employerName: 'Sai Electricals',
        categorySlug: 'electrician',
        employerRating: 4.9,
        employerVerified: true,
        wagePaise: 88000,
        wageType: 'daily',
        distanceM: 800,
        reasons: ['Skill match', 'Nearby (0.8 km)', 'Fair wage compliant', 'Top employer'],
        score: 92.0,
      );

      expect(job.reasons.length, 4);
      expect(job.reasons, contains('Skill match'));
      expect(job.reasons, contains('Nearby (0.8 km)'));
      expect(job.formattedWage, '₹880');
      expect(job.formattedDistance, '800 m');
    });
  });
}
