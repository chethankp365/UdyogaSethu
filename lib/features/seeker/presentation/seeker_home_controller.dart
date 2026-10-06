import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/seeker/data/seeker_home_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

class SeekerLocationState {
  final String displayName;
  final double lat;
  final double lng;
  final bool isGps;

  const SeekerLocationState({
    required this.displayName,
    required this.lat,
    required this.lng,
    required this.isGps,
  });

  SeekerLocationState copyWith({
    String? displayName,
    double? lat,
    double? lng,
    bool? isGps,
  }) {
    return SeekerLocationState(
      displayName: displayName ?? this.displayName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isGps: isGps ?? this.isGps,
    );
  }
}

class SeekerLocationNotifier extends Notifier<SeekerLocationState> {
  @override
  SeekerLocationState build() {
    // Attempt async GPS initialization
    Future.microtask(() => initLocation());
    return const SeekerLocationState(
      displayName: 'Koramangala, Bengaluru',
      lat: 12.9352,
      lng: 77.6101,
      isGps: false,
    );
  }

  Future<void> initLocation() async {
    try {
      bool isSupabaseInitialized = false;
      try {
        isSupabaseInitialized = Supabase.instance.isInitialized;
      } catch (_) {}
      if (!isSupabaseInitialized) return;

      final consentRepo = ref.read(consentRepositoryProvider);
      final hasGpsConsent = await consentRepo.hasValidConsent(ConsentPurpose.gps);
      if (!hasGpsConsent) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        state = SeekerLocationState(
          displayName: 'Current Location (GPS)',
          lat: position.latitude,
          lng: position.longitude,
          isGps: true,
        );
      }
    } catch (e) {
      AppLogger.w('Location initialization fallback to manual area: $e');
    }
  }

  void setManualArea(String areaName, double lat, double lng) {
    state = SeekerLocationState(
      displayName: areaName,
      lat: lat,
      lng: lng,
      isGps: false,
    );
  }
}

final seekerLocationProvider =
    NotifierProvider<SeekerLocationNotifier, SeekerLocationState>(SeekerLocationNotifier.new);

class SeekerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
}

final seekerSearchQueryProvider =
    NotifierProvider<SeekerSearchQueryNotifier, String>(SeekerSearchQueryNotifier.new);

class SeekerSearchRadiusNotifier extends Notifier<double> {
  @override
  double build() => 25000.0;
  void set(double radius) => state = radius;
}

final seekerSearchRadiusProvider =
    NotifierProvider<SeekerSearchRadiusNotifier, double>(SeekerSearchRadiusNotifier.new);

class SeekerAdDismissedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void dismiss() => state = true;
}

final seekerAdDismissedProvider =
    NotifierProvider<SeekerAdDismissedNotifier, bool>(SeekerAdDismissedNotifier.new);

class SeekerAppliedJobsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void add(String jobId) => state = {...state, jobId};
}

final seekerAppliedJobsProvider =
    NotifierProvider<SeekerAppliedJobsNotifier, Set<String>>(SeekerAppliedJobsNotifier.new);

final seekerHasGpsConsentProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(consentRepositoryProvider);
  return repo.hasValidConsent(ConsentPurpose.gps);
});

final seekerHasAdsConsentProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(consentRepositoryProvider);
  return repo.hasValidConsent(ConsentPurpose.ads);
});

final seekerHomeSummaryProvider = FutureProvider<SeekerHomeSummary>((ref) async {
  final repo = ref.watch(seekerHomeRepositoryProvider);
  String? uid;
  try {
    uid = Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {}

  if (uid == null || uid.isEmpty) {
    return const SeekerHomeSummary(
      walletBalancePaise: 345000,
      todayEarningsPaise: 80000,
      dailyGoalPaise: 150000,
    );
  }
  return repo.fetchHomeSummary(uid);
});

final seekerAdBannerProvider = FutureProvider<SponsoredAdBanner?>((ref) async {
  final hasAdsConsent = await ref.watch(seekerHasAdsConsentProvider.future);
  if (!hasAdsConsent) return null;

  final repo = ref.watch(seekerHomeRepositoryProvider);
  return repo.fetchSponsoredBanner(targetRole: 'seeker');
});

final seekerRecommendedJobsProvider =
    FutureProvider<List<JobRecommendation>>((ref) async {
  final repo = ref.watch(seekerHomeRepositoryProvider);
  final location = ref.watch(seekerLocationProvider);
  final radius = ref.watch(seekerSearchRadiusProvider);

  String? uid;
  try {
    uid = Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {}

  final targetUid = uid ?? '00000000-0000-0000-0000-000000000000';

  return repo.fetchRecommendations(
    workerId: targetUid,
    lat: location.lat,
    lng: location.lng,
    radiusM: radius,
    limit: 20,
  );
});
