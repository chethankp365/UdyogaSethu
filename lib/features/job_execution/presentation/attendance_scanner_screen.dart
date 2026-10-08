import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/job_ticket.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class AttendanceScannerScreen extends ConsumerStatefulWidget {
  final String? initialAssignmentId;
  final bool? testHasPermission;

  const AttendanceScannerScreen({
    super.key,
    this.initialAssignmentId,
    this.testHasPermission,
  });

  @override
  ConsumerState<AttendanceScannerScreen> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends ConsumerState<AttendanceScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _hasPermission = true;
  bool _isTorchOn = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.testHasPermission != null) {
      _hasPermission = widget.testHasPermission!;
    } else {
      _checkCameraPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasPermission && widget.testHasPermission == null) {
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
          _permissionError = req.isGranted ? null : 'Camera permission is required to scan attendance tickets.';
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

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      if (mounted) {
        setState(() => _isTorchOn = !_isTorchOn);
      }
    } catch (_) {}
  }

  Future<void> _processScannedCode(String rawCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    double? lat;
    double? lng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 3),
        ),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);
      final result = await repo.verifyAttendanceScan(
        qrToken: rawCode,
        lat: lat,
        lng: lng,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showResultSheet(result);
      }
    } catch (e) {
      if (mounted) {
        final errResult = AttendanceScanResult.error(
          code: 'network_error',
          message: e.toString().replaceAll('Exception: ', ''),
        );
        setState(() {
          _isProcessing = false;
        });
        _showResultSheet(errResult);
      }
    }
  }

  void _showResultSheet(AttendanceScanResult result) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        if (!result.valid) {
          // Failure Sheet (Expired, Already used, Unauthorized)
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  result.errorCode == 'token_already_used'
                      ? (l10n?.ticketReplayRefusedTitle ?? 'Replay Refused')
                      : result.errorCode == 'token_expired'
                          ? (l10n?.ticketExpiredTitle ?? 'Ticket Expired')
                          : (l10n?.attendanceScanFailedTitle ?? 'Attendance Scan Failed'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  result.errorMessage ?? 'Unable to verify QR ticket.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resetScanner();
                    },
                    child: Text(
                      l10n?.scanAgain ?? 'Scan Again',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Success Sheet (Worker Arrived)
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.emeraldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.emeraldPrimary, size: 42),
              ),
              const SizedBox(height: 14),
              Text(
                l10n?.attendanceConfirmedTitle ?? 'Attendance Confirmed!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.workerMarkedArrived ?? 'Worker marked as Arrived on site',
                style: const TextStyle(fontSize: 14, color: AppColors.emeraldPrimary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              // Worker Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      avatarPath: result.workerAvatar,
                      name: result.workerName ?? 'Worker',
                      radius: 28,
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
                                  result.workerName ?? 'Assigned Worker',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (result.isVerifiedBadge) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 18, color: AppColors.emeraldPrimary),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.jobTitle ?? 'Job Assignment',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          if (result.bookingCode != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              result.bookingCode!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetScanner();
                      },
                      child: Text(l10n?.scanDone ?? 'Done'),
                    ),
                  ),
                  if (result.assignmentId != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/jobs/active/${result.assignmentId!}');
                        },
                        child: Text(
                          l10n?.viewActiveJob ?? 'View Active Job',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _resetScanner();
    });
  }

  void _resetScanner() {
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.attendanceScannerTitle ?? 'Attendance Scanner')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _permissionError ?? 'Camera permission required',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: openAppSettings,
                  child: Text(l10n?.openSettings ?? 'Open Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n?.attendanceScannerTitle ?? 'Scan Worker QR',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.amber : Colors.white,
            ),
            tooltip: 'Torch',
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
            tooltip: 'Switch Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.isNotEmpty && !_isProcessing) {
                  _processScannedCode(raw);
                  break;
                }
              }
            },
          ),

          // Viewfinder Frame Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.emeraldPrimary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Instructions Banner
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n?.attendanceScannerInstructions ??
                    'Align worker\'s digital ticket QR code within the frame to verify arrival.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
              ),
            ),
          ),

          // Single-Phone Debug Input Panel (Gated under kDebugMode)
          if (kDebugMode)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildDebugInputCard(context),
            ),
        ],
      ),
    );
  }

  Widget _buildDebugInputCard(BuildContext context) {
    final textController = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛠️ Debug QR Testing Panel',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Paste ticket token...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isNotEmpty) {
                    _processScannedCode(text);
                  }
                },
                child: const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
