import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/services/voice_hints_helper.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/account/presentation/settings_controller.dart';
import 'package:udyogasethu/features/farmer/domain/ai_assist_models.dart';
import 'package:udyogasethu/features/wellness/data/wellness_repository.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Wellness, Benefits and Safety Guidance Hub.
/// Curated social welfare schemes, site safety protocols, and emergency assistance.
class WellnessBenefitsScreen extends ConsumerStatefulWidget {
  const WellnessBenefitsScreen({super.key});

  @override
  ConsumerState<WellnessBenefitsScreen> createState() => _WellnessBenefitsScreenState();
}

class _WellnessBenefitsScreenState extends ConsumerState<WellnessBenefitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VoiceHintsHelper.speakScreenHint(
        ref,
        hintText: 'Explore emergency helplines, safety guidelines, and welfare schemes.',
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _dialNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.wellnessTitle ?? 'Wellness & Benefits',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [
          VoiceHintSpeakerButton(
            hintText: 'Explore emergency helplines, safety guidelines, and welfare schemes.',
            color: Colors.white,
          ),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentOrange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Welfare Schemes'),
            Tab(text: 'Safety Guidelines'),
            Tab(text: 'Helplines'),
            Tab(text: 'Safety Hub'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSchemesTab(settings.language),
              _buildGuidelinesTab(),
              _buildHelplinesTab(),
              _buildSafetyShortcutsTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchemesTab(String langCode) {
    final schemesAsync = ref.watch(governmentSchemesProvider(null));

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(governmentSchemesProvider(null)),
      child: schemesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Could not load schemes: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(governmentSchemesProvider(null)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (schemes) {
          if (schemes.isEmpty) {
            return const Center(
              child: Text('No welfare schemes available at this time.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: schemes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              return _buildSchemeCard(schemes[index], langCode);
            },
          );
        },
      ),
    );
  }

  Widget _buildSchemeCard(GovernmentScheme scheme, String langCode) {
    final title = scheme.localizedName(langCode);
    final desc = scheme.localizedDescription(langCode);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_rounded, color: AppColors.headerGreenDark, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          scheme.category.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              desc,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, size: 16, color: AppColors.accentOrange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      scheme.benefitsSummary,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
            if (scheme.documentsRequired.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Required Documents:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: scheme.documentsRequired.map((doc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(doc, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.headerGreenDark,
                  side: const BorderSide(color: AppColors.cardBorderGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Official Government Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _openUrl(scheme.officialUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelinesTab() {
    final guidelines = ref.read(wellnessRepositoryProvider).getSafetyGuidelines();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: guidelines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final g = guidelines[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(g.icon, color: const Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                          Text(g.category, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(g.summary, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35)),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...g.tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.headerGreenDark, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(tip, style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.3)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelplinesTab() {
    final helplines = ref.read(wellnessRepositoryProvider).getHelplines();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: helplines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final h = helplines[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(h.icon, color: const Color(0xFFDC2626), size: 24),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(h.badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                ),
              ],
            ),
            subtitle: Text('${h.subtitle}\nDial: ${h.number}', style: const TextStyle(fontSize: 12, height: 1.3)),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              icon: const Icon(Icons.call_rounded, size: 16),
              label: Text(h.number, style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _dialNumber(h.number),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafetyShortcutsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: AppColors.headerGreenDark, size: 22),
                    SizedBox(width: 8),
                    Text('Integrated Safety Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quick access to your personal safety network, job protection insurance claims, and emergency SOS.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.contact_phone_rounded, color: AppColors.headerGreenDark),
                  title: const Text('Trusted Emergency Contacts'),
                  subtitle: const Text('Manage up to 5 family & work contacts for SOS alerts'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.emergencyContacts),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.health_and_safety_rounded, color: AppColors.headerGreenDark),
                  title: const Text('Job Protection Insurance Claim'),
                  subtitle: const Text('File verified worksite accident & injury protection claim'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.jobProtectionClaim),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: AppColors.headerGreenDark),
                  title: const Text('Safety & Protection Hub'),
                  subtitle: const Text('View full emergency checklist and live location sharing'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.safetyHub),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
