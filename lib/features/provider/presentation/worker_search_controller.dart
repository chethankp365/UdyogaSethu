import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/provider/data/worker_search_repository.dart';
import 'package:udyogasethu/features/provider/domain/nearby_worker.dart';
import 'package:udyogasethu/features/provider/domain/provider_active_booking.dart';
import 'package:udyogasethu/features/provider/domain/worker_detail_profile.dart';
import 'package:udyogasethu/features/provider/domain/worker_filter_criteria.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';

/// Provider location coordinates (defaults to central Bengaluru Koramangala)
class ProviderLocationNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() {
    return {'lat': 12.9352, 'lng': 77.6245};
  }

  void setLocation(double lat, double lng) {
    state = {'lat': lat, 'lng': lng};
  }
}

final providerLocationProvider = NotifierProvider<ProviderLocationNotifier, Map<String, double>>(
  ProviderLocationNotifier.new,
);

/// Active Booking for Customer Hub
final providerActiveBookingProvider = FutureProvider<ProviderActiveBooking?>((ref) async {
  final repo = ref.watch(workerSearchRepositoryProvider);
  String? userId;
  try {
    userId = Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {}
  return repo.getActiveBooking(providerId: userId);
});

/// Service Categories for Worker Search Filter
final workerSearchCategoriesProvider = FutureProvider<List<ServiceCategoryItem>>((ref) async {
  final repo = ref.watch(workerSearchRepositoryProvider);
  return repo.getCategories();
});

/// Worker Filter Criteria Notifier
class WorkerFilterNotifier extends Notifier<WorkerFilterCriteria> {
  @override
  WorkerFilterCriteria build() {
    return const WorkerFilterCriteria();
  }

  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  void setRadiusKm(double km) {
    state = state.copyWith(radiusKm: km);
  }

  void setLanguage(String? lang) {
    state = state.copyWith(language: lang);
  }

  void setAvailability(String? avail) {
    state = state.copyWith(availability: avail);
  }

  void setRateRange(int? minPaise, int? maxPaise) {
    state = state.copyWith(minRatePaise: minPaise, maxRatePaise: maxPaise);
  }

  void setGenderPreference(String? gender) {
    state = state.copyWith(genderPreference: gender);
  }

  void setMinRating(double? rating) {
    state = state.copyWith(minRating: rating);
  }

  void setMinJobsCompleted(int? jobs) {
    state = state.copyWith(minJobsCompleted: jobs);
  }

  void setVerifiedOnly(bool verified) {
    state = state.copyWith(verifiedOnly: verified);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleMapMode() {
    state = state.copyWith(isMapMode: !state.isMapMode);
  }

  void setMapMode(bool mapMode) {
    state = state.copyWith(isMapMode: mapMode);
  }

  void resetFilters() {
    state = WorkerFilterCriteria(
      searchQuery: state.searchQuery,
      isMapMode: state.isMapMode,
    );
  }
}

final workerFilterNotifierProvider = NotifierProvider<WorkerFilterNotifier, WorkerFilterCriteria>(
  WorkerFilterNotifier.new,
);

/// Filtered Workers List
final filteredWorkersProvider = FutureProvider<List<NearbyWorker>>((ref) async {
  final repo = ref.watch(workerSearchRepositoryProvider);
  final criteria = ref.watch(workerFilterNotifierProvider);
  final location = ref.watch(providerLocationProvider);

  final lat = location['lat'] ?? 12.9352;
  final lng = location['lng'] ?? 77.6245;

  return repo.searchNearbyWorkers(
    lat: lat,
    lng: lng,
    criteria: criteria,
  );
});

/// Verified on-demand local workers for Customer Hub quick section (verified-only, radius 10km)
final verifiedOnDemandWorkersProvider = FutureProvider<List<NearbyWorker>>((ref) async {
  final repo = ref.watch(workerSearchRepositoryProvider);
  final location = ref.watch(providerLocationProvider);

  final lat = location['lat'] ?? 12.9352;
  final lng = location['lng'] ?? 77.6245;

  return repo.searchNearbyWorkers(
    lat: lat,
    lng: lng,
    criteria: const WorkerFilterCriteria(verifiedOnly: true, radiusKm: 10.0),
  );
});

/// Worker Detail Profile Provider family
final workerDetailProfileProvider = FutureProvider.family<WorkerDetailProfile, String>((ref, workerId) async {
  final repo = ref.watch(workerSearchRepositoryProvider);
  final location = ref.watch(providerLocationProvider);

  return repo.getWorkerProfileDetail(
    workerId,
    callerLat: location['lat'],
    callerLng: location['lng'],
  );
});

/// Recently Viewed Workers Tracker
class RecentlyViewedWorkersNotifier extends Notifier<List<NearbyWorker>> {
  @override
  List<NearbyWorker> build() {
    return [];
  }

  void addWorker(NearbyWorker worker) {
    final existing = state.where((w) => w.userId != worker.userId).toList();
    state = [worker, ...existing].take(10).toList();
  }
}

final recentlyViewedWorkersProvider = NotifierProvider<RecentlyViewedWorkersNotifier, List<NearbyWorker>>(
  RecentlyViewedWorkersNotifier.new,
);
