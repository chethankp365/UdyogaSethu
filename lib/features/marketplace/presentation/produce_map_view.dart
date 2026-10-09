import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_filters.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_marketplace_item.dart';
import 'package:udyogasethu/features/marketplace/presentation/produce_detail_screen.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/farm_traceability_modal.dart';
import 'package:udyogasethu/features/marketplace/domain/lot_traceability_data.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class ProduceMapView extends ConsumerStatefulWidget {
  final List<ProduceMarketplaceItem> items;
  final ProduceFilters filters;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onOpenFilters;

  const ProduceMapView({
    super.key,
    required this.items,
    required this.filters,
    required this.onCategorySelected,
    required this.onOpenFilters,
  });

  @override
  ConsumerState<ProduceMapView> createState() => _ProduceMapViewState();
}

class _ProduceMapViewState extends ConsumerState<ProduceMapView> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final LatLng _defaultCenter = const LatLng(12.9716, 77.5946); // Bengaluru / Mandya region

  String? _selectedItemId;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All'},
    {'id': 'vegetable', 'label': 'Organic Veggies'},
    {'id': 'dairy', 'label': 'Fresh Milk & Dairy'},
    {'id': 'fruit', 'label': 'Fruit Orchards'},
    {'id': 'grain', 'label': 'Grains & Pulses'},
    {'id': 'flower', 'label': 'Flowers'},
    {'id': 'other', 'label': 'Local Products'},
  ];

  void _onPinTapped(ProduceMarketplaceItem item) {
    setState(() => _selectedItemId = item.id);
    if (item.lat != null && item.lng != null) {
      _mapController.move(LatLng(item.lat!, item.lng!), 14.0);
    }
    _sheetController.animateTo(
      0.55,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openTraceability(ProduceMarketplaceItem item) {
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
    final displayed = widget.items;

    return Stack(
      children: [
        // 1. Interactive OpenStreetMap
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: 12.0,
            minZoom: 6,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'in.udyogasethu',
            ),
            // Price & Walk-in Store Pins
            MarkerLayer(
              markers: displayed.map((item) {
                final lat = item.lat ?? 12.9716;
                final lng = item.lng ?? 77.5946;
                final isSelected = item.id == _selectedItemId;

                return Marker(
                  point: LatLng(lat, lng),
                  width: 140,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => _onPinTapped(item),
                    child: _buildMapPin(item, isSelected),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // 2. Top Header & Category Filter Chips
        Positioned(
          top: 10,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen 29 Prototype Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6548),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n?.customerProduceMapTitle ??
                            'CUSTOMER REQUIRED FARM PRODUCE, ORGANIC SELLERS & OUTLETS NEAR ME',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${displayed.length} Live Pins',
                        style: const TextStyle(
                          color: Color(0xFF0D6548),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Horizontal Category Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((c) {
                    final isSelected = widget.filters.category == c['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        label: Text(c['label']!),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00875A),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 11.5,
                        ),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF00875A) : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (_) => widget.onCategorySelected(c['id']!),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // 3. Zoom Controls (+ / -) & Recenter Button
        Positioned(
          right: 14,
          top: 140,
          child: Column(
            children: [
              _buildMapControlBtn(
                icon: Icons.add,
                onTap: () {
                  final curr = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, curr + 1);
                },
              ),
              const SizedBox(height: 6),
              _buildMapControlBtn(
                icon: Icons.remove,
                onTap: () {
                  final curr = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, curr - 1);
                },
              ),
              const SizedBox(height: 6),
              _buildMapControlBtn(
                icon: Icons.my_location_rounded,
                onTap: () => _mapController.move(_defaultCenter, 12.0),
              ),
            ],
          ),
        ),

        // 4. Draggable Bottom Sheet with PIN LISTINGS (N)
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.35,
          minChildSize: 0.16,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                ],
              ),
              child: Column(
                children: [
                  // Handle
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sheet Header (Screen 29 Specification)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEARBY GPS PIN LISTINGS (${displayed.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Text(
                              'Tap pin or card to inspect',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.filter_list_rounded, size: 14),
                          label: const Text('Filter', style: TextStyle(fontSize: 11)),
                          onPressed: widget.onOpenFilters,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 16),

                  // Listings List
                  Expanded(
                    child: displayed.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'No farm produce found for current filters.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: displayed.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final item = displayed[idx];
                              final isSelected = item.id == _selectedItemId;
                              return _buildProduceMapCard(item, isSelected);
                            },
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

  Widget _buildMapPin(ProduceMarketplaceItem item, bool isSelected) {
    final bgColor = isSelected ? const Color(0xFFE65100) : const Color(0xFF00875A);

    // If walk-in store and not selected, show Walk-in Store badge or price
    final pinLabel = item.walkInStore
        ? 'Walk-in Store'
        : item.formattedPrice;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.walkInStore ? Icons.storefront_rounded : item.categoryIcon,
                color: Colors.white,
                size: 12,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  pinLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_drop_down_rounded,
          color: bgColor,
          size: 14,
        ),
      ],
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: const Color(0xFF334155)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildProduceMapCard(ProduceMarketplaceItem item, bool isSelected) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProduceDetailScreen(item: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00875A) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(item.categoryIcon, color: const Color(0xFF00875A), size: 24),
              ),
            ),

            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.walkInStore) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Store',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${item.farmerName} • ${item.farmName}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isVerifiedFarmer) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF00875A)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '★ ${item.farmerRatingAvg.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${item.formattedDistance}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Price & Order CTA
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.formattedPrice,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF00875A)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Traceability',
                      onPressed: () => _openTraceability(item),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00875A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(60, 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProduceDetailScreen(item: item),
                          ),
                        );
                      },
                      child: const Text(
                        'Order Now',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
