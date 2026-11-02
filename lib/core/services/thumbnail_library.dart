import 'package:flutter/material.dart';

/// Item in the curated thumbnail library
class ThumbnailLibraryItem {
  final String key;
  final String title;
  final String assetPath;
  final String categoryGroup; // 'services', 'gigs', 'produce', 'crops', 'equipment', 'fallback'
  final bool hasBakedInTitle;
  final List<String> keywords;

  const ThumbnailLibraryItem({
    required this.key,
    required this.title,
    required this.assetPath,
    required this.categoryGroup,
    this.hasBakedInTitle = false,
    required this.keywords,
  });
}

/// Central registry of all 41 illustrated WebP thumbnails
class ThumbnailLibrary {
  ThumbnailLibrary._();

  static const String fallbackAsset = 'assets/thumbnails/fallback_generic.webp';

  /// All 41 illustrated thumbnails in the library
  static const List<ThumbnailLibraryItem> items = [
    // -------------------------------------------------------------------------
    // 1. ALL 12 SERVICE CATEGORIES
    // -------------------------------------------------------------------------
    ThumbnailLibraryItem(
      key: 'construction',
      title: 'Construction',
      assetPath: 'assets/thumbnails/construction.webp',
      categoryGroup: 'services',
      keywords: ['construction', 'builder', 'cement', 'concrete', 'building', 'scaffolding', 'civil', 'site work'],
    ),
    ThumbnailLibraryItem(
      key: 'plumbing',
      title: 'Plumbing',
      assetPath: 'assets/thumbnails/plumbing.webp',
      categoryGroup: 'services',
      keywords: ['plumbing', 'plumber', 'pipe', 'leak', 'tap', 'drainage', 'sink', 'faucet', 'sanitary', 'bathroom', 'water tank'],
    ),
    ThumbnailLibraryItem(
      key: 'painting',
      title: 'Painting',
      assetPath: 'assets/thumbnails/painting.webp',
      categoryGroup: 'services',
      keywords: ['painting', 'painter', 'whitewash', 'distemper', 'texture', 'varnish', 'spray paint', 'wall paint', 'color'],
    ),
    ThumbnailLibraryItem(
      key: 'delivery',
      title: 'Delivery & Logistics',
      assetPath: 'assets/thumbnails/delivery.webp',
      categoryGroup: 'services',
      keywords: ['delivery', 'courier', 'parcel', 'transport', 'dispatch', 'rider', 'cargo', 'swiggy', 'zomato', 'zepto', 'blinkit', 'quick commerce', 'food delivery'],
    ),
    ThumbnailLibraryItem(
      key: 'electrician',
      title: 'Electrician',
      assetPath: 'assets/thumbnails/electrician.webp',
      categoryGroup: 'services',
      keywords: ['electrician', 'electrical', 'wiring', 'switchboard', 'circuit', 'fuse', 'inverter', 'motor', 'appliance', 'ac repair', 'lighting', 'power'],
    ),
    ThumbnailLibraryItem(
      key: 'carpenter',
      title: 'Carpenter',
      assetPath: 'assets/thumbnails/carpenter.webp',
      categoryGroup: 'services',
      keywords: ['carpenter', 'carpentry', 'wood', 'furniture', 'door', 'table', 'chair', 'cabinet', 'plywood', 'wooden'],
    ),
    ThumbnailLibraryItem(
      key: 'mason',
      title: 'Mason',
      assetPath: 'assets/thumbnails/mason.webp',
      categoryGroup: 'services',
      keywords: ['mason', 'masonry', 'tile', 'tiles', 'plaster', 'bricklayer', 'flooring', 'stone', 'granite', 'brick'],
    ),
    ThumbnailLibraryItem(
      key: 'cleaner',
      title: 'Cleaning & Housekeeping',
      assetPath: 'assets/thumbnails/cleaner.webp',
      categoryGroup: 'services',
      keywords: ['cleaner', 'cleaning', 'housekeeping', 'sweep', 'mop', 'sanitation', 'wash', 'dusting', 'hygiene', 'office cleaning', 'janitor', 'deep clean'],
    ),
    ThumbnailLibraryItem(
      key: 'driver',
      title: 'Driver',
      assetPath: 'assets/thumbnails/driver.webp',
      categoryGroup: 'services',
      keywords: ['driver', 'driving', 'chauffeur', 'cab', 'taxi', 'car driver', 'truck driver', 'tempo', 'vehicle', 'chauffer'],
    ),
    ThumbnailLibraryItem(
      key: 'domestic_help',
      title: 'Domestic Help',
      assetPath: 'assets/thumbnails/domestic_help.webp',
      categoryGroup: 'services',
      keywords: ['domestic help', 'maid', 'cook', 'cooking', 'babysitter', 'caregiver', 'nanny', 'elder care', 'household', 'home helper'],
    ),
    ThumbnailLibraryItem(
      key: 'agri_labour',
      title: 'Agricultural Labour',
      assetPath: 'assets/thumbnails/agri_labour.webp',
      categoryGroup: 'services',
      keywords: ['agri labour', 'farm worker', 'field labour', 'harvesting labour', 'plantation labour', 'agriculture labour', 'agri_labour'],
    ),
    ThumbnailLibraryItem(
      key: 'loader',
      title: 'Loader / Unloader',
      assetPath: 'assets/thumbnails/loader.webp',
      categoryGroup: 'services',
      keywords: ['loader', 'unloader', 'loading', 'unloading', 'warehouse', 'shifting', 'packers', 'movers', 'luggage', 'lifting', 'cargo handling'],
    ),

    // -------------------------------------------------------------------------
    // 2. STUDENT & FLEXIBLE GIGS
    // -------------------------------------------------------------------------
    ThumbnailLibraryItem(
      key: 'campus_ambassador',
      title: 'Campus Ambassador',
      assetPath: 'assets/thumbnails/campus_ambassador.webp',
      categoryGroup: 'gigs',
      hasBakedInTitle: true,
      keywords: ['campus ambassador', 'campus connect', 'college ambassador', 'campus lead', 'student ambassador', 'brand ambassador', 'college rep'],
    ),
    ThumbnailLibraryItem(
      key: 'online_tutor',
      title: 'Online Tutor',
      assetPath: 'assets/thumbnails/online_tutor.webp',
      categoryGroup: 'gigs',
      keywords: ['online tutor', 'online tuition', 'remote tutor', 'virtual tutor', 'online class', 'video tutor', 'zoom tuition'],
    ),
    ThumbnailLibraryItem(
      key: 'tutoring',
      title: 'Tutoring',
      assetPath: 'assets/thumbnails/tutoring.webp',
      categoryGroup: 'gigs',
      keywords: ['tutor', 'tutoring', 'teaching', 'teacher', 'maths tuition', 'science tuition', 'home tuition', 'tuition teacher', 'academic coaching'],
    ),
    ThumbnailLibraryItem(
      key: 'research_assistant',
      title: 'Research Assistant',
      assetPath: 'assets/thumbnails/research_assistant.webp',
      categoryGroup: 'gigs',
      keywords: ['research assistant', 'research', 'lab assistant', 'library research', 'survey assistant', 'field research', 'academic assistant'],
    ),
    ThumbnailLibraryItem(
      key: 'data_entry',
      title: 'Data Entry',
      assetPath: 'assets/thumbnails/data_entry.webp',
      categoryGroup: 'gigs',
      keywords: ['data entry', 'excel', 'typing', 'spreadsheet', 'data operator', 'back office', 'data typing', 'computer operator'],
    ),
    ThumbnailLibraryItem(
      key: 'event_helper',
      title: 'Event Helper',
      assetPath: 'assets/thumbnails/event_helper.webp',
      categoryGroup: 'gigs',
      keywords: ['event helper', 'event staff', 'college fest', 'festival helper', 'conference assistant', 'exhibition helper', 'party helper', 'usher'],
    ),
    ThumbnailLibraryItem(
      key: 'content_creation',
      title: 'Content Creation',
      assetPath: 'assets/thumbnails/content_creation.webp',
      categoryGroup: 'gigs',
      keywords: ['content creation', 'content creator', 'video editing', 'reels', 'youtube', 'videography', 'photography', 'scriptwriter', 'editor'],
    ),
    ThumbnailLibraryItem(
      key: 'social_media',
      title: 'Social Media',
      assetPath: 'assets/thumbnails/social_media.webp',
      categoryGroup: 'gigs',
      keywords: ['social media', 'instagram', 'digital marketing', 'community manager', 'social media helper', 'brand promoter', 'marketing gig'],
    ),

    // -------------------------------------------------------------------------
    // 3. FARM PRODUCE CATEGORIES
    // -------------------------------------------------------------------------
    ThumbnailLibraryItem(
      key: 'produce_vegetables',
      title: 'Vegetables',
      assetPath: 'assets/thumbnails/produce_vegetables.webp',
      categoryGroup: 'produce',
      keywords: ['vegetables', 'vegetable', 'sabzi', 'tarkari', 'greens', 'leafy greens', 'capsicum', 'cabbage', 'carrot'],
    ),
    ThumbnailLibraryItem(
      key: 'produce_fruits',
      title: 'Fruits',
      assetPath: 'assets/thumbnails/produce_fruits.webp',
      categoryGroup: 'produce',
      keywords: ['fruits', 'fruit', 'fal', 'orchard', 'apples', 'oranges', 'grapes', 'papaya', 'guava'],
    ),
    ThumbnailLibraryItem(
      key: 'produce_grains',
      title: 'Grains & Pulses',
      assetPath: 'assets/thumbnails/produce_grains.webp',
      categoryGroup: 'produce',
      keywords: ['grains', 'grain', 'pulses', 'dal', 'wheat', 'atta', 'flour', 'millet', 'ragi', 'jowar', 'cereal', 'toor dal'],
    ),
    ThumbnailLibraryItem(
      key: 'produce_dairy',
      title: 'Dairy & Milk',
      assetPath: 'assets/thumbnails/produce_dairy.webp',
      categoryGroup: 'produce',
      keywords: ['dairy', 'milk', 'curd', 'ghee', 'paneer', 'butter', 'cow milk', 'buffalo milk', 'doodh'],
    ),
    ThumbnailLibraryItem(
      key: 'produce_flowers',
      title: 'Flowers',
      assetPath: 'assets/thumbnails/produce_flowers.webp',
      categoryGroup: 'produce',
      keywords: ['flowers', 'flower', 'marigold', 'jasmine', 'rose', 'garland', 'puja flowers', 'mogra', 'lotus', 'phool'],
    ),
    ThumbnailLibraryItem(
      key: 'produce_local',
      title: 'Local & Organic Products',
      assetPath: 'assets/thumbnails/produce_local.webp',
      categoryGroup: 'produce',
      keywords: ['local products', 'local produce', 'honey', 'jaggery', 'pickle', 'handicraft', 'pottery', 'organic spices', 'village special', 'gud'],
    ),

    // -------------------------------------------------------------------------
    // 4. INDIVIDUAL CROPS
    // -------------------------------------------------------------------------
    ThumbnailLibraryItem(
      key: 'crop_tomato',
      title: 'Tomato',
      assetPath: 'assets/thumbnails/crop_tomato.webp',
      categoryGroup: 'crops',
      keywords: ['tomato', 'tomatoes', 'tamatar', 'thakkali', 'tomato hybrid', 'desi tomato'],
    ),
    ThumbnailLibraryItem(
      key: 'crop_onion',
      title: 'Onion',
      assetPath: 'assets/thumbnails/crop_onion.webp',
      categoryGroup: 'crops',
      keywords: ['onion', 'pyaz', 'vengayam', 'bellary onion', 'red onion', 'shallot'],
    ),
    ThumbnailLibraryItem(
      key: 'crop_mango',
      title: 'Mango',
      assetPath: 'assets/thumbnails/crop_mango.webp',
      categoryGroup: 'crops',
      keywords: ['mango', 'aam', 'alphonso', 'badami', 'kesar', 'mallika', 'dasheri', 'banganapalli'],
    ),
    ThumbnailLibraryItem(
      key: 'crop_coconut',
      title: 'Coconut',
      assetPath: 'assets/thumbnails/crop_coconut.webp',
      categoryGroup: 'crops',
      keywords: ['coconut', 'nariyal', 'thengai', 'tender coconut', 'elaneer', 'copra', 'daak'],
    ),
    ThumbnailLibraryItem(
      key: 'crop_paddy',
      title: 'Paddy / Rice',
      assetPath: 'assets/thumbnails/crop_paddy.webp',
      categoryGroup: 'crops',
      keywords: ['paddy', 'rice', 'dhaan', 'sona masoori', 'basmati', 'chawal', 'paddy grain'],
    ),
    ThumbnailLibraryItem(
      key: 'crop_sugarcane',
      title: 'Sugarcane',
      assetPath: 'assets/thumbnails/crop_sugarcane.webp',
      categoryGroup: 'crops',
      keywords: ['sugarcane', 'ganna', 'karumbu', 'cane', 'sugar cane'],
    ),
    ThumbnailLibraryItem(
      key: 'crop_banana',
      title: 'Banana',
      assetPath: 'assets/thumbnails/crop_banana.webp',
      categoryGroup: 'crops',
      keywords: ['banana', 'kela', 'yelakki', 'robusta', 'plantain', 'nendran'],
    ),
    ThumbnailLibraryItem(
      key: 'crop_cardamom',
      title: 'Cardamom',
      assetPath: 'assets/thumbnails/crop_cardamom.webp',
      categoryGroup: 'crops',
      keywords: ['cardamom', 'elaichi', 'elakki', 'green cardamom', 'spices'],
    ),

    // -------------------------------------------------------------------------
    // 5. RESOURCES & EQUIPMENT
    // -------------------------------------------------------------------------
    ThumbnailLibraryItem(
      key: 'equipment_tractor',
      title: 'Tractor & Rotavator',
      assetPath: 'assets/thumbnails/equipment_tractor.webp',
      categoryGroup: 'equipment',
      keywords: ['tractor', 'rotavator', 'cultivator', 'plough', 'tillage', 'farm tractor'],
    ),
    ThumbnailLibraryItem(
      key: 'equipment_harvester',
      title: 'Harvester',
      assetPath: 'assets/thumbnails/equipment_harvester.webp',
      categoryGroup: 'equipment',
      keywords: ['harvester', 'combine harvester', 'reaper', 'threshing', 'harvest machine'],
    ),
    ThumbnailLibraryItem(
      key: 'equipment_drone',
      title: 'Agricultural Drone',
      assetPath: 'assets/thumbnails/equipment_drone.webp',
      categoryGroup: 'equipment',
      keywords: ['drone', 'agri drone', 'spray drone', 'uav', 'spraying drone', 'agriculture drone'],
    ),
    ThumbnailLibraryItem(
      key: 'resource_seeds',
      title: 'Seeds & Seedlings',
      assetPath: 'assets/thumbnails/resource_seeds.webp',
      categoryGroup: 'equipment',
      keywords: ['seeds', 'seed', 'hybrid seeds', 'seedlings', 'nursery plants', 'certified seeds'],
    ),
    ThumbnailLibraryItem(
      key: 'resource_fertilizer',
      title: 'Fertilizer & Vermicompost',
      assetPath: 'assets/thumbnails/resource_fertilizer.webp',
      categoryGroup: 'equipment',
      keywords: ['fertilizer', 'compost', 'vermicompost', 'organic manure', 'biofertilizer', 'npk', 'soil nutrient'],
    ),
    ThumbnailLibraryItem(
      key: 'resource_cold_storage',
      title: 'Cold Storage',
      assetPath: 'assets/thumbnails/resource_cold_storage.webp',
      categoryGroup: 'equipment',
      keywords: ['cold storage', 'refrigerated warehouse', 'chilling unit', 'storage facility', 'cold room'],
    ),

    // -------------------------------------------------------------------------
    // 6. GENERIC FALLBACK
    // -------------------------------------------------------------------------
    ThumbnailLibraryItem(
      key: 'fallback_generic',
      title: 'Udyoga Sethu Bridge',
      assetPath: 'assets/thumbnails/fallback_generic.webp',
      categoryGroup: 'fallback',
      keywords: ['general', 'default', 'bridge', 'work', 'job', 'task', 'udyoga sethu'],
    ),
  ];

  /// Find item by exact key
  static ThumbnailLibraryItem? findByKey(String? key) {
    if (key == null || key.isEmpty) return null;
    return items.where((it) => it.key.toLowerCase() == key.toLowerCase()).firstOrNull;
  }

  /// Resolve job thumbnail matching the strict source order:
  /// (a) Poster uploaded photo (if remote URL or custom file)
  /// (b) Dedicated illustration for exact title / keyword
  /// (c) Dedicated illustration for category
  /// (d) Generic fallback
  static ThumbnailResolution resolveJob({
    String? thumbnailPath,
    String? sitePhotoUrl,
    String? title,
    String? categorySlug,
    String? description,
  }) {
    // 1. Explicitly uploaded custom photo
    final customUrl = (thumbnailPath != null && thumbnailPath.trim().isNotEmpty)
        ? thumbnailPath.trim()
        : (sitePhotoUrl != null && sitePhotoUrl.trim().isNotEmpty ? sitePhotoUrl.trim() : null);

    if (customUrl != null) {
      if (customUrl.startsWith('http') || customUrl.contains('listing-images') || customUrl.contains('avatars')) {
        return ThumbnailResolution.network(url: customUrl);
      }
      // Check if it's a known library key or asset path
      if (customUrl.startsWith('assets/thumbnails/')) {
        final item = items.where((it) => it.assetPath == customUrl).firstOrNull;
        return ThumbnailResolution.asset(
          assetPath: customUrl,
          itemKey: item?.key ?? 'custom',
          hasBakedInTitle: item?.hasBakedInTitle ?? false,
        );
      }
      final itemByKey = findByKey(customUrl);
      if (itemByKey != null) {
        return ThumbnailResolution.asset(
          assetPath: itemByKey.assetPath,
          itemKey: itemByKey.key,
          hasBakedInTitle: itemByKey.hasBakedInTitle,
        );
      }
    }

    final searchCorpus = '${title ?? ''} ${description ?? ''}'.toLowerCase();
    final cleanCatKey = (categorySlug ?? '').toLowerCase().replaceAll('-', '_');
    final cleanCatText = (categorySlug ?? '').toLowerCase().replaceAll('-', ' ').replaceAll('_', ' ');

    // 2. Dedicated illustration for exact title if one exists (Check gigs & title keywords)
    final gigsAndSpecific = items.where((it) => it.categoryGroup == 'gigs').toList();
    for (final item in gigsAndSpecific) {
      for (final kw in item.keywords) {
        if (_matchesKeyword(searchCorpus, kw) || _matchesKeyword(cleanCatText, kw)) {
          return ThumbnailResolution.asset(
            assetPath: item.assetPath,
            itemKey: item.key,
            hasBakedInTitle: item.hasBakedInTitle,
          );
        }
      }
    }

    // 3. Category match
    // Direct key match on service categories
    final directCat = items.where((it) => it.key == cleanCatKey).firstOrNull;
    if (directCat != null) {
      return ThumbnailResolution.asset(
        assetPath: directCat.assetPath,
        itemKey: directCat.key,
        hasBakedInTitle: directCat.hasBakedInTitle,
      );
    }

    // Category keyword match across services (with word boundaries)
    for (final item in items.where((it) => it.categoryGroup == 'services')) {
      for (final kw in item.keywords) {
        if (_matchesKeyword(cleanCatText, kw) || _matchesKeyword(searchCorpus, kw)) {
          return ThumbnailResolution.asset(
            assetPath: item.assetPath,
            itemKey: item.key,
            hasBakedInTitle: item.hasBakedInTitle,
          );
        }
      }
    }

    // 4. Generic fallback
    return const ThumbnailResolution.asset(
      assetPath: fallbackAsset,
      itemKey: 'fallback_generic',
      hasBakedInTitle: false,
    );
  }

  /// Safe word boundary matching to avoid partial substring false positives
  static bool _matchesKeyword(String text, String keyword) {
    if (keyword.isEmpty || text.isEmpty) return false;
    final escaped = RegExp.escape(keyword.trim().toLowerCase());
    final pattern = RegExp('(^|[^a-zA-Z0-9])$escaped(s|es)?([^a-zA-Z0-9]|\$)', caseSensitive: false);
    return pattern.hasMatch(text.toLowerCase());
  }

  /// Resolve produce thumbnail
  static ThumbnailResolution resolveProduce({
    String? imageUrl,
    List<String>? images,
    String? name,
    String? category,
  }) {
    // 1. Uploaded photo
    if (imageUrl != null && imageUrl.trim().isNotEmpty && imageUrl.startsWith('http')) {
      return ThumbnailResolution.network(url: imageUrl.trim());
    }
    if (images != null && images.isNotEmpty) {
      final first = images.first;
      if (first.trim().isNotEmpty && first.startsWith('http')) {
        return ThumbnailResolution.network(url: first.trim());
      }
    }

    final query = '${name ?? ''} ${category ?? ''}'.toLowerCase();

    // 2. Specific crop match in data
    final crops = items.where((it) => it.categoryGroup == 'crops');
    for (final crop in crops) {
      for (final kw in crop.keywords) {
        if (_matchesKeyword(query, kw)) {
          return ThumbnailResolution.asset(
            assetPath: crop.assetPath,
            itemKey: crop.key,
            hasBakedInTitle: false,
          );
        }
      }
    }

    // 3. Produce category match
    final produceCats = items.where((it) => it.categoryGroup == 'produce');
    for (final pCat in produceCats) {
      for (final kw in pCat.keywords) {
        if (_matchesKeyword(query, kw)) {
          return ThumbnailResolution.asset(
            assetPath: pCat.assetPath,
            itemKey: pCat.key,
            hasBakedInTitle: false,
          );
        }
      }
    }

    // 4. Default produce fallback
    return const ThumbnailResolution.asset(
      assetPath: 'assets/thumbnails/produce_vegetables.webp',
      itemKey: 'produce_vegetables',
      hasBakedInTitle: false,
    );
  }

  /// Resolve crop thumbnail for mandi prices and agricultural crop cards
  static ThumbnailResolution resolveCrop({
    required String commodity,
    String? category,
  }) {
    final query = '$commodity ${category ?? ''}'.toLowerCase();

    // 1. Direct match with specific crops
    final crops = items.where((it) => it.categoryGroup == 'crops');
    for (final crop in crops) {
      for (final kw in crop.keywords) {
        if (_matchesKeyword(query, kw)) {
          return ThumbnailResolution.asset(
            assetPath: crop.assetPath,
            itemKey: crop.key,
            hasBakedInTitle: false,
          );
        }
      }
    }

    // 2. Fall back to produce categories
    final produceCats = items.where((it) => it.categoryGroup == 'produce');
    for (final pCat in produceCats) {
      for (final kw in pCat.keywords) {
        if (_matchesKeyword(query, kw)) {
          return ThumbnailResolution.asset(
            assetPath: pCat.assetPath,
            itemKey: pCat.key,
            hasBakedInTitle: false,
          );
        }
      }
    }

    // 3. Fallback realistic farm crop photograph
    return const ThumbnailResolution.asset(
      assetPath: 'assets/thumbnails/produce_vegetables.webp',
      itemKey: 'produce_vegetables',
      hasBakedInTitle: false,
    );
  }

  /// Resolve resource / equipment thumbnail
  static ThumbnailResolution resolveResource({
    String? imageUrl,
    String? title,
    String? resourceType,
  }) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty && imageUrl.startsWith('http')) {
      return ThumbnailResolution.network(url: imageUrl.trim());
    }

    final query = '${title ?? ''} ${resourceType ?? ''}'.toLowerCase();
    final equipment = items.where((it) => it.categoryGroup == 'equipment');
    for (final eq in equipment) {
      for (final kw in eq.keywords) {
        if (_matchesKeyword(query, kw)) {
          return ThumbnailResolution.asset(
            assetPath: eq.assetPath,
            itemKey: eq.key,
            hasBakedInTitle: false,
          );
        }
      }
    }

    return const ThumbnailResolution.asset(
      assetPath: 'assets/thumbnails/equipment_tractor.webp',
      itemKey: 'equipment_tractor',
      hasBakedInTitle: false,
    );
  }

  /// Suggests the best illustration for a new job being posted
  static ThumbnailLibraryItem suggestJobIllustration({
    String? title,
    String? categoryName,
    String? categorySlug,
  }) {
    final res = resolveJob(
      title: title,
      categorySlug: categorySlug ?? categoryName,
    );
    if (!res.isNetwork && res.itemKey != null) {
      final found = findByKey(res.itemKey);
      if (found != null) return found;
    }
    return items.first;
  }

  /// Pre-caches top and service thumbnails for instant display without jank
  static void precacheTopThumbnails(BuildContext context) {
    const topAssets = [
      'assets/thumbnails/campus_ambassador.webp',
      'assets/thumbnails/construction.webp',
      'assets/thumbnails/delivery.webp',
      'assets/thumbnails/plumbing.webp',
      'assets/thumbnails/electrician.webp',
      'assets/thumbnails/painting.webp',
      'assets/thumbnails/cleaner.webp',
      'assets/thumbnails/agri_labour.webp',
      'assets/thumbnails/produce_vegetables.webp',
      'assets/thumbnails/produce_fruits.webp',
      'assets/thumbnails/equipment_tractor.webp',
      'assets/thumbnails/fallback_generic.webp',
    ];
    for (final path in topAssets) {
      try {
        precacheImage(AssetImage(path), context);
      } catch (_) {}
    }
  }
}

/// Resolved thumbnail data
class ThumbnailResolution {
  final bool isNetwork;
  final String? networkUrl;
  final String? assetPath;
  final String? itemKey;
  final bool hasBakedInTitle;

  const ThumbnailResolution.network({
    required String url,
    this.itemKey,
  })  : isNetwork = true,
        networkUrl = url,
        assetPath = null,
        hasBakedInTitle = false;

  const ThumbnailResolution.asset({
    required String this.assetPath,
    this.itemKey,
    this.hasBakedInTitle = false,
  })  : isNetwork = false,
        networkUrl = null;
}
