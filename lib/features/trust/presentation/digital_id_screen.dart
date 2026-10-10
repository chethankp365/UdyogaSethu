import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/trust/data/digital_id_repository.dart';
import 'package:udyogasethu/features/trust/domain/digital_id_card.dart';

/// State notifier for permanent profile QR visibility (D-QR testing toggle)
class ProfileQrEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => kProfileQrEnabled;

  void setEnabled(bool value) => state = value;
}

final profileQrEnabledProvider = NotifierProvider<ProfileQrEnabledNotifier, bool>(
  ProfileQrEnabledNotifier.new,
);

class DigitalIdScreen extends ConsumerStatefulWidget {
  const DigitalIdScreen({super.key});

  @override
  ConsumerState<DigitalIdScreen> createState() => _DigitalIdScreenState();
}

class _DigitalIdScreenState extends ConsumerState<DigitalIdScreen> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  DigitalIdCardData? _idCard;
  Map<String, dynamic>? _nextTicket;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  Timer? _countdownTimer;
  int _secondsLeft = 300;
  int _totalDurationSeconds = 300;

  // Next accepted assignment rotating ticket QR state (E8)
  String? _ticketQrToken;
  int _ticketSecondsLeft = 120;
  Timer? _ticketCountdownTimer;

  @override
  void initState() {
    super.initState();
    _loadDigitalId();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _ticketCountdownTimer?.cancel();
    super.dispose();
  }

  String _getUserId() {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client.auth.currentUser?.id ?? 'demo-user-id';
      }
    } catch (_) {}
    return 'demo-user-id';
  }

  Future<void> _loadDigitalId() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(digitalIdRepositoryProvider);
      final data = await repo.fetchDigitalId(_getUserId());
      final isQrEnabled = ref.read(profileQrEnabledProvider);

      Map<String, dynamic>? ticket;
      String? ticketToken;
      int ticketLeft = 120;

      try {
        ticket = await ref.read(jobExecutionRepositoryProvider).getNextAcceptedTicket();
        if (ticket != null && ticket['assignment_id'] != null) {
          final aid = ticket['assignment_id'] as String;
          final tokenData = await ref.read(jobExecutionRepositoryProvider).getRotatingTicketToken(aid);
          ticketToken = tokenData['qr_token'] as String?;
          final exp = tokenData['expires_at'] != null ? DateTime.tryParse(tokenData['expires_at'].toString()) : null;
          final ttl = (tokenData['expires_in_seconds'] as num?)?.toInt() ?? 120;
          ticketLeft = exp != null
              ? exp.difference(DateTime.now()).inSeconds.clamp(0, ttl)
              : ttl;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _idCard = data;
          _nextTicket = ticket;
          _ticketQrToken = ticketToken;
          _ticketSecondsLeft = ticketLeft;
          _totalDurationSeconds = data.qrExpiresInSeconds;
          _secondsLeft = data.qrExpiresAt != null
              ? data.qrExpiresAt!.difference(DateTime.now()).inSeconds.clamp(0, data.qrExpiresInSeconds)
              : data.qrExpiresInSeconds;
          _isLoading = false;
        });

        if (ticket != null && ticket['assignment_id'] != null) {
          _startTicketCountdown(ticket['assignment_id'] as String);
        }

        if (isQrEnabled) {
          _startCountdown();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _startTicketCountdown(String assignmentId) {
    _ticketCountdownTimer?.cancel();
    _ticketCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_ticketSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _ticketSecondsLeft = 0;
        });
        try {
          final tokenData = await ref.read(jobExecutionRepositoryProvider).getRotatingTicketToken(assignmentId);
          if (mounted) {
            final newToken = tokenData['qr_token'] as String?;
            final newTtl = (tokenData['expires_in_seconds'] as num?)?.toInt() ?? 120;
            setState(() {
              _ticketQrToken = newToken;
              _ticketSecondsLeft = newTtl;
            });
            _startTicketCountdown(assignmentId);
          }
        } catch (_) {}
      } else {
        setState(() {
          _ticketSecondsLeft--;
        });
      }
    });
  }

  Future<void> _refreshQrToken() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });

    try {
      final repo = ref.read(digitalIdRepositoryProvider);
      final res = await repo.issueFreshQrToken();
      if (mounted) {
        final newToken = res['qr_token'] as String?;
        final newExpiresAt = res['expires_at'] != null ? DateTime.tryParse(res['expires_at'].toString()) : null;
        final newExpiresInSec = (res['expires_in_seconds'] as num?)?.toInt() ?? 300;

        setState(() {
          _idCard = _idCard?.copyWith(
            qrToken: newToken,
            qrExpiresAt: newExpiresAt,
            qrExpiresInSeconds: newExpiresInSec,
          );
          _totalDurationSeconds = newExpiresInSec;
          _secondsLeft = newExpiresInSec;
          _isRefreshing = false;
        });
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh QR: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
        // Auto-refresh when expired
        _refreshQrToken();
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _shareCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Digital ID Card image ready. You can present or save this card securely.'),
        backgroundColor: AppColors.headerGreenDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isQrEnabled = ref.watch(profileQrEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital ID Card', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Shareable Card Boundary
                  RepaintBoundary(
                    key: _cardBoundaryKey,
                    child: _buildIdCardWidget(isQrEnabled),
                  ),
                  const SizedBox(height: 20),

                  // QR Countdown & Expiry Progress Indicator (Shown only when QR is enabled)
                  if (isQrEnabled) ...[
                    _buildCountdownSection(),
                    const SizedBox(height: 24),
                  ],

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _shareCard,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share ID Card'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Notice
                  if (isQrEnabled)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.security_rounded, color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Privacy Protection: This QR code contains only a temporary cryptographic token with a 5-minute expiry. It never contains your phone number, Aadhaar number, or personal address.',
                              style: TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildIdCardWidget(bool isQrEnabled) {
    final card = _idCard;
    if (card == null) return const SizedBox.shrink();

    final isVerified = card.isVerifiedBadge;
    final primaryColor = isVerified ? AppColors.headerGreenDark : AppColors.amberOrange;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isVerified ? Colors.green.shade300 : Colors.amber.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isVerified
                    ? [AppColors.headerGreenDark, Colors.teal.shade700]
                    : [AppColors.amberOrange, Colors.deepOrange.shade600],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'UdyogaSethu Digital ID',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isVerified ? 'VERIFIED' : 'PENDING',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Avatar & Core Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatar(
                      avatarPath: card.avatarPath,
                      name: card.fullName,
                      radius: 36,
                      backgroundColor: primaryColor.withAlpha(30),
                      textColor: primaryColor,
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
                                  card.fullName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: Colors.green, size: 18),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            card.roleName,
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  card.displayId,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Text(
                                  'Level ${card.level} • ${card.levelName}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),

                if (_nextTicket != null) ...[
                  // Next Job Ticket Section (E8)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.headerGreenDark,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'UPCOMING JOB TICKET',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '#${_nextTicket!['booking_code'] ?? ''}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // QR Code container (tap opens full ticket)
                        InkWell(
                          onTap: () {
                            context.push('/jobs/ticket/${_nextTicket!['assignment_id']}');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _ticketQrToken != null
                                ? QrImageView(
                                    data: _ticketQrToken!,
                                    version: QrVersions.auto,
                                    size: 160,
                                  )
                                : const SizedBox(
                                    width: 160,
                                    height: 160,
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              'QR refreshes in ${_formatTime(_ticketSecondsLeft)}',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Job details directly under QR (E8)
                        Text(
                          _nextTicket!['job_title'] as String? ?? 'Upcoming Job',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (_nextTicket!['start_at'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Shift Time: ${DateFormat('EEE, d MMM • h:mm a').format(DateTime.tryParse(_nextTicket!['start_at'].toString())?.toLocal() ?? DateTime.now())}',
                            style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Employer: ${_nextTicket!['provider_name'] ?? 'Job Provider'}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.headerGreenDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Open Full Ticket & Route', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              context.push('/jobs/ticket/${_nextTicket!['assignment_id']}');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isQrEnabled) ...[
                  // Identity Verification QR Code
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: card.qrToken != null
                        ? QrImageView(
                            data: card.qrToken!,
                            version: QrVersions.auto,
                            size: 190,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: isVerified ? Colors.teal.shade900 : AppColors.textDark,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: isVerified ? AppColors.headerGreenDark : AppColors.textDark,
                            ),
                          )
                        : const SizedBox(
                            height: 190,
                            width: 190,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan to verify identity and trust credentials',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                ] else ...[
                  // Clean No Active Ticket Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50.withAlpha(150),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueGrey.shade100, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueGrey.withAlpha(30),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.confirmation_number_outlined, size: 44, color: AppColors.headerGreenDark),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No Active Job Ticket',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'When a job provider accepts your application, your live digital check-in QR ticket will appear here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.headerGreenDark,
                            side: const BorderSide(color: AppColors.cardBorderGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.search_rounded, size: 16),
                          label: const Text('Browse Available Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            context.push('/seeker/jobs');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection() {
    final progress = _totalDurationSeconds > 0 ? (_secondsLeft / _totalDurationSeconds) : 0.0;
    final isLow = _secondsLeft <= 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLow ? Colors.red.shade200 : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_rounded,
                size: 18,
                color: isLow ? Colors.red : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Token validity: ${_formatTime(_secondsLeft)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isLow ? Colors.red : AppColors.textDark,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _isRefreshing ? null : _refreshQrToken,
                icon: _isRefreshing
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh QR', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLow ? Colors.red : AppColors.headerGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
