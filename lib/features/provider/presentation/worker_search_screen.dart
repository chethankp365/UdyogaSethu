import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/provider/domain/nearby_worker.dart';
import 'package:udyogasethu/features/provider/domain/worker_filter_criteria.dart';
import 'package:udyogasethu/features/provider/presentation/worker_search_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class WorkerSearchScreen extends ConsumerStatefulWidget {
  const WorkerSearchScreen({super.key});

  @override
  ConsumerState<WorkerSearchScreen> createState() => _WorkerSearchScreenState();
}

class _WorkerSearchScreenState extends ConsumerState<WorkerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  NearbyWorker? _selectedMapWorker;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final criteria = ref.watch(workerFilterNotifierProvider);
    final workersAsync = ref.watch(filteredWorkersProvider);
    final categoriesAsync = ref.watch(workerSearchCategoriesProvider);
    final location = ref.watch(providerLocationProvider);
    final userLat = location['lat'] ?? 12.9352;
    final userLng = location['lng'] ?? 77.6245;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.hubSearchWorkers,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: criteria.isMapMode ? l10n.workerSearchToggleList : l10n.workerSearchToggleMap,
            icon: Icon(criteria.isMapMode ? Icons.view_list_rounded : Icons.map_rounded),
            onPressed: () => ref.read(workerFilterNotifierProvider.notifier).toggleMapMode(),
          ),
          IconButton(
            tooltip: l10n.workerFilterTitle,
            icon: Badge(
              isLabelVisible: criteria.activeFilterCount > 0,
              label: Text('${criteria.activeFilterCount}'),
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: () => _openFilterSheet(context, criteria, categoriesAsync.asData?.value ?? []),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Quick Filter Bar
          _buildSearchAndChipsBar(l10n, criteria, categoriesAsync.asData?.value ?? []),

          // Content: List or Map View
          Expanded(
            child: workersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading workers: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(filteredWorkersProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (workers) {
                if (workers.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                if (criteria.isMapMode) {
                  return _buildMapView(workers, userLat, userLng, criteria);
                }

                return _buildListView(workers, l10n);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndChipsBar(
    AppLocalizations l10n,
    WorkerFilterCriteria criteria,
    List<ServiceCategoryItem> categories,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.hubSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.headerGreenDark),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(workerFilterNotifierProvider.notifier).setSearchQuery(null);
                            },
                          )
                        : const Icon(Icons.mic_rounded, color: AppColors.amberOrange),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    ref.read(workerFilterNotifierProvider.notifier).setSearchQuery(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Filter Button
              InkWell(
                onTap: () => _openFilterSheet(context, criteria, categories),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: criteria.activeFilterCount > 0 ? AppColors.paleMint : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: criteria.activeFilterCount > 0 ? AppColors.headerGreenDark : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: criteria.activeFilterCount > 0 ? AppColors.headerGreenDark : Colors.grey.shade700,
                      ),
                      if (criteria.activeFilterCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${criteria.activeFilterCount}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Horizontal Quick Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Verified Only Toggle Chip
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: criteria.verifiedOnly ? Colors.white : AppColors.headerGreenDark,
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.workerFilterVerifiedOnly),
                    ],
                  ),
                  selected: criteria.verifiedOnly,
                  selectedColor: AppColors.headerGreenDark,
                  labelStyle: TextStyle(
                    color: criteria.verifiedOnly ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    ref.read(workerFilterNotifierProvider.notifier).setVerifiedOnly(val);
                  },
                ),

                const SizedBox(width: 8),

                // Distance Chip
                ActionChip(
                  avatar: const Icon(Icons.near_me_rounded, size: 16, color: AppColors.headerGreenDark),
                  label: Text('${criteria.radiusKm.round()} km'),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  onPressed: () => _openDistanceDialog(context, criteria),
                ),

                const SizedBox(width: 8),

                // Language Chip
                ActionChip(
                  avatar: const Icon(Icons.translate_rounded, size: 16, color: AppColors.headerGreenDark),
                  label: Text(
                    criteria.language == null || criteria.language == 'all'
                        ? l10n.workerFilterAllLanguages
                        : criteria.language!.toUpperCase(),
                  ),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  onPressed: () => _openLanguageDialog(context, criteria),
                ),

                const SizedBox(width: 8),

                // Category Chips
                ...categories.map((cat) {
                  final isSelected = criteria.categoryId == cat.id;
                  final name = cat.getLocalizedName(Localizations.localeOf(context).languageCode);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(name),
                      selected: isSelected,
                      selectedColor: AppColors.cardBorderGreen,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
                      ),
                      onSelected: (val) {
                        ref.read(workerFilterNotifierProvider.notifier).setCategory(
                              val ? cat.id : null,
                              val ? name : null,
                            );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<NearbyWorker> workers, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count summary
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l10n.workerSearchResultsCount(workers.length),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final worker = workers[index];
              return _WorkerCard(
                worker: worker,
                onTap: () => _navigateToWorkerProfile(worker),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapView(
    List<NearbyWorker> workers,
    double userLat,
    double userLng,
    WorkerFilterCriteria criteria,
  ) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(userLat, userLng),
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'in.udyogasethu',
            ),

            // User Geofence Circle
            CircleLayer(
              circles: [
                CircleMarker(
                  point: LatLng(userLat, userLng),
                  color: AppColors.headerGreenDark.withValues(alpha: 0.1),
                  borderColor: AppColors.headerGreenDark,
                  borderStrokeWidth: 1.5,
                  radius: (criteria.radiusKm * 1000) / 10,
                ),
              ],
            ),

            // Worker Pins
            MarkerLayer(
              markers: [
                // User Location Marker
                Marker(
                  point: LatLng(userLat, userLng),
                  width: 36,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                  ),
                ),

                // Worker Markers
                ...workers.map((worker) {
                  final lat = worker.lat ?? userLat;
                  final lng = worker.lng ?? userLng;
                  final isSelected = _selectedMapWorker?.userId == worker.userId;
                  final pinColor = worker.isVerifiedBadge ? AppColors.headerGreenDark : AppColors.amberOrange;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 70,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMapWorker = worker;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : pinColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              worker.formattedRate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.location_on_rounded,
                            size: 24,
                            color: isSelected ? Colors.black : pinColor,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Selected Worker Bottom Popup on Map
        if (_selectedMapWorker != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        UserAvatar(
                          avatarPath: _selectedMapWorker!.avatarPath,
                          name: _selectedMapWorker!.fullName,
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _selectedMapWorker!.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (_selectedMapWorker!.isVerifiedBadge)
                                    const Icon(Icons.verified_rounded, size: 16, color: AppColors.headerGreenDark)
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Unverified', style: TextStyle(fontSize: 10, color: Colors.brown)),
                                    ),
                                ],
                              ),
                              Text(
                                _selectedMapWorker!.headline,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppColors.amberOrange),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${_selectedMapWorker!.ratingAvg.toStringAsFixed(1)} • ${_selectedMapWorker!.formattedDistance}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() => _selectedMapWorker = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.headerGreenDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _navigateToWorkerProfile(_selectedMapWorker!),
                        child: const Text('View Profile & Book', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.workerSearchNoResults,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.workerSearchNoResultsDesc,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.workerFilterReset),
              onPressed: () {
                _searchController.clear();
                ref.read(workerFilterNotifierProvider.notifier).resetFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToWorkerProfile(NearbyWorker worker) {
    ref.read(recentlyViewedWorkersProvider.notifier).addWorker(worker);
    context.push('/provider/workers/${worker.userId}');
  }

  void _openDistanceDialog(BuildContext context, WorkerFilterCriteria criteria) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Maximum Distance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Search Radius:'),
                      Text('${criteria.radiusKm.round()} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.headerGreenDark)),
                    ],
                  ),
                  Slider(
                    value: criteria.radiusKm,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    activeColor: AppColors.headerGreenDark,
                    label: '${criteria.radiusKm.round()} km',
                    onChanged: (val) {
                      ref.read(workerFilterNotifierProvider.notifier).setRadiusKm(val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerGreenDark, foregroundColor: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openLanguageDialog(BuildContext context, WorkerFilterCriteria criteria) {
    final languages = [
      {'code': 'all', 'label': 'All Languages'},
      {'code': 'kn', 'label': 'ಕನ್ನಡ (Kannada)'},
      {'code': 'en', 'label': 'English'},
      {'code': 'hi', 'label': 'हिंदी (Hindi)'},
      {'code': 'te', 'label': 'తెలుగు (Telugu)'},
      {'code': 'ta', 'label': 'தமிழ் (Tamil)'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Spoken Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...languages.map((l) {
                final isSelected = (criteria.language ?? 'all') == l['code'];
                return ListTile(
                  title: Text(l['label']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.headerGreenDark) : null,
                  onTap: () {
                    ref.read(workerFilterNotifierProvider.notifier).setLanguage(l['code'] == 'all' ? null : l['code']);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _openFilterSheet(
    BuildContext context,
    WorkerFilterCriteria criteria,
    List<ServiceCategoryItem> categories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return _WorkerFilterBottomSheet(
              criteria: criteria,
              categories: categories,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final NearbyWorker worker;
  final VoidCallback onTap;

  const _WorkerCard({
    required this.worker,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar, Name, Verification Badge, Rate
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    avatarPath: worker.avatarPath,
                    name: worker.fullName,
                    radius: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                worker.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (worker.isVerifiedBadge)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.paleMint,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.cardBorderGreen),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 12, color: AppColors.headerGreenDark),
                                    SizedBox(width: 3),
                                    Text(
                                      'Verified ✓',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.headerGreenDark,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Text(
                                  l10n.workerUnverifiedNotice,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          worker.headline,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Price Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.paleMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      worker.formattedRate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.headerGreenDark,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Middle Row: Rating, Completed Jobs, Distance
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.amberOrange),
                  const SizedBox(width: 4),
                  Text(
                    worker.ratingAvg > 0 ? worker.ratingAvg.toStringAsFixed(1) : '4.8',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    ' (${worker.ratingCount > 0 ? worker.ratingCount : 12})',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.work_history_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${worker.jobsCompleted} jobs',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    worker.formattedDistance,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              if (worker.skills.isNotEmpty || worker.languages.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...worker.languages.take(2).map((lang) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lang.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                          ),
                        )),
                    ...worker.skills.take(2).map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.name,
                            style: const TextStyle(fontSize: 10, color: AppColors.textDark),
                          ),
                        )),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.headerGreenDark,
                        side: const BorderSide(color: AppColors.headerGreenDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: onTap,
                      child: Text(l10n.applicantActionProfile, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.headerGreenDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: onTap,
                      child: Text(l10n.hubBookWorker, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkerFilterBottomSheet extends ConsumerStatefulWidget {
  final WorkerFilterCriteria criteria;
  final List<ServiceCategoryItem> categories;
  final ScrollController scrollController;

  const _WorkerFilterBottomSheet({
    required this.criteria,
    required this.categories,
    required this.scrollController,
  });

  @override
  ConsumerState<_WorkerFilterBottomSheet> createState() => _WorkerFilterBottomSheetState();
}

class _WorkerFilterBottomSheetState extends ConsumerState<_WorkerFilterBottomSheet> {
  late String? _selectedCat;
  late double _radiusKm;
  late String? _language;
  late String? _availability;
  late int? _minRate;
  late int? _maxRate;
  late String? _gender;
  late double? _minRating;
  late int? _minJobs;
  late bool _verifiedOnly;

  @override
  void initState() {
    super.initState();
    _selectedCat = widget.criteria.categoryId;
    _radiusKm = widget.criteria.radiusKm;
    _language = widget.criteria.language;
    _availability = widget.criteria.availability;
    _minRate = widget.criteria.minRatePaise;
    _maxRate = widget.criteria.maxRatePaise;
    _gender = widget.criteria.genderPreference;
    _minRating = widget.criteria.minRating;
    _minJobs = widget.criteria.minJobsCompleted;
    _verifiedOnly = widget.criteria.verifiedOnly;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.workerFilterTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCat = null;
                    _radiusKm = 10.0;
                    _language = null;
                    _availability = null;
                    _minRate = null;
                    _maxRate = null;
                    _gender = null;
                    _minRating = null;
                    _minJobs = null;
                    _verifiedOnly = false;
                  });
                },
                child: Text(l10n.workerFilterReset, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),

          const Divider(),

          // 1. Verified Only Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.workerFilterVerifiedOnly, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Hide workers without Aadhaar/KYC badge', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            activeThumbColor: AppColors.headerGreenDark,
            value: _verifiedOnly,
            onChanged: (val) => setState(() => _verifiedOnly = val),
          ),

          const SizedBox(height: 12),

          // 2. Service Category
          Text(l10n.workerFilterCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.workerFilterAllCategories),
                selected: _selectedCat == null,
                selectedColor: AppColors.cardBorderGreen,
                onSelected: (val) => setState(() => _selectedCat = null),
              ),
              ...widget.categories.map((c) {
                final isSelected = _selectedCat == c.id;
                return ChoiceChip(
                  label: Text(c.getLocalizedName(Localizations.localeOf(context).languageCode)),
                  selected: isSelected,
                  selectedColor: AppColors.cardBorderGreen,
                  onSelected: (val) => setState(() => _selectedCat = val ? c.id : null),
                );
              }),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Distance Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.workerFilterDistance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${_radiusKm.round()} km', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
            ],
          ),
          Slider(
            value: _radiusKm,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            activeColor: AppColors.headerGreenDark,
            label: '${_radiusKm.round()} km',
            onChanged: (val) => setState(() => _radiusKm = val),
          ),

          const SizedBox(height: 16),

          // 4. Language Spoken
          Text(l10n.workerFilterLanguage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.workerFilterAllLanguages),
                selected: _language == null || _language == 'all',
                onSelected: (val) => setState(() => _language = null),
              ),
              ChoiceChip(
                label: const Text('ಕನ್ನಡ (kn)'),
                selected: _language == 'kn',
                onSelected: (val) => setState(() => _language = val ? 'kn' : null),
              ),
              ChoiceChip(
                label: const Text('English (en)'),
                selected: _language == 'en',
                onSelected: (val) => setState(() => _language = val ? 'en' : null),
              ),
              ChoiceChip(
                label: const Text('हिंदी (hi)'),
                selected: _language == 'hi',
                onSelected: (val) => setState(() => _language = val ? 'hi' : null),
              ),
              ChoiceChip(
                label: const Text('తెలుగు (te)'),
                selected: _language == 'te',
                onSelected: (val) => setState(() => _language = val ? 'te' : null),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 5. Gender Preference (Optional Filter)
          Text(l10n.workerFilterGender, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.workerFilterAnyGender),
                selected: _gender == null || _gender == 'any',
                onSelected: (val) => setState(() => _gender = null),
              ),
              ChoiceChip(
                label: const Text('Female'),
                selected: _gender == 'female',
                onSelected: (val) => setState(() => _gender = val ? 'female' : null),
              ),
              ChoiceChip(
                label: const Text('Male'),
                selected: _gender == 'male',
                onSelected: (val) => setState(() => _gender = val ? 'male' : null),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 6. Minimum Rating
          Text(l10n.workerFilterMinRating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.workerFilterAnyRating),
                selected: _minRating == null,
                onSelected: (val) => setState(() => _minRating = null),
              ),
              ChoiceChip(
                label: const Text('★ 4.0+'),
                selected: _minRating == 4.0,
                onSelected: (val) => setState(() => _minRating = val ? 4.0 : null),
              ),
              ChoiceChip(
                label: const Text('★ 4.5+'),
                selected: _minRating == 4.5,
                onSelected: (val) => setState(() => _minRating = val ? 4.5 : null),
              ),
              ChoiceChip(
                label: const Text('★ 4.8+'),
                selected: _minRating == 4.8,
                onSelected: (val) => setState(() => _minRating = val ? 4.8 : null),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 7. Completed Jobs
          Text(l10n.workerFilterMinJobs, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.workerFilterAnyJobs),
                selected: _minJobs == null,
                onSelected: (val) => setState(() => _minJobs = null),
              ),
              ChoiceChip(
                label: const Text('5+ jobs'),
                selected: _minJobs == 5,
                onSelected: (val) => setState(() => _minJobs = val ? 5 : null),
              ),
              ChoiceChip(
                label: const Text('10+ jobs'),
                selected: _minJobs == 10,
                onSelected: (val) => setState(() => _minJobs = val ? 10 : null),
              ),
              ChoiceChip(
                label: const Text('20+ jobs'),
                selected: _minJobs == 20,
                onSelected: (val) => setState(() => _minJobs = val ? 20 : null),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final notifier = ref.read(workerFilterNotifierProvider.notifier);
                notifier.setCategory(_selectedCat, null);
                notifier.setRadiusKm(_radiusKm);
                notifier.setLanguage(_language);
                notifier.setAvailability(_availability);
                notifier.setRateRange(_minRate, _maxRate);
                notifier.setGenderPreference(_gender);
                notifier.setMinRating(_minRating);
                notifier.setMinJobsCompleted(_minJobs);
                notifier.setVerifiedOnly(_verifiedOnly);
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.workerFilterApply,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
