import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/features/marketplace/data/orders_repository.dart';
import 'package:udyogasethu/features/marketplace/data/produce_marketplace_repository.dart';
import 'package:udyogasethu/features/marketplace/domain/lot_traceability_data.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_marketplace_item.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/farm_traceability_modal.dart';
import 'package:udyogasethu/core/widgets/app_thumbnail.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class ProduceDetailScreen extends ConsumerStatefulWidget {
  final ProduceMarketplaceItem? item;
  final String? listingId;

  const ProduceDetailScreen({
    super.key,
    this.item,
    this.listingId,
  });

  @override
  ConsumerState<ProduceDetailScreen> createState() => _ProduceDetailScreenState();
}

class _ProduceDetailScreenState extends ConsumerState<ProduceDetailScreen> {
  late ProduceMarketplaceItem _item;
  double _selectedQty = 1.0;
  String? _generatedLotToken;

  ProduceMarketplaceItem get item => _item;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _item = widget.item!;
    } else {
      final repo = ref.read(produceMarketplaceRepositoryProvider);
      _item = repo.fallbackProduceCatalog.firstWhere(
        (p) => p.id == widget.listingId,
        orElse: () => repo.fallbackProduceCatalog.first,
      );
    }
    _selectedQty = _item.stockQty > 5 ? 5.0 : _item.stockQty;
    if (_selectedQty < 1.0 && _item.stockQty > 0) {
      _selectedQty = _item.stockQty;
    }
    _generatedLotToken = LotTraceabilityData.createSignedLotToken(
      lotNumber: _item.lotNumber,
      listingId: _item.id,
    );
    _loadLotToken();
  }

  Future<void> _loadLotToken() async {
    final repo = ref.read(produceMarketplaceRepositoryProvider);
    final token = await repo.getOrGenerateLotToken(item);
    if (mounted) {
      setState(() => _generatedLotToken = token);
    }
  }

  void _showLotQrDialog(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Debug Mode: Lot QR for Testing',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lot Code: ${item.lotNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                item.name,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: token,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 14),
              const Text(
                'Scan this code with a second phone\'s "Scan QR" scanner to open traceability.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Token String', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lot Token copied to clipboard!')),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTraceabilityModal() {
    final trace = LotTraceabilityData(
      listingId: item.id,
      lotNumber: item.lotNumber,
      cropItem: item.name,
      category: item.category,
      farmerOrigin: '${item.farmName} • ${item.clusterVillage}',
      clusterVillage: item.clusterVillage,
      harvestTime: item.freshnessLabel,
      harvestAt: item.harvestAt,
      farmingMethod: item.farmingMethod,
      organicCertification: item.organicCertified
          ? (item.certificationName.isNotEmpty
              ? item.certificationName
              : 'Pesticide-Free ✓')
          : 'Natural IPNM Verified ✓',
      qualityNotes: item.qualityNotes,
      pricePaise: item.pricePaise,
      unit: item.unit,
      ratingAvg: item.farmerRatingAvg,
      images: item.images,
    );
    FarmTraceabilityModal.show(context, trace);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalAmount = _selectedQty * item.priceRupees;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF0D6548),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_outlined),
            tooltip: 'Traceability',
            onPressed: _openTraceabilityModal,
          ),
          Consumer(
            builder: (ctx, r, _) {
              final cart = r.watch(cartNotifierProvider);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Cart',
                    onPressed: () => context.push(AppRoutes.cart),
                  ),
                  if (cart.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cart.totalQuantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Product Image Banner
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ProduceThumbnail.fromMarketplaceItem(
                            item,
                            size: ThumbnailSize.header,
                            width: double.infinity,
                            height: 200,
                            borderRadius: BorderRadius.circular(20),
                            showTitle: true,
                          ),
                        ),
                        // Lot Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code_2_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  item.lotNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Price Badge
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6548),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.formattedPrice,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Crop Title & Trust Badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.farmingMethod,
                                    style: const TextStyle(
                                      color: Color(0xFF047857),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.freshnessLabel,
                                    style: const TextStyle(
                                      color: Color(0xFFB45309),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Stock indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          item.formattedStock,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // 3. Farmer Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFF00875A),
                          child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.farmerName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.isVerifiedFarmer) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF00875A)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.farmName} • ${item.clusterVillage}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '★ ${item.farmerRatingAvg.toStringAsFixed(1)} (${item.farmerRatingCount})',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                  ),
                                  Text(
                                    '• ${item.formattedDistance}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Quality Notes & Traceability CTA Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF047857), size: 18),
                            const Text(
                              'Verified Quality',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 13),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.qr_code_rounded, size: 16, color: Color(0xFF047857)),
                              label: const Text(
                                'View Traceability',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                              onPressed: _openTraceabilityModal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.qualityNotes,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Quantity Stepper
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Select Quantity (${item.unit}):',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF0D6548)),
                            onPressed: _selectedQty > 1.0
                                ? () => setState(() => _selectedQty -= 1.0)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_selectedQty.toStringAsFixed(0)} ${item.unit}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0D6548)),
                            onPressed: _selectedQty < item.stockQty
                                ? () => setState(() => _selectedQty += 1.0)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 6. Debug Helper for Testing Lot QR (kDebugMode only)
                  if (kDebugMode && _generatedLotToken != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bug_report_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Debug Mode: One-Phone / Two-Phone Testing',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6548),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(36),
                            ),
                            icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                            label: const Text('Show Lot QR Code for Scanning', style: TextStyle(fontSize: 12)),
                            onPressed: () => _showLotQrDialog(context, _generatedLotToken!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Bar: Order Now & Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('Total Estimated:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${totalAmount.round()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D6548),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0D6548)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ref.read(cartNotifierProvider.notifier).addItem(item, quantity: _selectedQty);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${_selectedQty.toInt()} ${item.unit} ${item.name} ${l10n?.addedToCart ?? 'added to cart!'}',
                                ),
                                action: SnackBarAction(
                                  label: l10n?.viewCart ?? 'View Cart',
                                  textColor: Colors.white,
                                  onPressed: () => context.push(AppRoutes.cart),
                                ),
                                duration: const Duration(seconds: 3),
                                backgroundColor: const Color(0xFF0D6548),
                              ),
                            );
                          },
                          child: Text(
                            l10n?.cartTitle ?? 'Add to Cart',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D6548)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6548),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ref.read(cartNotifierProvider.notifier).addItem(item, quantity: _selectedQty);
                            context.push(AppRoutes.orderCheckout);
                          },
                          child: Text(
                            l10n?.orderNow ?? 'Buy Now',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
