import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';

enum VerificationType {
  aadhaar,
  drivingLicence,
  student,
  bankUpi,
  backgroundCheck,
  face,
}

class VerificationItemConfig {
  final VerificationType type;
  final String title;
  final String docType;
  final String route;

  const VerificationItemConfig({
    required this.type,
    required this.title,
    required this.docType,
    required this.route,
  });
}

/// The single source of truth for verification item visibility across all roles & seeker types.
///
/// Matrix:
/// - Aadhaar eKYC: All roles & seeker types
/// - Driving Licence: Seekers only (informal, student, part_time). Hidden for provider and farmer.
/// - Student Verification: seeker_type == 'student' ONLY. Hidden for informal, part_time, provider, and farmer.
/// - Bank / UPI Payout: Seekers and Farmers. Hidden for providers.
/// - Background Verification: Seekers and Providers. Hidden for farmers.
/// - Face Enrolment: All roles.
bool isVerificationItemVisible({
  required VerificationType type,
  required UserRole role,
  required String? seekerType,
}) {
  final normSeekerType = seekerType?.toLowerCase().replaceAll('-', '_');

  switch (type) {
    case VerificationType.aadhaar:
      return true;
    case VerificationType.drivingLicence:
      return role == UserRole.seeker;
    case VerificationType.student:
      return role == UserRole.seeker && normSeekerType == 'student';
    case VerificationType.bankUpi:
      return role == UserRole.seeker || role == UserRole.farmer;
    case VerificationType.backgroundCheck:
      return role == UserRole.seeker || role == UserRole.provider;
    case VerificationType.face:
      return true;
  }
}

List<VerificationItemConfig> verificationItemsFor(UserRole role, String? seekerType) {
  const allConfigs = [
    VerificationItemConfig(
      type: VerificationType.aadhaar,
      title: 'Aadhaar eKYC Verification',
      docType: 'aadhaar',
      route: AppRoutes.kyc,
    ),
    VerificationItemConfig(
      type: VerificationType.drivingLicence,
      title: 'Driving Licence',
      docType: 'driving_licence',
      route: AppRoutes.kycDl,
    ),
    VerificationItemConfig(
      type: VerificationType.student,
      title: 'Student Verification',
      docType: 'college_id',
      route: AppRoutes.kycStudent,
    ),
    VerificationItemConfig(
      type: VerificationType.bankUpi,
      title: 'Bank / UPI Account',
      docType: 'bank_account',
      route: AppRoutes.kycBank,
    ),
    VerificationItemConfig(
      type: VerificationType.backgroundCheck,
      title: 'Background Verification',
      docType: 'background_check',
      route: AppRoutes.kycBackground,
    ),
    VerificationItemConfig(
      type: VerificationType.face,
      title: 'Face Enrolment & Liveness',
      docType: 'face',
      route: AppRoutes.kycFace,
    ),
  ];

  return allConfigs
      .where((item) => isVerificationItemVisible(
            type: item.type,
            role: role,
            seekerType: seekerType,
          ))
      .toList();
}

/// Riverpod FutureProvider for retrieving the active user's seeker_type if signed in as a seeker.
final userSeekerTypeProvider = FutureProvider<String?>((ref) async {
  final session = ref.watch(appSessionProvider);
  if (session.activeRole != UserRole.seeker) return null;
  if (session.seekerType != null && session.seekerType!.isNotEmpty) {
    return session.seekerType;
  }

  try {
    if (!Supabase.instance.isInitialized) return null;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final res = await Supabase.instance.client
          .from('worker_profiles')
          .select('seeker_type')
          .eq('user_id', user.id)
          .maybeSingle();
      if (res != null && res['seeker_type'] != null) {
        return res['seeker_type'] as String?;
      }
    }
  } catch (_) {}
  return null;
});
