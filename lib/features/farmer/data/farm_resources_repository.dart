import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/farmer/domain/farm_resource_model.dart';
import 'package:udyogasethu/features/farmer/domain/resource_booking_model.dart';

abstract class FarmResourcesRepository {
  Future<List<FarmResource>> getNearbyResources({
    double? lat,
    double? lng,
    double radiusM = 50000,
    FarmResourceType? type,
    String? searchQuery,
    int limit = 40,
    int offset = 0,
  });

  Future<ResourceBooking> bookResource({
    required String resourceId,
    required DateTime startAt,
    required DateTime endAt,
    required double quantity,
    required String deliveryAddress,
    String? notes,
    String paymentMethod = 'upi',
  });

  Future<List<ResourceBooking>> getFarmerBookings(String renterId);

  Future<List<FarmResource>> getVendorResources(String ownerId);

  Future<List<ResourceBooking>> getVendorBookings(String ownerId);

  Future<ResourceBooking> updateBookingStatus(
    String bookingId,
    ResourceBookingStatus newStatus,
  );

  Future<FarmResource> createOrUpdateResource(FarmResource resource);
}

final farmResourcesRepositoryProvider = Provider<FarmResourcesRepository>((ref) {
  return SupabaseFarmResourcesRepository();
});

class SupabaseFarmResourcesRepository implements FarmResourcesRepository {
  final SupabaseClient? _client;

  // In-memory fallback / cache for offline and test environments
  final List<FarmResource> _inMemoryResources = [
    const FarmResource(
      id: '88888888-8888-4888-8888-888888888801',
      ownerId: 'owner-kisan-hub-1',
      type: FarmResourceType.tractor,
      name: 'Mahindra 575 DI Tractor + Rotavator',
      pricePaise: 85000,
      unit: 'hr',
      distanceM: 1200.0,
      lat: 13.2483,
      lng: 77.7127,
      description:
          '50 HP diesel tractor equipped with 48-blade heavy duty rotavator for dry/wet soil preparation. Experienced driver included.',
      specs: '50 HP • Fuel Included',
      addressText: 'Kisan Machinery Hub • Devanahalli Road',
      ratingAvg: 4.9,
      ratingCount: 38,
      verified: true,
      ownerName: 'Kisan Machinery Hub',
      active: true,
    ),
    const FarmResource(
      id: '88888888-8888-4888-8888-888888888802',
      ownerId: 'owner-agritech-mandya',
      type: FarmResourceType.harvester,
      name: 'Multi-Crop Harvester & Thresher',
      pricePaise: 140000,
      unit: 'hr',
      distanceM: 4100.0,
      lat: 12.5244,
      lng: 76.8951,
      description:
          'High-capacity rubber-track paddy, ragi and grain harvester with zero grain loss technology. Suitable for wet fields.',
      specs: 'High Yield Grain Cutter',
      addressText: 'AgriTech Rentals Mandya • Mandya Town',
      ratingAvg: 4.8,
      ratingCount: 24,
      verified: true,
      ownerName: 'AgriTech Rentals Mandya',
      active: true,
    ),
    const FarmResource(
      id: '88888888-8888-4888-8888-888888888803',
      ownerId: 'owner-dronekisan',
      type: FarmResourceType.drone,
      name: 'Agricultural Drone Spraying Kit',
      pricePaise: 45000,
      unit: 'acre',
      distanceM: 1800.0,
      lat: 13.1007,
      lng: 77.5946,
      description:
          'DGCA certified agri drone for uniform pesticide, micronutrient and bio-fertilizer spraying. Covers 1 acre in 7 minutes.',
      specs: '10L Tank • Precision GPS',
      addressText: 'DroneKisan Karnataka • Yelahanka Rural',
      ratingAvg: 5.0,
      ratingCount: 42,
      verified: true,
      ownerName: 'DroneKisan Karnataka',
      active: true,
    ),
    const FarmResource(
      id: '88888888-8888-4888-8888-888888888804',
      ownerId: 'owner-greensoil',
      type: FarmResourceType.fertilizer,
      name: 'Bio-NPK & Vermicompost Depot',
      pricePaise: 45000,
      unit: 'bag',
      distanceM: 2400.0,
      lat: 13.1020,
      lng: 77.5960,
      description:
          'Certified rich organic vermicompost enriched with Trichoderma and Neem cake. 50kg moisture-sealed bags.',
      specs: '50kg Sealed Bag • 100% Organic',
      addressText: 'GreenSoil Organic Depot • Yelahanka Mandi Gate',
      ratingAvg: 4.7,
      ratingCount: 19,
      verified: true,
      ownerName: 'GreenSoil Organic Depot',
      active: true,
    ),
    const FarmResource(
      id: '88888888-8888-4888-8888-888888888805',
      ownerId: 'owner-coldchain',
      type: FarmResourceType.coldStorage,
      name: 'Solar Cold Storage Facility',
      pricePaise: 1500,
      unit: 'crate/day',
      distanceM: 3500.0,
      lat: 13.2500,
      lng: 77.7140,
      description:
          'Micro-climate controlled solar cold room maintaining 4-8°C with 90% humidity for tomatoes, capsicum and vegetables.',
      specs: 'Temp 4-8°C • Backup Generator',
      addressText: 'Karnataka Agri Cold Chain • Devanahalli',
      ratingAvg: 4.9,
      ratingCount: 15,
      verified: true,
      ownerName: 'Karnataka Agri Cold Chain',
      active: true,
    ),
    const FarmResource(
      id: '88888888-8888-4888-8888-888888888806',
      ownerId: 'owner-kvk-lab',
      type: FarmResourceType.labourEquipment,
      name: 'Soil Quality Testing & Lab Service',
      pricePaise: 20000,
      unit: 'sample',
      distanceM: 5000.0,
      lat: 12.5260,
      lng: 76.8970,
      description:
          'Complete 14-parameter soil health analysis card (N, P, K, pH, EC, Organic Carbon) delivered within 24 hours.',
      specs: '14 Parameters • 24hr Digital Report',
      addressText: 'Krishi Vigyan Kendra Mobile Lab • Mandya Yard',
      ratingAvg: 4.8,
      ratingCount: 29,
      verified: true,
      ownerName: 'Krishi Vigyan Kendra',
      active: true,
    ),
    const FarmResource(
      id: '88888888-8888-4888-8888-888888888807',
      ownerId: 'owner-rotavator-coop',
      type: FarmResourceType.tractor,
      name: 'Tractor Rotavator Attachment Only',
      pricePaise: 35000,
      unit: 'hr',
      distanceM: 2000.0,
      lat: 12.5220,
      lng: 76.8930,
      description:
          'Shaktiman 6-foot heavy rotavator attachment compatible with 45-60 HP 3-point hitch tractors.',
      specs: '6 Foot Width • Multi-Speed Gearbox',
      addressText: 'Mandya Rural Machinery Co-op • Sugar Town',
      ratingAvg: 4.6,
      ratingCount: 11,
      verified: true,
      ownerName: 'Mandya Rural Machinery Co-op',
      active: true,
    ),
  ];

  final List<ResourceBooking> _inMemoryBookings = [];

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseFarmResourcesRepository([SupabaseClient? client])
      : _client = client ?? _safeClient();

  @override
  Future<List<FarmResource>> getNearbyResources({
    double? lat,
    double? lng,
    double radiusM = 50000,
    FarmResourceType? type,
    String? searchQuery,
    int limit = 40,
    int offset = 0,
  }) async {
    if (_client != null) {
      try {
        final res = await _client.rpc(
          'nearby_resources',
          params: {
            'p_lat': lat ?? 12.5244,
            'p_lng': lng ?? 76.8951,
            'p_radius_m': radiusM,
            'p_type': type?.dbValue,
            'p_search_query': searchQuery,
            'p_limit': limit,
            'p_offset': offset,
          },
        );

        if (res is List && res.isNotEmpty) {
          return res.map((e) => FarmResource.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {
        // Fall back to in-memory list on network / offline error
      }
    }

    // In-memory filtering
    return _inMemoryResources.where((r) {
      if (!r.active) return false;
      if (type != null && r.type != type) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final match = r.name.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.specs.toLowerCase().contains(q) ||
            r.addressText.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<ResourceBooking> bookResource({
    required String resourceId,
    required DateTime startAt,
    required DateTime endAt,
    required double quantity,
    required String deliveryAddress,
    String? notes,
    String paymentMethod = 'upi',
  }) async {
    final resource = _inMemoryResources.firstWhere(
      (r) => r.id == resourceId,
      orElse: () => FarmResource(
        id: resourceId,
        ownerId: 'owner-default',
        type: FarmResourceType.tractor,
        name: 'Agricultural Equipment',
        pricePaise: 85000,
        unit: 'hr',
      ),
    );

    final totalPaise = (resource.pricePaise * quantity).toInt();
    final user = _client?.auth.currentUser;
    final renterId = user?.id ?? 'demo-farmer-id';

    if (_client != null && user != null) {
      try {
        final res = await _client.rpc(
          'book_resource',
          params: {
            'p_resource_id': resourceId,
            'p_start_at': startAt.toIso8601String(),
            'p_end_at': endAt.toIso8601String(),
            'p_quantity': quantity,
            'p_delivery_address': deliveryAddress,
            'p_notes': notes,
            'p_payment_method': paymentMethod,
          },
        );

        if (res is Map) {
          final booking = ResourceBooking(
            id: res['booking_id'] as String? ?? 'bkg-${DateTime.now().millisecondsSinceEpoch}',
            resourceId: resourceId,
            renterId: renterId,
            startAt: startAt,
            endAt: endAt,
            totalPaise: (res['total_paise'] as num?)?.toInt() ?? totalPaise,
            status: ResourceBookingStatus.confirmed,
            quantity: quantity,
            unit: resource.unit,
            deliveryAddress: deliveryAddress,
            notes: notes ?? '',
            paymentId: res['payment_id'] as String?,
            resourceName: resource.name,
            ownerName: resource.ownerName,
            receiptNo: res['receipt_no'] as String?,
            isEscrowHeld: res['escrow_held'] as bool? ?? true,
            createdAt: DateTime.now(),
          );
          _inMemoryBookings.insert(0, booking);
          return booking;
        }
      } catch (_) {
        // Fall back to in-memory creation on offline/mock
      }
    }

    final localBooking = ResourceBooking(
      id: 'bkg-${DateTime.now().millisecondsSinceEpoch}',
      resourceId: resourceId,
      renterId: renterId,
      startAt: startAt,
      endAt: endAt,
      totalPaise: totalPaise,
      status: ResourceBookingStatus.confirmed,
      quantity: quantity,
      unit: resource.unit,
      deliveryAddress: deliveryAddress,
      notes: notes ?? '',
      paymentId: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      resourceName: resource.name,
      ownerName: resource.ownerName,
      receiptNo: 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      isEscrowHeld: true,
      createdAt: DateTime.now(),
    );

    _inMemoryBookings.insert(0, localBooking);
    return localBooking;
  }

  @override
  Future<List<ResourceBooking>> getFarmerBookings(String renterId) async {
    if (_client != null) {
      try {
        final res = await _client
            .from('resource_bookings')
            .select('*, resource_listings(name, unit, price_paise)')
            .eq('renter_id', renterId)
            .order('created_at', ascending: false);

        if (res.isNotEmpty) {
          return res.map((e) => ResourceBooking.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    return _inMemoryBookings.where((b) => b.renterId == renterId || renterId.isEmpty).toList();
  }

  @override
  Future<List<FarmResource>> getVendorResources(String ownerId) async {
    if (_client != null) {
      try {
        final res = await _client
            .from('resource_listings')
            .select('*')
            .eq('owner_id', ownerId)
            .order('created_at', ascending: false);

        if (res.isNotEmpty) {
          return res.map((e) => FarmResource.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    return _inMemoryResources.where((r) => r.ownerId == ownerId || ownerId.isEmpty).toList();
  }

  @override
  Future<List<ResourceBooking>> getVendorBookings(String ownerId) async {
    if (_client != null) {
      try {
        final res = await _client
            .from('resource_bookings')
            .select('*, resource_listings!inner(owner_id, name, unit)')
            .eq('resource_listings.owner_id', ownerId)
            .order('created_at', ascending: false);

        if (res.isNotEmpty) {
          return res.map((e) => ResourceBooking.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    return _inMemoryBookings;
  }

  @override
  Future<ResourceBooking> updateBookingStatus(
    String bookingId,
    ResourceBookingStatus newStatus,
  ) async {
    if (_client != null) {
      try {
        await _client
            .from('resource_bookings')
            .update({'status': newStatus.dbValue})
            .eq('id', bookingId);
      } catch (_) {}
    }

    final index = _inMemoryBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final updated = _inMemoryBookings[index].copyWith(status: newStatus);
      _inMemoryBookings[index] = updated;
      return updated;
    }

    return ResourceBooking(
      id: bookingId,
      resourceId: '',
      renterId: '',
      startAt: DateTime.now(),
      endAt: DateTime.now().add(const Duration(hours: 4)),
      totalPaise: 85000,
      status: newStatus,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<FarmResource> createOrUpdateResource(FarmResource resource) async {
    if (_client != null) {
      try {
        if (resource.id.isNotEmpty && !resource.id.startsWith('res-local')) {
          await _client
              .from('resource_listings')
              .update(resource.toJson())
              .eq('id', resource.id);
        } else {
          final res = await _client
              .from('resource_listings')
              .insert(resource.toJson())
              .select()
              .single();
          return FarmResource.fromJson(res);
        }
      } catch (_) {}
    }

    final idx = _inMemoryResources.indexWhere((r) => r.id == resource.id);
    if (idx != -1) {
      _inMemoryResources[idx] = resource;
      return resource;
    } else {
      final newRes = resource.copyWith(
        id: resource.id.isEmpty
            ? 'res-local-${DateTime.now().millisecondsSinceEpoch}'
            : resource.id,
      );
      _inMemoryResources.insert(0, newRes);
      return newRes;
    }
  }
}
