import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/features/onboarding/data/role_selection_service.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Guided Role Selection Decision Tree Screen (Step P2.3).
class RoleTreeScreen extends ConsumerStatefulWidget {
  const RoleTreeScreen({super.key});

  @override
  ConsumerState<RoleTreeScreen> createState() => _RoleTreeScreenState();
}

class _RoleTreeScreenState extends ConsumerState<RoleTreeScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlayingTts = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isPlayingTts = false);
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) setState(() => _isPlayingTts = false);
      });
    } catch (_) {
      // Ignore initial TTS setup error
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  String _getTtsLanguageCode(String code) {
    switch (code) {
      case 'kn':
        return 'kn-IN';
      case 'hi':
        return 'hi-IN';
      case 'te':
        return 'te-IN';
      case 'ta':
        return 'ta-IN';
      case 'mr':
        return 'mr-IN';
      case 'bn':
        return 'bn-IN';
      case 'or':
        return 'or-IN';
      default:
        return 'en-US';
    }
  }

  Future<void> _readStepAloud(
      AppLocalizations l10n, String langCode, PendingRoleSelection pending) async {
    setState(() => _isPlayingTts = true);

    try {
      final ttsCode = _getTtsLanguageCode(langCode);
      await _flutterTts.setLanguage(ttsCode);

      final String speechText;
      if (pending.currentStep == 1) {
        speechText =
            '${l10n.roleTreeTitleStep1}. ${l10n.roleCardWorkerTitle}: ${l10n.roleCardWorkerDesc}. ${l10n.roleCardFarmerTitle}: ${l10n.roleCardFarmerDesc}.';
      } else if (pending.currentStep == 2) {
        speechText =
            '${l10n.roleTreeTitleStep2}. ${l10n.roleCardJobSeekerTitle}: ${l10n.roleCardJobSeekerDesc}. ${l10n.roleCardJobProviderTitle}: ${l10n.roleCardJobProviderDesc}.';
      } else {
        speechText =
            '${l10n.roleTreeTitleStep3}. ${l10n.seekerTypeInformalTitle}: ${l10n.seekerTypeInformalDesc}. ${l10n.seekerTypeStudentTitle}: ${l10n.seekerTypeStudentDesc}. ${l10n.seekerTypePartTimeTitle}: ${l10n.seekerTypePartTimeDesc}.';
      }

      await _flutterTts.speak(speechText);
    } catch (_) {
      if (mounted) setState(() => _isPlayingTts = false);
    }
  }

  void _handleContinue(PendingRoleSelection pending) {
    final notifier = ref.read(roleSelectionProvider.notifier);
    final isComplete = notifier.advanceStep();
    if (isComplete) {
      context.go(AppRoutes.login);
    }
  }

  void _handleBack(PendingRoleSelection pending) {
    if (pending.currentStep > 1) {
      ref.read(roleSelectionProvider.notifier).goBackStep();
    } else {
      context.go(AppRoutes.language);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = ref.watch(roleSelectionProvider);
    final locale = ref.watch(localeProvider);

    final currentStep = pending.currentStep;

    // Title based on step
    final String stepTitle;
    if (currentStep == 1) {
      stepTitle = l10n.roleTreeTitleStep1;
    } else if (currentStep == 2) {
      stepTitle = l10n.roleTreeTitleStep2;
    } else {
      stepTitle = l10n.roleTreeTitleStep3;
    }

    // Breadcrumb based on step
    String? breadcrumbText;
    if (currentStep == 2) {
      breadcrumbText = l10n.roleCardWorkerTitle;
    } else if (currentStep == 3) {
      breadcrumbText = '${l10n.roleCardWorkerTitle} > ${l10n.roleCardJobSeekerTitle}';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          key: const Key('role_tree_back_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => _handleBack(pending),
        ),
        title: const CompactLanguageSelector(),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Indicator Row (Dots + Speaker button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step Indicator Dots
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = (index + 1) == currentStep;
                      final isPassed = (index + 1) < currentStep;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryTeal
                              : (isPassed ? AppColors.headerGreenDark : AppColors.dividerLight),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),

                  // Low-literacy Speaker Button
                  IconButton(
                    key: const Key('role_tree_tts_button'),
                    onPressed: _isPlayingTts
                        ? null
                        : () => _readStepAloud(l10n, locale.languageCode, pending),
                    icon: _isPlayingTts
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primaryTeal),
                          )
                        : const Icon(Icons.volume_up_rounded,
                            color: AppColors.primaryTeal, size: 26),
                    tooltip: l10n.speakQuestion,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. Title & Breadcrumb
              Text(
                stepTitle,
                style: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (breadcrumbText != null) ...[
                const SizedBox(height: 4),
                Text(
                  breadcrumbText,
                  style: AppTypography.bodySmall(AppColors.primaryTeal).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 3. Main Step Cards List
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (currentStep == 1) ...[
                        // Step 1: Worker vs Farmer
                        _RoleOptionCard(
                          key: const Key('role_card_worker'),
                          title: l10n.roleCardWorkerTitle,
                          description: l10n.roleCardWorkerDesc,
                          icon: Icons.construction_rounded,
                          isSelected: pending.primaryRole == 'worker',
                          onTap: () =>
                              ref.read(roleSelectionProvider.notifier).selectPrimaryRole('worker'),
                        ),
                        const SizedBox(height: 14),
                        _RoleOptionCard(
                          key: const Key('role_card_farmer'),
                          title: l10n.roleCardFarmerTitle,
                          description: l10n.roleCardFarmerDesc,
                          icon: Icons.agriculture_rounded,
                          isSelected: pending.primaryRole == 'farmer',
                          onTap: () =>
                              ref.read(roleSelectionProvider.notifier).selectPrimaryRole('farmer'),
                        ),
                      ] else if (currentStep == 2) ...[
                        // Step 2: Job Seeker vs Job Provider
                        _RoleOptionCard(
                          key: const Key('role_card_seeker'),
                          title: l10n.roleCardJobSeekerTitle,
                          description: l10n.roleCardJobSeekerDesc,
                          icon: Icons.person_search_rounded,
                          isSelected: pending.secondaryRole == 'seeker',
                          onTap: () => ref
                              .read(roleSelectionProvider.notifier)
                              .selectSecondaryRole('seeker'),
                        ),
                        const SizedBox(height: 14),
                        _RoleOptionCard(
                          key: const Key('role_card_provider'),
                          title: l10n.roleCardJobProviderTitle,
                          description: l10n.roleCardJobProviderDesc,
                          icon: Icons.business_center_rounded,
                          isSelected: pending.secondaryRole == 'provider',
                          onTap: () => ref
                              .read(roleSelectionProvider.notifier)
                              .selectSecondaryRole('provider'),
                        ),
                      ] else ...[
                        // Step 3: Seeker Types
                        _RoleOptionCard(
                          key: const Key('seeker_type_informal'),
                          title: l10n.seekerTypeInformalTitle,
                          description: l10n.seekerTypeInformalDesc,
                          icon: Icons.handyman_rounded,
                          isSelected: pending.seekerType == 'informal',
                          onTap: () => ref
                              .read(roleSelectionProvider.notifier)
                              .selectSeekerType('informal'),
                        ),
                        const SizedBox(height: 14),
                        _RoleOptionCard(
                          key: const Key('seeker_type_student'),
                          title: l10n.seekerTypeStudentTitle,
                          description: l10n.seekerTypeStudentDesc,
                          icon: Icons.school_rounded,
                          isSelected: pending.seekerType == 'student',
                          onTap: () => ref
                              .read(roleSelectionProvider.notifier)
                              .selectSeekerType('student'),
                        ),
                        const SizedBox(height: 14),
                        _RoleOptionCard(
                          key: const Key('seeker_type_part_time'),
                          title: l10n.seekerTypePartTimeTitle,
                          description: l10n.seekerTypePartTimeDesc,
                          icon: Icons.access_time_rounded,
                          isSelected: pending.seekerType == 'part_time',
                          onTap: () => ref
                              .read(roleSelectionProvider.notifier)
                              .selectSeekerType('part_time'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. Bottom Continue Action Button
              AppButton(
                key: const Key('role_tree_continue_button'),
                label: l10n.continueButton,
                onPressed: pending.hasSelectionForCurrentStep
                    ? () => _handleContinue(pending)
                    : null,
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),

              const SizedBox(height: 10),

              // 5. Bottom "Already have an account? Log in" Link
              Center(
                child: TextButton(
                  key: const Key('role_tree_login_button'),
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(
                    l10n.alreadyHaveAccount,
                    style: AppTypography.button(AppColors.primaryTeal).copyWith(
                      fontSize: 14,
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

/// Option Card widget maintaining existing visual language (rounded card with icon, title, description, checkmark).
class _RoleOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paleMint : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.borderLight,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryTeal
                    : AppColors.primaryTeal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : AppColors.primaryTeal,
              ),
            ),

            const SizedBox(width: 14),

            // Content Column (Title & Description)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium(AppColors.textDark).copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.bodyMedium(AppColors.textMuted).copyWith(
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right Checkmark / Radio Icon
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 24,
              color: isSelected ? AppColors.primaryTeal : AppColors.dividerLight,
            ),
          ],
        ),
      ),
    );
  }
}
