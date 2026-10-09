import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';
import 'package:udyogasethu/features/wallet/data/wallet_repository.dart';
import 'package:udyogasethu/features/wallet/domain/upi_payment_data.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_transaction.dart';
import 'package:udyogasethu/features/wallet/domain/withdrawal_result.dart';
import 'package:udyogasethu/features/wallet/presentation/wallet_screen.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/scan_upi_dialog.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/withdraw_dialog.dart';

class MockWalletRepository implements WalletRepository {
  WalletBalance mockBalance;
  List<WalletTransaction> mockTransactions;
  bool shouldFailWithdrawal;
  String? lastWithdrawalRef;
  int? lastWithdrawalAmountPaise;

  MockWalletRepository({
    WalletBalance? balance,
    List<WalletTransaction>? transactions,
    this.shouldFailWithdrawal = false,
  })  : mockBalance = balance ??
            const WalletBalance(
              walletId: 'w-1',
              availablePaise: 1525000, // ₹15,250
              pendingPaise: 0,
              escrowPaise: 120000, // ₹1,200
              rewardPaise: 5000,
              totalBalancePaise: 1645000,
              todayCreditPaise: 80000, // ₹800
            ),
        mockTransactions = transactions ?? [];

  @override
  Future<WalletBalance> getWalletSummary() async => mockBalance;

  @override
  Stream<WalletBalance> watchWalletSummary() => Stream.value(mockBalance);

  @override
  Future<List<WalletTransaction>> getTransactions(TransactionFilterCriteria criteria) async {
    if (criteria.type == 'all') return mockTransactions;
    return mockTransactions.where((t) {
      if (criteria.type == 'wages') return t.type == WalletTransactionType.dailyWage;
      if (criteria.type == 'transfers') return t.type == WalletTransactionType.upiTransfer;
      if (criteria.type == 'farm_sales') return t.type == WalletTransactionType.produceSale;
      if (criteria.type == 'rewards') return t.type == WalletTransactionType.rewardCredit;
      if (criteria.type == 'refunds') return t.type == WalletTransactionType.refund;
      return true;
    }).toList();
  }

  @override
  Future<WithdrawalResult> requestWithdrawal({
    required int amountPaise,
    String method = 'upi',
    String? payoutRef,
    String? idempotencyKey,
  }) async {
    lastWithdrawalAmountPaise = amountPaise;
    lastWithdrawalRef = payoutRef;

    if (shouldFailWithdrawal || amountPaise > mockBalance.availablePaise) {
      throw Exception(
        'Insufficient available balance. Required: $amountPaise paise, Available: ${mockBalance.availablePaise} paise.',
      );
    }

    // Deduct balance
    mockBalance = WalletBalance(
      walletId: mockBalance.walletId,
      availablePaise: mockBalance.availablePaise - amountPaise,
      pendingPaise: mockBalance.pendingPaise,
      escrowPaise: mockBalance.escrowPaise,
      rewardPaise: mockBalance.rewardPaise,
      totalBalancePaise: mockBalance.totalBalancePaise - amountPaise,
      todayCreditPaise: mockBalance.todayCreditPaise,
    );

    return WithdrawalResult(
      payoutId: 'payout-test-1',
      ledgerId: 'ledger-test-1',
      amountPaise: amountPaise,
      payoutRef: payoutRef ?? 'UPI-PAYOUT-12345',
      status: 'completed',
      isDemo: true,
    );
  }
}

void main() {
  group('P5.1 Domain & Formatter Tests', () {
    test('WalletBalance Indian numbering format', () {
      expect(WalletBalance.formatIndianCurrency(0), '₹0');
      expect(WalletBalance.formatIndianCurrency(80000), '₹800');
      expect(WalletBalance.formatIndianCurrency(1525000), '₹15,250');
      expect(WalletBalance.formatIndianCurrency(10000000), '₹1,00,000');
      expect(WalletBalance.formatIndianCurrency(150000000), '₹15,00,000');
      expect(WalletBalance.formatIndianCurrency(1000000000), '₹1,00,00,000');
      expect(WalletBalance.formatIndianCurrency(-50000), '-₹500');
    });

    test('WalletBalance JSON serialization and properties', () {
      final json = {
        'wallet_id': 'wal-123',
        'available_paise': 1525000,
        'pending_paise': 50000,
        'escrow_paise': 120000,
        'reward_paise': 10000,
        'total_balance_paise': 1695000,
        'today_credit_paise': 80000,
      };

      final b = WalletBalance.fromJson(json);
      expect(b.walletId, 'wal-123');
      expect(b.availableRupees, 15250.0);
      expect(b.escrowRupees, 1200.0);
      expect(b.todayCreditRupees, 800.0);
      expect(b.formattedAvailable, '₹15,250');
      expect(b.formattedEscrow, '₹1,200');
      expect(b.formattedTodayCredit, '₹800');
    });

    test('WalletTransaction signed amount and icons', () {
      final creditTx = WalletTransaction(
        id: 'tx-1',
        direction: 'credit',
        amountPaise: 70000,
        bucket: 'available',
        createdAt: DateTime.now(),
        type: WalletTransactionType.dailyWage,
        note: 'Daily Wage - Construction Helper',
      );
      expect(creditTx.isCredit, isTrue);
      expect(creditTx.formattedSignedAmount, '+₹700');
      expect(creditTx.title, 'Daily Wage - Construction Helper');

      final debitTx = WalletTransaction(
        id: 'tx-2',
        direction: 'debit',
        amountPaise: 120000,
        bucket: 'available',
        createdAt: DateTime.now(),
        type: WalletTransactionType.upiTransfer,
        note: 'UPI Transfer to PhonePe (Bank)',
      );
      expect(debitTx.isDebit, isTrue);
      expect(debitTx.formattedSignedAmount, '-₹1,200');
    });

    test('UpiPaymentData parses valid upi://pay URI', () {
      const uri =
          'upi://pay?pa=farmer.suresh@upi&pn=Suresh%20Agri%20Produce&am=450.00&cu=INR&tn=Fresh%20Tomatoes';
      final parsed = UpiPaymentData.parse(uri);

      expect(parsed.isValid, isTrue);
      expect(parsed.payeeVpa, 'farmer.suresh@upi');
      expect(parsed.payeeName, 'Suresh Agri Produce');
      expect(parsed.amount, 450.0);
      expect(parsed.amountPaise, 45000);
      expect(parsed.currency, 'INR');
      expect(parsed.transactionNote, 'Fresh Tomatoes');
    });

    test('UpiPaymentData marks invalid URI as invalid', () {
      final parsed = UpiPaymentData.parse('https://random.com/not-upi');
      expect(parsed.isValid, isFalse);
      expect(parsed.payeeVpa, isEmpty);
    });
  });

  group('P5.1 Database Invariant & Repository Tests', () {
    test('Overdraw withdrawal is rejected by repository with insufficient balance error', () async {
      final repo = MockWalletRepository(
        balance: const WalletBalance(
          walletId: 'w-1',
          availablePaise: 50000, // ₹500 available
          pendingPaise: 0,
          escrowPaise: 0,
          rewardPaise: 0,
          totalBalancePaise: 50000,
          todayCreditPaise: 0,
        ),
      );

      // Attempting to withdraw ₹1,000 (100,000 paise > 50,000 paise)
      expect(
        () => repo.requestWithdrawal(amountPaise: 100000),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Insufficient available balance'),
        )),
      );

      // Valid withdrawal of ₹300 (30,000 paise <= 50,000 paise) succeeds
      final res = await repo.requestWithdrawal(amountPaise: 30000);
      expect(res.amountPaise, 30000);
      expect(res.isDemo, isTrue);
      expect(repo.mockBalance.availablePaise, 20000); // 500 - 300 = 200 left
    });
  });

  group('P5.1 Widget & Screen 8 Fidelity Tests', () {
    testWidgets('WalletScreen renders Screen 8 elements: header, balance, pending escrow, actions',
        (tester) async {
      final mockTxList = [
        WalletTransaction(
          id: 'tx-1',
          direction: 'credit',
          amountPaise: 70000,
          bucket: 'available',
          createdAt: DateTime.now(),
          type: WalletTransactionType.dailyWage,
          note: 'Daily Wage - Construction Helper',
        ),
        WalletTransaction(
          id: 'tx-2',
          direction: 'debit',
          amountPaise: 120000,
          bucket: 'available',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          type: WalletTransactionType.upiTransfer,
          note: 'UPI Transfer to PhonePe (Bank)',
        ),
      ];

      final mockRepo = MockWalletRepository(transactions: mockTxList);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WalletScreen(),
          ),
        ),
      );

      // Pump once and pump with duration to avoid infinite MicFab pulse loop
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Screen 8 Prototype match assertions
      expect(find.text('WALLET BALANCE'), findsOneWidget);
      expect(find.text('Escrow Protected'), findsOneWidget);
      expect(find.text('₹15,250'), findsOneWidget);
      expect(find.text('+₹800'), findsOneWidget);
      expect(find.text("Today's Released"), findsOneWidget);
      expect(find.text('₹1,200'), findsOneWidget);
      expect(find.text('Pending Escrow'), findsOneWidget);
      expect(find.text('Withdraw'), findsOneWidget);
      expect(find.text('Scan UPI QR'), findsOneWidget);
      expect(find.text('RECENT TRANSACTIONS'), findsOneWidget);

      // Verify transactions
      expect(find.text('Daily Wage - Construction Helper'), findsOneWidget);
      expect(find.text('+₹700'), findsOneWidget);
      expect(find.text('UPI Transfer to PhonePe (Bank)'), findsOneWidget);
      expect(find.text('-₹1,200'), findsOneWidget);
      expect(find.text('✓ Completed'), findsNWidgets(2));
    });

    testWidgets('WithdrawDialog displays balance, validates amount, and handles overdraw error',
        (tester) async {
      final mockRepo = MockWalletRepository(
        balance: const WalletBalance(
          walletId: 'w-1',
          availablePaise: 50000, // ₹500 available
          pendingPaise: 0,
          escrowPaise: 0,
          rewardPaise: 0,
          totalBalancePaise: 50000,
          todayCreditPaise: 0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: WithdrawDialog(
                walletBalance: mockRepo.mockBalance,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Withdraw Earnings'), findsOneWidget);
      expect(find.text('Demo mode: Simulated payout ledger debit until banking partner exists.'), findsOneWidget);
      expect(find.text('₹500'), findsNWidgets(2)); // Available balance and quick chip

      // Enter amount larger than balance: ₹1,000
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '1000');
      await tester.pumpAndSettle();

      final confirmBtn = find.text('Confirm Payout Withdrawal');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify database overdraw refusal banner appears
      expect(find.textContaining('Insufficient available balance'), findsOneWidget);
    });

    testWidgets('ScanUpiDialog renders Demo Mode banner, parses UPI payload, and previews data',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ScanUpiDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Scan UPI QR'), findsOneWidget);
      expect(find.text('Demo mode: Simulated UPI Scanner'), findsOneWidget);
      expect(find.text('No real money will be transferred. Payment rails connect in Phase 5.2.'), findsOneWidget);

      // Verify parsed payload display
      expect(find.text('Suresh Agri Produce'), findsOneWidget);
      expect(find.text('farmer.suresh@upi'), findsOneWidget);
      expect(find.text('₹450.00'), findsOneWidget);
      expect(find.text('Fresh Tomatoes'), findsOneWidget);
    });
  });
}
