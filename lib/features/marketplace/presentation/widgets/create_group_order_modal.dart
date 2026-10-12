import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/marketplace/domain/group_order_model.dart';
import 'package:udyogasethu/features/marketplace/presentation/subscriptions_controller.dart';

class CreateGroupOrderModal extends ConsumerStatefulWidget {
  const CreateGroupOrderModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CreateGroupOrderModal(),
    );
  }

  @override
  ConsumerState<CreateGroupOrderModal> createState() => _CreateGroupOrderModalState();
}

class _CreateGroupOrderModalState extends ConsumerState<CreateGroupOrderModal> {
  final _communityController = TextEditingController(text: 'Sobha Dream Acres, Panathur');
  String _listingId = 'list-mango';
  double _targetQty = 25.0;
  double _organizerQty = 5.0;
  int _deadlineHours = 48;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _sampleProduce = [
    {
      'id': 'list-mango',
      'name': 'Alphonso Mango 5kg Farm Crates',
      'tiers': [
        const GroupPriceTier(minQty: 10, pricePaise: 65000),
        const GroupPriceTier(minQty: 20, pricePaise: 58000),
        const GroupPriceTier(minQty: 30, pricePaise: 50000),
      ],
    },
    {
      'id': 'list-onions',
      'name': 'Nashik Red Onions (25kg Sacks)',
      'tiers': [
        const GroupPriceTier(minQty: 15, pricePaise: 75000),
        const GroupPriceTier(minQty: 30, pricePaise: 68000),
        const GroupPriceTier(minQty: 40, pricePaise: 60000),
      ],
    },
    {
      'id': 'list-rice',
      'name': 'Sona Masoori Organic Rice (25kg Bag)',
      'tiers': [
        const GroupPriceTier(minQty: 10, pricePaise: 140000),
        const GroupPriceTier(minQty: 25, pricePaise: 125000),
        const GroupPriceTier(minQty: 50, pricePaise: 110000),
      ],
    },
  ];

  @override
  void dispose() {
    _communityController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      final selectedItem = _sampleProduce.firstWhere((p) => p['id'] == _listingId);
      final tiers = selectedItem['tiers'] as List<GroupPriceTier>;

      await ref.read(subscriptionsControllerProvider.notifier).createGroupOrder(
            listingId: _listingId,
            communityName: _communityController.text.trim(),
            targetQty: _targetQty,
            priceTiers: tiers,
            deadline: DateTime.now().add(Duration(hours: _deadlineHours)),
            organizerQty: _organizerQty,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opened community group order for ${_communityController.text}!'),
            backgroundColor: AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Start Apartment Bulk Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Community Name
            const Text('Apartment / Community Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _communityController,
              decoration: InputDecoration(
                hintText: 'e.g., Prestige Falcon City, Koramangala',
                prefixIcon: const Icon(Icons.apartment_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),

            // Select Produce
            const Text('Farm Produce', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _listingId,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _sampleProduce.map((p) {
                return DropdownMenuItem<String>(
                  value: p['id'] as String,
                  child: Text(p['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _listingId = val;
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            // Target Quantity & Your Initial Pledge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Target Units', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<double>(
                        isExpanded: true,
                        initialValue: _targetQty,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 15.0, child: Text('15 units')),
                          DropdownMenuItem(value: 25.0, child: Text('25 units')),
                          DropdownMenuItem(value: 40.0, child: Text('40 units')),
                          DropdownMenuItem(value: 50.0, child: Text('50 units')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _targetQty = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Order (Units)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<double>(
                        isExpanded: true,
                        initialValue: _organizerQty,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 2.0, child: Text('2 units')),
                          DropdownMenuItem(value: 5.0, child: Text('5 units')),
                          DropdownMenuItem(value: 10.0, child: Text('10 units')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _organizerQty = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Deadline duration
            const Text('Order Deadline Window', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [24, 48, 72].map((hours) {
                final isSelected = _deadlineHours == hours;
                return ChoiceChip(
                  label: Text('$hours Hours'),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _deadlineHours = hours),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Launch Community Bulk Order',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
