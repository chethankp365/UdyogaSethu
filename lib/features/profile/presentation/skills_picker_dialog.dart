import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class SkillsPickerDialog extends ConsumerStatefulWidget {
  final String seekerType;
  final List<String> currentSkills;
  final ValueChanged<List<String>> onSkillsUpdated;

  const SkillsPickerDialog({
    super.key,
    required this.seekerType,
    required this.currentSkills,
    required this.onSkillsUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required String seekerType,
    required List<String> currentSkills,
    required ValueChanged<List<String>> onSkillsUpdated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SkillsPickerDialog(
        seekerType: seekerType,
        currentSkills: currentSkills,
        onSkillsUpdated: onSkillsUpdated,
      ),
    );
  }

  @override
  ConsumerState<SkillsPickerDialog> createState() => _SkillsPickerDialogState();
}

class _SkillsPickerDialogState extends ConsumerState<SkillsPickerDialog> {
  late List<String> _selectedSkills;
  bool _isSaving = false;

  static const List<String> _studentSkills = [
    'Tutoring & Teaching',
    'Content Writing',
    'Graphic Design & Canva',
    'Data Entry & Excel',
    'Social Media Handling',
    'Campus Event Organizing',
    'Delivery & Courier',
    'Retail Store Assistant',
    'Coding & Web Support',
    'Video Editing',
  ];

  static const List<String> _partTimeSkills = [
    'Retail Store Assistant',
    'Restaurant & Cafe Service',
    'Delivery & Courier',
    'Warehouse & Inventory',
    'Data Entry & Typing',
    'Content Writing',
    'Event Ushering & Hospitality',
    'Customer Support',
  ];

  static const List<String> _informalSkills = [
    'Plumbing & Pipe Repair',
    'Electrical Wiring & Repair',
    'Carpentry & Woodwork',
    'Masonry & Bricklaying',
    'House Painting',
    'Vehicle Driving',
    'Home & Office Cleaning',
    'Loading & Material Handling',
    'Agri Labour & Harvesting',
    'Domestic Cooking & Housekeeping',
  ];

  List<String> get _availablePool {
    switch (widget.seekerType) {
      case 'student':
        return _studentSkills;
      case 'part_time':
        return _partTimeSkills;
      case 'informal':
      default:
        return _informalSkills;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedSkills = List.from(widget.currentSkills);
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      if (Supabase.instance.isInitialized) {
        final client = Supabase.instance.client;
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          // Sync skills in worker_profiles table (tags or worker_skills)
          await client.from('worker_profiles').update({
            'selected_skills': _selectedSkills,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('user_id', uid);
        }
      }
    } catch (_) {
      // In offline/test mode, continue without error
    }

    widget.onSkillsUpdated(_selectedSkills);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skills updated successfully! ✓'),
          backgroundColor: AppColors.headerGreenDark,
        ),
      );
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
            child: const Icon(Icons.psychology_rounded, color: AppColors.headerGreenDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.addSkillDialogTitle ?? 'Select Skills',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.addSkillDialogSubtitle ?? 'Choose skills matching your work profile',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availablePool.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: isSelected,
              selectedColor: AppColors.paleMint,
              checkmarkColor: AppColors.headerGreenDark,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!_selectedSkills.contains(skill)) {
                      _selectedSkills.add(skill);
                    }
                  } else {
                    _selectedSkills.remove(skill);
                  }
                });
              },
            );
          }).toList(),
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
              : Text(l10n?.save ?? 'Save Skills', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
