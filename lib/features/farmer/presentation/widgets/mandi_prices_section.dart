import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/features/farmer/domain/mandi_price_model.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MandiPricesSection extends StatefulWidget {
  final List<MandiPrice> prices;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const MandiPricesSection({
    super.key,
    required this.prices,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  State<MandiPricesSection> createState() => _MandiPricesSectionState();
}

class _MandiPricesSectionState extends State<MandiPricesSection> {
  CropCategoryTab _selectedTab = CropCategoryTab.allCrops;
  bool _showPerKg = true; // true = ₹/kg, false = ₹/qtl

  String _getCategoryLabel(CropCategoryTab tab, AppLocalizations? l10n) {
    switch (tab) {
      case CropCategoryTab.allCrops:
        return l10n?.farmerAllCrops ?? 'All Crops';
      case CropCategoryTab.vegetables:
        return l10n?.farmerVegetables ?? 'Vegetables';
      case CropCategoryTab.fruits:
        return 'Fruits';
      case CropCategoryTab.grainsAndPulses:
        return l10n?.farmerGrainsAndPulses ?? 'Grains & Pulses';
      case CropCategoryTab.spices:
        return 'Spices';
      case CropCategoryTab.flowers:
        return 'Flowers';
    }
  }

  String _getDemandTagText(String tag, AppLocalizations? l10n) {
    switch (tag.toLowerCase()) {
      case 'high demand':
        return l10n?.farmerHighDemand ?? 'High Demand';
      case 'stable':
        return l10n?.farmerStable ?? 'Stable';
      case 'frp guaranteed':
        return l10n?.farmerFrpGuaranteed ?? 'FRP Guaranteed';
      case 'msp protected':
        return l10n?.farmerMspProtected ?? 'MSP Protected';
      case 'oversupply':
        return l10n?.farmerOversupply ?? 'Oversupply';
      case 'moderate':
        return l10n?.farmerModerate ?? 'Moderate';
      default:
        return tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.isLoading) {
      return _buildSkeletonGrid();
    }

    final filteredPrices = widget.prices.where((p) {
      if (_selectedTab == CropCategoryTab.allCrops) return true;
      return p.category == _selectedTab;
    }).toList();

    // Determine newest arrival date
    DateTime? newestDate;
    for (final p in widget.prices) {
      if (newestDate == null || p.arrivalDate.isAfter(newestDate)) {
        newestDate = p.arrivalDate;
      }
    }

    final dateLabel = newestDate != null
        ? (l10n?.farmerUpdatedDate(DateFormat('d MMM yyyy').format(newestDate)) ??
            'Updated ${DateFormat('d MMM yyyy').format(newestDate)}')
        : (l10n?.farmerApmcKarnatakaFeed ?? 'APMC Karnataka Feed');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header with Live Feed Pulse Pill & Unit Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n?.farmerLiveMandiPrices ?? 'LIVE MANDI PRICES & DEMAND',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.9,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Live Feed Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle, color: Color(0xFF00875A), size: 7),
                            const SizedBox(width: 4),
                            Text(
                              l10n?.farmerLiveFeed ?? 'Live Feed',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00875A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Unit Switcher (₹/kg vs ₹/qtl)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUnitToggleBtn('₹/kg', _showPerKg, () {
                    setState(() => _showPerKg = true);
                  }),
                  _buildUnitToggleBtn('₹/qtl', !_showPerKg, () {
                    setState(() => _showPerKg = false);
                  }),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Crop Category Filter Chips / Rails per group (Vegetables, Fruits, Grains & Pulses, Spices, Flowers)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CropCategoryTab.values.map((tab) {
              final isSelected = tab == _selectedTab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Text(tab.emoji),
                  label: Text(_getCategoryLabel(tab, l10n)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0D6548),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF0D6548) : const Color(0xFFCBD5E1),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedTab = tab);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 3. Grid of Mandi Price Cards (Swiggy / Zomato style with 2-column grid and group rails)
        if (filteredPrices.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.storefront_outlined, size: 36, color: Color(0xFF94A3B8)),
                const SizedBox(height: 8),
                Text(
                  l10n?.farmerNoPricesInCategory ?? 'No Mandi Prices in this Category',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.farmerSelectAllCropsHint ?? 'Select All Crops to view all Karnataka APMC market prices.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredPrices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final price = filteredPrices[index];
              return _buildMandiCard(price, l10n);
            },
          ),
      ],
    );
  }

  Widget _buildUnitToggleBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0D6548) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildMandiCard(MandiPrice price, AppLocalizations? l10n) {
    final isUp = price.trendDirection == 'up';
    final isDown = price.trendDirection == 'down';
    final trendColor = isUp
        ? const Color(0xFF00875A)
        : (isDown ? const Color(0xFFDC2626) : const Color(0xFF64748B));

    final displayPrice = _showPerKg
        ? price.formattedPricePerKg
        : price.formattedModalPricePerQtl;

    final slug = price.commodity.toLowerCase().replaceAll(' ', '_');
    final assetPath = 'assets/images/commodities/$slug.webp';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Large Top Photo with Gradient & First-Letter Fallback
          SizedBox(
            height: 94,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildGradientFallback(price);
                  },
                ),
                // Top Right Change Arrow Badge
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUp)
                          const Icon(Icons.arrow_drop_up_rounded, color: Color(0xFF00875A), size: 14)
                        else if (isDown)
                          const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFDC2626), size: 14),
                        Text(
                          price.formattedChange,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Left Demand Chip in Overlay
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getDemandTagText(price.demandTag, l10n),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Card Content Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Commodity name & variety
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        price.commodity,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        price.variety,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Big Price per kg
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          displayPrice,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0D6548),
                          ),
                        ),
                      ),
                      Text(
                        _showPerKg ? price.formattedModalPricePerQtl : price.formattedPricePerKg,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Market & District location row
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${price.market}, ${price.district}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientFallback(MandiPrice price) {
    final firstLetter = price.commodity.isNotEmpty ? price.commodity[0].toUpperCase() : 'C';

    List<Color> gradientColors;
    switch (price.category) {
      case CropCategoryTab.vegetables:
        gradientColors = [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)];
        break;
      case CropCategoryTab.fruits:
        gradientColors = [const Color(0xFFFFF3E0), const Color(0xFFFFCC80)];
        break;
      case CropCategoryTab.grainsAndPulses:
        gradientColors = [const Color(0xFFFFFDE7), const Color(0xFFFFF59D)];
        break;
      case CropCategoryTab.spices:
        gradientColors = [const Color(0xFFFBE9E7), const Color(0xFFFFAB91)];
        break;
      case CropCategoryTab.flowers:
        gradientColors = [const Color(0xFFFCE4EC), const Color(0xFFF48FB1)];
        break;
      case CropCategoryTab.allCrops:
        gradientColors = [const Color(0xFFECFDF5), const Color(0xFFA7F3D0)];
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            firstLetter,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF064E3B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 180,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 94,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 80, height: 12, color: Colors.grey.shade200),
                        const SizedBox(height: 6),
                        Container(width: 50, height: 10, color: Colors.grey.shade100),
                        const SizedBox(height: 16),
                        Container(width: 60, height: 16, color: Colors.grey.shade200),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
