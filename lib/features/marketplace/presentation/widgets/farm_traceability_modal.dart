import 'package:flutter/material.dart';
import 'package:udyogasethu/features/marketplace/domain/lot_traceability_data.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FarmTraceabilityModal extends StatelessWidget {
  final LotTraceabilityData data;

  const FarmTraceabilityModal({
    super.key,
    required this.data,
  });

  static Future<void> show(BuildContext context, LotTraceabilityData data) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FarmTraceabilityModal(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Magnifying Glass Inspection Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00875A), width: 2),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF00875A),
                  size: 32,
                ),
              ),

              const SizedBox(height: 14),

              // 2. Modal Title
              Text(
                l10n?.farmTraceabilityTitle ?? 'Farm Quality Traceability Verified',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D6548),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lot: ${data.lotNumber}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // 3. Data Attribute Rows (Screen 28 Specification)
              _buildAttributeRow(
                label: l10n?.traceabilityCropItem ?? 'Crop Item:',
                value: data.cropItem,
                isBold: true,
              ),

              const SizedBox(height: 10),

              _buildAttributeRow(
                label: l10n?.traceabilityFarmerOrigin ?? 'Farmer Origin:',
                value: data.farmerOrigin,
              ),

              const SizedBox(height: 10),

              _buildAttributeRow(
                label: l10n?.traceabilityHarvestTime ?? 'Harvest Time:',
                value: data.harvestTime,
              ),

              const SizedBox(height: 10),

              _buildAttributeRow(
                label: l10n?.traceabilityCertification ?? 'Organic Certification:',
                valueWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          data.organicCertification,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _buildAttributeRow(
                label: l10n?.traceabilityFarmingMethod ?? 'Farming Method:',
                value: data.farmingMethod,
              ),

              const SizedBox(height: 10),

              // Quality notes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.traceabilityQualityNotes ?? 'Quality Notes:',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.qualityNotes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Primary Button: Close Traceability Details
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n?.closeTraceability ?? 'Close Traceability Details',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeRow({
    required String label,
    String? value,
    Widget? valueWidget,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: valueWidget ??
              Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
        ),
      ],
    );
  }
}
