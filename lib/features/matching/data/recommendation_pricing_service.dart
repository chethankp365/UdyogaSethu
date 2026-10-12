import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/features/farmer/domain/price_suggestion_model.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';
import 'package:udyogasethu/features/matching/domain/customer_recommendation.dart';
import 'package:udyogasethu/features/matching/domain/route_order_plan.dart';
import 'package:udyogasethu/features/matching/domain/wage_suggestion.dart';

/// Pure Dart, testable recommendation, fair wage, pricing and route optimization service.
class RecommendationPricingService {
  const RecommendationPricingService();

  // ---------------------------------------------------------------------------
  // 1. FAIR WAGE SUGGESTION (Rule-based, explainable)
  // ---------------------------------------------------------------------------
  WageSuggestion calculateWageSuggestion({
    required int benchmarkMinPaise,
    required int benchmarkMaxPaise,
    String unit = 'daily',
    int yearsOfExperience = 0,
    bool isUrgent = false,
    bool isHighDemand = false,
  }) {
    final factors = <String>[];
    final minRupees = (benchmarkMinPaise / 100).round();
    final maxRupees = (benchmarkMaxPaise / 100).round();
    factors.add('Base market benchmark: ₹$minRupees – ₹$maxRupees per $unit');

    // Experience multiplier: +5% per year up to 25% max
    final expYears = yearsOfExperience.clamp(0, 10);
    final expMultiplier = min(expYears * 0.05, 0.25);
    if (expMultiplier > 0) {
      final pct = (expMultiplier * 100).round();
      factors.add('+$pct% for $yearsOfExperience years verified experience');
    }

    // Urgency multiplier: +15% for immediate same-day dispatch
    final urgencyMultiplier = isUrgent ? 0.15 : 0.0;
    if (isUrgent) {
      factors.add('+15% urgency premium for same-day request');
    }

    // High demand multiplier: +10% during peak hours/demand clusters
    final demandMultiplier = isHighDemand ? 0.10 : 0.0;
    if (isHighDemand) {
      factors.add('+10% locality demand adjustment');
    }

    final totalMultiplier = 1.0 + expMultiplier + urgencyMultiplier + demandMultiplier;
    final suggestedMin = (benchmarkMinPaise * totalMultiplier).round();
    final suggestedMax = (benchmarkMaxPaise * totalMultiplier).round();

    factors.add('Rule-based suggestion: Employers and workers retain 100% price freedom.');

    return WageSuggestion(
      benchmarkMinPaise: benchmarkMinPaise,
      benchmarkMaxPaise: benchmarkMaxPaise,
      unit: unit,
      yearsOfExperience: yearsOfExperience,
      isUrgent: isUrgent,
      isHighDemand: isHighDemand,
      suggestedMinPaise: suggestedMin,
      suggestedMaxPaise: suggestedMax,
      explanationFactors: factors,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FARMER PRICE BAND (Explainable seasonal & mandi band)
  // ---------------------------------------------------------------------------
  PriceSuggestion calculateFarmerPriceBand({
    required String commodity,
    required double mandiModalPriceRupees,
    String season = 'normal', // 'peak_harvest', 'off_season', 'normal'
    double stockQuantityKg = 100,
    int recentOrdersCount = 5,
    String marketName = 'Karnataka APMC',
  }) {
    // Direct-to-consumer farm-fresh premium: 10% base
    double modalMultiplier = 1.10;
    final reasons = <String>[];
    reasons.add('APMC Mandi wholesale benchmark: ₹${mandiModalPriceRupees.toStringAsFixed(0)}/kg');

    if (season == 'off_season') {
      modalMultiplier += 0.15;
      reasons.add('+15% off-season supply scarcity premium');
    } else if (season == 'peak_harvest') {
      modalMultiplier -= 0.05;
      reasons.add('-5% peak harvest volume adjustment');
    }

    if (recentOrdersCount > 15) {
      modalMultiplier += 0.05;
      reasons.add('+5% high platform consumer demand');
    }

    if (stockQuantityKg > 500) {
      modalMultiplier -= 0.05;
      reasons.add('-5% bulk farm inventory clearance');
    }

    final suggestedModalRupees = mandiModalPriceRupees * modalMultiplier;
    final suggestedMinRupees = suggestedModalRupees * 0.90;
    final suggestedMaxRupees = suggestedModalRupees * 1.15;

    reasons.add('Rule-based suggestion: Farmers retain complete pricing control.');

    return PriceSuggestion(
      commodity: commodity,
      mandiModalPriceRupees: mandiModalPriceRupees,
      mandiMarket: marketName,
      mandiArrivalDate: DateTime.now(),
      suggestedMinPaise: (suggestedMinRupees * 100).round(),
      suggestedMaxPaise: (suggestedMaxRupees * 100).round(),
      suggestedModalPaise: (suggestedModalRupees * 100).round(),
      explanation: reasons.join(' • '),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. WORKER ROUTE ORDERING (Nearest-neighbour respecting start times)
  // ---------------------------------------------------------------------------
  RouteOrderPlan optimizeRouteOrder({
    required List<WorkerScheduleItem> jobs,
    LatLng? startLocation,
  }) {
    if (jobs.isEmpty) {
      return RouteOrderPlan(
        date: DateTime.now(),
        stops: const [],
        totalDistanceKm: 0.0,
        totalTravelMinutes: 0,
        timeSavedMinutes: 0,
        originalDistanceKm: 0.0,
      );
    }

    if (jobs.length == 1) {
      final single = jobs.first;
      return RouteOrderPlan(
        date: single.startAt,
        stops: [
          RouteStop(
            sequence: 1,
            item: single,
            distanceToNextKm: 0.0,
            travelMinutesToNext: 0,
          ),
        ],
        totalDistanceKm: 0.0,
        totalTravelMinutes: 0,
        timeSavedMinutes: 0,
        originalDistanceKm: 0.0,
      );
    }

    // Baseline: Chronological order by start time
    final chronological = List<WorkerScheduleItem>.from(jobs)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final originalDistance = _calculateTotalDistance(chronological, startLocation);

    // Group jobs by strict start windows (gap >= 90 mins cannot be swapped)
    // For jobs within flexible/close windows (< 90 min difference), apply nearest neighbour
    final remaining = List<WorkerScheduleItem>.from(chronological);
    final ordered = <WorkerScheduleItem>[];

    LatLng currentPos = startLocation ?? remaining.first.location;

    while (remaining.isNotEmpty) {
      // Find candidate jobs that can be visited next based on earliest acceptable startAt
      final earliestStart = remaining.first.startAt;
      final candidates = remaining.where((item) {
        final diff = item.startAt.difference(earliestStart).inMinutes.abs();
        return diff <= 90; // Within 90-minute flexible window
      }).toList();

      // Pick nearest neighbour from candidates
      WorkerScheduleItem bestItem = candidates.first;
      double minDistance = double.infinity;

      for (final item in candidates) {
        final dist = _haversineDistance(currentPos, item.location);
        if (dist < minDistance) {
          minDistance = dist;
          bestItem = item;
        }
      }

      ordered.add(bestItem);
      remaining.remove(bestItem);
      currentPos = bestItem.location;
    }

    final optimizedDistance = _calculateTotalDistance(ordered, startLocation);

    // Build RouteStops with distance and travel time to next
    final stops = <RouteStop>[];
    for (int i = 0; i < ordered.length; i++) {
      final current = ordered[i];
      double distNext = 0.0;
      int timeNext = 0;

      if (i < ordered.length - 1) {
        final next = ordered[i + 1];
        distNext = _haversineDistance(current.location, next.location);
        // Average 3.5 minutes per km in Indian city traffic
        timeNext = max(10, (distNext * 3.5).round());
      }

      stops.add(RouteStop(
        sequence: i + 1,
        item: current,
        distanceToNextKm: double.parse(distNext.toStringAsFixed(1)),
        travelMinutesToNext: timeNext,
      ));
    }

    // Estimate time saved: 3.5 mins per km saved + 10 mins transition buffer
    final distanceDiff = max(0.0, originalDistance - optimizedDistance);
    final timeSaved = (distanceDiff * 3.5).round();
    final totalTravelMinutes = stops.fold<int>(0, (sum, s) => sum + s.travelMinutesToNext);

    return RouteOrderPlan(
      date: ordered.first.startAt,
      stops: stops,
      totalDistanceKm: double.parse(optimizedDistance.toStringAsFixed(1)),
      totalTravelMinutes: totalTravelMinutes,
      timeSavedMinutes: timeSaved,
      originalDistanceKm: double.parse(originalDistance.toStringAsFixed(1)),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. CUSTOMER RECOMMENDATIONS (Marketplace / Provider Hub)
  // ---------------------------------------------------------------------------
  CustomerRecommendationsState getCustomerRecommendations({
    String? currentUserId,
    String? categoryFilter,
  }) {
    // Curated high-rated workers
    final workers = [
      const RecommendedWorker(
        id: 'worker-rec-1',
        name: 'Ramesh Kumar',
        categoryName: 'Electrician',
        categorySlug: 'electrician',
        rating: 4.9,
        completedJobs: 84,
        distanceKm: 1.2,
        dailyWagePaise: 88000,
        isVerified: true,
        reason: 'Skill match • 0.8 km away • 5★ rating',
        isRepeatBooking: true,
      ),
      const RecommendedWorker(
        id: 'worker-rec-2',
        name: 'Manjunath Swamy',
        categoryName: 'Plumber',
        categorySlug: 'plumbing',
        rating: 4.8,
        completedJobs: 62,
        distanceKm: 2.1,
        dailyWagePaise: 85000,
        isVerified: true,
        reason: 'Nearby • Fast 30-min response • Top employer rating',
        isRepeatBooking: false,
      ),
      const RecommendedWorker(
        id: 'worker-rec-3',
        name: 'Venkatesh Gowda',
        categoryName: 'Carpenter',
        categorySlug: 'carpenter',
        rating: 4.9,
        completedJobs: 110,
        distanceKm: 2.8,
        dailyWagePaise: 95000,
        isVerified: true,
        reason: 'Expert trade rating • High verified completion rate',
        isRepeatBooking: true,
      ),
    ];

    // Curated farm bundles
    final bundles = [
      const RecommendedBundle(
        id: 'bundle-1',
        title: 'Weekly Farm-Fresh Veggie Basket',
        description: 'Direct harvest from Devanahalli organic farm. Includes 2kg Tomatoes, 1kg Onions, 1kg Potatoes, Fresh Coriander.',
        items: ['Tomatoes (2kg)', 'Onions (1kg)', 'Potatoes (1kg)', 'Greens (2 bunches)'],
        originalPricePaise: 24000,
        bundlePricePaise: 19500,
        discountPercent: 18,
        tag: 'Organic Harvest',
      ),
      const RecommendedBundle(
        id: 'bundle-2',
        title: 'Fresh Fruit & Tender Coconut Box',
        description: 'Direct from Mandya orchards: 1 Dozen Robusta Bananas, 2 Tender Coconuts, 1kg Seasonal Papaya.',
        items: ['Robusta Bananas (12 pcs)', 'Tender Coconut (2 pcs)', 'Fresh Papaya (1kg)'],
        originalPricePaise: 28000,
        bundlePricePaise: 22000,
        discountPercent: 21,
        tag: 'Seasonal Fresh',
      ),
    ];

    // Curated seasonal farm items
    final seasonal = [
      const SeasonalProduceItem(
        id: 'season-1',
        commodity: 'Bangalore Farm Tomatoes',
        unit: 'kg',
        typicalPricePaise: 2600,
        seasonDescription: 'Peak season harvest • Crisp & firm',
        farmerName: 'Gowda Organic Farms',
        rating: 4.9,
      ),
      const SeasonalProduceItem(
        id: 'season-2',
        commodity: 'Kolar Country Potatoes',
        unit: 'kg',
        typicalPricePaise: 2200,
        seasonDescription: 'Fresh red soil harvest • No cold storage',
        farmerName: 'Shree Basaveshwara Farm',
        rating: 4.8,
      ),
      const SeasonalProduceItem(
        id: 'season-3',
        commodity: 'Mysore Nanjangud Bananas',
        unit: 'bunch',
        typicalPricePaise: 4800,
        seasonDescription: 'GI Tagged special banana • Sweet aroma',
        farmerName: 'Cauvery River Farmers Co-op',
        rating: 5.0,
      ),
    ];

    return CustomerRecommendationsState(
      workers: workers,
      bundles: bundles,
      seasonalProduce: seasonal,
      recentlyViewedCategories: const ['electrician', 'plumbing', 'vegetable'],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER CALCULATIONS
  // ---------------------------------------------------------------------------
  double _calculateTotalDistance(List<WorkerScheduleItem> items, LatLng? start) {
    if (items.isEmpty) return 0.0;
    double dist = 0.0;
    LatLng current = start ?? items.first.location;

    for (final item in items) {
      dist += _haversineDistance(current, item.location);
      current = item.location;
    }
    return dist;
  }

  double _haversineDistance(LatLng p1, LatLng p2) {
    const double r = 6371.0; // Earth radius in km
    final dLat = (p2.latitude - p1.latitude) * (pi / 180.0);
    final dLon = (p2.longitude - p1.longitude) * (pi / 180.0);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * (pi / 180.0)) *
            cos(p2.latitude * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}

final recommendationPricingServiceProvider = Provider<RecommendationPricingService>((ref) {
  return const RecommendationPricingService();
});
