import 'produce_marketplace_item.dart';
import 'delivery_slot.dart';

class CartItem {
  final ProduceMarketplaceItem produceItem;
  final double quantity;

  const CartItem({
    required this.produceItem,
    required this.quantity,
  });

  String get listingId => produceItem.id;
  String get name => produceItem.name;
  String get unit => produceItem.unit;
  String get farmerId => produceItem.farmerId;
  String get farmerName => produceItem.farmerName;
  int get unitPricePaise => produceItem.pricePaise;
  double get maxStock => produceItem.stockQty;

  int get subtotalPaise => (unitPricePaise * quantity).round();

  String get formattedSubtotal {
    final rupees = subtotalPaise / 100;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toInt()}'
        : '₹${rupees.toStringAsFixed(2)}';
  }

  bool get canIncrease => quantity < maxStock;
  bool get canDecrease => quantity > 1.0;

  CartItem copyWith({
    ProduceMarketplaceItem? produceItem,
    double? quantity,
  }) {
    return CartItem(
      produceItem: produceItem ?? this.produceItem,
      quantity: quantity ?? this.quantity,
    );
  }
}

class FarmerCartGroup {
  final String farmerId;
  final String farmerName;
  final List<CartItem> items;
  final DeliverySlot? selectedSlot;

  const FarmerCartGroup({
    required this.farmerId,
    required this.farmerName,
    required this.items,
    this.selectedSlot,
  });

  int get subtotalPaise =>
      items.fold<int>(0, (sum, item) => sum + item.subtotalPaise);

  String get formattedSubtotal {
    final rupees = subtotalPaise / 100;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toInt()}'
        : '₹${rupees.toStringAsFixed(2)}';
  }

  int get totalItemsCount => items.length;

  FarmerCartGroup copyWith({
    String? farmerId,
    String? farmerName,
    List<CartItem>? items,
    DeliverySlot? selectedSlot,
  }) {
    return FarmerCartGroup(
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      items: items ?? this.items,
      selectedSlot: selectedSlot ?? this.selectedSlot,
    );
  }
}

class CartState {
  final Map<String, CartItem> items; // Key: listingId
  final bool useRewardCredits;
  final Map<String, String> selectedSlotIds; // farmerId -> slotId

  const CartState({
    this.items = const {},
    this.useRewardCredits = false,
    this.selectedSlotIds = const {},
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get totalUniqueItems => items.length;

  int get totalQuantity {
    return items.values.fold<int>(0, (sum, item) => sum + item.quantity.ceil());
  }

  int get subtotalPaise =>
      items.values.fold<int>(0, (sum, item) => sum + item.subtotalPaise);

  int get discountPaise {
    if (!useRewardCredits || subtotalPaise <= 0) return 0;
    // 5% reward discount up to ₹50 (5000 paise)
    final fivePercent = (subtotalPaise * 0.05).round();
    return fivePercent.clamp(0, 5000);
  }

  int get totalPayablePaise => (subtotalPaise - discountPaise).clamp(0, subtotalPaise);

  String get formattedSubtotal => _formatPaise(subtotalPaise);
  String get formattedDiscount => _formatPaise(discountPaise);
  String get formattedTotal => _formatPaise(totalPayablePaise);

  List<FarmerCartGroup> get farmerGroups {
    final Map<String, List<CartItem>> grouped = {};
    final Map<String, String> farmerNames = {};

    for (final item in items.values) {
      grouped.putIfAbsent(item.farmerId, () => []).add(item);
      farmerNames[item.farmerId] = item.farmerName;
    }

    return grouped.entries.map((entry) {
      return FarmerCartGroup(
        farmerId: entry.key,
        farmerName: farmerNames[entry.key] ?? 'Farmer',
        items: entry.value,
      );
    }).toList();
  }

  CartState copyWith({
    Map<String, CartItem>? items,
    bool? useRewardCredits,
    Map<String, String>? selectedSlotIds,
  }) {
    return CartState(
      items: items ?? this.items,
      useRewardCredits: useRewardCredits ?? this.useRewardCredits,
      selectedSlotIds: selectedSlotIds ?? this.selectedSlotIds,
    );
  }

  static String _formatPaise(int paise) {
    final rupees = paise / 100;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toInt()}'
        : '₹${rupees.toStringAsFixed(2)}';
  }
}
