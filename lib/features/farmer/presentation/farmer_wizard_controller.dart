import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/farmer/data/farmer_profile_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';

final farmerProfileRepositoryProvider = Provider<FarmerProfileRepository>((ref) {
  return SupabaseFarmerProfileRepository();
});

class FarmerWizardState {
  final FarmerProfileDraft draft;
  final bool isSaving;
  final String? errorMessage;
  final String? uploadError;

  const FarmerWizardState({
    required this.draft,
    this.isSaving = false,
    this.errorMessage,
    this.uploadError,
  });

  FarmerWizardState copyWith({
    FarmerProfileDraft? draft,
    bool? isSaving,
    String? errorMessage,
    String? uploadError,
  }) {
    return FarmerWizardState(
      draft: draft ?? this.draft,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      uploadError: uploadError,
    );
  }
}

class FarmerWizardNotifier extends Notifier<AsyncValue<FarmerWizardState>> {
  late final FarmerProfileRepository _repository;
  final FlutterTts _tts = FlutterTts();

  @override
  AsyncValue<FarmerWizardState> build() {
    _repository = ref.watch(farmerProfileRepositoryProvider);
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
      state = AsyncValue.data(FarmerWizardState(draft: draft));
    } catch (e, stack) {
      AppLogger.e('Failed to load farmer wizard state', e, stack);
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

  void updateDraft(FarmerProfileDraft Function(FarmerProfileDraft current) updateFn) {
    final currentState = state.value;
    if (currentState == null) return;
    final newDraft = updateFn(currentState.draft);
    state = AsyncValue.data(currentState.copyWith(draft: newDraft, errorMessage: null));
  }

  void setStep(int step) {
    updateDraft((d) => d.copyWith(currentStep: step.clamp(1, 5)));
  }

  Future<void> uploadAvatarBytes(List<int> bytes, String filename) async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isSaving: true, uploadError: null));
    try {
      final publicUrl = await _repository.uploadAvatar(
        userId: currentState.draft.userId,
        bytes: bytes,
        filename: filename,
      );
      final avatarPath = '${currentState.draft.userId}/$filename';
      updateDraft((d) => d.copyWith(avatarPath: avatarPath, avatarUrl: publicUrl));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isSaving: false,
        uploadError: e is AppException ? e.message : 'Failed to upload photo',
      ));
    } finally {
      final updatedState = state.value;
      if (updatedState != null) {
        state = AsyncValue.data(updatedState.copyWith(isSaving: false));
      }
    }
  }

  Future<void> uploadOrganicCertBytes(List<int> bytes, String filename) async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isSaving: true, uploadError: null));
    try {
      final relativePath = await _repository.uploadOrganicCert(
        userId: currentState.draft.userId,
        bytes: bytes,
        filename: filename,
      );
      updateDraft((d) => d.copyWith(
            organicCertPath: relativePath,
            organicCertStatus: 'pending',
          ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isSaving: false,
        uploadError: e is AppException ? e.message : 'Failed to upload organic certificate',
      ));
    } finally {
      final updatedState = state.value;
      if (updatedState != null) {
        state = AsyncValue.data(updatedState.copyWith(isSaving: false));
      }
    }
  }

  Future<void> logGpsConsent() async {
    await _repository.logGpsConsent();
  }

  Future<bool> saveCurrentStep() async {
    final currentState = state.value;
    if (currentState == null) return false;

    final draft = currentState.draft;
    final step = draft.currentStep;

    state = AsyncValue.data(currentState.copyWith(isSaving: true, errorMessage: null));
    try {
      await _repository.saveStep(draft, step);
      state = AsyncValue.data(currentState.copyWith(isSaving: false));
      return true;
    } catch (e) {
      AppLogger.e('Save step $step error', e, StackTrace.current);
      state = AsyncValue.data(currentState.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save step. Please try again.',
      ));
      return false;
    }
  }

  Future<bool> nextStep() async {
    final currentState = state.value;
    if (currentState == null) return false;

    final draft = currentState.draft;
    final step = draft.currentStep;

    // Validation per step
    if (step == 1) {
      if (draft.fullName.trim().isEmpty) {
        state = AsyncValue.data(currentState.copyWith(
          errorMessage: 'Please enter your name',
        ));
        return false;
      }
    } else if (step == 2) {
      if (draft.farmName.trim().isEmpty) {
        state = AsyncValue.data(currentState.copyWith(
          errorMessage: 'Please enter your farm name',
        ));
        return false;
      }
      if (draft.clusterVillage.trim().isEmpty) {
        state = AsyncValue.data(currentState.copyWith(
          errorMessage: 'Please enter your village or cluster',
        ));
        return false;
      }
      if (draft.primaryCrops.isEmpty) {
        state = AsyncValue.data(currentState.copyWith(
          errorMessage: 'Please select at least one primary crop',
        ));
        return false;
      }
    } else if (step == 4) {
      if (!draft.deliveryAvailable && !draft.pickupAvailable) {
        state = AsyncValue.data(currentState.copyWith(
          errorMessage: 'Please enable at least delivery or pickup options',
        ));
        return false;
      }
    }

    if (step < 5) {
      final saved = await saveCurrentStep();
      if (saved) {
        setStep(step + 1);
        return true;
      }
      return false;
    } else {
      // Step 5: Finish
      if (kDebugMode) {
        final beforeSession = ref.read(appSessionProvider);
        AppLogger.d('completeWizard() start: role=farmer, AppSession status before=${beforeSession.status}');
      }
      state = AsyncValue.data(currentState.copyWith(isSaving: true, errorMessage: null));
      try {
        await _repository.completeWizard(draft);
        if (kDebugMode) {
          AppLogger.d('completeWizard() DB update succeeded for farmer');
        }

        ref.read(appSessionProvider.notifier).updateSession(
          status: AuthSessionStatus.ready,
          role: UserRole.farmer,
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
          isSaving: false,
          draft: draft.copyWith(onboardingComplete: true),
        ));
        return true;
      } catch (e, stack) {
        if (kDebugMode) {
          AppLogger.e('Complete farmer wizard error: $e', e, stack);
        }
        state = AsyncValue.data(currentState.copyWith(
          isSaving: false,
          errorMessage: 'Failed to complete profile setup. ${e is AppException ? e.message : e.toString()}',
        ));
        return false;
      }
    }
  }

  Future<void> previousStep() async {
    final currentState = state.value;
    if (currentState == null) return;
    if (currentState.draft.currentStep > 1) {
      await saveCurrentStep();
      setStep(currentState.draft.currentStep - 1);
    }
  }
}

final farmerWizardProvider =
    NotifierProvider<FarmerWizardNotifier, AsyncValue<FarmerWizardState>>(
  FarmerWizardNotifier.new,
);
