import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/wallet/data/demo_wallet_transactions.dart';
import 'package:udyogasethu/features/wallet/data/wallet_repository.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_transaction.dart';
import 'package:udyogasethu/features/wallet/domain/withdrawal_result.dart';
import 'package:udyogasethu/features/wallet/presentation/wallet_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeRealWalletRepository implements WalletRepository {
  @override
  Future<WalletBalance> getWalletSummary() async {
    return const WalletBalance(
      walletId: 'real_w_1',
      availablePaise: 50000,
      pendingPaise: 0,
      escrowPaise: 0,
      rewardPaise: 0,
      totalBalancePaise: 50000,
      todayCreditPaise: 0,
    );
  }

  @override
  Stream<WalletBalance> watchWalletSummary() {
    return Stream.value(const WalletBalance(
      walletId: 'real_w_1',
      availablePaise: 50000,
      pendingPaise: 0,
      escrowPaise: 0,
      rewardPaise: 0,
      totalBalancePaise: 50000,
      todayCreditPaise: 0,
    ));
  }

  @override
  Future<List<WalletTransaction>> getTransactions(TransactionFilterCriteria criteria) async {
    return [
      WalletTransaction(
        id: 'real_tx_1',
        direction: 'credit',
        amountPaise: 50000,
        bucket: 'available',
        type: WalletTransactionType.dailyWage,
        createdAt: DateTime.now(),
        rawStatus: 'completed',
        linkedItemTitle: 'Real Production Shift',
      ),
    ];
  }

  @override
  Future<WithdrawalResult> requestWithdrawal({
    required int amountPaise,
    String method = 'upi',
    String? payoutRef,
    String? idempotencyKey,
  }) async {
    return const WithdrawalResult(
      payoutId: 'real_payout_1',
      ledgerId: 'real_ledger_1',
      amountPaise: 10000,
      payoutRef: 'real_ref_1',
      status: 'completed',
      isDemo: false,
    );
  }

  @override
  Future<Map<String, dynamic>> topupWallet({
    required int amountPaise,
    String? paymentRef,
  }) async {
    return {'success': true, 'amount_paise': amountPaise};
  }

  @override
  Future<Map<String, dynamic>> payVpaFromWallet({
    required String payeeVpa,
    required String payeeName,
    required int amountPaise,
    String? note,
  }) async {
    return {'success': true, 'amount_paise': amountPaise};
  }
}

void main() {
  group('Presentation Demo Transactions Tests', () {
    test('1. Demo data contains completed, pending, failed, and refunded statuses', () {
      final samples = DemoWalletData.getSampleTransactions();
      expect(samples.isNotEmpty, isTrue);

      final statuses = samples.map((t) => t.statusDisplay).toSet();
      expect(statuses.contains('Success'), isTrue, reason: 'Completed/Success should exist');
      expect(statuses.contains('Pending'), isTrue, reason: 'Pending should exist');
      expect(statuses.contains('Failed'), isTrue, reason: 'Failed should exist');
      expect(statuses.contains('Refunded'), isTrue, reason: 'Refunded should exist');
    });

    test('2. Demo data filtering filters accurately by criteria', () {
      final samples = DemoWalletData.getSampleTransactions();

      final wageOnly = DemoWalletData.filterTransactions(
        samples,
        const TransactionFilterCriteria(type: 'wages'),
      );
      expect(wageOnly.every((t) => t.type == WalletTransactionType.dailyWage), isTrue);

      final refundsOnly = DemoWalletData.filterTransactions(
        samples,
        const TransactionFilterCriteria(type: 'refunds'),
      );
      expect(refundsOnly.every((t) => t.type == WalletTransactionType.refund), isTrue);
    });

    test('3. walletTransactionsProvider switches to demo data when demo mode is active', () async {
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(FakeRealWalletRepository()),
        ],
      );
      addTearDown(container.dispose);

      const criteria = TransactionFilterCriteria(type: 'all');

      // Before demo mode: returns real data
      final realTx = await container.read(walletTransactionsProvider(criteria).future);
      expect(realTx.length, 1);
      expect(realTx.first.id, 'real_tx_1');

      // Activate demo mode
      container.read(walletDemoModeProvider.notifier).setDemo(true);

      // Now returns demo data
      final demoTx = await container.read(walletTransactionsProvider(criteria).future);
      expect(demoTx.length, greaterThan(1));
      expect(demoTx.any((t) => t.id.startsWith('demo_tx_')), isTrue);

      // Deactivate demo mode
      container.read(walletDemoModeProvider.notifier).setDemo(false);

      // Returns real data again
      final revertedTx = await container.read(walletTransactionsProvider(criteria).future);
      expect(revertedTx.length, 1);
      expect(revertedTx.first.id, 'real_tx_1');
    });

    testWidgets('4. WalletScreen renders demo banner and allows toggling & reset', (tester) async {
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(FakeRealWalletRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: WalletScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially demo banner is not visible
      expect(find.text('Demo Mode Active'), findsNothing);

      // Tap demo mode toggle in AppBar
      final demoToggle = find.byTooltip('Presentation Demo Mode');
      expect(demoToggle, findsOneWidget);
      await tester.tap(demoToggle);
      await tester.pumpAndSettle();

      // Now demo banner is visible
      expect(find.text('Demo Mode Active'), findsOneWidget);
      expect(find.text('Presentation Only'), findsOneWidget);

      // Tap Reset button
      final resetButton = find.text('Reset');
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Demo banner disappears
      expect(find.text('Demo Mode Active'), findsNothing);
    });
  });
}
