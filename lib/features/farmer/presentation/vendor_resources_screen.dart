import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/features/farmer/data/farm_resources_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farm_resource_model.dart';
import 'package:udyogasethu/features/farmer/domain/resource_booking_model.dart';
import 'package:udyogasethu/core/widgets/app_thumbnail.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class VendorResourcesScreen extends ConsumerStatefulWidget {
  const VendorResourcesScreen({super.key});

  @override
  ConsumerState<VendorResourcesScreen> createState() =>
      _VendorResourcesScreenState();
}

class _VendorResourcesScreenState extends ConsumerState<VendorResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FarmResource> _vendorResources = [];
  List<ResourceBooking> _incomingBookings = [];
  List<ResourceBooking> _myFarmerBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(farmResourcesRepositoryProvider);
    final user = Supabase.instance.isInitialized
        ? Supabase.instance.client.auth.currentUser
        : null;
    final uid = user?.id ?? 'demo-user-id';

    try {
      final resources = await repo.getVendorResources(uid);
      final inBookings = await repo.getVendorBookings(uid);
      final myBookings = await repo.getFarmerBookings(uid);

      if (mounted) {
        setState(() {
          _vendorResources = resources;
          _incomingBookings = inBookings;
          _myFarmerBookings = myBookings;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBookingStatus(
    ResourceBooking booking,
    ResourceBookingStatus newStatus,
  ) async {
    final repo = ref.read(farmResourcesRepositoryProvider);
    await repo.updateBookingStatus(booking.id, newStatus);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to ${newStatus.label}'),
          backgroundColor: newStatus.color,
        ),
      );
    }
  }

  void _showAddEditResourceDialog([FarmResource? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? (existing.pricePaise / 100).toString() : '',
    );
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'hr');
    final specsCtrl = TextEditingController(text: existing?.specs ?? '');
    final addressCtrl = TextEditingController(
      text: existing?.addressText ?? 'Mandya Farm Machinery Yard',
    );
    FarmResourceType selectedType = existing?.type ?? FarmResourceType.tractor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            existing == null ? 'Add Farm Machinery / Service' : 'Edit Listing',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FarmResourceType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Resource Type'),
                  items: FarmResourceType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(t.icon, color: t.badgeColor, size: 20),
                          const SizedBox(width: 8),
                          Text(t.name.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Equipment / Product Name',
                    hintText: 'e.g. Sonalika DI 60 Tractor + Rotavator',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Rate (₹)',
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'hr / acre / bag',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Key Specifications',
                    hintText: 'e.g. 60 HP • Fuel Included',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Depot / Farm Location',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                final res = FarmResource(
                  id: existing?.id ?? '',
                  ownerId: existing?.ownerId ?? 'current-user-id',
                  type: selectedType,
                  name: nameCtrl.text.trim(),
                  pricePaise: (price * 100).toInt(),
                  unit: unitCtrl.text.trim(),
                  specs: specsCtrl.text.trim(),
                  addressText: addressCtrl.text.trim(),
                  active: true,
                );

                final repo = ref.read(farmResourcesRepositoryProvider);
                await repo.createOrUpdateResource(res);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6548),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n?.farmerVendorHubTitle ?? 'Equipment & Machinery Vendor Hub',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'My Listings'),
            Tab(text: 'Incoming Bookings'),
            Tab(text: 'My Farm Rentals'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D6548),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n?.farmerAddEquipment ?? 'Add Equipment'),
        onPressed: () => _showAddEditResourceDialog(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.headerGreenDark),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyListingsTab(l10n),
                _buildIncomingBookingsTab(l10n),
                _buildMyRentalsTab(l10n),
              ],
            ),
    );
  }

  Widget _buildMyListingsTab(AppLocalizations? l10n) {
    if (_vendorResources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.agriculture_rounded, size: 54, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No Equipment Listings Yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'List your tractor, harvester, drone or cold storage to earn rental income.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showAddEditResourceDialog(),
              child: const Text('Add Your First Equipment'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.fabListPadding,
      itemCount: _vendorResources.length,
      itemBuilder: (context, idx) {
        final res = _vendorResources[idx];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ResourceThumbnail(
                title: res.name,
                resourceType: res.type.name,
                imageUrl: res.imageUrl,
                size: ThumbnailSize.small,
                width: 52,
                height: 52,
                borderRadius: BorderRadius.circular(12),
                showTitle: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      res.specs.isNotEmpty ? res.specs : res.addressText,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      res.pricePerUnitDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0D6548),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _showAddEditResourceDialog(res),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomingBookingsTab(AppLocalizations? l10n) {
    if (_incomingBookings.isEmpty) {
      return const Center(
        child: Text(
          'No incoming rental bookings yet.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.fabListPadding,
      itemCount: _incomingBookings.length,
      itemBuilder: (context, idx) {
        final bkg = _incomingBookings[idx];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bkg.resourceName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bkg.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bkg.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: bkg.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Duration: ${bkg.quantity.toInt()} ${bkg.unit} • Total: ${bkg.formattedTotal}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              if (bkg.deliveryAddress.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'Site: ${bkg.deliveryAddress}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (bkg.status == ResourceBookingStatus.requested ||
                      bkg.status == ResourceBookingStatus.confirmed) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D6548),
                        side: const BordersSide(),
                      ),
                      onPressed: () =>
                          _updateBookingStatus(bkg, ResourceBookingStatus.inProgress),
                      child: const Text('Start Work / Dispatch'),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                      onPressed: () =>
                          _updateBookingStatus(bkg, ResourceBookingStatus.cancelled),
                      child: const Text('Decline'),
                    ),
                  ],
                  if (bkg.status == ResourceBookingStatus.inProgress) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6548),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          _updateBookingStatus(bkg, ResourceBookingStatus.completed),
                      child: const Text('Mark Completed'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyRentalsTab(AppLocalizations? l10n) {
    if (_myFarmerBookings.isEmpty) {
      return const Center(
        child: Text(
          'You have not booked any equipment yet.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.fabListPadding,
      itemCount: _myFarmerBookings.length,
      itemBuilder: (context, idx) {
        final bkg = _myFarmerBookings[idx];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bkg.resourceName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bkg.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bkg.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: bkg.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Total Amount: ${bkg.formattedTotal} • Escrow Protected',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D6548),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Receipt: ${bkg.receiptNo ?? 'RCP-CONFIRMED'}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BordersSide extends BorderSide {
  const BordersSide() : super(color: const Color(0xFF0D6548));
}
