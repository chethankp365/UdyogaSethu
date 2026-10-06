import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/trust/data/safety_onboarding_repository.dart';
import 'package:udyogasethu/features/trust/domain/safety_onboarding_status.dart';

class SafetyOnboardingScreen extends ConsumerStatefulWidget {
  const SafetyOnboardingScreen({super.key});

  @override
  ConsumerState<SafetyOnboardingScreen> createState() => _SafetyOnboardingScreenState();
}

class _SafetyOnboardingScreenState extends ConsumerState<SafetyOnboardingScreen> {
  SafetyOnboardingStatus _status = SafetyOnboardingStatus.initial();
  bool _isLoading = true;
  bool _isBooking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  String _getUserId() {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client.auth.currentUser?.id ?? 'demo_user_123';
      }
    } catch (_) {}
    return 'demo_user_123';
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(safetyOnboardingRepositoryProvider);
      final status = await repo.fetchStatus(_getUserId());
      if (mounted) {
        setState(() {
          _status = status;
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

  Future<void> _bookSlot(String eventId) async {
    setState(() {
      _isBooking = true;
    });

    try {
      final repo = ref.read(safetyOnboardingRepositoryProvider);
      final updatedStatus = await repo.bookSlot(eventId);
      if (mounted) {
        setState(() {
          _status = updatedStatus;
          _isBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Training slot booked successfully! System reminder set.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _simulateStatus(String targetStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(safetyOnboardingRepositoryProvider);
      final updatedStatus = await repo.simulateStatus(_getUserId(), targetStatus);
      if (mounted) {
        setState(() {
          _status = updatedStatus;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo Mode: Status set to "$targetStatus"'),
            backgroundColor: AppColors.amberOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulation error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Onboarding', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Notice if present
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Main Program Card
                    _buildMainProgramCard(),
                    const SizedBox(height: 16),

                    // Slot Booking Card
                    _buildSlotBookingCard(),
                    const SizedBox(height: 16),

                    // Verified Badge 4-Ticks Card
                    _buildVerifiedBadgeCard(),
                    const SizedBox(height: 16),

                    // 4 Training Modules Section
                    const Text(
                      'Training Modules',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    _buildTrainingModuleCard(
                      number: '1',
                      title: 'Site Safety and PPE',
                      explainer: 'Mandatory protective gear: helmet, steel-toe boots, hi-vis vest, and harness safety protocols on active job sites.',
                      icon: Icons.construction_rounded,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(height: 10),
                    _buildTrainingModuleCard(
                      number: '2',
                      title: 'Conduct Rules',
                      explainer: 'Workplace ethics: strict punctuality, zero substance tolerance, respectful communication, and dispute escalation.',
                      icon: Icons.gavel_rounded,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 10),
                    _buildTrainingModuleCard(
                      number: '3',
                      title: 'QR Ticket Pass',
                      explainer: 'Attendance verification: scan provider QR code on site to issue daily work pass and log clock-in timestamps.',
                      icon: Icons.qr_code_scanner_rounded,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(height: 10),
                    _buildTrainingModuleCard(
                      number: '4',
                      title: 'Selfie/GPS Check',
                      explainer: 'Geofenced arrival: live face selfie combined with GPS location radius verification prior to start of shift.',
                      icon: Icons.person_pin_circle_rounded,
                      color: AppColors.headerGreenDark,
                    ),
                    const SizedBox(height: 20),

                    // Quick Links to Digital ID & Trust Centre
                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.badge_rounded, color: AppColors.headerGreenDark),
                            title: const Text('My Digital ID Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('View your expiring QR verification pass', style: TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push(AppRoutes.digitalId),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const Icon(Icons.security_rounded, color: Colors.teal),
                            title: const Text('Trust & Safety Centre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Learn about verified worker benefits & protections', style: TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push(AppRoutes.trustSafetyCentre),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Debug Simulation Panel (gated strictly under kDebugMode)
                    if (kDebugMode) ...[
                      _buildDebugPanel(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainProgramCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.headerGreenDark.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.headerGreenDark, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UdyogaSethu Safety Onboarding',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Complete registration, KYC and 1-day training to get verified',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            const Text(
              'Program Lifecycle Status',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),

            // Lifecycle Chip Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLifecycleChip(
                    label: 'Not Booked',
                    stage: 'not_booked',
                    currentStatus: _status.registrationStatus,
                    icon: Icons.radio_button_unchecked_rounded,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  _buildLifecycleChip(
                    label: 'Slot Booked',
                    stage: 'registered',
                    currentStatus: _status.registrationStatus,
                    icon: Icons.event_available_rounded,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  _buildLifecycleChip(
                    label: 'Attended',
                    stage: 'attended',
                    currentStatus: _status.registrationStatus,
                    icon: Icons.how_to_reg_rounded,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  _buildLifecycleChip(
                    label: 'Document Review',
                    stage: 'document_review',
                    currentStatus: _status.registrationStatus,
                    icon: Icons.assignment_rounded,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  _buildLifecycleChip(
                    label: 'Approved',
                    stage: 'approved',
                    currentStatus: _status.registrationStatus,
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleChip({
    required String label,
    required String stage,
    required String currentStatus,
    required IconData icon,
  }) {
    final stagesOrder = ['not_booked', 'registered', 'attended', 'document_review', 'approved'];
    final currentIndex = stagesOrder.indexOf(currentStatus);
    final stageIndex = stagesOrder.indexOf(stage);

    final isCurrent = currentStatus == stage;
    final isCompleted = currentIndex >= stageIndex && stageIndex >= 0;

    Color bg;
    Color fg;
    BorderSide border;

    if (isCurrent) {
      bg = AppColors.headerGreenDark;
      fg = Colors.white;
      border = BorderSide.none;
    } else if (isCompleted) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      border = BorderSide(color: Colors.green.shade300);
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade600;
      border = BorderSide(color: Colors.grey.shade300);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.fromBorderSide(border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted && !isCurrent ? Icons.check_circle_rounded : icon,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotBookingCard() {
    final hasBooked = _status.registrationStatus != 'not_booked';
    final event = _status.event;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: AppColors.amberOrange, size: 20),
                SizedBox(width: 8),
                Text(
                  '1-Day Onboarding Training Slot',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event?.title ?? 'Worksite Safety & PPE Onboarding Day',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event?.venue ?? 'Koramangala Community Centre, Bengaluru',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Capacity: ${event?.capacity ?? 50} slots • Language: ${event?.language.toUpperCase() ?? "EN"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (hasBooked) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Slot Registered • Status: ${_status.registrationStatus.toUpperCase().replaceAll('_', ' ')}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBooking || event == null
                      ? null
                      : () => _showBookingConfirmDialog(event.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isBooking
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.how_to_reg_rounded, size: 18),
                  label: Text(_isBooking ? 'Booking Slot...' : 'Book Free Training Slot'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmDialog(String eventId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Slot Booking'),
        content: const Text(
          'Are you sure you want to book a slot for the 1-Day Worksite Safety Onboarding training?\n\n'
          'Attendance is mandatory to complete your document approval and earn the UdyogaSethu Verified Badge.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bookSlot(eventId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerGreenDark),
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadgeCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.headerGreenDark, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Verified Worker Badge (4 Ticks)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const Spacer(),
                if (_status.isVerifiedBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Badge Active',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Earn high-trust employer preference by completing all four core requirements:',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            // Tick 1: Aadhaar eKYC
            _buildTickRow(
              title: '1. Aadhaar eKYC Verification',
              isPassed: _status.kycOk,
              actionLabel: _status.kycOk ? 'Verified' : 'Verify Now',
              onAction: _status.kycOk ? null : () => context.push(AppRoutes.kyc),
            ),
            const Divider(height: 16),

            // Tick 2: Face Liveness Setup
            _buildTickRow(
              title: '2. Face Liveness Template',
              isPassed: _status.faceOk,
              actionLabel: _status.faceOk ? 'Verified' : 'Enroll Face',
              onAction: _status.faceOk ? null : () => context.push(AppRoutes.kycFace),
            ),
            const Divider(height: 16),

            // Tick 3: 1-Day Training Attended
            _buildTickRow(
              title: '3. 1-Day Safety Training',
              isPassed: _status.trainingOk,
              actionLabel: _status.trainingOk ? 'Attended' : 'Book Slot',
              onAction: _status.trainingOk
                  ? null
                  : () {
                      final event = _status.event;
                      if (event != null) _bookSlot(event.id);
                    },
            ),
            const Divider(height: 16),

            // Tick 4: Document Approval
            _buildTickRow(
              title: '4. Document Approval',
              isPassed: _status.docOk,
              actionLabel: _status.docOk ? 'Approved' : 'Pending Review',
              onAction: null,
            ),
            const SizedBox(height: 16),

            // Banner if Badge active
            if (_status.isVerifiedBadge) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, AppColors.headerGreenDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎉 Verified Badge Earned! (+100 XP)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Your profile card now displays the green verified badge across search results and job applications.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTickRow({
    required String title,
    required bool isPassed,
    required String actionLabel,
    required VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Icon(
          isPassed ? Icons.check_circle_rounded : Icons.cancel_outlined,
          color: isPassed ? Colors.green : Colors.amber.shade800,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPassed ? AppColors.textDark : AppColors.textDark.withAlpha(200),
            ),
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPassed ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPassed ? Colors.green.shade800 : AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrainingModuleCard({
    required String number,
    required String title,
    required String explainer,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Module $number: $title',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    explainer,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_rounded, color: AppColors.amberOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Demo Mode: Admin Simulation Tools (P3.6 / P9.2)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Simulate status transitions to test 4-tick badge logic & XP events without web admin console.',
            style: TextStyle(fontSize: 11, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _simulateStatus('attended'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: const Text('1. Simulate Attended', style: TextStyle(fontSize: 11)),
              ),
              ElevatedButton(
                onPressed: () => _simulateStatus('document_review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: const Text('2. Simulate Doc Review', style: TextStyle(fontSize: 11)),
              ),
              ElevatedButton(
                onPressed: () => _simulateStatus('approved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: const Text('3. Simulate Approved (Earn Badge)', style: TextStyle(fontSize: 11)),
              ),
              OutlinedButton(
                onPressed: () => _simulateStatus('not_booked'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
