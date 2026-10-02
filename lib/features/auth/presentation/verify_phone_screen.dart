import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/features/auth/data/phone_auth_notifier.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Verify Mobile Number Screen for Google-first users matching Screen 4 visual style.
class VerifyPhoneScreen extends ConsumerStatefulWidget {
  const VerifyPhoneScreen({super.key});

  @override
  ConsumerState<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends ConsumerState<VerifyPhoneScreen> {
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
    final success = await notifier.sendPhoneChangeOtp();
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          key: const Key('verifyPhoneBackButton'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.headerGreenDark),
          onPressed: () {
            notifier.reset();
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
              // 1. Language selector header
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
                l10n.verifyPhoneTitle,
                style: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                l10n.verifyPhoneSubtitle,
                style: AppTypography.bodyMedium(AppColors.textMuted),
              ),

              const SizedBox(height: 24),

              // Error Display
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

              // 3. Mobile Input
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
                    color: authState.isPhoneValid ? AppColors.primaryTeal : AppColors.borderLight,
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
                    Expanded(
                      child: TextField(
                        key: const Key('verifyPhoneInputField'),
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

              const SizedBox(height: 28),

              // 4. Action button
              AppButton(
                key: const Key('sendVerificationOtpButton'),
                label: l10n.getOtpCode,
                isLoading: authState.isLoading,
                onPressed: authState.isPhoneValid && !authState.isLoading ? _handleGetOtp : null,
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
