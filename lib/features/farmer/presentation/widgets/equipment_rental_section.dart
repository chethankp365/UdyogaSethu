import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/farmer/domain/farm_resource_model.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/book_resource_modal.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class EquipmentRentalSection extends StatelessWidget {
  final List<FarmResource> resources;
  final VoidCallback? onViewAll;
  final void Function(FarmResource res)? onBookItem;

  const EquipmentRentalSection({
    super.key,
    required this.resources,
    this.onViewAll,
    this.onBookItem,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Display up to 3 featured rental equipment items
    final featured = resources.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header matching Screen 26
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n?.farmerNearbyRentals ?? 'NEARBY EQUIPMENT & DRONE RENTALS',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_rounded, size: 12, color: Color(0xFF0D6548)),
                  const SizedBox(width: 4),
                  Text(
                    l10n?.farmerEscrowGuaranteed ?? 'Escrow Guaranteed',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6548),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of Equipment Cards
        ...featured.map((res) => _buildEquipmentCard(context, res, l10n)),

        // View All Map CTA
        const SizedBox(height: 4),
        Center(
          child: TextButton.icon(
            onPressed: onViewAll ?? () => context.push('/farmer/resources'),
            icon: const Icon(Icons.map_rounded, size: 16, color: AppColors.headerGreenDark),
            label: Text(
              l10n?.farmerViewAllEquipmentMap ?? 'View All Farm Resources & Live Map →',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.headerGreenDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    FarmResource res,
    AppLocalizations? l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipment Icon / Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: res.type.badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(res.type.icon, color: res.type.badgeColor, size: 26),
              ),
              const SizedBox(width: 12),

              // Title, Supplier and Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${res.ownerName} • ${res.distanceKmString}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                        const SizedBox(width: 2),
                        Text(
                          res.formattedRating,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        if (res.specs.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '•  ${res.specs}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Price and Book Now button row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    res.pricePerUnitDisplay,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6548),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Verified Owner ✓',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6548),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (onBookItem != null) {
                    onBookItem!(res);
                  } else {
                    BookResourceModal.show(context, resource: res);
                  }
                },
                child: Text(
                  l10n?.farmerBookNow ?? 'Book Now',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
