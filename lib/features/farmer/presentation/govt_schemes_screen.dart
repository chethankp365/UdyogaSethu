import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/farmer/data/farmer_ai_repository.dart';
import 'package:udyogasethu/features/farmer/domain/ai_assist_models.dart';

final govtSchemesProvider = FutureProvider.autoDispose<List<GovernmentScheme>>((ref) async {
  final repo = ref.watch(farmerAiRepositoryProvider);
  return repo.getCuratedSchemes();
});

class GovtSchemesScreen extends ConsumerStatefulWidget {
  const GovtSchemesScreen({super.key});

  @override
  ConsumerState<GovtSchemesScreen> createState() => _GovtSchemesScreenState();
}

class _GovtSchemesScreenState extends ConsumerState<GovtSchemesScreen> {
  String _selectedCategory = 'all';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openOfficialPortal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Error launching scheme URL: $e');
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open portal: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schemesAsync = ref.watch(govtSchemesProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Government Schemes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: schemesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading schemes: $err'),
          ),
        ),
        data: (schemes) {
          final query = _searchController.text.toLowerCase().trim();
          final filtered = schemes.where((s) {
            final matchesCategory = _selectedCategory == 'all' || s.category == _selectedCategory;
            final matchesQuery = query.isEmpty ||
                s.nameEn.toLowerCase().contains(query) ||
                s.nameKn.toLowerCase().contains(query) ||
                s.shortDescriptionEn.toLowerCase().contains(query) ||
                s.shortDescriptionKn.toLowerCase().contains(query);
            return matchesCategory && matchesQuery;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.account_balance_rounded, color: Color(0xFF7C3AED), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Government Welfare Schemes',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5B21B6)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Official government subsidy and credit schemes. Apply directly on authorized portals.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6D28D9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search schemes (e.g. KCC, PM-KISAN, Insurance)...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Schemes'),
                      _buildFilterChip('income_support', 'Income Support'),
                      _buildFilterChip('credit', 'Crop Loans (KCC)'),
                      _buildFilterChip('insurance', 'Crop Insurance'),
                      _buildFilterChip('soil', 'Soil Testing'),
                      _buildFilterChip('irrigation', 'Krishi Bhagya'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Curated Cards
                if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text('No schemes match your query.', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  )
                else
                  ...filtered.map((scheme) {
                    final localizedName = scheme.localizedName(currentLocale.languageCode);
                    final localizedDesc = scheme.localizedDescription(currentLocale.languageCode);

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE9FE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF7C3AED), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizedName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        scheme.category.toUpperCase().replaceAll('_', ' '),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7C3AED),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              localizedDesc,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                            ),
                            const SizedBox(height: 10),

                            // Benefits summary
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFD97706)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      scheme.benefitsSummary,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Official Portal Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.shield_outlined, size: 13, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Text('Official Portal', style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C3AED),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: const Size(0, 34),
                                  ),
                                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                  label: const Text('Visit Official Website', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () => _openOfficialPortal(scheme.officialUrl),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF7C3AED),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF334155),
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _selectedCategory = key),
      ),
    );
  }
}
