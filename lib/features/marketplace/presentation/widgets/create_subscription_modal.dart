import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/marketplace/domain/subscription_model.dart';
import 'package:udyogasethu/features/marketplace/presentation/subscriptions_controller.dart';

class CreateSubscriptionModal extends ConsumerStatefulWidget {
  const CreateSubscriptionModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CreateSubscriptionModal(),
    );
  }

  @override
  ConsumerState<CreateSubscriptionModal> createState() => _CreateSubscriptionModalState();
}

class _CreateSubscriptionModalState extends ConsumerState<CreateSubscriptionModal> {
  String _selectedProduce = 'A2 Farm Milk Daily Subscription';
  String _listingId = 'list-001';
  double _quantity = 2.0;
  SubscriptionFrequency _frequency = SubscriptionFrequency.daily;
  String _slotTime = '07:00 AM';
  final _addressController = TextEditingController(text: 'Flat 402, Sunshine Apts, Koramangala');
  bool _isSubmitting = false;

  final List<Map<String, String>> _sampleListings = [
    {
      'id': 'list-001',
      'name': 'A2 Farm Milk Daily Subscription',
      'farmer': 'Pure A2 Gir Cow Farm',
      'price': '₹60/litre',
    },
    {
      'id': 'list-002',
      'name': 'Weekly Organic Farm Vegetable Box',
      'farmer': 'Ravi Organic Farm, Devanahalli',
      'price': '₹350/box',
    },
    {
      'id': 'list-003',
      'name': 'Fresh Tender Coconut Morning Delivery',
      'farmer': 'Mandya Palms Co-op',
      'price': '₹40/nut',
    },
  ];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(subscriptionsControllerProvider.notifier).createSubscription(
            listingId: _listingId,
            quantity: _quantity,
            frequency: _frequency,
            deliverySlotTime: _slotTime,
            doorstepAddress: _addressController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscribed to $_selectedProduce! Tomorrow\'s delivery scheduled.'),
            backgroundColor: AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating subscription: $e')),
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
                    'New Farm Subscription',
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

            // Select Produce Listing
            const Text(
              'Select Produce / Farm Listing',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            ..._sampleListings.map((item) {
              final isSelected = item['id'] == _listingId;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.headerGreenDark : const Color(0xFFCBD5E1),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? AppColors.paleMint.withValues(alpha: 0.3) : Colors.white,
                ),
                child: ListTile(
                  dense: true,
                  title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${item['farmer']} • ${item['price']}', style: const TextStyle(fontSize: 11)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.headerGreenDark)
                      : null,
                  onTap: () {
                    setState(() {
                      _listingId = item['id']!;
                      _selectedProduce = item['name']!;
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 12),

            // Frequency
            const Text(
              'Delivery Frequency',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: SubscriptionFrequency.values.map((f) {
                final isSelected = f == _frequency;
                return ChoiceChip(
                  label: Text(f.label),
                  selected: isSelected,
                  selectedColor: AppColors.headerGreenDark,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _frequency = f),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Quantity & Preferred Slot
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantity per Delivery',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: _quantity > 1.0 ? () => setState(() => _quantity -= 1.0) : null,
                              icon: const Icon(Icons.remove, size: 16),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _quantity.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              onPressed: () => setState(() => _quantity += 1.0),
                              icon: const Icon(Icons.add, size: 16),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Morning Doorstep Slot',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _slotTime,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: '06:30 AM', child: Text('06:30 AM')),
                          DropdownMenuItem(value: '07:00 AM', child: Text('07:00 AM')),
                          DropdownMenuItem(value: '07:30 AM', child: Text('07:30 AM')),
                          DropdownMenuItem(value: '08:00 AM', child: Text('08:00 AM')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _slotTime = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Doorstep Address
            const Text(
              'Doorstep Delivery Address',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Enter apartment, flat number, street',
                prefixIcon: const Icon(Icons.home_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Start Subscription',
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
