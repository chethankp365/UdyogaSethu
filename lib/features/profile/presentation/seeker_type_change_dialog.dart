import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class SeekerTypeChangeDialog extends ConsumerStatefulWidget {
  final String currentSeekerType;
  final ValueChanged<String>? onTypeChanged;

  const SeekerTypeChangeDialog({
    super.key,
    required this.currentSeekerType,
    this.onTypeChanged,
  });

  static Future<String?> show(BuildContext context, {
    required String currentSeekerType,
    ValueChanged<String>? onTypeChanged,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SeekerTypeChangeDialog(
        currentSeekerType: currentSeekerType,
        onTypeChanged: onTypeChanged,
      ),
    );
  }

  @override
  ConsumerState<SeekerTypeChangeDialog> createState() => _SeekerTypeChangeDialogState();
}

class _SeekerTypeChangeDialogState extends ConsumerState<SeekerTypeChangeDialog> {
  late String _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentSeekerType;
  }

  Future<void> _handleSave() async {
    if (_selectedType == widget.currentSeekerType) {
      Navigator.of(context).pop(_selectedType);
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (Supabase.instance.isInitialized) {
        final client = Supabase.instance.client;
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          await client.from('worker_profiles').update({
            'seeker_type': _selectedType,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('user_id', uid);
        }
      }

      // Update in-memory Riverpod session
      ref.read(appSessionProvider.notifier).setSeekerType(_selectedType);

      // Invalidate home controllers so feeds and stats update immediately
      ref.invalidate(seekerHomeProfileProvider);
      ref.invalidate(seekerRecommendedJobsProvider);
      ref.invalidate(seekerHomeSummaryProvider);

      widget.onTypeChanged?.call(_selectedType);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final label = _getLabelForType(_selectedType, l10n);
        Navigator.of(context).pop(_selectedType);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.categoryUpdatedSnackbar(label) ?? 'Category updated to $label! Feed refreshed.',
            ),
            backgroundColor: AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update category: $e')),
        );
      }
    }
  }

  String _getLabelForType(String type, AppLocalizations? l10n) {
    switch (type) {
      case 'student':
        return l10n?.categoryStudentTitle ?? 'Student Gig Worker';
      case 'part_time':
        return l10n?.categoryPartTimeTitle ?? 'Part-Time Worker';
      case 'informal':
      default:
        return l10n?.categoryInformalTitle ?? 'Informal / Skilled Worker';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.headerGreenDark.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: AppColors.headerGreenDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.changeCategoryTitle ?? 'Change Worker Category',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.changeCategorySubtitle ?? 'Select your work type to personalize jobs',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeOption(
              type: 'informal',
              icon: Icons.construction_rounded,
              title: l10n?.categoryInformalTitle ?? 'Informal / Skilled Worker',
              description: l10n?.categoryInformalDesc ?? 'Trades, craftsmanship, home services & agricultural work',
            ),
            const SizedBox(height: 8),
            _buildTypeOption(
              type: 'student',
              icon: Icons.school_rounded,
              title: l10n?.categoryStudentTitle ?? 'Student Gig Worker',
              description: l10n?.categoryStudentDesc ?? 'Campus gigs, tutoring, creative design & online tasks',
            ),
            const SizedBox(height: 8),
            _buildTypeOption(
              type: 'part_time',
              icon: Icons.work_history_rounded,
              title: l10n?.categoryPartTimeTitle ?? 'Part-Time Worker',
              description: l10n?.categoryPartTimeDesc ?? 'Retail, restaurant service, flexible evening & weekend shifts',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel', style: const TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.headerGreenDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n?.save ?? 'Save & Update', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required String type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paleMint.withValues(alpha: 0.5) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.headerGreenDark,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
