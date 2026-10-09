import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/farmer/domain/produce_listing_model.dart';
import 'package:udyogasethu/features/marketplace/data/orders_repository.dart';
import 'package:udyogasethu/features/marketplace/data/produce_marketplace_repository.dart';
import 'package:udyogasethu/features/marketplace/domain/lot_traceability_data.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_filters.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_marketplace_item.dart';
import 'package:udyogasethu/features/marketplace/presentation/produce_detail_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/produce_map_view.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/farm_traceability_modal.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/produce_filter_sheet.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class BuyerProduceTab extends ConsumerStatefulWidget {
  const BuyerProduceTab({super.key});

  @override
  ConsumerState<BuyerProduceTab> createState() => _BuyerProduceTabState();
}

class _BuyerProduceTabState extends ConsumerState<BuyerProduceTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProduceFilters _filters = const ProduceFilters();
  bool _isMapView = false;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Produce'},
    {'id': 'vegetable', 'label': 'Organic Veggies'},
    {'id': 'dairy', 'label': 'Fresh Milk & Dairy'},
    {'id': 'fruit', 'label': 'Fruit Orchards'},
    {'id': 'grain', 'label': 'Grains & Pulses'},
    {'id': 'flower', 'label': 'Flowers'},
    {'id': 'other', 'label': 'Local Products'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOrderBottomSheet(BuildContext context, ProduceMarketplaceItem item, AppLocalizations? l10n) {
    double orderQty = 5.0;
    if (orderQty > item.stockQty) orderQty = item.stockQty;
    if (orderQty < 1.0 && item.stockQty > 0) orderQty = item.stockQty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final totalRupees = orderQty * item.priceRupees;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Demo mode',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),

                Text(
                  'Order ${item.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'From ${item.farmerName} • ${item.farmName}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),

                const Divider(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Unit Price: ${item.formattedPrice}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Available: ${item.formattedStock}', style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 16),

                // Quantity selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF047857)),
                          onPressed: orderQty > 1
                              ? () => setModalState(() => orderQty -= 1)
                              : null,
                        ),
                        Text(
                          '${orderQty.toStringAsFixed(0)} ${item.unit}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF047857)),
                          onPressed: orderQty < item.stockQty
                              ? () => setModalState(() => orderQty += 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Order Summary Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Estimated Amount:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        '₹${NumberFormat('#,##0').format(totalRupees.round())}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF064E3B)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF064E3B)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ref.read(cartNotifierProvider.notifier).addItem(item, quantity: orderQty);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${orderQty.toStringAsFixed(0)} ${item.unit} ${item.name} ${l10n?.addedToCart ?? 'added to cart!'}',
                              ),
                              action: SnackBarAction(
                                label: l10n?.viewCart ?? 'View Cart',
                                textColor: Colors.white,
                                onPressed: () => context.push(AppRoutes.cart),
                              ),
                              backgroundColor: const Color(0xFF064E3B),
                            ),
                          );
                        },
                        child: Text(
                          l10n?.cartTitle ?? 'Add to Cart',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF064E3B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ref.read(cartNotifierProvider.notifier).addItem(item, quantity: orderQty);
                          context.push(AppRoutes.orderCheckout);
                        },
                        child: Text(
                          l10n?.proceedToCheckout ?? 'Checkout Direct',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openTraceabilityModal(ProduceMarketplaceItem item) {
    final trace = LotTraceabilityData(
      listingId: item.id,
      lotNumber: item.lotNumber,
      cropItem: item.name,
      category: item.category,
      farmerOrigin: '${item.farmName} • ${item.clusterVillage}',
      clusterVillage: item.clusterVillage,
      harvestTime: item.freshnessLabel,
      harvestAt: item.harvestAt,
      farmingMethod: item.farmingMethod,
      organicCertification: item.organicCertified
          ? (item.certificationName.isNotEmpty ? item.certificationName : 'Pesticide-Free ✓')
          : 'Natural IPNM Verified ✓',
      qualityNotes: item.qualityNotes,
      pricePaise: item.pricePaise,
      unit: item.unit,
      ratingAvg: item.farmerRatingAvg,
      images: item.images,
    );
    FarmTraceabilityModal.show(context, trace);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final produceAsync = ref.watch(
      produceMarketplaceListingsProvider((
        filters: _filters,
        searchQuery: _searchQuery,
        userLat: 12.9716,
        userLng: 77.5946,
      )),
    );

    return Column(
      children: [
        // Top Search, Filter and View Toggle Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  // 1. Search Bar
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n?.buyerSearchProduceHint ?? 'Search fresh farm produce (e.g. Tomato, Rice)...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF047857), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 2. Filter Button
                  InkWell(
                    onTap: () {
                      ProduceFilterSheet.show(
                        context,
                        currentFilters: _filters,
                        onApply: (newFilters) {
                          setState(() => _filters = newFilters);
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _filters.hasActiveCustomFilters ? const Color(0xFFECFDF5) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _filters.hasActiveCustomFilters ? const Color(0xFF047857) : Colors.grey.shade300,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: _filters.hasActiveCustomFilters ? const Color(0xFF047857) : const Color(0xFF475569),
                            size: 20,
                          ),
                          if (_filters.hasActiveCustomFilters)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF047857),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 3. List / Map View Toggle
                  InkWell(
                    onTap: () => setState(() => _isMapView = !_isMapView),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isMapView ? const Color(0xFF0D6548) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isMapView ? const Color(0xFF0D6548) : Colors.grey.shade300,
                        ),
                      ),
                      child: Icon(
                        _isMapView ? Icons.view_list_rounded : Icons.map_rounded,
                        color: _isMapView ? Colors.white : const Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 4. Shopping Cart Button
                  InkWell(
                    onTap: () => context.push(AppRoutes.cart),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0D6548), size: 20),
                          Consumer(
                            builder: (ctx, ref, _) {
                              final cart = ref.watch(cartNotifierProvider);
                              if (cart.isEmpty) return const SizedBox.shrink();
                              return Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${cart.totalQuantity}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Horizontal Category Chips Row (Shown in List View)
              if (!_isMapView) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((c) {
                      final isSelected = _filters.category == c['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(c['label']!),
                          selected: isSelected,
                          selectedColor: const Color(0xFFECFDF5),
                          checkmarkColor: const Color(0xFF047857),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF047857) : const Color(0xFF475569),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF047857) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _filters = _filters.copyWith(category: c['id']!);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Main View: Map View vs List View
        Expanded(
          child: produceAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF064E3B)),
            ),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 44, color: Colors.red),
                  const SizedBox(height: 10),
                  Text('Failed to load produce: $err'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(produceMarketplaceListingsProvider),
                    child: Text(l10n?.retry ?? 'Retry'),
                  ),
                ],
              ),
            ),
            data: (listings) {
              if (_isMapView) {
                return ProduceMapView(
                  items: listings,
                  filters: _filters,
                  onCategorySelected: (cat) => setState(() => _filters = _filters.copyWith(category: cat)),
                  onOpenFilters: () {
                    ProduceFilterSheet.show(
                      context,
                      currentFilters: _filters,
                      onApply: (newFilters) => setState(() => _filters = newFilters),
                    );
                  },
                );
              }

              if (listings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grass_outlined, size: 54, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          l10n?.noProduceAvailable ?? 'No Produce Found',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try clearing filters or widening your distance.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filters = const ProduceFilters();
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: listings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final item = listings[idx];
                  return _buildBuyerProduceCard(item, l10n);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerProduceCard(ProduceMarketplaceItem item, AppLocalizations? l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category Icon, Title, Farming Method Badge
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProduceDetailScreen(item: item),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(item.categoryIcon, color: const Color(0xFF00875A), size: 26),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.farmingMethod,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857),
                            ),
                          ),
                          const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                          Text(
                            item.freshnessLabel,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.formattedPrice,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF064E3B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Farmer Info Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_pin_rounded, color: Color(0xFF047857), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${item.farmerName} • ${item.farmName}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isVerifiedFarmer) ...[
                            const SizedBox(width: 4),
                            const Text('✓', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '★ ${item.farmerRatingAvg.toStringAsFixed(1)} • ${item.formattedDistance}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stock and Direct Order Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.status == ProduceStatus.lowStock ? Colors.amber : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.formattedStock,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: item.status == ProduceStatus.lowStock ? Colors.amber.shade900 : const Color(0xFF047857),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Traceability button
                  IconButton(
                    icon: const Icon(Icons.verified_outlined, size: 20, color: Color(0xFF00875A)),
                    tooltip: 'Traceability',
                    onPressed: () => _openTraceabilityModal(item),
                  ),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF064E3B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: Text(l10n?.orderDirect ?? 'Order Direct', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showOrderBottomSheet(context, item, l10n),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
