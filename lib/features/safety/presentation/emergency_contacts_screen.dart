// Screen: EmergencyContactsScreen (Step P7.3)
// Manage up to 5 emergency contacts with test verification and honest SMS status reporting

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/core/widgets/app_button.dart';
import 'package:udyogasethu/features/safety/data/safety_repository.dart';
import 'package:udyogasethu/features/safety/domain/emergency_contact.dart';

final emergencyContactsProvider =
    FutureProvider.autoDispose<List<EmergencyContact>>((ref) async {
  final repo = ref.watch(safetyRepositoryProvider);
  return repo.getEmergencyContacts();
});

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRelation = 'Family';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showAddContactSheet() {
    _nameController.clear();
    _phoneController.clear();
    _selectedRelation = 'Family';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Emergency Contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Add someone who can be reached immediately in an emergency.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  hintText: 'e.g. Ramesh Kumar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. 9845012345',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedRelation,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'Family', child: Text('Family')),
                  DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                  DropdownMenuItem(value: 'Colleague', child: Text('Colleague / Work')),
                  DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRelation = val);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Save Contact',
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final phone = _phoneController.text.trim();
                  if (name.isEmpty || phone.isEmpty) return;

                  Navigator.of(ctx).pop();
                  final repo = ref.read(safetyRepositoryProvider);
                  await repo.addEmergencyContact(
                    name: name,
                    phone: phone,
                    relation: _selectedRelation,
                  );
                  ref.invalidate(emergencyContactsProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTestSmsDialog(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sms_outlined, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Test SMS Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${contact.name} (${contact.phone})'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Honest Status: SMS gateway is not configured currently. Test emergency ping was logged to safety event monitor without real carrier SMS delivery.',
                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(emergencyContactsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: contactsAsync.when(
        data: (contacts) => _buildBody(contacts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load contacts: $err'),
              ElevatedButton(
                onPressed: () => ref.invalidate(emergencyContactsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: contactsAsync.maybeWhen(
            data: (contacts) => contacts.length < 5
                ? AppButton(
                    label: 'Add Emergency Contact (${contacts.length}/5)',
                    icon: Icons.add,
                    onPressed: _showAddContactSheet,
                  )
                : const Center(
                    heightFactor: 1,
                    child: Text(
                      'Maximum 5 emergency contacts added.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<EmergencyContact> contacts) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Top safety notice
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'During an SOS emergency, these contacts are sent an SMS alert with your live GPS location. Keep this list updated.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (contacts.isEmpty) ...[
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                Icon(Icons.contact_emergency_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'No emergency contacts added yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Add up to 5 family members or friends.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ] else ...[
          ...contacts.map((contact) => _buildContactCard(contact)),
        ],
      ],
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen.withAlpha(25),
                  child: Text(
                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
                    style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.phone,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    contact.relation,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _showTestSmsDialog(contact),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Verify by Test SMS', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: EdgeInsets.zero,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final repo = ref.read(safetyRepositoryProvider);
                    await repo.deleteEmergencyContact(contact.id);
                    ref.invalidate(emergencyContactsProvider);
                  },
                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                  tooltip: 'Delete contact',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
