import 'package:flutter/foundation.dart';

@immutable
class RecommendedWorker {
  final String id;
  final String name;
  final String categoryName;
  final String categorySlug;
  final double rating;
  final int completedJobs;
  final double distanceKm;
  final int dailyWagePaise;
  final bool isVerified;
  final String reason;
  final bool isRepeatBooking;

  const RecommendedWorker({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.categorySlug,
    required this.rating,
    required this.completedJobs,
    required this.distanceKm,
    required this.dailyWagePaise,
    required this.isVerified,
    required this.reason,
    this.isRepeatBooking = false,
  });

  int get dailyWageRupees => (dailyWagePaise / 100).round();
}

@immutable
class RecommendedBundle {
  final String id;
  final String title;
  final String description;
  final List<String> items;
  final int originalPricePaise;
  final int bundlePricePaise;
  final int discountPercent;
  final String tag; // 'Seasonal', 'Popular', 'Organic'

  const RecommendedBundle({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
    required this.originalPricePaise,
    required this.bundlePricePaise,
    required this.discountPercent,
    required this.tag,
  });

  int get bundlePriceRupees => (bundlePricePaise / 100).round();
  int get originalPriceRupees => (originalPricePaise / 100).round();
}

@immutable
class SeasonalProduceItem {
  final String id;
  final String commodity;
  final String unit;
  final int typicalPricePaise;
  final String seasonDescription;
  final String farmerName;
  final double rating;

  const SeasonalProduceItem({
    required this.id,
    required this.commodity,
    required this.unit,
    required this.typicalPricePaise,
    required this.seasonDescription,
    required this.farmerName,
    required this.rating,
  });

  int get priceRupees => (typicalPricePaise / 100).round();
}

@immutable
class CustomerRecommendationsState {
  final List<RecommendedWorker> workers;
  final List<RecommendedBundle> bundles;
  final List<SeasonalProduceItem> seasonalProduce;
  final List<String> recentlyViewedCategories;

  const CustomerRecommendationsState({
    required this.workers,
    required this.bundles,
    required this.seasonalProduce,
    required this.recentlyViewedCategories,
  });
}
