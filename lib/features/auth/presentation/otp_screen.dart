import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/features/auth/data/phone_auth_notifier.dart';
import 'package:udyogasethu/features/auth/domain/phone_auth_state.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// SMS Retriever implementation using SmartAuth for Pinput user-consent autofill.
class SmsRetrieverImpl implements SmsRetriever {
  const SmsRetrieverImpl(this.smartAuth);

  final SmartAuth smartAuth;

  @override
  Future<void> dispose() async {
    await smartAuth.removeUserConsentApiListener();
  }

  @override
  Future<String?> getSmsCode() async {
    try {
      final res = await smartAuth.getSmsWithUserConsentApi();
      if (res.hasData && res.data?.code != null) {
        return res.data!.code;
      }
    } catch (_) {}
    return null;
  }

  @override
  bool get listenForMultipleSms => false;
}


/// 6-Digit SMS OTP Verification Screen.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late final TextEditingController _pinController;
  late final FocusNode _focusNode;
  late final SmsRetrieverImpl _smsRetriever;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _focusNode = FocusNode();
    _smsRetriever = SmsRetrieverImpl(SmartAuth.instance);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _smsRetriever.dispose();
    super.dispose();
  }

  Future<void> _handleVerify(String code) async {
    final notifier = ref.read(phoneAuthProvider.notifier);
    final success = await notifier.verifyCurrentOtp(code);
    if (success && mounted) {
      context.go(AppRoutes.splash); // Triggers Bootstrap (P2.6)
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(phoneAuthProvider);
    final notifier = ref.read(phoneAuthProvider.notifier);

    final maskedPhone = authState.phone.length == 10
        ? '******${authState.phone.substring(6)}'
        : authState.phone;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderGreen),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.paleMint,
        border: Border.all(color: AppColors.primaryTeal, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.paleMint,
        border: Border.all(color: AppColors.primaryTeal, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          key: const Key('otpBackButton'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.headerGreenDark),
          onPressed: () {
            notifier.changeNumber();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Title & Subtitle
              Text(
                l10n.otpTitle,
                style: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                l10n.otpSubtitle(maskedPhone),
                style: AppTypography.bodyMedium(AppColors.textMuted),
              ),

              const SizedBox(height: 24),

              // Error Banner
              if (authState.errorMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warningOrange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: AppTypography.bodySmall(AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 2. 6-Box Pinput Field
              Center(
                child: Pinput(
                  key: const Key('otpPinputField'),
                  length: 6,
                  controller: _pinController,
                  focusNode: _focusNode,
                  smsRetriever: _smsRetriever,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  autofocus: true,
                  onCompleted: (pin) => _handleVerify(pin),
                ),
              ),

              const SizedBox(height: 28),

              // 3. Verify & Login Action Button
              AppButton(
                key: const Key('verifyOtpButton'),
                label: l10n.verifyAndLogin,
                isLoading: authState.isLoading || authState.step == PhoneAuthStep.verifying,
                onPressed: _pinController.text.length == 6 && !authState.isLoading
                    ? () => _handleVerify(_pinController.text)
                    : null,
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),

              const SizedBox(height: 20),

              // 4. Resend Code Row & Countdown Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Countdown or Resend limit status
                  if (authState.resendsCount >= 3)
                    Text(
                      l10n.maxResendsReached,
                      style: AppTypography.bodySmall(AppColors.errorRed).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (authState.resendCountdown > 0)
                    Text(
                      l10n.resendCodeIn(authState.resendCountdown.toString()),
                      style: AppTypography.bodySmall(AppColors.textMuted),
                    )
                  else
                    const SizedBox.shrink(),

                  // Resend Button
                  TextButton.icon(
                    key: const Key('resendOtpButton'),
                    onPressed: authState.canResendOtp
                        ? () async {
                            _pinController.clear();
                            await notifier.resendOtp();
                          }
                        : null,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      l10n.resendCode,
                      style: TextStyle(
                        color: authState.canResendOtp
                            ? AppColors.headerGreenDark
                            : AppColors.dividerLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 5. Change Number Action Link
              Center(
                child: TextButton(
                  key: const Key('changeNumberButton'),
                  onPressed: () {
                    notifier.changeNumber();
                    context.pop();
                  },
                  child: Text(
                    l10n.changeNumber,
                    style: AppTypography.button(AppColors.headerGreenDark).copyWith(
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
