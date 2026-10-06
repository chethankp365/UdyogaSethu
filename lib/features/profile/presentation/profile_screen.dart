import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/trust/data/kyc_repository.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';
import 'package:udyogasethu/features/trust/domain/verification_visibility.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

String formatIndianPhone(String? rawPhone) {
  if (rawPhone == null || rawPhone.isEmpty) return '';
  final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
  } else if (digits.length == 12 && digits.startsWith('91')) {
    final last10 = digits.substring(2);
    return '+91 ${last10.substring(0, 5)} ${last10.substring(5)}';
  }
  return rawPhone;
}

String getInitials(String name) {
  if (name.trim().isEmpty) return 'U';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.trim()[0].toUpperCase();
}

class ProfileScreen extends ConsumerStatefulWidget {
  final UserRole role;

  const ProfileScreen({super.key, required this.role});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _fullName = 'UdyogaSethu User';
  String? _avatarPath;
  String? _phone;
  String? _seekerType;
  bool _isVerifiedBadge = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  String _getUserId() {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client.auth.currentUser?.id ?? 'demo_user_123';
      }
    } catch (_) {}
    return 'demo_user_123';
  }

  Future<void> _loadProfileData() async {
    try {
      SupabaseClient? client;
      try {
        if (Supabase.instance.isInitialized) {
          client = Supabase.instance.client;
        }
      } catch (_) {}
      if (client == null) return;
      final user = client.auth.currentUser;
      if (user != null) {
        _phone = user.phone;
        try {
          final data = await client
              .from('profiles')
              .select('full_name, avatar_path')
              .eq('id', user.id)
              .maybeSingle();

          if (data != null && mounted) {
            setState(() {
              _fullName = (data['full_name'] as String?)?.isNotEmpty == true
                  ? data['full_name']
                  : (user.email ?? 'UdyogaSethu User');
              _avatarPath = data['avatar_path'] as String?;
            });
          }

          final wp = await client
              .from('worker_profiles')
              .select('seeker_type, is_verified_badge')
              .eq('user_id', user.id)
              .maybeSingle();
          if (wp != null && mounted) {
            setState(() {
              _seekerType = wp['seeker_type'] as String?;
              _isVerifiedBadge = wp['is_verified_badge'] == true;
            });
            if (widget.role == UserRole.seeker) {
              ref.read(appSessionProvider.notifier).setSeekerType(_seekerType);
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  String _getRoleDisplayName(String? seekerType) {
    switch (widget.role) {
      case UserRole.seeker:
        final norm = (seekerType ?? _seekerType)?.toLowerCase().replaceAll('-', '_');
        final typeLabel = (norm == 'student')
            ? 'Student'
            : (norm == 'part_time' ? 'Part-Time' : 'Informal');
        return 'Job Seeker · $typeLabel';
      case UserRole.provider:
        return 'Job Provider';
      case UserRole.farmer:
        return 'Farmer';
    }
  }

  Color _getRoleColor() {
    switch (widget.role) {
      case UserRole.seeker:
        return AppColors.headerGreenDark;
      case UserRole.provider:
        return AppColors.amberOrange;
      case UserRole.farmer:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(appSessionProvider);
    final activeSeekerType = session.seekerType ?? _seekerType;
    final visibleVerificationItems = verificationItemsFor(widget.role, activeSeekerType);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.profileTitle ?? 'My Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  UserAvatar(
                    avatarPath: _avatarPath,
                    name: _fullName,
                    radius: 42,
                    backgroundColor: _getRoleColor().withAlpha(38),
                    textColor: _getRoleColor(),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _fullName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      if (_isVerifiedBadge) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 22),
                      ],
                    ],
                  ),
                  if (_phone != null && _phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatIndianPhone(_phone),
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor().withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _getRoleColor().withAlpha(75)),
                        ),
                        child: Text(
                          _getRoleDisplayName(activeSeekerType),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getRoleColor()),
                        ),
                      ),
                      if (_isVerifiedBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_rounded, color: Colors.green, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Verified Worker',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Safety Onboarding & Verified Badge Quick Access Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0.5,
                color: _isVerifiedBadge ? Colors.green.shade50 : Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _isVerifiedBadge ? Colors.green.shade300 : Colors.amber.shade300,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isVerifiedBadge ? Colors.green.shade100 : Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isVerifiedBadge ? Icons.verified_user_rounded : Icons.shield_rounded,
                      color: _isVerifiedBadge ? Colors.green.shade800 : Colors.amber.shade900,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    _isVerifiedBadge ? 'UdyogaSethu Verified Worker Badge Active' : 'Safety Onboarding & Verified Badge',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _isVerifiedBadge ? Colors.green.shade900 : Colors.amber.shade900,
                    ),
                  ),
                  subtitle: Text(
                    _isVerifiedBadge
                        ? 'All 4 requirements complete (eKYC, Liveness, Training, Docs)'
                        : 'Complete registration, KYC and 1-day training to get verified',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isVerifiedBadge ? Colors.green.shade800 : AppColors.textDark,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.kycSafetyOnboarding),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Identity Verification Status List (Filtered by Role & Seeker Type Matrix)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: AppColors.headerGreenDark, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Identity Verification Badges',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      for (int i = 0; i < visibleVerificationItems.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 40),
                        _buildVerificationTile(visibleVerificationItems[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Digital ID Card & Scan to Verify Quick Access Group
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.digitalId),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.headerGreenDark.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.badge_rounded, color: AppColors.headerGreenDark, size: 22),
                              ),
                              const SizedBox(height: 8),
                              const Text('My Digital ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const Text('Show QR Pass', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.scanVerify),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.blue, size: 22),
                              ),
                              const SizedBox(height: 8),
                              const Text('Scan & Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const Text('Verify Worker', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Links Group
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security_rounded, color: Colors.teal, size: 20),
                      ),
                      title: const Text(
                        'Trust & Safety Centre',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Identity trust, escrow payments, and SOS safety', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.trustSafetyCentre),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.policy_rounded, color: Colors.indigo, size: 20),
                      ),
                      title: const Text(
                        'Trust, Governance & Rights',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Biometric consent, grievance officer & appeals', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.trustGovernanceRights),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.blue, size: 20),
                      ),
                      title: Text(
                        l10n?.privacyCentreTitle ?? 'Privacy Centre',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Consents, data rights, and permissions', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.privacyCentre),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.headerGreenDark.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings_rounded, color: AppColors.headerGreenDark, size: 20),
                      ),
                      title: Text(
                        l10n?.settingsTitle ?? 'Settings',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Language, accessibility, export & delete account', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.purple, size: 20),
                      ),
                      title: Text(
                        l10n?.termsAndPrivacyTitle ?? 'Terms & Privacy Policy',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Terms of service and legal draft notice', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.termsAndPrivacy),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Footer Notice
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'UdyogaSethu v1.0.0 • Verified Trust Network',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationTile(VerificationItemConfig item) {
    if (item.type == VerificationType.face) {
      return FutureBuilder<bool>(
        future: Supabase.instance.client
            .from('face_profiles')
            .select('id')
            .eq('user_id', _getUserId())
            .maybeSingle()
            .then((res) => res != null)
            .catchError((_) => false),
        builder: (context, snapshot) {
          final isVerified = snapshot.data ?? false;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green.shade50 : Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.face_retouching_natural,
                color: isVerified ? Colors.green : Colors.teal,
                size: 20,
              ),
            ),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
              isVerified ? 'Verified • Face Enrolled' : 'On-Device Liveness Template',
              style: TextStyle(fontSize: 12, color: isVerified ? Colors.green : AppColors.textMuted),
            ),
            trailing: isVerified
                ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: () => context.push(item.route),
          );
        },
      );
    }

    return StreamBuilder<KycRecord?>(
      stream: ref.watch(kycRepositoryProvider).watchKycRecord(
            _getUserId(),
            docType: item.docType,
          ),
      builder: (context, snapshot) {
        final record = snapshot.data;
        final isVerified = record?.isVerified ?? false;
        final isPending = record?.isPending ?? false;
        final isRejected = record?.isRejected ?? false;

        String subtitleText;
        Color subtitleColor;
        IconData iconData;
        Color iconBgColor;
        Color iconColor;

        switch (item.type) {
          case VerificationType.aadhaar:
            iconData = isVerified ? Icons.badge_rounded : Icons.fingerprint_rounded;
            iconBgColor = isVerified ? Colors.green.shade50 : Colors.amber.shade50;
            iconColor = isVerified ? Colors.green : Colors.amber.shade700;
            subtitleText = isVerified
                ? 'Verified • ${record?.maskedId ?? "XXXX-XXXX-4321"}'
                : 'Not Verified (Tap to start)';
            subtitleColor = isVerified ? Colors.green : AppColors.textMuted;
            break;

          case VerificationType.drivingLicence:
            iconData = isVerified ? Icons.directions_car_rounded : Icons.directions_car_outlined;
            iconBgColor = isVerified ? Colors.green.shade50 : (isPending ? Colors.amber.shade50 : Colors.grey.shade100);
            iconColor = isVerified ? Colors.green : (isPending ? Colors.amber.shade700 : AppColors.textMuted);
            subtitleText = isVerified
                ? 'Verified • ${record?.maskedId ?? ""}'
                : (isPending ? 'Pending Review' : 'Required for Driver/Delivery jobs');
            subtitleColor = isVerified ? Colors.green : (isPending ? Colors.amber.shade800 : AppColors.textMuted);
            break;

          case VerificationType.student:
            iconData = Icons.school_rounded;
            iconBgColor = isVerified ? Colors.green.shade50 : (isPending ? Colors.amber.shade50 : (isRejected ? Colors.red.shade50 : Colors.blue.shade50));
            iconColor = isVerified ? Colors.green : (isPending ? Colors.amber.shade700 : (isRejected ? Colors.red : Colors.blue));
            if (isVerified) {
              subtitleText = 'Verified Student ✓';
              subtitleColor = Colors.green;
            } else if (isPending) {
              subtitleText = 'Pending';
              subtitleColor = Colors.amber.shade800;
            } else if (isRejected) {
              subtitleText = 'Rejected (Tap to resubmit)';
              subtitleColor = Colors.red;
            } else {
              subtitleText = 'Not verified (tap to start)';
              subtitleColor = AppColors.textMuted;
            }
            break;

          case VerificationType.bankUpi:
            iconData = Icons.account_balance_wallet_rounded;
            iconBgColor = isVerified ? Colors.green.shade50 : Colors.grey.shade100;
            iconColor = isVerified ? Colors.green : AppColors.textMuted;
            subtitleText = isVerified
                ? 'Verified • ${record?.maskedId ?? "XXXX-5678"}'
                : 'Direct Payout Destination';
            subtitleColor = isVerified ? Colors.green : AppColors.textMuted;
            break;

          case VerificationType.backgroundCheck:
            iconData = Icons.security_rounded;
            iconBgColor = isVerified ? Colors.green.shade50 : (isPending ? Colors.amber.shade50 : Colors.purple.shade50);
            iconColor = isVerified ? Colors.green : (isPending ? Colors.amber.shade700 : Colors.purple);
            if (isVerified) {
              subtitleText = 'Status: Verified ✓';
              subtitleColor = Colors.green;
            } else if (isPending) {
              subtitleText = 'Status: Pending Review';
              subtitleColor = Colors.amber.shade800;
            } else if (isRejected) {
              subtitleText = 'Status: Rejected';
              subtitleColor = Colors.red;
            } else {
              subtitleText = 'Status: Not Requested';
              subtitleColor = AppColors.textMuted;
            }
            break;

          case VerificationType.face:
            iconData = Icons.face_retouching_natural;
            iconBgColor = isVerified ? Colors.green.shade50 : Colors.teal.shade50;
            iconColor = isVerified ? Colors.green : Colors.teal;
            subtitleText = isVerified
                ? 'Verified • ${record?.maskedId ?? "FACE-REF"}'
                : 'On-Device Liveness Template';
            subtitleColor = isVerified ? Colors.green : AppColors.textMuted;
            break;
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitleText, style: TextStyle(fontSize: 12, color: subtitleColor)),
          trailing: isVerified
              ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
              : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          onTap: () => context.push(item.route),
        );
      },
    );
  }
}
