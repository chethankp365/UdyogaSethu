import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result from a routing query, containing polyline points, distance, and duration.
class RoutingResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isStraightLineFallback;

  const RoutingResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isStraightLineFallback = false,
  });

  /// Distance in kilometers, rounded to 1 decimal place.
  double get distanceKm => (distanceMeters / 1000.0);

  /// Duration in minutes, rounded to the nearest integer.
  int get durationMinutes => (durationSeconds / 60.0).round();

  /// Formatted distance string e.g. "4.2 km" or "850 m".
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Formatted duration string e.g. "18 min" or "1 h 12 min".
  String get formattedDuration {
    final mins = durationMinutes;
    if (mins < 60) {
      return '$mins min';
    }
    final hrs = mins ~/ 60;
    final remMins = mins % 60;
    if (remMins == 0) {
      return '$hrs h';
    }
    return '$hrs h $remMins min';
  }
}

/// Routing service implementing public OSRM endpoint with straight-line Haversine fallback.
///
/// NOTE: The public OSRM server (`router.project-osrm.org`) is free and open, but rate-limited.
/// In case of rate-limiting, network error, or timeout, a straight-line fallback is automatically computed.
class RoutingService {
  final http.Client _httpClient;

  RoutingService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Average urban driving/riding speed in Indian cities (km/h) for straight-line ETA fallback.
  static const double kUrbanSpeedKmh = 25.0;

  /// Fetches a driving route from [start] to [destination].
  ///
  /// Uses public OSRM API with GeoJSON coordinates. Falls back to straight-line
  /// Haversine distance and estimated urban travel time if the network fails or times out.
  Future<RoutingResult> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    // Basic coordinate equality check
    if ((start.latitude - destination.latitude).abs() < 0.0001 &&
        (start.longitude - destination.longitude).abs() < 0.0001) {
      return RoutingResult(
        points: [start, destination],
        distanceMeters: 0,
        durationSeconds: 0,
        isStraightLineFallback: false,
      );
    }

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await _httpClient.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final code = data['code'] as String?;

        if (code == 'Ok') {
          final routes = data['routes'] as List<dynamic>?;
          if (routes != null && routes.isNotEmpty) {
            final route = routes.first as Map<String, dynamic>;
            final distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
            final duration = (route['duration'] as num?)?.toDouble() ?? 0.0;
            final geometry = route['geometry'] as Map<String, dynamic>?;

            final coordinates = geometry?['coordinates'] as List<dynamic>?;
            final List<LatLng> points = [];

            if (coordinates != null && coordinates.isNotEmpty) {
              for (final coord in coordinates) {
                if (coord is List && coord.length >= 2) {
                  final lng = (coord[0] as num).toDouble();
                  final lat = (coord[1] as num).toDouble();
                  points.add(LatLng(lat, lng));
                }
              }
            }

            if (points.isNotEmpty) {
              return RoutingResult(
                points: points,
                distanceMeters: distance,
                durationSeconds: duration,
                isStraightLineFallback: false,
              );
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RoutingService] OSRM query failed, falling back to straight-line: $e');
      }
    }

    // Straight-line fallback
    return computeStraightLineFallback(start, destination);
  }

  /// Calculates straight-line distance via Haversine formula and estimates duration
  /// using an urban speed of 25 km/h.
  RoutingResult computeStraightLineFallback(LatLng start, LatLng dest) {
    final distanceMeters = _calculateHaversineDistance(start, dest);
    // Speed in m/s = km/h * (1000 / 3600)
    final speedMps = kUrbanSpeedKmh * (1000.0 / 3600.0);
    final durationSeconds = distanceMeters / speedMps;

    return RoutingResult(
      points: [start, dest],
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      isStraightLineFallback: true,
    );
  }

  /// Haversine formula for distance in meters between two coordinates.
  double _calculateHaversineDistance(LatLng p1, LatLng p2) {
    const double earthRadiusMeters = 6371000.0;
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLon = _degToRad(p2.longitude - p1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(p1.latitude)) *
            math.cos(_degToRad(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Launches external navigation apps (Google Maps, Apple Maps, or generic geo: intent).
  static Future<bool> openExternalMaps({
    required LatLng destination,
    String? label,
  }) async {
    final lat = destination.latitude;
    final lng = destination.longitude;
    final query = label != null ? Uri.encodeComponent(label) : '$lat,$lng';

    // 1. Try Google Maps navigation intent
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }

    // 2. Fallback to generic geo URI
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($query)');
    if (await canLaunchUrl(geoUrl)) {
      return await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}
