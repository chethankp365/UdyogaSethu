import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/farmer/data/farmer_profile_page_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_model.dart';
import 'package:udyogasethu/features/farmer/presentation/widgets/edit_farm_details_dialog.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FarmerProfileScreen extends ConsumerWidget {
  const FarmerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(farmerProfileDataProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
        title: Text(
          l10n?.farmerProfileTitle ?? 'Farmer Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: l10n?.navSettings ?? 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF064E3B)),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error loading profile: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(farmerProfileDataProvider),
                  child: Text(l10n?.retry ?? 'Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) => RefreshIndicator(
          color: const Color(0xFF064E3B),
          onRefresh: () async {
            ref.invalidate(farmerProfileDataProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. FOREST GREEN HERO CARD
                _buildHeroCard(context, profile, l10n),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2. FARM INFRASTRUCTURE & CROP BADGES
                      _buildInfrastructureSection(context, profile, l10n),

                      const SizedBox(height: 14),

                      // 3. ZERO-PESTICIDE ORGANIC CERTIFICATE CARD
                      _buildCertificateCard(context, profile.certificate, l10n),

                      const SizedBox(height: 14),

                      // 4. LANGUAGE MODE CARD
                      _buildLanguageModeCard(context, ref, currentLocale, l10n),

                      const SizedBox(height: 14),

                      // 5. MANAGE PRODUCE LISTINGS SHORTCUT BUTTON
                      _buildManageProduceShortcut(context, l10n),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. FOREST GREEN HERO CARD
  // ---------------------------------------------------------------------------
  Widget _buildHeroCard(
    BuildContext context,
    FarmerProfileData profile,
    AppLocalizations? l10n,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF064E3B), // Deep Forest Green
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with mint border
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF042F2E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF34D399),
                    width: 2.2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: UserAvatar(
                    avatarPath: profile.avatarUrl,
                    name: profile.fullName,
                    radius: 34,
                    backgroundColor: const Color(0xFF042F2E),
                    textColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Name, Verified tag, Farm Name, Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farmer ${profile.fullName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Verified Farmer Tag vs Self-Declared Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: profile.isKycVerified ? const Color(0xFF2DD4BF) : Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        profile.isKycVerified
                            ? (l10n?.verifiedFarmer ?? 'VERIFIED FARMER ✓')
                            : (l10n?.selfDeclaredProfile ?? 'SELF-DECLARED PROFILE'),
                        style: TextStyle(
                          color: profile.isKycVerified ? const Color(0xFF064E3B) : Colors.brown.shade900,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Farm name & cluster
                    Text(
                      '${profile.farmName} • ${profile.clusterVillage}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Phone Number
                    Text(
                      profile.phone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Shield Icon on top right
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  profile.isKycVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
                  color: profile.isKycVerified ? const Color(0xFF6EE7B7) : Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3 Live Metric Boxes (Land, Sold This Month, Direct Sales)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Metric 1: Land (Acres)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${profile.landAcres} Acres',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n?.organicLand ?? 'Organic Land',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.2),
                ),

                // Metric 2: Sold This Month (kg)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${NumberFormat('#,##0').format(profile.produceSoldKgMonth.round())} kg',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24), // Amber / Gold
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n?.soldThisMonth ?? 'Sold This Month',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.2),
                ),

                // Metric 3: Direct Sales (₹)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '₹${NumberFormat('#,##0').format(profile.directSalesRupees.round())}',
                        style: const TextStyle(
                          color: Color(0xFF34D399), // Mint Green
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n?.directSales ?? 'Direct Sales',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Edit Farm Details Button
          OutlinedButton.icon(
            key: const Key('hero_edit_farm_button'),
            onPressed: () => EditFarmDetailsDialog.show(context, profile),
            icon: const Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
            label: Text(
              l10n?.editFarmDetails ?? 'Edit Farm Details',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FARM INFRASTRUCTURE & CROP BADGES
  // ---------------------------------------------------------------------------
  Widget _buildInfrastructureSection(
    BuildContext context,
    FarmerProfileData profile,
    AppLocalizations? l10n,
  ) {
    final badges = profile.badges;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌾', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.farmInfrastructureAndBadges ?? 'FARM INFRASTRUCTURE & CROP BADGES',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('edit_farm_details_button'),
                onPressed: () => EditFarmDetailsDialog.show(context, profile),
                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF064E3B)),
                label: Text(
                  l10n?.edit ?? 'Edit',
                  style: const TextStyle(
                    color: Color(0xFF064E3B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Grid of Badges
          Row(
            children: [
              Expanded(
                child: _buildBadgeTile(
                  caption: l10n?.soilClassification ?? 'SOIL CLASSIFICATION',
                  value: badges.soilClassification?.isNotEmpty == true
                      ? badges.soilClassification!
                      : 'Not specified',
                  valueColor: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBadgeTile(
                  caption: l10n?.primaryCrops ?? 'PRIMARY CROPS',
                  value: badges.primaryCrops?.isNotEmpty == true
                      ? badges.primaryCrops!
                      : 'Not specified',
                  valueColor: const Color(0xFF047857), // Green
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildBadgeTile(
                  caption: l10n?.apmcRegistration ?? 'APMC REGISTRATION',
                  value: badges.apmcRegistration?.isNotEmpty == true
                      ? badges.apmcRegistration!
                      : 'Not added',
                  subLabel: '(Self-declared, not verified yet)',
                  valueColor: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBadgeTile(
                  caption: l10n?.kisanCreditCard ?? 'KISAN CREDIT CARD',
                  value: badges.kisanCreditCardStatus?.isNotEmpty == true
                      ? badges.kisanCreditCardStatus!
                      : 'Not added',
                  subLabel: badges.isKccVerified ? null : '(Self-declared, not verified yet)',
                  valueColor: const Color(0xFF047857), // Green
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeTile({
    required String caption,
    required String value,
    required Color valueColor,
    String? subLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 3),
            Text(
              subLabel,
              style: const TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD97706),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ZERO-PESTICIDE ORGANIC CERTIFICATE CARD
  // ---------------------------------------------------------------------------
  Widget _buildCertificateCard(
    BuildContext context,
    OrganicCertificate certificate,
    AppLocalizations? l10n,
  ) {
    final hasCert = certificate.hasCertificate;
    final isAdminValidated = certificate.isValidatedByAdmin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAdminValidated ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdminValidated ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isAdminValidated ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(isAdminValidated ? '🌱' : '📄', style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.title?.isNotEmpty == true
                      ? certificate.title!
                      : (hasCert && certificate.certificateNumber != null
                          ? 'Organic Certificate #${certificate.certificateNumber}'
                          : 'Organic Certificate'),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isAdminValidated ? const Color(0xFF064E3B) : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAdminValidated
                      ? (certificate.issuer ?? 'Validated by Organic Certification Authority')
                      : (hasCert
                          ? 'Self-declared, not verified yet'
                          : 'Optional certificate not uploaded yet'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isAdminValidated ? const Color(0xFF047857) : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isAdminValidated ? const Color(0xFF065F46) : const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAdminValidated
                  ? 'VALIDATED ✓'
                  : (hasCert ? 'Self-declared, not verified yet' : 'Not Added'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. LANGUAGE MODE CARD
  // ---------------------------------------------------------------------------
  Widget _buildLanguageModeCard(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
    AppLocalizations? l10n,
  ) {
    final languages = [
      {'code': 'en', 'label': 'English'},
      {'code': 'kn', 'label': 'ಕನ್ನಡ'},
      {'code': 'te', 'label': 'తెలుగు'},
      {'code': 'hi', 'label': 'हिंदी'},
      {'code': 'ta', 'label': 'தமிழ்'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.languageMode ?? 'LANGUAGE MODE',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentLocale.languageCode.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Scrollable / Wrap Language Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: languages.map((lang) {
                final isSelected = currentLocale.languageCode == lang['code'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(lang['code']!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF047857) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF047857) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        lang['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. MANAGE PRODUCE LISTINGS SHORTCUT
  // ---------------------------------------------------------------------------
  Widget _buildManageProduceShortcut(BuildContext context, AppLocalizations? l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.farmerMarket),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.manageProduceListings ?? 'Manage Produce Listings',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.farmerSellProduceDesc ?? 'Create, update inventory, and manage pricing bands',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
