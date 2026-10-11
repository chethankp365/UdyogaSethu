import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
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
import 'package:udyogasethu/features/job_execution/presentation/mid_job_dialog.dart';
import 'package:udyogasethu/features/job_execution/presentation/widgets/job_live_timer_card.dart';
import 'package:udyogasethu/features/job_execution/presentation/widgets/running_late_dialog.dart';
import 'package:udyogasethu/features/job_execution/presentation/widgets/worker_not_arrived_sheet.dart';
import 'package:udyogasethu/features/trust/presentation/widgets/raise_dispute_dialog.dart';
import 'package:udyogasethu/features/trust/presentation/widgets/rate_job_dialog.dart';
import 'package:udyogasethu/features/payments/data/payment_repository.dart';
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
  LatLng? _currentWorkerLocation;
  bool _isLoadingRoute = true;
  bool _isActionInProgress = false;
  bool? _overrideSimpleMode;
  bool _hasShownNoShowSheet = false;
  Timer? _noShowCheckTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchRoute();
    _startNoShowChecker();
  }

  void _startNoShowChecker() {
    _checkNoShow();
    _noShowCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkNoShow();
    });
  }

  Future<void> _checkNoShow() async {
    try {
      await ref.read(jobExecutionRepositoryProvider).checkNoShowAssignments();
      if (mounted) {
        ref.invalidate(activeJobDetailProvider(widget.assignmentId));
      }
    } catch (_) {}
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

    LatLng? currentWorkerLoc;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 3)),
      );
      if (pos.latitude != 0.0 || pos.longitude != 0.0) {
        currentWorkerLoc = LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {}

    try {
      final detail = await ref.read(jobExecutionRepositoryProvider).fetchActiveJob(widget.assignmentId);

      if (kDebugMode) {
        debugPrint('[ActiveJobMap] assignmentId: ${widget.assignmentId}');
        debugPrint('[ActiveJobMap] jobLat: ${detail.jobLat}, jobLng: ${detail.jobLng}, hasValidJobCoordinates: ${detail.hasValidJobCoordinates}');
        debugPrint('[ActiveJobMap] workerLat: ${currentWorkerLoc?.latitude}, workerLng: ${currentWorkerLoc?.longitude}');
        debugPrint('[ActiveJobMap] mapCenter: ${currentWorkerLoc ?? detail.validJobLocation}, tileUrl: https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      }

      if (!detail.hasValidJobCoordinates) {
        if (mounted) {
          setState(() {
            _currentWorkerLocation = currentWorkerLoc;
            _routingResult = null;
            _isLoadingRoute = false;
          });
        }
        return;
      }

      final dest = detail.validJobLocation!;
      final start = currentWorkerLoc ?? detail.workerLocation ?? dest;

      final res = await routing.getRoute(start: start, destination: dest);
      if (mounted) {
        setState(() {
          _currentWorkerLocation = currentWorkerLoc;
          _routingResult = res;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentWorkerLocation = currentWorkerLoc;
          _isLoadingRoute = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _noShowCheckTimer?.cancel();
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
            icon: Icon(isProvider ? Icons.qr_code_scanner_rounded : Icons.qr_code_rounded),
            tooltip: isProvider ? (l10n?.actionScanWorkerQr ?? 'Scan Worker QR') : (l10n?.actionShowTicket ?? 'Show QR Ticket'),
            onPressed: () {
              if (isProvider) {
                context.push('/jobs/attendance-scan?assignment_id=${widget.assignmentId}');
              } else {
                context.push('/jobs/ticket/${widget.assignmentId}');
              }
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
          // Auto-trigger No-Show Sheet once for Provider when worker is late
          if (isProvider && detail.isLate && !_hasShownNoShowSheet && mounted) {
            _hasShownNoShowSheet = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                WorkerNotArrivedSheet.show(
                  context,
                  jobDetail: detail,
                  onActionCompleted: () {
                    ref.invalidate(activeJobDetailProvider(widget.assignmentId));
                  },
                );
              }
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Status Banner with Pulsing Live Dot
              _buildStatusBanner(context, detail, isProvider, l10n),
              const SizedBox(height: 16),

              // Provider No-Show Alert Banner (when late or late_notified_at is set)
              if (isProvider && (detail.isLate || detail.lateNotifiedAt != null) && detail.status == 'ticket_issued') ...[
                _buildProviderNoShowBanner(context, detail, l10n),
                const SizedBox(height: 16),
              ],

              // Worker-side "Running late?" action banner
              if (!isProvider && (detail.stage == AssignmentStage.accepted || detail.stage == AssignmentStage.ticketIssued) && detail.arrivedAt == null) ...[
                _buildWorkerRunningLateSection(context, detail, l10n),
                const SizedBox(height: 16),
              ],

              // Server-authoritative Live Timer (when job is in progress or completed)
              if (detail.stage == AssignmentStage.jobInProgress || detail.startedAt != null) ...[
                JobLiveTimerCard(
                  startedAt: detail.startedAt,
                  endedAt: detail.endedAt,
                  serverElapsedSeconds: detail.elapsedSeconds,
                  isCompleted: detail.stage == AssignmentStage.completed ||
                      detail.stage == AssignmentStage.paymentReleased,
                ),
                const SizedBox(height: 16),
              ],

              // Mid-Job Verification Banner (High-value job check >= ₹2,000)
              if (detail.stage == AssignmentStage.jobInProgress && detail.agreedWagePaise >= 200000) ...[
                _buildMidJobSection(context, detail, isProvider, l10n),
                const SizedBox(height: 16),
              ],

              // 2. The Big Primary Action (Normal vs Simple Mode)
              if (!isProvider && (detail.status == 'arrived' || detail.stage == AssignmentStage.workerArrived)) ...[
                _buildStep2RealtimePrompt(context, detail, l10n),
                const SizedBox(height: 16),
              ],
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

  Widget _buildStatusBanner(BuildContext context, ActiveJobDetail detail, bool isProvider, AppLocalizations? l10n) {
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
        if (!isProvider) {
          bg = const Color(0xFFFEF3C7);
          fg = const Color(0xFFB45309);
          statusLabel = l10n?.pendingEscrowRelease ?? 'Pending Escrow Release';
        } else {
          bg = const Color(0xFFECFDF5);
          fg = const Color(0xFF047857);
          statusLabel = 'Work Completed - Ready for Release';
        }
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
                    Flexible(
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: fg),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                    ),
                    if (detail.protectionSelected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: fg.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, size: 11, color: fg),
                            const SizedBox(width: 3),
                            Text(
                              l10n?.protectedBadge ?? 'Protected',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
          primaryText = l10n?.actionShowTicket ?? 'Show QR Ticket';
          primaryIcon = Icons.qr_code_rounded;
          onPrimaryPressed = () => context.push('/jobs/ticket/${detail.assignmentId}');
          break;
        case AssignmentStage.workerArrived:
        case AssignmentStage.verificationCompleted:
          primaryText = l10n?.verifyYourPresence ?? 'Verify Presence (Face & GPS)';
          primaryIcon = Icons.verified_user_rounded;
          onPrimaryPressed = () => context.push('/jobs/verify-presence/${detail.assignmentId}');
          break;
        case AssignmentStage.jobInProgress:
          primaryText = l10n?.actionCompleteJob ?? 'Complete Job & Submit Evidence';
          primaryIcon = Icons.task_alt_rounded;
          onPrimaryPressed = () => context.push('/jobs/completion/${detail.assignmentId}');
          break;
        case AssignmentStage.completed:
          primaryText = '${l10n?.pendingEscrowRelease ?? 'Pending Escrow Release'} (₹${detail.agreedWageRupees})';
          primaryIcon = Icons.hourglass_top_rounded;
          onPrimaryPressed = () => _showWorkerEscrowInfoSheet(context, detail);
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
          primaryText = l10n?.actionScanWorkerQr ?? 'Scan Worker QR';
          primaryIcon = Icons.qr_code_scanner_rounded;
          onPrimaryPressed = () => context.push('/jobs/attendance-scan?assignment_id=${detail.assignmentId}');
          break;
        case AssignmentStage.workerArrived:
          primaryText = 'Awaiting Worker Selfie Verification';
          primaryIcon = Icons.hourglass_top_rounded;
          onPrimaryPressed = null;
          break;
        case AssignmentStage.verificationCompleted:
          primaryText = l10n?.actionStartWork ?? 'Verify & Start Work';
          primaryIcon = Icons.play_arrow_rounded;
          onPrimaryPressed = () => _handleTransition(detail, 'in_progress_verified');
          break;
        case AssignmentStage.jobInProgress:
          primaryText = l10n?.actionConfirmCompletion ?? 'Confirm Job Completion';
          primaryIcon = Icons.task_alt_rounded;
          onPrimaryPressed = () => _showProviderCompletionDialog(context, detail);
          break;
        case AssignmentStage.completed:
          primaryText = '${l10n?.confirmAndRelease ?? 'Confirm & Release Payment'} (₹${detail.agreedWageRupees})';
          primaryIcon = Icons.payments_rounded;
          onPrimaryPressed = () => _showProviderReleaseDialog(context, detail);
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
        // Rate Job Button on Completion
        if (detail.stage == AssignmentStage.completed || detail.stage == AssignmentStage.paymentReleased) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD97706),
                side: const BorderSide(color: Color(0xFFFCD34D), width: 1.5),
                backgroundColor: const Color(0xFFFFFBEB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.star_rounded, size: 20),
              label: const Text(
                'Rate & Review This Job',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                RateJobDialog.show(
                  context,
                  assignmentId: detail.assignmentId,
                  jobTitle: detail.jobTitle,
                  counterpartyName: isProvider ? detail.workerName : detail.providerName,
                  onReviewSubmitted: () => ref.invalidate(activeJobDetailProvider(widget.assignmentId)),
                );
              },
            ),
          ),
        ],

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
                label: Text(detail.stage == AssignmentStage.disputeRaised
                    ? 'Dispute Active'
                    : (l10n?.actionDispute ?? 'Raise Dispute')),
                onPressed: detail.stage == AssignmentStage.disputeRaised
                    ? null
                    : () {
                        RaiseDisputeDialog.show(
                          context,
                          assignmentId: detail.assignmentId,
                          jobTitle: detail.jobTitle,
                          counterpartyName: isProvider ? detail.workerName : detail.providerName,
                          onDisputeRaised: () => ref.invalidate(activeJobDetailProvider(widget.assignmentId)),
                        );
                      },
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

  Widget _buildStep2RealtimePrompt(
    BuildContext context,
    ActiveJobDetail detail,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100D6548),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D6548),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Employer Verified Arrival!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Proceed to Step 2: Take live selfie & GPS reading to start work timer.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6548),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text(
                'Complete Step 2 Verification',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () => context.push('/jobs/verify-presence/${detail.assignmentId}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMapSection(
    BuildContext context,
    ActiveJobDetail detail,
    AppLocalizations? l10n,
  ) {
    if (!detail.hasValidJobCoordinates) {
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.location_off_rounded, size: 36, color: AppColors.warningOrange),
            const SizedBox(height: 8),
            const Text(
              'Job location is not available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              detail.addressText.isNotEmpty ? detail.addressText : 'No site coordinates recorded for this job',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.work_outline_rounded, size: 16),
              label: const Text('Open Job Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: () => context.push('/jobs/${detail.jobId}'),
            ),
          ],
        ),
      );
    }

    final route = _routingResult;
    final jobLoc = detail.validJobLocation!;
    final workerLoc = _currentWorkerLocation ?? detail.workerLocation ?? jobLoc;
    final hasWorkerPoint = workerLoc != jobLoc;

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
                    initialCenter: hasWorkerPoint
                        ? LatLng(
                            (workerLoc.latitude + jobLoc.latitude) / 2,
                            (workerLoc.longitude + jobLoc.longitude) / 2,
                          )
                        : jobLoc,
                    initialZoom: hasWorkerPoint ? 13.0 : 15.0,
                    initialCameraFit: hasWorkerPoint
                        ? CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints([workerLoc, jobLoc]),
                            padding: const EdgeInsets.all(36),
                          )
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'in.udyogasethu',
                      maxZoom: 19,
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
                      label: detail.addressText.isNotEmpty ? detail.addressText : detail.jobTitle,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  detail.jobTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
              ),
              if (detail.protectionSelected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF047857)),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.protectedBadge ?? 'Protected',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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

  Widget _buildMidJobSection(
    BuildContext context,
    ActiveJobDetail detail,
    bool isProvider,
    AppLocalizations? l10n,
  ) {
    final isDone = detail.midjobVerifiedAt != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.verified_rounded : Icons.shield_outlined,
              color: isDone ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDone
                      ? (l10n?.midJobCheckTitle ?? 'Mid-Shift Verification Completed')
                      : (l10n?.midJobCheckTitle ?? 'Mid-Job Verification Required'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDone ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDone
                      ? 'Attendance & site presence verified for ₹${detail.agreedWageRupees} wage.'
                      : 'Wage exceeds ₹2,000 threshold. Midpoint check ensures job safety.',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (!isDone) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final ok = await MidJobDialog.show(
                  context,
                  assignmentId: detail.assignmentId,
                  isCustomer: isProvider,
                );
                if (ok == true && mounted) {
                  ref.invalidate(activeJobDetailProvider(widget.assignmentId));
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ],
      ),
    );
  }

  void _showProviderCompletionDialog(BuildContext context, ActiveJobDetail detail) {
    final l10n = AppLocalizations.of(context);
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.paleMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.headerGreenDark, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.actionConfirmCompletion ?? 'Confirm Job Completion',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Has the worker completed all assigned work to your satisfaction? You can confirm directly or scan their ticket QR again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Confirm Completion (Release Eligible)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      try {
                        setState(() => _isActionInProgress = true);
                        await ref.read(jobExecutionRepositoryProvider).completeJob(
                              assignmentId: detail.assignmentId,
                              isCustomerConfirmed: true,
                            );
                        ref.invalidate(activeJobDetailProvider(widget.assignmentId));
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF0D6548),
                              content: Text('Job marked completed! Payment is flagged eligible for release.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Completion failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isActionInProgress = false);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.headerGreenDark,
                      side: const BorderSide(color: AppColors.headerGreenDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan Worker QR Ticket Again'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/jobs/attendance-scan?assignment_id=${detail.assignmentId}');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProviderReleaseDialog(BuildContext context, ActiveJobDetail detail) {
    final l10n = AppLocalizations.of(context);
    final wagePaise = detail.agreedWagePaise;
    final commissionPaise = (wagePaise * 5) ~/ 100; // 500 bps = 5%
    final workerNetPaise = wagePaise - commissionPaise;
    final wageRupees = (wagePaise / 100).toStringAsFixed(0);
    final commissionRupees = (commissionPaise / 100).toStringAsFixed(2);
    final workerNetRupees = (workerNetPaise / 100).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_open_rounded, color: Color(0xFF047857), size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.releaseEscrowPayment ?? 'Release Escrow Payment',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            detail.jobTitle,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (detail.protectionSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF047857)),
                            const SizedBox(width: 3),
                            Text(
                              l10n?.protectedBadge ?? 'Protected',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n?.paymentServiceWage ?? 'Service / Wage Amount',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                          Text('₹$wageRupees', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n?.paymentPlatformFee ?? 'Platform Fee'} (5%)',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                          Text('- ₹$commissionRupees', style: const TextStyle(color: Color(0xFFD97706), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n?.workerPayout ?? 'Worker Payout (Available Balance)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Text('₹$workerNetRupees', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF15803D))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Releasing escrow immediately transfers available balance to the worker and marks this assignment as settled.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text('${l10n?.confirmAndRelease ?? 'Confirm & Release Payment'} (₹$wageRupees)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _releaseEscrowAction(detail);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _releaseEscrowAction(ActiveJobDetail detail) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(paymentRepositoryProvider).confirmJobCompletionAndRelease(detail.assignmentId);
      ref.invalidate(activeJobDetailProvider(widget.assignmentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0D6548),
            content: Text(l10n?.releaseEscrowSuccess ?? 'Payment successfully released to worker wallet!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Escrow release failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _showWorkerEscrowInfoSheet(BuildContext context, ActiveJobDetail detail) {
    final l10n = AppLocalizations.of(context);
    final wagePaise = detail.agreedWagePaise;
    final commissionPaise = (wagePaise * 5) ~/ 100;
    final workerNetPaise = wagePaise - commissionPaise;
    final wageRupees = (wagePaise / 100).toStringAsFixed(0);
    final commissionRupees = (commissionPaise / 100).toStringAsFixed(2);
    final workerNetRupees = (workerNetPaise / 100).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFB45309), size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.pendingEscrowRelease ?? 'Pending Escrow Release',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            l10n?.escrowEarningsSecured ?? 'Your earnings are 100% secured in escrow',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (detail.protectionSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF047857)),
                            const SizedBox(width: 3),
                            Text(
                              l10n?.protectedBadge ?? 'Protected',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n?.paymentServiceWage ?? 'Service / Wage Amount',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                          Text('₹$wageRupees', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n?.paymentPlatformFee ?? 'Platform Fee'} (5%)',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                          Text('- ₹$commissionRupees', style: const TextStyle(color: Color(0xFFD97706), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n?.workerPayout ?? 'Expected Payout in Wallet',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Text('₹$workerNetRupees', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF15803D))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n?.escrowAutoReleaseNotice ??
                              'Payment will be released as soon as the employer confirms, or automatically within 24 hours if no dispute is raised.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildProviderNoShowBanner(
    BuildContext context,
    ActiveJobDetail detail,
    AppLocalizations? l10n,
  ) {
    final minsLate = detail.minutesPastScheduledArrival;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.arrivalGraceExpiredAlert ?? '⚠️ ARRIVAL GRACE PERIOD EXPIRED',
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      l10n?.workerHasNotArrivedTitle ?? 'Worker Has Not Arrived',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.workerHasNotArrivedSubtitle(
                  detail.workerName,
                  minsLate > 0 ? minsLate : 15,
                  detail.jobTitle,
                ) ??
                '${detail.workerName} is ${minsLate > 0 ? minsLate : 15} minutes past arrival time.',
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              WorkerNotArrivedSheet.show(
                context,
                jobDetail: detail,
                onActionCompleted: () {
                  ref.invalidate(activeJobDetailProvider(widget.assignmentId));
                },
              );
            },
            icon: const Icon(Icons.flash_on_rounded, size: 18),
            label: Text(
              l10n?.openRecoveryEngineAction ?? 'Open No-Show Recovery Engine',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerRunningLateSection(
    BuildContext context,
    ActiveJobDetail detail,
    AppLocalizations? l10n,
  ) {
    final alreadyReported = detail.runningLateReportedAt != null;

    if (alreadyReported) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.runningLateReportedBadge(detail.runningLateEtaMinutes ?? 15) ??
                    'Reported running late (+${detail.runningLateEtaMinutes ?? 15}m). Timer paused.',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n?.runningLateQuestionAction ?? 'Running late? Tap to share ETA',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              RunningLateDialog.show(
                context,
                assignmentId: detail.assignmentId,
                onReported: () {
                  ref.invalidate(activeJobDetailProvider(widget.assignmentId));
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(60, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Share ETA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
