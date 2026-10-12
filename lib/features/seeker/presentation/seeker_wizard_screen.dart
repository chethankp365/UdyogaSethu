import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/core/widgets/info_banner.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class SeekerWizardScreen extends ConsumerStatefulWidget {
  const SeekerWizardScreen({super.key});

  @override
  ConsumerState<SeekerWizardScreen> createState() => _SeekerWizardScreenState();
}

class _SeekerWizardScreenState extends ConsumerState<SeekerWizardScreen> {
  final _picker = ImagePicker();
  Uint8List? _localAvatarBytes;
  ImageSource? _lastPickedSource;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wizardAsync = ref.watch(seekerWizardProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.roleSeekerTitle,
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.sosRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(seekerWizardProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          final draft = state.draft;
          final step = draft.currentStep;

          return SafeArea(
            child: Column(
              children: [
                // Top Progress Bar & Header
                _buildHeader(context, ref, l10n, step, locale.languageCode),

                // Error banners if any
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InfoBanner(
                      text: state.errorMessage!,
                      type: InfoBannerType.emergency,
                    ),
                  ),

                // Active Step Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildStepView(context, ref, l10n, state),
                  ),
                ),

                // Bottom Navigation (Back / Next)
                _buildBottomNav(context, ref, l10n, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    int step,
    String langCode,
  ) {
    final progress = step / 7.0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.wizardStepProgress(step, 7),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.headerGreenDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: AppColors.headerGreenDark, size: 26),
                tooltip: 'Listen instructions',
                onPressed: () {
                  final text = _getStepInstruction(l10n, step);
                  ref.read(seekerWizardProvider.notifier).speakText(text, langCode);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.paleMint,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.headerGreenDark),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepInstruction(AppLocalizations l10n, int step) {
    switch (step) {
      case 1:
        return '${l10n.wizardStep1Title}. ${l10n.wizardStep1Subtitle}';
      case 2:
        return '${l10n.wizardStep2Title}. ${l10n.wizardStep2Subtitle}';
      case 3:
        return '${l10n.wizardStep3Title}. ${l10n.wizardStep3Subtitle}';
      case 4:
        return '${l10n.wizardStep4Title}. ${l10n.wizardStep4Subtitle}';
      case 5:
        return '${l10n.wizardStep5Title}. ${l10n.wizardStep5Subtitle}';
      case 6:
        return '${l10n.wizardStep6Title}. ${l10n.wizardStep6Subtitle}';
      case 7:
        return '${l10n.wizardStep7Title}. ${l10n.wizardStep7Subtitle}';
      default:
        return '';
    }
  }

  Widget _buildStepView(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SeekerWizardState state,
  ) {
    switch (state.draft.currentStep) {
      case 1:
        return _buildStep1Basics(context, ref, l10n, state);
      case 2:
        return _buildStep2Skills(context, ref, l10n, state);
      case 3:
        return _buildStep3ExperienceRate(context, ref, l10n, state);
      case 4:
        return _buildStep4Availability(context, ref, l10n, state);
      case 5:
        return _buildStep5Location(context, ref, l10n, state);
      case 6:
        return _buildStep6TypeSpecific(context, ref, l10n, state);
      case 7:
        return _buildStep7Review(context, ref, l10n, state);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: BASICS
  Widget _buildStep1Basics(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SeekerWizardState state,
  ) {
    final draft = state.draft;
    final notifier = ref.read(seekerWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wizardStep1Title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.wizardStep1Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),

        // Photo Upload Box
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
                    onPressed: state.isSaving ? null : () => _pickAndUploadPhoto(ref, ImageSource.camera),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.headerGreenDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt, size: 18, color: AppColors.headerGreenDark),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.takePhotoCamera,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: AppColors.headerGreenDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: state.isSaving ? null : () => _pickAndUploadPhoto(ref, ImageSource.gallery),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.headerGreenDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library, size: 18, color: AppColors.headerGreenDark),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.chooseGallery,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: AppColors.headerGreenDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.uploadError != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.uploadPhotoError,
                  style: const TextStyle(color: AppColors.sosRed, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.uploadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.sosRed, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: state.isSaving ? null : () => _retryUpload(ref),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.retry),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Full Name Field
        Text(
          l10n.fullName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: draft.fullName,
          decoration: InputDecoration(
            hintText: l10n.enterName,
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            notifier.updateDraft((d) => d.copyWith(fullName: val));
          },
        ),
        const SizedBox(height: 20),

        // Gender Selector (Optional)
        Text(
          l10n.genderLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            _buildChoiceChip('male', l10n.genderMale, draft.gender, (val) {
              notifier.updateDraft((d) => d.copyWith(gender: val));
            }),
            _buildChoiceChip('female', l10n.genderFemale, draft.gender, (val) {
              notifier.updateDraft((d) => d.copyWith(gender: val));
            }),
            _buildChoiceChip('other', l10n.genderOther, draft.gender, (val) {
              notifier.updateDraft((d) => d.copyWith(gender: val));
            }),
            _buildChoiceChip('prefer_not_to_say', l10n.genderPreferNot, draft.gender, (val) {
              notifier.updateDraft((d) => d.copyWith(gender: val));
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Languages Spoken
        Text(
          l10n.languagesLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildLangFilterChip('kn', 'ಕನ್ನಡ (Kannada)', draft.languages, notifier),
            _buildLangFilterChip('en', 'English', draft.languages, notifier),
            _buildLangFilterChip('hi', 'हिंदी (Hindi)', draft.languages, notifier),
            _buildLangFilterChip('te', 'తెలుగు (Telugu)', draft.languages, notifier),
            _buildLangFilterChip('ta', 'தமிழ் (Tamil)', draft.languages, notifier),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto(WidgetRef ref, ImageSource source) async {
    _lastPickedSource = source;
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _localAvatarBytes = bytes;
        });
        final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await ref
            .read(seekerWizardProvider.notifier)
            .uploadAvatarPhoto(bytes, filename);
      }
    } catch (e) {
      ref.read(seekerWizardProvider.notifier).setUploadError(e.toString());
    }
  }

  Future<void> _retryUpload(WidgetRef ref) async {
    if (_localAvatarBytes != null) {
      final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await ref
          .read(seekerWizardProvider.notifier)
          .uploadAvatarPhoto(_localAvatarBytes!, filename);
    } else if (_lastPickedSource != null) {
      _pickAndUploadPhoto(ref, _lastPickedSource!);
    }
  }

  Widget _buildChoiceChip(
    String value,
    String label,
    String? currentSelected,
    ValueChanged<String> onSelected,
  ) {
    final selected = currentSelected == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.headerGreenDark,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textDark,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (bool sel) {
        if (sel) onSelected(value);
      },
    );
  }

  Widget _buildLangFilterChip(
    String langCode,
    String label,
    List<String> currentLangs,
    SeekerWizardNotifier notifier,
  ) {
    final selected = currentLangs.contains(langCode);
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.paleMint,
      checkmarkColor: AppColors.headerGreenDark,
      labelStyle: TextStyle(
        color: selected ? AppColors.headerGreenDark : AppColors.textDark,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (bool sel) {
        final updated = List<String>.from(currentLangs);
        if (sel) {
          if (!updated.contains(langCode)) updated.add(langCode);
        } else {
          if (updated.length > 1) updated.remove(langCode);
        }
        notifier.updateDraft((d) => d.copyWith(languages: updated));
      },
    );
  }

  // STEP 2: SKILLS & INTERESTS
  Widget _buildStep2Skills(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SeekerWizardState state,
  ) {
    final draft = state.draft;
    final categoriesAsync = ref.watch(categoriesProvider);
    final skillsAsync = ref.watch(skillsProvider);
    final locale = ref.watch(localeProvider);
    final notifier = ref.read(seekerWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wizardStep2Title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.wizardStep2Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        if (draft.seekerType == 'informal')
          InfoBanner(
            text: l10n.informalSkillRequired,
            type: InfoBannerType.warning,
          ),

        const SizedBox(height: 16),
        Text(
          l10n.selectCategories,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),

        categoriesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, s) => Text('Error loading categories: $e'),
          data: (categories) {
            final visibleCategories = categories.where((cat) => cat.matchesSeekerType(draft.seekerType)).toList();
            final catsToDisplay = visibleCategories.isNotEmpty ? visibleCategories : categories;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: catsToDisplay.map((cat) {
                final isSelected = draft.selectedCategoryIds.contains(cat.id);
                return FilterChip(
                  label: Text(cat.getLocalizedName(locale.languageCode)),
                  selected: isSelected,
                  selectedColor: AppColors.paleMint,
                  checkmarkColor: AppColors.headerGreenDark,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    final updatedCats = List<String>.from(draft.selectedCategoryIds);
                    if (selected) {
                      updatedCats.add(cat.id);
                    } else {
                      updatedCats.remove(cat.id);
                    }
                    notifier.updateDraft((d) => d.copyWith(selectedCategoryIds: updatedCats));
                  },
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 24),
        Text(
          l10n.selectSkills,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),

        skillsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, s) => Text('Error loading skills: $e'),
          data: (allSkills) {
            final allSkillIdsFromDb = allSkills.map((s) => s.id).toSet();
            final customSkills = draft.selectedSkillIds.where((sId) => !allSkillIdsFromDb.contains(sId)).toList();

            if (draft.selectedCategoryIds.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.paleMint.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.headerGreenDark, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please select at least one category above to view available skills.',
                            style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (customSkills.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: customSkills.map((customSkill) {
                        return FilterChip(
                          label: Text(customSkill),
                          selected: true,
                          selectedColor: AppColors.headerGreenDark,
                          checkmarkColor: Colors.white,
                          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          onSelected: (_) {
                            final updatedSkills = List<String>.from(draft.selectedSkillIds)..remove(customSkill);
                            notifier.updateDraft((d) => d.copyWith(selectedSkillIds: updatedSkills));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _CustomSkillInput(
                    onAddSkill: (customSkillText) {
                      final text = customSkillText.trim();
                      if (text.isNotEmpty && !draft.selectedSkillIds.contains(text)) {
                        final updatedSkills = List<String>.from(draft.selectedSkillIds)..add(text);
                        notifier.updateDraft((d) => d.copyWith(selectedSkillIds: updatedSkills));
                      }
                    },
                  ),
                ],
              );
            }

            final categoriesList = categoriesAsync.value ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...draft.selectedCategoryIds.map((catId) {
                  final category = categoriesList.firstWhere(
                    (c) => c.id == catId,
                    orElse: () => ServiceCategoryItem(id: catId, slug: catId, names: {'en': catId}),
                  );
                  final categorySkills = allSkills.where((sk) => sk.categoryId == catId).toList();

                  if (categorySkills.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.getLocalizedName(locale.languageCode),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categorySkills.map((sk) {
                            final isSelected = draft.selectedSkillIds.contains(sk.id);
                            return FilterChip(
                              label: Text(sk.getLocalizedName(locale.languageCode)),
                              selected: isSelected,
                              selectedColor: AppColors.headerGreenDark,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textDark,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                final updatedSkills = List<String>.from(draft.selectedSkillIds);
                                if (selected) {
                                  updatedSkills.add(sk.id);
                                } else {
                                  updatedSkills.remove(sk.id);
                                }
                                notifier.updateDraft((d) => d.copyWith(selectedSkillIds: updatedSkills));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
                if (customSkills.isNotEmpty) ...[
                  const Text(
                    'Custom Skills',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: customSkills.map((customSkill) {
                      return FilterChip(
                        label: Text(customSkill),
                        selected: true,
                        selectedColor: AppColors.headerGreenDark,
                        checkmarkColor: Colors.white,
                        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        onSelected: (_) {
                          final updatedSkills = List<String>.from(draft.selectedSkillIds)..remove(customSkill);
                          notifier.updateDraft((d) => d.copyWith(selectedSkillIds: updatedSkills));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                _CustomSkillInput(
                  onAddSkill: (customSkillText) {
                    final text = customSkillText.trim();
                    if (text.isNotEmpty && !draft.selectedSkillIds.contains(text)) {
                      final updatedSkills = List<String>.from(draft.selectedSkillIds)..add(text);
                      notifier.updateDraft((d) => d.copyWith(selectedSkillIds: updatedSkills));
                    }
                  },
                ),
              ],
            );
          },
        ),

        if (draft.seekerType == 'student' || draft.seekerType == 'part_time') ...[
          const SizedBox(height: 24),
          Text(
            l10n.subjectsInterestsLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          _SubjectsInterestsInput(
            initialItems: draft.subjectsInterests,
            onChanged: (items) {
              notifier.updateDraft((d) => d.copyWith(subjectsInterests: items));
            },
          ),
        ],
      ],
    );
  }

  // STEP 3: EXPERIENCE & RATE
  Widget _buildStep3ExperienceRate(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SeekerWizardState state,
  ) {
    final draft = state.draft;
    final notifier = ref.read(seekerWizardProvider.notifier);
    final firstCatId = draft.selectedCategoryIds.isNotEmpty ? draft.selectedCategoryIds.first : null;
    final wageBandAsync = ref.watch(wageBandProvider(firstCatId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wizardStep3Title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.wizardStep3Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),

        // Wage Band Suggestion Range Hint
        wageBandAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
          data: (band) {
            final minRs = ((band?.minPaise ?? 60000) / 100).round();
            final maxRs = ((band?.maxPaise ?? 120000) / 100).round();
            final unit = band?.unit ?? 'day';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paleMint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorderGreen),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.headerGreenDark, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.wageBandHint(minRs, maxRs, unit),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headerGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Experience Years
        Text(
          '${l10n.experienceYearsLabel}: ${draft.experienceYears.toStringAsFixed(1)} years',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        Slider(
          value: draft.experienceYears,
          min: 0,
          max: 30,
          divisions: 60,
          activeColor: AppColors.headerGreenDark,
          label: '${draft.experienceYears.toStringAsFixed(1)} yrs',
          onChanged: (val) {
            notifier.updateDraft((d) => d.copyWith(experienceYears: val));
          },
        ),

        const SizedBox(height: 20),

        // Daily Rate Input
        Text(
          l10n.dailyRateLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: draft.dailyRatePaise != null ? (draft.dailyRatePaise! ~/ 100).toString() : '',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: 'e.g. 800',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            final rs = int.tryParse(val);
            notifier.updateDraft((d) => d.copyWith(dailyRatePaise: rs != null ? rs * 100 : null));
          },
        ),

        const SizedBox(height: 20),

        // Hourly Rate Input
        Text(
          l10n.hourlyRateLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: draft.hourlyRatePaise != null ? (draft.hourlyRatePaise! ~/ 100).toString() : '',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: 'e.g. 120',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            final rs = int.tryParse(val);
            notifier.updateDraft((d) => d.copyWith(hourlyRatePaise: rs != null ? rs * 100 : null));
          },
        ),
      ],
    );
  }

  // STEP 4: AVAILABILITY
  Widget _buildStep4Availability(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SeekerWizardState state,
  ) {
    final draft = state.draft;
    final notifier = ref.read(seekerWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wizardStep4Title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.wizardStep4Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),

        // Status Choices
        const Text(
          'Availability Status',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard('available', l10n.statusAvailable, Icons.check_circle_outline, draft.availabilityStatus, notifier),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusCard('busy', l10n.statusBusy, Icons.access_time, draft.availabilityStatus, notifier),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusCard('offline', l10n.statusOffline, Icons.do_not_disturb, draft.availabilityStatus, notifier),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Working Days Chips
        Text(
          l10n.workingDaysLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
            final isSelected = draft.workingDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              selectedColor: AppColors.headerGreenDark,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark),
              onSelected: (sel) {
                final updated = List<String>.from(draft.workingDays);
                if (sel) {
                  updated.add(day);
                } else {
                  updated.remove(day);
                }
                notifier.updateDraft((d) => d.copyWith(workingDays: updated));
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Student Timetable or Part-Timer Shifts
        if (draft.seekerType == 'student') ...[
          Text(
            l10n.studentWeeklyHoursLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Slider(
            value: (draft.preferredHoursJson['weekly_hours'] as num?)?.toDouble() ?? 20.0,
            min: 5,
            max: 40,
            divisions: 7,
            activeColor: AppColors.headerGreenDark,
            label: '${(draft.preferredHoursJson['weekly_hours'] ?? 20)} hrs/week',
            onChanged: (val) {
              final map = Map<String, dynamic>.from(draft.preferredHoursJson);
              map['weekly_hours'] = val.toInt();
              notifier.updateDraft((d) => d.copyWith(preferredHoursJson: map));
            },
          ),
        ] else if (draft.seekerType == 'part_time') ...[
          Text(
            l10n.partTimeShiftLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildShiftChip('morning', l10n.shiftMorning, draft.preferredHoursJson['shift'] as String? ?? 'morning', draft.preferredHoursJson, notifier),
              _buildShiftChip('evening', l10n.shiftEvening, draft.preferredHoursJson['shift'] as String?, draft.preferredHoursJson, notifier),
              _buildShiftChip('flexible', l10n.shiftFlexible, draft.preferredHoursJson['shift'] as String?, draft.preferredHoursJson, notifier),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildShiftChip(
    String value,
    String label,
    String? currentSelected,
    Map<String, dynamic> currentMap,
    SeekerWizardNotifier notifier,
  ) {
    final selected = currentSelected == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.headerGreenDark,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textDark,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (bool sel) {
        if (sel) {
          final map = Map<String, dynamic>.from(currentMap);
          map['shift'] = value;
          notifier.updateDraft((d) => d.copyWith(preferredHoursJson: map));
        }
      },
    );
  }

  Widget _buildStatusCard(
    String value,
    String label,
    IconData icon,
    String currentSelected,
    SeekerWizardNotifier notifier,
  ) {
    final selected = currentSelected == value;
    return GestureDetector(
      onTap: () {
        notifier.updateDraft((d) => d.copyWith(availabilityStatus: value));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.paleMint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.headerGreenDark : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.headerGreenDark : AppColors.textMuted),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.headerGreenDark : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 5: LOCATION
  Widget _buildStep5Location(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SeekerWizardState state,
  ) {
    final draft = state.draft;
    final notifier = ref.read(seekerWizardProvider.notifier);

    final mapCenter = LatLng(
      draft.latitude ?? 12.9352, // Default Koramangala Bengaluru
      draft.longitude ?? 77.6245,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wizardStep5Title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.wizardStep5Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        // JIT Consent Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paleMint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorderGreen),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.headerGreenDark),
                  const SizedBox(width: 8),
                  Text(
                    l10n.locationConsentTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.locationConsentText,
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await notifier.logGpsConsent();
                  try {
                    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GPS is turned off. Please turn on location.')),
                        );
                      }
                      return;
                    }

                    LocationPermission permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                    }

                    if (permission == LocationPermission.whileInUse ||
                        permission == LocationPermission.always) {
                      final pos = await Geolocator.getCurrentPosition();
                      notifier.updateDraft((d) => d.copyWith(
                            latitude: pos.latitude,
                            longitude: pos.longitude,
                            homeAddress: 'Near Koramangala, Bengaluru',
                          ));
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.locationPermissionDenied)),
                        );
                      }
                    }
                  } catch (e) {
                    AppLogger.e('Location detection error', e, StackTrace.current);
                  }
                },
                icon: const Icon(Icons.my_location),
                label: Text(l10n.allowLocationAccess),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Interactive Map Picker using flutter_map
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 14.0,
                onTap: (tapPos, point) {
                  notifier.updateDraft((d) => d.copyWith(
                        latitude: point.latitude,
                        longitude: point.longitude,
                      ));
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
                      point: mapCenter,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.sosRed,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Address Field
        Text(
          l10n.addressLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: draft.homeAddress ?? '',
          decoration: InputDecoration(
            hintText: 'e.g. #42, 4th Block, Koramangala, Bengaluru',
            prefixIcon: const Icon(Icons.home_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            notifier.updateDraft((d) => d.copyWith(homeAddress: val));
          },
        ),

        const SizedBox(height: 20),

        // Service Radius Slider
        Text(
          l10n.serviceRadiusLabel(draft.serviceRadiusKm.toStringAsFixed(1)),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        Slider(
          value: draft.serviceRadiusKm,
          min: 1.0,
          max: 50.0,
          divisions: 49,
          activeColor: AppColors.headerGreenDark,
          label: '${draft.serviceRadiusKm.toStringAsFixed(1)} km',
          onChanged: (val) {
            notifier.updateDraft((d) => d.copyWith(serviceRadiusKm: val));
          },
        ),
      ],
    );
  }

  // STEP 6: TYPE SPECIFIC
  Widget _buildStep6TypeSpecific(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SeekerWizardState state,
  ) {
    final draft = state.draft;
    final notifier = ref.read(seekerWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wizardStep6Title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.wizardStep6Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),

        if (draft.seekerType == 'student') ...[
          Text(
            l10n.collegeNameLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: draft.collegeName ?? '',
            decoration: InputDecoration(
              hintText: 'e.g. BMS College of Engineering',
              prefixIcon: const Icon(Icons.school_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              notifier.updateDraft((d) => d.copyWith(collegeName: val));
            },
          ),
          const SizedBox(height: 16),
          Text(
            l10n.courseNameLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: draft.courseName ?? '',
            decoration: InputDecoration(
              hintText: 'e.g. BE Computer Science',
              prefixIcon: const Icon(Icons.book_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              notifier.updateDraft((d) => d.copyWith(courseName: val));
            },
          ),
          const SizedBox(height: 16),
          Text(
            l10n.regNoLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: draft.regNoMasked ?? '',
            decoration: InputDecoration(
              hintText: 'e.g. 1BM23CS108',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              final masked = SeekerProfileDraft.maskRegNo(val);
              notifier.updateDraft((d) => d.copyWith(regNoMasked: masked));
            },
          ),
        ] else if (draft.seekerType == 'informal') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(
                    l10n.doYouDriveToggle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  value: draft.hasDrivingLicence,
                  activeTrackColor: AppColors.headerGreenDark,
                  onChanged: (val) {
                    notifier.updateDraft((d) => d.copyWith(hasDrivingLicence: val));
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    l10n.drivingLicenceExplanation,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const InfoBanner(
            text: 'Part-time preferences saved. Flexible shift options selected.',
            type: InfoBannerType.safety,
          ),
        ],
      ],
    );
  }

  // STEP 7: REVIEW & FINISH
  Widget _buildStep7Review(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SeekerWizardState state,
  ) {
    final draft = state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wizardStep7Title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.wizardStep7Subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        // Summary Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      avatarPath: draft.avatarPath ?? draft.avatarUrl,
                      imageBytes: _localAvatarBytes,
                      name: draft.fullName,
                      radius: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.fullName.isNotEmpty ? draft.fullName : 'Job Seeker',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.paleMint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              draft.seekerType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.headerGreenDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _summaryRow('Languages', draft.languages.join(', ')),
                _summaryRow('Experience', '${draft.experienceYears.toStringAsFixed(1)} years'),
                _summaryRow(
                  'Daily Rate',
                  draft.dailyRatePaise != null
                      ? '₹${draft.dailyRatePaise! ~/ 100}'
                      : 'Not set',
                ),
                _summaryRow('Availability', draft.availabilityStatus.toUpperCase()),
                _summaryRow('Working Days', draft.workingDays.join(', ')),
                _summaryRow('Address', draft.homeAddress ?? 'Not set'),
                _summaryRow('Service Radius', '${draft.serviceRadiusKm.toStringAsFixed(1)} km'),
                if (draft.seekerType == 'student') ...[
                  _summaryRow('College', draft.collegeName ?? '-'),
                  _summaryRow('Course', draft.courseName ?? '-'),
                  _summaryRow('Reg/USN', draft.regNoMasked ?? '-'),
                ],
                if (draft.seekerType == 'informal')
                  _summaryRow('Drives Vehicle', draft.hasDrivingLicence ? 'Yes' : 'No'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        InfoBanner(
          text: l10n.verifyIdentityPrompt,
          type: InfoBannerType.warning,
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SeekerWizardState state,
  ) {
    final step = state.draft.currentStep;
    final notifier = ref.read(seekerWizardProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          if (step > 1)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.headerGreenDark),
                ),
                onPressed: state.isSaving ? null : () => notifier.prevStep(),
                child: Text(l10n.back),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            child: AppButton(
              label: step == 7 ? l10n.finishProfileButton : l10n.continueButton,
              isLoading: state.isSaving,
              onPressed: () async {
                // Validation check for Step 1 Full Name
                if (step == 1 && state.draft.fullName.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your full name.')),
                  );
                  return;
                }

                // Validation check for Informal workers on Step 2
                if (step == 2 &&
                    state.draft.seekerType == 'informal' &&
                    state.draft.selectedSkillIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.informalSkillRequired)),
                  );
                  return;
                }

                final success = await notifier.saveAndNext();
                if (success && step == 7 && context.mounted) {
                  // Navigate to Seeker Home
                  context.go('/seeker/home');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectsInterestsInput extends StatefulWidget {
  final List<String> initialItems;
  final ValueChanged<List<String>> onChanged;

  const _SubjectsInterestsInput({
    required this.initialItems,
    required this.onChanged,
  });

  @override
  State<_SubjectsInterestsInput> createState() => _SubjectsInterestsInputState();
}

class _SubjectsInterestsInputState extends State<_SubjectsInterestsInput> {
  late List<String> _items;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.initialItems);
  }

  void _addItem() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !_items.contains(text)) {
      setState(() {
        _items.add(text);
        _textController.clear();
      });
      widget.onChanged(_items);
    }
  }

  void _removeItem(String item) {
    setState(() {
      _items.remove(item);
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Coding, Math, Tutoring',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.headerGreenDark, size: 36),
              onPressed: _addItem,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _items.map((item) {
            return Chip(
              label: Text(item),
              onDeleted: () => _removeItem(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CustomSkillInput extends StatefulWidget {
  final ValueChanged<String> onAddSkill;
  const _CustomSkillInput({required this.onAddSkill});

  @override
  State<_CustomSkillInput> createState() => _CustomSkillInputState();
}

class _CustomSkillInputState extends State<_CustomSkillInput> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAddSkill(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Add your own skill (e.g. Putty Work, Plumbing)',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Skill', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.headerGreenDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
