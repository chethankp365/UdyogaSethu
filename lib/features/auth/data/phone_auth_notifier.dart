import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/auth/data/auth_repository.dart';
import 'package:udyogasethu/features/auth/domain/phone_auth_state.dart';

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

        // Update global AppSessionNotifier to ready or needsProfile
        ref.read(appSessionProvider.notifier).updateSession(
          status: AuthSessionStatus.ready,
        );

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

  void changeNumber() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      step: PhoneAuthStep.inputPhone,
      clearErrorMessage: true,
      isLoading: false,
    );
  }

  void reset() {
    _countdownTimer?.cancel();
    state = const PhoneAuthState();
  }
}

final phoneAuthProvider =
    NotifierProvider<PhoneAuthNotifier, PhoneAuthState>(PhoneAuthNotifier.new);
