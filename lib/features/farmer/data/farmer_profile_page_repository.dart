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
          final isVerified = profileRes?['is_verified'] == true;
          final farmName = farmerProfileRes?['farm_name']?.toString() ?? 'My Farm';
          final cluster = farmerProfileRes?['cluster_village']?.toString() ?? 'Agri Cluster';
          final acres = (farmerProfileRes?['acres'] as num?)?.toDouble() ?? 0.0;
          final soil = farmerProfileRes?['soil_type']?.toString() ?? 'Self-Declared';
          final crops = farmerProfileRes?['primary_crops'] is List
              ? (farmerProfileRes!['primary_crops'] as List).join(', ')
              : (farmerProfileRes?['primary_crops']?.toString() ?? 'Seasonal Crops');
          final apmc = farmerProfileRes?['apmc_mandi']?.toString() ?? 'Local Mandi';
          final soldKg = (farmerProfileRes?['produce_sold_kg'] as num?)?.toDouble() ?? 0.0;
          final salesPaise = (farmerProfileRes?['direct_sales_paise'] as num?)?.toInt() ?? 0;

          return FarmerProfileData(
            id: uid,
            fullName: fullName,
            farmName: farmName,
            clusterVillage: cluster,
            phone: phone,
            avatarUrl: avatarPath,
            isVerified: isVerified,
            landAcres: acres,
            produceSoldKgMonth: soldKg,
            directSalesPaise: salesPaise,
            badges: FarmInfrastructureBadges(
              soilClassification: soil,
              primaryCrops: crops,
              apmcRegistration: apmc,
              kisanCreditCardStatus: isVerified ? 'KCC Verified ✓' : 'Self-Declared',
              isKccApproved: isVerified,
            ),
            certificate: OrganicCertificate(
              title: 'Zero-Pesticide Organic Certificate',
              issuer: 'Karnataka Organic Farmers Board',
              statusLabel: isVerified ? 'VALIDATED ✓' : 'SELF-DECLARED',
              isValidated: isVerified,
            ),
          );
        }
      } catch (e) {
        debugPrint('Fetch farmer profile page from Supabase failed: $e');
      }
    }

    // Default mock data (Zero stats for fresh user, honest self-declared status)
    return const FarmerProfileData(
      id: 'demo-farmer-id',
      fullName: 'Chethan Gowda',
      farmName: 'Greenfield Organic Farm',
      clusterVillage: 'Mandya Cluster',
      phone: '+91 98450 77889',
      isVerified: false,
      landAcres: 4.2,
      produceSoldKgMonth: 0.0,
      directSalesPaise: 0,
      badges: FarmInfrastructureBadges(
        soilClassification: 'Red Loam Soil (pH 6.8)',
        primaryCrops: 'Tomatoes, Paddy, Banana',
        apmcRegistration: 'Mandya APMC #4812',
        kisanCreditCardStatus: 'Self-Declared',
        isKccApproved: false,
      ),
      certificate: OrganicCertificate(
        title: 'Zero-Pesticide Organic Certificate',
        issuer: 'Karnataka Organic Farmers Board',
        statusLabel: 'SELF-DECLARED',
        isValidated: false,
      ),
    );
  }

  Future<void> updateFarmDetails({
    required String farmName,
    required String clusterVillage,
    required double acres,
    required String soilType,
    required String primaryCrops,
    String? apmcMandi,
  }) async {
    final uid = _supabase?.auth.currentUser?.id;
    if (_supabase != null && uid != null) {
      final payload = <String, dynamic>{
        'user_id': uid,
        'farm_name': farmName,
        'cluster_village': clusterVillage,
        'acres': acres,
        'soil_type': soilType,
        'primary_crops': primaryCrops,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (apmcMandi != null) {
        payload['apmc_mandi'] = apmcMandi;
      }
      await _supabase.from('farmer_profiles').upsert(payload);
    }
  }
}

final farmerProfilePageRepositoryProvider = Provider<FarmerProfilePageRepository>((ref) {
  return FarmerProfilePageRepository();
});

final farmerProfileDataProvider = FutureProvider<FarmerProfileData>((ref) async {
  final repo = ref.watch(farmerProfilePageRepositoryProvider);
  return repo.getFarmerProfile(null);
});
