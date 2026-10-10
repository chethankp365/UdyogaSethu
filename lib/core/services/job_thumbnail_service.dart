import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';

enum ThumbnailSourceType {
  network,
  asset,
}

class JobThumbnail {
  final ThumbnailSourceType sourceType;
  final String uri;
  final String categorySlug;
  final IconData categoryIcon;
  final String? imageName;

  const JobThumbnail({
    required this.sourceType,
    required this.uri,
    required this.categorySlug,
    required this.categoryIcon,
    this.imageName,
  });

  bool get isNetwork => sourceType == ThumbnailSourceType.network;
}

class LibraryImageRule {
  final String imageName;
  final String categorySlug;
  final String assetPath;
  final List<String> keywords;

  const LibraryImageRule({
    required this.imageName,
    required this.categorySlug,
    required this.assetPath,
    required this.keywords,
  });
}

class JobThumbnailService {
  static final JobThumbnailService _instance = JobThumbnailService._internal();
  factory JobThumbnailService() => _instance;
  JobThumbnailService._internal();

  static const String manifestAssetPath = 'assets/images/jobs/manifest.json';

  // In-memory keyword mapping: keyword -> category slug
  final Map<String, String> _keywordToSlug = {};
  final Set<String> _knownSlugs = {};
  final List<LibraryImageRule> _libraryRules = [];
  bool _isManifestLoaded = false;

  static final List<LibraryImageRule> _builtinLibraryRules = const [
    LibraryImageRule(
      imageName: 'painting-interior',
      categorySlug: 'painting',
      assetPath: 'assets/images/jobs/painting-interior.webp',
      keywords: ['wall paint', 'interior paint', 'room paint', 'wall painting', 'whitewash', 'indoor paint'],
    ),
    LibraryImageRule(
      imageName: 'painting-exterior',
      categorySlug: 'painting',
      assetPath: 'assets/images/jobs/painting-exterior.webp',
      keywords: ['exterior paint', 'building paint', 'weather paint', 'facade', 'outdoor paint'],
    ),
    LibraryImageRule(
      imageName: 'electrician-wiring',
      categorySlug: 'electrician',
      assetPath: 'assets/images/jobs/electrician-wiring.webp',
      keywords: ['wiring', 'switchboard', 'circuit', 'fuse', 'short circuit', 'electrical wiring'],
    ),
    LibraryImageRule(
      imageName: 'electrician-appliance',
      categorySlug: 'electrician',
      assetPath: 'assets/images/jobs/electrician-appliance.webp',
      keywords: ['ac repair', 'inverter', 'motor', 'appliance', 'fan', 'geyser', 'refrigerator'],
    ),
    LibraryImageRule(
      imageName: 'plumbing-repair',
      categorySlug: 'plumbing',
      assetPath: 'assets/images/jobs/plumbing-repair.webp',
      keywords: ['pipe', 'leak', 'tap', 'drainage', 'faucet', 'water pipe', 'pipeline', 'leakage'],
    ),
    LibraryImageRule(
      imageName: 'plumbing-bathroom',
      categorySlug: 'plumbing',
      assetPath: 'assets/images/jobs/plumbing-bathroom.webp',
      keywords: ['bathroom', 'sink', 'sanitary', 'water tank', 'toilet', 'commode', 'wash basin'],
    ),
    LibraryImageRule(
      imageName: 'carpenter-furniture',
      categorySlug: 'carpenter',
      assetPath: 'assets/images/jobs/carpenter-furniture.webp',
      keywords: ['furniture', 'table', 'chair', 'cabinet', 'wood', 'wooden', 'plywood', 'dining table', 'bed', 'sofa', 'wardrobe'],
    ),
    LibraryImageRule(
      imageName: 'carpenter-doors',
      categorySlug: 'carpenter',
      assetPath: 'assets/images/jobs/carpenter-doors.webp',
      keywords: ['door', 'window', 'frame', 'hinge', 'lock', 'latch', 'sliding door'],
    ),
    LibraryImageRule(
      imageName: 'cleaner-home',
      categorySlug: 'cleaner',
      assetPath: 'assets/images/jobs/cleaner-home.webp',
      keywords: ['cleaning', 'cleaner', 'housekeeping', 'sweep', 'mop', 'deep cleaning', 'home cleaning'],
    ),
    LibraryImageRule(
      imageName: 'cleaner-office',
      categorySlug: 'cleaner',
      assetPath: 'assets/images/jobs/cleaner-office.webp',
      keywords: ['office cleaning', 'commercial cleaning', 'sanitation', 'dusting', 'janitor', 'hygiene'],
    ),
    LibraryImageRule(
      imageName: 'gardener-lawn',
      categorySlug: 'gardener',
      assetPath: 'assets/images/jobs/gardener-lawn.webp',
      keywords: ['gardener', 'gardening', 'landscaping', 'lawn', 'mowing', 'lawn mowing', 'plants', 'plant care', 'nursery'],
    ),
    LibraryImageRule(
      imageName: 'delivery-food',
      categorySlug: 'delivery-gig-work',
      assetPath: 'assets/images/jobs/delivery-food.webp',
      keywords: ['food delivery', 'swiggy', 'zomato', 'zepto', 'blinkit', 'quick commerce'],
    ),
    LibraryImageRule(
      imageName: 'delivery-courier',
      categorySlug: 'delivery',
      assetPath: 'assets/images/jobs/delivery-courier.webp',
      keywords: ['courier', 'parcel', 'transport', 'dispatch', 'rider', 'cargo', 'package delivery'],
    ),
    LibraryImageRule(
      imageName: 'content-writing',
      categorySlug: 'content-writing',
      assetPath: 'assets/images/jobs/content-writing.webp',
      keywords: ['content', 'writing', 'copywriting', 'blog', 'article', 'translation', 'proofreading'],
    ),
    LibraryImageRule(
      imageName: 'design-creative',
      categorySlug: 'design-data-work',
      assetPath: 'assets/images/jobs/design-creative.webp',
      keywords: ['design', 'graphic', 'photoshop', 'illustrator', 'editing', 'presentation'],
    ),
    LibraryImageRule(
      imageName: 'data-entry',
      categorySlug: 'design-data-work',
      assetPath: 'assets/images/jobs/data-entry.webp',
      keywords: ['data entry', 'excel', 'typing', 'digital work', 'spreadsheet'],
    ),
  ];

  // Built-in keyword fallback map to ensure immediate synchronous resolution
  static final Map<String, List<String>> _builtinKeywords = {
    'electrician': ['electrician', 'electrical', 'wiring', 'switchboard', 'circuit', 'fuse', 'inverter', 'motor', 'appliance', 'ac repair', 'lighting', 'wire'],
    'plumbing': ['plumbing', 'plumber', 'pipe', 'leak', 'tap', 'drainage', 'sink', 'faucet', 'sanitary', 'bathroom', 'water tank'],
    'carpenter': ['carpenter', 'wood', 'furniture', 'door', 'table', 'chair', 'cabinet', 'plywood', 'carpentry', 'wooden'],
    'painting': ['painting', 'painter', 'whitewash', 'distemper', 'texture', 'varnish', 'spray paint', 'wall paint'],
    'cleaner': ['cleaning', 'cleaner', 'housekeeping', 'sweep', 'mop', 'sanitation', 'wash', 'dusting', 'hygiene', 'office cleaning', 'janitor'],
    'construction': ['construction', 'builder', 'cement', 'concrete', 'site', 'brick', 'civil', 'scaffolding', 'building work'],
    'mason': ['mason', 'masonry', 'tile', 'tiles', 'plaster', 'bricklayer', 'flooring', 'stone', 'granite'],
    'loader': ['loader', 'unloader', 'loading', 'unloading', 'warehouse', 'shifting', 'packers', 'movers', 'luggage', 'lifting'],
    'driver': ['driver', 'driving', 'chauffeur', 'cab', 'taxi', 'car driver', 'truck driver', 'tempo', 'vehicle'],
    'agri_labour': ['agriculture', 'farming', 'farm', 'harvest', 'crop', 'field', 'tractor', 'plantation', 'seed', 'dairy', 'cattle', 'agri'],
    'domestic_help': ['domestic help', 'maid', 'cook', 'cooking', 'babysitter', 'caregiver', 'nanny', 'elder care', 'household'],
    'delivery': ['delivery', 'courier', 'parcel', 'transport', 'dispatch', 'rider', 'cargo'],
    'delivery-gig-work': ['delivery gig', 'food delivery', 'swiggy', 'zomato', 'zepto', 'blinkit', 'quick commerce', 'package delivery', 'instant delivery'],
    'retail-food-service': ['retail', 'store', 'shop assistant', 'cashier', 'waiter', 'restaurant', 'cafe', 'billing', 'counter', 'sales assistant'],
    'content-writing': ['content', 'writing', 'copywriting', 'blog', 'article', 'translation', 'proofreading', 'typing', 'data entry'],
    'design-data-work': ['design', 'graphic', 'photoshop', 'illustrator', 'data entry', 'excel', 'editing', 'presentation', 'digital'],
    'tutoring-academics': ['tutoring', 'tutor', 'teacher', 'maths', 'science', 'coaching', 'tuition', 'academic', 'lessons'],
    'campus-brand-promotion': ['campus', 'brand', 'promotion', 'college', 'flyer', 'ambassador', 'marketing', 'event', 'sampling'],
    'gardener': ['gardener', 'gardening', 'landscaping', 'plants', 'lawn', 'mowing', 'nursery', 'horticulture', 'tree pruning', 'watering'],
    'general': ['general', 'helper', 'assistant', 'utility', 'support', 'daily labour', 'manual work'],
  };

  void init() {
    if (_keywordToSlug.isEmpty) {
      _loadBuiltin();
    }
  }

  void _loadBuiltin() {
    for (final entry in _builtinKeywords.entries) {
      _knownSlugs.add(entry.key);
      for (final kw in entry.value) {
        _keywordToSlug[kw.toLowerCase()] = entry.key;
      }
    }
    if (_libraryRules.isEmpty) {
      _libraryRules.addAll(_builtinLibraryRules);
    }
  }

  Future<void> loadManifest() async {
    if (_isManifestLoaded) return;
    init();
    try {
      final jsonString = await rootBundle.loadString(manifestAssetPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final categories = data['categories'] as List<dynamic>? ?? [];
      for (final cat in categories) {
        if (cat is Map<String, dynamic>) {
          final slug = cat['slug'] as String? ?? '';
          if (slug.isNotEmpty) {
            _knownSlugs.add(slug);
            final kws = cat['keywords'] as List<dynamic>? ?? [];
            for (final kw in kws) {
              _keywordToSlug[kw.toString().toLowerCase()] = slug;
            }
          }
        }
      }

      final libraryItems = data['library'] as List<dynamic>? ?? [];
      for (final item in libraryItems) {
        if (item is Map<String, dynamic>) {
          final name = item['name'] as String? ?? '';
          final cat = item['category'] as String? ?? '';
          final asset = item['asset'] as String? ?? '';
          final kws = (item['keywords'] as List<dynamic>? ?? []).map((k) => k.toString()).toList();
          if (name.isNotEmpty && asset.isNotEmpty) {
            final exists = _libraryRules.any((r) => r.imageName == name);
            if (!exists) {
              _libraryRules.add(LibraryImageRule(
                imageName: name,
                categorySlug: cat,
                assetPath: asset,
                keywords: kws,
              ));
            }
          }
        }
      }
      _isManifestLoaded = true;
    } catch (_) {
      // Keep builtins on error
    }
  }

  /// Keyword-aware selection with provider site photo priority
  JobThumbnail selectThumbnail({
    String? sitePhotoUrl,
    required String categorySlug,
    required String jobId,
    String? title,
    String? description,
  }) {
    init();

    // 1. Provider site photo priority (highest priority)
    if (sitePhotoUrl != null && sitePhotoUrl.trim().isNotEmpty) {
      return JobThumbnail(
        sourceType: ThumbnailSourceType.network,
        uri: sitePhotoUrl.trim(),
        categorySlug: categorySlug,
        categoryIcon: getCategoryIcon(categorySlug),
        imageName: null,
      );
    }

    // 2. Library image chosen by category AND keywords in title & description
    final text = '${title ?? ''} ${description ?? ''}'.toLowerCase();
    final libraryMatch = _matchLibraryRule(text, categorySlug);
    if (libraryMatch != null) {
      return JobThumbnail(
        sourceType: ThumbnailSourceType.asset,
        uri: libraryMatch.assetPath,
        categorySlug: libraryMatch.categorySlug,
        categoryIcon: getCategoryIcon(libraryMatch.categorySlug),
        imageName: libraryMatch.imageName,
      );
    }

    // 3. Fallback to category slug and deterministic variant
    String effectiveSlug = _matchKeywords(title, description) ?? categorySlug;
    if (!_knownSlugs.contains(effectiveSlug)) {
      effectiveSlug = 'general';
    }

    final variant = (jobId.hashCode.abs() % 2) + 1;
    final imageName = '$effectiveSlug-$variant';
    final assetPath = 'assets/images/jobs/$imageName.webp';

    return JobThumbnail(
      sourceType: ThumbnailSourceType.asset,
      uri: assetPath,
      categorySlug: effectiveSlug,
      categoryIcon: getCategoryIcon(effectiveSlug),
      imageName: imageName,
    );
  }

  LibraryImageRule? _matchLibraryRule(String text, String categorySlug) {
    if (text.trim().isEmpty) return null;

    // First check rules matching the given categorySlug
    final catRules = _libraryRules.where((r) => r.categorySlug == categorySlug).toList();
    for (final rule in catRules) {
      for (final kw in rule.keywords) {
        if (text.contains(kw.toLowerCase())) {
          return rule;
        }
      }
    }

    // Then check all rules, prioritizing longer multi-word phrases first
    final sortedRules = [..._libraryRules];
    sortedRules.sort((a, b) {
      final maxA = a.keywords.map((k) => k.length).fold(0, (prev, len) => len > prev ? len : prev);
      final maxB = b.keywords.map((k) => k.length).fold(0, (prev, len) => len > prev ? len : prev);
      return maxB.compareTo(maxA);
    });

    for (final rule in sortedRules) {
      for (final kw in rule.keywords) {
        if (text.contains(kw.toLowerCase())) {
          return rule;
        }
      }
    }

    return null;
  }

  String? _matchKeywords(String? title, String? description) {
    final text = '${title ?? ''} ${description ?? ''}'.toLowerCase();
    if (text.trim().isEmpty) return null;

    // Check longer multi-word keywords first, then single words
    final sortedKeywords = _keywordToSlug.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final kw in sortedKeywords) {
      if (text.contains(kw)) {
        return _keywordToSlug[kw];
      }
    }
    return null;
  }

  static IconData getCategoryIcon(String iconOrSlug) {
    switch (iconOrSlug.toLowerCase()) {
      case 'plumbing':
      case 'plumber':
        return Icons.plumbing_rounded;
      case 'electrician':
      case 'flash_on':
        return Icons.electrical_services_rounded;
      case 'carpenter':
        return Icons.carpenter_rounded;
      case 'construction':
      case 'mason':
      case 'handyman':
        return Icons.handyman_rounded;
      case 'cleaning':
      case 'cleaner':
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'loader':
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      case 'painting':
      case 'format_paint':
        return Icons.format_paint_rounded;
      case 'driver':
      case 'drive_eta':
        return Icons.drive_eta_rounded;
      case 'agri':
      case 'agri_labour':
      case 'agriculture':
        return Icons.agriculture_rounded;
      case 'domestic_help':
      case 'home_repair_service':
        return Icons.home_repair_service_rounded;
      case 'content-writing':
      case 'edit_note':
        return Icons.edit_note_rounded;
      case 'design-data-work':
      case 'computer':
        return Icons.computer_rounded;
      case 'tutoring-academics':
      case 'school':
        return Icons.school_rounded;
      case 'campus-brand-promotion':
      case 'campaign':
        return Icons.campaign_rounded;
      case 'retail-food-service':
      case 'storefront':
        return Icons.storefront_rounded;
      case 'gardener':
      case 'yard':
        return Icons.yard_rounded;
      case 'delivery':
      case 'delivery-gig-work':
      case 'two_wheeler':
        return Icons.two_wheeler_rounded;
      default:
        return Icons.work_outline_rounded;
    }
  }
}

/// Dynamic thumbnail widget with site photo priority, keyword asset fallback,
/// and gradient/icon error container
class JobThumbnailWidget extends StatelessWidget {
  final String? sitePhotoUrl;
  final String categorySlug;
  final String jobId;
  final String? title;
  final String? description;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const JobThumbnailWidget({
    super.key,
    this.sitePhotoUrl,
    required this.categorySlug,
    required this.jobId,
    this.title,
    this.description,
    this.width = 56,
    this.height = 56,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = JobThumbnailService().selectThumbnail(
      sitePhotoUrl: sitePhotoUrl,
      categorySlug: categorySlug,
      jobId: jobId,
      title: title,
      description: description,
    );

    final radius = borderRadius ?? BorderRadius.circular(10);

    Widget imageContent;
    if (thumb.isNetwork) {
      imageContent = Image.network(
        thumb.uri,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildAssetFallback(thumb, radius),
      );
    } else {
      imageContent = _buildAssetFallback(thumb, radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: imageContent,
      ),
    );
  }

  Widget _buildAssetFallback(JobThumbnail thumb, BorderRadius radius) {
    // Generate deterministic asset fallback if network fails
    final fallbackAsset = thumb.isNetwork
        ? JobThumbnailService().selectThumbnail(
            sitePhotoUrl: null,
            categorySlug: categorySlug,
            jobId: jobId,
            title: title,
            description: description,
          ).uri
        : thumb.uri;

    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, stack) => _buildGradientFallback(thumb),
    );
  }

  Widget _buildGradientFallback(JobThumbnail thumb) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.headerGreenDark,
            AppColors.primaryTeal.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          thumb.categoryIcon,
          color: Colors.white,
          size: width * 0.45,
        ),
      ),
    );
  }
}
