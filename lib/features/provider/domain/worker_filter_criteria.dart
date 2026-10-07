import 'package:flutter/foundation.dart';

@immutable
class WorkerFilterCriteria {
  final String? categoryId;
  final String? categoryName;
  final double radiusKm;
  final String? language;
  final String? availability;
  final int? minRatePaise;
  final int? maxRatePaise;
  final String? genderPreference;
  final double? minRating;
  final int? minJobsCompleted;
  final bool verifiedOnly;
  final String? searchQuery;
  final bool isMapMode;

  const WorkerFilterCriteria({
    this.categoryId,
    this.categoryName,
    this.radiusKm = 10.0,
    this.language,
    this.availability,
    this.minRatePaise,
    this.maxRatePaise,
    this.genderPreference,
    this.minRating,
    this.minJobsCompleted,
    this.verifiedOnly = false,
    this.searchQuery,
    this.isMapMode = false,
  });

  WorkerFilterCriteria copyWith({
    Object? categoryId = _sentinel,
    Object? categoryName = _sentinel,
    double? radiusKm,
    Object? language = _sentinel,
    Object? availability = _sentinel,
    Object? minRatePaise = _sentinel,
    Object? maxRatePaise = _sentinel,
    Object? genderPreference = _sentinel,
    Object? minRating = _sentinel,
    Object? minJobsCompleted = _sentinel,
    bool? verifiedOnly,
    Object? searchQuery = _sentinel,
    bool? isMapMode,
  }) {
    return WorkerFilterCriteria(
      categoryId: categoryId == _sentinel ? this.categoryId : categoryId as String?,
      categoryName: categoryName == _sentinel ? this.categoryName : categoryName as String?,
      radiusKm: radiusKm ?? this.radiusKm,
      language: language == _sentinel ? this.language : language as String?,
      availability: availability == _sentinel ? this.availability : availability as String?,
      minRatePaise: minRatePaise == _sentinel ? this.minRatePaise : minRatePaise as int?,
      maxRatePaise: maxRatePaise == _sentinel ? this.maxRatePaise : maxRatePaise as int?,
      genderPreference: genderPreference == _sentinel ? this.genderPreference : genderPreference as String?,
      minRating: minRating == _sentinel ? this.minRating : minRating as double?,
      minJobsCompleted: minJobsCompleted == _sentinel ? this.minJobsCompleted : minJobsCompleted as int?,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      searchQuery: searchQuery == _sentinel ? this.searchQuery : searchQuery as String?,
      isMapMode: isMapMode ?? this.isMapMode,
    );
  }

  static const Object _sentinel = Object();

  int get activeFilterCount {
    int count = 0;
    if (categoryId != null && categoryId!.isNotEmpty) count++;
    if (radiusKm != 10.0) count++;
    if (language != null && language!.isNotEmpty && language != 'all') count++;
    if (availability != null && availability!.isNotEmpty && availability != 'all') count++;
    if (minRatePaise != null || maxRatePaise != null) count++;
    if (genderPreference != null && genderPreference!.isNotEmpty && genderPreference != 'any') count++;
    if (minRating != null && minRating! > 0) count++;
    if (minJobsCompleted != null && minJobsCompleted! > 0) count++;
    if (verifiedOnly) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  static const defaultCriteria = WorkerFilterCriteria();
}
