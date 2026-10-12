// Screen: SafetyHubScreen (Step P7.3)
// Comprehensive Safety Hub featuring emergency numbers, guidelines, insurance info, scheme cards, and shortcuts

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/features/safety/presentation/widgets/sos_confirmation_dialog.dart';

class SafetyHubScreen extends ConsumerWidget {
  const SafetyHubScreen({super.key});

  Future<void> _dialNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Safety & Protection Hub'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => SosConfirmationDialog.show(context),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Hero Banner
          _buildHeroBanner(context),
          const SizedBox(height: AppSpacing.lg),

          // Quick Action Cards Row
          _buildQuickActions(context),
          const SizedBox(height: AppSpacing.lg),

          // Emergency Helplines Section
          _buildSectionHeader('Emergency Helplines (Tap to Call)', Icons.phone_in_talk),
          const SizedBox(height: AppSpacing.sm),
          _buildHelplinesGrid(),
          const SizedBox(height: AppSpacing.lg),

          // Accident & Work Safety Guidelines
          _buildSectionHeader('Accident & Site Safety Guidelines', Icons.health_and_safety_outlined),
          const SizedBox(height: AppSpacing.sm),
          _buildSafetyGuidelines(),
          const SizedBox(height: AppSpacing.lg),

          // Insurance & Protection Awareness
          _buildSectionHeader('Insurance & Worker Rights', Icons.verified_user_outlined),
          const SizedBox(height: AppSpacing.sm),
          _buildInsuranceAwareness(context),
          const SizedBox(height: AppSpacing.lg),

          // Welfare Schemes & NGO Support
          _buildSectionHeader('Government & Welfare Schemes', Icons.account_balance_outlined),
          const SizedBox(height: AppSpacing.sm),
          _buildWelfareSchemes(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D6548), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6548).withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Zero Compromise Safety',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'UdyogaSethu protects every assignment with Escrow guarantee, live location monitoring, emergency escalation and accident cover.',
            style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => SosConfirmationDialog.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Trigger Emergency SOS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context,
                icon: Icons.contact_emergency_outlined,
                title: 'Emergency Contacts',
                subtitle: 'Add up to 5',
                color: const Color(0xFF2563EB),
                onTap: () => context.push(AppRoutes.emergencyContacts),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildActionTile(
                context,
                icon: Icons.assignment_turned_in_outlined,
                title: 'Protection Claim',
                subtitle: 'Apply for cover',
                color: const Color(0xFF059669),
                onTap: () => context.push(AppRoutes.jobProtectionClaim),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () => context.push(AppRoutes.wellness),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.health_and_safety_rounded, color: AppColors.headerGreenDark, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wellness & Benefits Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.headerGreenDark)),
                      Text('Explore social welfare schemes, PMSBY, PM-JAY & safety protocols', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.headerGreenDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildHelplinesGrid() {
    final numbers = [
      {'label': 'National Emergency', 'number': '112', 'color': 0xFFDC2626},
      {'label': 'Ambulance / Medical', 'number': '108', 'color': 0xFFEA580C},
      {'label': 'Women Helpline', 'number': '1091', 'color': 0xFF7C3AED},
      {'label': 'Disaster Helpline', 'number': '1077', 'color': 0xFF0284C7},
      {'label': 'Women in Distress', 'number': '181', 'color': 0xFFDB2777},
      {'label': 'Udyoga Safety Desk', 'number': '1800-419-8200', 'color': 0xFF0D6548},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 340
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.sm) / 2;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: numbers.map((n) {
            return InkWell(
              onTap: () => _dialNumber(n['number'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n['label'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              n['number'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(n['color'] as int),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.call, size: 16, color: Color(n['color'] as int)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSafetyGuidelines() {
    final guides = [
      {
        'title': 'Site Gear & Footwear',
        'desc': 'Always wear enclosed shoes or boots. Use gloves and dust masks for construction or chemical spraying.',
        'icon': Icons.security,
      },
      {
        'title': 'Hydration & Heat Stress',
        'desc': 'Drink water every 45 minutes when doing outdoor farm/construction labour. Rest in shade during peak afternoon.',
        'icon': Icons.water_drop_outlined,
      },
      {
        'title': 'Electrical & Machine Precautions',
        'desc': 'Ensure switches are turned off before inspecting farm pumps or power tools. Avoid working with wet hands.',
        'icon': Icons.bolt,
      },
      {
        'title': 'Night Travel & Escrow Communication',
        'desc': 'Do not share personal telephone numbers or travel unverified routes. Use Udyoga Protected Chat.',
        'icon': Icons.nightlight_outlined,
      },
    ];

    return Column(
      children: guides.map((g) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(g['icon'] as IconData, color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      g['desc'] as String,
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsuranceAwareness(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pradhan Mantri Suraksha Bima Yojana (PMSBY)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Accident insurance cover of ₹2 Lakhs for accidental death/disability at only ₹20 per year through your linked bank account.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Udyoga Escrow Protection (Demo Mode)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Every verified booking automatically covers on-site accidental injury up to ₹25,000 when QR attendance and selfie gates are verified.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => context.push(AppRoutes.jobProtectionClaim),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryGreen),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inspect Claim Eligibility & File Claim',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelfareSchemes() {
    final schemes = [
      {
        'title': 'e-Shram Portal (National Database of Unorganised Workers)',
        'desc': 'Provides universal 12-digit UAN card and social security scheme access for gig and unorganised workers.',
      },
      {
        'title': 'KBOCW Karnataka Construction Workers Welfare',
        'desc': 'Free toolkits, accident assistance, and education scholarships for registered building & construction labourers.',
      },
      {
        'title': 'PM-KISAN Samman Nidhi',
        'desc': 'Direct income support of ₹6,000 per year in three 4-monthly instalments to eligible farmer families.',
      },
    ];

    return Column(
      children: schemes.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                s['desc']!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
