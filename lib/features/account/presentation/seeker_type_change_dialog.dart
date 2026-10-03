import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/account/presentation/role_switcher_bottom_sheet.dart';
import 'package:udyogasethu/features/onboarding/domain/pending_role_selection.dart';

class SeekerTypeChangeDialog extends ConsumerStatefulWidget {
  final SeekerType currentType;

  const SeekerTypeChangeDialog({super.key, required this.currentType});

  static void show(BuildContext context, SeekerType currentType) {
    showDialog(
      context: context,
      builder: (context) => SeekerTypeChangeDialog(currentType: currentType),
    );
  }

  @override
  ConsumerState<SeekerTypeChangeDialog> createState() => _SeekerTypeChangeDialogState();
}

class _SeekerTypeChangeDialogState extends ConsumerState<SeekerTypeChangeDialog> {
  late SeekerType _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
  }

  Future<void> _saveTypeChange() async {
    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.id.isEmpty) {
        throw const AppException.auth('User not authenticated');
      }

      await ref.read(accountRepositoryProvider).updateSeekerType(userId: user.id, newType: _selectedType);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seeker category updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update seeker category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.category_rounded, color: AppColors.headerGreenDark),
          SizedBox(width: 8),
          Text('Change Seeker Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your job seeker work schedule category:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            _buildTile(
              type: SeekerType.informal,
              title: 'Informal / Daily-wage Worker',
              subtitle: 'Daily-wage construction, delivery, plumbing jobs with instant pay',
              icon: Icons.construction_rounded,
            ),
            const SizedBox(height: 8),
            _buildTile(
              type: SeekerType.student,
              title: 'Student',
              subtitle: 'Part-time shifts fitted around college timetable',
              icon: Icons.school_rounded,
            ),
            const SizedBox(height: 8),
            _buildTile(
              type: SeekerType.partTime,
              title: 'Part-time / Flexible Worker',
              subtitle: 'Flexible daily or weekend shifts',
              icon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 12),

            // Warning notice
            if (_selectedType != widget.currentType)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: Changing category will update job recommendations and may reset active student/academic verifications.',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.headerGreenDark,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _saveTypeChange,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Category'),
        ),
      ],
    );
  }

  Widget _buildTile({
    required SeekerType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = type == _selectedType;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.headerGreenDark.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.headerGreenDark : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.headerGreenDark, size: 20),
          ],
        ),
      ),
    );
  }
}
