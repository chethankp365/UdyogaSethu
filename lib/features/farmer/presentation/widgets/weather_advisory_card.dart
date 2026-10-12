import 'package:flutter/material.dart';
import 'package:udyogasethu/features/farmer/domain/weather_advisory_model.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class WeatherAdvisoryCard extends StatelessWidget {
  final WeatherAdvisory advisory;
  final VoidCallback onBookHelpers;

  const WeatherAdvisoryCard({
    super.key,
    required this.advisory,
    required this.onBookHelpers,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final severityColor = advisory.severity.color;
    final bgColor = advisory.severity.backgroundColor;
    final borderColor = advisory.severity.borderColor;

    String? actionText = advisory.actionLabel;
    if (advisory.actionLabel == 'Book Harvest Helpers') {
      actionText = l10n?.farmerBookHarvestHelpers ?? 'Book Harvest Helpers';
    } else if (advisory.actionLabel == 'View Irrigation Guide') {
      actionText = l10n?.farmerViewIrrigationGuide ?? 'View Irrigation Guide';
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Weather Advisory Radar & Location + Live Pulse
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radar_rounded,
                    color: severityColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n?.farmerWeatherAdvisoryRadar ?? 'WEATHER ADVISORY RADAR',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 240),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, size: 12, color: severityColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        advisory.locationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weather Summary Chips Wrap (Temp, Rain Prob, Precipitation, Simulated chip)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.thermostat_rounded, size: 14, color: Color(0xFFE65100)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${advisory.currentTemp.round()}°C (${advisory.minTemp.round()}°-${advisory.maxTemp.round()}°)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n?.farmerRainProbability(advisory.rainProbability) ??
                            '${advisory.rainProbability}% Rain',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                      ),
                    ),
                  ],
                ),
              ),
              if (advisory.isSimulated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n?.farmerSimulatedForecast ?? 'Simulated Forecast',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Advisory Text Body
          Text(
            advisory.advisoryBody,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Action Button (Book Harvest Helpers)
          if (actionText != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00875A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                onPressed: onBookHelpers,
                icon: const Icon(Icons.group_add_rounded, size: 18),
                label: Text(
                  actionText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
