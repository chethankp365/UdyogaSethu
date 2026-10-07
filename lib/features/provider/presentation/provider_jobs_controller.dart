import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/provider/data/provider_jobs_repository.dart';
import 'package:udyogasethu/features/provider/domain/job_applicant.dart';
import 'package:udyogasethu/features/provider/domain/job_post_draft.dart';
import 'package:udyogasethu/features/provider/domain/provider_job.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';

// Provider for categories
final serviceCategoriesListProvider = FutureProvider<List<ServiceCategoryItem>>((ref) async {
  final repo = ref.watch(providerJobsRepositoryProvider);
  return repo.fetchCategories();
});

// Provider Jobs List State Notifier
class ProviderJobsNotifier extends AsyncNotifier<List<ProviderJob>> {
  RealtimeChannel? _realtimeChannel;

  @override
  Future<List<ProviderJob>> build() async {
    _setupRealtime();
    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
    });
    return _fetch();
  }

  Future<List<ProviderJob>> _fetch() async {
    final repo = ref.read(providerJobsRepositoryProvider);
    return repo.fetchProviderJobs();
  }

  void _setupRealtime() {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      _realtimeChannel = client
          .channel('provider-jobs-realtime-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'jobs',
            callback: (payload) {
              refreshJobs();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'job_applications',
            callback: (payload) {
              refreshJobs();
            },
          )
          .subscribe();
    } catch (e) {
      AppLogger.w('Failed to subscribe to provider jobs realtime: $e');
    }
  }

  Future<void> refreshJobs() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> pauseJob(String jobId, {required bool currentlyPaused}) async {
    final repo = ref.read(providerJobsRepositoryProvider);
    final targetStatus = currentlyPaused ? 'open' : 'draft';
    await repo.updateJobStatus(jobId, targetStatus);
    await refreshJobs();
  }

  Future<Map<String, dynamic>> cancelJob(String jobId) async {
    final repo = ref.read(providerJobsRepositoryProvider);
    final res = await repo.updateJobStatus(jobId, 'cancelled');
    await refreshJobs();
    return res;
  }

  Future<Map<String, dynamic>> updateJobStatus(String jobId, String status) async {
    final repo = ref.read(providerJobsRepositoryProvider);
    final res = await repo.updateJobStatus(jobId, status);
    await refreshJobs();
    return res;
  }
}

final providerJobsNotifierProvider =
    AsyncNotifierProvider<ProviderJobsNotifier, List<ProviderJob>>(ProviderJobsNotifier.new);

// Filtered segmented providers
final openProviderJobsProvider = Provider<List<ProviderJob>>((ref) {
  final jobs = ref.watch(providerJobsNotifierProvider).asData?.value ?? [];
  return jobs.where((j) => j.isOpen || j.isPaused).toList();
});

final filledProviderJobsProvider = Provider<List<ProviderJob>>((ref) {
  final jobs = ref.watch(providerJobsNotifierProvider).asData?.value ?? [];
  return jobs.where((j) => j.isFilled).toList();
});

final completedProviderJobsProvider = Provider<List<ProviderJob>>((ref) {
  final jobs = ref.watch(providerJobsNotifierProvider).asData?.value ?? [];
  return jobs.where((j) => j.isCompleted || j.isCancelled).toList();
});

// Job Applicants Future Provider
final jobApplicantsFutureProvider =
    FutureProvider.family<List<JobApplicant>, String>((ref, jobId) async {
  final repo = ref.watch(providerJobsRepositoryProvider);
  return repo.fetchJobApplicants(jobId);
});

// Post / Edit Job Wizard Controller
class PostJobWizardNotifier extends Notifier<JobPostDraft> {
  @override
  JobPostDraft build() {
    return JobPostDraft(
      startAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  void initForNewJob({String? defaultAddress, double? lat, double? lng}) {
    state = JobPostDraft(
      startAt: DateTime.now().add(const Duration(hours: 24)),
      addressText: defaultAddress ?? '',
      latitude: lat,
      longitude: lng,
      currentStep: 0,
    );
  }

  void initForEdit(ProviderJob job) {
    state = JobPostDraft(
      jobId: job.id,
      categoryId: job.categoryId,
      categoryName: job.categoryName,
      title: job.title,
      description: job.description ?? '',
      wageType: job.wageType,
      wagePaise: job.wagePaise,
      estDurationMinutes: job.estDurationMinutes,
      startAt: job.startAt,
      slotsTotal: job.slotsTotal,
      materialsProvided: job.materialsProvided,
      paymentMode: job.paymentMode,
      verifiedOnly: job.verifiedOnly,
      licenceRequired: job.licenceRequired,
      studentsOk: job.studentsOk,
      addressText: job.addressText ?? '',
      geofenceRadiusM: job.geofenceRadiusM,
      currentStep: 0,
    );
    if (job.categoryId != null) {
      checkWageBand(job.categoryId!);
    }
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> setCategory(String categoryId, String categoryName) async {
    state = state.copyWith(
      categoryId: categoryId,
      categoryName: categoryName,
    );
    await checkWageBand(categoryId);
  }

  Future<void> checkWageBand(String categoryId) async {
    final repo = ref.read(providerJobsRepositoryProvider);
    final band = await repo.fetchWageBand(categoryId: categoryId);
    if (band != null) {
      state = state.copyWith(
        minWagePaiseHint: band.minPaise,
        maxWagePaiseHint: band.maxPaise,
        wageBandUnit: band.unit,
      );
    }
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  void setWageType(String wageType) {
    state = state.copyWith(wageType: wageType);
  }

  void setWageRupees(int rupees) {
    state = state.copyWith(wagePaise: rupees * 100);
  }

  void setDurationMinutes(int minutes) {
    state = state.copyWith(estDurationMinutes: minutes);
  }

  void setStartAt(DateTime dt) {
    state = state.copyWith(startAt: dt);
  }

  void setSlotsTotal(int slots) {
    state = state.copyWith(slotsTotal: slots.clamp(1, 50));
  }

  void setMaterialsProvided(bool val) {
    state = state.copyWith(materialsProvided: val);
  }

  void setPaymentMode(String mode) {
    state = state.copyWith(paymentMode: mode);
  }

  void setRequirements({
    bool? verifiedOnly,
    bool? licenceRequired,
    bool? studentsOk,
  }) {
    state = state.copyWith(
      verifiedOnly: verifiedOnly ?? state.verifiedOnly,
      licenceRequired: licenceRequired ?? state.licenceRequired,
      studentsOk: studentsOk ?? state.studentsOk,
    );
  }

  void setLocation({
    required String address,
    double? lat,
    double? lng,
    int? radiusM,
  }) {
    state = state.copyWith(
      addressText: address,
      latitude: lat ?? state.latitude,
      longitude: lng ?? state.longitude,
      geofenceRadiusM: radiusM ?? state.geofenceRadiusM,
    );
  }

  Future<String> publish() async {
    final repo = ref.read(providerJobsRepositoryProvider);
    String resultJobId = '';
    if (state.jobId != null) {
      await repo.updateJob(state);
      resultJobId = state.jobId!;
    } else {
      resultJobId = await repo.postJob(state);
    }
    await ref.read(providerJobsNotifierProvider.notifier).refreshJobs();
    return resultJobId;
  }
}

final postJobWizardProvider =
    NotifierProvider<PostJobWizardNotifier, JobPostDraft>(PostJobWizardNotifier.new);
