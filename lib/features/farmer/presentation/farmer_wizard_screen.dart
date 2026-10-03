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
import 'package:udyogasethu/features/farmer/domain/farmer_profile_draft.dart';
import 'package:udyogasethu/features/farmer/presentation/farmer_wizard_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FarmerWizardScreen extends ConsumerStatefulWidget {
  const FarmerWizardScreen({super.key});

  @override
  ConsumerState<FarmerWizardScreen> createState() => _FarmerWizardScreenState();
}

class _FarmerWizardScreenState extends ConsumerState<FarmerWizardScreen> {
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wizardAsync = ref.watch(farmerWizardProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.farmerWizardTitle,
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
                Text('Error loading profile wizard: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                AppButton(
                  label: l10n.retry,
                  onPressed: () => ref.refresh(farmerWizardProvider),
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
                                : () => ref.read(farmerWizardProvider.notifier).previousStep(),
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
                            if (step == 2 && state.draft.farmName.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter your farm name.')),
                              );
                              return;
                            }

                            final success = await ref.read(farmerWizardProvider.notifier).nextStep();
                            if (success && step == 5 && context.mounted) {
                              context.go(AppRoutes.farmerHome);
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

  Widget _buildStepContent(BuildContext context, FarmerWizardState state, String langCode) {
    final draft = state.draft;
    final step = draft.currentStep;

    switch (step) {
      case 1:
        return _buildStep1Basics(context, state, langCode);
      case 2:
        return _buildStep2Farm(context, state, langCode);
      case 3:
        return _buildStep3Registrations(context, state, langCode);
      case 4:
        return _buildStep4SellingOptions(context, state, langCode);
      case 5:
        return _buildStep5Review(context, state, langCode);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: BASICS
  Widget _buildStep1Basics(BuildContext context, FarmerWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.farmerStep1Title,
          subtitle: l10n.farmerStep1Subtitle,
          ttsText: '${l10n.farmerStep1Title}. ${l10n.farmerStep1Subtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 20),

        // Photo Picker Area
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: AppColors.headerGreenDark.withValues(alpha: 0.1),
                backgroundImage: draft.avatarUrl != null && draft.avatarUrl!.isNotEmpty
                    ? NetworkImage(draft.avatarUrl!)
                    : null,
                child: draft.avatarUrl == null || draft.avatarUrl!.isEmpty
                    ? const Icon(Icons.person_rounded, size: 54, color: AppColors.headerGreenDark)
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickAndUploadPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: Text(l10n.takePhotoCamera),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickAndUploadPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: Text(l10n.chooseGallery),
                  ),
                ],
              ),
              if (state.uploadError != null) ...[
                const SizedBox(height: 8),
                Text(state.uploadError!, style: const TextStyle(color: AppColors.errorRed, fontSize: 13)),
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
            ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(fullName: val));
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
                ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(languages: list));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 2: FARM DETAILS
  Widget _buildStep2Farm(BuildContext context, FarmerWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    final cropsList = [
      'Tomatoes', 'Potatoes', 'Paddy / Rice', 'Ragi', 'Maize', 'Sugarcane',
      'Cotton', 'Vegetables', 'Fruits', 'Coffee', 'Arecanut', 'Spices', 'Flowers'
    ];

    final soilTypes = [
      'Red Soil', 'Black Soil', 'Alluvial Soil', 'Laterite Soil', 'Sandy Soil', 'Clay Soil'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.farmerStep2Title,
          subtitle: l10n.farmerStep2Subtitle,
          ttsText: '${l10n.farmerStep2Title}. ${l10n.farmerStep2Subtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 20),

        // Farm Name
        TextField(
          controller: TextEditingController(text: draft.farmName)
            ..selection = TextSelection.collapsed(offset: draft.farmName.length),
          onChanged: (val) {
            ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(farmName: val));
          },
          decoration: InputDecoration(
            labelText: l10n.farmNameLabel,
            hintText: l10n.farmNameHint,
            prefixIcon: const Icon(Icons.agriculture_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Village or Cluster
        TextField(
          controller: TextEditingController(text: draft.clusterVillage)
            ..selection = TextSelection.collapsed(offset: draft.clusterVillage.length),
          onChanged: (val) {
            ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(clusterVillage: val));
          },
          decoration: InputDecoration(
            labelText: l10n.villageClusterLabel,
            hintText: l10n.villageClusterHint,
            prefixIcon: const Icon(Icons.location_city_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        // Acres Slider & Field
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.acresLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${draft.acres.toStringAsFixed(1)} Acres', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark, fontSize: 16)),
          ],
        ),
        Slider(
          value: draft.acres.clamp(0.5, 50.0),
          min: 0.5,
          max: 50.0,
          divisions: 99,
          activeColor: AppColors.headerGreenDark,
          onChanged: (val) {
            ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(acres: val));
          },
        ),
        const SizedBox(height: 16),

        // Farming Method Chips
        Text(l10n.farmingMethodLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMethodChip('organic', l10n.methodOrganic, draft.farmingMethod),
            const SizedBox(width: 8),
            _buildMethodChip('natural', l10n.methodNatural, draft.farmingMethod),
            const SizedBox(width: 8),
            _buildMethodChip('conventional', l10n.methodConventional, draft.farmingMethod),
          ],
        ),
        const SizedBox(height: 20),

        // Soil Type Dropdown
        Text(l10n.soilTypeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: soilTypes.contains(draft.soilType) ? draft.soilType : soilTypes.first,
          decoration: OutlineInputBorder(borderRadius: BorderRadius.circular(12)).toInputDecoration(),
          items: soilTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(soilType: val));
            }
          },
        ),
        const SizedBox(height: 16),

        // Soil pH (Optional)
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: TextEditingController(text: draft.soilPh?.toString() ?? '')
            ..selection = TextSelection.collapsed(offset: (draft.soilPh?.toString() ?? '').length),
          onChanged: (val) {
            final parsed = double.tryParse(val);
            ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(soilPh: parsed));
          },
          decoration: InputDecoration(
            labelText: l10n.soilPhLabel,
            hintText: 'e.g. 6.5',
            prefixIcon: const Icon(Icons.science_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        // Primary Crops Chips
        Text(l10n.primaryCropsLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cropsList.map((crop) {
            final isSelected = draft.primaryCrops.contains(crop);
            return FilterChip(
              selected: isSelected,
              label: Text(
                crop,
                style: TextStyle(
                  color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selectedColor: AppColors.paleMint,
              checkmarkColor: AppColors.headerGreenDark,
              onSelected: (selected) {
                final list = List<String>.from(draft.primaryCrops);
                if (selected) {
                  list.add(crop);
                } else {
                  list.remove(crop);
                }
                ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(primaryCrops: list));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Map Picker for Farm Location
        Text(l10n.farmLocationLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildMapPicker(context, draft),
      ],
    );
  }

  Widget _buildMethodChip(String value, String label, String selectedValue) {
    final isSelected = value == selectedValue;
    return Expanded(
      child: ChoiceChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selectedColor: AppColors.paleMint,
        checkmarkColor: AppColors.headerGreenDark,
        onSelected: (selected) {
          if (selected) {
            ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(farmingMethod: value));
          }
        },
      ),
    );
  }

  // STEP 3: REGISTRATIONS & BADGES
  Widget _buildStep3Registrations(BuildContext context, FarmerWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.farmerStep3Title,
          subtitle: l10n.farmerStep3Subtitle,
          ttsText: '${l10n.farmerStep3Title}. ${l10n.farmerStep3Subtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 20),

        // APMC Registration Number
        TextField(
          controller: TextEditingController(text: draft.apmcRegistration ?? '')
            ..selection = TextSelection.collapsed(offset: (draft.apmcRegistration ?? '').length),
          onChanged: (val) {
            ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(apmcRegistration: val.isEmpty ? null : val));
          },
          decoration: InputDecoration(
            labelText: l10n.apmcRegLabel,
            hintText: l10n.apmcRegHint,
            prefixIcon: const Icon(Icons.verified_user_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        // KCC Status
        Text(l10n.kccStatusLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKccChip('none', l10n.kccNone, draft.kccStatus)),
            const SizedBox(width: 8),
            Expanded(child: _buildKccChip('applied', l10n.kccApplied, draft.kccStatus)),
            const SizedBox(width: 8),
            Expanded(child: _buildKccChip('approved', l10n.kccApproved, draft.kccStatus)),
          ],
        ),
        const SizedBox(height: 24),

        // Organic Certificate Upload (Private Storage: kyc-docs)
        Text(l10n.organicCertLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(l10n.organicCertHelper, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              if (draft.organicCertPath != null && draft.organicCertPath!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.headerGreenDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.certUploadedPending,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: state.isSaving ? null : () => _pickAndUploadCert(),
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(l10n.uploadCertButton),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // LIVE FARM BADGES PREVIEW
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.headerGreenDark.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.headerGreenDark.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.amberOrange),
                  const SizedBox(width: 8),
                  Text(l10n.farmBadgesTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (draft.hasApmcBadge)
                    Chip(
                      avatar: const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                      label: Text(l10n.apmcBadgeTitle),
                      backgroundColor: AppColors.headerGreenDark,
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  if (draft.hasKccBadge)
                    Chip(
                      avatar: const Icon(Icons.credit_card_rounded, size: 16, color: Colors.white),
                      label: Text('KCC (${draft.kccStatus.toUpperCase()})'),
                      backgroundColor: AppColors.headerGreenDark,
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  if (draft.hasOrganicBadge)
                    Chip(
                      avatar: const Icon(Icons.eco_rounded, size: 16, color: Colors.white),
                      label: Text(l10n.organicBadgeTitle),
                      backgroundColor: AppColors.amberOrange,
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  if (!draft.hasApmcBadge && !draft.hasKccBadge && !draft.hasOrganicBadge)
                    const Text('Add registrations above to earn farm profile badges!', style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKccChip(String value, String label, String selectedValue) {
    final isSelected = value == selectedValue;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selectedColor: AppColors.paleMint,
      checkmarkColor: AppColors.headerGreenDark,
      onSelected: (selected) {
        if (selected) {
          ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(kccStatus: value));
        }
      },
    );
  }

  // STEP 4: SELLING OPTIONS
  Widget _buildStep4SellingOptions(BuildContext context, FarmerWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    final leadTimes = ['Same day', '1 day', '2 days', '3+ days'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.farmerStep4Title,
          subtitle: l10n.farmerStep4Subtitle,
          ttsText: '${l10n.farmerStep4Title}. ${l10n.farmerStep4Subtitle}',
          langCode: langCode,
        ),
        const SizedBox(height: 20),

        // Delivery Available Switch
        SwitchListTile(
          value: draft.deliveryAvailable,
          activeThumbColor: AppColors.headerGreenDark,
          title: Text(l10n.deliveryAvailableLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Deliver farm produce directly to buyers'),
          onChanged: (val) {
            ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(deliveryAvailable: val));
          },
        ),
        const Divider(),

        // Pickup Available Switch
        SwitchListTile(
          value: draft.pickupAvailable,
          activeThumbColor: AppColors.headerGreenDark,
          title: Text(l10n.pickupAvailableLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Allow buyers to pick up fresh produce at your farm'),
          onChanged: (val) {
            ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(pickupAvailable: val));
          },
        ),
        const SizedBox(height: 20),

        // Delivery Radius Slider
        if (draft.deliveryAvailable) ...[
          Text(l10n.deliveryRadiusLabel(draft.deliveryRadiusKm.toInt()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Slider(
            value: draft.deliveryRadiusKm.clamp(5.0, 100.0),
            min: 5.0,
            max: 100.0,
            divisions: 19,
            activeColor: AppColors.headerGreenDark,
            onChanged: (val) {
              ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(deliveryRadiusKm: val));
            },
          ),
          const SizedBox(height: 20),
        ],

        // Typical Lead Time Chips
        Text(l10n.leadTimeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: leadTimes.map((time) {
            final isSelected = draft.leadTime == time;
            return ChoiceChip(
              selected: isSelected,
              label: Text(time),
              selectedColor: AppColors.amberOrange.withValues(alpha: 0.2),
              onSelected: (selected) {
                if (selected) {
                  ref.read(farmerWizardProvider.notifier).updateDraft((d) => d.copyWith(leadTime: time));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 5: REVIEW & FINISH
  Widget _buildStep5Review(BuildContext context, FarmerWizardState state, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.farmerStep5Title,
          subtitle: l10n.farmerStep5Subtitle,
          ttsText: '${l10n.farmerStep5Title}. ${l10n.farmerStep5Subtitle}',
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
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.headerGreenDark.withValues(alpha: 0.1),
                      backgroundImage: draft.avatarUrl != null ? NetworkImage(draft.avatarUrl!) : null,
                      child: draft.avatarUrl == null
                          ? const Icon(Icons.agriculture_rounded, size: 30, color: AppColors.headerGreenDark)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.farmName.isNotEmpty ? draft.farmName : 'My Farm',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            draft.fullName,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                          Text(
                            draft.clusterVillage,
                            style: const TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                _buildSummaryRow(Icons.landscape_rounded, 'Farm Area', '${draft.acres.toStringAsFixed(1)} Acres (${draft.soilType})'),
                _buildSummaryRow(Icons.eco_rounded, 'Farming Method', draft.farmingMethod.toUpperCase()),
                _buildSummaryRow(Icons.grass_rounded, 'Primary Crops', draft.primaryCrops.join(', ')),
                _buildSummaryRow(Icons.local_shipping_rounded, 'Selling Options', 'Delivery: ${draft.deliveryAvailable ? "${draft.deliveryRadiusKm.toInt()} km" : "No"} | Pickup: ${draft.pickupAvailable ? "Yes" : "No"} | Lead: ${draft.leadTime}'),

                if (draft.hasApmcBadge || draft.hasKccBadge || draft.hasOrganicBadge) ...[
                  const SizedBox(height: 12),
                  const Text('Earned Badges:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (draft.hasApmcBadge)
                        const Chip(label: Text('APMC Registered'), backgroundColor: AppColors.headerGreenDark, labelStyle: TextStyle(color: Colors.white, fontSize: 12)),
                      if (draft.hasKccBadge)
                        Chip(label: Text('KCC ${draft.kccStatus.toUpperCase()}'), backgroundColor: AppColors.headerGreenDark, labelStyle: const TextStyle(color: Colors.white, fontSize: 12)),
                      if (draft.hasOrganicBadge)
                        const Chip(label: Text('Organic Cert (Pending)'), backgroundColor: AppColors.amberOrange, labelStyle: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.headerGreenDark),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => ref.read(farmerWizardProvider.notifier).speakText(ttsText, langCode),
          icon: const Icon(Icons.volume_up_rounded, color: AppColors.amberOrange, size: 28),
          tooltip: 'Listen to instructions',
        ),
      ],
    );
  }

  Widget _buildMapPicker(BuildContext context, FarmerProfileDraft draft) {
    final lat = draft.farmLatitude ?? 13.245; // Default near Devanahalli / Bengaluru Rural
    final lng = draft.farmLongitude ?? 77.712;

    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 13.0,
                onTap: (tapPosition, point) {
                  ref.read(farmerWizardProvider.notifier).updateDraft(
                    (d) => d.copyWith(farmLatitude: point.latitude, farmLongitude: point.longitude),
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'in.udyogasethu',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.amberOrange,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Coords: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            TextButton.icon(
              onPressed: () async {
                await ref.read(farmerWizardProvider.notifier).logGpsConsent();
                try {
                  final pos = await Geolocator.getCurrentPosition();
                  ref.read(farmerWizardProvider.notifier).updateDraft(
                    (d) => d.copyWith(farmLatitude: pos.latitude, farmLongitude: pos.longitude),
                  );
                } catch (_) {}
              },
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: const Text('Use Current GPS'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await ref.read(farmerWizardProvider.notifier).uploadAvatarBytes(bytes, picked.name);
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadCert() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await ref.read(farmerWizardProvider.notifier).uploadOrganicCertBytes(bytes, picked.name);
      }
    } catch (_) {}
  }
}

extension on InputBorder {
  InputDecoration toInputDecoration() => InputDecoration(border: this);
}
