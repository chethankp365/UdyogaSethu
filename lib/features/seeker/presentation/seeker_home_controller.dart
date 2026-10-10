import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final DateTime? cachedAt;

  const SeekerLocationState({
    required this.displayName,
    required this.lat,
    required this.lng,
    required this.isGps,
    this.cachedAt,
  });

  SeekerLocationState copyWith({
    String? displayName,
    double? lat,
    double? lng,
    bool? isGps,
    DateTime? cachedAt,
  }) {
    return SeekerLocationState(
      displayName: displayName ?? this.displayName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isGps: isGps ?? this.isGps,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}

class SeekerLocationNotifier extends Notifier<SeekerLocationState> {
  static const _prefKeyLat = 'seeker_loc_lat';
  static const _prefKeyLng = 'seeker_loc_lng';
  static const _prefKeyName = 'seeker_loc_name';
  static const _prefKeyIsGps = 'seeker_loc_is_gps';
  static const _prefKeyTime = 'seeker_loc_time';

  @override
  SeekerLocationState build() {
    Future.microtask(() => _loadCachedOrInit());
    return const SeekerLocationState(
      displayName: 'Select Location',
      lat: 0.0,
      lng: 0.0,
      isGps: false,
    );
  }

  Future<void> _loadCachedOrInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_prefKeyLat);
      final lng = prefs.getDouble(_prefKeyLng);
      final name = prefs.getString(_prefKeyName);
      final isGps = prefs.getBool(_prefKeyIsGps) ?? false;
      final timeStr = prefs.getString(_prefKeyTime);
      final time = timeStr != null ? DateTime.tryParse(timeStr) : null;

      if (lat != null && lng != null && name != null && name.isNotEmpty && lat != 0.0) {
        state = SeekerLocationState(
          displayName: name,
          lat: lat,
          lng: lng,
          isGps: isGps,
          cachedAt: time,
        );
      }
    } catch (_) {}

    await initLocation();
  }

  Future<void> _saveCache(SeekerLocationState loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKeyLat, loc.lat);
      await prefs.setDouble(_prefKeyLng, loc.lng);
      await prefs.setString(_prefKeyName, loc.displayName);
      await prefs.setBool(_prefKeyIsGps, loc.isGps);
      if (loc.cachedAt != null) {
        await prefs.setString(_prefKeyTime, loc.cachedAt!.toIso8601String());
      }
    } catch (_) {}
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
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
          return '$area, $city';
        } else if (area != null) {
          return area;
        } else if (city != null) {
          return city;
        }
      }
    } catch (e) {
      AppLogger.w('Reverse geocoding error: $e');
    }
    return 'Current Location';
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

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );

        final displayName = await _reverseGeocode(position.latitude, position.longitude);

        final newState = SeekerLocationState(
          displayName: displayName,
          lat: position.latitude,
          lng: position.longitude,
          isGps: true,
          cachedAt: DateTime.now(),
        );
        state = newState;
        await _saveCache(newState);
      }
    } catch (e) {
      AppLogger.w('Location initialization error: $e');
    }
  }

  Future<void> refreshGpsLocation() async {
    await initLocation();
  }

  Future<void> refreshOnResume() async {
    if (!state.isGps || state.lat == 0.0) return;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) return;

      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      final distance = Geolocator.distanceBetween(
        state.lat,
        state.lng,
        currentPos.latitude,
        currentPos.longitude,
      );

      final minutesSinceLast = state.cachedAt != null
          ? DateTime.now().difference(state.cachedAt!).inMinutes
          : 999;

      // Refresh if moved more than 1 km (1000m) or cache older than 30 minutes
      if (distance > 1000 || minutesSinceLast > 30) {
        final displayName = await _reverseGeocode(currentPos.latitude, currentPos.longitude);
        final newState = SeekerLocationState(
          displayName: displayName,
          lat: currentPos.latitude,
          lng: currentPos.longitude,
          isGps: true,
          cachedAt: DateTime.now(),
        );
        state = newState;
        await _saveCache(newState);
      }
    } catch (e) {
      AppLogger.w('refreshOnResume error: $e');
    }
  }

  Future<bool> requestGpsWithConsent() async {
    try {
      final consentRepo = ref.read(consentRepositoryProvider);
      await consentRepo.recordConsent(
        purpose: ConsentPurpose.gps,
        granted: true,
      );

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        await consentRepo.recordConsent(
          purpose: ConsentPurpose.gps,
          granted: false,
        );
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final displayName = await _reverseGeocode(position.latitude, position.longitude);

      final newState = SeekerLocationState(
        displayName: displayName,
        lat: position.latitude,
        lng: position.longitude,
        isGps: true,
        cachedAt: DateTime.now(),
      );
      state = newState;
      await _saveCache(newState);
      return true;
    } catch (e) {
      AppLogger.w('Error in requestGpsWithConsent: $e');
      return false;
    }
  }

  Future<void> setManualArea(String areaName, double lat, double lng) async {
    final newState = SeekerLocationState(
      displayName: areaName,
      lat: lat,
      lng: lng,
      isGps: false,
      cachedAt: DateTime.now(),
    );
    state = newState;
    await _saveCache(newState);
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
