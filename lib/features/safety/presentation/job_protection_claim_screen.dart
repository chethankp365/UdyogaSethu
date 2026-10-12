// Screen: JobProtectionClaimScreen (Step P7.3)
// Simulated Job Protection Claim with real eligibility checklist from assignment data

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/features/safety/data/safety_repository.dart';
import 'package:udyogasethu/features/safety/domain/protection_claim.dart';

final submittedClaimsProvider =
    FutureProvider.autoDispose<List<ProtectionClaim>>((ref) async {
  final repo = ref.watch(safetyRepositoryProvider);
  return repo.getSubmittedClaims();
});

class JobProtectionClaimScreen extends ConsumerStatefulWidget {
  final String? initialAssignmentId;

  const JobProtectionClaimScreen({
    super.key,
    this.initialAssignmentId,
  });

  @override
  ConsumerState<JobProtectionClaimScreen> createState() =>
      _JobProtectionClaimScreenState();
}

class _JobProtectionClaimScreenState
    extends ConsumerState<JobProtectionClaimScreen> {
  final _amountController = TextEditingController(text: '3500');
  final _detailsController = TextEditingController();
  String _selectedClaimType = 'Accidental Injury on Site';
  String _selectedAssignmentId = 'demo_asg_01';
  bool _isCheckingEligibility = false;
  ClaimEligibilityResult? _eligibility;
  bool _isSubmitting = false;
  ProtectionClaim? _submittedClaim;

  final List<String> _claimTypes = [
    'Accidental Injury on Site',
    'Equipment Damage during Work',
    'Unsafe Working Conditions',
    'Medical Emergency Treatment',
    'Emergency Transit Loss',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAssignmentId = widget.initialAssignmentId ?? 'demo_asg_01';
    _checkEligibility();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    setState(() => _isCheckingEligibility = true);
    try {
      final repo = ref.read(safetyRepositoryProvider);
      final res = await repo.checkClaimEligibility(_selectedAssignmentId);
      if (mounted) {
        setState(() {
          _eligibility = res;
          _isCheckingEligibility = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingEligibility = false);
    }
  }

  Future<void> _submitClaim() async {
    final amountRupees = int.tryParse(_amountController.text.trim()) ?? 0;
    final details = _detailsController.text.trim();

    if (amountRupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid claim amount.')),
      );
      return;
    }

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide incident details.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(safetyRepositoryProvider);
      final claim = await repo.submitProtectionClaim(
        assignmentId: _selectedAssignmentId,
        claimType: _selectedClaimType,
        amountPaise: amountRupees * 100,
        details: details,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submittedClaim = claim;
        });
        ref.invalidate(submittedClaimsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Job Protection Claim'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent Demo Mode Banner (Honesty Protocol)
            _buildDemoBanner(),
            const SizedBox(height: AppSpacing.md),

            if (_submittedClaim != null) ...[
              _buildSuccessCard(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Eligibility Gate Checklist
            _buildEligibilitySection(),
            const SizedBox(height: AppSpacing.lg),

            // Claim Submission Form
            _buildClaimForm(),
            const SizedBox(height: AppSpacing.xl),

            // Past Submitted Claims List
            _buildPastClaimsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo mode: real cover needs a licensed insurance partner',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'This claim simulator checks real on-site criteria (QR attendance, GPS/selfie verification, time log) and registers claims in demo mode for administrative audit.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilitySection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'On-Site Eligibility Verification',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (_isCheckingEligibility)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Escrow job protection checks four automated gates before approving claims:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_eligibility != null) ...[
              _buildGateRow(
                '1. QR Ticket Attendance',
                _eligibility!.qrOk,
                'Verified check-in scan on employer device',
              ),
              _buildGateRow(
                '2. Selfie & GPS Verification',
                _eligibility!.selfieGpsOk,
                'Facial photo match within worksite geofence',
              ),
              _buildGateRow(
                '3. Work Timer Log',
                _eligibility!.timerOk,
                'Minimum 5 min active duration logged (${_eligibility!.durationMinutes} min elapsed)',
              ),
              _buildGateRow(
                '4. Incident Photos / Evidence',
                _eligibility!.evidenceOk,
                _eligibility!.evidenceOk
                    ? '${_eligibility!.evidenceCount} photo(s) or dispute report attached'
                    : 'Attach medical bill or photos with this claim',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGateRow(String title, bool isPassed, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel_outlined,
            color: isPassed ? const Color(0xFF059669) : const Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isPassed ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimForm() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'File a Protection Claim',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.md),

            // Claim Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedClaimType,
              decoration: const InputDecoration(
                labelText: 'Nature of Incident',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _claimTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedClaimType = val);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Amount Field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Claim Amount (₹)',
                hintText: 'e.g. 3500 (Max ₹25,000)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Details Field
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Incident Description & Medical Details',
                hintText: 'Describe what happened on-site and required first aid...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              label: _isSubmitting ? 'Submitting Claim...' : 'Submit Claim for Review',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitClaim,
              icon: Icons.send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    final claim = _submittedClaim!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF059669), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Claim Submitted (${claim.claimCode})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your claim of ₹${(claim.amountPaise / 100).toStringAsFixed(0)} for "${claim.claimType}" was registered in Demo Mode for safety audit.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF047857), height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildPastClaimsSection() {
    final claimsAsync = ref.watch(submittedClaimsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Claims History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.sm),
        claimsAsync.when(
          data: (claims) {
            if (claims.isEmpty) {
              return const Text(
                'No previous claims filed.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              );
            }
            return Column(
              children: claims.map((c) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    title: Text(c.claimType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Code: ${c.claimCode} • Status: ${c.status}'),
                    trailing: Text(
                      '₹${(c.amountPaise / 100).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D6548)),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, _) => Text('Error loading history: $err'),
        ),
      ],
    );
  }
}
