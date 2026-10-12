import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/features/farmer/data/farmer_listings_repository.dart';
import 'package:udyogasethu/features/farmer/domain/price_suggestion_model.dart';
import 'package:udyogasethu/features/farmer/domain/produce_listing_model.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class EditListingModal extends ConsumerStatefulWidget {
  final ProduceListing? listing;
  final String farmerId;

  const EditListingModal({
    super.key,
    this.listing,
    required this.farmerId,
  });

  static Future<bool?> show(
    BuildContext context, {
    ProduceListing? listing,
    required String farmerId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditListingModal(
        listing: listing,
        farmerId: farmerId,
      ),
    );
  }

  @override
  ConsumerState<EditListingModal> createState() => _EditListingModalState();
}

class _EditListingModalState extends ConsumerState<EditListingModal> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockThresholdController;
  late TextEditingController _qualityNotesController;
  late TextEditingController _descriptionController;

  String _selectedCategory = 'vegetable';
  String _selectedUnit = 'kg';
  String _farmingMethod = 'Organic';
  AvailabilityMode _availabilityMode = AvailabilityMode.sameDay;
  bool _deliveryAvailable = true;
  bool _pickupAvailable = true;
  DateTime _harvestDate = DateTime.now();

  PriceSuggestion? _priceSuggestion;
  bool _isLoadingSuggestion = false;
  bool _isSaving = false;
  final List<Uint8List> _selectedImageBytes = [];
  final List<String> _existingImages = [];

  final List<String> _categories = [
    'vegetable',
    'fruit',
    'grain',
    'pulse',
    'spices',
    'dairy',
  ];

  final List<String> _units = [
    'kg',
    'quintal',
    'bunch',
    'piece',
    'box',
  ];

  final List<String> _farmingMethods = [
    'Organic',
    'Natural Farming',
    'Conventional',
    'Hydroponic',
  ];

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _nameController = TextEditingController(text: l?.name ?? '');
    _priceController = TextEditingController(
      text: l != null ? l.priceRupees.toStringAsFixed(0) : '28',
    );
    _stockController = TextEditingController(
      text: l != null ? l.stockQty.toStringAsFixed(0) : '100',
    );
    _lowStockThresholdController = TextEditingController(
      text: l != null ? l.lowStockThreshold.toStringAsFixed(0) : '10',
    );
    _qualityNotesController = TextEditingController(text: l?.qualityNotes ?? '');
    _descriptionController = TextEditingController(text: l?.description ?? '');

    if (l != null) {
      _selectedCategory = l.category;
      _selectedUnit = l.unit;
      _farmingMethod = l.farmingMethod;
      _availabilityMode = l.availabilityMode;
      _deliveryAvailable = l.deliveryAvailable;
      _pickupAvailable = l.pickupAvailable;
      _harvestDate = l.harvestAt ?? DateTime.now();
      _existingImages.addAll(l.images);
    }

    _fetchPriceSuggestion(_nameController.text.isNotEmpty ? _nameController.text : 'Tomato');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _lowStockThresholdController.dispose();
    _qualityNotesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 80,
      );
      if (picked != null) {
        final raw = await picked.readAsBytes();
        final compressed = await _compressImage(raw);
        if (mounted) {
          setState(() => _selectedImageBytes.add(compressed));
        }
      }
    } catch (e) {
      debugPrint('Error picking produce photo: $e');
    }
  }

  Future<Uint8List> _compressImage(Uint8List rawBytes) async {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      img.Image resized = decoded;
      if (decoded.width > 800 || decoded.height > 800) {
        resized = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 800 : null,
          height: decoded.height > decoded.width ? 800 : null,
        );
      }
      return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
    } catch (_) {
      return rawBytes;
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF047857)),
              title: Text(AppLocalizations.of(ctx)?.takePhotoCamera ?? 'Take Photo with Camera'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF047857)),
              title: Text(AppLocalizations.of(ctx)?.chooseGallery ?? 'Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchPriceSuggestion(String name) async {
    if (name.trim().isEmpty) return;
    setState(() => _isLoadingSuggestion = true);
    try {
      final repo = ref.read(farmerListingsRepositoryProvider);
      final suggestion = await repo.getPriceSuggestion(
        commodity: name.trim(),
        unit: _selectedUnit,
      );
      if (mounted) {
        setState(() {
          _priceSuggestion = suggestion;
          _isLoadingSuggestion = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSuggestion = false);
    }
  }

  Future<void> _pickHarvestDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF047857),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _harvestDate = picked);
    }
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(farmerListingsRepositoryProvider);
      final priceRupees = double.tryParse(_priceController.text.trim()) ?? 25.0;
      final pricePaise = (priceRupees * 100).round();
      final stockQty = double.tryParse(_stockController.text.trim()) ?? 0.0;
      final lowStockThreshold =
          double.tryParse(_lowStockThresholdController.text.trim()) ?? 10.0;

      if (widget.listing == null) {
        // Create
        await repo.createListing(
          farmerId: widget.farmerId,
          name: _nameController.text.trim(),
          category: _selectedCategory,
          description: _descriptionController.text.trim(),
          pricePaise: pricePaise,
          unit: _selectedUnit,
          stockQty: stockQty,
          lowStockThreshold: lowStockThreshold,
          harvestAt: _harvestDate,
          qualityNotes: _qualityNotesController.text.trim(),
          farmingMethod: _farmingMethod,
          deliveryAvailable: _deliveryAvailable,
          pickupAvailable: _pickupAvailable,
          availabilityMode: _availabilityMode,
          imageBytesList: _selectedImageBytes.isNotEmpty ? _selectedImageBytes : null,
        );
      } else {
        // Update
        final updated = widget.listing!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          description: _descriptionController.text.trim(),
          pricePaise: pricePaise,
          unit: _selectedUnit,
          stockQty: stockQty,
          lowStockThreshold: lowStockThreshold,
          harvestAt: _harvestDate,
          qualityNotes: _qualityNotesController.text.trim(),
          farmingMethod: _farmingMethod,
          images: _existingImages,
          deliveryAvailable: _deliveryAvailable,
          pickupAvailable: _pickupAvailable,
          availabilityMode: _availabilityMode,
        );
        await repo.updateListing(
          updated,
          newImageBytesList: _selectedImageBytes.isNotEmpty ? _selectedImageBytes : null,
        );
      }

      ref.invalidate(farmerListingsProvider);
      ref.invalidate(buyerProduceListingsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save listing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.listing != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Top Pill Handle & Title
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing
                      ? (l10n?.editProduceListing ?? 'Edit Produce Listing')
                      : (l10n?.addNewProduce ?? 'Add New Produce'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const Divider(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 0. PRODUCE PHOTOS
                    _buildPhotoPickerSection(l10n),

                    const SizedBox(height: 14),

                    // 1. PRODUCT NAME
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n?.produceName ?? 'Produce Name *',
                        hintText: 'e.g. Organic Hybrid Tomatoes',
                        prefixIcon: const Icon(Icons.grass_rounded, color: Color(0xFF047857)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? (l10n?.requiredField ?? 'Required field')
                          : null,
                      onFieldSubmitted: (val) => _fetchPriceSuggestion(val),
                    ),

                    const SizedBox(height: 12),

                    // MANDI SUGGESTED PRICE BAND CARD
                    _buildPriceSuggestionCard(l10n),

                    const SizedBox(height: 14),

                    // 2. CATEGORY & UNIT ROW
                    Row(
                      children: [
                        // Category Dropdown
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: l10n?.category ?? 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _categories.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c[0].toUpperCase() + c.substring(1)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Unit Dropdown
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedUnit,
                            decoration: InputDecoration(
                              labelText: l10n?.unit ?? 'Unit',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _units.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(u),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 3. PRICE PER UNIT & STOCK QUANTITY ROW
                    Row(
                      children: [
                        // Price Field
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${l10n?.pricePerUnit(_selectedUnit) ?? 'Price (₹/$_selectedUnit)'} *',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return l10n?.requiredField ?? 'Required';
                              final p = double.tryParse(val);
                              if (p == null || p <= 0) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Stock Field
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${l10n?.stockQuantity ?? 'Stock Qty'} ($_selectedUnit) *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return l10n?.requiredField ?? 'Required';
                              final s = double.tryParse(val);
                              if (s == null || s < 0) return 'Invalid stock';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 4. LOW STOCK THRESHOLD & HARVEST DATE ROW
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _lowStockThresholdController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Low Stock Alert ($_selectedUnit)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _pickHarvestDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n?.harvestDate ?? 'Harvest Date',
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(_harvestDate),
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF047857)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 5. FARMING METHOD & AVAILABILITY MODE
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _farmingMethod,
                            decoration: InputDecoration(
                              labelText: l10n?.farmingMethod ?? 'Farming Method',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _farmingMethods.map((m) {
                              return DropdownMenuItem(value: m, child: Text(m));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _farmingMethod = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<AvailabilityMode>(
                            initialValue: _availabilityMode,
                            decoration: InputDecoration(
                              labelText: l10n?.availabilityMode ?? 'Availability Mode',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: AvailabilityMode.values.map((mode) {
                              return DropdownMenuItem(
                                value: mode,
                                child: Text(
                                  mode == AvailabilityMode.sameDay
                                      ? (l10n?.sameDayDelivery ?? 'Same Day')
                                      : mode == AvailabilityMode.nextDay
                                          ? (l10n?.nextDayDelivery ?? 'Next Day')
                                          : (l10n?.harvestPreOrder ?? 'Pre-Order'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _availabilityMode = val);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 6. DELIVERY & PICKUP SWITCHES
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            title: Text(
                              l10n?.deliveryAvailable ?? 'Delivery Available to Buyer',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('Farmer can arrange cluster dispatch', style: TextStyle(fontSize: 11)),
                            value: _deliveryAvailable,
                            activeThumbColor: const Color(0xFF047857),
                            dense: true,
                            onChanged: (val) => setState(() => _deliveryAvailable = val),
                          ),
                          const Divider(height: 8),
                          SwitchListTile.adaptive(
                            title: Text(
                              l10n?.pickupAvailable ?? 'Farm Gate Pickup Allowed',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('Buyer collects directly at farm gate', style: TextStyle(fontSize: 11)),
                            value: _pickupAvailable,
                            activeThumbColor: const Color(0xFF047857),
                            dense: true,
                            onChanged: (val) => setState(() => _pickupAvailable = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 7. QUALITY NOTES & DESCRIPTION
                    TextFormField(
                      controller: _qualityNotesController,
                      decoration: InputDecoration(
                        labelText: l10n?.qualityNotes ?? 'Quality Notes',
                        hintText: 'e.g. Naturally ripened, Grade-A medium size, crisp texture',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Detailed crop batch information for buyers',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // SAVE BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF064E3B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSaving ? null : _saveListing,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isEditing
                          ? (l10n?.save ?? 'Save Changes')
                          : (l10n?.addNewProduce ?? 'Post Produce Listing'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSuggestionCard(AppLocalizations? l10n) {
    if (_isLoadingSuggestion) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF047857))),
            SizedBox(width: 10),
            Text('Fetching Mandi pricing band...', style: TextStyle(fontSize: 12, color: Color(0xFF047857))),
          ],
        ),
      );
    }

    final sug = _priceSuggestion;
    if (sug == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFF047857), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'APMC Mandi Price Band: ${sug.formattedBand}/$_selectedUnit',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF064E3B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.farmerSetsFinalPrice ?? 'The farmer always sets the final price. Mandi modal: ₹${sug.mandiModalPriceRupees.toStringAsFixed(0)}/$_selectedUnit.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              setState(() {
                _priceController.text = sug.mandiModalPriceRupees.round().toString();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF047857),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Apply Mandi Modal Price (₹${sug.mandiModalPriceRupees.round()}/$_selectedUnit)',
                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPickerSection(AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.uploadProducePhotos ?? 'Produce Photos (produce-images)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const Text(
              'Compressed JPEG',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF047857),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              InkWell(
                onTap: _showImageSourceDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF047857), width: 1.2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_rounded, color: Color(0xFF047857), size: 22),
                      const SizedBox(height: 4),
                      Text(
                        l10n?.addPhoto ?? 'Add Photo',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Existing photos
              ..._existingImages.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 76,
                            height: 76,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_rounded, size: 24),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () => setState(() => _existingImages.removeAt(idx)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Newly selected compressed photos
              ..._selectedImageBytes.asMap().entries.map((entry) {
                final idx = entry.key;
                final bytes = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          bytes,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () => setState(() => _selectedImageBytes.removeAt(idx)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
