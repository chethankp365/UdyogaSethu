import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/features/wallet/data/wallet_repository.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_transaction.dart';

/// Notifier controlling Presentation Demo Mode for wallet transactions.
/// Strictly isolated from real user ledger entries and real Razorpay payments.
class WalletDemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setDemo(bool value) => state = value;
  void reset() => state = false;
}

final walletDemoModeProvider =
    NotifierProvider<WalletDemoModeNotifier, bool>(WalletDemoModeNotifier.new);

/// Dedicated container for presentation demo transactions.
class DemoWalletData {
  DemoWalletData._();

  /// Fictional, realistic sample transactions representing all supported statuses:
  /// completed, pending, failed, and refunded.
  static List<WalletTransaction> getSampleTransactions() {
    final now = DateTime.now();

    return [
      WalletTransaction(
        id: 'demo_tx_001',
        direction: 'credit',
        amountPaise: 85000, // ₹850.00
        bucket: 'available',
        type: WalletTransactionType.dailyWage,
        refType: 'job_assignment',
        refId: 'demo_asg_101',
        linkedItemTitle: 'Plumbing & Pipe Fitting (Site #3)',
        counterpartyName: 'Kavitha Constructions',
        counterpartyAccount: 'kavitha.infra@okaxis',
        utr: 'DEMO-UPI-982341201',
        rawStatus: 'completed',
        createdAt: now.subtract(const Duration(hours: 2)),
        feePaise: 2500,
        note: 'Daily wage credited after shift completion',
      ),
      WalletTransaction(
        id: 'demo_tx_002',
        direction: 'credit',
        amountPaise: 120000, // ₹1,200.00
        bucket: 'escrow',
        type: WalletTransactionType.dailyWage,
        refType: 'job_assignment',
        refId: 'demo_asg_102',
        linkedItemTitle: 'Warehouse Material Handling Shift',
        counterpartyName: 'Apex Logistics Hub',
        counterpartyAccount: 'apex.pay@icici',
        utr: 'DEMO-ESC-551293',
        rawStatus: 'pending',
        createdAt: now.subtract(const Duration(hours: 5)),
        feePaise: 3500,
        note: 'Held in escrow until employer attendance sign-off',
      ),
      WalletTransaction(
        id: 'demo_tx_003',
        direction: 'credit',
        amountPaise: 340000, // ₹3,400.00
        bucket: 'available',
        type: WalletTransactionType.produceSale,
        refType: 'produce_order',
        refId: 'demo_ord_201',
        linkedItemTitle: 'Fresh Organic Tomatoes (120 kg)',
        counterpartyName: 'Ramesh Wholesale Mandi',
        counterpartyAccount: 'mandi.hub4@sbi',
        utr: 'DEMO-MANDI-33819',
        rawStatus: 'completed',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        feePaise: 5000,
        note: 'Direct farm produce order settlement',
      ),
      WalletTransaction(
        id: 'demo_tx_004',
        direction: 'debit',
        amountPaise: 50000, // ₹500.00
        bucket: 'available',
        type: WalletTransactionType.upiTransfer,
        refType: 'payout',
        refId: 'demo_payout_fail_01',
        linkedItemTitle: 'Instant Payout to worker@okhdfc',
        counterpartyName: 'HDFC Bank Payout Gateway',
        counterpartyAccount: 'worker.sample@okhdfc',
        utr: 'DEMO-FAIL-88129',
        rawStatus: 'failed',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        feePaise: 0,
        note: 'Simulated bank server timeout (No funds deducted)',
      ),
      WalletTransaction(
        id: 'demo_tx_005',
        direction: 'credit',
        amountPaise: 6500, // ₹65.00
        bucket: 'available',
        type: WalletTransactionType.refund,
        refType: 'refund',
        refId: 'demo_ref_301',
        linkedItemTitle: 'Escrow Dispute Settlement Refund',
        counterpartyName: 'UdyogaSethu Trust & Safety',
        counterpartyAccount: 'safety.escrow@udyogasethu',
        utr: 'DEMO-REF-99120',
        rawStatus: 'refunded',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        feePaise: 0,
        note: 'Dispute arbitration decided in worker favour',
      ),
      WalletTransaction(
        id: 'demo_tx_006',
        direction: 'debit',
        amountPaise: 150000, // ₹1,500.00
        bucket: 'available',
        type: WalletTransactionType.upiTransfer,
        refType: 'payout',
        refId: 'demo_payout_401',
        linkedItemTitle: 'Instant Bank Withdrawal to SBI ****4321',
        counterpartyName: 'State Bank of India',
        counterpartyAccount: 'worker.personal@oksbi',
        utr: 'DEMO-UPI-449102',
        rawStatus: 'completed',
        createdAt: now.subtract(const Duration(days: 3, hours: 1)),
        feePaise: 1500,
        note: 'Transferred to personal savings account via IMPS',
      ),
    ];
  }

  /// Filter demo transactions by criteria without querying the database
  static List<WalletTransaction> filterTransactions(
    List<WalletTransaction> all,
    TransactionFilterCriteria criteria,
  ) {
    var filtered = all;

    if (criteria.type != 'all') {
      filtered = filtered.where((tx) {
        switch (criteria.type) {
          case 'wages':
            return tx.type == WalletTransactionType.dailyWage;
          case 'transfers':
          case 'withdrawals':
            return tx.type == WalletTransactionType.upiTransfer ||
                tx.type == WalletTransactionType.autoPayout;
          case 'farm_sales':
          case 'farm_produce':
            return tx.type == WalletTransactionType.produceSale;
          case 'refunds':
            return tx.type == WalletTransactionType.refund;
          case 'escrow':
            return tx.bucket == 'escrow';
          case 'rewards':
            return tx.type == WalletTransactionType.rewardCredit;
          default:
            return true;
        }
      }).toList();
    }

    if (criteria.startDate != null) {
      filtered = filtered.where((tx) => tx.createdAt.isAfter(criteria.startDate!)).toList();
    }
    if (criteria.endDate != null) {
      filtered = filtered.where((tx) => tx.createdAt.isBefore(criteria.endDate!)).toList();
    }

    return filtered.take(criteria.limit).toList();
  }

  /// Sample demo summary balance (Fictional, separated from real ledger)
  static const WalletBalance sampleDemoBalance = WalletBalance(
    walletId: 'demo-wallet-presentation',
    availablePaise: 425000,     // ₹4,250.00
    pendingPaise: 120000,       // ₹1,200.00
    escrowPaise: 120000,        // ₹1,200.00
    rewardPaise: 15000,         // ₹150.00
    totalBalancePaise: 560000,  // ₹5,600.00
    todayCreditPaise: 85000,    // ₹850.00
  );
}
