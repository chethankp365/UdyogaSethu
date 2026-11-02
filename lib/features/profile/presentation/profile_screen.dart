import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/profile/presentation/seeker_type_change_dialog.dart';
import 'package:udyogasethu/features/profile/presentation/skills_picker_dialog.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';
import 'package:udyogasethu/features/trust/data/face_embedding_service.dart';
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

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  String _fullName = 'Chethan Kumar';
  String? _avatarPath;
  String? _phone;
  String _seekerType = 'informal';
  bool _isVerifiedBadge = false;
  List<String> _skills = [];
  String? _collegeName;
  String? _courseName;
  bool _hasEnrolledFace = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.role == UserRole.seeker) {
      _tabController = TabController(length: 3, vsync: this);
    }
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
      if (!Supabase.instance.isInitialized) return;
      final client = Supabase.instance.client;
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
                  : (user.email ?? 'Chethan Kumar');
              _avatarPath = data['avatar_path'] as String?;
            });
          }

          final wp = await client
              .from('worker_profiles')
              .select('seeker_type, is_verified_badge, selected_skills, college_name, course_name')
              .eq('user_id', user.id)
              .maybeSingle();
          if (wp != null && mounted) {
            setState(() {
              _seekerType = (wp['seeker_type'] as String?) ?? 'informal';
              _isVerifiedBadge = wp['is_verified_badge'] == true;
              _collegeName = wp['college_name'] as String?;
              _courseName = wp['course_name'] as String?;
              final rawSkills = wp['selected_skills'];
              if (rawSkills is List) {
                _skills = rawSkills.map((e) => e.toString()).toList();
              }
            });
            if (widget.role == UserRole.seeker) {
              ref.read(appSessionProvider.notifier).setSeekerType(_seekerType);
            }
          }

          try {
            final fp = await client
                .from('face_profiles')
                .select('id, status')
                .eq('user_id', user.id)
                .maybeSingle();
            final hasLocalFace = await ref.read(faceEmbeddingServiceProvider).hasEnrolledFace();
            final isEnrolled = (fp != null && fp['status'] == 'verified') || hasLocalFace;
            if (isEnrolled && mounted) {
              ref.read(appSessionProvider.notifier).setHasEnrolledFace(true);
              setState(() {
                _hasEnrolledFace = true;
              });
            }
          } catch (_) {}
        } catch (_) {}
      }
    } catch (_) {}
  }

  String _getCategoryTitle(String seekerType, AppLocalizations? l10n) {
    switch (seekerType) {
      case 'student':
        return l10n?.categoryStudentTitle ?? 'Student Gig Worker';
      case 'part_time':
        return l10n?.categoryPartTimeTitle ?? 'Part-Time Worker';
      case 'informal':
      default:
        return l10n?.categoryInformalTitle ?? 'Informal / Skilled Worker';
    }
  }

  String _getRoleDisplayName(String? seekerType) {
    switch (widget.role) {
      case UserRole.seeker:
        final norm = (seekerType ?? _seekerType).toLowerCase().replaceAll('-', '_');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(appSessionProvider);
    final activeSeekerType = session.seekerType ?? _seekerType;

    if (widget.role != UserRole.seeker) {
      return _buildGenericProfileScaffold(context, l10n, activeSeekerType);
    }

    final summaryAsync = ref.watch(seekerHomeSummaryProvider);
    final summary = summaryAsync.value ?? const SeekerHomeSummary();
    final profileAsync = ref.watch(seekerHomeProfileProvider);
    final profileDraft = profileAsync.value;

    final displayName = profileDraft?.fullName.isNotEmpty == true
        ? profileDraft!.fullName
        : _fullName;
    final displayPhone = _phone ?? '+91 98765 43210';
    final effectiveSeekerType = profileDraft?.seekerType ?? activeSeekerType;

    // Default skills based on audience if none currently in DB
    final displaySkills = _skills.isNotEmpty
        ? _skills
        : (effectiveSeekerType == 'student'
            ? ['Tutoring', 'Content Writing', 'Canva Design']
            : (effectiveSeekerType == 'part_time'
                ? ['Retail Assistant', 'Delivery Gig', 'Inventory']
                : ['Plumbing', 'Pipe Repair', 'Tap Fixing']));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildSeekerHeader(
                  context: context,
                  l10n: l10n,
                  name: displayName,
                  phone: displayPhone,
                  seekerType: effectiveSeekerType,
                  summary: summary,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.headerGreenDark,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.headerGreenDark,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: [
                      Tab(text: l10n?.tabOverview ?? 'Overview'),
                      Tab(text: l10n?.tabWorkShowcase ?? 'Work Showcase'),
                      Tab(text: l10n?.tabSafetyStatus ?? 'Safety Status'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(
                context: context,
                l10n: l10n,
                seekerType: effectiveSeekerType,
                skills: displaySkills,
                collegeName: profileDraft?.collegeName ?? _collegeName,
                courseName: profileDraft?.courseName ?? _courseName,
              ),
              _buildWorkShowcaseTab(context, l10n),
              _buildSafetyStatusTab(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // SEEKER HEADER (PAGE 3 PHONE 4)
  // ==========================================================================
  Widget _buildSeekerHeader({
    required BuildContext context,
    required AppLocalizations? l10n,
    required String name,
    required String phone,
    required String seekerType,
    required SeekerHomeSummary summary,
  }) {
    final categoryLabel = _getCategoryTitle(seekerType, l10n);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F3E2E), // Deep Forest Green
            Color(0xFF1B5E3C), // Emerald Dark
            Color(0xFF2E7D4E), // Leaf Green
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
      child: Column(
        children: [
          // Top row: Back button if canPop + Title + Digital ID button
          Row(
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: l10n?.back ?? 'Back',
                )
              else
                const SizedBox(width: 8),
              Text(
                l10n?.profileTitle ?? 'My Profile',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.badge_outlined, color: Colors.white),
                tooltip: 'Digital ID',
                onPressed: () => context.push(AppRoutes.digitalId),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Avatar with edit pencil overlay
          Center(
            child: Stack(
              children: [
                UserAvatar(
                  avatarPath: _avatarPath,
                  name: name,
                  radius: 46,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  textColor: Colors.white,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Avatar editing available in settings')),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.amberOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // User Full Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 3),

          // Formatted Phone
          Text(
            formatIndianPhone(phone),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          // Role Badge Chip (Job Seeker · Student / Job Seeker · Informal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getRoleDisplayName(seekerType),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Verified Badge Chip
          InkWell(
            onTap: _isVerifiedBadge
                ? null
                : () => context.push(AppRoutes.kycSafetyOnboarding),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _isVerifiedBadge
                    ? const Color(0xFF10B981) // Mint Green
                    : const Color(0xFFF59E0B), // Amber Warning
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isVerifiedBadge ? Icons.verified_rounded : Icons.shield_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isVerifiedBadge
                        ? (l10n?.verifiedWorkerBadge ?? 'UDYOGASETHU VERIFIED ✓')
                        : (l10n?.notVerifiedYet ?? 'Not verified yet'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Category Subtitle
          Text(
            l10n?.categoryPrefix(categoryLabel) ?? 'Category: $categoryLabel',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // 3 Live Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    value: _isVerifiedBadge ? '12' : '0',
                    label: l10n?.verifiedJobsStat ?? 'Verified Jobs',
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildStatColumn(
                    value: _isVerifiedBadge ? '4.8 ★' : 'New',
                    label: l10n?.ratingStat ?? 'Rating',
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.wallet),
                    borderRadius: BorderRadius.circular(8),
                    child: _buildStatColumn(
                      value: summary.walletBalanceRupees > 0
                          ? '₹${summary.walletBalanceRupees.toStringAsFixed(0)}'
                          : '₹0',
                      label: l10n?.totalEarningsStat ?? 'Total Earnings',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 1: OVERVIEW TAB (PAGE 3 PHONE 4)
  // ==========================================================================
  Widget _buildOverviewTab({
    required BuildContext context,
    required AppLocalizations? l10n,
    required String seekerType,
    required List<String> skills,
    String? collegeName,
    String? courseName,
  }) {
    final currentLocale = ref.watch(localeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ROLE CREDENTIALS & CATEGORY BADGES CARD
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          l10n?.roleCredentialsTitle ?? 'ROLE CREDENTIALS & CATEGORY BADGES',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.headerGreenDark,
                          side: const BorderSide(color: AppColors.headerGreenDark),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: () {
                          SeekerTypeChangeDialog.show(
                            context,
                            currentSeekerType: seekerType,
                            onTypeChanged: (newType) {
                              setState(() => _seekerType = newType);
                            },
                          );
                        },
                        child: Text(
                          l10n?.changeCategoryBtn ?? 'Change Category',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Driving Licence Chip
                  _buildCredentialTile(
                    icon: Icons.directions_car_rounded,
                    title: 'Driving Licence',
                    subtitle: 'Commercial & delivery authorization',
                    statusText: 'Verified ✓',
                    isVerified: true,
                    onTap: () => context.push(AppRoutes.kycDl),
                  ),

                  // Student Part-Time Verification Chip (Strictly shown ONLY for student seekers!)
                  if (seekerType == 'student') ...[
                    const Divider(height: 18),
                    _buildCredentialTile(
                      icon: Icons.school_rounded,
                      title: 'Student Verification',
                      subtitle: '${collegeName ?? "RV College of Engineering"} • ${courseName ?? "B.Tech"}',
                      statusText: _isVerifiedBadge ? 'Verified ✓' : 'Pending',
                      isVerified: _isVerifiedBadge,
                      onTap: () => context.push(AppRoutes.kycStudent),
                    ),
                  ],

                  const Divider(height: 18),

                  // Bank / UPI Chip
                  _buildCredentialTile(
                    icon: Icons.account_balance_rounded,
                    title: 'Bank / UPI Account',
                    subtitle: 'Direct DBT / Escrow payouts destination',
                    statusText: 'Linked ✓',
                    isVerified: true,
                    onTap: () => context.push(AppRoutes.kycBank),
                  ),

                  const Divider(height: 18),

                  // Background Verification Chip
                  _buildCredentialTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Background Verification',
                    subtitle: 'Police & criminal check validation',
                    statusText: _isVerifiedBadge ? 'Clear ✓' : 'Pending',
                    isVerified: _isVerifiedBadge,
                    onTap: () => context.push(AppRoutes.kycBackground),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. LANGUAGE & ACCESSIBILITY CARD (LIVE SWITCHER)
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.translate_rounded, color: AppColors.headerGreenDark, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.languageAccessibilityTitle ?? 'LANGUAGE & ACCESSIBILITY',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildLanguageChip(code: 'en', label: 'English', activeLocale: currentLocale),
                      _buildLanguageChip(code: 'kn', label: 'ಕನ್ನಡ', activeLocale: currentLocale),
                      _buildLanguageChip(code: 'hi', label: 'हिंदी', activeLocale: currentLocale),
                      _buildLanguageChip(code: 'te', label: 'తెలుగు', activeLocale: currentLocale),
                      _buildLanguageChip(code: 'ta', label: 'தமிழ்', activeLocale: currentLocale),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. MY SKILLS CARD
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.mySkillsTitle ?? 'MY SKILLS',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.headerGreenDark,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          l10n?.addSkillBtn ?? '+ Add Skill',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          SkillsPickerDialog.show(
                            context,
                            seekerType: seekerType,
                            currentSkills: skills,
                            onSkillsUpdated: (newSkills) {
                              setState(() => _skills = newSkills);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor: AppColors.paleMint.withValues(alpha: 0.6),
                        side: BorderSide(color: AppColors.cardBorderGreen.withValues(alpha: 0.8)),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headerGreenDark,
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.headerGreenDark),
                        onDeleted: () {
                          setState(() => _skills.remove(skill));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. VERIFICATION STATUS CARD
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.headerGreenDark, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.verificationStatusTitle ?? 'VERIFICATION STATUS',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildStatusRow(
                    title: 'Aadhaar eKYC Verification',
                    detail: 'Masked: XXXX-XXXX-4321',
                    isComplete: true,
                    onTap: () => context.push(AppRoutes.kyc),
                  ),
                  const Divider(height: 16),
                  _buildStatusRow(
                    title: 'Face Enrolment & Liveness',
                    detail: (ref.watch(appSessionProvider).hasEnrolledFace || _hasEnrolledFace)
                        ? 'Biometric profile active'
                        : 'Not enrolled (Tap to enroll)',
                    isComplete: ref.watch(appSessionProvider).hasEnrolledFace || _hasEnrolledFace,
                    onTap: () async {
                      await context.push(AppRoutes.kycFace);
                      if (mounted) {
                        _loadProfileData();
                      }
                    },
                  ),
                  const Divider(height: 16),
                  _buildStatusRow(
                    title: '1-Day Safety & Protocol Training',
                    detail: _isVerifiedBadge ? 'Completed & certified' : 'Pending slot booking',
                    isComplete: _isVerifiedBadge,
                    onTap: () => context.push(AppRoutes.kycSafetyOnboarding),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 5. ACCOUNT AND SAFETY NAVIGATION CARD
          _buildAccountAndSafetyCard(context, l10n),

          const SizedBox(height: 24),

          // Footer
          const Center(
            child: Text(
              'UdyogaSethu v1.0.0 • Verified Trust Network',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required bool isVerified,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green.shade50 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: isVerified ? Colors.green.shade700 : AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isVerified ? Colors.green.shade300 : Colors.amber.shade300),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isVerified ? Colors.green.shade800 : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageChip({
    required String code,
    required String label,
    required Locale activeLocale,
  }) {
    final isSelected = activeLocale.languageCode == code;

    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(code);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.headerGreenDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.headerGreenDark.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required String title,
    required String detail,
    required bool isComplete,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isComplete ? Colors.green : Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: WORK SHOWCASE TAB (PAGE 4 PHONE 2)
  // ==========================================================================
  Widget _buildWorkShowcaseTab(BuildContext context, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 36),
          // Clean empty state illustration / badge
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.paleMint.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorderGreen, width: 1.5),
            ),
            child: const Icon(
              Icons.work_history_rounded,
              color: AppColors.headerGreenDark,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n?.emptyShowcaseTitle ?? 'Your completed jobs, photos and ratings will appear here',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n?.emptyShowcaseSubtitle ??
                'Once you complete jobs through UdyogaSethu, verified employer reviews, photos of your work, and earnings will be showcased here to help you get hired faster.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(
                  l10n?.browseJobsAction ?? 'Browse Jobs',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  context.go(AppRoutes.seekerHome);
                },
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.headerGreenDark,
                  side: const BorderSide(color: AppColors.cardBorderGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text(
                  'Job History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  context.push(AppRoutes.jobHistory);
                },
              ),
            ],
          ),
          const SizedBox(height: 36),
          _buildAccountAndSafetyCard(context, l10n),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: SAFETY STATUS TAB (SAFETY LIFECYCLE)
  // ==========================================================================
  Widget _buildSafetyStatusTab(BuildContext context, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0.5,
            color: _isVerifiedBadge ? Colors.green.shade50 : Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _isVerifiedBadge ? Colors.green.shade300 : Colors.amber.shade300,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isVerifiedBadge ? Icons.verified_user_rounded : Icons.shield_outlined,
                        color: _isVerifiedBadge ? Colors.green.shade800 : Colors.amber.shade900,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isVerifiedBadge
                              ? 'Safety Verified Worker Badge Active'
                              : (l10n?.safetyLifecycleTitle ?? 'Safety Onboarding & Badges'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _isVerifiedBadge ? Colors.green.shade900 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isVerifiedBadge
                        ? 'All 4 verification standards complete. Employers can hire with zero friction and escrow insurance active.'
                        : 'Complete registration, Aadhaar eKYC, and 1-day safety protocol to become a verified UdyogaSethu professional.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isVerifiedBadge ? Colors.green.shade800 : AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isVerifiedBadge ? Colors.green.shade700 : AppColors.headerGreenDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 42),
                    ),
                    onPressed: () => context.push(AppRoutes.kycSafetyOnboarding),
                    child: Text(
                      _isVerifiedBadge ? 'View Safety Certificate' : 'Continue Safety Verification ->',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAccountAndSafetyCard(context, l10n),
        ],
      ),
    );
  }

  // ==========================================================================
  // SHARED: ACCOUNT AND SAFETY NAVIGATION CARD
  // ==========================================================================
  Widget _buildAccountAndSafetyCard(BuildContext context, AppLocalizations? l10n) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n?.accountAndSafetyTitle ?? 'Account & Safety',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (widget.role == UserRole.seeker) ...[
            ListTile(
              leading: _buildCircleIcon(Icons.badge_rounded, AppColors.headerGreenDark),
              title: const Text('My Digital ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Verified digital ID & QR code', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.digitalId),
            ),
            const Divider(height: 1, indent: 56),
          ] else if (widget.role == UserRole.provider) ...[
            ListTile(
              leading: _buildCircleIcon(Icons.qr_code_scanner_rounded, Colors.blue),
              title: const Text('Scan & Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Verify worker credentials instantly', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.scanVerify),
            ),
            const Divider(height: 1, indent: 56),
          ],
          ListTile(
            leading: _buildCircleIcon(Icons.military_tech_rounded, Colors.amber.shade800),
            title: Text(l10n?.rewardsHubTitle ?? 'Rewards & Progression Hub',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('XP, Level perks, badges, streaks & store', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.rewards),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.forum_rounded, Colors.teal),
            title: Text(l10n?.communityHubTitle ?? 'Community & Trust Wall',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Top workers, locality trust index & training events', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.community),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.school_rounded, Colors.indigo),
            title: Text(l10n?.learningHubTitle ?? 'Skill & Learning Hub',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Micro-courses, assessment quizzes & credentials', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.learning),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.account_balance_wallet_rounded, const Color(0xFF0D6548)),
            title: const Text('Wallet & Escrow', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Balance, protected escrow, and withdrawals', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.wallet),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.history_rounded, Colors.orange),
            title: const Text('Job History & Ratings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Past jobs, reviews, and dispute status', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.jobHistory),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.favorite_rounded, Colors.red),
            title: const Text('Favourites & Trust Circles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Trusted repeat workers and farmers', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.favourites),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.security_rounded, Colors.teal),
            title: const Text('Trust & Safety Centre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Identity trust, escrow payments, and SOS safety', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.trustSafetyCentre),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.policy_rounded, Colors.indigo),
            title: const Text('Trust, Governance & Rights', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Biometric consent, grievance officer & appeals', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.trustGovernanceRights),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.shield_rounded, Colors.blue),
            title: Text(l10n?.privacyCentreTitle ?? 'Privacy Centre', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Consents, data rights, and permissions', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.privacyCentre),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.settings_rounded, AppColors.headerGreenDark),
            title: Text(l10n?.settingsTitle ?? 'Settings', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Language, accessibility, and account', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.settings),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _buildCircleIcon(Icons.description_rounded, Colors.purple),
            title: Text(l10n?.termsAndPrivacyTitle ?? 'Terms & Privacy Policy', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Terms of service and legal notice', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.termsAndPrivacy),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  // ==========================================================================
  // FALLBACK FOR PROVIDER / FARMER
  // ==========================================================================
  Widget _buildGenericProfileScaffold(BuildContext context, AppLocalizations? l10n, String? activeSeekerType) {
    final visibleVerificationItems = verificationItemsFor(widget.role, activeSeekerType);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.profileTitle ?? 'My Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: UserAvatar(
                avatarPath: _avatarPath,
                name: _fullName,
                radius: 42,
              ),
            ),
            const SizedBox(height: 12),
            Text(_fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_phone != null) ...[
              const SizedBox(height: 4),
              Text(formatIndianPhone(_phone), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.headerGreenDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getRoleDisplayName(activeSeekerType),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  for (final item in visibleVerificationItems) ...[
                    _buildVerificationTile(item),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAccountAndSafetyCard(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationTile(VerificationItemConfig item) {
    return StreamBuilder<KycRecord?>(
      stream: ref.watch(kycRepositoryProvider).watchKycRecord(_getUserId(), docType: item.docType),
      builder: (context, snapshot) {
        final record = snapshot.data;
        final isVerified = record?.isVerified ?? false;
        return ListTile(
          leading: Icon(isVerified ? Icons.verified_rounded : Icons.pending_rounded,
              color: isVerified ? Colors.green : Colors.amber),
          title: Text(item.title),
          subtitle: Text(isVerified ? 'Verified ✓' : 'Pending'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(item.route),
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
