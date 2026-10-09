import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/farmer/data/farmer_listings_repository.dart';
import 'package:udyogasethu/features/farmer/domain/produce_listing_model.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class BuyerProduceTab extends ConsumerStatefulWidget {
  const BuyerProduceTab({super.key});

  @override
  ConsumerState<BuyerProduceTab> createState() => _BuyerProduceTabState();
}

class _BuyerProduceTabState extends ConsumerState<BuyerProduceTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Produce'},
    {'id': 'vegetable', 'label': 'Vegetables'},
    {'id': 'fruit', 'label': 'Fruits'},
    {'id': 'grain', 'label': 'Grains'},
    {'id': 'pulse', 'label': 'Pulses'},
    {'id': 'spices', 'label': 'Spices'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOrderBottomSheet(BuildContext context, ProduceListing item, AppLocalizations? l10n) {
    double orderQty = 10.0;
    if (orderQty > item.stockQty) orderQty = item.stockQty;

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

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064E3B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Direct order for ${orderQty.toStringAsFixed(0)} ${item.unit} sent to ${item.farmerName}! (Demo mode)',
                        ),
                        backgroundColor: const Color(0xFF064E3B),
                      ),
                    );
                  },
                  child: const Text('Confirm Produce Request (Demo mode)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final produceAsync = ref.watch(buyerProduceListingsProvider(_searchQuery.isNotEmpty ? _searchQuery : null));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n?.buyerSearchProduceHint ?? 'Search fresh farm produce (e.g. Tomato, Rice)...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF047857)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

          const SizedBox(height: 12),

          // 2. Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c['id'];
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
                    onSelected: (_) => setState(() => _selectedCategory = c['id']!),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Listings Grid / List
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
                      onPressed: () => ref.invalidate(buyerProduceListingsProvider),
                      child: Text(l10n?.retry ?? 'Retry'),
                    ),
                  ],
                ),
              ),
              data: (listings) {
                // Filter by category if not 'all'
                final filtered = listings.where((l) {
                  if (_selectedCategory != 'all' && l.category != _selectedCategory) {
                    return false;
                  }
                  // Strict invariant: only show active/lowStock and stockQty > 0
                  return l.isActiveAndInStock;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.grass_outlined, size: 54, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.noProduceAvailable ?? 'No Produce In Stock',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Produce listings appear only when active and in stock.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final item = filtered[idx];
                    return _buildBuyerProduceCard(item, l10n);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerProduceCard(ProduceListing item, AppLocalizations? l10n) {
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
          // Row 1: Sprout Icon, Title, Farming Method Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🌾', style: TextStyle(fontSize: 24)),
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
                          item.availabilityMode.label,
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
                  child: Text(
                    '${item.farmerName} • ${item.farmName} (${item.clusterVillage})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.isVerifiedFarmer)
                  const Text('✓', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 13)),
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
    );
  }
}
