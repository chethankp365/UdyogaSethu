import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/matching/data/recommendation_pricing_service.dart';
import 'package:udyogasethu/features/matching/domain/customer_recommendation.dart';

/// Reusable Customer Recommendations Section displaying repeat bookings, bundles, and seasonal products.
class CustomerRecommendationsSection extends ConsumerWidget {
  final String? categoryFilter;

  const CustomerRecommendationsSection({super.key, this.categoryFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(recommendationPricingServiceProvider);
    final recommendations = service.getCustomerRecommendations(categoryFilter: categoryFilter);

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final workerListHeight = (165 * textScale.clamp(1.0, 1.8)).toDouble();
    final bundleListHeight = (180 * textScale.clamp(1.0, 1.8)).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Recommended Workers & Repeat Bookings
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text(
                'RECOMMENDED WORKERS',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Rule-based',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: workerListHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.workers.length,
            separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
            itemBuilder: (ctx, index) {
              final worker = recommendations.workers[index];
              return _buildWorkerCard(context, worker);
            },
          ),
        ),

        const SizedBox(height: 20),

        // Section 2: Farm Produce Bundles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text(
                'CURATED FARM BUNDLES',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Direct Farm-Fresh',
                style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: bundleListHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.bundles.length,
            separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
            itemBuilder: (ctx, index) {
              final bundle = recommendations.bundles[index];
              return _buildBundleCard(context, bundle);
            },
          ),
        ),

        const SizedBox(height: 20),

        // Section 3: Seasonal Products
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'SEASONAL HARVEST HIGHLIGHTS',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 10),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: recommendations.seasonalProduce.length,
          separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
          itemBuilder: (ctx, index) {
            final item = recommendations.seasonalProduce[index];
            return _buildSeasonalRow(context, item);
          },
        ),
      ],
    );
  }

  Widget _buildWorkerCard(BuildContext context, RecommendedWorker worker) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cardWidth = (210 * textScale.clamp(1.0, 1.4)).toDouble();

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.paleMint,
                child: Text(
                  worker.name[0],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      worker.categoryName,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (worker.isRepeatBooking) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Rebook', style: TextStyle(fontSize: 9.5, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  '${worker.rating} • ${worker.distanceKm} km',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            worker.reason,
            style: const TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₹${worker.dailyWageRupees}/day',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => context.push('/provider/workers'),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Book', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBundleCard(BuildContext context, RecommendedBundle bundle) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cardWidth = (240 * textScale.clamp(1.0, 1.4)).toDouble();

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.paleMint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bundle.tag,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${bundle.discountPercent}% OFF',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bundle.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            bundle.items.join(' • '),
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${bundle.bundlePriceRupees}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${bundle.originalPriceRupees}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => context.push('/marketplace'),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalRow(BuildContext context, SeasonalProduceItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.paleMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.headerGreenDark, size: 22),
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
                  runSpacing: 2,
                  children: [
                    Text(
                      item.commodity,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${item.priceRupees}/${item.unit}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.seasonDescription} • ${item.farmerName}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
