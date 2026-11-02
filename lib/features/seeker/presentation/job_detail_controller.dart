import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/features/provider/presentation/provider_jobs_controller.dart';
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
      ref.invalidate(jobEligibilityFutureProvider(jobId));
      ref.invalidate(jobDetailFutureProvider(jobId));
      ref.invalidate(jobApplicantsFutureProvider(jobId));

      state = AsyncValue.data(id);
      return true;
    } catch (e, st) {
      debugPrint('[JobApplyNotifier] apply raw error: $e');
      final errUpper = e.toString().toUpperCase();
      String userMsg = 'Unable to submit application. Please try again.';

      if (errUpper.contains('ALREADY_APPLIED') || errUpper.contains('ALREADY APPLIED') || errUpper.contains('DUPLICATE KEY')) {
        ref.read(myApplicationsProvider.notifier).seedStatuses([
          WorkerJobStatus(
            jobId: jobId,
            applicationStatus: JobAppStatus.applied,
            appliedAt: DateTime.now(),
          ),
        ]);
        state = const AsyncValue.data('already_applied');
        return true;
      } else if (errUpper.contains('SLOTS_FILLED') || errUpper.contains('SLOTS FULL') || errUpper.contains('ALREADY FILLED')) {
        userMsg = 'This job is already full. No more positions available.';
      } else if (errUpper.contains('EXPIRED') || errUpper.contains('JOB CLOSED') || errUpper.contains('PAST_START')) {
        userMsg = 'This job is closed or its scheduled start time has passed.';
      } else if (errUpper.contains('AUDIENCE_MISMATCH') || errUpper.contains('STUDENT_GATED') || errUpper.contains('NOT ELIGIBLE')) {
        userMsg = 'You are not eligible for this job category.';
      } else if (errUpper.contains('OWN_JOB')) {
        userMsg = 'You cannot apply to your own job.';
      } else if (errUpper.contains('NOT_AUTHENTICATED') || errUpper.contains('AUTHENTICATION REQUIRED')) {
        userMsg = 'Please sign in to apply for this job.';
      } else if (errUpper.contains('LICENCE_REQUIRED')) {
        userMsg = 'A valid driving licence is required for this role.';
      } else if (errUpper.contains('VERIFIED_REQUIRED')) {
        userMsg = 'A verified profile badge is required for this role.';
      } else if (errUpper.contains('SCHEDULE_CLASH')) {
        userMsg = 'You have a schedule clash with another active booking.';
      } else if (errUpper.contains('INELIGIBLE TO APPLY:')) {
        final match = RegExp(r'Ineligible to apply:\s*\[(.*?)\]', caseSensitive: false).firstMatch(e.toString());
        if (match != null && match.group(1) != null) {
          userMsg = match.group(1)!.replaceAll('"', '').trim();
        }
      }

      state = AsyncValue.error(userMsg, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final jobApplyControllerProvider =
    NotifierProvider<JobApplyNotifier, AsyncValue<String?>>(JobApplyNotifier.new);
