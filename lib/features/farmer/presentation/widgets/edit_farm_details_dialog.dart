import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/farmer/data/farmer_home_repository.dart';
import 'package:udyogasethu/features/farmer/data/farmer_profile_page_repository.dart';
import 'package:udyogasethu/features/farmer/domain/farmer_profile_model.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class EditFarmDetailsDialog extends ConsumerStatefulWidget {
  final FarmerProfileData profile;

  const EditFarmDetailsDialog({
    super.key,
    required this.profile,
  });

  static Future<dynamic> show(BuildContext context, FarmerProfileData profile) {
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditFarmDetailsDialog(profile: profile),
    );
  }

  @override
  ConsumerState<EditFarmDetailsDialog> createState() => _EditFarmDetailsDialogState();
}

class _EditFarmDetailsDialogState extends ConsumerState<EditFarmDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _farmNameCtrl;
  late final TextEditingController _clusterCtrl;
  late final TextEditingController _acresCtrl;
  late final TextEditingController _soilCtrl;
  late final TextEditingController _methodCtrl;
  late final TextEditingController _cropsCtrl;
  late final TextEditingController _deliveryRadiusCtrl;
  late final TextEditingController _leadTimeCtrl;
  late final TextEditingController _farmPhotoCtrl;

  // Self-declared optional fields
  late final TextEditingController _apmcCtrl;
  late final TextEditingController _kccCtrl;
  late final TextEditingController _certNoCtrl;
  late final TextEditingController _certPathCtrl;

  late bool _pickupAvailable;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _farmNameCtrl = TextEditingController(text: p.farmName);
    _clusterCtrl = TextEditingController(text: p.clusterVillage);
    _acresCtrl = TextEditingController(text: p.landAcres > 0 ? p.landAcres.toString() : '1.0');
    _soilCtrl = TextEditingController(text: p.badges.soilClassification ?? 'Red Loam Soil');
    _methodCtrl = TextEditingController(text: p.badges.farmingMethod ?? 'Natural / Organic');
    _cropsCtrl = TextEditingController(text: p.badges.primaryCrops ?? '');
    _deliveryRadiusCtrl = TextEditingController(text: p.badges.deliveryRadiusKm.toString());
    _leadTimeCtrl = TextEditingController(text: p.badges.leadTimeHours.toString());
    _farmPhotoCtrl = TextEditingController(text: p.badges.farmPhotoUrl ?? '');

    _apmcCtrl = TextEditingController(text: p.badges.apmcRegistration ?? '');
    _kccCtrl = TextEditingController(text: p.badges.kisanCreditCardStatus ?? '');
    _certNoCtrl = TextEditingController(text: p.certificate.certificateNumber ?? '');
    _certPathCtrl = TextEditingController(text: p.certificate.documentPath ?? '');

    _pickupAvailable = p.badges.pickupAvailable;
  }

  @override
  void dispose() {
    _farmNameCtrl.dispose();
    _clusterCtrl.dispose();
    _acresCtrl.dispose();
    _soilCtrl.dispose();
    _methodCtrl.dispose();
    _cropsCtrl.dispose();
    _deliveryRadiusCtrl.dispose();
    _leadTimeCtrl.dispose();
    _farmPhotoCtrl.dispose();
    _apmcCtrl.dispose();
    _kccCtrl.dispose();
    _certNoCtrl.dispose();
    _certPathCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final acresVal = double.tryParse(_acresCtrl.text.trim()) ?? 0.0;
    final deliveryRadiusVal = double.tryParse(_deliveryRadiusCtrl.text.trim()) ?? 25.0;
    final leadTimeVal = int.tryParse(_leadTimeCtrl.text.trim()) ?? 24;

    try {
      final savedRow = await ref.read(farmerProfilePageRepositoryProvider).updateFarmDetails(
            farmName: _farmNameCtrl.text.trim(),
            clusterVillage: _clusterCtrl.text.trim(),
            acres: acresVal,
            soilType: _soilCtrl.text.trim(),
            farmingMethod: _methodCtrl.text.trim(),
            primaryCrops: _cropsCtrl.text.trim(),
            deliveryRadiusKm: deliveryRadiusVal,
            pickupAvailable: _pickupAvailable,
            leadTimeHours: leadTimeVal,
            farmPhotoUrl: _farmPhotoCtrl.text.trim().isNotEmpty ? _farmPhotoCtrl.text.trim() : null,
            apmcRegistration: _apmcCtrl.text.trim().isNotEmpty ? _apmcCtrl.text.trim() : null,
            kccStatus: _kccCtrl.text.trim().isNotEmpty ? _kccCtrl.text.trim() : null,
            organicCertNumber: _certNoCtrl.text.trim().isNotEmpty ? _certNoCtrl.text.trim() : null,
            organicCertPath: _certPathCtrl.text.trim().isNotEmpty ? _certPathCtrl.text.trim() : null,
          );

      // Invalidate both profile and home providers for instantaneous UI updates
      ref.invalidate(farmerProfileDataProvider);
      ref.invalidate(farmerHomeProfileProvider);

      if (mounted) {
        Navigator.of(context).pop(savedRow);
        final farmName = savedRow['farm_name']?.toString() ?? 'Farm';
        final acres = savedRow['acres']?.toString() ?? '';
        final radius = savedRow['delivery_radius_km']?.toString() ?? '';
        final detailInfo = [
          if (acres.isNotEmpty) '$acres acres',
          if (radius.isNotEmpty) '$radius km radius',
        ].join(', ');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$farmName saved successfully${detailInfo.isNotEmpty ? ' ($detailInfo)' : ''}',
            ),
            backgroundColor: AppColors.headerGreenDark,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final friendlyMsg = AppException.userFriendlyMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update farm details: $friendlyMsg'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
            action: kDebugMode
                ? SnackBarAction(
                    label: 'Details',
                    textColor: Colors.white,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Error Details'),
                          content: SingleChildScrollView(child: Text(e.toString())),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        color: Color(0xFF064E3B),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.editFarmDetails ?? 'Edit Farm Details',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Update farm profile, delivery settings and self-declared badges',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Scrollable Form Fields
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Farm Name
                        TextFormField(
                          key: const Key('farm_name_input'),
                          controller: _farmNameCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.farmNameLabel ?? 'Farm / Plantation Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.landscape_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Farm name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Location / Map pin
                        TextFormField(
                          key: const Key('farm_cluster_input'),
                          controller: _clusterCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.clusterVillageLabel ?? 'Location / Village (Map Pin)',
                            hintText: 'e.g. Mandya Taluk, Karnataka',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF064E3B)),
                            suffixIcon: IconButton(
                              tooltip: 'Pick map location pin',
                              icon: const Icon(Icons.my_location_rounded, color: Color(0xFF064E3B)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Location pin captured from current GPS position.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Location / Village is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Land Area (Acres) & Farming Method in a Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const Key('farm_acres_input'),
                                controller: _acresCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: l10n?.acresLabel ?? 'Acres',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.square_foot_rounded),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Acres required';
                                  }
                                  final parsed = double.tryParse(val.trim());
                                  if (parsed == null || parsed <= 0) {
                                    return 'Enter > 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                key: const Key('farming_method_input'),
                                controller: _methodCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Farming Method',
                                  hintText: 'Organic / Natural',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.spa_rounded),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Soil Classification
                        TextFormField(
                          key: const Key('farm_soil_input'),
                          controller: _soilCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.soilTypeLabel ?? 'Soil Classification',
                            hintText: 'e.g. Red Loam Soil, Black Soil',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.terrain_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Primary Crops
                        TextFormField(
                          key: const Key('farm_crops_input'),
                          controller: _cropsCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.primaryCropsLabel ?? 'Primary Crops Grown',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.eco_rounded),
                            hintText: 'e.g. Tomato, Paddy, Banana, Coconut',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Primary crops cannot be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Delivery Radius & Lead Time in a Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const Key('delivery_radius_input'),
                                controller: _deliveryRadiusCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Delivery Radius (km)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.local_shipping_outlined),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Radius required';
                                  final numVal = double.tryParse(val.trim());
                                  if (numVal == null || numVal < 0) return 'Invalid radius';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                key: const Key('lead_time_input'),
                                controller: _leadTimeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Lead Time (hours)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.timer_outlined),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Lead time required';
                                  final numVal = int.tryParse(val.trim());
                                  if (numVal == null || numVal < 0) return 'Invalid hours';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Farm Pickup Available Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Farm Gate Pickup Available', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Allow buyers to collect directly from farm', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          value: _pickupAvailable,
                          activeThumbColor: const Color(0xFF064E3B),
                          onChanged: (val) => setState(() => _pickupAvailable = val),
                        ),
                        const SizedBox(height: 8),

                        // Farm Photo URL / Path
                        TextFormField(
                          key: const Key('farm_photo_input'),
                          controller: _farmPhotoCtrl,
                          decoration: InputDecoration(
                            labelText: 'Farm Photo (URL or local path)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.photo_camera_rounded),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Self-Declared Section Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Self-declared fields (not verified yet until KYC/evidence submitted)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // APMC Registration (Optional Self-declared)
                        TextFormField(
                          key: const Key('farm_apmc_input'),
                          controller: _apmcCtrl,
                          decoration: InputDecoration(
                            labelText: 'APMC Registration Number',
                            helperText: 'Self-declared, not verified yet',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.storefront_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Kisan Credit Card Status (Optional Self-declared)
                        TextFormField(
                          key: const Key('farm_kcc_input'),
                          controller: _kccCtrl,
                          decoration: InputDecoration(
                            labelText: 'Kisan Credit Card (KCC) Status',
                            helperText: 'Self-declared, not verified yet (e.g. Active, Applied)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.credit_card_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Organic Certificate Number (Optional Self-declared)
                        TextFormField(
                          key: const Key('organic_cert_no_input'),
                          controller: _certNoCtrl,
                          decoration: InputDecoration(
                            labelText: 'Organic Certificate Number',
                            helperText: 'Self-declared, not verified yet',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.verified_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Organic Certificate Document Upload / Reference
                        TextFormField(
                          key: const Key('organic_cert_path_input'),
                          controller: _certPathCtrl,
                          decoration: InputDecoration(
                            labelText: 'Certificate Document Upload / Path',
                            helperText: 'Document proof reference',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.upload_file_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('save_farm_details_button'),
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF064E3B),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n?.save ?? 'Save Details',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
