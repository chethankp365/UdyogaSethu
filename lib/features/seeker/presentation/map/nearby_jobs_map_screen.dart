import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:udyogasethu/features/seeker/domain/job_pin.dart';
import 'package:udyogasethu/features/seeker/presentation/map/nearby_jobs_map_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/map/tile_config.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// Screen 7: GPS Based Job Tracking / Nearby Jobs Map
/// Matching Screen 7 in docs/UI_REFERENCE.md exactly in structure and styling.
class NearbyJobsMapScreen extends ConsumerStatefulWidget {
  const NearbyJobsMapScreen({super.key});

  @override
  ConsumerState<NearbyJobsMapScreen> createState() => _NearbyJobsMapScreenState();
}

class _NearbyJobsMapScreenState extends ConsumerState<NearbyJobsMapScreen> {
  final MapController _mapController = MapController();
  final ScrollController _listScrollController = ScrollController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  static const Color kHeaderColor = Color(0xFF0D6548);
  static const Color kPinColor = Color(0xFF00875A);
  static const Color kPinSelectedColor = Color(0xFFE65100);
  static const Color kLiveBadgeBg = Color(0xFFE6F4EA);
  static const Color kLiveBadgeText = Color(0xFF064E3B);

  @override
  void dispose() {
    _mapController.dispose();
    _listScrollController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _scrollToJob(String jobId, List<JobPin> pins) {
    final index = pins.indexWhere((p) => p.id == jobId);
    if (index != -1 && _listScrollController.hasClients) {
      final targetOffset = index * 128.0;
      _listScrollController.animateTo(
        targetOffset.clamp(0.0, _listScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _animateMapTo(LatLng point) {
    _mapController.move(point, _mapController.camera.zoom);
  }

  void _zoomIn() {
    final current = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (current + 1.0).clamp(3.0, 19.0));
  }

  void _zoomOut() {
    final current = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (current - 1.0).clamp(3.0, 19.0));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(nearbyJobsMapNotifierProvider);
    final notifier = ref.read(nearbyJobsMapNotifierProvider.notifier);
    final tileConfig = ref.watch(tileConfigProvider);
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. TOP HEADER & LIVE PINS BADGE
            _buildTopHeader(l10n, state),

            // 2. HORIZONTAL CATEGORY FILTER CHIPS
            _buildCategoryChips(state, notifier, currentLang, l10n),

            // 3. MAP VIEW & DRAGGABLE BOTTOM SHEET
            Expanded(
              child: Stack(
                children: [
                  // OpenStreetMap FlutterMap
                  _buildMap(state, notifier, tileConfig),

                  // Non-blocking GPS disabled banner
                  if (state.isGpsDisabled)
                    _buildGpsDisabledBanner(l10n),

                  // Floating Map Controls (Zoom +, Zoom -, Recenter, Radius)
                  Positioned(
                    top: state.isGpsDisabled ? 56 : 16,
                    right: 16,
                    child: _buildMapControls(l10n, state, notifier),
                  ),

                  // DRAGGABLE BOTTOM SHEET: NEARBY GPS PIN LISTINGS
                  _buildListingsSheet(l10n, state, notifier, currentLang),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(AppLocalizations l10n, NearbyJobsMapState state) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: kHeaderColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.nearbyJobsMapTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Live Pins Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kLiveBadgeBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing Green Indicator Dot
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.livePinsCount(state.livePinsCount),
                  style: const TextStyle(
                    color: kLiveBadgeText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(
    NearbyJobsMapState state,
    NearbyJobsMapNotifier notifier,
    String lang,
    AppLocalizations l10n,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // "All" filter chip
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: l10n.categoryFilterAll,
                icon: Icons.apps_rounded,
                isSelected: state.selectedCategoryId == null,
                onTap: () => notifier.selectCategory(null),
              ),
            ),
            // Dynamic category chips
            ...state.categories.map((cat) {
              final isSelected = state.selectedCategoryId == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  label: cat.getLocalizedName(lang),
                  icon: _mapCategoryIcon(cat.icon),
                  isSelected: isSelected,
                  onTap: () => notifier.selectCategory(cat.id),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kHeaderColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kHeaderColor : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(
    NearbyJobsMapState state,
    NearbyJobsMapNotifier notifier,
    TileConfig tileConfig,
  ) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: state.mapCenter,
        initialZoom: state.mapZoom,
        minZoom: tileConfig.minZoom.toDouble(),
        maxZoom: tileConfig.maxZoom.toDouble(),
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) {
            notifier.onMapMoved(camera.center, camera.zoom);
          }
        },
      ),
      children: [
        // 1. Tile Layer with TileConfig
        TileLayer(
          urlTemplate: tileConfig.urlTemplate,
          userAgentPackageName: tileConfig.userAgentPackageName,
          maxZoom: tileConfig.maxZoom.toDouble(),
          minZoom: tileConfig.minZoom.toDouble(),
        ),

        // 2. User Location Marker
        if (state.userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: state.userLocation!,
                width: 32,
                height: 32,
                child: _buildUserLocationMarker(),
              ),
            ],
          ),

        // 3. Price Pin Markers
        MarkerLayer(
          markers: state.jobPins.map((job) {
            final isSelected = state.selectedJobId == job.id;
            return Marker(
              point: job.latLng,
              width: 76,
              height: 42,
              child: GestureDetector(
                onTap: () {
                  notifier.selectJob(job.id);
                  _animateMapTo(job.latLng);
                  _scrollToJob(job.id, state.jobPins);
                },
                child: _buildPricePinMarker(job, isSelected),
              ),
            );
          }).toList(),
        ),

        // 4. OpenStreetMap Attribution
        const SimpleAttributionWidget(
          source: Text(
            '© OpenStreetMap contributors',
            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          alignment: Alignment.bottomLeft,
        ),
      ],
    );
  }

  Widget _buildUserLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricePinMarker(JobPin job, bool isSelected) {
    final bgColor = isSelected ? kPinSelectedColor : kPinColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: isSelected ? 6 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            job.pricePinText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: isSelected ? 12.5 : 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ),
        // Downward Arrow Tip
        CustomPaint(
          size: const Size(8, 4),
          painter: _TrianglePainter(color: bgColor),
        ),
      ],
    );
  }

  Widget _buildGpsDisabledBanner(AppLocalizations l10n) {
    return Positioned(
      top: 8,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCD34D)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Color(0xFFB45309), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.gpsDisabledBanner,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
              ),
            ),
            TextButton(
              onPressed: () => Geolocator.openLocationSettings(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 30),
              ),
              child: Text(
                l10n.openLocationSettings,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(
    AppLocalizations l10n,
    NearbyJobsMapState state,
    NearbyJobsMapNotifier notifier,
  ) {
    return Column(
      children: [
        // Recenter GPS Button
        _buildCircleControlButton(
          icon: Icons.my_location_rounded,
          tooltip: l10n.recenterMap,
          onPressed: () => notifier.recenterOnUser(),
        ),
        const SizedBox(height: 10),
        // Zoom In
        _buildCircleControlButton(
          icon: Icons.add_rounded,
          tooltip: l10n.zoomIn,
          onPressed: _zoomIn,
        ),
        const SizedBox(height: 6),
        // Zoom Out
        _buildCircleControlButton(
          icon: Icons.remove_rounded,
          tooltip: l10n.zoomOut,
          onPressed: _zoomOut,
        ),
        const SizedBox(height: 10),
        // Radius Selector Pill
        _buildRadiusButton(l10n, state, notifier),
      ],
    );
  }

  Widget _buildCircleControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF1E293B), size: 22),
        ),
      ),
    );
  }

  Widget _buildRadiusButton(
    AppLocalizations l10n,
    NearbyJobsMapState state,
    NearbyJobsMapNotifier notifier,
  ) {
    final currentKm = (state.radiusM / 1000).round();
    return PopupMenuButton<double>(
      initialValue: state.radiusM,
      tooltip: l10n.searchRadius,
      onSelected: (radius) => notifier.setRadius(radius),
      itemBuilder: (context) => [
        PopupMenuItem(value: 5000, child: Text(l10n.radiusKm(5))),
        PopupMenuItem(value: 10000, child: Text(l10n.radiusKm(10))),
        PopupMenuItem(value: 25000, child: Text(l10n.radiusKm(25))),
        PopupMenuItem(value: 50000, child: Text(l10n.radiusKm(50))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar_rounded, size: 14, color: kHeaderColor),
            const SizedBox(width: 4),
            Text(
              l10n.radiusKm(currentKm),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsSheet(
    AppLocalizations l10n,
    NearbyJobsMapState state,
    NearbyJobsMapNotifier notifier,
    String lang,
  ) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.38,
      minChildSize: 0.16,
      maxChildSize: 0.85,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Bottom Sheet Header matching Screen 7:
              // NEARBY GPS PIN LISTINGS (N) | Tap pin or card to inspect
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.nearbyGpsPinListings(state.livePinsCount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.tapPinOrCardToInspect,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kPinColor),
                      ),
                  ],
                ),
              ),

              const Divider(height: 12, thickness: 1, color: Color(0xFFF1F5F9)),

              // LIST OF JOB CARDS OR EMPTY/ERROR STATES
              Expanded(
                child: _buildListingsContent(
                  l10n,
                  state,
                  notifier,
                  scrollController,
                  lang,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListingsContent(
    AppLocalizations l10n,
    NearbyJobsMapState state,
    NearbyJobsMapNotifier notifier,
    ScrollController scrollController,
    String lang,
  ) {
    if (state.errorMessage != null && state.jobPins.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 8),
              Text(
                l10n.loadJobsError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => notifier.fetchJobs(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.retryAction),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kHeaderColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.isLoading && state.jobPins.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 8),
              Text(
                l10n.noJobsInArea,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => notifier.setRadius(50000),
                icon: const Icon(Icons.zoom_out_map_rounded, size: 16),
                label: Text(l10n.widenRadiusAction),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kHeaderColor,
                  side: const BorderSide(color: kHeaderColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: state.jobPins.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final job = state.jobPins[index];
        final isSelected = state.selectedJobId == job.id;
        final isApplied = state.appliedJobIds.contains(job.id);

        return _buildJobCard(
          job: job,
          isSelected: isSelected,
          isApplied: isApplied,
          lang: lang,
          l10n: l10n,
          onTap: () {
            notifier.selectJob(job.id);
            _animateMapTo(job.latLng);
          },
          onApply: () async {
            await notifier.applyToJob(job.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.applied} - ${job.title}'),
                  backgroundColor: kPinColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildJobCard({
    required JobPin job,
    required bool isSelected,
    required bool isApplied,
    required String lang,
    required AppLocalizations l10n,
    required VoidCallback onTap,
    required VoidCallback onApply,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPinColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 8 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _mapCategoryIcon(job.categoryIcon),
                color: kPinColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Job Title, Employer, Distance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          job.employerName,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (job.employerVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF10B981),
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          job.addressText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (job.formattedDistance.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        Text(
                          job.formattedDistance,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Price & Apply Button Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  job.formattedWage,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: isApplied ? null : onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isApplied ? const Color(0xFFE2E8F0) : kPinColor,
                      foregroundColor: isApplied ? const Color(0xFF64748B) : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleRadius(16),
                    ),
                    child: Text(
                      isApplied ? l10n.applied : l10n.applyButton,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isApplied ? const Color(0xFF64748B) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _mapCategoryIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'construction':
        return Icons.construction_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'painting':
      case 'format_paint':
        return Icons.format_paint_rounded;
      case 'delivery':
      case 'local_shipping':
      case 'two_wheeler':
        return Icons.local_shipping_rounded;
      case 'electrician':
      case 'electrical_services':
        return Icons.electrical_services_rounded;
      case 'carpenter':
        return Icons.handyman_rounded;
      case 'mason':
        return Icons.foundation_rounded;
      case 'cleaner':
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'driver':
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'agri_labour':
      case 'agriculture':
        return Icons.agriculture_rounded;
      case 'loader':
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      default:
        return Icons.work_rounded;
    }
  }
}

class RoundedRectangleRadius extends RoundedRectangleBorder {
  RoundedRectangleRadius(double radius) : super(borderRadius: BorderRadius.circular(radius));
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
