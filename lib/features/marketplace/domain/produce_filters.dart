import 'package:flutter/material.dart';

enum ProduceSortOption {
  distanceAsc,
  priceAsc,
  priceDesc,
  freshnessDesc,
  ratingDesc;

  String get dbValue {
    switch (this) {
      case ProduceSortOption.distanceAsc:
        return 'distance_asc';
      case ProduceSortOption.priceAsc:
        return 'price_asc';
      case ProduceSortOption.priceDesc:
        return 'price_desc';
      case ProduceSortOption.freshnessDesc:
        return 'freshness_desc';
      case ProduceSortOption.ratingDesc:
        return 'rating_desc';
    }
  }

  String get label {
    switch (this) {
      case ProduceSortOption.distanceAsc:
        return 'Nearest First';
      case ProduceSortOption.priceAsc:
        return 'Price: Low to High';
      case ProduceSortOption.priceDesc:
        return 'Price: High to Low';
      case ProduceSortOption.freshnessDesc:
        return 'Freshness: Recent Harvest';
      case ProduceSortOption.ratingDesc:
        return 'Top Rated Farmers';
    }
  }
}

enum FreshnessFilter {
  all,
  today,
  last24h,
  last3Days;

  String get label {
    switch (this) {
      case FreshnessFilter.all:
        return 'All Produce';
      case FreshnessFilter.today:
        return 'Harvested Today';
      case FreshnessFilter.last24h:
        return 'Last 24 Hours';
      case FreshnessFilter.last3Days:
        return 'Last 3 Days';
    }
  }
}

@immutable
class ProduceFilters {
  final String category; // 'all', 'vegetable', 'dairy', 'fruit', 'grain', 'flower', 'other'
  final int? minPricePaise;
  final int? maxPricePaise;
  final double? maxDistanceKm;
  final double? minRating;
  final String? farmingMethod;
  final bool? deliveryAvailable;
  final bool? walkInStoreOnly;
  final bool? organicCertifiedOnly;
  final FreshnessFilter freshness;
  final ProduceSortOption sortBy;

  const ProduceFilters({
    this.category = 'all',
    this.minPricePaise,
    this.maxPricePaise,
    this.maxDistanceKm,
    this.minRating,
    this.farmingMethod,
    this.deliveryAvailable,
    this.walkInStoreOnly,
    this.organicCertifiedOnly,
    this.freshness = FreshnessFilter.all,
    this.sortBy = ProduceSortOption.distanceAsc,
  });

  bool get hasActiveCustomFilters =>
      category != 'all' ||
      minPricePaise != null ||
      maxPricePaise != null ||
      maxDistanceKm != null ||
      minRating != null ||
      farmingMethod != null ||
      deliveryAvailable != null ||
      walkInStoreOnly == true ||
      organicCertifiedOnly == true ||
      freshness != FreshnessFilter.all ||
      sortBy != ProduceSortOption.distanceAsc;

  ProduceFilters copyWith({
    String? category,
    int? minPricePaise,
    int? maxPricePaise,
    double? maxDistanceKm,
    double? minRating,
    String? farmingMethod,
    bool? deliveryAvailable,
    bool? walkInStoreOnly,
    bool? organicCertifiedOnly,
    FreshnessFilter? freshness,
    ProduceSortOption? sortBy,
  }) {
    return ProduceFilters(
      category: category ?? this.category,
      minPricePaise: minPricePaise ?? this.minPricePaise,
      maxPricePaise: maxPricePaise ?? this.maxPricePaise,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      minRating: minRating ?? this.minRating,
      farmingMethod: farmingMethod ?? this.farmingMethod,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      walkInStoreOnly: walkInStoreOnly ?? this.walkInStoreOnly,
      organicCertifiedOnly: organicCertifiedOnly ?? this.organicCertifiedOnly,
      freshness: freshness ?? this.freshness,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  ProduceFilters reset() => const ProduceFilters();
}
