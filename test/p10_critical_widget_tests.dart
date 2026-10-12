import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/theme/app_theme.dart';
import 'package:udyogasethu/core/widgets/empty_state.dart';
import 'package:udyogasethu/core/widgets/error_state.dart';
import 'package:udyogasethu/core/widgets/job_card.dart';
import 'package:udyogasethu/features/auth/presentation/otp_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/language_screen.dart';
import 'package:udyogasethu/features/onboarding/presentation/role_tree_screen.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_balance.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

Widget buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // =========================================================================
  // 1. ROLE-SELECTION SCREENS
  // =========================================================================
  group('P10.4 Widget - Role Selection Screen', () {
    testWidgets('RoleTreeScreen renders step 1 options and navigates steps', (tester) async {
      await tester.pumpWidget(buildTestApp(const RoleTreeScreen()));
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Who are you?'), findsOneWidget);

      // Category cards by Key
      expect(find.byKey(const Key('cardWorker')), findsOneWidget);
      expect(find.byKey(const Key('cardFarmer')), findsOneWidget);

      // Select Farmer card
      await tester.tap(find.byKey(const Key('cardFarmer')));
      await tester.pumpAndSettle();

      // Continue button should be present
      expect(find.byKey(const Key('roleTreeContinueButton')), findsOneWidget);
    });
  });

  // =========================================================================
  // 2. OTP INPUT AND VALIDATION
  // =========================================================================
  group('P10.4 Widget - OTP Input & Validation', () {
    testWidgets('OtpScreen renders 6-digit pinput and action buttons', (tester) async {
      await tester.pumpWidget(buildTestApp(const OtpScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.byKey(const Key('otpPinputField')), findsOneWidget);
      expect(find.byKey(const Key('verifyOtpButton')), findsOneWidget);
      expect(find.byKey(const Key('resendOtpButton')), findsOneWidget);
      expect(find.byKey(const Key('changeNumberButton')), findsOneWidget);
    });
  });

  // =========================================================================
  // 3. LANGUAGE SWITCHING
  // =========================================================================
  group('P10.4 Widget - Language Switching', () {
    testWidgets('LanguageScreen displays multiple language options and triggers selection', (tester) async {
      await tester.pumpWidget(buildTestApp(const LanguageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Choose your language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('ಕನ್ನಡ (Kannada)'), findsOneWidget);
      expect(find.text('हिंदी (Hindi)'), findsOneWidget);
      expect(find.text('తెలుగు (Telugu)'), findsOneWidget);

      // Tap Kannada option
      await tester.tap(find.text('ಕನ್ನಡ (Kannada)'));
      await tester.pumpAndSettle();

      expect(find.text('Continue ->'), findsOneWidget);
    });
  });

  // =========================================================================
  // 4. JOB-CARD STATES
  // =========================================================================
  group('P10.4 Widget - Job-Card States', () {
    testWidgets('JobCard renders verified employer, pay rate, distance, and hot badge', (tester) async {
      bool applied = false;
      bool tapped = false;

      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            body: JobCard(
              title: 'Farm Labour Harvest',
              employerName: 'Mysore Organic Farms',
              isEmployerVerified: true,
              rating: 4.8,
              reviewCount: 32,
              distanceText: '2.5 km away',
              payRateText: '₹650 / day',
              isHotJobBadge: 'Urgent',
              onApply: () => applied = true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Farm Labour Harvest'), findsOneWidget);
      expect(find.text('Mysore Organic Farms'), findsOneWidget);
      expect(find.text('₹650 / day'), findsOneWidget);
      expect(find.textContaining('2.5 km away'), findsOneWidget);
      expect(find.text('🔥 Urgent'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify apply button interaction
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(applied, isTrue);

      // Verify card tap interaction
      await tester.tap(find.text('Farm Labour Harvest'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  // =========================================================================
  // 5. WALLET AMOUNTS USING INDIAN NUMBER GROUPING
  // =========================================================================
  group('P10.4 Widget - Wallet Indian Currency Formatting', () {
    testWidgets('Renders wallet amounts formatted with standard Indian lakh/crore commas', (tester) async {
      const balance = WalletBalance(
        walletId: 'test-wallet-1',
        availablePaise: 12500000, // ₹1,25,000
        escrowPaise: 500000,      // ₹5,000
        pendingPaise: 75000,      // ₹750
        rewardPaise: 100000,      // ₹1,000
        totalBalancePaise: 13000000,
        todayCreditPaise: 250000, // ₹2,500
      );

      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            body: Column(
              children: [
                Text('Available: ${balance.formattedAvailable}'),
                Text('Escrow: ${balance.formattedEscrow}'),
                Text('Total: ${balance.formattedTotal}'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Available: ₹1,25,000'), findsOneWidget);
      expect(find.text('Escrow: ₹5,000'), findsOneWidget);
      expect(find.text('Total: ₹1,30,000'), findsOneWidget);
    });
  });

  // =========================================================================
  // 6. ERROR, LOADING, EMPTY, OFFLINE AND RETRY STATES
  // =========================================================================
  group('P10.4 Widget - Error, Empty, and Retry States', () {
    testWidgets('EmptyState renders message, icon, and optional action', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            body: EmptyState(
              title: 'No Jobs Found',
              description: 'Try adjusting your search or category filters.',
              actionLabel: 'Reset Filters',
              onActionTap: () => actionTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Jobs Found'), findsOneWidget);
      expect(find.text('Try adjusting your search or category filters.'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);

      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();
      expect(actionTapped, isTrue);
    });

    testWidgets('ErrorState renders error message and triggers retry callback', (tester) async {
      bool retryTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            body: ErrorState(
              title: 'Network Connection Lost',
              message: 'Could not connect to server. Check your internet connection.',
              retryLabel: 'Retry Now',
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network Connection Lost'), findsOneWidget);
      expect(find.text('Could not connect to server. Check your internet connection.'), findsOneWidget);
      expect(find.text('Retry Now'), findsOneWidget);

      await tester.tap(find.text('Retry Now'));
      await tester.pumpAndSettle();
      expect(retryTapped, isTrue);
    });
  });
}
