import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/earnings/data/earnings_repository.dart';
import 'package:udyogasethu/features/earnings/domain/earnings_models.dart';
import 'package:udyogasethu/features/earnings/domain/savings_goal_model.dart';
import 'package:udyogasethu/features/wallet/data/wallet_repository.dart';
import 'package:udyogasethu/features/wallet/domain/upi_payment_data.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_transaction.dart';
import 'package:udyogasethu/features/wallet/domain/withdrawal_result.dart';
import 'package:udyogasethu/features/wallet/presentation/wallet_screen.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/payment_receipt_modal.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/savings_planner_card.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/scan_upi_dialog.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockWalletRepoForTest implements WalletRepository {
  final WalletBalance balance;
  final List<WalletTransaction> transactions;

  MockWalletRepoForTest({required this.balance, required this.transactions});

  @override
  Future<WalletBalance> getWalletSummary() async => balance;

  @override
  Stream<WalletBalance> watchWalletSummary() => Stream.value(balance);

  @override
  Future<List<WalletTransaction>> getTransactions(TransactionFilterCriteria criteria) async {
    if (criteria.type == 'all') return transactions;
    if (criteria.type == 'wages') {
      return transactions.where((t) => t.type == WalletTransactionType.dailyWage).toList();
    }
    if (criteria.type == 'escrow') {
      return transactions.where((t) => t.bucket == 'escrow').toList();
    }
    return transactions;
  }

  @override
  Future<WithdrawalResult> requestWithdrawal({
    required int amountPaise,
    String method = 'upi',
    String? payoutRef,
    String? idempotencyKey,
  }) async {
    return WithdrawalResult(
      payoutId: 'payout-1',
      ledgerId: 'ledger-1',
      amountPaise: amountPaise,
      payoutRef: 'PAYOUT-123',
      status: 'completed',
    );
  }
}

class MockEarningsRepoForTest implements EarningsRepository {
  final List<SavingsGoal> goals;

  MockEarningsRepoForTest(this.goals);

  @override
  Future<List<SavingsGoal>> getSavingsGoals() async => goals;

  @override
  Future<EarningsDashboardData> getEarningsDashboard({int days = 14}) async => EarningsDashboardData.empty();

  @override
  Future<int> updateDailyEarningsGoal(int goalPaise) async => goalPaise;

  @override
  Future<SavingsGoal> createSavingsGoal(SavingsGoalDraft draft) async => throw UnimplementedError();

  @override
  Future<SavingsGoal> allocateSavingsGoal({required String goalId, required int amountPaise}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteSavingsGoal(String goalId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleDate = DateTime(2026, 10, 10, 14, 30);

  final sampleTxWage = WalletTransaction(
    id: 'tx-12345678-abcd',
    direction: 'credit',
    amountPaise: 80000, // ₹800
    bucket: 'available',
    refType: 'job_assignment',
    refId: 'job-ref-001',
    note: 'Daily Wage - Campus Courier',
    createdAt: sampleDate,
    type: WalletTransactionType.dailyWage,
    feePaise: 4000, // ₹40
  );

  final sampleTxEscrow = WalletTransaction(
    id: 'tx-87654321-wxyz',
    direction: 'credit',
    amountPaise: 120000, // ₹1,200
    bucket: 'escrow',
    refType: 'job_escrow',
    refId: 'escrow-ref-002',
    note: 'Escrow Deposit - Site Electrical',
    createdAt: sampleDate.subtract(const Duration(days: 1)),
    type: WalletTransactionType.other,
    feePaise: 0,
  );

  final sampleGoal = SavingsGoal(
    id: 'goal-1',
    userId: 'user-1',
    title: 'New Electric Scooter',
    category: SavingsGoalCategory.scooter,
    targetPaise: 5000000, // ₹50,000
    savedPaise: 3250000, // ₹32,500 (65%)
    deadline: DateTime(2026, 12, 31),
    isCompleted: false,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  group('Part D: Wallet Domain & Receipt Tests', () {
    test('WalletTransaction computes receipt fee breakdown and UTR correctly', () {
      expect(sampleTxWage.formattedSignedAmount, equals('+₹800'));
      expect(sampleTxWage.grossAmountPaise, equals(80000));
      expect(sampleTxWage.feePaise, equals(4000));
      expect(sampleTxWage.formattedFee, equals('₹40'));
      expect(sampleTxWage.taxPaise, equals(720)); // 18% of 4000 = 720 paise
      expect(sampleTxWage.formattedNetAmount, equals('₹800'));
      expect(sampleTxWage.utrNumber, startsWith('UTR-'));
      expect(sampleTxWage.status, equals('completed'));
    });

    test('UpiPaymentData parses valid UPI intent URI', () {
      const uri =
          'upi://pay?pa=farmer.suresh@upi&pn=Suresh%20Agri%20Produce&am=450.00&cu=INR&tn=Fresh%20Tomatoes';
      final parsed = UpiPaymentData.parse(uri);

      expect(parsed.isValid, isTrue);
      expect(parsed.payeeVpa, equals('farmer.suresh@upi'));
      expect(parsed.payeeName, equals('Suresh Agri Produce'));
      expect(parsed.amount, equals(450.00));
      expect(parsed.amountPaise, equals(45000));
      expect(parsed.transactionNote, equals('Fresh Tomatoes'));
    });

    test('Fresh user balance is zero with no mock defaults', () {
      final zeroBalance = WalletBalance.zero('w-fresh');
      expect(zeroBalance.availablePaise, equals(0));
      expect(zeroBalance.pendingPaise, equals(0));
      expect(zeroBalance.escrowPaise, equals(0));
      expect(zeroBalance.totalBalancePaise, equals(0));
      expect(zeroBalance.todayCreditPaise, equals(0));
      expect(zeroBalance.formattedAvailable, equals('₹0'));
    });
  });

  group('Part D: PaymentReceiptModal & Widgets Tests', () {
    testWidgets('PaymentReceiptModal displays receipt details and breakdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentReceiptModal(transaction: sampleTxWage),
          ),
        ),
      );

      expect(find.text('Payment Receipt'), findsOneWidget);
      expect(find.text('+₹800'), findsOneWidget);
      expect(find.text('Daily Wage - Campus Courier'), findsOneWidget);
      expect(find.text('Bank Reference (UTR / RRN)'), findsOneWidget);
      expect(find.text('Gross Amount'), findsOneWidget);
      expect(find.text('Share Receipt'), findsOneWidget);
      expect(find.text('SafeEscrow Lifecycle'), findsOneWidget);
    });

    testWidgets('SavingsPlannerCard displays goal completion ring and suggestion', (tester) async {
      final mockEarnings = MockEarningsRepoForTest([sampleGoal]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            earningsRepositoryProvider.overrideWithValue(mockEarnings),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SavingsPlannerCard(
                walletBalance: WalletBalance.zero(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SAVINGS PLANNER'), findsOneWidget);
      expect(find.text('New Electric Scooter'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('₹32,500'), findsOneWidget);
    });

    testWidgets('ScanUpiDialog supports mode switching and sample test selection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScanUpiDialog(),
          ),
        ),
      );

      expect(find.text('Scan UPI QR'), findsOneWidget);
      expect(find.text('Demo mode: Simulated UPI Scanner'), findsOneWidget);
      expect(find.text('Live Camera'), findsOneWidget);
      expect(find.text('Manual / Sample'), findsOneWidget);

      // Switch to Manual / Sample mode
      await tester.tap(find.text('Manual / Sample'));
      await tester.pumpAndSettle();

      expect(find.text('Quick test presets:'), findsOneWidget);
      expect(find.text('Worker Wage (₹750)'), findsOneWidget);

      // Tap preset
      await tester.tap(find.text('Worker Wage (₹750)'));
      await tester.pumpAndSettle();

      expect(find.text('Parsed UPI Target'), findsOneWidget);
      expect(find.text('electrician.ramesh@okaxis'), findsOneWidget);
    });

    testWidgets('WalletScreen renders hero balance, savings planner, and grouped transactions', (tester) async {
      final mockWallet = MockWalletRepoForTest(
        balance: const WalletBalance(
          walletId: 'w-1',
          availablePaise: 250000,
          pendingPaise: 0,
          escrowPaise: 120000,
          rewardPaise: 0,
          totalBalancePaise: 370000,
          todayCreditPaise: 80000,
        ),
        transactions: [sampleTxWage, sampleTxEscrow],
      );
      final mockEarnings = MockEarningsRepoForTest([sampleGoal]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletRepositoryProvider.overrideWithValue(mockWallet),
            earningsRepositoryProvider.overrideWithValue(mockEarnings),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: WalletScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Wallet & Escrow'), findsOneWidget);
      expect(find.text('WALLET BALANCE'), findsOneWidget);
      expect(find.text('SAVINGS PLANNER'), findsOneWidget);
      expect(find.text('RECENT TRANSACTIONS'), findsOneWidget);
      expect(find.text('Farm Produce'), findsOneWidget);
      expect(find.text('Daily Wage - Campus Courier'), findsOneWidget);
    });
  });
}
