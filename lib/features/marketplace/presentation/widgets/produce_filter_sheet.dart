import 'package:flutter/material.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_filters.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class ProduceFilterSheet extends StatefulWidget {
  final ProduceFilters initialFilters;
  final ValueChanged<ProduceFilters> onApply;

  const ProduceFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required ProduceFilters currentFilters,
    required ValueChanged<ProduceFilters> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ProduceFilterSheet(
        initialFilters: currentFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ProduceFilterSheet> createState() => _ProduceFilterSheetState();
}

class _ProduceFilterSheetState extends State<ProduceFilterSheet> {
  late ProduceFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.produceFiltersTitle ?? 'Filters & Sorting',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filters = const ProduceFilters();
                      });
                    },
                    child: Text(
                      l10n?.clearFilters ?? 'Reset All',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Filters
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Sort By
                  _buildSectionTitle(l10n?.sortBy ?? 'Sort By'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ProduceSortOption.values.map((opt) {
                      final isSelected = _filters.sortBy == opt;
                      return ChoiceChip(
                        label: Text(opt.label),
                        selected: isSelected,
                        selectedColor: const Color(0xFFECFDF5),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF047857) : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _filters = _filters.copyWith(sortBy: opt)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 2. Max Distance
                  _buildSectionTitle(l10n?.maxDistance ?? 'Maximum Distance'),
                  Wrap(
                    spacing: 8,
                    children: [5.0, 10.0, 25.0, 50.0].map((km) {
                      final isSelected = _filters.maxDistanceKm == km;
                      return ChoiceChip(
                        label: Text('${km.toInt()} km'),
                        selected: isSelected,
                        selectedColor: const Color(0xFFECFDF5),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF047857) : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _filters = _filters.copyWith(
                              maxDistanceKm: selected ? km : null,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 3. Minimum Farmer Rating
                  _buildSectionTitle(l10n?.minFarmerRating ?? 'Farmer Rating'),
                  Wrap(
                    spacing: 8,
                    children: [4.0, 4.5, 4.8].map((rating) {
                      final isSelected = _filters.minRating == rating;
                      return ChoiceChip(
                        label: Text('★ $rating+'),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFEF3C7),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFFB45309) : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _filters = _filters.copyWith(
                              minRating: selected ? rating : null,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 4. Freshness
                  _buildSectionTitle(l10n?.freshnessFilter ?? 'Harvest Freshness'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FreshnessFilter.values.map((f) {
                      final isSelected = _filters.freshness == f;
                      return ChoiceChip(
                        label: Text(f.label),
                        selected: isSelected,
                        selectedColor: const Color(0xFFECFDF5),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF047857) : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _filters = _filters.copyWith(freshness: f)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 5. Farming Method
                  _buildSectionTitle(l10n?.farmingMethod ?? 'Farming Method'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Organic',
                      'Zero-Pesticide',
                      'Natural',
                      'Traditional',
                    ].map((method) {
                      final isSelected = _filters.farmingMethod?.toLowerCase() == method.toLowerCase();
                      return ChoiceChip(
                        label: Text(method),
                        selected: isSelected,
                        selectedColor: const Color(0xFFECFDF5),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF047857) : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _filters = _filters.copyWith(
                              farmingMethod: selected ? method : null,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 6. Delivery & Walk-in Store Options
                  _buildSectionTitle(l10n?.fulfillmentOptions ?? 'Fulfillment & Availability'),
                  SwitchListTile(
                    title: Text(l10n?.deliveryAvailableOnly ?? 'Doorstep Delivery Available'),
                    value: _filters.deliveryAvailable ?? false,
                    activeThumbColor: const Color(0xFF00875A),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        _filters = _filters.copyWith(
                          deliveryAvailable: val ? true : null,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n?.walkInStoreOnly ?? 'Walk-in Store / Farm Depot Pickup'),
                    value: _filters.walkInStoreOnly ?? false,
                    activeThumbColor: const Color(0xFF00875A),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        _filters = _filters.copyWith(
                          walkInStoreOnly: val ? true : null,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n?.organicCertifiedOnly ?? 'Organic Certificate Validated Only'),
                    value: _filters.organicCertifiedOnly ?? false,
                    activeThumbColor: const Color(0xFF00875A),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        _filters = _filters.copyWith(
                          organicCertifiedOnly: val ? true : null,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),

            // Bottom Apply Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6548),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    widget.onApply(_filters);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    l10n?.applyFilters ?? 'Apply Filters',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
