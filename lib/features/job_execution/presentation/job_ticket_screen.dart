import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:udyogasethu/core/services/routing_service.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class JobTicketScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const JobTicketScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<JobTicketScreen> createState() => _JobTicketScreenState();
}

class _JobTicketScreenState extends ConsumerState<JobTicketScreen> {
  Timer? _countdownTimer;
  Timer? _autoRefreshTimer;
  int _secondsRemaining = 120;
  bool _isRefreshing = false;
  String? _currentToken;
  DateTime? _expiresAt;
  bool _isOfflineNotice = false;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _triggerAutoRefresh();
      }
    });

    // Auto-refresh token every 100 seconds
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 100), (timer) {
      if (mounted) {
        _triggerAutoRefresh();
      }
    });
  }

  Future<void> _triggerAutoRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      final res = await repo.refreshTicketQr(widget.assignmentId);
      if (mounted) {
        setState(() {
          _currentToken = res['qr_token'] as String?;
          _secondsRemaining = (res['expires_in_seconds'] as num?)?.toInt() ?? 120;
          if (res['expires_at'] != null) {
            _expiresAt = DateTime.tryParse(res['expires_at'].toString());
          }
          _isOfflineNotice = false;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      bool trulyOffline = false;
      try {
        final conn = await Connectivity().checkConnectivity();
        trulyOffline = conn.contains(ConnectivityResult.none);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isOfflineNotice = trulyOffline;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(jobTicketProvider(widget.assignmentId));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B), // Premium midnight background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n?.ticketScreenTitle ?? 'Digital Job Ticket',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: l10n?.refreshTicketTooltip ?? 'Refresh Ticket QR',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _triggerAutoRefresh,
          ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.emeraldPrimary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(jobTicketProvider(widget.assignmentId)),
                  child: Text(l10n?.retry ?? 'Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (ticket) {
          final qrData = _currentToken ?? ticket.qrToken ?? 'TICKET-${ticket.bookingCode}';
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                if (_isOfflineNotice)
                  _buildOfflineNoticeBanner(context, ticket),
                const SizedBox(height: 12),
                _buildTicketCard(context, ticket, qrData),
                const SizedBox(height: 20),
                _buildSecurityExplanation(context),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineNoticeBanner(BuildContext context, JobTicketData ticket) {
    final l10n = AppLocalizations.of(context);
    final expiryTime = _expiresAt ?? ticket.qrExpiresAt;
    final expiryFormatted = expiryTime != null ? DateFormat('h:mm:ss a').format(expiryTime.toLocal()) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF422006),
        border: Border.all(color: Colors.amber.shade700),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.ticketOfflineNotice ??
                      'Online connection required to refresh security token. Please reconnect before employer scan.',
                  style: const TextStyle(color: Color(0xFFFEF3C7), fontSize: 13, height: 1.3),
                ),
                if (expiryFormatted != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last token expiry: $expiryFormatted',
                    style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, JobTicketData ticket, String qrData) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('EEE, d MMM yyyy • h:mm a');
    final formattedDate = dateFormat.format(ticket.startAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header: Booking Code & Status Chip
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.ticketBookingPassHeader ?? 'BOOKING PASS',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: ticket.bookingCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n?.bookingCodeCopied ?? 'Booking code copied'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            ticket.bookingCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(context, ticket.status),
              ],
            ),
          ),

          // Worker & Job Details Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Worker Profile Row
                Row(
                  children: [
                    UserAvatar(
                      avatarPath: ticket.workerAvatar,
                      name: ticket.workerName,
                      radius: 25,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ticket.workerName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (ticket.isWorkerVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 18, color: AppColors.emeraldPrimary),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ticket.workerSeekerType == 'student'
                                ? 'Student Worker'
                                : ticket.workerSeekerType == 'part_time'
                                    ? 'Part-Time Worker'
                                    : 'Verified Skilled Worker',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),

                // Job Role & Employer Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.work_outline, color: AppColors.emeraldPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.jobTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Employer: ${ticket.providerName}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Schedule & Wage Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Text(
                                '${ticket.estDurationMinutes ~/ 60} hrs estimated',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                          Text(
                            ticket.formattedWage,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emeraldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (ticket.addressText != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.addressText!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map, size: 20, color: AppColors.emeraldPrimary),
                        tooltip: 'Open in Maps',
                        onPressed: () {
                          RoutingService.openExternalMaps(
                            destination: LatLng(
                              ticket.lat ?? 12.9716,
                              ticket.lng ?? 77.5946,
                            ),
                            label: ticket.addressText,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Perforated Cutout Separator
          _buildPerforatedDivider(),

          // QR Code Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                Text(
                  l10n?.ticketScanInstructions ?? 'Present this QR pass to your employer upon site arrival',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),

                // QR Code Container with Frame
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: true,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F172A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Countdown Timer Ring
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        value: _secondsRemaining / 120.0,
                        strokeWidth: 3,
                        color: _secondsRemaining < 20 ? Colors.red : AppColors.emeraldPrimary,
                        backgroundColor: const Color(0xFFE2E8F0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${l10n?.ticketAutoRefreshesIn ?? 'Refreshes in'} ${_secondsRemaining}s',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _secondsRemaining < 20 ? Colors.red : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerforatedDivider() {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed line
          Positioned(
            left: 20,
            right: 20,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dashCount = (constraints.maxWidth / 10).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (_) => const SizedBox(
                      width: 5,
                      height: 1.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Left cutout notch
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF0B132B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right cutout notch
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF0B132B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color bg = const Color(0xFF1E293B);
    Color fg = Colors.white;
    String label = status.toUpperCase();

    if (status == 'ticket_issued') {
      bg = const Color(0xFF0284C7);
      label = 'TICKET ISSUED';
    } else if (status == 'arrived') {
      bg = const Color(0xFF0D9488);
      label = 'ARRIVED';
    } else if (status == 'verification_completed' || status == 'in_progress_verified') {
      bg = AppColors.emeraldPrimary;
      label = 'ACTIVE';
    } else if (status == 'completed') {
      bg = const Color(0xFF10B981);
      label = 'COMPLETED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSecurityExplanation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security_outlined, color: AppColors.emeraldPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.ticketReplayShieldTitle ?? 'Replay Protection Enabled',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n?.ticketReplayShieldBody ??
                      'This dynamic security pass is single-use and auto-refreshes every 2 minutes. Screenshots cannot be replayed or scanned more than once.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
