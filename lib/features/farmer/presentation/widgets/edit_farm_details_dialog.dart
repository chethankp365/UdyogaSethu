import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static Future<bool?> show(BuildContext context, FarmerProfileData profile) {
    return showDialog<bool>(
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
  late final TextEditingController _cropsCtrl;
  late final TextEditingController _apmcCtrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _farmNameCtrl = TextEditingController(text: widget.profile.farmName);
    _clusterCtrl = TextEditingController(text: widget.profile.clusterVillage);
    _acresCtrl = TextEditingController(
      text: widget.profile.landAcres > 0 ? widget.profile.landAcres.toString() : '',
    );
    _soilCtrl = TextEditingController(text: widget.profile.badges.soilClassification);
    _cropsCtrl = TextEditingController(text: widget.profile.badges.primaryCrops);
    _apmcCtrl = TextEditingController(text: widget.profile.badges.apmcRegistration);
  }

  @override
  void dispose() {
    _farmNameCtrl.dispose();
    _clusterCtrl.dispose();
    _acresCtrl.dispose();
    _soilCtrl.dispose();
    _cropsCtrl.dispose();
    _apmcCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context);
    final acresVal = double.tryParse(_acresCtrl.text.trim()) ?? 0.0;

    try {
      await ref.read(farmerProfilePageRepositoryProvider).updateFarmDetails(
            farmName: _farmNameCtrl.text.trim(),
            clusterVillage: _clusterCtrl.text.trim(),
            acres: acresVal,
            soilType: _soilCtrl.text.trim(),
            primaryCrops: _cropsCtrl.text.trim(),
            apmcMandi: _apmcCtrl.text.trim().isNotEmpty ? _apmcCtrl.text.trim() : null,
          );

      ref.invalidate(farmerProfileDataProvider);
      ref.invalidate(farmerHomeProfileProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.farmDetailsUpdatedSuccess ?? 'Farm details updated successfully',
            ),
            backgroundColor: AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update farm details: $e'),
            backgroundColor: AppColors.errorRed,
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                            Text(
                              l10n?.editFarmDetailsSubtitle ??
                                  'Update land area, soil, and crop specializations',
                              style: const TextStyle(
                                fontSize: 12,
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
                  const SizedBox(height: 18),

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

                  // Cluster / Village
                  TextFormField(
                    key: const Key('farm_cluster_input'),
                    controller: _clusterCtrl,
                    decoration: InputDecoration(
                      labelText: l10n?.clusterVillageLabel ?? 'Cluster / Village Location',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.location_on_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Cluster / Village is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Land Area (Acres)
                  TextFormField(
                    key: const Key('farm_acres_input'),
                    controller: _acresCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n?.acresLabel ?? 'Total Land (Acres)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.square_foot_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Land area is required';
                      }
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid positive number of acres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Soil Classification
                  TextFormField(
                    key: const Key('farm_soil_input'),
                    controller: _soilCtrl,
                    decoration: InputDecoration(
                      labelText: l10n?.soilTypeLabel ?? 'Soil Classification',
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
                      hintText: 'e.g. Tomatoes, Paddy, Banana',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Primary crops cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // APMC Mandi
                  TextFormField(
                    key: const Key('farm_apmc_input'),
                    controller: _apmcCtrl,
                    decoration: InputDecoration(
                      labelText: l10n?.apmcMandiLabel ?? 'Registered APMC Mandi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.storefront_rounded),
                    ),
                  ),
                  const SizedBox(height: 22),

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
      ),
    );
  }
}
