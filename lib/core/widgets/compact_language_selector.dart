import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';

/// Compact horizontal language selector chip row shown at the top of login and header screens.
class CompactLanguageSelector extends ConsumerWidget {
  const CompactLanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    // Display top 5 prominent Indic languages
    final topLanguages = [
      AppLanguages.english,
      AppLanguages.kannada,
      AppLanguages.hindi,
      AppLanguages.telugu,
      AppLanguages.tamil,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: topLanguages.map((lang) {
          final isSelected = currentLocale.languageCode == lang.code;

          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              avatar: Text(
                lang.countryCode,
                style: AppTypography.label(
                  isSelected ? Colors.white : AppColors.headerGreenDark,
                ).copyWith(fontSize: 10),
              ),
              label: Text(
                lang.code == 'en' ? lang.englishName : lang.nativeName,
                style: AppTypography.bodySmall(
                  isSelected ? Colors.white : AppColors.textDark,
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.headerGreenDark,
              backgroundColor: AppColors.paleMint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? AppColors.headerGreenDark : AppColors.cardBorderGreen,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  ref.read(localeProvider.notifier).setLocale(lang.code);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
