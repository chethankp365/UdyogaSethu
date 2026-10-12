import 'package:flutter/material.dart';
import 'package:udyogasethu/core/services/thumbnail_library.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';

/// Modal bottom sheet allowing users to browse and pick any illustrated thumbnail from the library
class ThumbnailPickerSheet extends StatefulWidget {
  final String? initialSelectedKey;
  final ValueChanged<ThumbnailLibraryItem> onSelected;

  const ThumbnailPickerSheet({
    super.key,
    this.initialSelectedKey,
    required this.onSelected,
  });

  static Future<ThumbnailLibraryItem?> show(
    BuildContext context, {
    String? initialSelectedKey,
    String? selectedAssetPath,
  }) {
    String? key = initialSelectedKey;
    if (key == null && selectedAssetPath != null) {
      final match = ThumbnailLibrary.items.where((i) => i.assetPath == selectedAssetPath).firstOrNull;
      key = match?.key;
    }
    return showModalBottomSheet<ThumbnailLibraryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ThumbnailPickerSheet(
        initialSelectedKey: key,
        onSelected: (item) => Navigator.pop(ctx, item),
      ),
    );
  }

  @override
  State<ThumbnailPickerSheet> createState() => _ThumbnailPickerSheetState();
}

class _ThumbnailPickerSheetState extends State<ThumbnailPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'all',
    'services',
    'gigs',
    'produce',
    'crops',
    'equipment',
  ];

  final Map<String, String> _tabLabels = {
    'all': 'All (41)',
    'services': 'Services (12)',
    'gigs': 'Student & Gigs (8)',
    'produce': 'Farm Produce (6)',
    'crops': 'Crops (8)',
    'equipment': 'Equipment (6)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ThumbnailLibraryItem> _getFilteredItems(String categoryGroup) {
    var list = ThumbnailLibrary.items;
    if (categoryGroup != 'all') {
      list = list.where((it) => it.categoryGroup == categoryGroup).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((it) {
        return it.title.toLowerCase().contains(q) ||
            it.key.toLowerCase().contains(q) ||
            it.keywords.any((k) => k.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.collections_rounded, color: AppColors.headerGreenDark, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Choose Cover Illustration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search thumbnails (e.g. Tutor, Tomato, Plumbing)...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.headerGreenDark,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppColors.headerGreenDark,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: _categories.map((c) => Tab(text: _tabLabels[c])).toList(),
          ),

          const Divider(height: 1),

          // Grid views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final items = _getFilteredItems(cat);
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching illustrations found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 16 / 11, // 16:9 image + title caption below
                  ),
                  itemCount: items.length,
                  itemBuilder: (ctx, idx) {
                    final it = items[idx];
                    final isSelected = widget.initialSelectedKey == it.key;

                    return InkWell(
                      onTap: () => widget.onSelected(it),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.headerGreenDark : const Color(0xFFE2E8F0),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 16:9 Image
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                    child: Image.asset(
                                      it.assetPath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.headerGreenDark,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Title label
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              color: isSelected ? const Color(0xFFE6F4EA) : Colors.white,
                              child: Text(
                                it.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
