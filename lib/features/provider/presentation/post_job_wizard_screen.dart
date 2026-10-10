import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/provider/domain/job_post_draft.dart';
import 'package:udyogasethu/features/provider/presentation/provider_home_screen.dart';
import 'package:udyogasethu/features/provider/presentation/provider_jobs_controller.dart';
import 'package:udyogasethu/core/services/job_thumbnail_service.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class PostJobWizardScreen extends ConsumerStatefulWidget {
  final String? editJobId;

  const PostJobWizardScreen({
    super.key,
    this.editJobId,
  });

  @override
  ConsumerState<PostJobWizardScreen> createState() => _PostJobWizardScreenState();
}

class _PostJobWizardScreenState extends ConsumerState<PostJobWizardScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _wageController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _searchAddressController = TextEditingController();
  final MapController _mapController = MapController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isPublishing = false;
  bool _isLocating = false;
  bool _isSearchingAddress = false;
  bool _isUploadingPhoto = false;
  static const double _defaultBengaluruLat = 12.9716;
  static const double _defaultBengaluruLng = 77.5946;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initForm());
  }

  void _initForm() {
    final notifier = ref.read(postJobWizardProvider.notifier);
    if (widget.editJobId != null) {
      final jobs = ref.read(providerJobsNotifierProvider).asData?.value ?? [];
      final target = jobs.where((j) => j.id == widget.editJobId).firstOrNull;
      if (target != null) {
        notifier.initForEdit(target);
        _titleController.text = target.title;
        _descController.text = target.description ?? '';
        _wageController.text = (target.wagePaise / 100).round().toString();
        _addressController.text = target.addressText ?? '';
        return;
      }
    }

    // New Job: Pre-fill address from provider profile if available
    final profile = ref.read(providerHomeProfileProvider).asData?.value;
    final defaultAddr = profile != null
        ? (profile.isHousehold ? profile.addressLine1 : profile.siteAddressLine1)
        : '';
    final defaultLat = profile != null
        ? (profile.isHousehold ? profile.latitude : profile.siteLatitude)
        : null;
    final defaultLng = profile != null
        ? (profile.isHousehold ? profile.longitude : profile.siteLongitude)
        : null;

    // Never default coordinates! Only use real profile coordinates if present
    notifier.initForNewJob(
      defaultAddress: defaultAddr,
      lat: defaultLat,
      lng: defaultLng,
    );
    _addressController.text = defaultAddr;
    _landmarkController.text = '';
    _wageController.text = '700';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _wageController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _searchAddressController.dispose();
    super.dispose();
  }

  bool _isInvalidAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.length < 8) return true;
    final houseOnlyRegex = RegExp(r'^(#|no\.?|plot|flat|door|h\.?no\.?)?\s*\d+[\w\s\-/]*$', caseSensitive: false);
    return houseOnlyRegex.hasMatch(trimmed);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services on your device')),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied. Please allow in settings.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      String address = '';
      String landmark = '';
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          landmark = p.name ?? '';
          final parts = <String>[];
          if (p.street != null && p.street!.isNotEmpty && p.street != p.name) parts.add(p.street!);
          if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
          if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
          if (p.postalCode != null && p.postalCode!.isNotEmpty) parts.add(p.postalCode!);
          address = [if (landmark.isNotEmpty) landmark, ...parts].join(', ');
        }
      } catch (_) {}

      if (address.isEmpty) {
        address = 'Coordinates: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _addressController.text = address;
          if (landmark.isNotEmpty) _landmarkController.text = landmark;
        });
        ref.read(postJobWizardProvider.notifier).setLocation(
          address: address,
          landmark: landmark.isNotEmpty ? landmark : _landmarkController.text,
          lat: pos.latitude,
          lng: pos.longitude,
        );
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated from GPS successfully!'), backgroundColor: AppColors.headerGreenDark),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    setState(() => _isSearchingAddress = true);
    try {
      final locations = await Geocoding().locationFromAddress(clean);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        String resolvedAddr = clean;
        String landmark = '';
        try {
          final placemarks = await Geocoding().placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            landmark = p.name ?? '';
            final parts = <String>[];
            if (p.street != null && p.street!.isNotEmpty && p.street != p.name) parts.add(p.street!);
            if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
            if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
            if (p.postalCode != null && p.postalCode!.isNotEmpty) parts.add(p.postalCode!);
            resolvedAddr = [if (landmark.isNotEmpty) landmark, ...parts].join(', ');
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _addressController.text = resolvedAddr;
            if (landmark.isNotEmpty) _landmarkController.text = landmark;
          });
          ref.read(postJobWizardProvider.notifier).setLocation(
            address: resolvedAddr,
            landmark: landmark.isNotEmpty ? landmark : _landmarkController.text,
            lat: loc.latitude,
            lng: loc.longitude,
          );
          _mapController.move(LatLng(loc.latitude, loc.longitude), 15.0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address found and map updated!'), backgroundColor: AppColors.headerGreenDark),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No coordinates found for this address. Please refine search.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geocoding search failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingAddress = false);
    }
  }

  Future<void> _pickAndUploadSitePhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);
      final bytes = await picked.readAsBytes();

      // Compress to max 800 width/height
      Uint8List compressed = bytes;
      try {
        final decoded = img.decodeImage(bytes);
        if (decoded != null && (decoded.width > 800 || decoded.height > 800)) {
          final resized = img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 800 : null,
            height: decoded.height > decoded.width ? 800 : null,
          );
          compressed = Uint8List.fromList(img.encodeJpg(resized, quality: 80));
        }
      } catch (_) {}

      // Upload to listing-images bucket
      String? photoUrl;
      try {
        if (Supabase.instance.isInitialized) {
          final client = Supabase.instance.client;
          final uid = client.auth.currentUser?.id ?? 'anonymous';
          final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storagePath = '$uid/jobs/$filename';

          await client.storage.from('listing-images').uploadBinary(
            storagePath,
            compressed,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
          photoUrl = client.storage.from('listing-images').getPublicUrl(storagePath);
        }
      } catch (uploadErr) {
        AppLogger.w('Failed to upload site photo to storage: $uploadErr');
      }

      photoUrl ??= picked.path; // Local path fallback
      ref.read(postJobWizardProvider.notifier).setSitePhotoUrl(photoUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Site photo attached successfully! ✓'),
            backgroundColor: AppColors.headerGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.headerGreenDark),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadSitePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.amberOrange),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadSitePhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.watch(postJobWizardProvider);
    final categoriesAsync = ref.watch(serviceCategoriesListProvider);
    final isEditing = widget.editJobId != null;

    final steps = [
      l10n.postJobStep1,
      l10n.postJobStepAudience,
      l10n.postJobStep2,
      l10n.postJobStep3,
      l10n.postJobStep4,
      l10n.postJobStep5,
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        title: Text(
          isEditing ? l10n.editJobWizardTitle : l10n.postJobWizardTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper indicator
            _buildStepperHeader(draft.currentStep, steps),
            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildCurrentStep(draft, categoriesAsync, l10n),
              ),
            ),
            // Bottom action buttons
            _buildBottomNav(draft, l10n, isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader(int currentStep, List<String> stepTitles) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: List.generate(stepTitles.length, (index) {
              final isDone = index < currentStep;
              final isCurrent = index == currentStep;
              return Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isDone
                          ? AppColors.headerGreenDark
                          : isCurrent
                              ? AppColors.amberOrange
                              : Colors.grey.shade300,
                      child: isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                    ),
                    if (index < stepTitles.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: isDone ? AppColors.headerGreenDark : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            stepTitles[currentStep],
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(
    JobPostDraft draft,
    AsyncValue<List<ServiceCategoryItem>> categoriesAsync,
    AppLocalizations l10n,
  ) {
    switch (draft.currentStep) {
      case 0:
        return _buildStep1CategoryAndTitle(draft, categoriesAsync, l10n);
      case 1:
        return _buildStepAudience(draft, l10n);
      case 2:
        return _buildStep2WagesAndSchedule(draft, l10n);
      case 3:
        return _buildStep3SlotsAndPayment(draft, l10n);
      case 4:
        return _buildStep4RequirementsAndLocation(draft, l10n, categoriesAsync);
      case 5:
      default:
        return _buildStep5Preview(draft, l10n);
    }
  }

  // STEP 1: Category & Title & Description
  Widget _buildStep1CategoryAndTitle(
    JobPostDraft draft,
    AsyncValue<List<ServiceCategoryItem>> categoriesAsync,
    AppLocalizations l10n,
  ) {
    final notifier = ref.read(postJobWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.postJobSelectCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        categoriesAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (err, _) => Text('Error loading categories: $err'),
          data: (categories) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = draft.categoryId == cat.id;
                final catName = cat.getLocalizedName('en');
                return ChoiceChip(
                  label: Text(catName),
                  selected: isSelected,
                  selectedColor: AppColors.headerGreenDark,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  avatar: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : const Icon(Icons.work_outline_rounded, size: 16, color: AppColors.headerGreenDark),
                  onSelected: (selected) {
                    if (selected) {
                      final allowsStudent = cat.audience.contains('student') || cat.audience.contains('part_time');
                      notifier.setCategory(cat.id, catName, allowsStudent: allowsStudent);
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(l10n.postJobTitleLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: l10n.postJobTitleHint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          onChanged: notifier.setTitle,
        ),
        const SizedBox(height: 18),
        Text(l10n.postJobDescLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          controller: _descController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.postJobDescHint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          onChanged: notifier.setDescription,
        ),
        const SizedBox(height: 18),
        _buildSitePhotoSection(draft),
      ],
    );
  }

  Widget _buildSitePhotoSection(JobPostDraft draft) {
    final notifier = ref.read(postJobWizardProvider.notifier);
    final hasPhoto = draft.sitePhotoUrl != null && draft.sitePhotoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_a_photo_outlined, size: 20, color: AppColors.headerGreenDark),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Site Photo (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              if (hasPhoto)
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => notifier.setSitePhotoUrl(null),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Upload a real photo of the workplace or site to build trust with workers.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          if (_isUploadingPhoto)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: AppColors.headerGreenDark),
              ),
            )
          else if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  draft.sitePhotoUrl!.startsWith('http')
                      ? Image.network(
                          draft.sitePhotoUrl!,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 140,
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image, size: 36)),
                          ),
                        )
                      : Container(
                          height: 140,
                          color: AppColors.paleMint,
                          child: const Center(
                            child: Icon(Icons.photo_camera_rounded, size: 40, color: AppColors.headerGreenDark),
                          ),
                        ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.7),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _showPhotoPickerSheet,
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Change', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    onPressed: () => _pickAndUploadSitePhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.headerGreenDark),
                    label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    onPressed: () => _pickAndUploadSitePhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppColors.amberOrange),
                    label: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // STEP 2: Who is this job for? (Target Workers)
  Widget _buildStepAudience(JobPostDraft draft, AppLocalizations l10n) {
    final notifier = ref.read(postJobWizardProvider.notifier);

    final audiences = [
      (
        id: 'informal',
        title: l10n.postJobAudienceInformal,
        hint: l10n.postJobAudienceInformalHint,
        icon: Icons.handyman_rounded,
        color: AppColors.headerGreenDark,
      ),
      (
        id: 'student',
        title: l10n.postJobAudienceStudent,
        hint: l10n.postJobAudienceStudentHint,
        icon: Icons.school_rounded,
        color: Colors.blue.shade700,
      ),
      (
        id: 'part_time',
        title: l10n.postJobAudiencePartTime,
        hint: l10n.postJobAudiencePartTimeHint,
        icon: Icons.schedule_rounded,
        color: AppColors.amberOrange,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.postJobAudienceTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.headerGreenDark),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.postJobAudienceSubtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        ...audiences.map((aud) {
          final isSelected = draft.suitableFor.contains(aud.id);
          return Card(
            elevation: isSelected ? 2 : 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected ? aud.color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                final current = List<String>.from(draft.suitableFor);
                if (isSelected) {
                  current.remove(aud.id);
                } else {
                  current.add(aud.id);
                }
                notifier.setSuitableFor(current);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isSelected ? aud.color : Colors.grey.shade200).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(aud.icon, color: isSelected ? aud.color : Colors.grey.shade600, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  aud.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSelected ? AppColors.textDark : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: isSelected,
                                activeColor: aud.color,
                                onChanged: (val) {
                                  final current = List<String>.from(draft.suitableFor);
                                  if (val == true) {
                                    if (!current.contains(aud.id)) current.add(aud.id);
                                  } else {
                                    current.remove(aud.id);
                                  }
                                  notifier.setSuitableFor(current);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            aud.hint,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (draft.suitableFor.isEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.postJobAudienceRequired,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // STEP 3: Wages & Schedule
  Widget _buildStep2WagesAndSchedule(JobPostDraft draft, AppLocalizations l10n) {
    final notifier = ref.read(postJobWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.postJobWageType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: l10n.postJobWageDaily,
                selected: draft.wageType == 'daily',
                onSelected: () => notifier.setWageType('daily'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChoiceChip(
                label: l10n.postJobWageHourly,
                selected: draft.wageType == 'hourly',
                onSelected: () => notifier.setWageType('hourly'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChoiceChip(
                label: l10n.postJobWageFixed,
                selected: draft.wageType == 'fixed',
                onSelected: () => notifier.setWageType('fixed'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(l10n.postJobAmountLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _wageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val) ?? 0;
                  notifier.setWageRupees(parsed);
                },
              ),
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('+₹50'),
              onPressed: () {
                final cur = (draft.wagePaise / 100).round();
                final updated = cur + 50;
                _wageController.text = updated.toString();
                notifier.setWageRupees(updated);
              },
            ),
            const SizedBox(width: 4),
            ActionChip(
              label: const Text('+₹100'),
              onPressed: () {
                final cur = (draft.wagePaise / 100).round();
                final updated = cur + 100;
                _wageController.text = updated.toString();
                notifier.setWageRupees(updated);
              },
            ),
          ],
        ),

        // FAIR WAGE BAND HINT
        if (draft.minWagePaiseHint != null && draft.maxWagePaiseHint != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.paleMint.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderGreen),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: AppColors.headerGreenDark, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.postJobFairWageBandTitle} ${l10n.postJobFairWageBandRange((draft.minWagePaiseHint! / 100).round(), (draft.maxWagePaiseHint! / 100).round(), draft.wageBandUnit)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.headerGreenDark),
                  ),
                ),
              ],
            ),
          ),
        ],

        // BELOW FAIR WAGE WARNING (Warn, never block)
        if (draft.isBelowFairWage) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amberOrange),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.amberOrange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.postJobBelowFairWageWarning(
                      (draft.minWagePaiseHint! / 100).round(),
                      (draft.maxWagePaiseHint! / 100).round(),
                    ),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        Text(l10n.postJobDurationLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [240, 480, 600].map((mins) {
            final hrs = (mins / 60).round();
            final isSel = draft.estDurationMinutes == mins;
            return ChoiceChip(
              label: Text(l10n.postJobDurationHours(hrs)),
              selected: isSel,
              selectedColor: AppColors.headerGreenDark,
              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textDark),
              onSelected: (_) => notifier.setDurationMinutes(mins),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        Text(l10n.postJobStartDateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: draft.startAt,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
            );
            if (pickedDate != null && mounted) {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(draft.startAt),
              );
              if (pickedTime != null) {
                final fullDt = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                notifier.setStartAt(fullDt);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: AppColors.headerGreenDark, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEE, dd MMM yyyy • hh:mm a').format(draft.startAt),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                const Text('Change', style: TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 3: Slots, Materials & Payment Mode
  Widget _buildStep3SlotsAndPayment(JobPostDraft draft, AppLocalizations l10n) {
    final notifier = ref.read(postJobWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.postJobSlotsTotalLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: draft.slotsTotal > 1 ? () => notifier.setSlotsTotal(draft.slotsTotal - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.headerGreenDark, width: 1.5),
              ),
              child: Text(
                '${draft.slotsTotal} Workers',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
              ),
            ),
            const SizedBox(width: 16),
            IconButton.filledTonal(
              onPressed: () => notifier.setSlotsTotal(draft.slotsTotal + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.postJobMaterialsLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        SwitchListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Colors.white,
          title: Text(
            draft.materialsProvided ? l10n.postJobMaterialsProvided : l10n.postJobMaterialsWorkerBrings,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            draft.materialsProvided
                ? 'Tools, ladder & safety gear available at site'
                : 'Workers should come equipped with standard trade tools',
            style: const TextStyle(fontSize: 12),
          ),
          value: draft.materialsProvided,
          activeThumbColor: AppColors.headerGreenDark,
          onChanged: notifier.setMaterialsProvided,
        ),
        const SizedBox(height: 24),
        Text(l10n.postJobPaymentModeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        _buildPaymentModeCard(
          title: l10n.postJobPaymentEscrow,
          subtitle: l10n.postJobPaymentEscrowDesc,
          icon: Icons.shield_rounded,
          selected: draft.paymentMode == 'escrow',
          onTap: () => notifier.setPaymentMode('escrow'),
        ),
        const SizedBox(height: 8),
        _buildPaymentModeCard(
          title: l10n.postJobPaymentUpi,
          subtitle: l10n.postJobPaymentUpiDesc,
          icon: Icons.qr_code_scanner_rounded,
          selected: draft.paymentMode == 'upi',
          onTap: () => notifier.setPaymentMode('upi'),
        ),
        const SizedBox(height: 8),
        _buildPaymentModeCard(
          title: l10n.postJobPaymentCash,
          subtitle: l10n.postJobPaymentCashDesc,
          icon: Icons.payments_outlined,
          selected: draft.paymentMode == 'cash',
          onTap: () => notifier.setPaymentMode('cash'),
        ),
      ],
    );
  }

  // STEP 4: Requirements & Location
  Widget _buildStep4RequirementsAndLocation(
    JobPostDraft draft,
    AppLocalizations l10n,
    AsyncValue<List<ServiceCategoryItem>> categoriesAsync,
  ) {
    final notifier = ref.read(postJobWizardProvider.notifier);
    final mapCenter = LatLng(draft.latitude ?? _defaultBengaluruLat, draft.longitude ?? _defaultBengaluruLng);
    final selectedCat = categoriesAsync.asData?.value.where((c) => c.id == draft.categoryId).firstOrNull;
    final showStudentsWelcome = selectedCat != null &&
        (selectedCat.audience.contains('student') || selectedCat.audience.contains('part_time'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.postJobRequirementsLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        CheckboxListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Colors.white,
          title: Text(l10n.postJobReqVerifiedOnly, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: const Text('Workers must have verified Aadhaar and identity badge', style: TextStyle(fontSize: 12)),
          value: draft.verifiedOnly,
          activeColor: AppColors.headerGreenDark,
          onChanged: (val) => notifier.setRequirements(verifiedOnly: val ?? false),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Colors.white,
          title: Text(l10n.postJobReqLicence, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: const Text('Two-wheeler / transport licence required', style: TextStyle(fontSize: 12)),
          value: draft.licenceRequired,
          activeColor: AppColors.headerGreenDark,
          onChanged: (val) => notifier.setRequirements(licenceRequired: val ?? false),
        ),
        if (showStudentsWelcome) ...[
          const SizedBox(height: 8),
          CheckboxListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            title: Text(l10n.postJobReqStudents, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: const Text('Flexible shift friendly for college students', style: TextStyle(fontSize: 12)),
            value: draft.studentsOk,
            activeColor: AppColors.headerGreenDark,
            onChanged: (val) => notifier.setRequirements(studentsOk: val ?? false),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.postJobLocationLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            if (draft.latitude != null && draft.longitude != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.paleMint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorderGreen),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 13, color: AppColors.headerGreenDark),
                    SizedBox(width: 4),
                    Text('GPS Set', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Quick GPS Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paleMint,
              foregroundColor: AppColors.headerGreenDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorderGreen, width: 1.5),
              ),
            ),
            onPressed: _isLocating ? null : _useCurrentLocation,
            icon: _isLocating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.headerGreenDark))
                : const Icon(Icons.my_location, size: 18),
            label: Text(
              _isLocating ? 'Detecting GPS...' : 'Use My Current Location',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Address Search Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchAddressController,
                decoration: InputDecoration(
                  hintText: 'Search address / area (e.g. Indiranagar)',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                onSubmitted: _searchAddress,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: _isSearchingAddress ? null : () => _searchAddress(_searchAddressController.text),
              child: _isSearchingAddress
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Full Address field
        Text('Full Address (Street, Area, City)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        TextField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g. #42, 5th Cross, Koramangala 4th Block, Bengaluru',
            prefixIcon: const Icon(Icons.location_on, color: AppColors.headerGreenDark),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          onChanged: (val) => notifier.setLocation(address: val),
        ),

        const SizedBox(height: 12),

        // Landmark field
        Text('Landmark (Required)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        TextField(
          controller: _landmarkController,
          decoration: InputDecoration(
            hintText: 'e.g. Near Forum Mall, Opposite Metro Pillar 124',
            prefixIcon: const Icon(Icons.storefront_rounded, color: AppColors.amberOrange),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          onChanged: (val) => notifier.setLocation(address: _addressController.text, landmark: val),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pick on Map (Tap or drag pin)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            if (draft.latitude == null)
              Text('⚠️ Please tap map to set pin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
          ],
        ),
        const SizedBox(height: 6),

        // Interactive FlutterMap with Geofence circle
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: draft.latitude == null ? Colors.amber.shade400 : Colors.grey.shade300, width: draft.latitude == null ? 2 : 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 14.5,
                onTap: (_, point) async {
                  notifier.setLocation(
                    address: _addressController.text,
                    landmark: _landmarkController.text,
                    lat: point.latitude,
                    lng: point.longitude,
                  );
                  try {
                    final placemarks = await Geocoding().placemarkFromCoordinates(point.latitude, point.longitude);
                    if (placemarks.isNotEmpty && mounted) {
                      final p = placemarks.first;
                      final landmark = p.name ?? '';
                      final parts = <String>[];
                      if (p.street != null && p.street!.isNotEmpty && p.street != p.name) parts.add(p.street!);
                      if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
                      if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
                      if (p.postalCode != null && p.postalCode!.isNotEmpty) parts.add(p.postalCode!);
                      final addr = [if (landmark.isNotEmpty) landmark, ...parts].join(', ');
                      if (addr.isNotEmpty) {
                        setState(() {
                          _addressController.text = addr;
                          if (_landmarkController.text.isEmpty && landmark.isNotEmpty) {
                            _landmarkController.text = landmark;
                          }
                        });
                        notifier.setLocation(
                          address: addr,
                          landmark: _landmarkController.text.isNotEmpty ? _landmarkController.text : landmark,
                          lat: point.latitude,
                          lng: point.longitude,
                        );
                      }
                    }
                  } catch (_) {}
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'in.udyogasethu',
                ),
                if (draft.latitude != null && draft.longitude != null) ...[
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(draft.latitude!, draft.longitude!),
                        radius: draft.geofenceRadiusM.toDouble(),
                        useRadiusInMeter: true,
                        color: AppColors.headerGreenDark.withValues(alpha: 0.15),
                        borderColor: AppColors.headerGreenDark,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(draft.latitude!, draft.longitude!),
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.location_pin, color: AppColors.amberOrange, size: 44),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.postJobGeofenceRadiusLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [50, 100, 150, 250, 500].map((radius) {
            final isSel = draft.geofenceRadiusM == radius;
            return ChoiceChip(
              label: Text(l10n.postJobGeofenceMeters(radius)),
              selected: isSel,
              selectedColor: AppColors.headerGreenDark,
              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textDark),
              onSelected: (_) {
                notifier.setLocation(address: _addressController.text, radiusM: radius);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 5: Preview & Publish
  Widget _buildStep5Preview(JobPostDraft draft, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                JobThumbnailWidget(
                  sitePhotoUrl: draft.sitePhotoUrl,
                  categorySlug: draft.categoryName?.toLowerCase() ?? 'general',
                  jobId: draft.jobId ?? 'preview-draft',
                  title: draft.title,
                  description: draft.description,
                  width: 52,
                  height: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(draft.title.isNotEmpty ? draft.title : 'Untitled Job', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(draft.categoryName ?? 'General', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildPreviewRow('Wage', '₹${(draft.wagePaise / 100).round()} / ${draft.wageType} (${draft.paymentMode.toUpperCase()})'),
            _buildPreviewRow('Workers Needed', '${draft.slotsTotal} Slots'),
            _buildPreviewRow('Start Time', DateFormat('EEE, dd MMM • hh:mm a').format(draft.startAt)),
            _buildPreviewRow('Duration', '${(draft.estDurationMinutes / 60).round()} Hours'),
            _buildPreviewRow('Materials', draft.materialsProvided ? 'Provided by Employer' : 'Worker must bring tools'),
            _buildPreviewRow('Site Address', draft.addressText.isNotEmpty ? draft.addressText : 'Not specified'),
            _buildPreviewRow('Landmark', draft.landmark.isNotEmpty ? draft.landmark : 'Not specified'),
            _buildPreviewRow('Geofence Radius', '${draft.geofenceRadiusM} meters'),
            _buildPreviewRow(
              'Target Workers',
              draft.suitableFor.isEmpty
                  ? 'None selected'
                  : draft.suitableFor.map((s) {
                      if (s == 'informal') return l10n.postJobAudienceInformal;
                      if (s == 'student') return l10n.postJobAudienceStudent;
                      if (s == 'part_time') return l10n.postJobAudiencePartTime;
                      return s;
                    }).join(', '),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              children: [
                if (draft.verifiedOnly)
                  const Chip(
                    avatar: Icon(Icons.verified, size: 16, color: Colors.white),
                    backgroundColor: AppColors.headerGreenDark,
                    label: Text('Verified Only', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                if (draft.licenceRequired)
                  const Chip(
                    avatar: Icon(Icons.two_wheeler, size: 16, color: Colors.white),
                    backgroundColor: AppColors.headerGreenDark,
                    label: Text('Licence Required', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                if (draft.studentsOk)
                  Chip(
                    avatar: const Icon(Icons.school, size: 16, color: Colors.white),
                    backgroundColor: AppColors.amberOrange,
                    label: Text(l10n.studentsWelcomeChip, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
              ],
            ),
            if (draft.latitude != null && draft.longitude != null) ...[
              const SizedBox(height: 16),
              const Text('Site Location Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(draft.latitude!, draft.longitude!),
                      initialZoom: 14.5,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'in.udyogasethu',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(draft.latitude!, draft.longitude!),
                            radius: draft.geofenceRadiusM.toDouble(),
                            useRadiusInMeter: true,
                            color: AppColors.headerGreenDark.withValues(alpha: 0.15),
                            borderColor: AppColors.headerGreenDark,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(draft.latitude!, draft.longitude!),
                            width: 36,
                            height: 36,
                            child: const Icon(Icons.location_pin, color: AppColors.amberOrange, size: 36),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (draft.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(draft.description, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Center(child: Text(label)),
      selected: selected,
      selectedColor: AppColors.headerGreenDark,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textDark, fontWeight: FontWeight.bold),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildPaymentModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.paleMint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.headerGreenDark : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.headerGreenDark : Colors.grey.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: selected ? AppColors.headerGreenDark : AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.headerGreenDark, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(JobPostDraft draft, AppLocalizations l10n, bool isEditing) {
    final notifier = ref.read(postJobWizardProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (draft.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: notifier.prevStep,
                child: const Text('Back'),
              ),
            ),
          if (draft.currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isPublishing
                  ? null
                  : () async {
                      if (draft.currentStep == 0 && draft.title.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a job title')),
                        );
                        return;
                      }
                      if (draft.currentStep == 1 && draft.suitableFor.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.postJobAudienceRequired)),
                        );
                        return;
                      }
                      if (draft.currentStep == 4) {
                        if (draft.latitude == null || draft.longitude == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please choose site coordinates using GPS, address search, or map pin')),
                          );
                          return;
                        }
                        if (_isInvalidAddress(_addressController.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a full address with street/locality. A house number alone is not sufficient.')),
                          );
                          return;
                        }
                        if (_landmarkController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please specify a landmark to help workers locate the site')),
                          );
                          return;
                        }
                      }
                      if (draft.currentStep < 5) {
                        notifier.nextStep();
                      } else {
                        // PUBLISH
                        setState(() => _isPublishing = true);
                        try {
                          await notifier.publish();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.postJobPublishSuccess),
                                backgroundColor: AppColors.headerGreenDark,
                              ),
                            );
                            context.pop();
                          }
                        } catch (e, stack) {
                          AppLogger.e('Failed to publish job', e, stack);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isPublishing = false);
                        }
                      }
                    },
              child: _isPublishing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      draft.currentStep < 5
                          ? 'Next'
                          : isEditing
                              ? l10n.postJobSaveEditButton
                              : l10n.postJobPublishButton,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
