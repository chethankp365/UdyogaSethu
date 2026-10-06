import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';
import 'package:udyogasethu/features/trust/domain/verification_visibility.dart';

class DrivingLicenceScreen extends ConsumerStatefulWidget {
  const DrivingLicenceScreen({super.key});

  @override
  ConsumerState<DrivingLicenceScreen> createState() => _DrivingLicenceScreenState();
}

class _DrivingLicenceScreenState extends ConsumerState<DrivingLicenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dlController = TextEditingController();
  String _selectedClass = 'LMV / Transport';
  DateTime? _expiryDate;
  XFile? _frontImage;
  XFile? _backImage;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
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
    _dlController.dispose();
    super.dispose();
  }

  bool _validateIndianDl(String val) {
    final clean = val.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    // Indian DL format: 2 state letters + 2 digit RTO + 11 digit year/number (total 15 chars)
    return clean.length >= 12 && clean.length <= 16;
  }

  Future<void> _pickImage(bool isFront) async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          if (isFront) {
            _frontImage = image;
          } else {
            _backImage = image;
          }
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to select image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _getUserId();
    final repo = ref.watch(kycRepositoryProvider);
    final session = ref.watch(appSessionProvider);

    final isEligible = isVerificationItemVisible(
      type: VerificationType.drivingLicence,
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
            const SnackBar(content: Text('Driving licence verification is restricted to job seekers.')),
          );
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyCard,
        title: const Text('Driving Licence Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<KycRecord?>(
        stream: repo.watchKycRecord(userId, docType: 'driving_licence'),
        builder: (context, snapshot) {
          final kycRecord = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navyCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.navyBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.directions_car_rounded, color: AppColors.amberOrange, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Licence-Gated Jobs Verification',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Verification is required to see and apply for Driver and Delivery job categories.',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status Banner if record exists
                if (kycRecord != null && !kycRecord.isNotRequested) ...[
                  _buildStatusBanner(kycRecord),
                  const SizedBox(height: 16),
                ],

                // Form Container
                if (kycRecord == null || kycRecord.isNotRequested || kycRecord.isRejected)
                  _buildFormCard(),

                if (kycRecord != null && kycRecord.isVerified)
                  _buildVerifiedDetails(kycRecord),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(KycRecord record) {
    Color bg = AppColors.navyCard;
    Color border = AppColors.navyBorder;
    IconData icon = Icons.info_outline;
    String statusText = record.status.toUpperCase();

    if (record.isVerified) {
      bg = Colors.green.shade900.withAlpha(100);
      border = Colors.green.shade500;
      icon = Icons.verified_user_rounded;
      statusText = 'VERIFIED ✓';
    } else if (record.isPending) {
      bg = Colors.amber.shade900.withAlpha(100);
      border = Colors.amber.shade500;
      icon = Icons.hourglass_top_rounded;
      statusText = 'PENDING ADMIN REVIEW';
    } else if (record.isRejected) {
      bg = Colors.red.shade900.withAlpha(100);
      border = Colors.red.shade500;
      icon = Icons.error_outline_rounded;
      statusText = 'REJECTED';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                'Status: $statusText',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          if (record.maskedId != null) ...[
            const SizedBox(height: 6),
            Text('Masked Licence ID: ${record.maskedId}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
          if (record.isRejected && record.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Rejection Reason: ${record.rejectionReason}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
          ],
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
              'Driving Licence Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 14),

            // DL Number Input
            TextFormField(
              controller: _dlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Licence Number (e.g. KA-01-2020-1234567)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: AppColors.navyCardSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Licence number is required';
                if (!_validateIndianDl(val)) return 'Enter a valid Indian DL number';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Vehicle Class Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedClass,
              dropdownColor: AppColors.navyCardSecondary,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Vehicle Class',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: AppColors.navyCardSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(value: 'LMV / Transport', child: Text('LMV / Commercial Transport')),
                DropdownMenuItem(value: 'Two-Wheeler', child: Text('Two-Wheeler (MCWG)')),
                DropdownMenuItem(value: 'Heavy Vehicle', child: Text('Heavy Goods / Passenger (HMV)')),
                DropdownMenuItem(value: 'Auto-Rickshaw', child: Text('Three-Wheeler / Auto-Rickshaw')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedClass = val);
              },
            ),
            const SizedBox(height: 14),

            // Expiry Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
                );
                if (picked != null) {
                  setState(() => _expiryDate = picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Licence Expiry Date',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.navyCardSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _expiryDate != null
                      ? _expiryDate!.toLocal().toString().split(' ').first
                      : 'Select Expiry Date',
                  style: TextStyle(color: _expiryDate != null ? Colors.white : Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Upload Photos (Private Storage Bucket)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: _frontImage != null ? AppColors.emerald : AppColors.navyBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _pickImage(true),
                    icon: Icon(_frontImage != null ? Icons.check_circle : Icons.upload_file, color: _frontImage != null ? AppColors.emerald : Colors.white70),
                    label: Text(_frontImage != null ? 'Front Attached' : 'Front Photo', style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: _backImage != null ? AppColors.emerald : AppColors.navyBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _pickImage(false),
                    icon: Icon(_backImage != null ? Icons.check_circle : Icons.upload_file, color: _backImage != null ? AppColors.emerald : Colors.white70),
                    label: Text(_backImage != null ? 'Back Attached' : 'Back Photo', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isUploading) ...[
              LinearProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null, color: AppColors.amberOrange, backgroundColor: AppColors.navyCardSecondary),
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
                onPressed: _isUploading ? null : _submitDl,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Submit Driving Licence for Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedDetails(KycRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
              SizedBox(width: 10),
              Text('Verification Active', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const Divider(color: AppColors.navyBorder, height: 20),
          _buildRow('Masked Licence ID', record.maskedId ?? 'XXXX-XXXX-XXXX-1234'),
          _buildRow('Status', 'VERIFIED ✓'),
          _buildRow('Verified Date', record.verifiedAt?.toLocal().toString().split(' ').first ?? 'Active'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _submitDl() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      setState(() => _errorMessage = 'Please select licence expiry date.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.3;
      _errorMessage = null;
    });

    try {
      List<int>? frontBytes;
      List<int>? backBytes;
      if (_frontImage != null) frontBytes = await _frontImage!.readAsBytes();
      if (_backImage != null) backBytes = await _backImage!.readAsBytes();

      setState(() => _uploadProgress = 0.7);

      final repo = ref.read(kycRepositoryProvider);
      await repo.submitDrivingLicence(
        dlNumber: _dlController.text.trim(),
        vehicleClass: _selectedClass,
        expiryDate: _expiryDate!,
        frontBytes: frontBytes,
        backBytes: backBytes,
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driving Licence submitted successfully for verification.')),
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
