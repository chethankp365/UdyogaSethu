import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_model.dart';

class FarmerProfilePageRepository {
  final SupabaseClient? _supabase;

  FarmerProfilePageRepository([SupabaseClient? client])
      : _supabase = client ?? _safeClient();

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<FarmerProfileData> getFarmerProfile(String? farmerId) async {
    final uid = farmerId ?? _supabase?.auth.currentUser?.id;

    if (_supabase != null && uid != null && uid.isNotEmpty) {
      try {
        final profileRes = await _supabase
            .from('profiles')
            .select()
            .eq('id', uid)
            .maybeSingle();

        final farmerProfileRes = await _supabase
            .from('farmer_profiles')
            .select()
            .eq('user_id', uid)
            .maybeSingle();

        if (profileRes != null || farmerProfileRes != null) {
          final fullName = profileRes?['full_name']?.toString() ??
              farmerProfileRes?['farmer_name']?.toString() ??
              'Farmer';
          final phone = profileRes?['phone']?.toString() ?? '';
          final avatarPath = profileRes?['avatar_path']?.toString();
          final isKycVerified = profileRes?['is_verified'] == true;
          final farmName = farmerProfileRes?['farm_name']?.toString() ?? 'My Farm';
          final cluster = farmerProfileRes?['cluster_village']?.toString() ?? 'Agri Cluster';
          final acres = (farmerProfileRes?['acres'] as num?)?.toDouble() ?? 0.0;
          final soil = farmerProfileRes?['soil_type']?.toString();
          final method = farmerProfileRes?['farming_method']?.toString();
          final crops = farmerProfileRes?['primary_crops'] is List
              ? (farmerProfileRes!['primary_crops'] as List).join(', ')
              : farmerProfileRes?['primary_crops']?.toString();
          final apmc = farmerProfileRes?['apmc_registration']?.toString() ??
              farmerProfileRes?['apmc_mandi']?.toString();
          final kccStatus = farmerProfileRes?['kcc_status']?.toString();
          final deliveryRadius = (farmerProfileRes?['delivery_radius_km'] as num?)?.toDouble() ?? 25.0;
          final pickupAvailable = farmerProfileRes?['pickup_available'] != false;
          final leadTime = (farmerProfileRes?['lead_time_hours'] as num?)?.toInt() ?? 24;
          final farmPhoto = farmerProfileRes?['farm_photo_url']?.toString();

          // Organic Certificate
          final certNo = farmerProfileRes?['organic_cert_number']?.toString();
          final certPath = farmerProfileRes?['organic_cert_path']?.toString();
          final certStatus = farmerProfileRes?['organic_cert_status']?.toString();
          final isAdminValidated = certStatus != null &&
              (certStatus.toLowerCase() == 'verified' || certStatus.toLowerCase() == 'validated');

          // Compute real stats from orders (0 for new farmer)
          int realSalesPaise = 0;
          double realSoldKg = 0.0;
          try {
            final ordersRes = await _supabase
                .from('orders')
                .select('total_paise, items:order_items(quantity)')
                .eq('seller_id', uid)
                .eq('status', 'delivered');

            for (final ord in ordersRes) {
              realSalesPaise += (ord['total_paise'] as num?)?.toInt() ?? 0;
              if (ord['items'] is List) {
                for (final item in ord['items']) {
                  realSoldKg += (item['quantity'] as num?)?.toDouble() ?? 0.0;
                }
              }
            }
          } catch (_) {
            // Keep 0 if orders table query encounters an issue
          }

          return FarmerProfileData(
            id: uid,
            fullName: fullName,
            farmName: farmName,
            clusterVillage: cluster,
            phone: phone,
            avatarUrl: avatarPath,
            isKycVerified: isKycVerified,
            landAcres: acres,
            produceSoldKgMonth: realSoldKg,
            directSalesPaise: realSalesPaise,
            badges: FarmInfrastructureBadges(
              soilClassification: soil,
              primaryCrops: crops,
              farmingMethod: method,
              apmcRegistration: apmc,
              kisanCreditCardStatus: kccStatus,
              isKccVerified: isKycVerified && kccStatus != null,
              deliveryRadiusKm: deliveryRadius,
              pickupAvailable: pickupAvailable,
              leadTimeHours: leadTime,
              farmPhotoUrl: farmPhoto,
            ),
            certificate: OrganicCertificate(
              title: certNo != null ? 'Organic Certificate' : null,
              issuer: isAdminValidated ? 'Verified by Organic Certification Board' : null,
              statusLabel: isAdminValidated
                  ? 'VALIDATED ✓'
                  : (certNo != null ? 'Self-declared, not verified yet' : 'Not added'),
              isValidatedByAdmin: isAdminValidated,
              certificateNumber: certNo,
              documentPath: certPath,
            ),
          );
        }
      } catch (e) {
        debugPrint('Fetch farmer profile page from Supabase failed: $e');
      }
    }

    // Default zero state for fresh or offline farmer (No fake demo constants per Prompt F1)
    return const FarmerProfileData(
      id: 'fresh-farmer',
      fullName: 'Farmer',
      farmName: 'My Farm',
      clusterVillage: 'Agri Cluster',
      phone: '',
      isKycVerified: false,
      landAcres: 0.0,
      produceSoldKgMonth: 0.0,
      directSalesPaise: 0,
      badges: FarmInfrastructureBadges(
        soilClassification: null,
        primaryCrops: null,
        farmingMethod: null,
        apmcRegistration: null,
        kisanCreditCardStatus: null,
        isKccVerified: false,
        deliveryRadiusKm: 25.0,
        pickupAvailable: true,
        leadTimeHours: 24,
      ),
      certificate: OrganicCertificate(
        title: null,
        issuer: null,
        statusLabel: 'Self-declared, not verified yet',
        isValidatedByAdmin: false,
        certificateNumber: null,
      ),
    );
  }

  Future<Map<String, dynamic>> updateFarmDetails({
    required String farmName,
    required String clusterVillage,
    required double acres,
    required String soilType,
    required String farmingMethod,
    required String primaryCrops,
    required double deliveryRadiusKm,
    required bool pickupAvailable,
    required int leadTimeHours,
    String? farmPhotoUrl,
    String? apmcRegistration,
    String? kccStatus,
    String? organicCertNumber,
    String? organicCertPath,
  }) async {
    final uid = _supabase?.auth.currentUser?.id;
    final cropsList = primaryCrops
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final payload = <String, dynamic>{
      'farm_name': farmName,
      'cluster_village': clusterVillage,
      'acres': acres,
      'soil_type': soilType,
      'farming_method': farmingMethod,
      'primary_crops': cropsList,
      'delivery_radius_km': deliveryRadiusKm,
      'pickup_available': pickupAvailable,
      'lead_time_hours': leadTimeHours,
      'delivery_options': {
        'delivery_available': true,
        'pickup_available': pickupAvailable,
        'delivery_radius_km': deliveryRadiusKm,
        'lead_time': '$leadTimeHours hrs',
      },
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (farmPhotoUrl != null && farmPhotoUrl.isNotEmpty) {
      payload['farm_photo_url'] = farmPhotoUrl;
    }
    if (apmcRegistration != null && apmcRegistration.isNotEmpty) {
      payload['apmc_registration'] = apmcRegistration;
    }
    if (kccStatus != null && kccStatus.isNotEmpty) {
      payload['kcc_status'] = kccStatus;
    }
    if (organicCertNumber != null && organicCertNumber.isNotEmpty) {
      payload['organic_cert_number'] = organicCertNumber;
    }
    if (organicCertPath != null && organicCertPath.isNotEmpty) {
      payload['organic_cert_path'] = organicCertPath;
    }

    if (uid != null) {
      payload['user_id'] = uid;
    }

    if (_supabase != null && uid != null) {
      final res = await _supabase.from('farmer_profiles').upsert(payload).select().single();
      return Map<String, dynamic>.from(res);
    }

    return payload;
  }
}

final farmerProfilePageRepositoryProvider = Provider<FarmerProfilePageRepository>((ref) {
  return FarmerProfilePageRepository();
});

final farmerProfileDataProvider = FutureProvider<FarmerProfileData>((ref) async {
  final repo = ref.watch(farmerProfilePageRepositoryProvider);
  return repo.getFarmerProfile(null);
});
