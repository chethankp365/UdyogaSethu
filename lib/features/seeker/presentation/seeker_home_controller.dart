import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/seeker/data/seeker_home_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';

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

        String displayName = 'Current Location (GPS)';
        try {
          final placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final subLocality = p.subLocality?.trim();
            final locality = p.locality?.trim();
            final subAdmin = p.subAdministrativeArea?.trim();
            final admin = p.administrativeArea?.trim();

            String? area;
            if (subLocality != null && subLocality.isNotEmpty) {
              area = subLocality;
            } else if (locality != null && locality.isNotEmpty) {
              area = locality;
            } else if (p.name != null && p.name!.isNotEmpty) {
              area = p.name;
            }

            String? city;
            if (locality != null && locality.isNotEmpty && locality != area) {
              city = locality;
            } else if (subAdmin != null && subAdmin.isNotEmpty) {
              city = subAdmin;
            } else if (admin != null && admin.isNotEmpty) {
              city = admin;
            }

            if (area != null && city != null) {
              displayName = '$area, $city';
            } else if (area != null) {
              displayName = area;
            } else if (city != null) {
              displayName = city;
            }
          }
        } catch (e) {
          AppLogger.w('Reverse geocoding error: $e');
        }

        state = SeekerLocationState(
          displayName: displayName,
          lat: position.latitude,
          lng: position.longitude,
          isGps: true,
        );
      }
    } catch (e) {
      AppLogger.w('Location initialization fallback to manual area: $e');
    }
  }

  Future<void> refreshGpsLocation() async {
    await initLocation();
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

class SeekerDailyGoalNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setGoalPaise(int paise) {
    state = paise;
  }
}

final seekerDailyGoalProvider =
    NotifierProvider<SeekerDailyGoalNotifier, int?>(SeekerDailyGoalNotifier.new);

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

final seekerHomeProfileProvider = FutureProvider<SeekerProfileDraft>((ref) async {
  final repo = ref.watch(seekerProfileRepositoryProvider);
  String? userId;
  bool isSupabaseInitialized = true;
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.id.isNotEmpty) userId = user.id;
  } catch (_) {
    isSupabaseInitialized = false;
  }
  if (isSupabaseInitialized && userId == null) {
    return const SeekerProfileDraft(userId: '');
  }
  final targetId = userId ?? 'test-user-id';
  return repo.loadDraft(targetId);
});

final seekerSkillsListProvider = FutureProvider<List<SkillItem>>((ref) async {
  final repo = ref.watch(seekerProfileRepositoryProvider);
  return repo.fetchSkills();
});

final seekerRecommendedJobsProvider =
    FutureProvider<List<JobRecommendation>>((ref) async {
  final repo = ref.watch(seekerHomeRepositoryProvider);
  final location = ref.watch(seekerLocationProvider);
  final radius = ref.watch(seekerSearchRadiusProvider);
  final profileAsync = ref.watch(seekerHomeProfileProvider);

  String? uid;
  try {
    uid = Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {}

  // Realtime subscription on jobs table: updates feed live when provider posts/updates a job
  try {
    if (Supabase.instance.isInitialized) {
      final channel = Supabase.instance.client
          .channel('seeker-feed-realtime-${uid ?? "guest"}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'jobs',
            callback: (_) {
              ref.invalidateSelf();
            },
          )
          .subscribe();
      ref.onDispose(() {
        channel.unsubscribe();
      });
    }
  } catch (e) {
    AppLogger.w('Failed to subscribe to seeker feed realtime: $e');
  }

  final targetUid = uid ?? '00000000-0000-0000-0000-000000000000';
  final seekerType = profileAsync.value?.seekerType ?? 'informal';

  return repo.fetchRecommendations(
    workerId: targetUid,
    seekerType: seekerType,
    lat: location.lat,
    lng: location.lng,
    radiusM: radius,
    limit: 20,
  );
});
