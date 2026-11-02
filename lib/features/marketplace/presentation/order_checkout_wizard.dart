import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../data/orders_repository.dart';
import '../domain/cart_item.dart';
import '../domain/delivery_slot.dart';

class OrderCheckoutWizard extends ConsumerStatefulWidget {
  const OrderCheckoutWizard({super.key});

  @override
  ConsumerState<OrderCheckoutWizard> createState() => _OrderCheckoutWizardState();
}

class _OrderCheckoutWizardState extends ConsumerState<OrderCheckoutWizard> {
  int _currentStep = 0; // 0: Slot, 1: Address, 2: Payment
  String _fulfilment = 'delivery'; // 'delivery' or 'pickup'
  final TextEditingController _addressController = TextEditingController(
    text: 'Flat 304, Cauvery Heights, 4th Cross, Mandya Agri Market Road',
  );
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(
    text: '+91 98765 43210',
  );

  String _paymentMethod = 'upi';
  bool _isProtected = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Selected slot per farmer: farmerId -> slotId
  final Map<String, String> _selectedSlots = {};

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cartState = ref.watch(cartNotifierProvider);

    if (cartState.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.checkoutTitle ?? 'Checkout')),
        body: Center(
          child: Text(l10n?.cartEmptyTitle ?? 'Your cart is empty'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.checkoutTitle ?? 'Direct Farm Checkout',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Step progress indicator
          _buildStepHeader(l10n),

          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
              child: _buildCurrentStepView(cartState, l10n),
            ),
          ),

          // Bottom Action Bar
          _buildBottomAction(cartState, l10n),
        ],
      ),
    );
  }

  Widget _buildStepHeader(AppLocalizations? l10n) {
    final steps = [
      l10n?.stepSlot ?? '1. Delivery Slot',
      l10n?.stepAddress ?? '2. Address',
      l10n?.stepPayment ?? '3. Payment',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final title = entry.value;
          final isCurrent = _currentStep == idx;
          final isPast = _currentStep > idx;

          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCurrent || isPast
                      ? const Color(0xFF0D6548)
                      : const Color(0xFFCBD5E1),
                  child: isPast
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStepView(CartState cartState, AppLocalizations? l10n) {
    switch (_currentStep) {
      case 0:
        return _buildSlotStep(cartState, l10n);
      case 1:
        return _buildAddressStep(l10n);
      case 2:
        return _buildPaymentStep(cartState, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: DELIVERY SLOTS & FULFILMENT
  // ---------------------------------------------------------------------------
  Widget _buildSlotStep(CartState cartState, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fulfilment Type Switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _fulfilment = 'delivery'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _fulfilment == 'delivery'
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _fulfilment == 'delivery'
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 18,
                          color: _fulfilment == 'delivery'
                              ? const Color(0xFF0D6548)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n?.doorstepDelivery ?? 'Doorstep Delivery',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _fulfilment == 'delivery'
                                  ? const Color(0xFF0D6548)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _fulfilment = 'pickup'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _fulfilment == 'pickup'
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _fulfilment == 'pickup'
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 18,
                          color: _fulfilment == 'pickup'
                              ? const Color(0xFF0D6548)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n?.farmPickup ?? 'Farm Pickup',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _fulfilment == 'pickup'
                                  ? const Color(0xFF0D6548)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Delivery Slots per farmer
        ...cartState.farmerGroups.map((group) {
          return _buildFarmerSlotsSection(group, l10n);
        }),
      ],
    );
  }

  Widget _buildFarmerSlotsSection(FarmerCartGroup group, AppLocalizations? l10n) {
    final slotsAsync = ref.watch(farmerDeliverySlotsProvider(group.farmerId));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.agriculture, color: Color(0xFF0D6548), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${group.farmerName} Slots',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n?.selectDeliveryWindow ?? 'Select your preferred harvest and arrival window',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),

            slotsAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n?.noSlotsAvailable ?? 'No active slots available for this farm.',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }

                // Auto select first slot if not set
                if (!_selectedSlots.containsKey(group.farmerId)) {
                  final firstAvailable = slots.firstWhere(
                    (s) => !s.isFull,
                    orElse: () => slots.first,
                  );
                  _selectedSlots[group.farmerId] = firstAvailable.id;
                }

                return Column(
                  children: slots.map((slot) {
                    final isSelected = _selectedSlots[group.farmerId] == slot.id;
                    return _buildSlotTile(group.farmerId, slot, isSelected, l10n);
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0D6548)),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Could not load slots: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotTile(
    String farmerId,
    DeliverySlot slot,
    bool isSelected,
    AppLocalizations? l10n,
  ) {
    Color modeColor;
    String modeLabel;
    switch (slot.mode) {
      case DeliveryMode.sameDay:
        modeColor = const Color(0xFF00875A);
        modeLabel = l10n?.slotSameDay ?? 'Same Day';
        break;
      case DeliveryMode.nextDay:
        modeColor = const Color(0xFF2563EB);
        modeLabel = l10n?.slotNextDay ?? 'Next Day';
        break;
      case DeliveryMode.preOrder:
        modeColor = const Color(0xFFD97706);
        modeLabel = l10n?.slotPreOrder ?? 'Pre-Order';
        break;
    }

    return GestureDetector(
      onTap: slot.isFull
          ? null
          : () {
              setState(() {
                _selectedSlots[farmerId] = slot.id;
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00875A)
                : (slot.isFull ? const Color(0xFFF1F5F9) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio indicator
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? const Color(0xFF00875A) : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: modeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              modeLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: modeColor,
                              ),
                            ),
                          ),
                          Text(
                            slot.formattedDate,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: slot.isFull ? Colors.grey : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            slot.formattedWindow,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: slot.isFull ? Colors.grey : const Color(0xFF0D6548),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        slot.freshnessNote,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            size: 13,
                            color: slot.isFull ? Colors.red : const Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              slot.isFull
                                  ? (l10n?.slotFullLabel ?? 'Slot Full (0 remaining)')
                                  : '${slot.availableCapacity} / ${slot.capacity} ${l10n?.slotsRemaining ?? 'slots available'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: slot.isFull ? Colors.red : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: ADDRESS & CONTACT
  // ---------------------------------------------------------------------------
  Widget _buildAddressStep(AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF0D6548), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _fulfilment == 'pickup'
                          ? (l10n?.farmPickupLocation ?? 'Farm Pickup Location')
                          : (l10n?.deliveryAddressHeader ?? 'Delivery Address'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_fulfilment == 'pickup')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.store, color: Color(0xFF0D6548), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n?.farmPickupNotice ??
                                'Pick up directly at the farm packhouse. Bring your order confirmation code.',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF0D6548)),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n?.fullAddressLabel ?? 'Street Address / Door No.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00875A), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: l10n?.deliveryNotesLabel ?? 'Delivery instructions (Optional)',
                      hintText: 'e.g. Leave at gate, call when arriving',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n?.contactPhoneLabel ?? 'Contact Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: PAYMENT SELECTION WITH PROTECTION
  // ---------------------------------------------------------------------------
  Widget _buildPaymentStep(CartState cartState, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Unobtrusive payment notice
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Simulated payment checkout with instant verification.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Escrow Protection Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFA7F3D0)),
          ),
          color: const Color(0xFFF0FDF4),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.security, color: Color(0xFF00875A), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.escrowProtectionTitle ?? '100% Escrow Protection Guarantee',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6548),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.escrowProtectionSubtitle ??
                            'Payment is held safely until you receive and verify produce quality.',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF065F46)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isProtected,
                  activeTrackColor: const Color(0xFF00875A),
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _isProtected = val),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Payment Method Options
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.paymentMethodHeader ?? 'Select Payment Method',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPaymentRadioTile('upi', 'UPI (Google Pay / PhonePe / BHIM)', Icons.qr_code),
                _buildPaymentRadioTile('wallet', 'UdyogaSethu Wallet', Icons.account_balance_wallet),
                _buildPaymentRadioTile('card', 'Credit / Debit Card', Icons.credit_card),
                _buildPaymentRadioTile('cod', 'Cash on Delivery (COD)', Icons.payments_outlined),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Order Total Review Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n?.itemsTotal ?? 'Items Total', style: const TextStyle(color: Color(0xFF64748B))),
                    Text(cartState.formattedSubtotal, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (cartState.discountPaise > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n?.rewardDiscount ?? 'Reward Discount', style: const TextStyle(color: Color(0xFF00875A))),
                      Text('-${cartState.formattedDiscount}', style: const TextStyle(color: Color(0xFF00875A), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n?.escrowFeeLabel ?? 'Escrow Protection Fee', style: const TextStyle(color: Color(0xFF64748B))),
                    Text(_isProtected ? '₹5.00' : '₹0.00', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.totalPayable ?? 'Total Payable',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      cartState.formattedTotal,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D6548)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRadioTile(String value, String title, IconData icon) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00875A) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF00875A) : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 20, color: const Color(0xFF0D6548)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomAction(CartState cartState, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n?.backButton ?? 'Back'),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _handleNextOrSubmit(cartState, l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6548),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep < 2
                                ? (l10n?.nextStep ?? 'Continue')
                                : '${l10n?.confirmOrder ?? 'Place Order'} • ${cartState.formattedTotal}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _currentStep < 2 ? Icons.arrow_forward : Icons.check_circle_outline,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNextOrSubmit(CartState cartState, AppLocalizations? l10n) async {
    setState(() => _errorMessage = null);

    if (_currentStep == 0) {
      // Validate slot chosen for each farmer
      for (final group in cartState.farmerGroups) {
        if (!_selectedSlots.containsKey(group.farmerId)) {
          setState(() {
            _errorMessage = 'Please select a delivery slot for ${group.farmerName}.';
          });
          return;
        }
      }
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      if (_fulfilment == 'delivery' && _addressController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your delivery street address.';
        });
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    // Step 2: Place Order through atomic SQL function
    setState(() => _isSubmitting = true);
    try {
      final itemsPayload = cartState.items.values.map((item) {
        return {
          'listing_id': item.listingId,
          'quantity': item.quantity,
        };
      }).toList();

      final ordersRepo = ref.read(ordersRepositoryProvider);
      final createdOrders = await ordersRepo.placeOrder(
        items: itemsPayload,
        fulfilment: _fulfilment,
        addressText: _fulfilment == 'delivery' ? _addressController.text.trim() : 'Farm Pickup',
        slots: _selectedSlots,
        isProtected: _isProtected,
        applyRewardCredits: cartState.useRewardCredits,
        paymentMethod: _paymentMethod,
        deliveryNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Clear Cart on successful order
      ref.read(cartNotifierProvider.notifier).clear();

      if (!mounted) return;

      final firstOrder = createdOrders.first;
      context.go(
        AppRoutes.orderConfirmationWithId(firstOrder.orderId),
        extra: createdOrders,
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}
