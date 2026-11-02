import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/farmer/data/farmer_ai_repository.dart';
import 'package:udyogasethu/features/farmer/domain/ai_assist_models.dart';

class PestAiDocScreen extends ConsumerStatefulWidget {
  const PestAiDocScreen({super.key});

  @override
  ConsumerState<PestAiDocScreen> createState() => _PestAiDocScreenState();
}

class _PestAiDocScreenState extends ConsumerState<PestAiDocScreen> {
  String _selectedCrop = 'Tomato (ಟೊಮೇಟೊ)';
  final _symptomsController = TextEditingController();
  File? _photoFile;
  String? _base64Photo;
  int? _photoSizeBytes;
  bool _isLoading = false;
  AiAssistResponse<PestDiagnosisResult>? _result;

  final List<String> _commonCrops = [
    'Tomato (ಟೊಮೇಟೊ)',
    'Chilli (ಮೆಣಸಿನಕಾಯಿ)',
    'Paddy (ಭತ್ತ)',
    'Onion (ಈರುಳ್ಳಿ)',
    'Cotton (ಹತ್ತಿ)',
    'Maize (ಮೆಕ್ಕೆಜೋಳ)',
    'Arecanut (ಅಡಿಕೆ)',
  ];

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked != null) {
        final file = File(picked.path);
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);

        setState(() {
          _photoFile = file;
          _base64Photo = base64Str;
          _photoSizeBytes = bytes.length;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  Future<void> _analyze() async {
    if (_base64Photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a leaf photo first.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(farmerAiRepositoryProvider);
      final currentLocale = ref.read(localeProvider);

      final res = await repo.diagnosePest(
        crop: _selectedCrop,
        symptoms: _symptomsController.text.trim().isNotEmpty
            ? _symptomsController.text.trim()
            : 'Visual leaf disease analysis requested from attached photo.',
        imageBase64: _base64Photo,
        imageMime: 'image/jpeg',
        district: 'Kolar / Mandya',
        language: currentLocale.languageCode,
      );

      setState(() => _result = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Diagnosis error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showExpertDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: AppColors.headerGreenDark),
            SizedBox(width: 8),
            Text('Ask an Expert (KVK / RSK)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raitha Samparka Kendra (RSK) Agricultural Officer Helpline:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text('📞 Kisan Call Centre Toll-Free: 1800-180-1551', style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
            SizedBox(height: 4),
            Text('⏰ Active Hours: 06:00 AM to 10:00 PM (All 7 Days)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            SizedBox(height: 12),
            Text(
              'You can take your affected plant sample to your nearest Taluk Krishi Bhavan for in-person microscope testing.',
              style: TextStyle(fontSize: 12, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoFile != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pest AI Doc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pest_control_rounded, color: Color(0xFFDC2626), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plant Pathology & Pest Doctor',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Instant AI diagnosis for leaf spots, stem rot, pests, and nutrient deficiencies.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Leaf Photo Card (Real Camera & Gallery only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  if (hasPhoto) ...[
                    // Real Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.file(
                            _photoFile!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _photoFile = null;
                                  _base64Photo = null;
                                  _photoSizeBytes = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              _photoSizeBytes != null
                                  ? 'Leaf photo attached (${(_photoSizeBytes! / 1024).toStringAsFixed(1)} KB)'
                                  : 'Leaf photo attached',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _photoFile = null;
                              _base64Photo = null;
                              _photoSizeBytes = null;
                            });
                          },
                          child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Empty State
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 36,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Add a leaf photo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Take or choose a close-up photo of the affected leaf',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Two Real Buttons: Take Photo & Choose from Gallery
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Take Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D6548),
                            side: const BorderSide(color: Color(0xFF0D6548)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('From Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Crop Selector
            const Text('Crop Affected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedCrop,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _commonCrops.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCrop = val);
              },
            ),
            const SizedBox(height: 14),

            // Symptoms input
            const Text('Observed Symptoms (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe spots, leaf curling, wilting, or insect activity (optional)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Analyze Button - ENABLED ONLY WHEN PHOTO IS ATTACHED
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasPhoto ? const Color(0xFFDC2626) : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  elevation: hasPhoto ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(
                  _isLoading
                      ? 'Analyzing with AI...'
                      : hasPhoto
                          ? 'Diagnose Plant Disease'
                          : 'Attach photo to diagnose',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: (hasPhoto && !_isLoading) ? _analyze : null,
              ),
            ),
            const SizedBox(height: 20),

            // Results Section
            if (_result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _result!.isGemini ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Diagnosis Header + Confidence
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.coronavirus_rounded, color: Color(0xFFDC2626), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _result!.result.likelyCause,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (_result!.result.confidenceLevel != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text(
                                        _result!.result.confidenceLevel!,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: const Text(
                                      'AI DIAGNOSIS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB91C1C),
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
                    if (_result!.result.symptomsAnalysis != null && _result!.result.symptomsAnalysis!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _result!.result.symptomsAnalysis!,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                      ),
                    ],
                    const Divider(height: 24),

                    // Organic Remedy
                    if (_result!.result.organicRemedies.isNotEmpty) ...[
                      const Row(
                        children: [
                          Icon(Icons.eco_rounded, size: 16, color: Color(0xFF16A34A)),
                          SizedBox(width: 6),
                          Text('Organic / Bio-Control Remedy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _result!.result.organicRemedies.join('\n• '),
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF166534), height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Chemical Remedy
                    if (_result!.result.chemicalAdvice != null && _result!.result.chemicalAdvice!.isNotEmpty) ...[
                      const Row(
                        children: [
                          Icon(Icons.science_rounded, size: 16, color: Color(0xFF475569)),
                          SizedBox(width: 6),
                          Text('Chemical / Spray Recommendation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _result!.result.chemicalAdvice!,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Preventive Action / Expert Warning
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text('Preventive Measures & Warning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D4ED8))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _result!.result.preventionTips.isNotEmpty
                          ? _result!.result.preventionTips.join('\n• ')
                          : _result!.result.expertWarning,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.3),
                    ),
                    const SizedBox(height: 16),

                    // Fallback / Gemini Source Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _result!.isGemini ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _result!.isGemini ? '✨ Powered by Gemini Vision' : 'Offline Rule-Engine Match',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _result!.isGemini ? const Color(0xFF047857) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showExpertDialog,
                          icon: const Icon(Icons.support_agent_rounded, size: 16, color: AppColors.headerGreenDark),
                          label: const Text('Ask RSK Officer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                        ),
                      ],
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
}
