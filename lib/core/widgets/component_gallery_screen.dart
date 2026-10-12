import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/theme/app_theme.dart';
import 'package:udyogasethu/core/widgets/widgets.dart';

class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  double _textScaleFactor = 1.0;
  bool _isDarkPanelMode = false;

  @override
  Widget build(BuildContext context) {
    Widget body = Scaffold(
      appBar: AppBar(
        title: const Text('Design System Gallery'),
        actions: [
          IconButton(
            icon: Icon(_isDarkPanelMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkPanelMode = !_isDarkPanelMode;
              });
            },
            tooltip: 'Toggle Theme Variant',
          ),
        ],
      ),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_textScaleFactor),
        ),
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Scale Selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TEXT SCALE FACTOR: ${_textScaleFactor.toStringAsFixed(1)}x',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [1.0, 1.3, 1.6].map((scale) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text('${scale}x'),
                                  selected: _textScaleFactor == scale,
                                  onSelected: (_) {
                                    setState(() {
                                      _textScaleFactor = scale;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const Divider(),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.visibility_rounded, size: 18),
                                label: const Text('/dev/job-visibility'),
                                onPressed: () => GoRouter.of(context).push('/dev/job-visibility'),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.collections_rounded, size: 18),
                                label: const Text('/dev/thumbnails'),
                                onPressed: () => GoRouter.of(context).push('/dev/thumbnails'),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.image_rounded, size: 18),
                                label: const Text('/dev/assets'),
                                onPressed: () => GoRouter.of(context).push('/dev/assets'),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                                label: const Text('/dev/role'),
                                onPressed: () => GoRouter.of(context).push('/dev/role'),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                                label: const Text('/dev/connection'),
                                onPressed: () => GoRouter.of(context).push('/dev/connection'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 1. Gradient Header
                  const SectionHeader(title: 'Gradient Header'),
                  const SizedBox(height: AppSpacing.sm),
                  GradientHeader(
                    greeting: 'Good Morning,',
                    userName: 'Chethan Kumar',
                    location: '📍 Koramangala, Bengaluru',
                    onNotificationTap: () {},
                    onProfileTap: () {},
                    onSosTap: () {},
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Goal',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '₹800 / ₹1500',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        ProgressRing(progress: 0.53),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. Buttons
                  const SectionHeader(title: 'Buttons (AppButton)'),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Primary Emerald Button',
                    onPressed: () {},
                    variant: AppButtonVariant.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Secondary Outline Button',
                    onPressed: () {},
                    variant: AppButtonVariant.secondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Danger SOS Action',
                    onPressed: () {},
                    variant: AppButtonVariant.danger,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Loading Primary Button',
                    onPressed: () {},
                    isLoading: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 3. Badges & Chips
                  const SectionHeader(title: 'Verified Badges & Status Chips'),
                  const SizedBox(height: AppSpacing.sm),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      VerifiedBadge(type: VerifiedBadgeType.worker),
                      VerifiedBadge(type: VerifiedBadgeType.farmer),
                      VerifiedBadge(type: VerifiedBadgeType.customer),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(label: 'Active', style: StatusChipStyle.success),
                      StatusChip(label: 'Pending', style: StatusChipStyle.warning),
                      StatusChip(label: 'No-Show Alert', style: StatusChipStyle.danger),
                      StatusChip(label: 'Read-Only', style: StatusChipStyle.neutral),
                      StatusChip(label: 'Construction', isSelected: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 4. Input Fields
                  const SectionHeader(title: 'Input Fields'),
                  const SizedBox(height: AppSpacing.sm),
                  const AppTextField(
                    label: 'FULL NAME',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const PhoneField(),
                  const SizedBox(height: AppSpacing.md),
                  const Text('ENTER 6-DIGIT OTP:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  OtpField(onCompleted: (_) {}),
                  const SizedBox(height: AppSpacing.md),
                  SearchBarWithMic(
                    onMicTap: () {},
                    onFilterTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 5. Job Card & Cards
                  const SectionHeader(title: 'Job Card (JobCard)'),
                  const SizedBox(height: AppSpacing.sm),
                  JobCard(
                    title: 'Commercial Electrical Repair',
                    employerName: 'Sai Electricals',
                    rating: 4.9,
                    reviewCount: 125,
                    distanceText: '0.8 km away',
                    payRateText: '₹880/day',
                    isHotJobBadge: 'Hot Job',
                    onApply: () {},
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 6. Quick Action Tiles
                  const SectionHeader(title: 'Quick Action Grid'),
                  const SizedBox(height: AppSpacing.sm),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      QuickActionTile(
                        icon: Icons.work_outline,
                        title: 'Nearby Jobs',
                        badgeText: '12',
                        onTap: () {},
                      ),
                      QuickActionTile(
                        icon: Icons.auto_awesome_outlined,
                        title: 'AI Assist',
                        onTap: () {},
                      ),
                      QuickActionTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Wallet',
                        onTap: () {},
                      ),
                      QuickActionTile(
                        icon: Icons.shield_outlined,
                        title: 'Safety Hub',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 7. Info Banners
                  const SectionHeader(title: 'Info Banners (InfoBanner)'),
                  const SizedBox(height: AppSpacing.sm),
                  const InfoBanner(
                    type: InfoBannerType.safety,
                    text: 'UdyogaSethu Safety: Phone & payment handles are masked for your privacy.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const InfoBanner(
                    type: InfoBannerType.warning,
                    text: 'Moderate Rain Expected Tomorrow Afternoon - Protect tomato crops.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const InfoBanner(
                    type: InfoBannerType.demoMode,
                    text: 'Demo Simulation Note: Safety team & emergency contacts will be notified.',
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 8. Rating & Progress Ring
                  const SectionHeader(title: 'Rating & Floating Mic FAB'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const RatingStars(rating: 4.9, reviewCount: 125),
                      MicFab(onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 9. Dialog & BottomSheet Triggers
                  const SectionHeader(title: 'Interactive Modals & States'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Show Confirm Dialog',
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            ConfirmDialog.show(
                              context: context,
                              title: 'Trigger Emergency SOS?',
                              message: 'This will log a high-priority safety incident.',
                              confirmLabel: 'Yes, Trigger',
                              isDanger: true,
                              onConfirm: () {},
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: 'Show Bottom Sheet',
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            AppBottomSheet.show(
                              context: context,
                              title: 'Farm Quality Traceability',
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text('Crop Item'),
                                    subtitle: Text('Red Tomatoes'),
                                  ),
                                  ListTile(
                                    title: Text('Organic Certificate'),
                                    subtitle: Text('Pesticide-Free ✓'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 10. Shimmer & States
                  const SectionHeader(title: 'Shimmer & Empty/Error States'),
                  const SizedBox(height: AppSpacing.sm),
                  const ShimmerPlaceholder(height: 60),
                  const SizedBox(height: AppSpacing.md),
                  const EmptyState(
                    title: 'No Active Bookings',
                    description: 'You have no scheduled jobs today. Browse nearby jobs to start earning.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ErrorState(
                    message: 'Failed to load nearby mandi prices. Please check your internet connection.',
                    onRetry: () {},
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (_isDarkPanelMode) {
      return DarkPanelTheme(child: body);
    }
    return body;
  }
}
