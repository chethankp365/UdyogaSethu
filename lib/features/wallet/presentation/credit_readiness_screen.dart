import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/services/voice_hints_helper.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/wallet/data/credit_readiness_repository.dart';
import 'package:udyogasethu/features/wallet/domain/credit_readiness_profile.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Guidance-only Credit Readiness Screen.
/// Informs gig workers and farmers of their digital footprint readiness without promising loans.
class CreditReadinessScreen extends ConsumerStatefulWidget {
  const CreditReadinessScreen({super.key});

  @override
  ConsumerState<CreditReadinessScreen> createState() => _CreditReadinessScreenState();
}

class _CreditReadinessScreenState extends ConsumerState<CreditReadinessScreen> {
  static const String mandatoryDisclaimer =
      'This is guidance only. It does not guarantee any loan. Future links to regulated financial partners would need your consent.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VoiceHintsHelper.speakScreenHint(
        ref,
        hintText: 'View your credit readiness guidance and steps to build financial records.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(creditReadinessProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.creditReadinessTitle ?? 'Credit Readiness Guidance',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [
          VoiceHintSpeakerButton(
            hintText: 'View your credit readiness guidance and steps to build financial records.',
            color: Colors.white,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(creditReadinessProfileProvider),
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _buildErrorState(context, err),
              data: (profile) => _buildContent(context, profile, l10n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CreditReadinessProfile profile,
    AppLocalizations? l10n,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 1. Mandatory Clear Disclaimer Banner
        _buildDisclaimerBanner(),
        const SizedBox(height: 16),

        // 2. Conceptual Readiness Score Gauge
        _buildReadinessGaugeCard(profile),
        const SizedBox(height: 16),

        // 3. Four Core Readiness Pillars
        const Text(
          'Readiness Assessment Factors',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.headerGreenDark,
          ),
        ),
        const SizedBox(height: 8),
        ...profile.pillars.map((pillar) => _buildPillarCard(context, pillar)),
        const SizedBox(height: 16),

        // 4. Actionable Next Steps
        _buildActionableStepsCard(profile),
        const SizedBox(height: 16),

        // 5. Educational Guidance Footer
        _buildEducationalFooter(),
      ],
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              mandatoryDisclaimer,
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessGaugeCard(CreditReadinessProfile profile) {
    Color bandColor;
    switch (profile.band) {
      case CreditReadinessBand.strong:
        bandColor = const Color(0xFF0D6548);
        break;
      case CreditReadinessBand.good:
        bandColor = const Color(0xFF0284C7);
        break;
      case CreditReadinessBand.developing:
        bandColor = const Color(0xFFD97706);
        break;
      case CreditReadinessBand.building:
        bandColor = const Color(0xFF475569);
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Readiness Footprint Index',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.band.label} Readiness',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: bandColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on verified identity, digital settlements, and customer ratings.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: bandColor, width: 6),
                  ),
                  child: Center(
                    child: Text(
                      '${profile.conceptualScore}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: bandColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: profile.conceptualScore / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(bandColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatPill('Completed Jobs', '${profile.completedJobsCount}')),
                Expanded(child: _buildStatPill('Platform Tenure', '${profile.accountTenureDays} days')),
                Expanded(child: _buildStatPill('Disputes', '${profile.disputesCount}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildPillarCard(BuildContext context, ReadinessPillar pillar) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: pillar.isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                pillar.isCompleted ? Icons.check_circle_rounded : Icons.pending_outlined,
                color: pillar.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        pillar.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pillar.isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: pillar.isCompleted ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          pillar.statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: pillar.isCompleted ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pillar.actionPrompt,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionableStepsCard(CreditReadinessProfile profile) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag_rounded, color: AppColors.headerGreenDark, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recommended Actionable Steps',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headerGreenDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...profile.actionableNextSteps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right_rounded, color: AppColors.headerGreenDark, size: 20),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            if (!profile.identityVerified)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.verified_user_rounded, size: 16),
                  label: const Text('Verify Identity (Aadhaar eKYC)'),
                  onPressed: () => context.push(AppRoutes.kyc),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How Does UdyogaSethu Use This Guidance?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'UdyogaSethu is not a bank or lender. We help workers build an authentic digital track record of earnings, completed work, and verified reviews. In the future, you may choose to share this verified track record with RBI-regulated financial institutions for credit evaluation only with your explicit consent.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Could not load credit readiness data: $err', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(creditReadinessProfileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
