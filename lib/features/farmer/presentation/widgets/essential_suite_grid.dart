import 'package:flutter/material.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

enum EssentialSuiteType {
  rentTractor,
  hireWorkers,
  soilAiTest,
  sellProduce,
  pestAiDoc,
  govtSchemes,
  agriDrone,
  irrigationAi;

  IconData get icon {
    switch (this) {
      case EssentialSuiteType.rentTractor:
        return Icons.agriculture_rounded;
      case EssentialSuiteType.hireWorkers:
        return Icons.people_alt_rounded;
      case EssentialSuiteType.soilAiTest:
        return Icons.science_rounded;
      case EssentialSuiteType.sellProduce:
        return Icons.storefront_rounded;
      case EssentialSuiteType.pestAiDoc:
        return Icons.pest_control_rounded;
      case EssentialSuiteType.govtSchemes:
        return Icons.account_balance_rounded;
      case EssentialSuiteType.agriDrone:
        return Icons.flight_takeoff_rounded;
      case EssentialSuiteType.irrigationAi:
        return Icons.water_drop_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EssentialSuiteType.rentTractor:
        return const Color(0xFFD97706);
      case EssentialSuiteType.hireWorkers:
        return const Color(0xFF2563EB);
      case EssentialSuiteType.soilAiTest:
        return const Color(0xFF059669);
      case EssentialSuiteType.sellProduce:
        return const Color(0xFF0D6548);
      case EssentialSuiteType.pestAiDoc:
        return const Color(0xFFDC2626);
      case EssentialSuiteType.govtSchemes:
        return const Color(0xFF7C3AED);
      case EssentialSuiteType.agriDrone:
        return const Color(0xFF0891B2);
      case EssentialSuiteType.irrigationAi:
        return const Color(0xFF0284C7);
    }
  }

  String get phase {
    switch (this) {
      case EssentialSuiteType.rentTractor:
        return 'P6.3';
      case EssentialSuiteType.hireWorkers:
        return 'P6.3';
      case EssentialSuiteType.soilAiTest:
        return 'P6.8';
      case EssentialSuiteType.sellProduce:
        return 'P6.2';
      case EssentialSuiteType.pestAiDoc:
        return 'P6.8';
      case EssentialSuiteType.govtSchemes:
        return 'P6.8';
      case EssentialSuiteType.agriDrone:
        return 'P6.3';
      case EssentialSuiteType.irrigationAi:
        return 'P6.8';
    }
  }

  String title(AppLocalizations? l10n) {
    switch (this) {
      case EssentialSuiteType.rentTractor:
        return l10n?.farmerRentTractor ?? 'Rent Tractor';
      case EssentialSuiteType.hireWorkers:
        return l10n?.farmerHireWorkers ?? 'Hire Workers';
      case EssentialSuiteType.soilAiTest:
        return l10n?.farmerSoilAiTest ?? 'Soil AI Test';
      case EssentialSuiteType.sellProduce:
        return l10n?.farmerSellProduce ?? 'Sell Produce';
      case EssentialSuiteType.pestAiDoc:
        return l10n?.farmerPestAiDoc ?? 'Pest AI Doc';
      case EssentialSuiteType.govtSchemes:
        return l10n?.farmerGovtSchemes ?? 'Govt Schemes';
      case EssentialSuiteType.agriDrone:
        return l10n?.farmerAgriDrone ?? 'Agri Drone';
      case EssentialSuiteType.irrigationAi:
        return l10n?.farmerIrrigationAi ?? 'Irrigation AI';
    }
  }

  String description(AppLocalizations? l10n) {
    switch (this) {
      case EssentialSuiteType.rentTractor:
        return l10n?.farmerRentTractorDesc ??
            'Book nearby tractors, rotavators, and harvesters directly from verified agri-machinery hubs.';
      case EssentialSuiteType.hireWorkers:
        return l10n?.farmerHireWorkersDesc ??
            'Farmers will be able to post agricultural labour requests, specify shifts, and hire verified nearby workers directly from their farmer account with escrow protection.';
      case EssentialSuiteType.soilAiTest:
        return l10n?.farmerSoilAiTestDesc ??
            'Upload soil test report or photograph to get instant AI N-P-K recommendations and fertilizer dosages.';
      case EssentialSuiteType.sellProduce:
        return l10n?.farmerSellProduceDesc ??
            'List your harvested crops for direct bulk sale to mandi traders and commercial buyers with zero middlemen.';
      case EssentialSuiteType.pestAiDoc:
        return l10n?.farmerPestAiDocDesc ??
            'Snap a picture of leaf damage or crop pests for immediate AI diagnosis and organic treatment remedies.';
      case EssentialSuiteType.govtSchemes:
        return l10n?.farmerGovtSchemesDesc ??
            'Explore PM-Kisan, Raitha Siri, solar pump subsidies, and crop insurance schemes tailored to your land.';
      case EssentialSuiteType.agriDrone:
        return l10n?.farmerAgriDroneDesc ??
            'Book certified agri-drone pilots for precision nano-urea and organic pest spray within 24 hours.';
      case EssentialSuiteType.irrigationAi:
        return l10n?.farmerIrrigationAiDesc ??
            'Smart irrigation scheduling based on local evapotranspiration and soil moisture retention curves.';
    }
  }
}

class EssentialSuiteItem {
  final EssentialSuiteType type;

  const EssentialSuiteItem({required this.type});

  String get title => type.name;
  IconData get icon => type.icon;
  Color get color => type.color;
  String get placeholderPhase => type.phase;
}

class EssentialSuiteGrid extends StatelessWidget {
  final void Function(EssentialSuiteItem item)? onItemTap;

  const EssentialSuiteGrid({
    super.key,
    this.onItemTap,
  });

  static const List<EssentialSuiteItem> items = [
    EssentialSuiteItem(type: EssentialSuiteType.rentTractor),
    EssentialSuiteItem(type: EssentialSuiteType.hireWorkers),
    EssentialSuiteItem(type: EssentialSuiteType.soilAiTest),
    EssentialSuiteItem(type: EssentialSuiteType.sellProduce),
    EssentialSuiteItem(type: EssentialSuiteType.pestAiDoc),
    EssentialSuiteItem(type: EssentialSuiteType.govtSchemes),
    EssentialSuiteItem(type: EssentialSuiteType.agriDrone),
    EssentialSuiteItem(type: EssentialSuiteType.irrigationAi),
  ];

  static void showItemModal(BuildContext context, EssentialSuiteItem item) {
    final l10n = AppLocalizations.of(context);
    final title = item.type.title(l10n);
    final desc = item.type.description(l10n);
    final phaseText = l10n?.farmerComingInPhase(item.type.phase) ?? 'Coming in ${item.type.phase}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          phaseText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6548),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l10n?.farmerUnderstood ?? 'Understood',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF0D6548)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.farmerEssentialSuite ?? 'FARMER ESSENTIAL SUITE',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.9,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: (0.68 / MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6)).clamp(0.45, 0.72),
          ),
          itemBuilder: (context, index) {
            final it = items[index];
            final title = it.type.title(l10n);

            return InkWell(
              onTap: () {
                if (onItemTap != null) {
                  onItemTap!(it);
                } else {
                  showItemModal(context, it);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: it.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(it.icon, color: it.color, size: 20),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.15,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
