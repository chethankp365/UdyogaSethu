import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/wallet/data/wallet_repository.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_transaction.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/savings_planner_card.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/scan_upi_dialog.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/transaction_tile.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/wallet_skeleton.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/withdraw_dialog.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _selectedFilter = 'all'; // 'all', 'wages', 'transfers', 'farm_produce', 'withdrawals', 'refunds'
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int _currentLimit = 20;

  TransactionFilterCriteria get _currentCriteria => TransactionFilterCriteria(
        type: _selectedFilter,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        limit: _currentLimit,
      );

  Future<void> _refresh() async {
    setState(() {
      _currentLimit = 20;
    });
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(walletTransactionsProvider(_currentCriteria));
  }

  void _openWithdrawDialog(WalletBalance balance) {
    showDialog(
      context: context,
      builder: (ctx) => WithdrawDialog(
        walletBalance: balance,
        onWithdrawalSuccess: _refresh,
      ),
    );
  }

  void _openScanUpiDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ScanUpiDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletSummaryStreamProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider(_currentCriteria));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6548),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Wallet & Escrow',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Balances',
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF0D6548),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HERO CARD & SAVINGS PLANNER (Screen 8 Prototype Match)
              balanceAsync.when(
                data: (balance) => Column(
                  children: [
                    _buildHeroCard(balance),
                    const SizedBox(height: 18),
                    SavingsPlannerCard(walletBalance: balance),
                  ],
                ),
                loading: () => const WalletSkeleton(),
                error: (err, _) => _buildHeroCard(WalletBalance.zero()),
              ),

              const SizedBox(height: 24),

              // 2. RECENT TRANSACTIONS HEADER & FILTER CHIPS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT TRANSACTIONS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (_selectedStartDate != null || _selectedEndDate != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.clear, size: 14, color: AppColors.textMuted),
                      label: const Text('Clear date', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      onPressed: () {
                        setState(() {
                          _selectedStartDate = null;
                          _selectedEndDate = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Chips Row (Prompt D1: All, Daily Wages, UPI Transfers, Farm Produce, Withdrawals, Refunds)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All'),
                    const SizedBox(width: 8),
                    _filterChip('wages', 'Daily Wages'),
                    const SizedBox(width: 8),
                    _filterChip('transfers', 'UPI Transfers'),
                    const SizedBox(width: 8),
                    _filterChip('farm_produce', 'Farm Produce'),
                    const SizedBox(width: 8),
                    _filterChip('withdrawals', 'Withdrawals'),
                    const SizedBox(width: 8),
                    _filterChip('refunds', 'Refunds'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. TRANSACTIONS LIST (Grouped by Day & Month with Pagination)
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildGroupedTransactions(transactions);
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF0D6548)),
                  ),
                ),
                error: (err, _) => _buildErrorState(err.toString()),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TOP HERO CARD (Screen 8 match)
  // ==========================================================================
  Widget _buildHeroCard(WalletBalance balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D6548),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6548).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: WALLET BALANCE & Escrow Protected Pill
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'WALLET BALANCE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFFD1FAE5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Escrow Protected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Large Balance Display (Indian Grouping)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              balance.formattedAvailable,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Two Inner Metric Cards (Screen 8 match: +₹800 today & Pending Escrow ₹1,200)
          Row(
            children: [
              // Sub-card 1: Today's Amount
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          balance.todayCreditPaise > 0
                              ? '+${balance.formattedTodayCredit}'
                              : '₹0',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34D399),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Today's Released",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Sub-card 2: Pending Escrow
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          balance.formattedEscrow,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pending Escrow',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Action Buttons: ↗ Withdraw & Scan UPI QR
          Row(
            children: [
              // Withdraw Button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D6548),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  ),
                  onPressed: () => _openWithdrawDialog(balance),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_outward_rounded, size: 18),
                      SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Withdraw',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Scan UPI QR Button
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  ),
                  onPressed: _openScanUpiDialog,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 18),
                      SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Scan UPI QR',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Link to Earnings Dashboard & Savings Goal Planner
          InkWell(
            onTap: () => context.push(AppRoutes.earningsDashboard),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights_rounded, color: Color(0xFF34D399), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Earnings Analytics & Savings Planner',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // FILTER CHIP WIDGET
  // ==========================================================================
  Widget _filterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF0D6548),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textDark,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF0D6548) : const Color(0xFFCBD5E1),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilter = key;
          });
        }
      },
    );
  }

  // ==========================================================================
  // GROUPED TRANSACTIONS BUILDER (Grouped by Day & Month - Prompt D1)
  // ==========================================================================
  Map<String, List<WalletTransaction>> _groupTransactions(List<WalletTransaction> transactions) {
    final Map<String, List<WalletTransaction>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in transactions) {
      final txDate = DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);
      String header;
      if (txDate == today) {
        header = 'TODAY • ${DateFormat('d MMMM yyyy').format(tx.createdAt).toUpperCase()}';
      } else if (txDate == yesterday) {
        header = 'YESTERDAY • ${DateFormat('d MMMM yyyy').format(tx.createdAt).toUpperCase()}';
      } else {
        header = DateFormat('d MMMM yyyy').format(tx.createdAt).toUpperCase();
      }
      grouped.putIfAbsent(header, () => []).add(tx);
    }
    return grouped;
  }

  Widget _buildGroupedTransactions(List<WalletTransaction> transactions) {
    final groups = _groupTransactions(transactions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groups.entries.map((entry) {
          final header = entry.key;
          final items = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      header,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${items.length} ${items.length == 1 ? 'transaction' : 'transactions'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((tx) => TransactionTile(transaction: tx)),
              const SizedBox(height: 6),
            ],
          );
        }),
        if (transactions.length >= _currentLimit) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D6548),
                side: const BorderSide(color: Color(0xFF0D6548)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_downward_rounded, size: 16),
              label: const Text(
                'Load Earlier Transactions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                setState(() {
                  _currentLimit += 20;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================================
  // EMPTY STATE
  // ==========================================================================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'No Transactions Found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Completed daily wages and transfers will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ERROR STATE WITH RETRY
  // ==========================================================================
  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 36),
          const SizedBox(height: 10),
          const Text(
            'Failed to Load Transactions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }
}
