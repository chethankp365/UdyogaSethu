// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

class CommodityDef {
  final String slug;
  final String name;
  final String category;
  final String emoji;
  final int color1;
  final int color2;
  final String defaultUnit;
  final List<String> keywords;

  const CommodityDef({
    required this.slug,
    required this.name,
    required this.category,
    required this.emoji,
    required this.color1,
    required this.color2,
    this.defaultUnit = 'kg',
    required this.keywords,
  });

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'category': category,
        'emoji': emoji,
        'assetPath': 'assets/images/commodities/$slug.webp',
        'defaultUnit': defaultUnit,
        'keywords': keywords,
      };
}

const List<CommodityDef> commodities = [
  // 1-14 Vegetables
  CommodityDef(
    slug: 'tomato',
    name: 'Tomato',
    category: 'Vegetables',
    emoji: '🍅',
    color1: 0xFFE53935,
    color2: 0xFFFF8A80,
    keywords: ['tomato', 'tomatoes', 'hybrid tomato', 'desi tomato'],
  ),
  CommodityDef(
    slug: 'onion',
    name: 'Onion',
    category: 'Vegetables',
    emoji: '🧅',
    color1: 0xFF8E24AA,
    color2: 0xFFE1BEE7,
    keywords: ['onion', 'onions', 'red onion', 'bellary onion', 'nasik onion'],
  ),
  CommodityDef(
    slug: 'potato',
    name: 'Potato',
    category: 'Vegetables',
    emoji: '🥔',
    color1: 0xFF8D6E63,
    color2: 0xFFD7CCC8,
    keywords: ['potato', 'potatoes', 'jyoti potato', 'baby potato'],
  ),
  CommodityDef(
    slug: 'green_chilli',
    name: 'Green Chilli',
    category: 'Vegetables',
    emoji: '🌶️',
    color1: 0xFF2E7D32,
    color2: 0xFFA5D6A7,
    keywords: ['green chilli', 'chilli', 'mirchi', 'g4 chilli'],
  ),
  CommodityDef(
    slug: 'carrot',
    name: 'Carrot',
    category: 'Vegetables',
    emoji: '🥕',
    color1: 0xFFEF6C00,
    color2: 0xFFFFCC80,
    keywords: ['carrot', 'carrots', 'orange carrot', 'desi carrot'],
  ),
  CommodityDef(
    slug: 'cabbage',
    name: 'Cabbage',
    category: 'Vegetables',
    emoji: '🥬',
    color1: 0xFF43A047,
    color2: 0xFFC8E6C9,
    keywords: ['cabbage', 'green cabbage'],
  ),
  CommodityDef(
    slug: 'cauliflower',
    name: 'Cauliflower',
    category: 'Vegetables',
    emoji: '🥦',
    color1: 0xFF558B2F,
    color2: 0xFFDCEDC8,
    keywords: ['cauliflower', 'gobi'],
  ),
  CommodityDef(
    slug: 'beans',
    name: 'French Beans',
    category: 'Vegetables',
    emoji: '🫘',
    color1: 0xFF388E3C,
    color2: 0xFFA5D6A7,
    keywords: ['beans', 'french beans', 'ring beans'],
  ),
  CommodityDef(
    slug: 'brinjal',
    name: 'Brinjal / Eggplant',
    category: 'Vegetables',
    emoji: '🍆',
    color1: 0xFF4A148C,
    color2: 0xFFCE93D8,
    keywords: ['brinjal', 'eggplant', 'baingan', 'purple brinjal'],
  ),
  CommodityDef(
    slug: 'beetroot',
    name: 'Beetroot',
    category: 'Vegetables',
    emoji: '🫒',
    color1: 0xFF880E4F,
    color2: 0xFFF48FB1,
    keywords: ['beetroot', 'beet'],
  ),
  CommodityDef(
    slug: 'cucumber',
    name: 'Cucumber',
    category: 'Vegetables',
    emoji: '🥒',
    color1: 0xFF2E7D32,
    color2: 0xFFC8E6C9,
    keywords: ['cucumber', 'kheera', 'green cucumber'],
  ),
  CommodityDef(
    slug: 'capsicum',
    name: 'Capsicum / Bell Pepper',
    category: 'Vegetables',
    emoji: '🫑',
    color1: 0xFF1B5E20,
    color2: 0xFF81C784,
    keywords: ['capsicum', 'bell pepper', 'shimla mirch'],
  ),
  CommodityDef(
    slug: 'garlic',
    name: 'Garlic',
    category: 'Vegetables',
    emoji: '🧄',
    color1: 0xFF795548,
    color2: 0xFFEFEBE9,
    keywords: ['garlic', 'lahsun', 'desi garlic'],
  ),
  CommodityDef(
    slug: 'ginger',
    name: 'Ginger',
    category: 'Vegetables',
    emoji: '🫚',
    color1: 0xFFB45309,
    color2: 0xFFFDE68A,
    keywords: ['ginger', 'adrak', 'fresh ginger'],
  ),

  // 15-21 Cereals & Grains
  CommodityDef(
    slug: 'rice',
    name: 'Rice',
    category: 'Cereals & Grains',
    emoji: '🌾',
    color1: 0xFFD97706,
    color2: 0xFFFEF3C7,
    keywords: ['rice', 'sona masoori', 'basmati', 'raw rice'],
  ),
  CommodityDef(
    slug: 'paddy',
    name: 'Paddy',
    category: 'Cereals & Grains',
    emoji: '🌾',
    color1: 0xFFB45309,
    color2: 0xFFFDE68A,
    defaultUnit: 'qtl',
    keywords: ['paddy', 'dhan', 'unhusked paddy'],
  ),
  CommodityDef(
    slug: 'wheat',
    name: 'Wheat',
    category: 'Cereals & Grains',
    emoji: '🌾',
    color1: 0xFFCA8A04,
    color2: 0xFFFEF08A,
    defaultUnit: 'qtl',
    keywords: ['wheat', 'gehun', 'sharbati wheat'],
  ),
  CommodityDef(
    slug: 'ragi',
    name: 'Finger Millet (Ragi)',
    category: 'Cereals & Grains',
    emoji: '🌾',
    color1: 0xFF78350F,
    color2: 0xFFFCD34D,
    keywords: ['ragi', 'finger millet', 'nachni'],
  ),
  CommodityDef(
    slug: 'maize',
    name: 'Maize / Corn',
    category: 'Cereals & Grains',
    emoji: '🌽',
    color1: 0xFFEAB308,
    color2: 0xFFFEF08A,
    defaultUnit: 'qtl',
    keywords: ['maize', 'corn', 'makka', 'sweet corn'],
  ),
  CommodityDef(
    slug: 'jowar',
    name: 'Sorghum (Jowar)',
    category: 'Cereals & Grains',
    emoji: '🌾',
    color1: 0xFF92400E,
    color2: 0xFFFDE68A,
    defaultUnit: 'qtl',
    keywords: ['jowar', 'sorghum', 'white jowar'],
  ),
  CommodityDef(
    slug: 'bajra',
    name: 'Pearl Millet (Bajra)',
    category: 'Cereals & Grains',
    emoji: '🌾',
    color1: 0xFF854D0E,
    color2: 0xFFFEF9C3,
    defaultUnit: 'qtl',
    keywords: ['bajra', 'pearl millet', 'sajje'],
  ),

  // 22-25 Pulses
  CommodityDef(
    slug: 'red_gram',
    name: 'Red Gram / Tur Dal',
    category: 'Pulses',
    emoji: '🥣',
    color1: 0xFFEA580C,
    color2: 0xFFFFEDD5,
    defaultUnit: 'qtl',
    keywords: ['red gram', 'tur dal', 'toor dal', 'arhar'],
  ),
  CommodityDef(
    slug: 'bengal_gram',
    name: 'Bengal Gram / Chana',
    category: 'Pulses',
    emoji: '🥣',
    color1: 0xFFD97706,
    color2: 0xFFFEF3C7,
    defaultUnit: 'qtl',
    keywords: ['bengal gram', 'chana', 'chickpea'],
  ),
  CommodityDef(
    slug: 'green_gram',
    name: 'Green Gram / Moong',
    category: 'Pulses',
    emoji: '🥣',
    color1: 0xFF16A34A,
    color2: 0xFFDCFCE7,
    keywords: ['green gram', 'moong', 'mung bean'],
  ),
  CommodityDef(
    slug: 'black_gram',
    name: 'Black Gram / Urad',
    category: 'Pulses',
    emoji: '🥣',
    color1: 0xFF1E293B,
    color2: 0xFF94A3B8,
    keywords: ['black gram', 'urad', 'black dal'],
  ),

  // 26-28 Oilseeds
  CommodityDef(
    slug: 'groundnut',
    name: 'Groundnut / Peanut',
    category: 'Oilseeds',
    emoji: '🥜',
    color1: 0xFFB45309,
    color2: 0xFFFED7AA,
    keywords: ['groundnut', 'peanut', 'moongfali'],
  ),
  CommodityDef(
    slug: 'soybean',
    name: 'Soybean',
    category: 'Oilseeds',
    emoji: '🫘',
    color1: 0xFF65A30D,
    color2: 0xFFECFCCB,
    defaultUnit: 'qtl',
    keywords: ['soybean', 'soya', 'yellow soybean'],
  ),
  CommodityDef(
    slug: 'sunflower',
    name: 'Sunflower Seed',
    category: 'Oilseeds',
    emoji: '🌻',
    color1: 0xFFCA8A04,
    color2: 0xFFFEF08A,
    defaultUnit: 'qtl',
    keywords: ['sunflower', 'sunflower seed'],
  ),

  // 29-30 Commercial
  CommodityDef(
    slug: 'sugarcane',
    name: 'Sugarcane',
    category: 'Commercial',
    emoji: '🎋',
    color1: 0xFF15803D,
    color2: 0xFFBBF7D0,
    defaultUnit: 'tonne',
    keywords: ['sugarcane', 'cane', 'co 86032'],
  ),
  CommodityDef(
    slug: 'cotton',
    name: 'Cotton',
    category: 'Commercial',
    emoji: '🧶',
    color1: 0xFF0284C7,
    color2: 0xFFE0F2FE,
    defaultUnit: 'qtl',
    keywords: ['cotton', 'kapas', 'dch-32'],
  ),

  // 31-33 Plantation
  CommodityDef(
    slug: 'coconut',
    name: 'Coconut',
    category: 'Plantation',
    emoji: '🥥',
    color1: 0xFF78350F,
    color2: 0xFFFDE68A,
    defaultUnit: 'piece',
    keywords: ['coconut', 'tender coconut', 'copra'],
  ),
  CommodityDef(
    slug: 'arecanut',
    name: 'Arecanut / Betel Nut',
    category: 'Plantation',
    emoji: '🌰',
    color1: 0xFF991B1B,
    color2: 0xFFFECACA,
    defaultUnit: 'qtl',
    keywords: ['arecanut', 'supari', 'betel nut', 'rashi'],
  ),
  CommodityDef(
    slug: 'coffee',
    name: 'Coffee Beans',
    category: 'Plantation',
    emoji: '☕',
    color1: 0xFF451A03,
    color2: 0xFFD7CCC8,
    keywords: ['coffee', 'arabica', 'robusta coffee'],
  ),

  // 34-36 Spices
  CommodityDef(
    slug: 'black_pepper',
    name: 'Black Pepper',
    category: 'Spices',
    emoji: '🌿',
    color1: 0xFF0F172A,
    color2: 0xFF64748B,
    keywords: ['black pepper', 'pepper', 'kali mirch'],
  ),
  CommodityDef(
    slug: 'cardamom',
    name: 'Green Cardamom',
    category: 'Spices',
    emoji: '🫚',
    color1: 0xFF15803D,
    color2: 0xFF86EFAC,
    keywords: ['cardamom', 'elaichi', 'green cardamom'],
  ),
  CommodityDef(
    slug: 'turmeric',
    name: 'Turmeric',
    category: 'Spices',
    emoji: '🧂',
    color1: 0xFFD97706,
    color2: 0xFFFDE68A,
    keywords: ['turmeric', 'haldi', 'yellow turmeric'],
  ),

  // 37-40 Fruits
  CommodityDef(
    slug: 'banana',
    name: 'Banana',
    category: 'Fruits',
    emoji: '🍌',
    color1: 0xFFEAB308,
    color2: 0xFFFEF08A,
    defaultUnit: 'dozen',
    keywords: ['banana', 'elakki banana', 'robusta banana', 'rasabale'],
  ),
  CommodityDef(
    slug: 'mango',
    name: 'Mango',
    category: 'Fruits',
    emoji: '🥭',
    color1: 0xFFF97316,
    color2: 0xFFFED7AA,
    keywords: ['mango', 'alphonso', 'badami', 'kesar mango'],
  ),
  CommodityDef(
    slug: 'papaya',
    name: 'Papaya',
    category: 'Fruits',
    emoji: '🍈',
    color1: 0xFFEA580C,
    color2: 0xFFFFEDD5,
    keywords: ['papaya', 'red lady papaya'],
  ),
  CommodityDef(
    slug: 'pomegranate',
    name: 'Pomegranate',
    category: 'Fruits',
    emoji: '🍎',
    color1: 0xFFBE123C,
    color2: 0xFFFECDD3,
    keywords: ['pomegranate', 'anar', 'bhagwa pomegranate'],
  ),
];

void main() async {
  final commoditiesDir = Directory('assets/images/commodities');
  if (!commoditiesDir.existsSync()) {
    commoditiesDir.createSync(recursive: true);
  }

  print('Generating 40 Commodity WebP assets (600x600) in ${commoditiesDir.path}...');

  for (final item in commodities) {
    final fileName = '${item.slug}.webp';
    final file = File('${commoditiesDir.path}/$fileName');

    // Create 600x600 canvas
    final image = img.Image(width: 600, height: 600);

    final c1 = item.color1;
    final c2 = item.color2;

    // Draw rich radiant agricultural background gradient
    for (int y = 0; y < 600; y++) {
      for (int x = 0; x < 600; x++) {
        // Radial & linear mix for pleasant organic glow
        final dx = (x - 300) / 300.0;
        final dy = (y - 300) / 300.0;
        final dist = sqrt(dx * dx + dy * dy).clamp(0.0, 1.4) / 1.4;

        final t = (dist * 0.7 + (y / 600.0) * 0.3).clamp(0.0, 1.0);
        final r = (((c2 >> 16) & 0xFF) * (1 - t) + ((c1 >> 16) & 0xFF) * t).round();
        final g = (((c2 >> 8) & 0xFF) * (1 - t) + ((c1 >> 8) & 0xFF) * t).round();
        final b = ((c2 & 0xFF) * (1 - t) + (c1 & 0xFF) * t).round();

        // Subtle micro-pattern
        final pattern = ((x * 19 + y * 23) % 9) - 4;
        final fr = (r + pattern).clamp(0, 255);
        final fg = (g + pattern).clamp(0, 255);
        final fb = (b + pattern).clamp(0, 255);

        image.setPixelRgba(x, y, fr, fg, fb, 255);
      }
    }

    // Inner soft container frame
    const pad = 48;
    for (int cy = pad; cy < 600 - pad; cy++) {
      for (int cx = pad; cx < 600 - pad; cx++) {
        final pixel = image.getPixel(cx, cy);
        final cr = (pixel.r * 0.88 + 255 * 0.12).round().clamp(0, 255);
        final cg = (pixel.g * 0.88 + 255 * 0.12).round().clamp(0, 255);
        final cb = (pixel.b * 0.88 + 255 * 0.12).round().clamp(0, 255);
        image.setPixelRgba(cx, cy, cr, cg, cb, 255);
      }
    }

    // Encode as high-quality WebP
    final webpBytes = img.encodeWebP(image, quality: 80);
    file.writeAsBytesSync(webpBytes);
    print('  ✓ [${item.category}] ${item.name} -> $fileName (${(webpBytes.length / 1024).toStringAsFixed(1)} KB)');
  }

  // Generate manifest.json
  final manifestFile = File('${commoditiesDir.path}/manifest.json');
  final manifestData = {
    'version': '1.0.0',
    'total': commodities.length,
    'commodities': commodities.map((c) => c.toJson()).toList(),
  };

  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifestData),
  );
  print('Saved commodities manifest: ${manifestFile.path} (${commodities.length} items)');
}
