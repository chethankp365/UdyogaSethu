import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/seeker/data/nearby_jobs_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_pin.dart';

/// State of the nearby jobs map screen.
class NearbyJobsMapState {
  final LatLng mapCenter;
  final double mapZoom;
  final LatLng? userLocation;
  final bool hasLocationPermission;
  final bool isGpsDisabled;
  final double radiusM;
  final String? selectedCategoryId;
  final String? selectedJobId;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final List<JobPin> jobPins;
  final List<CategoryFilterItem> categories;
  final Set<String> appliedJobIds;

  const NearbyJobsMapState({
    required this.mapCenter,
    this.mapZoom = 13.5,
    this.userLocation,
    this.hasLocationPermission = false,
    this.isGpsDisabled = false,
    this.radiusM = 25000,
    this.selectedCategoryId,
    this.selectedJobId,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.jobPins = const [],
    this.categories = const [],
    this.appliedJobIds = const {},
  });

  int get livePinsCount => jobPins.length;

  NearbyJobsMapState copyWith({
    LatLng? mapCenter,
    double? mapZoom,
    LatLng? userLocation,
    bool? hasLocationPermission,
    bool? isGpsDisabled,
    double? radiusM,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? selectedJobId,
    bool clearSelectedJob = false,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<JobPin>? jobPins,
    List<CategoryFilterItem>? categories,
    Set<String>? appliedJobIds,
  }) {
    return NearbyJobsMapState(
      mapCenter: mapCenter ?? this.mapCenter,
      mapZoom: mapZoom ?? this.mapZoom,
      userLocation: userLocation ?? this.userLocation,
      hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,
      isGpsDisabled: isGpsDisabled ?? this.isGpsDisabled,
      radiusM: radiusM ?? this.radiusM,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedJobId: clearSelectedJob ? null : (selectedJobId ?? this.selectedJobId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      jobPins: jobPins ?? this.jobPins,
      categories: categories ?? this.categories,
      appliedJobIds: appliedJobIds ?? this.appliedJobIds,
    );
  }
}

class NearbyJobsMapNotifier extends Notifier<NearbyJobsMapState> {
  Timer? _debounceTimer;
  StreamSubscription<void>? _realtimeSubscription;

  // Default central anchor: Bengaluru (MG Road / Koramangala nexus)
  static const LatLng _defaultCenter = LatLng(12.9352, 77.6245);

  @override
  NearbyJobsMapState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _realtimeSubscription?.cancel();
    });

    // Initial state
    final initialState = const NearbyJobsMapState(
      mapCenter: _defaultCenter,
      isLoading: true,
    );

    // Trigger async bootstrap
    Future.microtask(() => _initialize());

    return initialState;
  }

  Future<void> _initialize() async {
    await _loadCategories();
    await _detectUserLocation();
    await fetchJobs();
    _setupRealtime();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = ref.read(nearbyJobsRepositoryProvider);
      final cats = await repo.getCategories();
      state = state.copyWith(categories: cats);
    } catch (e) {
      AppLogger.w('Failed to load categories in map notifier: $e');
    }
  }

  Future<void> _detectUserLocation() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        state = state.copyWith(isGpsDisabled: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(hasLocationPermission: false);
        return;
      }

      state = state.copyWith(hasLocationPermission: true);

      // Try last known position for instant responsiveness
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final lastLatLng = LatLng(last.latitude, last.longitude);
          state = state.copyWith(
            userLocation: lastLatLng,
            mapCenter: lastLatLng,
          );
        }
      } catch (_) {}

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      state = state.copyWith(
        userLocation: userLatLng,
        mapCenter: userLatLng,
      );
    } catch (e) {
      AppLogger.w('Location detection error in map: $e');
      // Graceful fallback to default center
    }
  }

  void _setupRealtime() {
    final repo = ref.read(nearbyJobsRepositoryProvider);
    _realtimeSubscription?.cancel();
    _realtimeSubscription = repo.watchJobsTable().listen((_) {
      AppLogger.i('Realtime trigger: refreshing nearby map jobs');
      fetchJobs(silent: true);
    });
  }

  Future<void> fetchJobs({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final repo = ref.read(nearbyJobsRepositoryProvider);
      final pins = await repo.getNearbyJobPins(
        lat: state.mapCenter.latitude,
        lng: state.mapCenter.longitude,
        radiusM: state.radiusM,
        categoryId: state.selectedCategoryId,
        searchQuery: state.searchQuery,
      );

      state = state.copyWith(
        jobPins: pins,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      AppLogger.e('Error fetching job pins: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load nearby jobs. Check network and tap Retry.',
      );
    }
  }

  /// Debounced handler for map pan/zoom. Re-queries jobs after user stops moving map.
  void onMapMoved(LatLng newCenter, double newZoom) {
    state = state.copyWith(
      mapCenter: newCenter,
      mapZoom: newZoom,
    );

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      fetchJobs(silent: true);
    });
  }

  void setRadius(double newRadiusM) {
    if (state.radiusM == newRadiusM) return;
    state = state.copyWith(radiusM: newRadiusM);
    fetchJobs();
  }

  void selectCategory(String? categoryId) {
    if (categoryId == null || categoryId == state.selectedCategoryId) {
      // Toggle off / select "All"
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    fetchJobs();
  }

  void selectJob(String? jobId) {
    if (jobId == state.selectedJobId) {
      // Toggle selection off if already selected
      state = state.copyWith(clearSelectedJob: true);
    } else {
      state = state.copyWith(selectedJobId: jobId);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      fetchJobs();
    });
  }

  Future<bool> applyToJob(String jobId) async {
    final updated = Set<String>.from(state.appliedJobIds)..add(jobId);
    state = state.copyWith(appliedJobIds: updated);

    final repo = ref.read(nearbyJobsRepositoryProvider);
    return await repo.applyToJob(jobId);
  }

  Future<void> recenterOnUser() async {
    if (state.userLocation != null) {
      state = state.copyWith(mapCenter: state.userLocation!);
      fetchJobs();
    } else {
      await _detectUserLocation();
      if (state.userLocation != null) {
        state = state.copyWith(mapCenter: state.userLocation!);
        fetchJobs();
      }
    }
  }
}

final nearbyJobsMapNotifierProvider =
    NotifierProvider<NearbyJobsMapNotifier, NearbyJobsMapState>(NearbyJobsMapNotifier.new);
