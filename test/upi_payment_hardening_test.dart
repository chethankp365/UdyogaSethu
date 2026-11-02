import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/payments/data/payment_repository.dart';
import 'package:udyogasethu/features/payments/domain/payment_bill_summary.dart';
import 'package:udyogasethu/features/payments/domain/payment_models.dart';
import 'package:udyogasethu/features/payments/presentation/payment_checkout_screen.dart';
import 'package:udyogasethu/features/payments/presentation/payment_status_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockHardenPaymentRepository implements PaymentRepository {
  bool reconcileCalled = false;
  String? lastUpiFlow;
  String? lastUpiVpa;
  int orderCallCount = 0;

  @override
  Future<PaymentBillSummary> computeBill({
    required String refType,
    required String refId,
    bool? protectionOverride,
  }) async {
    return const PaymentBillSummary(
      baseAmountPaise: 50000,
      platformFeePaise: 2500,
      protectionFeePaise: 0,
      totalPaise: 52500,
      isProtected: true,
      description: 'Field Tilling Service',
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
    orderCallCount++;
    lastUpiFlow = upiFlow;
    lastUpiVpa = upiVpa;
    return PaymentOrderResult(
      paymentId: 'pay_upi_test_101',
      orderId: 'order_upi_101',
      keyId: 'rzp_test_abc123',
      amountPaise: 52500,
      currency: 'INR',
      receiptNo: 'RCP-20261024-001',
      status: 'created',
      method: method.name,
      upiString: 'upi://pay?pa=udyogasethu@icici&pn=UdyogaSethu&am=525.00&cu=INR&tn=RCP-20261024-001&tr=order_upi_101',
      upiFlow: upiFlow ?? 'intent',
      billSummary: const PaymentBillSummary(
        baseAmountPaise: 50000,
        platformFeePaise: 2500,
        protectionFeePaise: 0,
        totalPaise: 52500,
        isProtected: true,
        description: 'Field Tilling Service',
      ),
    );
  }

  @override
  Future<PaymentRecord> getPayment(String paymentId) async {
    return PaymentRecord(
      id: paymentId,
      payerId: 'user_01',
      payeeId: 'user_02',
      refType: 'assignment',
      refId: 'asg_999',
      amountPaise: 52500,
      platformFeePaise: 2500,
      method: PaymentMethod.upi,
      status: PaymentStatus.held,
      protected: true,
      signatureVerified: true,
      receiptNo: 'RCP-20261024-001',
      razorpayPaymentId: 'pay_rzp_999',
      razorpayOrderId: 'order_upi_101',
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<PaymentRecord?> streamPayment(String paymentId) {
    return Stream.value(
      PaymentRecord(
        id: paymentId,
        payerId: 'user_01',
        payeeId: 'user_02',
        refType: 'assignment',
        refId: 'asg_999',
        amountPaise: 52500,
        platformFeePaise: 2500,
        method: PaymentMethod.upi,
        status: PaymentStatus.created,
        protected: true,
        signatureVerified: false,
        receiptNo: 'RCP-20261024-001',
        razorpayPaymentId: null,
        razorpayOrderId: 'order_upi_101',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<int> getAvailableWalletBalancePaise() async => 100000;

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
  Future<Map<String, dynamic>> reconcilePayment(String paymentId) async {
    reconcileCalled = true;
    return {
      'reconciled': true,
      'status': 'held',
      'payment_id': paymentId,
      'message': 'Payment confirmed by bank',
    };
  }

  @override
  Future<bool> validateVpa(String vpa) async {
    final vpaRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    return vpaRegex.hasMatch(vpa.trim());
  }
}

Widget createTestApp(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  group('UPI Payment Hardening Unit Tests', () {
    late MockHardenPaymentRepository repo;

    setUp(() {
      repo = MockHardenPaymentRepository();
    });

    test('VPA validation regex accepts valid VPAs and rejects malformed ones', () async {
      expect(await repo.validateVpa('farmer.karnataka@okhdfcbank'), isTrue);
      expect(await repo.validateVpa('worker_98@paytm'), isTrue);
      expect(await repo.validateVpa('chethan-123@oksbi'), isTrue);

      // Invalid patterns
      expect(await repo.validateVpa('invalid_vpa_without_at'), isFalse);
      expect(await repo.validateVpa('@bank'), isFalse);
      expect(await repo.validateVpa('user@'), isFalse);
      expect(await repo.validateVpa('user@bank@extra'), isFalse);
      expect(await repo.validateVpa(' '), isFalse);
    });

    test('PaymentOrderResult parses upiString and upiFlow correctly from JSON', () {
      final json = {
        'payment_id': 'pay_999',
        'order_id': 'order_888',
        'key_id': 'rzp_key',
        'amount_paise': 73500,
        'currency': 'INR',
        'receipt_no': 'RCP-001',
        'status': 'created',
        'method': 'upi',
        'upi_string': 'upi://pay?pa=merchant@icici&pn=UdyogaSethu&am=735.00&cu=INR',
        'upi_flow': 'qr',
      };

      final deserialized = PaymentOrderResult.fromJson(json);
      expect(deserialized.paymentId, 'pay_999');
      expect(deserialized.orderId, 'order_888');
      expect(deserialized.upiString, 'upi://pay?pa=merchant@icici&pn=UdyogaSethu&am=735.00&cu=INR');
      expect(deserialized.upiFlow, 'qr');
      expect(deserialized.amountPaise, 73500);
    });

    test('reconcilePayment updates mock state and returns server response', () async {
      expect(repo.reconcileCalled, isFalse);
      final res = await repo.reconcilePayment('pay_upi_test_101');
      expect(repo.reconcileCalled, isTrue);
      expect(res['reconciled'], isTrue);
      expect(res['status'], 'held');
    });
  });

  group('UPI Checkout & Status UI Widget Tests', () {
    testWidgets('PaymentCheckoutScreen renders UPI sub-options and validates VPA input', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockHardenPaymentRepository();

      await tester.pumpWidget(
        createTestApp(
          const PaymentCheckoutScreen(
            refType: 'assignment',
            refId: 'asg_999',
          ),
          overrides: [
            paymentRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Find UPI method tile and tap it
      final upiTile = find.text('UPI (GPay / PhonePe / Paytm)');
      expect(upiTile, findsOneWidget);
      await tester.tap(upiTile);
      await tester.pumpAndSettle();

      // Verify sub-options appear: App Intent, Dynamic QR, VPA Collect
      expect(find.text('UPI Apps (GPay, PhonePe, Paytm)'), findsOneWidget);
      expect(find.text('Dynamic UPI QR Code'), findsOneWidget);
      expect(find.text('Enter UPI ID / VPA'), findsOneWidget);

      // Select VPA Collect
      await tester.tap(find.text('Enter UPI ID / VPA'));
      await tester.pumpAndSettle();

      // Verify text field appears
      expect(find.byType(TextField), findsOneWidget);

      // Enter invalid VPA and tap Pay
      await tester.enterText(find.byType(TextField), 'malformed_vpa');
      await tester.pumpAndSettle();

      final payButton = find.byType(ElevatedButton);
      expect(payButton, findsOneWidget);
      await tester.ensureVisible(payButton);
      await tester.tap(payButton);
      await tester.pumpAndSettle();

      // Verify validation error on the text field
      expect(find.text('Please enter a valid UPI ID (e.g. name@bank)'), findsOneWidget);
      expect(repo.orderCallCount, 0); // Guarded: not called
    });

    testWidgets('PaymentStatusScreen has Check Bank Status button that triggers reconciliation', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockHardenPaymentRepository();

      await tester.pumpWidget(
        createTestApp(
          const PaymentStatusScreen(
            paymentId: 'pay_upi_test_101',
          ),
          overrides: [
            paymentRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );

      // Pump initial render without pumpAndSettle because CircularProgressIndicator spins continuously
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Look for the Check Bank Status button
      final verifyBtn = find.text('Check Bank Status');
      expect(verifyBtn, findsOneWidget);

      await tester.tap(verifyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.reconcileCalled, isTrue);
    });
  });
}
