import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';
import 'package:udyogasethu/features/trust/domain/verification_visibility.dart';

class StudentVerificationScreen extends ConsumerStatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  ConsumerState<StudentVerificationScreen> createState() => _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends ConsumerState<StudentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _collegeController = TextEditingController();
  final _courseController = TextEditingController();
  final _usnController = TextEditingController();

  XFile? _cardImage;
  bool _isUploading = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  String _getUserId() {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client.auth.currentUser?.id ?? 'demo_user_123';
      }
    } catch (_) {}
    return 'demo_user_123';
  }

  @override
  void dispose() {
    _collegeController.dispose();
    _courseController.dispose();
    _usnController.dispose();
    super.dispose();
  }

  Future<void> _pickCardImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                title: const Text('Take Photo (Camera)', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  _captureImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  _captureImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        setState(() => _cardImage = image);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to select ID card photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _getUserId();
    final repo = ref.watch(kycRepositoryProvider);
    final session = ref.watch(appSessionProvider);

    final isEligible = isVerificationItemVisible(
      type: VerificationType.student,
      role: session.activeRole,
      seekerType: session.seekerType,
    );

    final isStillLoading = session.activeRole == UserRole.seeker &&
        !session.seekerTypeLoaded &&
        session.seekerType == null;

    if (!isStillLoading && !isEligible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student verification is only available for student job seekers.')),
          );
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyCard,
        title: const Text('Student Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<KycRecord?>(
        stream: repo.watchKycRecord(userId, docType: 'college_id'),
        builder: (context, snapshot) {
          final kycRecord = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy Notice Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade400),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.lightBlueAccent, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Strict Student Data Privacy',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'All student documents and USN records remain strictly private. They are never shared publicly or with employers.',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status Banner
                _buildStatusChipCard(kycRecord),
                const SizedBox(height: 16),

                if (kycRecord == null || kycRecord.isNotRequested || kycRecord.isRejected)
                  _buildFormCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChipCard(KycRecord? record) {
    String chipLabel = 'Not verified (tap to start)';
    Color chipColor = Colors.grey;
    IconData icon = Icons.school_outlined;

    if (record != null) {
      if (record.isVerified) {
        chipLabel = 'Student Status: Verified ✓';
        chipColor = AppColors.emerald;
        icon = Icons.school_rounded;
      } else if (record.isPending) {
        chipLabel = 'Student Status: Pending Verification';
        chipColor = AppColors.amberOrange;
        icon = Icons.hourglass_top_rounded;
      } else if (record.isRejected) {
        chipLabel = 'Student Status: Rejected';
        chipColor = AppColors.errorRed;
        icon = Icons.error_outline_rounded;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: chipColor, size: 24),
              const SizedBox(width: 10),
              Text(
                chipLabel,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: chipColor),
              ),
            ],
          ),
          if (record?.maskedId != null)
            Text(record!.maskedId!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'College / Academic Verification Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 14),

            // College Name
            TextFormField(
              controller: _collegeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'College / University Name',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: AppColors.navyCardSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'College name is required' : null,
            ),
            const SizedBox(height: 14),

            // Course Name
            TextFormField(
              controller: _courseController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Course / Degree (e.g. B.E / B.Sc / Diploma)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: AppColors.navyCardSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Course name is required' : null,
            ),
            const SizedBox(height: 14),

            // USN / Reg No
            TextFormField(
              controller: _usnController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'USN / Registration Number (Will be stored masked)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: AppColors.navyCardSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'USN / Reg No is required' : null,
            ),
            const SizedBox(height: 16),

            // Photo Picker Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: _cardImage != null ? AppColors.emerald : AppColors.navyBorder),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onPressed: _pickCardImage,
              icon: Icon(_cardImage != null ? Icons.check_circle : Icons.badge_outlined, color: _cardImage != null ? AppColors.emerald : Colors.white70),
              label: Text(_cardImage != null ? 'Student ID Card Photo Attached' : 'Attach Student ID Card Photo', style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 16),

            if (_isUploading) ...[
              const LinearProgressIndicator(color: AppColors.amberOrange, backgroundColor: AppColors.navyCardSecondary),
              const SizedBox(height: 10),
            ],

            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isUploading ? null : _submitStudent,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Submit Student Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cardImage == null) {
      setState(() => _errorMessage = 'Please attach your Student ID Card photo.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final cardBytes = await _cardImage!.readAsBytes();
      final repo = ref.read(kycRepositoryProvider);

      await repo.submitStudentVerification(
        collegeName: _collegeController.text.trim(),
        courseName: _courseController.text.trim(),
        regUsn: _usnController.text.trim(),
        cardBytes: cardBytes,
      );

      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student verification submitted successfully.')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Submission failed: $e';
      });
    }
  }
}
