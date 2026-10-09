import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/farmer/data/farm_resources_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farm_resource_model.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/book_resource_modal.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FarmResourcesMapScreen extends ConsumerStatefulWidget {
  final FarmResourceCategoryFilter initialFilter;

  const FarmResourcesMapScreen({
    super.key,
    this.initialFilter = FarmResourceCategoryFilter.all,
  });

  @override
  ConsumerState<FarmResourcesMapScreen> createState() =>
      _FarmResourcesMapScreenState();
}

class _FarmResourcesMapScreenState extends ConsumerState<FarmResourcesMapScreen> {
  final MapController _mapController = MapController();
  final ScrollController _listScrollController = ScrollController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  late FarmResourceCategoryFilter _selectedFilter;
  String? _selectedResourceId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<FarmResource> _allResources = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const LatLng _defaultCenter = LatLng(12.9716, 77.5946); // Bengaluru / Mandya cluster
  final LatLng _center = _defaultCenter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _loadResources();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _listScrollController.dispose();
    _sheetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(farmResourcesRepositoryProvider);
      final list = await repo.getNearbyResources(
        lat: _center.latitude,
        lng: _center.longitude,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (mounted) {
        setState(() {
          _allResources = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<FarmResource> get _filteredResources {
    return _allResources.where((r) {
      if (!_selectedFilter.matches(r.type)) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final match = r.name.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.specs.toLowerCase().contains(q) ||
            r.addressText.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  void _onPinTapped(FarmResource res) {
    setState(() => _selectedResourceId = res.id);
    if (res.lat != null && res.lng != null) {
      _mapController.move(LatLng(res.lat!, res.lng!), 14.0);
    }
    _scrollToResource(res.id);
  }

  void _scrollToResource(String id) {
    final list = _filteredResources;
    final idx = list.indexWhere((r) => r.id == id);
    if (idx != -1 && _listScrollController.hasClients) {
      final target = (idx * 160.0).clamp(
        0.0,
        _listScrollController.position.maxScrollExtent,
      );
      _listScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayed = _filteredResources;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6548),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.farmerMapHeader ??
                  'FARMERS REQUIRED PRODUCTS, SEEDS, MACHINERY & SERVICES NEAR ME',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${displayed.length} Live Pins Available',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFA7F3D0)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadResources,
            tooltip: 'Refresh Pins',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Interactive OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 11.5,
              minZoom: 6,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'in.udyogasethu',
              ),
              // Price overlay pins
              MarkerLayer(
                markers: displayed.map((res) {
                  final lat = res.lat ?? 12.9716;
                  final lng = res.lng ?? 77.5946;
                  final isSelected = res.id == _selectedResourceId;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 140,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => _onPinTapped(res),
                      child: _buildMapPin(res, isSelected),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Top Category Filter Chips & Search Bar
          PositionColumnHeader(
            searchController: _searchController,
            selectedFilter: _selectedFilter,
            onFilterSelected: (f) => setState(() => _selectedFilter = f),
            onSearchChanged: (q) {
              setState(() => _searchQuery = q);
              _loadResources();
            },
          ),

          // 3. Zoom Controls (+ / -) & Recenter Button
          Positioned(
            right: 14,
            top: 130,
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
                  onTap: () {
                    _mapController.move(_defaultCenter, 12.0);
                  },
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
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
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

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'NEARBY GPS PIN LISTINGS (${displayed.length})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Tap pin or card to inspect',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),

                    // Cards List
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.headerGreenDark,
                              ),
                            )
                          : _errorMessage != null
                              ? _buildErrorState()
                              : displayed.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                  itemCount: displayed.length,
                                  itemBuilder: (context, idx) {
                                    final res = displayed[idx];
                                    final isSelected = res.id == _selectedResourceId;
                                    return _buildListingCard(res, isSelected);
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(FarmResource res, bool isSelected) {
    final bgColor = isSelected ? const Color(0xFFE65100) : const Color(0xFF00875A);

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
              Icon(res.type.icon, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  res.pricePerUnitDisplay,
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

  Widget _buildListingCard(FarmResource res, bool isSelected) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedResourceId = res.id);
        if (res.lat != null && res.lng != null) {
          _mapController.move(LatLng(res.lat!, res.lng!), 14.0);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D6548).withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D6548) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
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
                // Icon avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: res.type.badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(res.type.icon, color: res.type.badgeColor, size: 26),
                ),
                const SizedBox(width: 12),

                // Name and supplier
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${res.addressText} • ${res.distanceKmString}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF59E0B), size: 15),
                          const SizedBox(width: 2),
                          Text(
                            res.formattedRating,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          if (res.specs.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${res.specs}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
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

            // Price and Book Item CTA
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  res.pricePerUnitDisplay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6548),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    BookResourceModal.show(
                      context,
                      resource: res,
                      onBookingConfirmed: (b) {
                        _loadResources();
                      },
                    );
                  },
                  child: Text(
                    l10n?.farmerBookItem ?? 'Book Item',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
          const SizedBox(height: 8),
          const Text(
            'Failed to Load Farm Resources',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _errorMessage ?? 'Network or connection error.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerGreenDark,
              foregroundColor: Colors.white,
            ),
            onPressed: _loadResources,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          const Text(
            'No Farm Resources Found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try changing category filter or expanding search area.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedFilter = FarmResourceCategoryFilter.all;
                _searchQuery = '';
                _searchController.clear();
              });
              _loadResources();
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}

class PositionColumnHeader extends StatelessWidget {
  final TextEditingController searchController;
  final FarmResourceCategoryFilter selectedFilter;
  final ValueChanged<FarmResourceCategoryFilter> onFilterSelected;
  final ValueChanged<String> onSearchChanged;

  const PositionColumnHeader({
    super.key,
    required this.searchController,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 12,
      right: 12,
      child: Column(
        children: [
          // Search Input Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search machinery, seeds, drones...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D6548)),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Category Filter Chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', FarmResourceCategoryFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Tractors & Implements',
                  FarmResourceCategoryFilter.tractorsAndImplements,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Seeds & Bio-Fertilizers',
                  FarmResourceCategoryFilter.seedsAndBioFertilizers,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Cold Storage',
                  FarmResourceCategoryFilter.coldStorage,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Drones & Spraying',
                  FarmResourceCategoryFilter.dronesAndSpraying,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, FarmResourceCategoryFilter filter) {
    final isSelected = selectedFilter == filter;

    return InkWell(
      onTap: () => onFilterSelected(filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D6548) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D6548) : const Color(0xFFCBD5E1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }
}
