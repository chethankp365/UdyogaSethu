import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';
import 'package:udyogasethu/features/seeker/data/seeker_profile_repository.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';

final seekerProfileRepositoryProvider = Provider<SeekerProfileRepository>((ref) {
  return SupabaseSeekerProfileRepository();
});

final categoriesProvider = FutureProvider<List<ServiceCategoryItem>>((ref) async {
  final repo = ref.watch(seekerProfileRepositoryProvider);
  return repo.fetchCategories();
});

final skillsProvider = FutureProvider<List<SkillItem>>((ref) async {
  final repo = ref.watch(seekerProfileRepositoryProvider);
  return repo.fetchSkills();
});

final wageBandProvider = FutureProvider.family<WageBandResult?, String?>((ref, categoryId) async {
  final repo = ref.watch(seekerProfileRepositoryProvider);
  return repo.fetchWageBand(categoryId: categoryId);
});

class SeekerWizardState {
  final SeekerProfileDraft draft;
  final bool isSaving;
  final String? errorMessage;
  final String? uploadError;

  const SeekerWizardState({
    required this.draft,
    this.isSaving = false,
    this.errorMessage,
    this.uploadError,
  });

  SeekerWizardState copyWith({
    SeekerProfileDraft? draft,
    bool? isSaving,
    String? errorMessage,
    String? uploadError,
  }) {
    return SeekerWizardState(
      draft: draft ?? this.draft,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      uploadError: uploadError,
    );
  }
}

class SeekerWizardNotifier extends Notifier<AsyncValue<SeekerWizardState>> {
  late final SeekerProfileRepository _repository;
  final FlutterTts _tts = FlutterTts();

  @override
  AsyncValue<SeekerWizardState> build() {
    _repository = ref.watch(seekerProfileRepositoryProvider);
    _init();
    return const AsyncValue.loading();
  }

  Future<void> _init() async {
    try {
      String? userId;
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.id.isNotEmpty) {
          userId = user.id;
        }
      } catch (_) {}

      final targetId = userId ?? 'test-user-id';
      final draft = await _repository.loadDraft(targetId);
      state = AsyncValue.data(SeekerWizardState(draft: draft));
    } catch (e, stack) {
      AppLogger.e('Failed to load seeker wizard state', e, stack);
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> speakText(String text, String langCode) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(langCode);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
    } catch (e) {
      AppLogger.e('TTS speech error', e, StackTrace.current);
    }
  }

  void updateDraft(SeekerProfileDraft Function(SeekerProfileDraft current) updateFn) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedDraft = updateFn(currentState.draft);
    state = AsyncValue.data(currentState.copyWith(draft: updatedDraft));
  }

  Future<bool> saveAndNext() async {
    final currentState = state.value;
    if (currentState == null) return false;

    state = AsyncValue.data(currentState.copyWith(isSaving: true, errorMessage: null));

    try {
      final draft = currentState.draft;
      final currentStep = draft.currentStep;

      // Save to database step by step
      await _repository.saveStep(draft, currentStep);

      if (currentStep < 7) {
        final nextStep = currentStep + 1;
        final updatedDraft = draft.copyWith(currentStep: nextStep);
        await _repository.saveStep(updatedDraft, nextStep);
        state = AsyncValue.data(currentState.copyWith(
          draft: updatedDraft,
          isSaving: false,
        ));
        return true;
      } else {
        // Complete wizard
        if (kDebugMode) {
          final beforeSession = ref.read(appSessionProvider);
          AppLogger.d('completeWizard() start: role=seeker, AppSession status before=${beforeSession.status}');
        }
        await _repository.completeWizard(draft);
        if (kDebugMode) {
          AppLogger.d('completeWizard() DB update succeeded for seeker');
        }

        // Refresh bootstrap state & update global AppSession to ready
        ref.read(appSessionProvider.notifier).updateSession(
          status: AuthSessionStatus.ready,
          role: UserRole.seeker,
          seekerType: draft.seekerType,
        );
        unawaited(ref.read(bootstrapProvider.notifier).runBootstrap().catchError((e, s) {
          if (kDebugMode) {
            AppLogger.w('Background bootstrap refresh error: $e');
          }
        }));

        if (kDebugMode) {
          final afterSession = ref.read(appSessionProvider);
          AppLogger.d('completeWizard() finished: AppSession status after=${afterSession.status}, activeRole=${afterSession.activeRole}');
        }

        state = AsyncValue.data(currentState.copyWith(
          draft: draft.copyWith(onboardingComplete: true),
          isSaving: false,
        ));
        return true;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        AppLogger.e('Failed to complete seeker wizard: $e', e, stack);
      }
      state = AsyncValue.data(currentState.copyWith(
        isSaving: false,
        errorMessage: 'Failed to complete profile. ${e is AppException ? e.message : e.toString()}',
      ));
      return false;
    }
  }

  Future<void> prevStep() async {
    final currentState = state.value;
    if (currentState == null) return;
    final currentStep = currentState.draft.currentStep;
    if (currentStep > 1) {
      final prevStep = currentStep - 1;
      final updatedDraft = currentState.draft.copyWith(currentStep: prevStep);
      state = AsyncValue.data(currentState.copyWith(draft: updatedDraft));
      await _repository.saveStep(updatedDraft, prevStep);
    }
  }

  Future<void> goToStep(int targetStep) async {
    final currentState = state.value;
    if (currentState == null) return;
    if (targetStep >= 1 && targetStep <= 7) {
      final updatedDraft = currentState.draft.copyWith(currentStep: targetStep);
      state = AsyncValue.data(currentState.copyWith(draft: updatedDraft));
      await _repository.saveStep(updatedDraft, targetStep);
    }
  }

  Future<void> uploadAvatarPhoto(List<int> bytes, String filename) async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isSaving: true, uploadError: null));

    try {
      final userId = currentState.draft.userId;
      final avatarUrl = await _repository.uploadAvatar(
        userId: userId,
        bytes: bytes,
        filename: filename,
      );

      final updatedDraft = currentState.draft.copyWith(
        avatarPath: avatarUrl,
        avatarUrl: avatarUrl,
      );

      state = AsyncValue.data(currentState.copyWith(
        draft: updatedDraft,
        isSaving: false,
      ));

      await _repository.saveStep(updatedDraft, updatedDraft.currentStep);
    } catch (e) {
      AppLogger.e('Failed to upload avatar photo', e, StackTrace.current);
      state = AsyncValue.data(currentState.copyWith(
        isSaving: false,
        uploadError: e.toString(),
      ));
    }
  }

  void setUploadError(String error) {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncValue.data(currentState.copyWith(isSaving: false, uploadError: error));
  }

  Future<void> logGpsConsent() async {
    await _repository.logGpsConsent();
  }
}

final seekerWizardProvider =
    NotifierProvider<SeekerWizardNotifier, AsyncValue<SeekerWizardState>>(SeekerWizardNotifier.new);
