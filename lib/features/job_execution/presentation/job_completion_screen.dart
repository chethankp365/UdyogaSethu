import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class JobCompletionScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const JobCompletionScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<JobCompletionScreen> createState() => _JobCompletionScreenState();
}

class _JobCompletionScreenState extends ConsumerState<JobCompletionScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();

  File? _completionSelfie;
  final List<File> _workPhotos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takeCompletionSelfie() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 720,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _completionSelfie = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _addWorkPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _workPhotos.add(File(picked.path)));
      }
    } catch (_) {}
  }

  void _removeWorkPhoto(int index) {
    setState(() => _workPhotos.removeAt(index));
  }

  Future<void> _submitCompletion() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(jobExecutionRepositoryProvider);

      double? lat;
      double? lng;
      bool isMocked = false;

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(timeLimit: Duration(seconds: 3)),
        );
        lat = pos.latitude;
        lng = pos.longitude;
        isMocked = pos.isMocked;
      } catch (_) {}

      // 1. Upload completion selfie
      String? selfiePath;
      if (_completionSelfie != null) {
        final bytes = await _completionSelfie!.readAsBytes();
        selfiePath = await repo.uploadJobEvidence(
          assignmentId: widget.assignmentId,
          fileBytes: bytes,
          fileName: 'completion_selfie.jpg',
        );
      }

      // 2. Upload work evidence photos
      final List<String> uploadedPhotoPaths = [];
      for (int i = 0; i < _workPhotos.length; i++) {
        final bytes = await _workPhotos[i].readAsBytes();
        final path = await repo.uploadJobEvidence(
          assignmentId: widget.assignmentId,
          fileBytes: bytes,
          fileName: 'work_evidence_$i.jpg',
        );
        uploadedPhotoPaths.add(path);
      }

      // 3. Call completeJob API
      final res = await repo.completeJob(
        assignmentId: widget.assignmentId,
        lat: lat,
        lng: lng,
        isMocked: isMocked,
        selfiePath: selfiePath,
        workPhotos: uploadedPhotoPaths,
      );

      if (!mounted) return;

      if (res.success) {
        ref.invalidate(activeJobDetailProvider(widget.assignmentId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0D6548),
            content: Text('Job Completed! Payment is now eligible for release.'),
            duration: Duration(seconds: 3),
          ),
        );
        context.pop();
      } else {
        setState(() => _isSubmitting = false);
        _showErrorDialog(res.errorMessage ?? 'Completion failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.verificationFailed ?? 'Verification Refused'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.retry ?? 'Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(activeJobDetailProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.completionTitle ?? 'Verified Job Completion',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (detail) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.headerGreenDark.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline, color: AppColors.headerGreenDark, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.jobTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n?.completionSubtitle ??
                                  'Capture your final completion selfie and work-result evidence photos.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Step 1: Completion Selfie Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.face, size: 20, color: AppColors.headerGreenDark),
                          SizedBox(width: 8),
                          Text(
                            'Completion Selfie',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: GestureDetector(
                          onTap: _takeCompletionSelfie,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _completionSelfie != null ? AppColors.headerGreenDark : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                            ),
                            child: _completionSelfie != null
                                ? ClipOval(child: Image.file(_completionSelfie!, fit: BoxFit.cover))
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, size: 36, color: Color(0xFF64748B)),
                                      SizedBox(height: 6),
                                      Text(
                                        'Take Selfie',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Step 2: Work Result Evidence Photos Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 20, color: AppColors.headerGreenDark),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.workResultPhotos ?? 'Work-Result Evidence Photos (Private)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...List.generate(_workPhotos.length, (index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _workPhotos[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeWorkPhoto(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          GestureDetector(
                            onTap: _addWorkPhoto,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined, size: 24, color: Color(0xFF64748B)),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n?.addWorkPhoto ?? 'Add Photo',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Submit Completion Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreenDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSubmitting ? null : _submitCompletion,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            l10n?.completeAndSubmit ?? 'Submit & Complete Job',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
