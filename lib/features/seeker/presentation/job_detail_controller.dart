import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/features/seeker/data/job_detail_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_application_status.dart';
import 'package:udyogasethu/features/seeker/domain/job_detail.dart';
import 'package:udyogasethu/features/seeker/domain/job_eligibility.dart';
import 'package:udyogasethu/features/seeker/presentation/my_applications_controller.dart';

final jobDetailFutureProvider = FutureProvider.family<({JobDetail detail, bool isOffline}), String>((ref, jobId) async {
  final repo = ref.watch(jobDetailRepositoryProvider);
  return repo.fetchJobDetail(jobId);
});

final jobEligibilityFutureProvider = FutureProvider.family<JobEligibility, String>((ref, jobId) async {
  final repo = ref.watch(jobDetailRepositoryProvider);
  return repo.checkEligibility(jobId);
});

class JobApplyNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncValue.data(null);

  Future<bool> apply({required String jobId, String? message}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(jobDetailRepositoryProvider);
      final id = await repo.applyToJob(jobId: jobId, message: message);

      ref.read(myApplicationsProvider.notifier).seedStatuses([
        WorkerJobStatus(
          jobId: jobId,
          applicationStatus: JobAppStatus.applied,
          applicationId: id,
          appliedAt: DateTime.now(),
        ),
      ]);

      state = AsyncValue.data(id);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final jobApplyControllerProvider =
    NotifierProvider<JobApplyNotifier, AsyncValue<String?>>(JobApplyNotifier.new);
