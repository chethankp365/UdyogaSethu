import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/features/seeker/data/seeker_jobs_repository.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_job_item.dart';

class SeekerJobsState {
  final bool isLoading;
  final String? error;
  final Map<SeekerJobSegment, List<SeekerJobItem>> segments;
  final SeekerJobSegment selectedSegment;

  const SeekerJobsState({
    this.isLoading = false,
    this.error,
    this.segments = const {
      SeekerJobSegment.applied: [],
      SeekerJobSegment.accepted: [],
      SeekerJobSegment.active: [],
      SeekerJobSegment.completed: [],
      SeekerJobSegment.requests: [],
    },
    this.selectedSegment = SeekerJobSegment.applied,
  });

  SeekerJobsState copyWith({
    bool? isLoading,
    String? error,
    Map<SeekerJobSegment, List<SeekerJobItem>>? segments,
    SeekerJobSegment? selectedSegment,
  }) {
    return SeekerJobsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      segments: segments ?? this.segments,
      selectedSegment: selectedSegment ?? this.selectedSegment,
    );
  }

  int get pendingRequestsCount => segments[SeekerJobSegment.requests]?.length ?? 0;
  List<SeekerJobItem> get currentList => segments[selectedSegment] ?? const [];
}

class SeekerJobsNotifier extends Notifier<SeekerJobsState> {
  SeekerJobsRepository get _repo => ref.read(seekerJobsRepositoryProvider);
  StreamSubscription? _subscription;

  @override
  SeekerJobsState build() {
    _subscription?.cancel();
    _subscription = _repo.watchSeekerJobs().listen(
      (data) {
        state = state.copyWith(isLoading: false, segments: data, error: null);
      },
      onError: (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return const SeekerJobsState(isLoading: true);
  }

  void selectSegment(SeekerJobSegment segment) {
    state = state.copyWith(selectedSegment: segment);
  }

  Future<void> loadJobs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.fetchSeekerJobs();
      state = state.copyWith(isLoading: false, segments: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<({bool success, bool travelWarning, double? gapMinutes, String? error})> acceptAssignment(String id) async {
    try {
      final res = await _repo.acceptAssignment(id);
      await loadJobs();
      return (
        success: true,
        travelWarning: res.travelWarning,
        gapMinutes: res.gapMinutes,
        error: null,
      );
    } catch (e) {
      final errMsg = e.toString().replaceAll('Exception:', '').trim();
      return (
        success: false,
        travelWarning: false,
        gapMinutes: null,
        error: errMsg,
      );
    }
  }

  Future<bool> declineAssignment(String id) async {
    try {
      final ok = await _repo.declineAssignment(id);
      await loadJobs();
      return ok;
    } catch (e) {
      return false;
    }
  }

  Future<void> debugSeedOverlappingRequests() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.debugSeedOverlappingRequests();
      await loadJobs();
      state = state.copyWith(selectedSegment: SeekerJobSegment.requests);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final seekerJobsControllerProvider =
    NotifierProvider<SeekerJobsNotifier, SeekerJobsState>(SeekerJobsNotifier.new);
