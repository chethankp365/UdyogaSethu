import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/auth/data/auth_repository.dart';
import 'package:udyogasethu/features/auth/domain/phone_auth_state.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';

class PhoneAuthNotifier extends Notifier<PhoneAuthState> {
  Timer? _countdownTimer;

  @override
  PhoneAuthState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return const PhoneAuthState();
  }

  void updatePhone(String phone) {
    state = state.copyWith(
      phone: phone,
      clearErrorMessage: true,
    );
  }

  void toggleTerms(bool value) {
    state = state.copyWith(
      termsAccepted: value,
      clearErrorMessage: true,
    );
  }

  Future<bool> sendOtp() async {
    if (!state.canRequestOtp) return false;

    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      isRateLimited: false,
    );

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendSmsOtp(state.phone);

      state = state.copyWith(
        step: PhoneAuthStep.otpSent,
        isLoading: false,
        resendCountdown: 30,
      );
      _startResendTimer();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        isRateLimited: e.type == AppExceptionType.rateLimit,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP code. Please try again.',
      );
      return false;
    }
  }

  Future<bool> resendOtp() async {
    if (state.resendsCount >= 3) {
      state = state.copyWith(
        errorMessage: 'Maximum 3 resends allowed per session. Please try again later or change number.',
      );
      return false;
    }

    state = state.copyWith(
      resendsCount: state.resendsCount + 1,
    );

    return sendOtp();
  }


  void _startResendTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown > 1) {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      } else {
        state = state.copyWith(resendCountdown: 0);
        timer.cancel();
      }
    });
  }

  Future<bool> verifyOtp(String otpToken) async {
    if (otpToken.trim().length != 6) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 6-digit verification code.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      step: PhoneAuthStep.verifying,
      clearErrorMessage: true,
    );

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.verifySmsOtp(state.phone, otpToken);

      if (response.session != null) {
        state = state.copyWith(
          isLoading: false,
          step: PhoneAuthStep.success,
        );

        // Run bootstrap to process pending role selection and profile status
        await ref.read(bootstrapProvider.notifier).runBootstrap();

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          step: PhoneAuthStep.otpSent,
          errorMessage: 'Verification failed. Session could not be created.',
        );
        return false;
      }
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        step: PhoneAuthStep.otpSent,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        step: PhoneAuthStep.otpSent,
        errorMessage: 'Verification error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
    );

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signInWithGoogle();

      if (response == null) {
        // User cancelled sign in
        state = state.copyWith(isLoading: false);
        return false;
      }

      if (response.user != null) {
        final user = response.user!;
        final phone = user.phone;

        if (phone == null || phone.trim().isEmpty) {
          // Google-first user must verify phone number
          state = state.copyWith(
            isLoading: false,
            step: PhoneAuthStep.needsPhoneVerification,
            clearErrorMessage: true,
          );
          return true;
        }

        // Account has both Google and Phone verified
        state = state.copyWith(
          isLoading: false,
          step: PhoneAuthStep.success,
        );

        await ref.read(bootstrapProvider.notifier).runBootstrap();
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google sign-in failed. Session could not be created.',
      );
      return false;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred during Google sign-in. Please try again.',
      );
      return false;
    }
  }

  Future<bool> sendPhoneChangeOtp() async {
    if (!state.isPhoneValid) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 10-digit mobile number starting with 6-9',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      isPhoneChangeFlow: true,
    );

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPhoneChangeOtp(state.phone);

      state = state.copyWith(
        step: PhoneAuthStep.otpSent,
        isLoading: false,
        resendCountdown: 30,
        isPhoneChangeFlow: true,
      );
      _startResendTimer();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send verification code to mobile number.',
      );
      return false;
    }
  }

  Future<bool> verifyCurrentOtp(String otpToken) async {
    if (state.isPhoneChangeFlow) {
      return verifyPhoneChangeOtp(otpToken);
    } else {
      return verifyOtp(otpToken);
    }
  }

  Future<bool> verifyPhoneChangeOtp(String otpToken) async {
    if (otpToken.trim().length != 6) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 6-digit verification code.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      step: PhoneAuthStep.verifying,
      clearErrorMessage: true,
    );

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.verifyPhoneChangeOtp(state.phone, otpToken);

      if (response.session != null || response.user != null) {
        state = state.copyWith(
          isLoading: false,
          step: PhoneAuthStep.success,
        );

        await ref.read(bootstrapProvider.notifier).runBootstrap();
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        step: PhoneAuthStep.otpSent,
        errorMessage: 'Phone verification failed.',
      );
      return false;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        step: PhoneAuthStep.otpSent,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        step: PhoneAuthStep.otpSent,
        errorMessage: 'Verification error occurred. Please try again.',
      );
      return false;
    }
  }

  void changeNumber() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      step: PhoneAuthStep.inputPhone,
      clearErrorMessage: true,
      isLoading: false,
      isPhoneChangeFlow: false,
    );
  }

  void reset() {
    _countdownTimer?.cancel();
    state = const PhoneAuthState();
  }
}

final phoneAuthProvider =
    NotifierProvider<PhoneAuthNotifier, PhoneAuthState>(PhoneAuthNotifier.new);

