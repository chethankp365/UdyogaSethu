import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/marketplace/data/produce_marketplace_repository.dart';
import 'package:udyogasethu/features/marketplace/domain/lot_traceability_data.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/farm_traceability_modal.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/trust/data/digital_id_repository.dart';
import 'package:udyogasethu/features/trust/domain/digital_id_card.dart';

class ScanVerifyScreen extends ConsumerStatefulWidget {
  const ScanVerifyScreen({super.key});

  @override
  ConsumerState<ScanVerifyScreen> createState() => _ScanVerifyScreenState();
}

class _ScanVerifyScreenState extends ConsumerState<ScanVerifyScreen> with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _hasPermission = true;
  String? _permissionError;
  PublicVerificationResult? _verificationResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasPermission) {
      _checkCameraPermission();
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) setState(() => _hasPermission = true);
    } else if (status.isDenied) {
      final req = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _hasPermission = req.isGranted;
          _permissionError = req.isGranted ? null : 'Camera permission is required to scan ID QR codes.';
        });
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _permissionError = 'Camera permission is permanently denied. Please enable it in Settings.';
        });
      }
    }
  }

  Future<void> _processQrCode(String rawCode) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Check if token or raw text represents a farm produce lot
      final payload = LotTraceabilityData.parseTokenPayload(rawCode);
      if (payload?['pur'] == 'produce_lot' || rawCode.startsWith('LOT-')) {
        final produceRepo = ref.read(produceMarketplaceRepositoryProvider);
        final trace = await produceRepo.getLotTraceability(rawCode);
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          FarmTraceabilityModal.show(context, trace);
        }
        return;
      }

      // 2. Check if token represents a job ticket
      final isTicketCandidate = rawCode.startsWith('TKT-') ||
          rawCode.startsWith('TK-') ||
          rawCode.startsWith('TICKET-') ||
          rawCode.startsWith('BOOK-') ||
          rawCode.contains('TKT-') ||
          rawCode.contains('BOOK-') ||
          payload?['pur'] == 'ticket';

      if (isTicketCandidate) {
        final jobRepo = ref.read(jobExecutionRepositoryProvider);
        final ticketRes = await jobRepo.verifyAttendanceScan(qrToken: rawCode);
        if (mounted) {
          setState(() {
            _isProcessing = false;
            if (ticketRes.valid) {
              _verificationResult = PublicVerificationResult(
                valid: true,
                nameInitial: ticketRes.workerName != null && ticketRes.workerName!.isNotEmpty
                    ? '${ticketRes.workerName![0].toUpperCase()}.'
                    : 'W.',
                displayId: ticketRes.bookingCode ?? 'TICKET',
                isVerifiedBadge: ticketRes.isVerifiedBadge,
                level: 1,
                levelName: 'Verified Worker',
                purpose: 'ticket',
                assignmentId: ticketRes.assignmentId,
                bookingCode: ticketRes.bookingCode,
                workerName: ticketRes.workerName,
                jobTitle: ticketRes.jobTitle,
              );
            } else {
              _verificationResult = PublicVerificationResult.error(
                code: ticketRes.errorCode ?? 'TICKET_INVALID',
                message: ticketRes.errorMessage ?? ticketRes.message ?? 'Ticket verification failed.',
              );
            }
          });
        }
        return;
      }

      // 3. Otherwise verify through digitalId repository
      final repo = ref.read(digitalIdRepositoryProvider);
      var result = await repo.verifyQrToken(rawCode);

      // If digitalId verification rejected format, try ticket scan as fallback
      if (!result.valid && (result.errorCode == 'INVALID_FORMAT' || result.errorCode == 'token_expired' || result.errorCode == 'invalid_token')) {
        try {
          final jobRepo = ref.read(jobExecutionRepositoryProvider);
          final ticketRes = await jobRepo.verifyAttendanceScan(qrToken: rawCode);
          if (ticketRes.valid) {
            result = PublicVerificationResult(
              valid: true,
              nameInitial: ticketRes.workerName != null && ticketRes.workerName!.isNotEmpty
                  ? '${ticketRes.workerName![0].toUpperCase()}.'
                  : 'W.',
              displayId: ticketRes.bookingCode ?? 'TICKET',
              isVerifiedBadge: ticketRes.isVerifiedBadge,
              level: 1,
              levelName: 'Verified Worker',
              purpose: 'ticket',
              assignmentId: ticketRes.assignmentId,
              bookingCode: ticketRes.bookingCode,
              workerName: ticketRes.workerName,
              jobTitle: ticketRes.jobTitle,
            );
          }
        } catch (_) {}
      }

      // If backend returned produce_lot verification:
      if (result.purpose == 'produce_lot') {
        final produceRepo = ref.read(produceMarketplaceRepositoryProvider);
        final trace = await produceRepo.getLotTraceability(rawCode);
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          FarmTraceabilityModal.show(context, trace);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _verificationResult = result;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verificationResult = PublicVerificationResult.error(
            code: 'scan_error',
            message: e.toString().replaceAll('Exception: ', ''),
          );
          _isProcessing = false;
        });
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _verificationResult = null;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan to Verify', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Toggle Flash',
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Scanner Area or Permission Error
          Expanded(
            flex: 5,
            child: !_hasPermission
                ? _buildPermissionDeniedWidget()
                : _verificationResult != null
                    ? _buildResultView()
                    : Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              if (_isProcessing || _verificationResult != null) return;
                              final barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final code = barcode.rawValue;
                                if (code != null && code.isNotEmpty) {
                                  _processQrCode(code);
                                  break;
                                }
                              }
                            },
                          ),
                          // Viewfinder Reticle Overlay
                          _buildReticleOverlay(),
                          if (_isProcessing)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white),
                                    SizedBox(height: 16),
                                    Text(
                                      'Verifying cryptographic token...',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
          ),

          // Bottom Controls & Single-Phone Testing Helpers
          if (_verificationResult == null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Point camera at the worker\'s Digital ID QR code on their phone screen.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReticleOverlay() {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withAlpha(200), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Scan UdyogaSethu QR',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 54, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _permissionError ?? 'Please grant camera access to scan and verify worker ID cards before entering premises.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Open App Settings'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerGreenDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final res = _verificationResult!;
    final isValid = res.valid;
    final isBadge = res.isVerifiedBadge;

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isValid
                        ? (isBadge ? Colors.green.shade400 : Colors.amber.shade400)
                        : Colors.red.shade400,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // Status Badge Icon
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isValid
                            ? (isBadge ? Colors.green.shade50 : Colors.amber.shade50)
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isValid
                            ? (isBadge ? Icons.verified_user_rounded : Icons.shield_outlined)
                            : Icons.gpp_bad_rounded,
                        size: 48,
                        color: isValid
                            ? (isBadge ? Colors.green : Colors.amber.shade800)
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      isValid
                          ? (res.purpose == 'ticket'
                              ? 'Attendance Confirmed • Worker Arrived'
                              : (isBadge ? 'UdyogaSethu Verified Worker' : 'Registered Worker (Unverified)'))
                          : 'Verification Rejected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isValid ? AppColors.textDark : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    if (!isValid) ...[
                      Text(
                        res.errorMessage ?? 'Invalid, tampered, or expired QR code.',
                        style: const TextStyle(fontSize: 13, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Do not permit access until the worker presents an authentic, active ID code.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Text(
                        res.purpose == 'ticket'
                            ? 'Attendance recorded on site at ${res.verifiedAt != null ? res.verifiedAt!.toLocal().toString().split('.').first : "just now"}'
                            : 'Public Credential Status (Zero Personal Data Shared)',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      if (res.purpose == 'ticket') ...[
                        if (res.workerName != null)
                          _buildInfoRow('Worker Name', res.workerName!),
                        if (res.bookingCode != null)
                          _buildInfoRow('Booking Code', res.bookingCode!),
                        if (res.jobTitle != null)
                          _buildInfoRow('Job Title', res.jobTitle!),
                        _buildInfoRow(
                          'Status',
                          'Arrived on Site ✓',
                          color: AppColors.emeraldPrimary,
                        ),
                      ] else ...[
                        // Public Non-PII Fields
                        _buildInfoRow('Worker Name', '${res.nameInitial} (Verified Initial)'),
                        _buildInfoRow('Public ID', res.displayId),
                        _buildInfoRow('Skill Level', 'Level ${res.level} • ${res.levelName}'),
                        _buildInfoRow(
                          'Verified Badge',
                          isBadge ? 'Active ✓' : 'Incomplete',
                          color: isBadge ? Colors.green : Colors.amber.shade800,
                        ),
                        if (res.kycVerifiedAt != null)
                          _buildInfoRow('eKYC Verified', res.kycVerifiedAt!.toLocal().toString().split(' ').first),
                        if (res.faceVerifiedAt != null)
                          _buildInfoRow('Face Liveness', res.faceVerifiedAt!.toLocal().toString().split(' ').first),
                        if (res.trainingVerifiedAt != null)
                          _buildInfoRow('Safety Training', res.trainingVerifiedAt!.toLocal().toString().split(' ').first),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (res.purpose == 'ticket' && res.assignmentId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _resetScanner();
                      Navigator.of(context).pushNamed('/jobs/active/${res.assignmentId}');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Open Active Job Screen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Scan Again Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan Another Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
