import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/payments/data/payment_repository.dart';
import 'package:udyogasethu/features/payments/domain/payment_bill_summary.dart';
import 'package:udyogasethu/features/payments/domain/payment_models.dart';
import 'package:udyogasethu/features/payments/domain/payment_receipt_pdf.dart';
import 'package:udyogasethu/features/payments/presentation/payment_status_screen.dart';
import 'package:udyogasethu/features/payments/presentation/widgets/bill_summary_card.dart';
import 'package:udyogasethu/features/payments/presentation/widgets/payment_method_tile.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockPaymentRepository implements PaymentRepository {
  PaymentRecord? mockPayment;
  bool createOrderShouldThrow;
  int availableWalletBalance;

  MockPaymentRepository({
    this.mockPayment,
    this.createOrderShouldThrow = false,
    this.availableWalletBalance = 500000,
  });

  @override
  Future<PaymentBillSummary> computeBill({
    required String refType,
    required String refId,
    bool? protectionOverride,
  }) async {
    return const PaymentBillSummary(
      baseAmountPaise: 70000,
      platformFeePaise: 3500,
      protectionFeePaise: 0,
      totalPaise: 73500,
      isProtected: true,
      description: 'Farm Harvesting Daily Wage',
    );
  }

  @override
  Future<PaymentOrderResult> createOrder({
    required String refType,
    required String refId,
    required PaymentMethod method,
    bool? protectionOverride,
    String? upiFlow,
    String? upiVpa,
  }) async {
    if (createOrderShouldThrow) {
      throw Exception('Server error creating order');
    }
    return PaymentOrderResult(
      paymentId: 'pay-test-123',
      orderId: 'order_test_987',
      keyId: 'rzp_test_public_key',
      amountPaise: 73500,
      currency: 'INR',
      receiptNo: 'RCP-20261009-000001',
      status: 'created',
      method: method.name,
      upiString: 'upi://pay?pa=rzp.test@hdfcbank&pn=UdyogaSethu&am=735.00&cu=INR&tn=RCP-20261009-000001&tr=order_test_987',
      upiFlow: upiFlow ?? 'intent',
      billSummary: const PaymentBillSummary(
        baseAmountPaise: 70000,
        platformFeePaise: 3500,
        protectionFeePaise: 0,
        totalPaise: 73500,
        isProtected: true,
        description: 'Farm Harvesting Daily Wage',
      ),
    );
  }

  @override
  Future<PaymentRecord> getPayment(String paymentId) async {
    return mockPayment ??
        PaymentRecord(
          id: paymentId,
          payerId: 'user-payer-1',
          payeeId: 'user-payee-2',
          refType: 'assignment',
          refId: 'asg-test-456',
          amountPaise: 73500,
          platformFeePaise: 3500,
          method: PaymentMethod.card,
          status: PaymentStatus.held,
          protected: true,
          signatureVerified: true,
          receiptNo: 'RCP-20261009-000001',
          razorpayPaymentId: 'pay_test_rzp_captured',
          razorpayOrderId: 'order_test_987',
          createdAt: DateTime.now(),
        );
  }

  @override
  Stream<PaymentRecord?> streamPayment(String paymentId) {
    return Stream.value(
      mockPayment ??
          PaymentRecord(
            id: paymentId,
            payerId: 'user-payer-1',
            payeeId: 'user-payee-2',
            refType: 'assignment',
            refId: 'asg-test-456',
            amountPaise: 73500,
            platformFeePaise: 3500,
            method: PaymentMethod.card,
            status: PaymentStatus.held,
            protected: true,
            signatureVerified: true,
            receiptNo: 'RCP-20261009-000001',
            razorpayPaymentId: 'pay_test_rzp_captured',
            razorpayOrderId: 'order_test_987',
            createdAt: DateTime.now(),
          ),
    );
  }

  @override
  Future<int> getAvailableWalletBalancePaise() async {
    return availableWalletBalance;
  }

  @override
  Future<bool> releaseAssignmentEscrow(String assignmentId) async => true;

  @override
  Future<bool> confirmJobCompletionAndRelease(String assignmentId) async => true;

  @override
  Future<bool> refundEscrow(String paymentId, {int? refundPaise, String? reason}) async => true;

  @override
  Future<bool> refundAssignmentEscrow(String assignmentId, {int? refundPaise, String? reason}) async => true;

  @override
  Future<bool> releaseOrderEscrow(String orderId) async => true;

  @override
  Future<Map<String, dynamic>> reconcilePayment(String paymentId) async => {
    'reconciled': true,
    'status': 'held',
    'payment_id': paymentId,
    'message': 'Payment confirmed',
  };

  @override
  Future<bool> validateVpa(String vpa) async => vpa.contains('@');
}

Widget createTestWidget(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Payment Domain Models & Helpers', () {
    test('PaymentRecord Indian currency formatting formats standard and fractional values correctly', () {
      expect(PaymentRecord.formatIndianCurrency(0), '₹0');
      expect(PaymentRecord.formatIndianCurrency(100), '₹1');
      expect(PaymentRecord.formatIndianCurrency(70000), '₹700');
      expect(PaymentRecord.formatIndianCurrency(1525000), '₹15,250');
      expect(PaymentRecord.formatIndianCurrency(10000000), '₹1,00,000');
      expect(PaymentRecord.formatIndianCurrency(123456789), '₹12,34,567.89');
    });

    test('PaymentRecord JSON serialization and deserialization preserves all fields', () {
      final json = {
        'id': 'pay-abc-123',
        'receipt_no': 'RCP-20261009-000099',
        'ref_type': 'assignment',
        'ref_id': 'asg-999',
        'payer_id': 'payer-1',
        'payee_id': 'payee-2',
        'amount_paise': 73500,
        'platform_fee_paise': 3500,
        'method': 'upi',
        'status': 'held',
        'protected': true,
        'signature_verified': true,
        'razorpay_order_id': 'order_123',
        'razorpay_payment_id': 'pay_456',
        'created_at': '2026-10-09T08:00:00Z',
      };

      final record = PaymentRecord.fromJson(json);
      expect(record.id, 'pay-abc-123');
      expect(record.receiptNo, 'RCP-20261009-000099');
      expect(record.refType, 'assignment');
      expect(record.amountPaise, 73500);
      expect(record.platformFeePaise, 3500);
      expect(record.method, PaymentMethod.upi);
      expect(record.status, PaymentStatus.held);
      expect(record.protected, true);
      expect(record.razorpayPaymentId, 'pay_456');

      final serialized = record.toJson();
      expect(serialized['id'], 'pay-abc-123');
      expect(serialized['method'], 'upi');
      expect(serialized['status'], 'held');
      expect(serialized['protected'], true);
    });

    test('PaymentBillSummary and PaymentOrderResult parse JSON correctly', () {
      final summaryJson = {
        'base_amount_paise': 80000,
        'platform_fee_paise': 4000,
        'protection_fee_paise': 0,
        'total_paise': 84000,
        'is_protected': true,
        'description': 'Paddy Sowing',
      };
      final summary = PaymentBillSummary.fromJson(summaryJson);
      expect(summary.totalPaise, 84000);
      expect(summary.baseAmountPaise, 80000);
      expect(summary.platformFeePaise, 4000);
      expect(summary.isProtected, true);

      final orderJson = {
        'payment_id': 'pay-1',
        'order_id': 'order_rzp_99',
        'key_id': 'rzp_test_public_key',
        'amount_paise': 84000,
        'currency': 'INR',
        'receipt_no': 'RCP-20261009-000100',
        'status': 'created',
        'method': 'card',
        'bill_summary': summaryJson,
      };
      final orderResult = PaymentOrderResult.fromJson(orderJson);
      expect(orderResult.orderId, 'order_rzp_99');
      expect(orderResult.keyId, 'rzp_test_public_key');
      expect(orderResult.amountPaise, 84000);
      expect(orderResult.billSummary.totalPaise, 84000);
    });
  });

  group('PDF Receipt Generator', () {
    test('PaymentReceiptPdf generates valid PDF bytes for protected payment', () async {
      final payment = PaymentRecord(
        id: 'pay-pdf-test-1',
        payerId: 'user-payer-1',
        payeeId: 'user-payee-2',
        refType: 'assignment',
        refId: 'asg-test-456',
        amountPaise: 73500,
        platformFeePaise: 3500,
        method: PaymentMethod.card,
        status: PaymentStatus.held,
        protected: true,
        signatureVerified: true,
        receiptNo: 'RCP-20261009-000001',
        razorpayPaymentId: 'pay_test_rzp_captured',
        razorpayOrderId: 'order_test_987',
        createdAt: DateTime.now(),
      );

      final Uint8List pdfBytes = await PaymentReceiptPdf.generate(payment);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF documents start with '%PDF-'
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });

  group('Payment UI Widgets', () {
    testWidgets('BillSummaryCard renders wage, platform fee, total, and escrow note', (tester) async {
      const summary = PaymentBillSummary(
        baseAmountPaise: 70000,
        platformFeePaise: 3500,
        protectionFeePaise: 0,
        totalPaise: 73500,
        isProtected: true,
        description: 'Farm Harvesting Daily Wage',
      );

      await tester.pumpWidget(
        createTestWidget(
          const BillSummaryCard(bill: summary),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bill Summary'), findsOneWidget);
      expect(find.text('₹700'), findsOneWidget);
      expect(find.text('₹35'), findsOneWidget);
      expect(find.text('₹735'), findsOneWidget);
      expect(find.textContaining('Protected until verified completion'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });

    testWidgets('PaymentMethodTile renders title, subtitle, and responds to tap', (tester) async {
      var selected = false;

      await tester.pumpWidget(
        createTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return PaymentMethodTile(
                method: PaymentMethod.upi,
                isSelected: selected,
                requiredAmountPaise: 73500,
                onTap: () {
                  setState(() {
                    selected = true;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('UPI (GPay / PhonePe / Paytm)'), findsOneWidget);
      expect(find.text('Instant bank transfer via any UPI app'), findsOneWidget);

      await tester.tap(find.text('UPI (GPay / PhonePe / Paytm)'));
      await tester.pumpAndSettle();

      expect(selected, isTrue);
    });

    testWidgets('PaymentStatusScreen renders confirmed state with receipt details', (tester) async {
      final mockRepo = MockPaymentRepository(
        mockPayment: PaymentRecord(
          id: 'pay-test-success',
          payerId: 'user-payer-1',
          payeeId: 'user-payee-2',
          refType: 'assignment',
          refId: 'asg-test-456',
          amountPaise: 73500,
          platformFeePaise: 3500,
          method: PaymentMethod.card,
          status: PaymentStatus.held,
          protected: true,
          signatureVerified: true,
          receiptNo: 'RCP-20261009-000042',
          razorpayPaymentId: 'pay_test_captured_123',
          razorpayOrderId: 'order_test_987',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          const PaymentStatusScreen(paymentId: 'pay-test-success'),
          overrides: [
            paymentRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      // Pump once and pump with duration to avoid infinite MicFab pulse loop
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Payment Successful and Confirmed'), findsOneWidget);
      expect(find.text('RCP-20261009-000042'), findsOneWidget);
      expect(find.text('₹735'), findsOneWidget);
      expect(find.text('pay_test_captured_123'), findsOneWidget);
      expect(find.text('Share / Download PDF Receipt'), findsOneWidget);
      expect(find.text('Continue to Job / Order'), findsOneWidget);
    });

    testWidgets('PaymentStatusScreen renders failure state with retry option', (tester) async {
      final mockRepo = MockPaymentRepository(
        mockPayment: PaymentRecord(
          id: 'pay-test-failed',
          payerId: 'user-payer-1',
          payeeId: 'user-payee-2',
          refType: 'assignment',
          refId: 'asg-test-456',
          amountPaise: 73500,
          platformFeePaise: 3500,
          method: PaymentMethod.card,
          status: PaymentStatus.failed,
          protected: true,
          signatureVerified: false,
          receiptNo: 'RCP-20261009-000043',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          const PaymentStatusScreen(paymentId: 'pay-test-failed'),
          overrides: [
            paymentRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      // Pump once and pump with duration to avoid infinite MicFab pulse loop
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Payment Failed'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
