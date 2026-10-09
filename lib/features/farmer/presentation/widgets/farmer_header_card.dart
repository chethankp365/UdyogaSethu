import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/farmer/data/farmer_home_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FarmerHeaderCard extends StatelessWidget {
  final FarmerProfileDraft profile;
  final FarmerHomeStats stats;

  const FarmerHeaderCard({
    super.key,
    required this.profile,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clusterName = profile.clusterVillage.isNotEmpty
        ? '${profile.clusterVillage} Agri-Cluster'
        : 'Mandya Agri Cluster';
    final farmTitle = profile.farmName.isNotEmpty
        ? profile.farmName
        : (profile.fullName.isNotEmpty ? '${profile.fullName}\'s Farm' : 'Greenfield Organic Farm');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.headerGreenDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerGreenDark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Workspace Pill & Cluster Tag + Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Green Pulse Pill + Cluster
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF34D399), size: 9),
                        const SizedBox(width: 5),
                        Text(
                          l10n?.farmerWorkspace ?? 'FARMER WORKSPACE',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.9,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    clusterName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              // Right: Profile Avatar
              InkWell(
                onTap: () => context.push(AppRoutes.profileSetupFarmer),
                child: UserAvatar(
                  avatarPath: profile.avatarPath,
                  name: profile.fullName.isNotEmpty ? profile.fullName : farmTitle,
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Farm Name & Network Tagline
          Text(
            farmTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n?.farmerEmpoweredNetwork ?? 'Empowered by UdyogaSethu Direct Agri-Network',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Three Metrics Cards (Produce Sold, Direct Earnings, Active Labor)
          // Strictly display real values (0 is natural for new farmers - never fake data)
          Row(
            children: [
              // Metric 1: Produce Sold
              Expanded(
                child: _buildMetricBox(
                  value: '${NumberFormat('#,##0').format(stats.produceSoldKg.round())} kg',
                  label: l10n?.farmerProduceSold ?? 'PRODUCE SOLD',
                  subLabel: l10n?.farmerThisMonth ?? 'This Month',
                  valueColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              // Metric 2: Direct Earnings
              Expanded(
                child: _buildMetricBox(
                  value: '₹${NumberFormat('#,##,##0').format(stats.directEarningsRupees.round())}',
                  label: l10n?.farmerDirectEarnings ?? 'DIRECT EARNINGS',
                  subLabel: l10n?.farmerZeroMiddlemen ?? 'Zero Middlemen',
                  valueColor: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 8),
              // Metric 3: Active Labor (0 Booked until P6.3)
              Expanded(
                child: _buildMetricBox(
                  value: l10n?.farmerBooked(stats.activeLaborBookings) ?? '${stats.activeLaborBookings} Booked',
                  label: l10n?.farmerActiveLabor ?? 'ACTIVE LABOR',
                  subLabel: l10n?.farmerHarvestShiftPlaceholder ?? 'Harvest Shift (P6.3)',
                  valueColor: const Color(0xFFFDE68A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String value,
    required String label,
    required String subLabel,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: Color(0xFFD1FAE5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
