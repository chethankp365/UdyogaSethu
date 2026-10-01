import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/features/onboarding/data/role_tree_service.dart';
import 'package:udyogasethu/features/onboarding/domain/pending_role_selection.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Guided Account Role Selection Tree Screen (Step P2.3 in AGENTS.md).
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
    } catch (_) {}
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakCurrentStep(AppLocalizations l10n, RoleTreeState state) async {
    setState(() => _isPlayingTts = true);
    try {
      final currentLocale = ref.read(localeProvider);
      final ttsLangCode = _getTtsLanguageCode(currentLocale.languageCode);
      await _flutterTts.setLanguage(ttsLangCode);

      String speechText = '';
      if (state.currentStep == 1) {
        speechText = '${l10n.roleTreeTitleStep1}. ${l10n.roleCategoryWorker}: ${l10n.roleCategoryWorkerDesc}. ${l10n.roleCategoryFarmer}: ${l10n.roleCategoryFarmerDesc}.';
      } else if (state.currentStep == 2) {
        speechText = '${l10n.roleTreeTitleStep2}. ${l10n.roleSeekerTitle}: ${l10n.roleSeekerDesc}. ${l10n.roleProviderTitle}: ${l10n.roleProviderDesc}.';
      } else {
        speechText = '${l10n.roleTreeTitleStep3}. ${l10n.seekerTypeInformalTitle}: ${l10n.seekerTypeInformalDesc}. ${l10n.seekerTypeStudentTitle}: ${l10n.seekerTypeStudentDesc}. ${l10n.seekerTypePartTimeTitle}: ${l10n.seekerTypePartTimeDesc}.';
      }

      await _flutterTts.speak(speechText);
    } catch (_) {
      if (mounted) setState(() => _isPlayingTts = false);
    }
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

  void _handleBack() {
    final handled = ref.read(roleTreeProvider.notifier).goBack();
    if (!handled) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.language);
      }
    }
  }

  void _handleContinue(RoleTreeState state) {
    final notifier = ref.read(roleTreeProvider.notifier);

    if (state.currentStep == 1) {
      if (state.selectedCategory == 'farmer') {
        ref.read(appSessionProvider.notifier).setRole(UserRole.farmer);
        context.go(AppRoutes.login);
      } else if (state.selectedCategory == 'worker') {
        notifier.confirmStep1();
      }
    } else if (state.currentStep == 2) {
      if (state.selectedRole == UserRole.provider) {
        ref.read(appSessionProvider.notifier).setRole(UserRole.provider);
        context.go(AppRoutes.login);
      } else if (state.selectedRole == UserRole.seeker) {
        notifier.confirmStep2();
      }
    } else if (state.currentStep == 3) {
      if (state.selectedSeekerType != null) {
        ref.read(appSessionProvider.notifier).setRole(UserRole.seeker);
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final treeState = ref.watch(roleTreeProvider);
    final currentLocale = ref.watch(localeProvider);
    final langOption = AppLanguages.fromCode(currentLocale.languageCode);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('roleTreeBackButton'),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.headerGreenDark),
                    onPressed: _handleBack,
                    tooltip: l10n.back,
                  ),
                  Image.asset(
                    'assets/images/logo_small.png',
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  // Voice Speaker narration button
                  IconButton(
                    key: const Key('roleTreeSpeakerButton'),
                    icon: _isPlayingTts
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.headerGreenDark,
                            ),
                          )
                        : const Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.headerGreenDark,
                            size: 24,
                          ),
                    onPressed: _isPlayingTts ? null : () => _speakCurrentStep(l10n, treeState),
                    tooltip: l10n.listenToStepOptions(langOption.englishName),
                  ),
                ],
              ),
            ),

            // 2. Compact Language Selector Chip Row
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CompactLanguageSelector(),
            ),

            const SizedBox(height: 12),

            // 3. Step Dots & Breadcrumb Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Step Indicator Dots
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index < treeState.currentStep;
                      final isCurrent = index == treeState.currentStep - 1;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: isCurrent ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.headerGreenDark
                              : AppColors.dividerLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Breadcrumb tag
                  if (treeState.currentStep > 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.paleMint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorderGreen),
                      ),
                      child: Text(
                        treeState.currentStep == 2
                            ? l10n.breadcrumbWorker
                            : l10n.breadcrumbSeeker,
                        style: AppTypography.label(AppColors.headerGreenDark).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4. Main Title & Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStepTitle(l10n, treeState.currentStep),
                      style: AppTypography.displayMedium(AppColors.headerGreenDark).copyWith(
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStepSubtitle(l10n, treeState.currentStep),
                      style: AppTypography.bodyMedium(AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. Options Cards Container
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    if (treeState.currentStep == 1) ...[
                      // Step 1: Worker vs Farmer
                      _RoleCardTile(
                        key: const Key('cardWorker'),
                        title: l10n.roleCategoryWorker,
                        description: l10n.roleCategoryWorkerDesc,
                        icon: Icons.engineering_rounded,
                        isSelected: treeState.selectedCategory == 'worker',
                        onTap: () {
                          ref.read(roleTreeProvider.notifier).selectCategory('worker');
                        },
                      ),
                      const SizedBox(height: 12),
                      _RoleCardTile(
                        key: const Key('cardFarmer'),
                        title: l10n.roleCategoryFarmer,
                        description: l10n.roleCategoryFarmerDesc,
                        icon: Icons.eco_rounded,
                        isSelected: treeState.selectedCategory == 'farmer',
                        onTap: () {
                          ref.read(roleTreeProvider.notifier).selectCategory('farmer');
                        },
                      ),
                    ] else if (treeState.currentStep == 2) ...[
                      // Step 2: Job Seeker vs Job Provider
                      _RoleCardTile(
                        key: const Key('cardSeeker'),
                        title: l10n.roleSeekerTitle,
                        description: l10n.roleSeekerDesc,
                        icon: Icons.person_search_rounded,
                        isSelected: treeState.selectedRole == UserRole.seeker,
                        onTap: () {
                          ref.read(roleTreeProvider.notifier).selectRole(UserRole.seeker);
                        },
                      ),
                      const SizedBox(height: 12),
                      _RoleCardTile(
                        key: const Key('cardProvider'),
                        title: l10n.roleProviderTitle,
                        description: l10n.roleProviderDesc,
                        icon: Icons.business_center_rounded,
                        isSelected: treeState.selectedRole == UserRole.provider,
                        onTap: () {
                          ref.read(roleTreeProvider.notifier).selectRole(UserRole.provider);
                        },
                      ),
                    ] else if (treeState.currentStep == 3) ...[
                      // Step 3: Seeker Types
                      _RoleCardTile(
                        key: const Key('cardSeekerInformal'),
                        title: l10n.seekerTypeInformalTitle,
                        description: l10n.seekerTypeInformalDesc,
                        icon: Icons.construction_rounded,
                        isSelected: treeState.selectedSeekerType == SeekerType.informal,
                        onTap: () {
                          ref
                              .read(roleTreeProvider.notifier)
                              .selectSeekerType(SeekerType.informal);
                        },
                      ),
                      const SizedBox(height: 12),
                      _RoleCardTile(
                        key: const Key('cardSeekerStudent'),
                        title: l10n.seekerTypeStudentTitle,
                        description: l10n.seekerTypeStudentDesc,
                        icon: Icons.school_rounded,
                        isSelected: treeState.selectedSeekerType == SeekerType.student,
                        onTap: () {
                          ref
                              .read(roleTreeProvider.notifier)
                              .selectSeekerType(SeekerType.student);
                        },
                      ),
                      const SizedBox(height: 12),
                      _RoleCardTile(
                        key: const Key('cardSeekerPartTime'),
                        title: l10n.seekerTypePartTimeTitle,
                        description: l10n.seekerTypePartTimeDesc,
                        icon: Icons.schedule_rounded,
                        isSelected: treeState.selectedSeekerType == SeekerType.partTime,
                        onTap: () {
                          ref
                              .read(roleTreeProvider.notifier)
                              .selectSeekerType(SeekerType.partTime);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 6. Bottom Sticky Actions Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  AppButton(
                    key: const Key('roleTreeContinueButton'),
                    label: l10n.continueButton,
                    onPressed: treeState.canContinue ? () => _handleContinue(treeState) : null,
                    variant: AppButtonVariant.primary,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: AppTypography.bodySmall(AppColors.textMuted),
                      ),
                      TextButton(
                        key: const Key('directLoginButton'),
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(
                          l10n.loginLink,
                          style: AppTypography.button(AppColors.headerGreenDark).copyWith(
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(AppLocalizations l10n, int step) {
    switch (step) {
      case 1:
        return l10n.roleTreeTitleStep1;
      case 2:
        return l10n.roleTreeTitleStep2;
      case 3:
        return l10n.roleTreeTitleStep3;
      default:
        return '';
    }
  }

  String _getStepSubtitle(AppLocalizations l10n, int step) {
    switch (step) {
      case 1:
        return l10n.roleTreeSubtitleStep1;
      case 2:
        return l10n.roleTreeSubtitleStep2;
      case 3:
        return l10n.roleTreeSubtitleStep3;
      default:
        return '';
    }
  }
}

/// Tappable Rounded Selection Card Tile matching UI_REFERENCE.md.
class _RoleCardTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCardTile({
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
            color: isSelected ? AppColors.primaryTeal : AppColors.cardBorderGreen,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container Box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : AppColors.paleMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.headerGreenDark,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Title and Description Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium(AppColors.textDark).copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: AppTypography.bodySmall(AppColors.textMuted).copyWith(
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Checkmark Circle Icon
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primaryTeal : AppColors.dividerLight,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
