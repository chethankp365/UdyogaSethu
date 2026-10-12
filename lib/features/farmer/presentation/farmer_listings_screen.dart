import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/features/farmer/data/farmer_listings_repository.dart';
import 'package:udyogasethu/features/farmer/domain/produce_listing_model.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/edit_listing_modal.dart';
import 'package:udyogasethu/core/widgets/app_thumbnail.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FarmerListingsScreen extends ConsumerStatefulWidget {
  const FarmerListingsScreen({super.key});

  @override
  ConsumerState<FarmerListingsScreen> createState() => _FarmerListingsScreenState();
}

class _FarmerListingsScreenState extends ConsumerState<FarmerListingsScreen> {
  String _selectedFilter = 'all'; // 'all', 'active', 'low_stock', 'sold_out', 'paused'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUpdateStockDialog(ProduceListing listing, AppLocalizations? l10n) {
    final stockController = TextEditingController(
      text: listing.stockQty.toStringAsFixed(listing.stockQty.truncateToDouble() == listing.stockQty ? 0 : 1),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${l10n?.updateStock ?? 'Update Stock'}: ${listing.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current stock: ${listing.formattedStock}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Stock (${listing.unit})',
                hintText: 'Enter 0 to mark as Sold Out',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: Setting stock to 0 automatically updates status to Sold Out and hides it from buyer search.',
              style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newStock = double.tryParse(stockController.text.trim());
              if (newStock != null && newStock >= 0) {
                final repo = ref.read(farmerListingsRepositoryProvider);
                await repo.updateStock(listing.id, newStock);
                ref.invalidate(farmerListingsProvider);
                ref.invalidate(buyerProduceListingsProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stock updated to $newStock ${listing.unit}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  void _togglePauseListing(ProduceListing listing, AppLocalizations? l10n) async {
    final repo = ref.read(farmerListingsRepositoryProvider);
    final nextStatus = listing.status == ProduceStatus.paused
        ? (listing.stockQty <= 0
            ? ProduceStatus.soldOut
            : (listing.stockQty <= listing.lowStockThreshold
                ? ProduceStatus.lowStock
                : ProduceStatus.active))
        : ProduceStatus.paused;

    await repo.setStatus(listing.id, nextStatus);
    ref.invalidate(farmerListingsProvider);
    ref.invalidate(buyerProduceListingsProvider);

    if (mounted) {
      final msg = nextStatus == ProduceStatus.paused
          ? (l10n?.statusPaused ?? 'Listing paused')
          : (l10n?.statusActive ?? 'Listing active');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listingsAsync = ref.watch(farmerListingsProvider(''));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
        title: Text(
          l10n?.produceListingsTitle ?? 'Produce Listings',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time_rounded, color: Colors.white),
            tooltip: 'Delivery Slots',
            onPressed: () {
              context.push(AppRoutes.farmerDeliverySlots);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(farmerListingsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF064E3B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n?.addNewProduce ?? 'Add Produce',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => EditListingModal.show(context, farmerId: 'f-123'),
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filter Chips Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search your produce listings...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),

                const SizedBox(height: 10),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', l10n?.filterAll ?? 'All'),
                      _buildFilterChip('active', l10n?.statusActive ?? 'Active'),
                      _buildFilterChip('low_stock', l10n?.statusLowStock ?? 'Low Stock'),
                      _buildFilterChip('sold_out', l10n?.statusSoldOut ?? 'Sold Out'),
                      _buildFilterChip('paused', l10n?.statusPaused ?? 'Paused'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. Listings List
          Expanded(
            child: listingsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF064E3B)),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading listings: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(farmerListingsProvider),
                        child: Text(l10n?.retry ?? 'Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (listings) {
                // Apply filter
                final filtered = listings.where((l) {
                  if (_selectedFilter != 'all') {
                    if (l.status.dbValue != _selectedFilter) return false;
                  }
                  if (_searchQuery.isNotEmpty) {
                    if (!l.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                        !l.category.toLowerCase().contains(_searchQuery.toLowerCase())) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 14),
                          Text(
                            l10n?.noProduceAvailable ?? 'No Produce Listings Found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap the button below to add your first fresh farm produce.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF064E3B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(l10n?.addNewProduce ?? 'Add Produce'),
                            onPressed: () => EditListingModal.show(context, farmerId: 'f-123'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF064E3B),
                  onRefresh: () async {
                    ref.invalidate(farmerListingsProvider);
                  },
                  child: ListView.separated(
                    padding: AppSpacing.fabListPadding,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      return _buildListingCard(item, l10n);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
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
        onSelected: (sel) {
          setState(() => _selectedFilter = value);
        },
      ),
    );
  }

  Widget _buildListingCard(ProduceListing item, AppLocalizations? l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Produce Name, Category, Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illustrated Produce Thumbnail
              ProduceThumbnail(
                name: item.name,
                category: item.category,
                images: item.images,
                imageUrl: item.images.isNotEmpty ? item.images.first : null,
                size: ThumbnailSize.small,
                width: 52,
                height: 52,
                borderRadius: BorderRadius.circular(14),
                showTitle: false,
              ),

              const SizedBox(width: 12),

              // Title and category
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      children: [
                        Text(
                          item.category[0].toUpperCase() + item.category.substring(1),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                        Text(
                          item.farmingMethod,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.status.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _getStatusLabel(item.status, l10n),
                      style: TextStyle(
                        color: item.status.color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Price & Stock Row
          Row(
            children: [
              // Price
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELLING PRICE',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.formattedPrice,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Stock Qty
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INVENTORY STOCK',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${item.stockQty.toStringAsFixed(item.stockQty.truncateToDouble() == item.stockQty ? 0 : 1)} ${item.unit}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: item.stockQty <= 0 ? Colors.red : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (item.qualityNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Notes: ${item.qualityNotes}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Divider(height: 20),

          // Action Buttons: Quick Stock Edit, Pause/Activate, Edit Full
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Stock Edit Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF047857),
                  side: const BorderSide(color: Color(0xFF047857)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(l10n?.updateStock ?? 'Stock', style: const TextStyle(fontSize: 12)),
                onPressed: () => _showUpdateStockDialog(item, l10n),
              ),

              // Pause / Resume Toggle
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: item.status == ProduceStatus.paused ? const Color(0xFF047857) : Colors.orange.shade800,
                  side: BorderSide(
                    color: item.status == ProduceStatus.paused ? const Color(0xFF047857) : Colors.orange.shade400,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                  item.status == ProduceStatus.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 16,
                ),
                label: Text(
                  item.status == ProduceStatus.paused
                      ? (l10n?.activateListing ?? 'Activate')
                      : (l10n?.pauseListing ?? 'Pause'),
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _togglePauseListing(item, l10n),
              ),

              // Full Edit
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: Text(l10n?.edit ?? 'Edit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => EditListingModal.show(context, listing: item, farmerId: item.farmerId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(ProduceStatus status, AppLocalizations? l10n) {
    switch (status) {
      case ProduceStatus.active:
        return l10n?.statusActive ?? 'Active';
      case ProduceStatus.lowStock:
        return l10n?.statusLowStock ?? 'Low Stock';
      case ProduceStatus.soldOut:
        return l10n?.statusSoldOut ?? 'Sold Out';
      case ProduceStatus.paused:
        return l10n?.statusPaused ?? 'Paused';
    }
  }
}
