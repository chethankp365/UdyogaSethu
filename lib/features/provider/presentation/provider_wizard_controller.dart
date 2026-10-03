import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';
import 'package:udyogasethu/features/provider/data/provider_profile_repository.dart';
import 'package:udyogasethu/features/provider/domain/provider_profile_draft.dart';

final providerProfileRepositoryProvider = Provider<ProviderProfileRepository>((ref) {
  return SupabaseProviderProfileRepository();
});

class ProviderWizardState {
  final ProviderProfileDraft draft;
  final bool isSaving;
  final String? errorMessage;
  final String? uploadError;

  const ProviderWizardState({
    required this.draft,
    this.isSaving = false,
    this.errorMessage,
    this.uploadError,
  });

  ProviderWizardState copyWith({
    ProviderProfileDraft? draft,
    bool? isSaving,
    String? errorMessage,
    String? uploadError,
  }) {
    return ProviderWizardState(
      draft: draft ?? this.draft,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      uploadError: uploadError,
    );
  }
}

class ProviderWizardNotifier extends Notifier<AsyncValue<ProviderWizardState>> {
  late final ProviderProfileRepository _repository;
  final FlutterTts _tts = FlutterTts();

  @override
  AsyncValue<ProviderWizardState> build() {
    _repository = ref.watch(providerProfileRepositoryProvider);
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
      state = AsyncValue.data(ProviderWizardState(draft: draft));
    } catch (e, stack) {
      AppLogger.e('Failed to load provider wizard state', e, stack);
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

  void updateDraft(ProviderProfileDraft Function(ProviderProfileDraft current) updateFn) {
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

  Future<void> logConsent(String consentType) async {
    await _repository.logConsent(consentType: consentType);
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
      AppLogger.e('Save provider step $step error', e, StackTrace.current);
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
      if (draft.providerType.isEmpty) {
        state = AsyncValue.data(currentState.copyWith(
          errorMessage: 'Please select provider type',
        ));
        return false;
      }
    } else if (step == 3) {
      if (draft.isHousehold) {
        if (draft.addressLine1.trim().isEmpty) {
          state = AsyncValue.data(currentState.copyWith(
            errorMessage: 'Please enter flat / house number and street',
          ));
          return false;
        }
      } else {
        if (draft.orgName.trim().isEmpty) {
          state = AsyncValue.data(currentState.copyWith(
            errorMessage: 'Please enter organisation name',
          ));
          return false;
        }
        if (draft.siteAddressLine1.trim().isEmpty) {
          state = AsyncValue.data(currentState.copyWith(
            errorMessage: 'Please enter primary site address',
          ));
          return false;
        }
        if (draft.categoriesHiring.isEmpty) {
          state = AsyncValue.data(currentState.copyWith(
            errorMessage: 'Please select at least one hiring category',
          ));
          return false;
        }
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
        AppLogger.d('completeWizard() start: role=provider, AppSession status before=${beforeSession.status}');
      }
      state = AsyncValue.data(currentState.copyWith(isSaving: true, errorMessage: null));
      try {
        await _repository.completeWizard(draft);
        if (kDebugMode) {
          AppLogger.d('completeWizard() DB update succeeded for provider');
        }

        ref.read(appSessionProvider.notifier).updateSession(
          status: AuthSessionStatus.ready,
          role: UserRole.provider,
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
          AppLogger.e('Complete provider wizard error: $e', e, stack);
        }
        state = AsyncValue.data(currentState.copyWith(
          isSaving: false,
          errorMessage: 'Failed to complete provider setup. ${e is AppException ? e.message : e.toString()}',
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

final providerWizardProvider =
    NotifierProvider<ProviderWizardNotifier, AsyncValue<ProviderWizardState>>(
  ProviderWizardNotifier.new,
);
