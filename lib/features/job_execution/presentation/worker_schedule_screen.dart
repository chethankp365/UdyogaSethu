import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/job_row.dart';
import 'package:udyogasethu/features/job_execution/data/job_execution_repository.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';
import 'package:udyogasethu/features/matching/data/recommendation_pricing_service.dart';
import 'package:udyogasethu/features/matching/presentation/widgets/route_order_card.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

enum ScheduleViewMode { day, week }

class WorkerScheduleScreen extends ConsumerStatefulWidget {
  final String? initialWorkerId;

  const WorkerScheduleScreen({super.key, this.initialWorkerId});

  @override
  ConsumerState<WorkerScheduleScreen> createState() => _WorkerScheduleScreenState();
}

class _WorkerScheduleScreenState extends ConsumerState<WorkerScheduleScreen> {
  ScheduleViewMode _viewMode = ScheduleViewMode.day;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final workerId = widget.initialWorkerId ?? ref.watch(currentUserProvider)?.id ?? '';
    final l10n = AppLocalizations.of(context);

    final scheduleAsync = ref.watch(workerScheduleProvider(workerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n?.scheduleTitle ?? 'Worker Schedule & Travel',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Day / Week Toggle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<ScheduleViewMode>(
              segments: [
                ButtonSegment(
                  value: ScheduleViewMode.day,
                  label: Text(l10n?.scheduleDayView ?? 'Day', style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: ScheduleViewMode.week,
                  label: Text(l10n?.scheduleWeekView ?? 'Week', style: const TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (set) {
                setState(() => _viewMode = set.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return Colors.white.withValues(alpha: 0.15);
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.headerGreenDark;
                  }
                  return Colors.white;
                }),
              ),
            ),
          ),
        ],
      ),
      body: scheduleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.headerGreenDark),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 44),
                const SizedBox(height: 12),
                Text('Error loading schedule: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(workerScheduleProvider(workerId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          return Column(
            children: [
              // 1. Horizontal Date Strip
              _buildHorizontalDateStrip(items),

              // 2. Schedule List (Day or Week)
              Expanded(
                child: _viewMode == ScheduleViewMode.day
                    ? _buildDayView(items, l10n)
                    : _buildWeekView(items, l10n),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHorizontalDateStrip(List<WorkerScheduleItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(7, (index) {
            final date = today.add(Duration(days: index));
            final isSelected = date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;

            final jobCountForDay = items.where((i) {
              return i.startAt.year == date.year &&
                  i.startAt.month == date.month &&
                  i.startAt.day == date.day;
            }).length;

            return InkWell(
              onTap: () => setState(() => _selectedDate = date),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.headerGreenDark : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEE').format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white70 : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (jobCountForDay > 0)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.warningOrange,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDayView(List<WorkerScheduleItem> allItems, AppLocalizations? l10n) {
    final dayItems = allItems.where((i) {
      return i.startAt.year == _selectedDate.year &&
          i.startAt.month == _selectedDate.month &&
          i.startAt.day == _selectedDate.day;
    }).toList();

    if (dayItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_available_rounded, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'No assignments on ${DateFormat('EEEE, MMM d').format(_selectedDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                'You have no jobs scheduled for this date. Explore open jobs in the Jobs tab.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final routePlan = dayItems.length > 1
        ? ref.watch(recommendationPricingServiceProvider).optimizeRouteOrder(jobs: dayItems)
        : null;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (routePlan != null && routePlan.hasMultipleStops)
          RouteOrderCard(plan: routePlan),
        ...dayItems.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Travel Warning Chip between consecutive jobs
                if (item.hasTravelWarning) ...[
                  _buildTravelWarningChip(item, l10n),
                  const SizedBox(height: 12),
                ],
                _buildScheduleCard(context, item, l10n),
                const SizedBox(height: 12),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeekView(List<WorkerScheduleItem> allItems, AppLocalizations? l10n) {
    if (allItems.isEmpty) {
      return const Center(child: Text('No upcoming assignments for this week.'));
    }

    int totalPaise = 0;
    for (final it in allItems) {
      totalPaise += it.agreedWagePaise;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Week Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorderGreen),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.scheduleWeeklyTotal ?? 'Week Projected Earnings',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalPaise ~/ 100}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerGreenDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.paleMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${allItems.length} Jobs Scheduled',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // All Assignments
        ...allItems.map((item) {
          return Column(
            children: [
              if (item.hasTravelWarning) ...[
                _buildTravelWarningChip(item, l10n),
                const SizedBox(height: 8),
              ],
              _buildScheduleCard(context, item, l10n),
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTravelWarningChip(WorkerScheduleItem item, AppLocalizations? l10n) {
    final gap = item.gapFromPrevMinutes?.round() ?? 0;
    final est = item.estimatedTravelMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber 50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.isOverlap
                  ? '⚠️ Schedule Overlap: Job overlaps with preceding shift!'
                  : '⚠️ Travel Warning: Only ${gap}m gap between jobs, travel takes ~${est}m.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, WorkerScheduleItem item, AppLocalizations? l10n) {
    final categoryIcon = JobRow.getCategoryIcon(item.categoryIcon);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/jobs/active/${item.assignmentId}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.paleMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(categoryIcon, color: AppColors.headerGreenDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Client: ${item.providerName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.status == 'requested') ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Waiting for your answer',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₹${item.agreedWageRupees}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.headerGreenDark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${DateFormat('hh:mm a').format(item.startAt)} - ${DateFormat('hh:mm a').format(item.endAt)} (${item.estDurationMinutes} mins)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.addressText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
