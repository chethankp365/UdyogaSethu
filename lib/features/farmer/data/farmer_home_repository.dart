import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/farmer/domain/mandi_price_model.dart';
import 'package:udyogasethu/features/farmer/domain/weather_advisory_model.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_controller.dart';

@immutable
class FarmerHomeStats {
  final double produceSoldKg;
  final int directEarningsPaise;
  final int activeLaborBookings;

  const FarmerHomeStats({
    this.produceSoldKg = 0.0,
    this.directEarningsPaise = 0,
    this.activeLaborBookings = 0,
  });

  double get directEarningsRupees => directEarningsPaise / 100.0;
}

class FarmerHomeRepository {
  final SupabaseClient? _supabase;

  FarmerHomeRepository([SupabaseClient? client])
      : _supabase = client ?? _safeClient();

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // 1. MANDI PRICES WITH OFFLINE PERSISTENT CACHE
  Future<List<MandiPrice>> getMandiPrices({bool forceRefresh = false}) async {
    const cacheKey = 'cached_mandi_prices_v1';
    final prefs = await SharedPreferences.getInstance();

    if (_supabase != null) {
      try {
        // 1. Attempt database fetch via RPC or direct select
        final res = await _supabase.rpc(
          'get_mandi_prices_with_demand',
          params: {'p_limit': 40},
        );

        if (res is List && res.isNotEmpty) {
          final prices = res
              .map((item) => MandiPrice.fromJson(item as Map<String, dynamic>))
              .toList();

          // Cache locally for offline inspection
          await prefs.setString(
            cacheKey,
            jsonEncode(prices.map((p) => p.toJson()).toList()),
          );

          return prices;
        }

        // Fallback: direct table select if RPC not applied yet
        final tableData = await _supabase
            .from('mandi_prices')
            .select()
            .order('arrival_date', ascending: false)
            .limit(40);

        if (tableData.isNotEmpty) {
          final prices = tableData
              .map((item) => MandiPrice.fromJson(item))
              .toList();

          await prefs.setString(
            cacheKey,
            jsonEncode(prices.map((p) => p.toJson()).toList()),
          );

          return prices;
        }
      } catch (e) {
        debugPrint('Mandi fetch failed, loading offline persistent cache: $e');
      }
    }

    // 2. Offline Cache Fallback
    final cachedStr = prefs.getString(cacheKey);
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedStr) as List<dynamic>;
        return decoded
            .map((e) => MandiPrice.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return [];
  }

  // 2. WEATHER ADVISORY VIA OPEN-METEO WITH LOCAL CACHE
  Future<WeatherAdvisory> getWeatherAdvisory({
    required double lat,
    required double lng,
    required String locationName,
    bool simulateRain = false,
  }) async {
    if (simulateRain) {
      return WeatherAdvisory.simulatedRain(locationName: locationName);
    }

    const cacheKey = 'cached_weather_advisory_v1';
    final prefs = await SharedPreferences.getInstance();

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,weather_code'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max'
        '&timezone=auto&forecast_days=2',
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        final currentTemp = (data['current']?['temperature_2m'] as num?)?.toDouble() ?? 27.0;
        final currentCode = (data['current']?['weather_code'] as num?)?.toInt() ?? 0;

        final daily = data['daily'];
        final maxTemp = ((daily?['temperature_2m_max'] as List?)?.first as num?)?.toDouble() ?? 30.0;
        final minTemp = ((daily?['temperature_2m_min'] as List?)?.first as num?)?.toDouble() ?? 21.0;
        final rainProb = ((daily?['precipitation_probability_max'] as List?)?.first as num?)?.toInt() ?? 20;
        final precipMm = ((daily?['precipitation_sum'] as List?)?.first as num?)?.toDouble() ?? 0.0;
        final dailyCode = ((daily?['weather_code'] as List?)?.first as num?)?.toInt() ?? currentCode;

        final advisory = WeatherAdvisory.fromForecastData(
          locationName: locationName,
          currentTemp: currentTemp,
          maxTemp: maxTemp,
          minTemp: minTemp,
          rainProbability: rainProb,
          precipitationMm: precipMm,
          weatherCode: dailyCode,
        );

        // Cache offline
        await prefs.setString(cacheKey, jsonEncode(advisory.toJson()));
        return advisory;
      }
    } catch (e) {
      debugPrint('Open-Meteo call failed, loading offline cached weather: $e');
    }

    // Offline cache
    final cachedStr = prefs.getString(cacheKey);
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedStr) as Map<String, dynamic>;
        return WeatherAdvisory.fromJson(decoded);
      } catch (_) {}
    }

    // Default pleasant weather fallback
    return WeatherAdvisory.fromForecastData(
      locationName: locationName,
      currentTemp: 28.0,
      maxTemp: 31.0,
      minTemp: 22.0,
      rainProbability: 15,
      precipitationMm: 0.0,
      weatherCode: 1,
    );
  }

  // 3. REAL STATS FOR FARMER
  Future<FarmerHomeStats> getFarmerStats(String userId) async {
    if (_supabase == null || userId.isEmpty) {
      return const FarmerHomeStats();
    }
    try {
      // Query produce orders count & sold kg if orders table exists
      double totalKg = 0.0;
      int earningsPaise = 0;

      final res = await _supabase
          .from('orders')
          .select('total_amount_paise, items')
          .eq('seller_id', userId)
          .eq('status', 'delivered');

      for (final row in res) {
        earningsPaise += (row['total_amount_paise'] as num?)?.toInt() ?? 0;
        final items = row['items'];
        if (items is List) {
          for (final it in items) {
            totalKg += (it['quantity_kg'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      return FarmerHomeStats(
        produceSoldKg: totalKg,
        directEarningsPaise: earningsPaise,
        activeLaborBookings: 0, // 0 for now until P6.3
      );
    } catch (_) {
      // Fresh farmer starts with 0
      return const FarmerHomeStats(
        produceSoldKg: 0.0,
        directEarningsPaise: 0,
        activeLaborBookings: 0,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// RIVERPOD PROVIDERS
// ---------------------------------------------------------------------------

final farmerHomeRepositoryProvider = Provider<FarmerHomeRepository>((ref) {
  return FarmerHomeRepository();
});

final farmerHomeProfileProvider = FutureProvider<FarmerProfileDraft>((ref) async {
  final repo = ref.watch(farmerProfileRepositoryProvider);
  String? userId;
  bool isSupabaseInitialized = true;
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.id.isNotEmpty) userId = user.id;
  } catch (_) {
    isSupabaseInitialized = false;
  }
  if (isSupabaseInitialized && userId == null) {
    return const FarmerProfileDraft(userId: '');
  }
  final targetId = userId ?? 'test-user-id';
  return repo.loadDraft(targetId);
});

// Debug-only simulated rain switch
class SimulatedRainNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setSimulated(bool value) => state = value;
}

final simulatedRainForecastProvider =
    NotifierProvider<SimulatedRainNotifier, bool>(SimulatedRainNotifier.new);

// Mandi Prices Provider
final mandiPricesProvider = FutureProvider<List<MandiPrice>>((ref) async {
  final repo = ref.watch(farmerHomeRepositoryProvider);
  return repo.getMandiPrices();
});

// Weather Advisory Provider
final farmerWeatherAdvisoryProvider = FutureProvider<WeatherAdvisory>((ref) async {
  final repo = ref.watch(farmerHomeRepositoryProvider);
  final isRainSimulated = ref.watch(simulatedRainForecastProvider);

  // Read farmer profile location if available
  final profileAsync = ref.watch(farmerHomeProfileProvider);
  final draft = profileAsync.value;

  final lat = draft?.farmLatitude ?? 12.52; // Mandya default
  final lng = draft?.farmLongitude ?? 76.89;
  final cluster = draft?.clusterVillage.isNotEmpty == true
      ? draft!.clusterVillage
      : 'Mandya District';

  return repo.getWeatherAdvisory(
    lat: lat,
    lng: lng,
    locationName: cluster,
    simulateRain: isRainSimulated,
  );
});

// Farmer Stats Provider
final farmerStatsProvider = FutureProvider<FarmerHomeStats>((ref) async {
  final repo = ref.watch(farmerHomeRepositoryProvider);
  final user = Supabase.instance.client.auth.currentUser;
  final uid = user?.id ?? '';
  return repo.getFarmerStats(uid);
});
