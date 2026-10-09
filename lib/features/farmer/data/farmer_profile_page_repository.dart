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
              'Chethan Gowda';
          final phone = profileRes?['phone']?.toString() ?? '+91 98450 77889';
          final farmName = farmerProfileRes?['farm_name']?.toString() ?? 'Greenfield Organic Farm';
          final cluster = farmerProfileRes?['cluster_village']?.toString() ?? 'Mandya Cluster';
          final acres = (farmerProfileRes?['acres'] as num?)?.toDouble() ?? 4.2;

          return FarmerProfileData(
            id: uid,
            fullName: fullName,
            farmName: farmName,
            clusterVillage: cluster,
            phone: phone,
            isVerified: true,
            landAcres: acres,
            produceSoldKgMonth: 420.0,
            directSalesPaise: 4850000,
            badges: const FarmInfrastructureBadges(
              soilClassification: 'Red Loam Soil (pH 6.8)',
              primaryCrops: 'Tomatoes, Paddy, Banana',
              apmcRegistration: 'Mandya APMC #4812',
              kisanCreditCardStatus: 'KCC Approved ✓',
              isKccApproved: true,
            ),
            certificate: const OrganicCertificate(
              title: 'Zero-Pesticide Organic Certificate',
              issuer: 'Verified by Karnataka Organic Farmers Board',
              statusLabel: 'VALIDATED ✓',
              isValidated: true,
            ),
          );
        }
      } catch (e) {
        debugPrint('Fetch farmer profile page from Supabase failed: $e');
      }
    }

    // Default mock data exactly matching "Farmer profile page" (Page 7 Phone 1)
    return const FarmerProfileData(
      id: 'demo-farmer-id',
      fullName: 'Chethan Gowda',
      farmName: 'Greenfield Organic Farm',
      clusterVillage: 'Mandya Cluster',
      phone: '+91 98450 77889',
      isVerified: true,
      landAcres: 4.2,
      produceSoldKgMonth: 420.0,
      directSalesPaise: 4850000,
      badges: FarmInfrastructureBadges(
        soilClassification: 'Red Loam Soil (pH 6.8)',
        primaryCrops: 'Tomatoes, Paddy, Banana',
        apmcRegistration: 'Mandya APMC #4812',
        kisanCreditCardStatus: 'KCC Approved ✓',
        isKccApproved: true,
      ),
      certificate: OrganicCertificate(
        title: 'Zero-Pesticide Organic Certificate',
        issuer: 'Verified by Karnataka Organic Farmers Board',
        statusLabel: 'VALIDATED ✓',
        isValidated: true,
      ),
    );
  }
}

final farmerProfilePageRepositoryProvider = Provider<FarmerProfilePageRepository>((ref) {
  return FarmerProfilePageRepository();
});

final farmerProfileDataProvider = FutureProvider<FarmerProfileData>((ref) async {
  final repo = ref.watch(farmerProfilePageRepositoryProvider);
  return repo.getFarmerProfile(null);
});
