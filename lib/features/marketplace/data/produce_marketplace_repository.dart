import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/farmer/domain/produce_listing_model.dart';
import 'package:udyogasethu/features/marketplace/domain/lot_traceability_data.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_filters.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_marketplace_item.dart';

final produceMarketplaceRepositoryProvider = Provider<ProduceMarketplaceRepository>((ref) {
  SupabaseClient? client;
  EdgeApiClient? edgeApi;
  try {
    if (Supabase.instance.isInitialized) {
      client = Supabase.instance.client;
      edgeApi = ref.watch(edgeApiClientProvider);
    }
  } catch (_) {}
  return ProduceMarketplaceRepository(client: client, edgeApi: edgeApi);
});

final produceMarketplaceListingsProvider = FutureProvider.autoDispose.family<
    List<ProduceMarketplaceItem>,
    ({ProduceFilters filters, String searchQuery, double? userLat, double? userLng})>(
  (ref, args) async {
    final repo = ref.watch(produceMarketplaceRepositoryProvider);
    return repo.getNearbyProduce(
      filters: args.filters,
      searchQuery: args.searchQuery,
      userLat: args.userLat,
      userLng: args.userLng,
    );
  },
);

class ProduceMarketplaceRepository {
  final SupabaseClient? client;
  final EdgeApiClient? edgeApi;

  ProduceMarketplaceRepository({this.client, this.edgeApi});

  static SupabaseClient? _safeClient() {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  // Realistic Karnataka Farm Produce Catalog matching Screen 27 & Screen 29
  List<ProduceMarketplaceItem> get fallbackProduceCatalog => List.unmodifiable(_inMemoryCatalog);

  static final List<ProduceMarketplaceItem> _inMemoryCatalog = [
    ProduceMarketplaceItem(
      id: 'a1111111-3333-4333-8333-111111111111',
      farmerId: 'farmer-ravi-1',
      farmerName: 'Direct Farmer Ravi',
      farmName: 'Ravi Organic Vegetable Farm',
      clusterVillage: 'Devanahalli Organic Cluster',
      farmerAvatarPath: null,
      isVerifiedFarmer: true,
      farmerRatingAvg: 4.9,
      farmerRatingCount: 38,
      name: 'Organic Red Tomatoes',
      category: 'vegetable',
      description: 'Sun-ripened, naturally grown native Karnataka tomatoes with rich natural sweetness.',
      pricePaise: 3400, // ₹34/kg
      unit: 'kg',
      stockQty: 120.0,
      images: const ['assets/images/produce/tomatoes.webp'],
      lat: 12.9820,
      lng: 77.6080,
      distanceM: 1500, // 1.5 km away
      harvestAt: DateTime.now().subtract(const Duration(hours: 4)), // Harvested Today, 4h ago
      farmingMethod: 'Zero-Pesticide Organic',
      qualityNotes: 'Harvested early morning, sorted A-grade quality with natural sweetness.',
      deliveryAvailable: true,
      pickupAvailable: true,
      walkInStore: false,
      organicCertified: true,
      certificationName: 'Pesticide-Free ✓ (KA Organic Board #4812)',
      lotNumber: 'LOT-KA-2026-TOM-01',
      status: ProduceStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ProduceMarketplaceItem(
      id: 'a2222222-3333-4333-8333-222222222222',
      farmerId: 'farmer-anand-2',
      farmerName: 'Anand Kumar',
      farmName: 'Pure A2 Gir Cow Farm',
      clusterVillage: 'Koramangala 4th Block',
      farmerAvatarPath: null,
      isVerifiedFarmer: true,
      farmerRatingAvg: 5.0,
      farmerRatingCount: 52,
      name: 'Pure A2 Gir Cow Milk',
      category: 'dairy',
      description: 'Raw, unadulterated whole A2 milk directly from free-grazing indigenous Gir cows.',
      pricePaise: 6000, // ₹60/Liter
      unit: 'Liter',
      stockQty: 65.0,
      images: const ['assets/images/produce/milk.webp'],
      lat: 12.9750,
      lng: 77.5990,
      distanceM: 500, // 0.5 km away
      harvestAt: DateTime.now().subtract(const Duration(hours: 4)), // Today 5 AM
      farmingMethod: 'Organic Dairy Natural',
      qualityNotes: 'Milked at 5:00 AM, chilled instantly to 4°C, zero hormones or preservatives.',
      deliveryAvailable: true,
      pickupAvailable: true,
      walkInStore: true, // Walk-in Store Marker!
      organicCertified: true,
      certificationName: 'Pure A2 Dairy Certified ✓',
      lotNumber: 'LOT-KA-2026-MLK-02',
      status: ProduceStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ProduceMarketplaceItem(
      id: 'a3333333-3333-4333-8333-333333333333',
      farmerId: 'farmer-kaveri-3',
      farmerName: 'Kaveri Gowda',
      farmName: 'Kaveri Fruit Orchard',
      clusterVillage: 'Mandya River Basin',
      farmerAvatarPath: null,
      isVerifiedFarmer: true,
      farmerRatingAvg: 4.85,
      farmerRatingCount: 29,
      name: 'Alphonso Mango & Guava Orchard Box',
      category: 'fruit',
      description: 'Naturally tree-ripened Alphonso mangoes and white guavas from Mandya river basin.',
      pricePaise: 12000, // ₹120/kg
      unit: 'kg',
      stockQty: 45.0,
      images: const ['assets/images/produce/mangoes.webp'],
      lat: 12.9620,
      lng: 77.5850,
      distanceM: 3200, // 3.2 km away
      harvestAt: DateTime.now().subtract(const Duration(days: 2)),
      farmingMethod: 'Natural Orchard IPM',
      qualityNotes: 'Naturally straw-ripened without carbide, graded A-grade table fruit.',
      deliveryAvailable: true,
      pickupAvailable: true,
      walkInStore: false,
      organicCertified: true,
      certificationName: 'Residue-Free Orchard Certified',
      lotNumber: 'LOT-KA-2026-MNG-03',
      status: ProduceStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    ProduceMarketplaceItem(
      id: 'a4444444-3333-4333-8333-444444444444',
      farmerId: 'farmer-malla-4',
      farmerName: 'Mallappa S.',
      farmName: 'Mandya Heritage Grains',
      clusterVillage: 'Mandya Rural',
      farmerAvatarPath: null,
      isVerifiedFarmer: true,
      farmerRatingAvg: 4.92,
      farmerRatingCount: 21,
      name: 'Single-Origin Finger Millet (Ragi)',
      category: 'grain',
      description: 'Traditional rain-fed finger millet rich in calcium and dietary fiber.',
      pricePaise: 4500, // ₹45/kg
      unit: 'kg',
      stockQty: 250.0,
      images: const ['assets/images/produce/ragi.webp'],
      lat: 12.9900,
      lng: 77.6200,
      distanceM: 4800, // 4.8 km away
      harvestAt: DateTime.now().subtract(const Duration(days: 5)),
      farmingMethod: 'Traditional Organic',
      qualityNotes: 'Sun-dried, de-stoned, ready for stone grinding.',
      deliveryAvailable: true,
      pickupAvailable: true,
      walkInStore: true, // Walk-in Store
      organicCertified: true,
      certificationName: 'Traditional Indigenous Seed ✓',
      lotNumber: 'LOT-KA-2026-RAG-04',
      status: ProduceStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    ProduceMarketplaceItem(
      id: 'a5555555-3333-4333-8333-555555555555',
      farmerId: 'farmer-chandru-5',
      farmerName: 'Chandru Gowda',
      farmName: 'Mysore Jasmine Groves',
      clusterVillage: 'Yelahanka Floriculture Hub',
      farmerAvatarPath: null,
      isVerifiedFarmer: false, // Testing unverified farmer display!
      farmerRatingAvg: 4.78,
      farmerRatingCount: 15,
      name: 'Fresh Morning Jasmine (Moggu)',
      category: 'flower',
      description: 'Freshly plucked Mysore Mallige jasmine buds for morning puja and celebrations.',
      pricePaise: 8000, // ₹80/kg
      unit: 'kg',
      stockQty: 18.0,
      images: const ['assets/images/produce/flowers.webp'],
      lat: 12.9550,
      lng: 77.5750,
      distanceM: 2100, // 2.1 km away
      harvestAt: DateTime.now().subtract(const Duration(hours: 3)),
      farmingMethod: 'Natural Floriculture',
      qualityNotes: 'Plucked before sunrise at 4:30 AM for peak fragrance and freshness.',
      deliveryAvailable: false,
      pickupAvailable: true,
      walkInStore: true, // Walk-in Store
      organicCertified: false,
      certificationName: 'Mysore Mallige GI Tagged',
      lotNumber: 'LOT-KA-2026-FLW-05',
      status: ProduceStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ProduceMarketplaceItem(
      id: 'a6666666-3333-4333-8333-666666666666',
      farmerId: 'farmer-veeresh-6',
      farmerName: 'Veeresh Patil',
      farmName: 'Malnad Bio Products',
      clusterVillage: 'Shimoga Forest Border',
      farmerAvatarPath: null,
      isVerifiedFarmer: true,
      farmerRatingAvg: 4.95,
      farmerRatingCount: 44,
      name: 'Wild Forest Honey & Virgin Coconut Oil',
      category: 'other',
      description: 'Pure raw unprocessed honey and wood-pressed virgin coconut oil from farm groves.',
      pricePaise: 45000, // ₹450 / 500ml
      unit: '500ml',
      stockQty: 8.0, // Low stock!
      images: const ['assets/images/produce/honey.webp'],
      lat: 12.9800,
      lng: 77.6350,
      distanceM: 5500, // 5.5 km away
      harvestAt: DateTime.now().subtract(const Duration(days: 7)),
      farmingMethod: 'Artisanal Farm-Made',
      qualityNotes: 'Wood-churned extraction, zero heating, unfiltered nutrient-dense.',
      deliveryAvailable: true,
      pickupAvailable: true,
      walkInStore: true,
      organicCertified: true,
      certificationName: 'Artisanal Food Board Validated',
      lotNumber: 'LOT-KA-2026-HNY-06',
      status: ProduceStatus.lowStock,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];

  /// Fetch nearby produce listings applying multi-criteria filters and sorting.
  Future<List<ProduceMarketplaceItem>> getNearbyProduce({
    ProduceFilters filters = const ProduceFilters(),
    String? searchQuery,
    double? userLat,
    double? userLng,
  }) async {
    final activeClient = client ?? _safeClient();

    if (activeClient != null) {
      try {
        final categoryParam = filters.category != 'all' ? filters.category : null;
        final radiusParam = filters.maxDistanceKm != null
            ? (filters.maxDistanceKm! * 1000).toDouble()
            : 50000.0;

        final res = await activeClient.rpc('nearby_produce', params: {
          'p_lat': userLat ?? 12.9716,
          'p_lng': userLng ?? 77.5946,
          'p_radius_m': radiusParam,
          'p_category': categoryParam,
          'p_min_price_paise': filters.minPricePaise,
          'p_max_price_paise': filters.maxPricePaise,
          'p_farming_method': filters.farmingMethod,
          'p_delivery_available': filters.deliveryAvailable,
          'p_search_query': searchQuery?.trim().isNotEmpty == true ? searchQuery!.trim() : null,
          'p_sort_by': filters.sortBy.dbValue,
          'p_limit': 50,
          'p_offset': 0,
        });

        if (res is List && res.isNotEmpty) {
          final items = res.map((r) => ProduceMarketplaceItem.fromJson(Map<String, dynamic>.from(r as Map))).toList();
          return _applyClientFilters(items, filters);
        }
      } catch (_) {}
    }

    // Offline / fallback filtering on in-memory catalog
    return _applyClientFilters(_inMemoryCatalog, filters, searchQuery: searchQuery);
  }

  /// In-memory filter application for combined criteria (ratings, freshness, walk-in, etc.)
  List<ProduceMarketplaceItem> _applyClientFilters(
    List<ProduceMarketplaceItem> source,
    ProduceFilters filters, {
    String? searchQuery,
  }) {
    var result = source.where((item) {
      // 1. Strict invariant: must be active or lowStock and stockQty > 0
      if (!item.isActiveAndInStock) return false;

      // 2. Category
      if (filters.category != 'all' && item.category.toLowerCase() != filters.category.toLowerCase()) {
        return false;
      }

      // 3. Search query
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final match = item.name.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.farmName.toLowerCase().contains(q) ||
            item.farmerName.toLowerCase().contains(q);
        if (!match) return false;
      }

      // 4. Price range
      if (filters.minPricePaise != null && item.pricePaise < filters.minPricePaise!) {
        return false;
      }
      if (filters.maxPricePaise != null && item.pricePaise > filters.maxPricePaise!) {
        return false;
      }

      // 5. Distance
      if (filters.maxDistanceKm != null && item.distanceM != null) {
        if (item.distanceM! > (filters.maxDistanceKm! * 1000)) return false;
      }

      // 6. Farmer Rating
      if (filters.minRating != null && item.farmerRatingAvg < filters.minRating!) {
        return false;
      }

      // 7. Farming Method
      if (filters.farmingMethod != null && filters.farmingMethod!.isNotEmpty) {
        if (!item.farmingMethod.toLowerCase().contains(filters.farmingMethod!.toLowerCase())) {
          return false;
        }
      }

      // 8. Delivery available
      if (filters.deliveryAvailable == true && !item.deliveryAvailable) {
        return false;
      }

      // 9. Walk-in store only
      if (filters.walkInStoreOnly == true && !item.walkInStore) {
        return false;
      }

      // 10. Organic certified only
      if (filters.organicCertifiedOnly == true && !item.organicCertified) {
        return false;
      }

      // 11. Freshness filter
      if (filters.freshness != FreshnessFilter.all) {
        if (item.harvestAt == null) return false;
        final diff = DateTime.now().difference(item.harvestAt!);
        if (filters.freshness == FreshnessFilter.today && diff.inHours > 24) {
          return false;
        }
        if (filters.freshness == FreshnessFilter.last24h && diff.inHours > 24) {
          return false;
        }
        if (filters.freshness == FreshnessFilter.last3Days && diff.inDays > 3) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting
    switch (filters.sortBy) {
      case ProduceSortOption.priceAsc:
        result.sort((a, b) => a.pricePaise.compareTo(b.pricePaise));
        break;
      case ProduceSortOption.priceDesc:
        result.sort((a, b) => b.pricePaise.compareTo(a.pricePaise));
        break;
      case ProduceSortOption.ratingDesc:
        result.sort((a, b) => b.farmerRatingAvg.compareTo(a.farmerRatingAvg));
        break;
      case ProduceSortOption.freshnessDesc:
        result.sort((a, b) {
          if (a.harvestAt == null) return 1;
          if (b.harvestAt == null) return -1;
          return b.harvestAt!.compareTo(a.harvestAt!);
        });
        break;
      case ProduceSortOption.distanceAsc:
        result.sort((a, b) {
          if (a.distanceM == null) return 1;
          if (b.distanceM == null) return -1;
          return a.distanceM!.compareTo(b.distanceM!);
        });
        break;
    }

    return result;
  }

  /// Get produce lot traceability data from scanned QR token or lot number.
  Future<LotTraceabilityData> getLotTraceability(String tokenOrLot) async {
    final trimmed = tokenOrLot.trim();

    // Check if input is a signed token (contains '.')
    if (trimmed.contains('.')) {
      // 1. Try remote Edge Function qr-verify
      if (edgeApi != null) {
        try {
          final res = await edgeApi!.qrVerify(qrToken: trimmed);
          if (res['success'] == true && res['data'] != null) {
            final data = Map<String, dynamic>.from(res['data'] as Map);
            if (data['purpose'] == 'produce_lot') {
              return LotTraceabilityData.fromJson(data);
            }
          }
        } catch (_) {}
      }

      // 2. Fallback: Parse token payload claims directly
      final payload = LotTraceabilityData.parseTokenPayload(trimmed);
      if (payload != null) {
        final lotId = payload['lot_id']?.toString() ?? payload['lot_number']?.toString();
        final listingId = payload['listing_id']?.toString();
        return _fetchTraceabilityFromDbOrCatalog(lotId: lotId, listingId: listingId);
      }
    }

    // Direct lot code or listing ID lookup
    return _fetchTraceabilityFromDbOrCatalog(lotId: trimmed, listingId: trimmed);
  }

  Future<LotTraceabilityData> _fetchTraceabilityFromDbOrCatalog({
    String? lotId,
    String? listingId,
  }) async {
    final activeClient = client ?? _safeClient();
    if (activeClient != null) {
      try {
        final res = await activeClient.rpc('get_produce_lot_traceability', params: {
          'p_lot_number': lotId,
          'p_listing_id': listingId != null && listingId.length == 36 ? listingId : null,
        });
        if (res is List && res.isNotEmpty) {
          return LotTraceabilityData.fromJson(Map<String, dynamic>.from(res.first as Map));
        }
      } catch (_) {}
    }

    // Match in-memory catalog
    final match = _inMemoryCatalog.firstWhere(
      (item) =>
          item.lotNumber.toLowerCase() == lotId?.toLowerCase() ||
          item.id == listingId ||
          item.name.toLowerCase().contains(lotId?.toLowerCase() ?? ''),
      orElse: () => _inMemoryCatalog.first,
    );

    return LotTraceabilityData(
      listingId: match.id,
      lotNumber: match.lotNumber,
      cropItem: match.name,
      category: match.category,
      farmerOrigin: '${match.farmName} • ${match.clusterVillage}',
      clusterVillage: match.clusterVillage,
      harvestTime: match.freshnessLabel,
      harvestAt: match.harvestAt,
      farmingMethod: match.farmingMethod,
      organicCertification: match.organicCertified
          ? (match.certificationName.isNotEmpty ? match.certificationName : 'Pesticide-Free ✓')
          : 'Natural IPNM Verified ✓',
      qualityNotes: match.qualityNotes,
      pricePaise: match.pricePaise,
      unit: match.unit,
      ratingAvg: match.farmerRatingAvg,
      images: match.images,
    );
  }

  /// Generate signed lot token for a produce marketplace item
  Future<String> getOrGenerateLotToken(ProduceMarketplaceItem item) async {
    if (edgeApi != null) {
      try {
        final res = await edgeApi!.qrIssue(
          purpose: 'produce_lot',
          listingId: item.id,
          lotNumber: item.lotNumber,
        );
        if (res['success'] == true && res['data'] != null) {
          final token = (res['data'] as Map)['qr_token'] as String?;
          if (token != null && token.isNotEmpty) {
            return token;
          }
        }
      } catch (_) {}
    }

    // Fallback: client-side signed HMAC token
    return LotTraceabilityData.createSignedLotToken(
      lotNumber: item.lotNumber,
      listingId: item.id,
    );
  }
}
