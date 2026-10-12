import 'package:flutter/material.dart';
import 'package:udyogasethu/core/services/thumbnail_library.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/app_thumbnail.dart';

/// Debug-only gallery screen at `/dev/thumbnails` showing all 41 thumbnails
/// with sample titles across English, Kannada, Hindi, Tamil, and Telugu,
/// at Card, Header, and Small sizes.
class DebugThumbnailGalleryScreen extends StatefulWidget {
  const DebugThumbnailGalleryScreen({super.key});

  @override
  State<DebugThumbnailGalleryScreen> createState() => _DebugThumbnailGalleryScreenState();
}

class _DebugThumbnailGalleryScreenState extends State<DebugThumbnailGalleryScreen> {
  ThumbnailSize _selectedSize = ThumbnailSize.card;
  String _selectedLocale = 'en';
  String _selectedCategory = 'all';

  final Map<String, String> _languages = {
    'en': 'English',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'hi': 'हिंदी (Hindi)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
  };

  // Sample titles in 5 languages per item
  final Map<String, Map<String, String>> _sampleTitles = {
    'campus_ambassador': {
      'en': 'Campus Ambassador - College Fest 2026',
      'kn': 'ಕ್ಯಾಂಪಸ್ ರಾಯಭಾರಿ - ಕಾಲೇಜು ಉತ್ಸವ 2026',
      'hi': 'कैंपस एंबेसडर - कॉलेज फेस्ट 2026',
      'ta': 'கேம்பஸ் தூதர் - கல்லூரி விழா 2026',
      'te': 'క్యాంపస్ అంబాసిడర్ - కాలేజీ ఫెస్ట్ 2026',
    },
    'construction': {
      'en': 'Site Construction Worker & Masonry',
      'kn': 'ಕಟ್ಟಡ ನಿರ್ಮಾಣ ಕಾರ್ಮಿಕ ಮತ್ತು ಗಾರೆ ಕೆಲಸ',
      'hi': 'भवन निर्माण श्रमिक एवं चिनाई कार्य',
      'ta': 'கட்டிட கட்டுமான தொழிலாளி & கொத்தனார்',
      'te': 'భవన నిర్మాణ కార్మికుడు & తాపీ పని',
    },
    'plumbing': {
      'en': 'Emergency Pipeline & Bathroom Plumbing',
      'kn': 'ತುರ್ತು ಪೈಪ್‌ಲೈನ್ ಮತ್ತು ಬಾತ್‌ರೂಮ್ ಪ್ಲಂಬಿಂಗ್',
      'hi': 'आपातकालीन पाइपलाइन एवं नलसाजी',
      'ta': 'அவசர குழாய் பழுதுபார்ப்பு & பிளம்பிங்',
      'te': 'ఎమర్జెన్సీ పైప్‌లైన్ మరియు ప్లంబింగ్ పని',
    },
    'painting': {
      'en': 'Interior Wall & Exterior House Painter',
      'kn': 'ಒಳಾಂಗಣ ಗೋಡೆ ಮತ್ತು ಬಣ್ಣ ಬಳಿಯುವ ಕೆಲಸ',
      'hi': 'आंतरिक दीवार एवं घर रंगाई पुताई',
      'ta': 'உட்புற சுவர் மற்றும் வீட்டு பெயிண்டர்',
      'te': 'ఇంటి లోపల మరియు బయట పెయింటింగ్ పని',
    },
    'electrician': {
      'en': 'Master Electrician & Switchboard Wiring',
      'kn': 'ನುರಿತ ಎಲೆಕ್ಟ್ರಿಷಿಯನ್ ಮತ್ತು ವೈರಿಂಗ್ ಕೆಲಸ',
      'hi': 'अनुभवी इलेक्ट्रीशियन एवं वायरिंग कार्य',
      'ta': 'தலைசிறந்த எலக்ட்ரீஷியன் & வயரிங்',
      'te': 'నిపుణుడైన ఎలక్ట్రీషియన్ మరియు వైరింగ్',
    },
    'delivery': {
      'en': 'Express Parcel Delivery & Courier Rider',
      'kn': 'ತ್ವರಿತ ಪಾರ್ಸೆಲ್ ಡೆಲಿವರಿ ಮತ್ತು ಕೊರಿಯರ್',
      'hi': 'त्वरित पार्सल डिलीवरी एवं कूरियर राइडर',
      'ta': 'விரைவு பார்சல் டெலிவரி & கூரியர் ரைடர்',
      'te': 'ఎక్స్‌ప్రెస్ పార్శిల్ డెలివరీ & కొరియర్',
    },
    'online_tutor': {
      'en': 'Maths & Science Online Tutor (Class 10)',
      'kn': 'ಗಣಿತ ಮತ್ತು ವಿಜ್ಞಾನ ಆನ್‌ಲೈನ್ ಟ್ಯೂಷನ್',
      'hi': 'गणित और विज्ञान ऑनलाइन ट्यूटर (कक्षा 10)',
      'ta': 'கணிதம் மற்றும் அறிவியல் ஆன்லைன் ஆசிரியர்',
      'te': 'గణితం మరియు సైన్స్ ఆన్‌లైన్ ట్యూటర్',
    },
    'produce_vegetables': {
      'en': 'Farm Fresh Organic Mixed Vegetables',
      'kn': 'ತೋಟದ ತಾಜಾ ಸಾವಯವ ಮಿಶ್ರ ತರಕಾರಿಗಳು',
      'hi': 'खेत की ताज़ा जैविक मिश्रित सब्ज़ियाँ',
      'ta': 'பண்ணை புதிய இயற்கை காய்கறிகள்',
      'te': 'తోట తాజా సేంద్రీయ కూరగాయలు',
    },
    'crop_tomato': {
      'en': 'Grade-A Fresh Vine Ripe Tomatoes',
      'kn': 'ಉತ್ತಮ ಗುಣಮಟ್ಟದ ನಾಟಿ ತಾಜಾ ಟೊಮೆಟೊ',
      'hi': 'उत्कृष्ट श्रेणी के ताज़ा देशी टमाटर',
      'ta': 'முதல் தர புதிய நாட்டு தக்காளி',
      'te': 'మంచి నాణ్యమైన తాజా టమాటాలు',
    },
    'equipment_tractor': {
      'en': '55HP Tractor with Rotary Tiller on Rent',
      'kn': 'ರೋಟಾವೇಟರ್ ಸಹಿತ ಟ್ರ್ಯಾಕ್ಟರ್ ಬಾಡಿಗೆಗೆ',
      'hi': 'रोटावेटर सहित ट्रैक्टर किराये पर',
      'ta': 'ரோட்டாவேட்டருடன் டிராக்டர் வாடகைக்கு',
      'te': 'రోటావ్రేటర్‌తో ట్రాక్టర్ అద్దెకు',
    },
  };

  String _getLocalizedTitle(ThumbnailLibraryItem item, String lang) {
    if (_sampleTitles.containsKey(item.key)) {
      return _sampleTitles[item.key]![lang] ?? item.title;
    }
    // Generic localized suffix
    switch (lang) {
      case 'kn':
        return '${item.title} (ತಾಜಾ / ಪರಿಶೀಲಿಸಿದ)';
      case 'hi':
        return '${item.title} (ताज़ा / सत्यापित)';
      case 'ta':
        return '${item.title} (சரிபார்க்கப்பட்டது)';
      case 'te':
        return '${item.title} (ధృవీకరించబడింది)';
      default:
        return 'Verified ${item.title} Listing';
    }
  }

  @override
  Widget build(BuildContext context) {
    var items = ThumbnailLibrary.items;
    if (_selectedCategory != 'all') {
      items = items.where((it) => it.categoryGroup == _selectedCategory).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Thumbnail Gallery (/dev/thumbnails)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Control Bar: Size & Language Switchers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                // Row 1: Size Switcher
                Row(
                  children: [
                    const Text('Size: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Card (16:9)'),
                      selected: _selectedSize == ThumbnailSize.card,
                      selectedColor: AppColors.headerGreenDark,
                      labelStyle: TextStyle(
                        color: _selectedSize == ThumbnailSize.card ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedSize = ThumbnailSize.card),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Header (Hero)'),
                      selected: _selectedSize == ThumbnailSize.header,
                      selectedColor: AppColors.headerGreenDark,
                      labelStyle: TextStyle(
                        color: _selectedSize == ThumbnailSize.header ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedSize = ThumbnailSize.header),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Small (Icon)'),
                      selected: _selectedSize == ThumbnailSize.small,
                      selectedColor: AppColors.headerGreenDark,
                      labelStyle: TextStyle(
                        color: _selectedSize == ThumbnailSize.small ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedSize = ThumbnailSize.small),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Language Switcher Dropdown & Category
                Row(
                  children: [
                    const Text('Lang: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedLocale,
                      underline: const SizedBox(),
                      style: const TextStyle(color: AppColors.headerGreenDark, fontWeight: FontWeight.bold, fontSize: 13),
                      items: _languages.entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLocale = val);
                      },
                    ),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      underline: const SizedBox(),
                      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All (41)')),
                        DropdownMenuItem(value: 'services', child: Text('Services (12)')),
                        DropdownMenuItem(value: 'gigs', child: Text('Gigs (8)')),
                        DropdownMenuItem(value: 'produce', child: Text('Produce (6)')),
                        DropdownMenuItem(value: 'crops', child: Text('Crops (8)')),
                        DropdownMenuItem(value: 'equipment', child: Text('Equipment (6)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemBuilder: (ctx, idx) {
                final it = items[idx];
                final sampleTitle = _getLocalizedTitle(it, _selectedLocale);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Meta Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '#${idx + 1} ${it.title} [${it.key}]',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              it.categoryGroup.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.headerGreenDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Rendered Thumbnail
                      Center(
                        child: _renderThumbnailForGallery(it, sampleTitle),
                      ),

                      const SizedBox(height: 10),
                      // Details row
                      Text(
                        'Asset: ${it.assetPath}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        'Baked-in Title: ${it.hasBakedInTitle ? "YES (Title Overlay Suppressed)" : "NO (Dynamic Outlined Pop Lettering)"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: it.hasBakedInTitle ? Colors.orange.shade800 : Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderThumbnailForGallery(ThumbnailLibraryItem item, String sampleTitle) {
    switch (_selectedSize) {
      case ThumbnailSize.header:
        return JobThumbnail(
          title: sampleTitle,
          thumbnailPath: item.assetPath,
          size: ThumbnailSize.header,
          height: 180,
          showTitle: true,
        );
      case ThumbnailSize.card:
        return SizedBox(
          width: 320,
          child: JobThumbnail(
            title: sampleTitle,
            thumbnailPath: item.assetPath,
            size: ThumbnailSize.card,
            height: 180,
            showTitle: true,
          ),
        );
      case ThumbnailSize.small:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            JobThumbnail(
              title: sampleTitle,
              thumbnailPath: item.assetPath,
              size: ThumbnailSize.small,
              width: 64,
              height: 64,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                sampleTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        );
    }
  }
}
