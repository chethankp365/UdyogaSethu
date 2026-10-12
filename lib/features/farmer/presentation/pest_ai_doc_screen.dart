import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _symptomsController =
      TextEditingController(text: 'Yellowing edges on lower leaves with dark brown concentric spots.');
  bool _hasPhotoAttached = true;
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

  Future<void> _analyze() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(farmerAiRepositoryProvider);
      final currentLocale = ref.read(localeProvider);

      // Lightweight 1x1 png inline image base64 if photo attached
      String? base64Photo;
      if (_hasPhotoAttached) {
        base64Photo = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      }

      final res = await repo.diagnosePest(
        crop: _selectedCrop,
        symptoms: _symptomsController.text.trim(),
        imageBase64: base64Photo,
        imageMime: 'image/png',
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
                          'Pest & Crop Disease Diagnosis',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Instant leaf diagnosis with organic-first IPM solutions and expert safety confirmation.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Leaf Photo Card
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
                  Container(
                    width: double.infinity,
                    height: 130,
                    decoration: BoxDecoration(
                      color: _hasPhotoAttached ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasPhotoAttached ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasPhotoAttached ? Icons.check_circle_rounded : Icons.add_a_photo_outlined,
                          size: 36,
                          color: _hasPhotoAttached ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hasPhotoAttached ? 'Leaf Photo Attached (Compressed)' : 'Tap to Take or Upload Leaf Photo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _hasPhotoAttached ? const Color(0xFF15803D) : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _hasPhotoAttached ? 'Ready for AI vision scan' : 'Focus closely on affected leaf surface',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text('Take Photo', style: TextStyle(fontSize: 12)),
                        onPressed: () => setState(() => _hasPhotoAttached = true),
                      ),
                      const SizedBox(width: 10),
                      if (_hasPhotoAttached)
                        TextButton(
                          onPressed: () => setState(() => _hasPhotoAttached = false),
                          child: const Text('Remove', style: TextStyle(fontSize: 12, color: Colors.red)),
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
            const Text('Observed Symptoms', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe spots, leaf curling, wilting, or insect activity...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Analyze Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(
                  _isLoading ? 'Analyzing with AI...' : 'Diagnose Plant Disease',
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

                    // Likely Cause
                    Text(
                      _result!.result.likelyCause,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),

                    // Organic Remedies
                    const Text(
                      '🌿 Organic & Natural IPM Remedies (Recommended):',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                    const SizedBox(height: 6),
                    ..._result!.result.organicRemedies.map((remedy) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(remedy, style: const TextStyle(fontSize: 12, height: 1.3)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    // Chemical Option
                    if (_result!.result.chemicalAdvice != null) ...[
                      const Text(
                        '🧪 Cautious Chemical Options:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _result!.result.chemicalAdvice!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.3),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Expert Warning Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _result!.result.expertWarning,
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Fallback to Expert Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.support_agent_rounded, size: 18),
                        label: const Text('Ask a Local Agronomist (KVK Helpline)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _showExpertDialog,
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
