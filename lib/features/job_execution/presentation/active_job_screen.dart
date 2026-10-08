import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/services/routing_service.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/account/presentation/settings_screen.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/active_job_detail.dart';
import 'package:udyogasethu/features/job_execution/domain/assignment_event_item.dart';
import 'package:udyogasethu/features/job_execution/presentation/assignment_timeline_widget.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const ActiveJobScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  final FlutterTts _tts = FlutterTts();
  final MapController _mapController = MapController();

  RoutingResult? _routingResult;
  bool _isLoadingRoute = true;
  bool _isActionInProgress = false;
  bool? _overrideSimpleMode;

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchRoute();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveJobScreen] TTS init error: $e');
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveJobScreen] TTS speak error: $e');
    }
  }

  Future<void> _fetchRoute() async {
    setState(() => _isLoadingRoute = true);
    final routing = ref.read(routingServiceProvider);

    // Default coordinates in Bengaluru (Worker in Jayanagar, Job in Koramangala)
    const workerFallback = LatLng(12.9279, 77.6271);
    const jobFallback = LatLng(12.9352, 77.6245);

    try {
      final detail = await ref.read(jobExecutionRepositoryProvider).fetchActiveJob(widget.assignmentId);
      final start = detail.workerLocation ?? workerFallback;
      final dest = detail.jobLocation;

      final res = await routing.getRoute(start: start, destination: dest);
      if (mounted) {
        setState(() {
          _routingResult = res;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      final res = routing.computeStraightLineFallback(workerFallback, jobFallback);
      if (mounted) {
        setState(() {
          _routingResult = res;
          _isLoadingRoute = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final isProvider = session.activeRole == UserRole.provider;
    final globalSettings = ref.watch(userSettingsProvider).value;
    final isSimpleMode = _overrideSimpleMode ?? (globalSettings?.simpleMode ?? false);
    final l10n = AppLocalizations.of(context);

    final jobAsync = ref.watch(activeJobDetailProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.activeJobTitle ?? 'Active Job Execution',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Simple Mode Toggle Chip
          IconButton(
            icon: Icon(
              isSimpleMode ? Icons.accessibility_new_rounded : Icons.accessibility_new_outlined,
              color: isSimpleMode ? const Color(0xFFF59E0B) : Colors.white,
            ),
            tooltip: isSimpleMode ? 'Disable Simple Mode' : 'Enable Simple Mode',
            onPressed: () {
              setState(() {
                _overrideSimpleMode = !isSimpleMode;
              });
              final msg = isSimpleMode ? 'Standard Mode Enabled' : 'Simple Mode Enabled';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(activeJobDetailProvider(widget.assignmentId));
              _fetchRoute();
            },
          ),
        ],
      ),
      body: jobAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.headerGreenDark),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Error loading active job: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerGreenDark),
                  onPressed: () => ref.invalidate(activeJobDetailProvider(widget.assignmentId)),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Status Banner with Pulsing Live Dot
              _buildStatusBanner(context, detail, l10n),
              const SizedBox(height: 16),

              // 2. The Big Primary Action (Normal vs Simple Mode)
              _buildPrimaryActionSection(context, detail, isProvider, isSimpleMode, l10n),
              const SizedBox(height: 20),

              // 3. Route, ETA & Open in Maps Section
              _buildRouteMapSection(context, detail, l10n),
              const SizedBox(height: 20),

              // 4. Assignment Timeline Widget (9 Stages, Realtime Stream)
              AssignmentTimelineWidget(
                assignmentId: detail.assignmentId,
                currentStatus: detail.status,
                isProvider: isProvider,
              ),
              const SizedBox(height: 20),

              // 5. Job & Counterpart Information Card
              _buildJobDetailsCard(context, detail, isProvider, l10n),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, ActiveJobDetail detail, AppLocalizations? l10n) {
    Color bg;
    Color fg;
    String statusLabel = detail.stage.title;

    switch (detail.stage) {
      case AssignmentStage.requestCreated:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        statusLabel = l10n?.stageRequestCreated ?? 'Request Created';
        break;
      case AssignmentStage.accepted:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF15803D);
        statusLabel = l10n?.stageAccepted ?? 'Accepted - Preparing';
        break;
      case AssignmentStage.ticketIssued:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF15803D);
        statusLabel = l10n?.stageTicketIssued ?? 'Ticket Issued';
        break;
      case AssignmentStage.workerArrived:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        statusLabel = l10n?.stageWorkerArrived ?? 'Worker Arrived at Site';
        break;
      case AssignmentStage.verificationCompleted:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        statusLabel = l10n?.stageVerificationCompleted ?? 'Verification Completed';
        break;
      case AssignmentStage.jobInProgress:
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFC2410C);
        statusLabel = l10n?.stageJobInProgress ?? 'Job In Progress';
        break;
      case AssignmentStage.completed:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        statusLabel = l10n?.stageCompleted ?? 'Work Completed';
        break;
      case AssignmentStage.paymentReleased:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF15803D);
        statusLabel = l10n?.stagePaymentReleased ?? 'Payment Released';
        break;
      case AssignmentStage.disputeRaised:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFB91C1C);
        statusLabel = l10n?.stageDisputeRaised ?? 'Dispute Raised';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(detail.stage.icon, color: fg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: fg),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Booking Code: ${detail.bookingCode}',
                  style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Text(
            '₹${detail.agreedWageRupees}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionSection(
    BuildContext context,
    ActiveJobDetail detail,
    bool isProvider,
    bool isSimpleMode,
    AppLocalizations? l10n,
  ) {
    String primaryText;
    IconData primaryIcon;
    VoidCallback? onPrimaryPressed;

    if (!isProvider) {
      // Worker actions
      switch (detail.stage) {
        case AssignmentStage.requestCreated:
          primaryText = l10n?.actionAcceptJob ?? 'Accept Job';
          primaryIcon = Icons.check_circle_outline_rounded;
          onPrimaryPressed = () => _handleTransition(detail, 'accepted');
          break;
        case AssignmentStage.accepted:
        case AssignmentStage.ticketIssued:
          primaryText = l10n?.actionWorkerArrived ?? 'I Have Arrived';
          primaryIcon = Icons.pin_drop_rounded;
          onPrimaryPressed = () => _handleTransition(detail, 'arrived');
          break;
        case AssignmentStage.workerArrived:
        case AssignmentStage.verificationCompleted:
          primaryText = l10n?.actionStartWork ?? 'Start Work';
          primaryIcon = Icons.play_arrow_rounded;
          onPrimaryPressed = () => _handleTransition(detail, 'in_progress_verified');
          break;
        case AssignmentStage.jobInProgress:
          primaryText = l10n?.actionCompleteJob ?? 'Complete Job';
          primaryIcon = Icons.task_alt_rounded;
          onPrimaryPressed = () => _handleTransition(detail, 'completed');
          break;
        case AssignmentStage.completed:
          primaryText = l10n?.actionAwaitingPayment ?? 'Awaiting Payment Release';
          primaryIcon = Icons.hourglass_top_rounded;
          onPrimaryPressed = null;
          break;
        case AssignmentStage.paymentReleased:
          primaryText = l10n?.actionJobFinished ?? 'Job Fully Completed';
          primaryIcon = Icons.done_all_rounded;
          onPrimaryPressed = null;
          break;
        case AssignmentStage.disputeRaised:
          primaryText = l10n?.actionDisputeMediation ?? 'In Dispute Review';
          primaryIcon = Icons.warning_rounded;
          onPrimaryPressed = null;
          break;
      }
    } else {
      // Provider actions
      switch (detail.stage) {
        case AssignmentStage.requestCreated:
          primaryText = l10n?.actionWaitingAcceptance ?? 'Waiting for Worker to Accept';
          primaryIcon = Icons.hourglass_bottom_rounded;
          onPrimaryPressed = null;
          break;
        case AssignmentStage.accepted:
        case AssignmentStage.ticketIssued:
          primaryText = l10n?.actionConfirmArrival ?? 'Confirm Worker Arrival';
          primaryIcon = Icons.pin_drop_rounded;
          onPrimaryPressed = () => _handleTransition(detail, 'arrived');
          break;
        case AssignmentStage.workerArrived:
        case AssignmentStage.verificationCompleted:
          primaryText = l10n?.actionStartWork ?? 'Verify & Start Work';
          primaryIcon = Icons.play_arrow_rounded;
          onPrimaryPressed = () => _handleTransition(detail, 'in_progress_verified');
          break;
        case AssignmentStage.jobInProgress:
          primaryText = l10n?.actionConfirmCompletion ?? 'Confirm Job Completion';
          primaryIcon = Icons.task_alt_rounded;
          onPrimaryPressed = () => _handleTransition(detail, 'completed');
          break;
        case AssignmentStage.completed:
          primaryText = l10n?.actionReleasePayment ?? 'Release Payment';
          primaryIcon = Icons.payments_rounded;
          onPrimaryPressed = () => _handleTransition(detail, 'payment_released');
          break;
        case AssignmentStage.paymentReleased:
          primaryText = l10n?.actionPaymentDone ?? 'Payment Settled';
          primaryIcon = Icons.check_circle_rounded;
          onPrimaryPressed = null;
          break;
        case AssignmentStage.disputeRaised:
          primaryText = l10n?.actionDisputeMediation ?? 'In Dispute Review';
          primaryIcon = Icons.warning_rounded;
          onPrimaryPressed = null;
          break;
      }
    }

    if (isSimpleMode) {
      // HUGE Simple Mode Primary Action
      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6548), Color(0xFF064E3B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D6548).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _speak(primaryText);
                  onPrimaryPressed?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(primaryIcon, size: 36, color: Colors.white),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryText,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFFFDE68A)),
                                const SizedBox(width: 4),
                                Text(
                                  l10n?.simpleModeSpokenLabel ?? 'Tap to Speak & Execute',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFFDE68A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_isActionInProgress)
                        const CircularProgressIndicator(color: Colors.white)
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Secondary Simple Mode Action: "Ask for Help"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.support_agent_rounded, size: 26),
              label: Text(
                l10n?.actionAskForHelp ?? 'Ask for Help / SOS',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _speak('Ask for help');
                _showHelpSheet(context);
              },
            ),
          ),
        ],
      );
    }

    // Standard Mode Action
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerGreenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: _isActionInProgress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(primaryIcon, size: 22),
            label: Text(
              primaryText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _isActionInProgress ? null : onPrimaryPressed,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: Text(l10n?.actionDispute ?? 'Raise Dispute'),
                onPressed: () => _handleTransition(detail, 'disputed'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.headerGreenDark,
                  side: const BorderSide(color: AppColors.cardBorderGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: Text(l10n?.actionAskForHelp ?? 'Ask for Help'),
                onPressed: () => _showHelpSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteMapSection(
    BuildContext context,
    ActiveJobDetail detail,
    AppLocalizations? l10n,
  ) {
    final route = _routingResult;
    final workerLoc = detail.workerLocation ?? const LatLng(12.9279, 77.6271);
    final jobLoc = detail.jobLocation;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderGreen.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with ETA and OSRM Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.alt_route_rounded, color: AppColors.headerGreenDark, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n?.routeAndEtaTitle ?? 'Route & Travel ETA',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const Spacer(),
                if (route != null && route.isStraightLineFallback)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Text(
                      l10n?.demoModeChip ?? 'Demo Mode: Straight-line',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.paleMint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'OSRM Driving',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                    ),
                  ),
              ],
            ),
          ),

          // Map View with Polyline
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      (workerLoc.latitude + jobLoc.latitude) / 2,
                      (workerLoc.longitude + jobLoc.longitude) / 2,
                    ),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'in.udyogasethu',
                    ),
                    if (route != null && route.points.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: route.points,
                            strokeWidth: 4.5,
                            color: const Color(0xFF0D6548),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Worker Marker
                        Marker(
                          point: workerLoc,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ),
                        // Job Site Marker
                        Marker(
                          point: jobLoc,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isLoadingRoute)
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.headerGreenDark),
                    ),
                  ),
              ],
            ),
          ),

          // Distance, ETA & "Open in Maps" button
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_car_rounded, size: 16, color: AppColors.textDark),
                          const SizedBox(width: 4),
                          Text(
                            route?.formattedDistance ?? 'Calculating...',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.schedule_rounded, size: 16, color: AppColors.warningOrange),
                          const SizedBox(width: 4),
                          Text(
                            route?.formattedDuration ?? '...',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.warningOrange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail.addressText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A), // Slate 900
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: Text(l10n?.openInMapsBtn ?? 'Open in Maps', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    RoutingService.openExternalMaps(
                      destination: jobLoc,
                      label: detail.jobTitle,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsCard(
    BuildContext context,
    ActiveJobDetail detail,
    bool isProvider,
    AppLocalizations? l10n,
  ) {
    final otherPartyName = isProvider ? detail.workerName : detail.providerName;
    final otherPartyRole = isProvider ? 'Worker' : 'Job Provider';
    final otherPartyPhone = isProvider ? detail.workerPhone : detail.providerPhone;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.jobTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
          ),
          if (detail.jobDescription != null) ...[
            const SizedBox(height: 4),
            Text(
              detail.jobDescription!,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Counterparty Row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.paleMint,
                child: Text(
                  otherPartyName.isNotEmpty ? otherPartyName[0] : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          otherPartyName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                      ],
                    ),
                    Text(
                      '$otherPartyRole • ${otherPartyPhone ?? 'Verified contact'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleTransition(ActiveJobDetail detail, String nextStatus) async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(jobExecutionRepositoryProvider).advanceStage(detail.assignmentId, nextStatus);
      // Invalidate active job detail to refresh state
      ref.invalidate(activeJobDetailProvider(widget.assignmentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $nextStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error advancing status: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.support_agent_rounded, size: 48, color: AppColors.headerGreenDark),
                const SizedBox(height: 12),
                const Text(
                  'Need Help or Emergency Assistance?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our 24/7 trust and safety support team is available to assist with on-site emergencies, location issues, or queries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.sos_rounded),
                    label: const Text('Trigger Emergency SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.safetyHub);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
