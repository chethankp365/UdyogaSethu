import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/features/auth/data/phone_auth_notifier.dart';
import 'package:udyogasethu/features/auth/domain/phone_auth_state.dart';
import 'package:udyogasethu/features/demo/presentation/demo_launcher_sheet.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Mobile Number Login Screen matching Screen 4 in UI_REFERENCE.md.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final currentPhone = ref.read(phoneAuthProvider).phone;
    _phoneController = TextEditingController(text: currentPhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGetOtp() async {
    final notifier = ref.read(phoneAuthProvider.notifier);
    final success = await notifier.sendOtp();
    if (success && mounted) {
      context.push(AppRoutes.otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(phoneAuthProvider);
    final notifier = ref.read(phoneAuthProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar & Language Selector Chip Row
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo_small.png',
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: CompactLanguageSelector()),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Title & Subtitle
              Text(
                l10n.loginTitle,
                style: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                l10n.loginSubtitle,
                style: AppTypography.bodyMedium(AppColors.textMuted),
              ),

              const SizedBox(height: 24),

              // Error Banner Display
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

              // 3. Mobile Number Input Container (+91 Prefix + 10-digit Input)
              Text(
                l10n.phoneInputLabel,
                style: AppTypography.label(AppColors.textDark).copyWith(
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: authState.isPhoneValid
                        ? AppColors.primaryTeal
                        : AppColors.borderLight,
                    width: authState.isPhoneValid ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // IN +91 Prefix Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: const BoxDecoration(
                        color: AppColors.paleMint,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(11),
                          bottomLeft: Radius.circular(11),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'IN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+91',
                            style: AppTypography.titleMedium(AppColors.headerGreenDark).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 10-digit Phone Text Field
                    Expanded(
                      child: TextField(
                        key: const Key('phoneInputField'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: AppTypography.titleMedium(AppColors.textDark).copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: '9123456789',
                          hintStyle: AppTypography.bodyMedium(AppColors.dividerLight),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: (val) {
                          notifier.updatePhone(val);
                        },
                      ),
                    ),

                    if (authState.isPhoneValid) ...[
                      const Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 22),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Terms and Privacy Checkbox Line
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      key: const Key('termsCheckbox'),
                      value: authState.termsAccepted,
                      activeColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) {
                        if (val != null) notifier.toggleTerms(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => notifier.toggleTerms(!authState.termsAccepted),
                      child: Text(
                        l10n.agreeTermsDisclaimer,
                        style: AppTypography.bodySmall(AppColors.textDark).copyWith(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. Get SMS OTP Verification Code Button
              AppButton(
                key: const Key('getOtpButton'),
                label: l10n.getOtpCode,
                isLoading: authState.isLoading,
                onPressed: authState.canRequestOtp ? _handleGetOtp : null,
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),

              const SizedBox(height: 20),

              // Divider Line
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.borderLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'OR',
                      style: AppTypography.label(AppColors.textMuted).copyWith(fontSize: 11),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderLight)),
                ],
              ),

              const SizedBox(height: 20),

              // 6. Continue with Google Button
              OutlinedButton.icon(
                key: const Key('googleLoginButton'),
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        final router = GoRouter.of(context);
                        final success = await notifier.signInWithGoogle();
                        if (!mounted || !success) return;
                        final currentStep = ref.read(phoneAuthProvider).step;
                        if (currentStep == PhoneAuthStep.needsPhoneVerification) {
                          router.push(AppRoutes.verifyPhone);
                        } else if (currentStep == PhoneAuthStep.success) {
                          router.go(AppRoutes.splash);
                        }
                      },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  backgroundColor: Colors.white,
                ),
                icon: SvgPicture.asset(
                  'assets/images/google_logo.svg',
                  height: 20,
                  width: 20,
                ),
                label: authState.isLoading && authState.step == PhoneAuthStep.inputPhone
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryTeal,
                        ),
                      )
                    : Text(
                        l10n.continueWithGoogle,
                        style: AppTypography.button(AppColors.textDark).copyWith(fontSize: 14),
                      ),
              ),

              // 7. Evaluator Demo Shortcuts (Strictly Gated to Demo Builds)
              if (Env.isDemoBuild) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.science_rounded, size: 18, color: Colors.amber.shade900),
                              const SizedBox(width: 6),
                              Text(
                                'EVALUATOR DEMO SHORTCUTS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEMO BUILD',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fast evaluator access to seeded accounts and the 5 guided end-to-end scenarios.',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push(AppRoutes.demoAccounts),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.amber.shade900,
                                side: BorderSide(color: Colors.amber.shade600),
                                backgroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.people_alt_outlined, size: 16),
                              label: const Text('Demo Accounts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => DemoLauncherSheet.show(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade800,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.play_circle_fill, size: 16),
                              label: const Text('5 Scenarios', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
