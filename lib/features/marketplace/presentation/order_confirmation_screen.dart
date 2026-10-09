import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/produce_order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final List<ProduceOrder>? orders;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orderList = orders ?? [
      ProduceOrder(
        orderId: orderId,
        orderCode: 'ORD-261009-FARM01',
        farmerId: '44444444-4444-4444-8444-444444444401',
        farmerName: 'Cauvery Bio Farm',
        totalPaise: 3400,
        feePaise: 500,
        discountPaise: 170,
        status: 'pending',
        itemsCount: 1,
        fulfilment: 'delivery',
        protected: true,
        createdAt: DateTime.now(),
      )
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n?.orderConfirmedTitle ?? 'Order Confirmed'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Animation / Icon Container
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF00875A),
                size: 50,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              l10n?.orderPlacedSuccessfully ?? 'Order Placed Successfully!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              orderList.length > 1
                  ? '${orderList.length} direct orders dispatched to respective local farmers'
                  : 'Direct notification dispatched to the farmer for packing',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Order Cards (one for each farmer order)
            ...orderList.asMap().entries.map((entry) {
              final index = entry.key;
              final ord = entry.value;
              return _buildOrderCard(context, ord, index + 1, orderList.length, l10n);
            }),

            const SizedBox(height: 12),

            // Escrow Trust Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF00875A), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.escrowProtectedHeader ?? 'Escrow Protected Payment',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6548),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n?.escrowProtectedNotice ??
                              'Your payment remains safely locked in platform escrow until you inspect and verify freshness upon delivery.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Return to marketplace
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go(AppRoutes.providerHome);
                },
                icon: const Icon(Icons.storefront),
                label: Text(l10n?.backToMarketplace ?? 'Back to Produce Marketplace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6548),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    ProduceOrder order,
    int index,
    int totalCount,
    AppLocalizations? l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
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
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    totalCount > 1 ? 'Order $index' : 'Direct Order',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6548),
                    ),
                  ),
                ),
                Text(
                  order.farmerName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n?.pendingFarmerConfirmation ?? 'Pending Farmer Confirmation',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Order Code with copy button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.orderCodeLabel ?? 'Order Code',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        order.orderCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: order.orderCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${l10n?.orderCodeLabel ?? 'Order code'} copied to clipboard!',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20, color: Color(0xFF0D6548)),
                  tooltip: 'Copy Code',
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${order.itemsCount} ${order.itemsCount == 1 ? 'Produce item' : 'Produce items'}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  order.formattedTotal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6548),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
