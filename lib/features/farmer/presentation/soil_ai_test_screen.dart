import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/farmer/data/farmer_ai_repository.dart';
import 'package:udyogasethu/features/farmer/domain/ai_assist_models.dart';

class SoilAiTestScreen extends ConsumerStatefulWidget {
  const SoilAiTestScreen({super.key});

  @override
  ConsumerState<SoilAiTestScreen> createState() => _SoilAiTestScreenState();
}

class _SoilAiTestScreenState extends ConsumerState<SoilAiTestScreen> {
  double _soilPh = 6.8;
  String _selectedSoilType = 'Red Loamy (ಕೆಂಪು ಮಣ್ಣು)';
  String _targetCrop = 'Tomato & Vegetables';
  bool _isLoading = false;
  File? _reportFile;
  String? _base64Report;
  int? _reportSizeBytes;
  AiAssistResponse<SoilAdviceResult>? _result;

  final List<String> _soilTypes = [
    'Red Loamy (ಕೆಂಪು ಮಣ್ಣು)',
    'Black Cotton (ಕಪ್ಪು ಮಣ್ಣು)',
    'Alluvial / Riverbed (ವಂಡಲು ಮಣ್ಣು)',
    'Laterite / Coastal (ಲ್ಯಾಟರೈಟ್ ಮಣ್ಣು)',
    'Sandy Loam (ಮರಳು ಮಿಶ್ರಿತ ಮಣ್ಣು)',
  ];

  Future<void> _pickReportImage(ImageSource source) async {
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
          _reportFile = file;
          _base64Report = base64Str;
          _reportSizeBytes = bytes.length;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick soil report photo: $e')),
        );
      }
    }
  }

  Future<void> _analyze() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(farmerAiRepositoryProvider);
      final currentLocale = ref.read(localeProvider);

      final res = await repo.getSoilAdvice(
        soilPh: _soilPh,
        soilType: _selectedSoilType,
        crop: _targetCrop,
        district: 'Karnataka',
        language: currentLocale.languageCode,
        imageBase64: _base64Report,
        imageMime: 'image/jpeg',
      );

      setState(() => _result = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Soil analysis error: ${e.toString().replaceAll("Exception: ", "")}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Soil AI Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science_rounded, color: Color(0xFF059669), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soil Health & pH Advisory',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Optimize soil nutrients, correct acidity/alkalinity, and find best-yield crops.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Soil Test Report Photo Card (Gemini Vision)
            Container(
              padding: const EdgeInsets.all(14),
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
                      Icon(Icons.document_scanner_rounded, color: Color(0xFF059669), size: 20),
                      SizedBox(width: 8),
                      Text('Soil Report / Card Photo (Gemini Vision)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attach a clear photo of your Soil Health Card or lab report for AI analysis.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  if (_reportFile != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_reportFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => setState(() {
                              _reportFile = null;
                              _base64Report = null;
                              _reportSizeBytes = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Report photo attached (${((_reportSizeBytes ?? 0) / 1024).toStringAsFixed(0)} KB)',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF059669),
                              side: const BorderSide(color: Color(0xFF059669)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Camera', style: TextStyle(fontSize: 12)),
                            onPressed: () => _pickReportImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF059669),
                              side: const BorderSide(color: Color(0xFF059669)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                            onPressed: () => _pickReportImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // pH Input Slider Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Soil pH Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _soilPh < 6.0
                              ? Colors.orange.shade100
                              : _soilPh > 7.5
                                  ? Colors.purple.shade100
                                  : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'pH ${_soilPh.toStringAsFixed(1)} (${_soilPh < 6.0 ? 'Acidic' : _soilPh > 7.5 ? 'Alkaline' : 'Neutral'})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _soilPh < 6.0
                                ? Colors.orange.shade900
                                : _soilPh > 7.5
                                    ? Colors.purple.shade900
                                    : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _soilPh,
                    min: 4.5,
                    max: 9.0,
                    divisions: 45,
                    activeColor: const Color(0xFF059669),
                    label: _soilPh.toStringAsFixed(1),
                    onChanged: (val) => setState(() => _soilPh = val),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('4.5 (Very Acidic)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      Text('7.0 (Neutral)', style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                      Text('9.0 (Very Alkaline)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Soil Type Picker
            const Text('Soil Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedSoilType,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _soilTypes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSoilType = val);
              },
            ),
            const SizedBox(height: 14),

            // Target Crop
            const Text('Planned Crop / Rotation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: _targetCrop,
              decoration: InputDecoration(
                hintText: 'e.g., Tomato, Paddy, Onion, Maize',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => _targetCrop = v,
            ),
            const SizedBox(height: 18),

            // Analyze Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(
                  _isLoading ? 'Analyzing Soil Health...' : 'Get Soil Amendments & Crops',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _isLoading ? null : _analyze,
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _result!.isGemini
                                ? const Color(0xFF00875A).withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _result!.isGemini ? Icons.auto_awesome_rounded : Icons.info_outline_rounded,
                                size: 14,
                                color: _result!.isGemini ? const Color(0xFF00875A) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _result!.isGemini
                                    ? 'AI suggestion (Gemini), not professional advice'
                                    : 'Basic mode (offline rules)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _result!.isGemini ? const Color(0xFF00875A) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      _result!.result.phAssessment,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 14),

                    // Organic Amendments
                    const Text(
                      '🌱 Recommended Organic Amendments:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                    const SizedBox(height: 6),
                    ..._result!.result.organicAmendments.map((a) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.eco_rounded, size: 16, color: Color(0xFF059669)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(a, style: const TextStyle(fontSize: 12, height: 1.3))),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 14),

                    // Recommended Crops
                    const Text(
                      '🌾 Best Suited Crops for this Soil:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _result!.result.recommendedCrops.map((c) {
                        return Chip(
                          backgroundColor: const Color(0xFFF1F5F9),
                          label: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Expert Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _result!.result.expertNote,
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}
