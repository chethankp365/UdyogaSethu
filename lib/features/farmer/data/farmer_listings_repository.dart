import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/farmer/domain/price_suggestion_model.dart';
import 'package:udyogasethu/features/farmer/domain/produce_listing_model.dart';

class FarmerListingsRepository {
  final SupabaseClient? _supabase;

  FarmerListingsRepository([SupabaseClient? client])
      : _supabase = client ?? _safeClient();

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory cache for test & offline environments
  static final List<ProduceListing> _inMemoryListings = [
    ProduceListing(
      id: 'seed-tomato-1',
      farmerId: 'f-123',
      farmerName: 'Chethan Gowda',
      farmName: 'Cauvery Bio Farm',
      clusterVillage: 'Mandya Cluster',
      name: 'Organic Hybrid Tomatoes',
      category: 'vegetable',
      description: 'Vine-ripened, pesticide-free fresh farm tomatoes.',
      pricePaise: 2800,
      unit: 'kg',
      stockQty: 120.0,
      lowStockThreshold: 15.0,
      status: ProduceStatus.active,
      harvestAt: DateTime.now(),
      qualityNotes: 'Grade A, firm and juicy',
      farmingMethod: 'Organic',
      deliveryAvailable: true,
      pickupAvailable: true,
      availabilityMode: AvailabilityMode.sameDay,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ProduceListing(
      id: 'seed-rice-2',
      farmerId: 'f-123',
      farmerName: 'Chethan Gowda',
      farmName: 'Cauvery Bio Farm',
      clusterVillage: 'Mandya Cluster',
      name: 'Fresh Sona Masuri Rice',
      category: 'grain',
      description: 'Organically grown Sona Masuri unpolished rice, harvest 2026.',
      pricePaise: 6500,
      unit: 'kg',
      stockQty: 450.0,
      lowStockThreshold: 50.0,
      status: ProduceStatus.active,
      harvestAt: DateTime.now().subtract(const Duration(days: 5)),
      qualityNotes: 'Naturally aged, zero preservatives',
      farmingMethod: 'Natural Farming',
      deliveryAvailable: true,
      pickupAvailable: true,
      availabilityMode: AvailabilityMode.nextDay,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ProduceListing(
      id: 'seed-banana-3',
      farmerId: 'f-123',
      farmerName: 'Chethan Gowda',
      farmName: 'Cauvery Bio Farm',
      clusterVillage: 'Mandya Cluster',
      name: 'Nanjanagudu Rasabale Banana',
      category: 'fruit',
      description: 'GI-tagged heirloom sweet fragrance bananas from Mysuru.',
      pricePaise: 4500,
      unit: 'bunch',
      stockQty: 8.0,
      lowStockThreshold: 10.0,
      status: ProduceStatus.lowStock,
      harvestAt: DateTime.now(),
      qualityNotes: 'Sweet and naturally ripened without carbide',
      farmingMethod: 'Organic',
      deliveryAvailable: true,
      pickupAvailable: true,
      availabilityMode: AvailabilityMode.sameDay,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ProduceListing(
      id: 'seed-potato-4',
      farmerId: 'f-123',
      farmerName: 'Chethan Gowda',
      farmName: 'Cauvery Bio Farm',
      clusterVillage: 'Mandya Cluster',
      name: 'Fresh Farm Baby Potatoes',
      category: 'vegetable',
      description: 'Tender red skin potatoes fresh from Hassan soil.',
      pricePaise: 2400,
      unit: 'kg',
      stockQty: 0.0,
      lowStockThreshold: 10.0,
      status: ProduceStatus.soldOut,
      harvestAt: DateTime.now().subtract(const Duration(days: 4)),
      qualityNotes: 'Graded medium size',
      farmingMethod: 'Conventional',
      deliveryAvailable: true,
      pickupAvailable: false,
      availabilityMode: AvailabilityMode.preOrder,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // 1. Fetch Listings for specific farmer
  Future<List<ProduceListing>> getFarmerListings(String farmerId) async {
    if (_supabase != null && farmerId.isNotEmpty) {
      try {
        final res = await _supabase
            .from('produce_listings')
            .select()
            .eq('farmer_id', farmerId)
            .order('created_at', ascending: false);

        if (res.isNotEmpty) {
          return res.map((r) => ProduceListing.fromJson(r)).toList();
        }
      } catch (e) {
        debugPrint('Fetch farmer listings from DB failed: $e');
      }
    }

    return _inMemoryListings.where((l) => l.farmerId == farmerId || farmerId.isEmpty).toList();
  }

  // 2. Create Listing
  Future<ProduceListing> createListing({
    required String farmerId,
    required String name,
    required String category,
    required String description,
    required int pricePaise,
    required String unit,
    required double stockQty,
    double lowStockThreshold = 10.0,
    DateTime? harvestAt,
    String qualityNotes = '',
    String farmingMethod = 'Organic',
    bool deliveryAvailable = true,
    bool pickupAvailable = true,
    AvailabilityMode availabilityMode = AvailabilityMode.sameDay,
    List<Uint8List>? imageBytesList,
  }) async {
    List<String> imageUrls = [];

    // Auto calculate initial status
    ProduceStatus initStatus = ProduceStatus.active;
    if (stockQty <= 0) {
      initStatus = ProduceStatus.soldOut;
    } else if (stockQty <= lowStockThreshold) {
      initStatus = ProduceStatus.lowStock;
    }

    final newId = 'listing-${DateTime.now().millisecondsSinceEpoch}';

    // Upload images to produce-images storage bucket if available
    if (_supabase != null && imageBytesList != null) {
      for (int i = 0; i < imageBytesList.length; i++) {
        try {
          final path = '$farmerId/$newId/photo_$i.jpg';
          await _supabase.storage.from('produce-images').uploadBinary(
                path,
                imageBytesList[i],
                fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
              );
          final publicUrl = _supabase.storage.from('produce-images').getPublicUrl(path);
          imageUrls.add(publicUrl);
        } catch (e) {
          debugPrint('Upload produce image failed: $e');
        }
      }
    }

    final listing = ProduceListing(
      id: newId,
      farmerId: farmerId,
      name: name,
      category: category,
      description: description,
      pricePaise: pricePaise,
      unit: unit,
      stockQty: stockQty,
      lowStockThreshold: lowStockThreshold,
      status: initStatus,
      harvestAt: harvestAt ?? DateTime.now(),
      qualityNotes: qualityNotes,
      farmingMethod: farmingMethod,
      images: imageUrls,
      deliveryAvailable: deliveryAvailable,
      pickupAvailable: pickupAvailable,
      availabilityMode: availabilityMode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_supabase != null && farmerId.isNotEmpty) {
      try {
        final row = {
          'farmer_id': farmerId,
          'name': name,
          'category': category,
          'description': description,
          'price_paise': pricePaise,
          'unit': unit,
          'stock_qty': stockQty,
          'low_stock_threshold': lowStockThreshold,
          'status': initStatus.dbValue,
          'harvest_at': (harvestAt ?? DateTime.now()).toIso8601String(),
          'quality_notes': qualityNotes,
          'farming_method': farmingMethod,
          'images': imageUrls,
          'delivery_available': deliveryAvailable,
          'pickup_available': pickupAvailable,
          'availability_mode': availabilityMode.dbValue,
        };

        final inserted = await _supabase.from('produce_listings').insert(row).select().single();
        return ProduceListing.fromJson(inserted);
      } catch (e) {
        debugPrint('Insert produce listing into DB failed: $e');
      }
    }

    _inMemoryListings.insert(0, listing);
    return listing;
  }

  // 3. Update Listing
  Future<ProduceListing> updateListing(
    ProduceListing listing, {
    List<Uint8List>? newImageBytesList,
  }) async {
    List<String> imageUrls = List.from(listing.images);

    if (_supabase != null && newImageBytesList != null && newImageBytesList.isNotEmpty) {
      for (int i = 0; i < newImageBytesList.length; i++) {
        try {
          final path =
              '${listing.farmerId}/${listing.id}/photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await _supabase.storage.from('produce-images').uploadBinary(
                path,
                newImageBytesList[i],
                fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
              );
          final publicUrl = _supabase.storage.from('produce-images').getPublicUrl(path);
          imageUrls.add(publicUrl);
        } catch (e) {
          debugPrint('Upload produce image failed: $e');
        }
      }
    }

    // Auto status adjust
    ProduceStatus updatedStatus = listing.status;
    if (listing.stockQty <= 0) {
      updatedStatus = ProduceStatus.soldOut;
    } else if (listing.status != ProduceStatus.paused) {
      if (listing.stockQty <= listing.lowStockThreshold) {
        updatedStatus = ProduceStatus.lowStock;
      } else {
        updatedStatus = ProduceStatus.active;
      }
    }

    final updated = listing.copyWith(status: updatedStatus, images: imageUrls);

    if (_supabase != null) {
      try {
        await _supabase.from('produce_listings').update({
          'name': updated.name,
          'category': updated.category,
          'description': updated.description,
          'price_paise': updated.pricePaise,
          'unit': updated.unit,
          'stock_qty': updated.stockQty,
          'low_stock_threshold': updated.lowStockThreshold,
          'status': updated.status.dbValue,
          'harvest_at': updated.harvestAt?.toIso8601String(),
          'quality_notes': updated.qualityNotes,
          'farming_method': updated.farmingMethod,
          'images': updated.images,
          'delivery_available': updated.deliveryAvailable,
          'pickup_available': updated.pickupAvailable,
          'availability_mode': updated.availabilityMode.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', updated.id);
      } catch (e) {
        debugPrint('Update listing in DB failed: $e');
      }
    }

    final idx = _inMemoryListings.indexWhere((l) => l.id == updated.id);
    if (idx != -1) {
      _inMemoryListings[idx] = updated;
    }

    return updated;
  }

  // 4. Update Status (e.g. Pause / Activate)
  Future<ProduceListing> setStatus(String listingId, ProduceStatus newStatus) async {
    if (_supabase != null) {
      try {
        await _supabase
            .from('produce_listings')
            .update({'status': newStatus.dbValue, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', listingId);
      } catch (e) {
        debugPrint('Update status in DB failed: $e');
      }
    }

    final idx = _inMemoryListings.indexWhere((l) => l.id == listingId);
    if (idx != -1) {
      final updated = _inMemoryListings[idx].copyWith(status: newStatus);
      _inMemoryListings[idx] = updated;
      return updated;
    }

    throw Exception('Listing not found');
  }

  // 5. Update Stock quantity
  Future<ProduceListing> updateStock(String listingId, double newStock) async {
    final idx = _inMemoryListings.indexWhere((l) => l.id == listingId);
    ProduceListing current = idx != -1
        ? _inMemoryListings[idx]
        : ProduceListing(
            id: listingId,
            farmerId: '',
            name: '',
            pricePaise: 0,
            stockQty: 0,
            status: ProduceStatus.soldOut,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    ProduceStatus nextStatus = current.status;
    if (newStock <= 0) {
      nextStatus = ProduceStatus.soldOut;
    } else if (current.status != ProduceStatus.paused) {
      if (newStock <= current.lowStockThreshold) {
        nextStatus = ProduceStatus.lowStock;
      } else {
        nextStatus = ProduceStatus.active;
      }
    }

    final updated = current.copyWith(stockQty: newStock, status: nextStatus);

    if (_supabase != null) {
      try {
        await _supabase.from('produce_listings').update({
          'stock_qty': newStock,
          'status': nextStatus.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', listingId);
      } catch (e) {
        debugPrint('Update stock in DB failed: $e');
      }
    }

    if (idx != -1) {
      _inMemoryListings[idx] = updated;
    }

    return updated;
  }

  // 6. Get Price Suggestion Band (from APMC Mandi trends & season)
  Future<PriceSuggestion> getPriceSuggestion({
    required String commodity,
    String unit = 'kg',
  }) async {
    if (_supabase != null) {
      try {
        final res = await _supabase.rpc(
          'get_produce_price_suggestion',
          params: {'p_commodity': commodity, 'p_unit': unit},
        );

        if (res is List && res.isNotEmpty) {
          return PriceSuggestion.fromJson(res.first as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('Fetch price suggestion RPC failed: $e');
      }
    }

    // Default calculated fallback
    double benchmark = 25.0;
    final lower = commodity.toLowerCase();
    if (lower.contains('tomato')) benchmark = 25.0;
    if (lower.contains('onion')) benchmark = 28.0;
    if (lower.contains('potato')) benchmark = 21.0;
    if (lower.contains('banana')) benchmark = 42.0;
    if (lower.contains('rice') || lower.contains('paddy')) benchmark = 65.0;
    if (lower.contains('chilli')) benchmark = 435.0;
    if (lower.contains('ginger')) benchmark = 88.0;

    return PriceSuggestion.fallback(commodity, benchmark);
  }

  // 7. Get Buyer Produce Listings (STRICT INVARIANT: Active & In Stock only)
  Future<List<ProduceListing>> getBuyerProduceListings({
    String? search,
    String? category,
    String? farmingMethod,
  }) async {
    if (_supabase != null) {
      try {
        final res = await _supabase.rpc(
          'get_buyer_produce_listings',
          params: {
            'p_search': search,
            'p_category': category,
            'p_farming_method': farmingMethod,
          },
        );

        if (res is List && res.isNotEmpty) {
          return res.map((r) => ProduceListing.fromJson(r as Map<String, dynamic>)).toList();
        }

        // Direct select fallback
        var query = _supabase
            .from('produce_listings')
            .select()
            .inFilter('status', ['active', 'low_stock'])
            .gt('stock_qty', 0);

        if (search != null && search.isNotEmpty) {
          query = query.ilike('name', '%$search%');
        }

        final tableRes = await query.order('created_at', ascending: false);
        if (tableRes.isNotEmpty) {
          return tableRes.map((r) => ProduceListing.fromJson(r)).toList();
        }
      } catch (e) {
        debugPrint('Buyer produce query failed: $e');
      }
    }

    // Filter in-memory listings: ONLY active or lowStock AND stock_qty > 0
    return _inMemoryListings.where((l) {
      if (!l.isActiveAndInStock) return false;
      if (search != null && search.isNotEmpty) {
        if (!l.name.toLowerCase().contains(search.toLowerCase()) &&
            !l.description.toLowerCase().contains(search.toLowerCase())) {
          return false;
        }
      }
      if (category != null && category.isNotEmpty && l.category != category) {
        return false;
      }
      return true;
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// RIVERPOD PROVIDERS
// ---------------------------------------------------------------------------

final farmerListingsRepositoryProvider = Provider<FarmerListingsRepository>((ref) {
  return FarmerListingsRepository();
});

final farmerListingsProvider =
    FutureProvider.family<List<ProduceListing>, String>((ref, farmerId) async {
  final repo = ref.watch(farmerListingsRepositoryProvider);
  return repo.getFarmerListings(farmerId);
});

final buyerProduceListingsProvider =
    FutureProvider.family<List<ProduceListing>, String?>((ref, search) async {
  final repo = ref.watch(farmerListingsRepositoryProvider);
  return repo.getBuyerProduceListings(search: search);
});

final producePriceSuggestionProvider =
    FutureProvider.family<PriceSuggestion, String>((ref, commodity) async {
  final repo = ref.watch(farmerListingsRepositoryProvider);
  return repo.getPriceSuggestion(commodity: commodity);
});
