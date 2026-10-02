enum PhoneAuthStep {
  inputPhone,
  otpSent,
  verifying,
  needsPhoneVerification,
  success,
}

/// State representation for Phone OTP Authentication flow.
class PhoneAuthState {
  final PhoneAuthStep step;
  final String phone; // 10-digit raw number
  final bool termsAccepted;
  final bool isLoading;
  final String? errorMessage;
  final int resendCountdown; // seconds remaining before resend enabled
  final int resendsCount; // total resends performed in session
  final bool isRateLimited;
  final bool isPhoneChangeFlow;

  const PhoneAuthState({
    this.step = PhoneAuthStep.inputPhone,
    this.phone = '',
    this.termsAccepted = true,
    this.isLoading = false,
    this.errorMessage,
    this.resendCountdown = 30,
    this.resendsCount = 0,
    this.isRateLimited = false,
    this.isPhoneChangeFlow = false,
  });

  bool get isPhoneValid {
    final clean = phone.trim();
    return clean.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(clean);
  }

  bool get canRequestOtp {
    return isPhoneValid && termsAccepted && !isLoading && !isRateLimited;
  }

  bool get canResendOtp {
    return step == PhoneAuthStep.otpSent &&
        resendCountdown == 0 &&
        resendsCount < 3 &&
        !isLoading &&
        !isRateLimited;
  }

  PhoneAuthState copyWith({
    PhoneAuthStep? step,
    String? phone,
    bool? termsAccepted,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? resendCountdown,
    int? resendsCount,
    bool? isRateLimited,
    bool? isPhoneChangeFlow,
  }) {
    return PhoneAuthState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      resendCountdown: resendCountdown ?? this.resendCountdown,
      resendsCount: resendsCount ?? this.resendsCount,
      isRateLimited: isRateLimited ?? this.isRateLimited,
      isPhoneChangeFlow: isPhoneChangeFlow ?? this.isPhoneChangeFlow,
    );
  }
}
