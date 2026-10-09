import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/features/earnings/domain/earnings_models.dart';

enum ChartTimeframe {
  daily14,
  monthly6,
}

class EarningsTrendChart extends StatefulWidget {
  final List<DailyTrendItem> dailyTrends;
  final List<MonthlyTrendItem> monthlyTrends;

  const EarningsTrendChart({
    super.key,
    required this.dailyTrends,
    required this.monthlyTrends,
  });

  @override
  State<EarningsTrendChart> createState() => _EarningsTrendChartState();
}

class _EarningsTrendChartState extends State<EarningsTrendChart> {
  ChartTimeframe _selectedTimeframe = ChartTimeframe.daily14;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title and Segmented Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: Color(0xFF0D6548), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Payout Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeframeTab('14 Days', ChartTimeframe.daily14),
                    _buildTimeframeTab('6 Months', ChartTimeframe.monthly6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Display Area
          SizedBox(
            height: 200,
            child: _selectedTimeframe == ChartTimeframe.daily14
                ? _buildDailyLineChart()
                : _buildMonthlyBarChart(),
          ),
          const SizedBox(height: 16),

          // Accessible Text Summary (Screen readers and easy comprehension)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedTimeframe == ChartTimeframe.daily14
                        ? _generateDailySummaryText()
                        : _generateMonthlySummaryText(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeTab(String label, ChartTimeframe timeframe) {
    final isSelected = _selectedTimeframe == timeframe;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeframe = timeframe;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0D6548) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyLineChart() {
    if (widget.dailyTrends.isEmpty) {
      return const Center(
        child: Text('No daily trend data available yet.'),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 1000;

    for (int i = 0; i < widget.dailyTrends.length; i++) {
      final item = widget.dailyTrends[i];
      final rupees = item.earningsRupees;
      if (rupees > maxY) maxY = rupees;
      spots.add(FlSpot(i.toDouble(), rupees));
    }

    // Give some padding at top of chart
    maxY = (maxY * 1.2).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: max(500, maxY),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: max(100, maxY / 4),
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFF1F5F9),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: max(100, maxY / 4),
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '₹${NumberFormat.compact().format(value)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: max(1, (widget.dailyTrends.length / 5).floorToDouble()),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.dailyTrends.length) {
                  return const SizedBox.shrink();
                }
                final date = widget.dailyTrends[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('d/M').format(date),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final item = widget.dailyTrends[idx];
                return LineTooltipItem(
                  '${DateFormat('d MMM').format(item.date)}\n₹${NumberFormat('#,##,##0').format(spot.y.round())}\n${item.jobsCount} jobs',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF0D6548),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: spot.y > 0 ? 3.5 : 1.5,
                  color: spot.y > 0 ? const Color(0xFF10B981) : Colors.transparent,
                  strokeWidth: spot.y > 0 ? 2 : 0,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.3),
                  const Color(0xFF10B981).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    if (widget.monthlyTrends.isEmpty) {
      return const Center(
        child: Text('No monthly trend data available yet.'),
      );
    }

    final barGroups = <BarChartGroupData>[];
    double maxY = 1000;

    for (int i = 0; i < widget.monthlyTrends.length; i++) {
      final item = widget.monthlyTrends[i];
      final rupees = item.earningsRupees;
      if (rupees > maxY) maxY = rupees;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: rupees,
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6548), Color(0xFF10B981)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    maxY = (maxY * 1.2).ceilToDouble();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: max(1000, maxY),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: max(200, maxY / 4),
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFF1F5F9),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: max(200, maxY / 4),
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '₹${NumberFormat.compact().format(value)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.monthlyTrends.length) {
                  return const SizedBox.shrink();
                }
                final item = widget.monthlyTrends[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.monthLabel.split(' ').first,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = widget.monthlyTrends[group.x];
              return BarTooltipItem(
                '${item.monthLabel}\n₹${NumberFormat('#,##,##0').format(rod.toY.round())}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  String _generateDailySummaryText() {
    if (widget.dailyTrends.isEmpty) {
      return 'No earnings recorded in the last 14 days.';
    }

    int totalPaise = 0;
    int totalJobs = 0;
    DailyTrendItem? bestDay;

    for (final item in widget.dailyTrends) {
      totalPaise += item.earningsPaise;
      totalJobs += item.jobsCount;
      if (bestDay == null || item.earningsPaise > bestDay.earningsPaise) {
        bestDay = item;
      }
    }

    if (totalPaise == 0) {
      return 'No payouts recorded in the last 14 days. Complete jobs to start seeing payout trends.';
    }

    final totalRupeesFormatted =
        '₹${NumberFormat('#,##,##0').format((totalPaise / 100).round())}';
    final bestRupeesFormatted =
        '₹${NumberFormat('#,##,##0').format((bestDay!.earningsPaise / 100).round())}';
    final bestDateFormatted = DateFormat('d MMM').format(bestDay.date);

    return 'Total $totalRupeesFormatted earned across $totalJobs jobs over the last 14 days. Highest payout was $bestRupeesFormatted on $bestDateFormatted.';
  }

  String _generateMonthlySummaryText() {
    if (widget.monthlyTrends.isEmpty) {
      return 'No earnings recorded in the last 6 months.';
    }

    int totalPaise = 0;
    MonthlyTrendItem? bestMonth;

    for (final item in widget.monthlyTrends) {
      totalPaise += item.earningsPaise;
      if (bestMonth == null || item.earningsPaise > bestMonth.earningsPaise) {
        bestMonth = item;
      }
    }

    if (totalPaise == 0) {
      return 'No payouts recorded in the last 6 months.';
    }

    final totalRupeesFormatted =
        '₹${NumberFormat('#,##,##0').format((totalPaise / 100).round())}';
    final bestRupeesFormatted =
        '₹${NumberFormat('#,##,##0').format((bestMonth!.earningsPaise / 100).round())}';

    return 'Total $totalRupeesFormatted earned over the past 6 months. Best month was ${bestMonth.monthLabel} with $bestRupeesFormatted.';
  }
}
