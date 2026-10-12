import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/core/widgets/info_banner.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class ProviderWizardScreen extends ConsumerStatefulWidget {
  const ProviderWizardScreen({super.key});

  @override
  ConsumerState<ProviderWizardScreen> createState() => _ProviderWizardScreenState();
}

class _ProviderWizardScreenState extends ConsumerState<ProviderWizardScreen> {
  final _picker = ImagePicker();
  Uint8List? _localAvatarBytes;
  ImageSource? _lastPickedSource;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wizardAsync = ref.watch(providerWizardProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.providerWizardTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          CompactLanguageSelector(),
          SizedBox(width: 8),
        ],
      ),
      body: wizardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 48),
                const SizedBox(height: 12),
                Text('Error loading provider wizard: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                AppButton(
                  label: l10n.retry,
                  onPressed: () => ref.refresh(providerWizardProvider),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          final draft = state.draft;
          final step = draft.currentStep;

          return Column(
            children: [
              // Progress Bar
              Container(
                color: AppColors.headerGreenDark.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.wizardStepProgress(step, 5),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.headerGreenDark,
                          ),
                        ),
                        Text(
                          '${((step / 5) * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: step / 5,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amberOrange),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),

              // Error Banner if any
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: InfoBanner(
                    text: state.errorMessage!,
                    type: InfoBannerType.warning,
                  ),
                ),

              // Step Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildStepContent(context, state, locale.languageCode),
                ),
              ),

              // Bottom Navigation Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      if (step > 1)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: AppColors.headerGreenDark),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: state.isSaving
                                ? null
                                : () => ref.read(providerWizardProvider.notifier).previousStep(),
                            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.headerGreenDark),
                            label: Text(l10n.back, style: const TextStyle(color: AppColors.headerGreenDark, fontSize: 16)),
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            l10n.quitAndResumeNotice,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: step == 5
                              ? l10n.finishProfileButton
                              : l10n.continueButton,
                          icon: step == 5 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                          isLoading: state.isSaving,
                          onPressed: () async {
                            if (step == 1 && state.draft.fullName.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter your full name.')),
                              );
                              return;
                            }

                            final success = await ref.read(providerWizardProvider.notifier).nextStep();
                            if (success && step == 5 && context.mounted) {
                              context.go(AppRoutes.providerHome);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, ProviderWizardState state, String langCode) {
    final draft = state.draft;
    final step = draft.currentStep;

    switch (step) {
      case 1:
        return _buildStep1Basics(context, state, langCode);
      case 2:
        return _buildStep2ProviderType(context, state, langCode);
      case 3:
        return draft.isHousehold
            ? _buildStep3HouseholdAddress(context, state, langCode)
            : _buildStep3EmployerDetails(context, state, langCode);
      case 4:
        return _buildStep4Consents(context, state, langCode);
      case 5:
        return _buildStep5Review(context, state, langCode);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: BASICS
  Widget _buildStep1Basics(BuildContext context, ProviderWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.providerStep1Title,
          subtitle: l10n.providerStep1Subtitle,
          ttsText: '${l10n.providerStep1Title}. ${l10n.providerStep1Subtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 20),

        // Photo Picker Area
        Center(
          child: Column(
            children: [
              UserAvatar(
                avatarPath: draft.avatarPath ?? draft.avatarUrl,
                imageBytes: _localAvatarBytes,
                name: draft.fullName,
                radius: 54,
                isLoading: state.isSaving,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: state.isSaving ? null : () => _pickAndUploadPhoto(ImageSource.camera),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_rounded, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.takePhotoCamera,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: state.isSaving ? null : () => _pickAndUploadPhoto(ImageSource.gallery),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.chooseGallery,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.uploadError != null) ...[
                const SizedBox(height: 8),
                Text(state.uploadError!, style: const TextStyle(color: AppColors.errorRed, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: state.isSaving ? null : _retryUpload,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.retry),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Full Name Field
        TextField(
          controller: TextEditingController(text: draft.fullName)
            ..selection = TextSelection.collapsed(offset: draft.fullName.length),
          onChanged: (val) {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(fullName: val));
          },
          decoration: InputDecoration(
            labelText: l10n.fullName,
            hintText: l10n.enterName,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),

        // Spoken Languages Selector
        Text(l10n.languagesLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            {'code': 'kn', 'label': 'ಕನ್ನಡ (Kannada)'},
            {'code': 'en', 'label': 'English'},
            {'code': 'hi', 'label': 'हिंदी (Hindi)'},
            {'code': 'te', 'label': 'తెలుగు (Telugu)'},
            {'code': 'ta', 'label': 'தமிழ் (Tamil)'},
          ].map((item) {
            final code = item['code']!;
            final isSelected = draft.languages.contains(code);
            return FilterChip(
              selected: isSelected,
              label: Text(item['label']!),
              selectedColor: AppColors.paleMint,
              checkmarkColor: AppColors.headerGreenDark,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                final list = List<String>.from(draft.languages);
                if (selected) {
                  list.add(code);
                } else if (list.length > 1) {
                  list.remove(code);
                }
                ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(languages: list));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 2: PROVIDER TYPE
  Widget _buildStep2ProviderType(BuildContext context, ProviderWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.providerStep2Title,
          subtitle: l10n.providerStep2Subtitle,
          ttsText: '${l10n.providerStep2Title}. ${l10n.providerStep2Subtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 24),

        // Household Card Option
        _buildTypeCard(
          title: l10n.providerTypeHousehold,
          subtitle: 'Hire workers for domestic help, plumbing, garden work, or home delivery.',
          icon: Icons.home_rounded,
          isSelected: draft.isHousehold,
          onTap: () {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(providerType: 'household'));
          },
        ),
        const SizedBox(height: 16),

        // Employer / Contractor Card Option
        _buildTypeCard(
          title: l10n.providerTypeEmployer,
          subtitle: 'Hire construction crews, factory workers, drivers, or multi-site staff.',
          icon: Icons.business_center_rounded,
          isSelected: draft.isEmployer,
          onTap: () {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(providerType: 'employer'));
          },
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.headerGreenDark.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : AppColors.headerGreenDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? AppColors.headerGreenDark : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.headerGreenDark, size: 24),
          ],
        ),
      ),
    );
  }

  // STEP 3: HOUSEHOLD ADDRESS & DELIVERY
  Widget _buildStep3HouseholdAddress(BuildContext context, ProviderWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.providerStep3HouseholdTitle,
          subtitle: l10n.providerStep3HouseholdSubtitle,
          ttsText: '${l10n.providerStep3HouseholdTitle}. ${l10n.providerStep3HouseholdSubtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 20),

        // Default Doorstep Address Card Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.amberOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amberOrange.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.door_front_door_rounded, color: AppColors.amberOrange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Default Doorstep Delivery Address Card',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.amberOrange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Flat / Door No & Street
        TextField(
          controller: TextEditingController(text: draft.addressLine1)
            ..selection = TextSelection.collapsed(offset: draft.addressLine1.length),
          onChanged: (val) {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(addressLine1: val));
          },
          decoration: InputDecoration(
            labelText: l10n.doorstepAddressLabel,
            hintText: l10n.doorstepAddressHint,
            prefixIcon: const Icon(Icons.home_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Landmark
        TextField(
          controller: TextEditingController(text: draft.landmark)
            ..selection = TextSelection.collapsed(offset: draft.landmark.length),
          onChanged: (val) {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(landmark: val));
          },
          decoration: InputDecoration(
            labelText: l10n.landmarkLabel,
            hintText: l10n.landmarkHint,
            prefixIcon: const Icon(Icons.location_city_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Delivery Instructions
        TextField(
          controller: TextEditingController(text: draft.deliveryDropoffInstruction)
            ..selection = TextSelection.collapsed(offset: draft.deliveryDropoffInstruction.length),
          onChanged: (val) {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(deliveryDropoffInstruction: val));
          },
          decoration: InputDecoration(
            labelText: l10n.deliveryInstructionsLabel,
            hintText: l10n.deliveryInstructionsHint,
            prefixIcon: const Icon(Icons.local_shipping_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Gate Code (Optional)
        TextField(
          controller: TextEditingController(text: draft.gateCode ?? '')
            ..selection = TextSelection.collapsed(offset: (draft.gateCode ?? '').length),
          onChanged: (val) {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(gateCode: val.isEmpty ? null : val));
          },
          decoration: InputDecoration(
            labelText: l10n.gateCodeLabel,
            hintText: l10n.gateCodeHint,
            prefixIcon: const Icon(Icons.lock_clock_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        // Map Picker
        const Text('Doorstep Location Pin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildMapPicker(
          context,
          latitude: draft.latitude,
          longitude: draft.longitude,
          onPositionPicked: (lat, lng) {
            ref.read(providerWizardProvider.notifier).updateDraft(
              (d) => d.copyWith(latitude: lat, longitude: lng),
            );
          },
        ),
      ],
    );
  }

  // STEP 3: EMPLOYER DETAILS & SITE ADDRESS
  Widget _buildStep3EmployerDetails(BuildContext context, ProviderWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    final categoriesAsync = ref.watch(categoriesProvider);
    final dbCategoryNames = categoriesAsync.asData?.value.map((c) => c.getLocalizedName(langCode)).toList();
    final hiringCategoryOptions = (dbCategoryNames != null && dbCategoryNames.isNotEmpty)
        ? dbCategoryNames
        : [
            'Construction & Labour',
            'Housekeeping & Maid',
            'Agriculture & Farm Labour',
            'Catering & Kitchen Staff',
            'Logistics & Delivery Drivers',
            'Maintenance & Electrician',
            'Security Guards'
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.providerStep3EmployerTitle,
          subtitle: l10n.providerStep3EmployerSubtitle,
          ttsText: '${l10n.providerStep3EmployerTitle}. ${l10n.providerStep3EmployerSubtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 20),

        // Organisation / Business Name
        TextField(
          controller: TextEditingController(text: draft.orgName)
            ..selection = TextSelection.collapsed(offset: draft.orgName.length),
          onChanged: (val) {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(orgName: val));
          },
          decoration: InputDecoration(
            labelText: l10n.orgNameLabel,
            hintText: l10n.orgNameHint,
            prefixIcon: const Icon(Icons.business_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Primary Site Address Line 1
        TextField(
          controller: TextEditingController(text: draft.siteAddressLine1)
            ..selection = TextSelection.collapsed(offset: draft.siteAddressLine1.length),
          onChanged: (val) {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(siteAddressLine1: val));
          },
          decoration: InputDecoration(
            labelText: l10n.primarySiteAddressLabel,
            hintText: l10n.primarySiteAddressHint,
            prefixIcon: const Icon(Icons.add_location_alt_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Site Landmark
        TextField(
          controller: TextEditingController(text: draft.siteLandmark)
            ..selection = TextSelection.collapsed(offset: draft.siteLandmark.length),
          onChanged: (val) {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(siteLandmark: val));
          },
          decoration: InputDecoration(
            labelText: l10n.landmarkLabel,
            hintText: l10n.landmarkHint,
            prefixIcon: const Icon(Icons.location_city_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        // Categories Usually Hired For
        Text(l10n.categoriesHiringLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hiringCategoryOptions.map((cat) {
            final isSelected = draft.categoriesHiring.contains(cat);
            return FilterChip(
              selected: isSelected,
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selectedColor: AppColors.paleMint,
              checkmarkColor: AppColors.headerGreenDark,
              onSelected: (selected) {
                final list = List<String>.from(draft.categoriesHiring);
                if (selected) {
                  list.add(cat);
                } else {
                  list.remove(cat);
                }
                ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(categoriesHiring: list));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Typical Crew Size Needed Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.typicalCrewSizeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              l10n.crewSizeWorkers(draft.typicalCrewSize),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark, fontSize: 16),
            ),
          ],
        ),
        Slider(
          value: draft.typicalCrewSize.toDouble().clamp(1.0, 50.0),
          min: 1.0,
          max: 50.0,
          divisions: 49,
          activeColor: AppColors.headerGreenDark,
          onChanged: (val) {
            ref.read(providerWizardProvider.notifier).updateDraft((d) => d.copyWith(typicalCrewSize: val.round()));
          },
        ),
        const SizedBox(height: 20),

        // Site Location Pin Map
        const Text('Primary Site Location Pin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildMapPicker(
          context,
          latitude: draft.siteLatitude,
          longitude: draft.siteLongitude,
          onPositionPicked: (lat, lng) {
            ref.read(providerWizardProvider.notifier).updateDraft(
              (d) => d.copyWith(siteLatitude: lat, siteLongitude: lng),
            );
          },
        ),
      ],
    );
  }

  // STEP 4: CONSENTS (GPS & Notifications)
  Widget _buildStep4Consents(BuildContext context, ProviderWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.providerStep4Title,
          subtitle: l10n.providerStep4Subtitle,
          ttsText: '${l10n.providerStep4Title}. ${l10n.providerStep4Subtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 24),

        // GPS Location Consent Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: AppColors.headerGreenDark, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'GPS Location Access',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (draft.gpsConsentGranted)
                    Chip(
                      avatar: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      label: Text(l10n.permissionGranted),
                      backgroundColor: AppColors.headerGreenDark,
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.gpsConsentExplanation,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              if (!draft.gpsConsentGranted)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await ref.read(providerWizardProvider.notifier).logConsent('gps');
                    ref.read(providerWizardProvider.notifier).updateDraft(
                          (d) => d.copyWith(gpsConsentGranted: true),
                        );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.grantGpsPermission),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Notifications Consent Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.amberOrange, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Push Notifications Access',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (draft.notificationsConsentGranted)
                    Chip(
                      avatar: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      label: Text(l10n.permissionGranted),
                      backgroundColor: AppColors.headerGreenDark,
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.notificationsConsentExplanation,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              if (!draft.notificationsConsentGranted)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amberOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await ref.read(providerWizardProvider.notifier).logConsent('notifications');
                    ref.read(providerWizardProvider.notifier).updateDraft(
                          (d) => d.copyWith(notificationsConsentGranted: true),
                        );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.grantNotificationsPermission),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 5: REVIEW & FINISH
  Widget _buildStep5Review(BuildContext context, ProviderWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.providerStep5Title,
          subtitle: l10n.providerStep5Subtitle,
          ttsText: '${l10n.providerStep5Title}. ${l10n.providerStep5Subtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 20),

        // Summary Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      avatarPath: draft.avatarPath ?? draft.avatarUrl,
                      imageBytes: _localAvatarBytes,
                      name: draft.fullName,
                      radius: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Chip(
                            padding: EdgeInsets.zero,
                            labelStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            backgroundColor: draft.isHousehold ? AppColors.amberOrange : AppColors.headerGreenDark,
                            label: Text(draft.isHousehold ? l10n.providerTypeHousehold : l10n.providerTypeEmployer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (draft.isHousehold) ...[
                  _buildSummaryRow(Icons.door_front_door_rounded, 'Doorstep Address', '${draft.addressLine1}, ${draft.landmark}'),
                  _buildSummaryRow(Icons.location_city_rounded, 'City / PIN', '${draft.city} - ${draft.pincode}'),
                  _buildSummaryRow(Icons.local_shipping_rounded, 'Delivery Instructions', draft.deliveryDropoffInstruction),
                  if (draft.gateCode != null)
                    _buildSummaryRow(Icons.lock_clock_rounded, 'Gate Code', draft.gateCode!),
                ] else ...[
                  _buildSummaryRow(Icons.business_rounded, 'Organisation', draft.orgName),
                  _buildSummaryRow(Icons.add_location_alt_rounded, 'Site Address', '${draft.siteAddressLine1}, ${draft.siteLandmark}'),
                  _buildSummaryRow(Icons.category_rounded, 'Categories Hired For', draft.categoriesHiring.join(', ')),
                  _buildSummaryRow(Icons.groups_rounded, 'Typical Crew Size', l10n.crewSizeWorkers(draft.typicalCrewSize)),
                ],

                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      draft.gpsConsentGranted ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: draft.gpsConsentGranted ? AppColors.headerGreenDark : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('GPS Location Consent Granted', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      draft.notificationsConsentGranted ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: draft.notificationsConsentGranted ? AppColors.headerGreenDark : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Notifications Consent Granted', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.headerGreenDark),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader({
    required String title,
    required String subtitle,
    required String ttsText,
    required String langCode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.headerGreenDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.headerGreenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(providerWizardProvider.notifier).speakText(ttsText, langCode);
            },
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.headerGreenDark, size: 28),
            tooltip: 'Listen to instructions',
          ),
        ],
      ),
    );
  }

  Widget _buildMapPicker(
    BuildContext context, {
    required double? latitude,
    required double? longitude,
    required Function(double lat, double lng) onPositionPicked,
  }) {
    final defaultLat = latitude ?? 12.9716;
    final defaultLng = longitude ?? 77.5946;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(defaultLat, defaultLng),
                initialZoom: 14.0,
                onTap: (tapPosition, point) {
                  onPositionPicked(point.latitude, point.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.udyogasethu.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(defaultLat, defaultLng),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on_rounded, color: AppColors.amberOrange, size: 40),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton.small(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                onPressed: () async {
                  try {
                    LocationPermission perm = await Geolocator.checkPermission();
                    if (perm == LocationPermission.denied) {
                      perm = await Geolocator.requestPermission();
                    }
                    if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
                      final pos = await Geolocator.getCurrentPosition();
                      onPositionPicked(pos.latitude, pos.longitude);
                    }
                  } catch (_) {}
                },
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    _lastPickedSource = source;
    try {
      final XFile? file = await _picker.pickImage(source: source, maxWidth: 600, imageQuality: 80);
      if (file != null) {
        final Uint8List bytes = await file.readAsBytes();
        setState(() {
          _localAvatarBytes = bytes;
        });
        final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await ref.read(providerWizardProvider.notifier).uploadAvatarBytes(bytes, filename);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  Future<void> _retryUpload() async {
    if (_localAvatarBytes != null) {
      final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await ref.read(providerWizardProvider.notifier).uploadAvatarBytes(_localAvatarBytes!, filename);
    } else if (_lastPickedSource != null) {
      _pickAndUploadPhoto(_lastPickedSource!);
    }
  }
}
