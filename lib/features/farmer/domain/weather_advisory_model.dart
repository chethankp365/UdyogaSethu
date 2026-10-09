import 'package:flutter/material.dart';

enum WeatherAdvisorySeverity {
  info,
  warning,
  alert;

  Color get color {
    switch (this) {
      case WeatherAdvisorySeverity.info:
        return const Color(0xFF0D6548);
      case WeatherAdvisorySeverity.warning:
        return const Color(0xFFE65100);
      case WeatherAdvisorySeverity.alert:
        return const Color(0xFFDC2626);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case WeatherAdvisorySeverity.info:
        return const Color(0xFFF0FDF4);
      case WeatherAdvisorySeverity.warning:
        return const Color(0xFFFFFBEB);
      case WeatherAdvisorySeverity.alert:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get borderColor {
    switch (this) {
      case WeatherAdvisorySeverity.info:
        return const Color(0xFFBBF7D0);
      case WeatherAdvisorySeverity.warning:
        return const Color(0xFFFDE68A);
      case WeatherAdvisorySeverity.alert:
        return const Color(0xFFFECACA);
    }
  }
}

@immutable
class WeatherAdvisory {
  final String locationName;
  final double currentTemp;
  final double maxTemp;
  final double minTemp;
  final int rainProbability;
  final double precipitationMm;
  final int weatherCode;
  final String advisoryTitle;
  final String advisoryBody;
  final String? actionLabel;
  final WeatherAdvisorySeverity severity;
  final DateTime date;
  final bool isSimulated;

  const WeatherAdvisory({
    required this.locationName,
    required this.currentTemp,
    required this.maxTemp,
    required this.minTemp,
    required this.rainProbability,
    required this.precipitationMm,
    required this.weatherCode,
    required this.advisoryTitle,
    required this.advisoryBody,
    this.actionLabel,
    required this.severity,
    required this.date,
    this.isSimulated = false,
  });

  /// Rule-based agricultural advisor algorithm
  factory WeatherAdvisory.fromForecastData({
    required String locationName,
    required double currentTemp,
    required double maxTemp,
    required double minTemp,
    required int rainProbability,
    required double precipitationMm,
    required int weatherCode,
    bool isSimulated = false,
  }) {
    // 1. Heavy rain alert
    if (precipitationMm >= 25.0 || weatherCode >= 80) {
      return WeatherAdvisory(
        locationName: locationName,
        currentTemp: currentTemp,
        maxTemp: maxTemp,
        minTemp: minTemp,
        rainProbability: rainProbability,
        precipitationMm: precipitationMm,
        weatherCode: weatherCode,
        advisoryTitle: 'Heavy Rainfall Warning',
        advisoryBody:
            'Heavy rain expected (${precipitationMm.toStringAsFixed(0)}mm). Clear drainage furrows in low-lying tomato and vegetable plots to prevent root rot and waterlogging.',
        actionLabel: 'Book Harvest Helpers',
        severity: WeatherAdvisorySeverity.alert,
        date: DateTime.now(),
        isSimulated: isSimulated,
      );
    }

    // 2. Moderate rain forecast (Prompt & Screen 26 match)
    if (rainProbability >= 45 || precipitationMm >= 4.0 || (weatherCode >= 50 && weatherCode <= 65)) {
      return WeatherAdvisory(
        locationName: locationName,
        currentTemp: currentTemp,
        maxTemp: maxTemp,
        minTemp: minTemp,
        rainProbability: rainProbability,
        precipitationMm: precipitationMm,
        weatherCode: weatherCode,
        advisoryTitle: 'Moderate Rain Expected Tomorrow Afternoon',
        advisoryBody:
            'Moderate Rain Expected Tomorrow Afternoon - Protect ready tomato crops by harvesting before 12 PM. 5 Local harvest helpers are available nearby for booking.',
        actionLabel: 'Book Harvest Helpers',
        severity: WeatherAdvisorySeverity.warning,
        date: DateTime.now(),
        isSimulated: isSimulated,
      );
    }

    // 3. High heat / moisture stress
    if (maxTemp >= 34.0) {
      return WeatherAdvisory(
        locationName: locationName,
        currentTemp: currentTemp,
        maxTemp: maxTemp,
        minTemp: minTemp,
        rainProbability: rainProbability,
        precipitationMm: precipitationMm,
        weatherCode: weatherCode,
        advisoryTitle: 'High Temperature Advisory (${maxTemp.round()}°C)',
        advisoryBody:
            'High temperatures expected. Schedule early morning or late evening irrigation to prevent heat stress and blossom drop in vegetable crops.',
        actionLabel: 'View Irrigation Guide',
        severity: WeatherAdvisorySeverity.warning,
        date: DateTime.now(),
        isSimulated: isSimulated,
      );
    }

    // 4. Optimal clear weather
    return WeatherAdvisory(
      locationName: locationName,
      currentTemp: currentTemp,
      maxTemp: maxTemp,
      minTemp: minTemp,
      rainProbability: rainProbability,
      precipitationMm: precipitationMm,
      weatherCode: weatherCode,
      advisoryTitle: 'Favourable Field Weather',
      advisoryBody:
          'Clear skies and dry field conditions expected for next 48 hours. Optimal window for intercultural operations, bio-fertilizer application, and weed management.',
      actionLabel: null,
      severity: WeatherAdvisorySeverity.info,
      date: DateTime.now(),
      isSimulated: isSimulated,
    );
  }

  factory WeatherAdvisory.simulatedRain({String locationName = 'Mandya District'}) {
    return WeatherAdvisory.fromForecastData(
      locationName: locationName,
      currentTemp: 26.0,
      maxTemp: 29.0,
      minTemp: 21.0,
      rainProbability: 75,
      precipitationMm: 14.5,
      weatherCode: 61, // Moderate rain
      isSimulated: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'location_name': locationName,
        'current_temp': currentTemp,
        'max_temp': maxTemp,
        'min_temp': minTemp,
        'rain_probability': rainProbability,
        'precipitation_mm': precipitationMm,
        'weather_code': weatherCode,
        'advisory_title': advisoryTitle,
        'advisory_body': advisoryBody,
        'action_label': actionLabel,
        'severity': severity.name,
        'date': date.toIso8601String(),
        'is_simulated': isSimulated,
      };

  factory WeatherAdvisory.fromJson(Map<String, dynamic> json) {
    return WeatherAdvisory(
      locationName: json['location_name']?.toString() ?? 'Mandya District',
      currentTemp: (json['current_temp'] as num?)?.toDouble() ?? 28.0,
      maxTemp: (json['max_temp'] as num?)?.toDouble() ?? 31.0,
      minTemp: (json['min_temp'] as num?)?.toDouble() ?? 22.0,
      rainProbability: (json['rain_probability'] as num?)?.toInt() ?? 20,
      precipitationMm: (json['precipitation_mm'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      advisoryTitle: json['advisory_title']?.toString() ?? 'Favourable Field Weather',
      advisoryBody: json['advisory_body']?.toString() ?? 'Field weather is calm.',
      actionLabel: json['action_label']?.toString(),
      severity: WeatherAdvisorySeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => WeatherAdvisorySeverity.info,
      ),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      isSimulated: json['is_simulated'] == true,
    );
  }
}
