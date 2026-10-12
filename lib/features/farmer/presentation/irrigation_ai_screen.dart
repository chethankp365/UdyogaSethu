import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/farmer/data/farmer_ai_repository.dart';
import 'package:udyogasethu/features/farmer/domain/ai_assist_models.dart';

class IrrigationAiScreen extends ConsumerStatefulWidget {
  const IrrigationAiScreen({super.key});

  @override
  ConsumerState<IrrigationAiScreen> createState() => _IrrigationAiScreenState();
}

class _IrrigationAiScreenState extends ConsumerState<IrrigationAiScreen> {
  String _crop = 'Tomato (ಟೊಮೇಟೊ)';
  String _cropStage = 'Flowering & Early Fruit Set';
  String _irrigationSource = 'Borewell + Drip Irrigation';
  final String _weatherSummary = 'Warm 31°C, low humidity, light rain forecast in 48h';
  bool _isLoading = false;
  AiAssistResponse<IrrigationPlanResult>? _result;

  final List<String> _stages = [
    'Germination / Seedling Stage',
    'Vegetative Growth',
    'Flowering & Early Fruit Set',
    'Fruit Development & Bulking',
    'Maturity & Pre-Harvest',
  ];

  Future<void> _analyze() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(farmerAiRepositoryProvider);
      final currentLocale = ref.read(localeProvider);

      final res = await repo.getIrrigationPlan(
        crop: _crop,
        cropStage: _cropStage,
        irrigationSource: _irrigationSource,
        weatherSummary: _weatherSummary,
        district: 'Kolar / Chikkaballapur',
        language: currentLocale.languageCode,
      );

      setState(() => _result = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Irrigation plan error: $e')),
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
        title: const Text('Irrigation AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0284C7),
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
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Irrigation & Water Saving',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0369A1)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Weather-adaptive pump runtimes, morning scheduling, and rainfall adjustments.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF075985)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weather Card (Context)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prevailing District Weather:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text(_weatherSummary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Crop Name
            const Text('Crop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: _crop,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => _crop = v,
            ),
            const SizedBox(height: 14),

            // Crop Growth Stage
            const Text('Crop Growth Stage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _cropStage,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _cropStage = val);
              },
            ),
            const SizedBox(height: 14),

            // Source & Method
            const Text('Source & Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _irrigationSource,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: const [
                DropdownMenuItem(value: 'Borewell + Drip Irrigation', child: Text('Borewell + Drip Irrigation')),
                DropdownMenuItem(value: 'Canal / Flow Irrigation', child: Text('Canal / Flow Irrigation')),
                DropdownMenuItem(value: 'Open Well + Sprinkler', child: Text('Open Well + Sprinkler')),
                DropdownMenuItem(value: 'Rainfed / Farm Pond', child: Text('Rainfed / Farm Pond')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _irrigationSource = val);
              },
            ),
            const SizedBox(height: 18),

            // Analyze Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(
                  _isLoading ? 'Calculating Schedule...' : 'Generate Irrigation Plan',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _isLoading ? null : _analyze,
              ),
            ),
            const SizedBox(height: 20),

            // Result
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

                    // Watering Schedule
                    Text(
                      _result!.result.wateringFrequency,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 10),

                    // Best time & Drip duration
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.alarm_rounded, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Optimal Time: ${_result!.result.bestTimeOfDay}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.timelapse_rounded, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Cycle Duration: ${_result!.result.dripDurationHours}', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Water Saving Tips
                    const Text('💧 Water Conservation & Soil Moisture Tips:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                    const SizedBox(height: 6),
                    ..._result!.result.waterSavingTips.map((tip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0284C7)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(tip, style: const TextStyle(fontSize: 12, height: 1.3))),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    // Expert Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _result!.result.expertNote,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
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
