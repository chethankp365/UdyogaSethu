import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/job_row.dart';
import 'package:udyogasethu/features/farmer/domain/produce_listing_model.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_marketplace_item.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_order.dart';
import 'package:udyogasethu/features/provider/domain/job_applicant.dart';
import 'package:udyogasethu/features/provider/domain/nearby_worker.dart';
import 'package:udyogasethu/features/provider/domain/provider_active_booking.dart';
import 'package:udyogasethu/features/provider/domain/provider_job.dart';
import 'package:udyogasethu/features/provider/presentation/job_applicants_screen.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_transaction.dart';
import 'package:udyogasethu/features/wallet/presentation/widgets/transaction_tile.dart';
import 'package:udyogasethu/features/marketplace/domain/subscription_model.dart';
import 'package:udyogasethu/features/marketplace/domain/group_order_model.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/subscription_card.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/group_order_card.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/create_subscription_modal.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/create_group_order_modal.dart';
import 'package:udyogasethu/features/marketplace/presentation/widgets/join_group_order_modal.dart';
import 'package:udyogasethu/features/marketplace/presentation/subscriptions_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/pest_ai_doc_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/soil_ai_test_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/irrigation_ai_screen.dart';
import 'package:udyogasethu/features/farmer/presentation/govt_schemes_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testWidths = [320.0, 360.0, 393.0, 412.0, 480.0, 600.0];
  const testTextScales = [1.0, 1.3, 1.6, 2.0];
  const testLocales = [
    Locale('en'),
    Locale('kn'),
    Locale('hi'),
    Locale('ta'),
    Locale('te'),
  ];

  // Realistic Long Test Data
  final longJob = const JobRecommendation(
    id: 'j-long-1',
    providerId: 'p-1',
    title: 'High-Rise Commercial Complex Interior Master Painting and Touchup Specialist',
    wageType: 'daily',
    wagePaise: 150000,
    employerName: 'Dr. Srikanthan Chandrasekharan Venkataraman Builders & Developers',
    employerRating: 4.9,
    employerVerified: true,
    categorySlug: 'painting',
    distanceM: 14800,
    studentsOk: true,
    reasons: ['Top skill match in painting', 'Close to your preferred route'],
  );

  final longApplicant = JobApplicant(
    applicationId: 'app-long-1',
    jobId: 'j-long-1',
    workerId: 'w-1',
    workerName: 'Dr. Srikanthan Chandrasekharan Venkataraman',
    workerAvatar: null,
    seekerType: 'student',
    levelNumber: 4,
    badgeName: 'Registered Worker (Unverified Background)',
    rating: 4.8,
    jobsCompletedCount: 38,
    distanceM: 12500,
    status: 'pending',
    createdAt: DateTime.now(),
    skills: ['Electrical Maintenance', 'Switchboard Repair', 'Three-Phase Wiring'],
    languages: ['Kannada (Fluent)', 'Telugu (Intermediate)'],
    message: 'I have 5 years of commercial industrial experience and my own tools ready to start immediately.',
    isVerified: true,
  );

  final sampleProviderJob = ProviderJob(
    id: 'j-long-1',
    providerId: 'p-1',
    title: 'High-Rise Commercial Complex Interior Master Painting and Touchup Specialist',
    description: 'Complete commercial wall preparation and painting',
    categoryName: 'Painting',
    slotsTotal: 5,
    slotsFilled: 2,
    wagePaise: 150000,
    wageType: 'daily',
    startAt: DateTime.now(),
    status: 'open',
    addressText: 'Flat 402, Building C, Sri Lakshmi Venkateshwara Residency, Bengaluru',
    createdAt: DateTime.now(),
  );

  final longBooking = ProviderActiveBooking(
    assignmentId: 'asg-1',
    jobId: 'j-1',
    bookingCode: 'BOOK-984210',
    jobTitle: 'Emergency Commercial Electrical Wiring and Switchboard Replacement',
    roleName: 'Electrician',
    workerId: 'w-1',
    workerName: 'Dr. Srikanthan Chandrasekharan Venkataraman',
    workerVerified: true,
    addressText: 'Flat 402, Building C, Sri Lakshmi Venkateshwara Residency, 17th Cross, 5th Main Road, HSR Layout Sector 2, Bengaluru, Karnataka 560102',
    scheduledStart: DateTime.now(),
    scheduledEnd: DateTime.now().add(const Duration(hours: 8)),
    escrowWagePaise: 185000,
    status: 'assigned',
  );

  final longWorker = const NearbyWorker(
    userId: 'w-1',
    fullName: 'Dr. Srikanthan Chandrasekharan Venkataraman',
    headline: 'Experienced Senior Electrician & Industrial Wiring Specialist',
    dailyRatePaise: 75000,
    hourlyRatePaise: 12000,
    ratingAvg: 4.9,
    ratingCount: 35,
    jobsCompleted: 42,
    isVerifiedBadge: true,
    distanceM: 8400,
    languages: ['kn', 'en', 'hi'],
  );

  final longProduce = ProduceMarketplaceItem(
    id: 'prod-1',
    farmerId: 'f-1',
    farmerName: 'Dr. Srikanthan Chandrasekharan',
    farmName: 'Sri Lakshmi Venkateshwara Agro Organic Farms',
    name: 'Naturally Ripened Organic Alphonso Mangoes Premium Export Grade',
    category: 'fruits',
    pricePaise: 145000,
    unit: '5kg crate',
    stockQty: 250,
    lotNumber: 'LOT-2026-MNG-9842',
    status: ProduceStatus.active,
    farmingMethod: 'Certified Natural Zero-Budget Vedic Farming',
    distanceM: 16200,
    farmerRatingAvg: 4.9,
    isVerifiedFarmer: true,
    createdAt: DateTime.now(),
  );

  final longOrder = ProduceOrder(
    orderId: 'ord-1',
    orderCode: 'ORD-2026-BLR-894210',
    farmerId: 'f-1',
    farmerName: 'Sri Lakshmi Venkateshwara Agro Organic Farm',
    totalPaise: 485000,
    feePaise: 2500,
    discountPaise: 0,
    status: 'out_for_delivery',
    itemsCount: 12,
    fulfilment: 'delivery',
    protected: true,
    createdAt: DateTime.now(),
  );

  /// Helper to test a widget across dimensions and report failures
  Future<void> runOverflowMatrix({
    required WidgetTester tester,
    required String testName,
    required Widget Function(BuildContext context, AppLocalizations l10n) builder,
    List<double> widths = testWidths,
    List<double> scales = testTextScales,
    List<Locale> locales = testLocales,
  }) async {
    for (final width in widths) {
      for (final textScale in scales) {
        for (final loc in locales) {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          String? detectedOverflow;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflowed by') || msg.contains('RenderFlex overflowed')) {
              detectedOverflow = details.toString();
            }
          };

          try {
            await tester.pumpWidget(
              ProviderScope(
                child: MaterialApp(
                  locale: loc,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: Builder(
                      builder: (ctx) {
                        final l10n = AppLocalizations.of(ctx)!;
                        return MediaQuery(
                          data: MediaQueryData(
                            size: Size(width, 1000),
                            textScaler: TextScaler.linear(textScale),
                          ),
                          child: SingleChildScrollView(
                            child: builder(ctx, l10n),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
          } finally {
            FlutterError.onError = prevOnError;
          }

          final exc = tester.takeException();
          if (exc != null && detectedOverflow == null) {
            if (exc.toString().contains('overflowed')) {
              detectedOverflow = exc.toString();
            }
          }

          expect(
            detectedOverflow,
            isNull,
            reason: '$testName OVERFLOWED at width ${width.toInt()}dp, scale $textScale, locale ${loc.languageCode}:\n$detectedOverflow',
          );
        }
      }
    }
  }

  final longTransaction = WalletTransaction(
    id: 'tx-long-1',
    direction: 'credit',
    amountPaise: 18500000,
    bucket: 'available',
    refType: 'booking',
    refId: 'BOOK-984210',
    note: 'Daily wage payment escrow release for industrial electrical wiring shift',
    createdAt: DateTime.now(),
    type: WalletTransactionType.dailyWage,
    feePaise: 500,
    counterpartyName: 'Dr. Srikanthan Chandrasekharan Venkataraman Developers',
    linkedItemTitle: 'Commercial Complex Three-Phase Switchboard Wiring and Installation',
    rawStatus: 'released',
  );

  group('Automated Layout Overflow Finder Suite', () {
    testWidgets('JobRow card layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'JobRow',
        builder: (ctx, l10n) => JobRow(job: longJob),
      );
    });

    testWidgets('ApplicantCard layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'ApplicantCard',
        builder: (ctx, l10n) => ApplicantCard(
          applicant: longApplicant,
          job: sampleProviderJob,
          onHire: () {},
          onShortlist: () {},
          onReject: () {},
          onViewProfile: () {},
          onChat: () {},
        ),
      );
    });

    testWidgets('TransactionTile layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'TransactionTile',
        builder: (ctx, l10n) => TransactionTile(transaction: longTransaction),
      );
    });

    testWidgets('Photo Picker Buttons layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'PhotoPickerButtons',
        builder: (ctx, l10n) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D6548),
                side: const BorderSide(color: Color(0xFF0D6548)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_camera_rounded, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.takePhotoCamera,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D6548),
                side: const BorderSide(color: Color(0xFF0D6548)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_rounded, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.chooseGallery,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });

    testWidgets('Wallet Hero Balance Card layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'WalletHeroCard',
        builder: (ctx, l10n) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D6548),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹1,85,000.00',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0D6548),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      ),
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_outward_rounded, size: 18),
                          SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      ),
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 18),
                          SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Scan UPI QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('Scrollable TabBar layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'ScrollableTabBar',
        builder: (ctx, l10n) => DefaultTabController(
          length: 3,
          child: Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.headerGreenDark,
              indicatorWeight: 3,
              labelColor: AppColors.headerGreenDark,
              tabs: [
                Tab(text: '${l10n.providerTabOpen} (12)'),
                Tab(text: '${l10n.providerTabFilled} (4)'),
                Tab(text: '${l10n.providerTabCompleted} (28)'),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('ProviderActiveBookingCard layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'ProviderActiveBookingCard',
        builder: (ctx, l10n) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      longBooking.jobTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.paleMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        longBooking.bookingCode,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    'Worker: ${longBooking.workerName}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  if (longBooking.workerVerified)
                    const Text('(Aadhaar Verified ✓)', style: TextStyle(fontSize: 11, color: AppColors.headerGreenDark, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      longBooking.addressText,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '• ${longBooking.formattedEscrowWage}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(l10n.hubWorkerNotArrived, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.headerGreenDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(l10n.hubProtectedChat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('WorkerCard layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'WorkerCard',
        builder: (ctx, l10n) => Card(
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.paleMint,
              child: Text(longWorker.fullName[0]),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    longWorker.fullName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (longWorker.isVerifiedBadge) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 14, color: AppColors.headerGreenDark),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(longWorker.headline, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.amberOrange),
                          const SizedBox(width: 2),
                          Text('${longWorker.ratingAvg.toStringAsFixed(1)} • ${longWorker.formattedDistance}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(longWorker.formattedRate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                    ),
                  ],
                ),
              ],
            ),
            trailing: SizedBox(
              width: 90,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                ),
                onPressed: () {},
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.hubBookWorker, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('CustomerOrderCard layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'CustomerOrderCard',
        builder: (ctx, l10n) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        longOrder.orderCode,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      color: AppColors.paleMint,
                      child: const Text('Delivering', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  children: [
                    const Icon(Icons.storefront, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            longOrder.farmerName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${longOrder.itemsCount} produce items • Farm Delivery',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          longOrder.formattedTotal,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('ProduceCard layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'ProduceCard',
        builder: (ctx, l10n) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.eco, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            longProduce.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            children: [
                              Text(longProduce.farmingMethod, style: const TextStyle(fontSize: 12)),
                              const Text('•'),
                              Text(longProduce.freshnessLabel, style: const TextStyle(fontSize: 11.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          longProduce.formattedPrice,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('SubscriptionCard layout overflow check', (tester) async {
      final sampleSub = ProduceSubscription(
        id: 'sub-test-1',
        customerId: 'cust-1',
        farmerId: 'farm-1',
        listingId: 'list-1',
        quantity: 2.0,
        frequency: SubscriptionFrequency.daily,
        status: SubscriptionStatus.active,
        deliverySlotTime: '07:00 AM',
        unitPricePaise: 6000,
        listingName: 'A2 Farm Milk Daily Subscription, 2 litres, 7:00 AM doorstep',
        farmerName: 'Pure A2 Gir Cow Farm, Devanahalli Cluster',
        createdAt: DateTime.now(),
      );
      await runOverflowMatrix(
        tester: tester,
        testName: 'SubscriptionCard',
        builder: (ctx, l10n) => SubscriptionCard(
          subscription: sampleSub,
          onTogglePause: () {},
          onSkipTomorrow: () {},
          onUpdateQuantity: (_) {},
        ),
      );
    });

    testWidgets('GroupOrderCard layout overflow check', (tester) async {
      final sampleGroup = GroupOrder(
        id: 'grp-test-1',
        organizerId: 'org-1',
        organizerName: 'Anita V. (Tower A Secretary)',
        listingId: 'list-1',
        listingName: 'Naturally Ripened Organic Alphonso Mangoes Premium 5kg Farm Crates',
        produceCategory: 'fruits',
        communityName: 'Prestige Falcon City Apartments, Koramangala South',
        targetQty: 30.0,
        currentQty: 22.0,
        priceTiers: const [
          GroupPriceTier(minQty: 10, pricePaise: 65000),
          GroupPriceTier(minQty: 20, pricePaise: 58000),
          GroupPriceTier(minQty: 30, pricePaise: 50000),
        ],
        deadline: DateTime.now().add(const Duration(hours: 36)),
        status: GroupOrderStatus.open,
        effectivePricePaise: 58000,
        memberCount: 7,
        hasJoined: true,
        userQty: 5.0,
        paid: true,
        createdAt: DateTime.now(),
      );
      await runOverflowMatrix(
        tester: tester,
        testName: 'GroupOrderCard',
        builder: (ctx, l10n) => GroupOrderCard(
          groupOrder: sampleGroup,
          onJoinTap: () {},
        ),
      );
    });

    testWidgets('CreateSubscriptionModal layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'dialog_create_subscription_modal',
        builder: (ctx, l10n) => const CreateSubscriptionModal(),
      );
    });

    testWidgets('CreateGroupOrderModal layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'dialog_create_group_order_modal',
        builder: (ctx, l10n) => const CreateGroupOrderModal(),
      );
    });

    testWidgets('JoinGroupOrderModal layout overflow check', (tester) async {
      final sampleGroup = GroupOrder(
        id: 'grp-test-1',
        organizerId: 'org-1',
        organizerName: 'Anita V. (Tower A Secretary)',
        listingId: 'list-1',
        listingName: 'Naturally Ripened Organic Alphonso Mangoes Premium 5kg Farm Crates',
        produceCategory: 'fruits',
        communityName: 'Prestige Falcon City Apartments, Koramangala South',
        targetQty: 30.0,
        currentQty: 22.0,
        priceTiers: const [
          GroupPriceTier(minQty: 10, pricePaise: 65000),
          GroupPriceTier(minQty: 20, pricePaise: 58000),
          GroupPriceTier(minQty: 30, pricePaise: 50000),
        ],
        deadline: DateTime.now().add(const Duration(hours: 36)),
        status: GroupOrderStatus.open,
        effectivePricePaise: 58000,
        memberCount: 7,
        hasJoined: true,
        userQty: 5.0,
        paid: true,
        createdAt: DateTime.now(),
      );
      await runOverflowMatrix(
        tester: tester,
        testName: 'dialog_join_group_order_modal',
        builder: (ctx, l10n) => JoinGroupOrderModal(groupOrder: sampleGroup),
      );
    });

    testWidgets('SubscriptionsScreen layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'SubscriptionsScreen',
        builder: (ctx, l10n) => const SubscriptionsScreen(),
      );
    });

    testWidgets('PestAiDocScreen layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'PestAiDocScreen',
        builder: (ctx, l10n) => const PestAiDocScreen(),
      );
    });

    testWidgets('SoilAiTestScreen layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'SoilAiTestScreen',
        builder: (ctx, l10n) => const SoilAiTestScreen(),
      );
    });

    testWidgets('IrrigationAiScreen layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'IrrigationAiScreen',
        builder: (ctx, l10n) => const IrrigationAiScreen(),
      );
    });

    testWidgets('GovtSchemesScreen layout overflow check', (tester) async {
      await runOverflowMatrix(
        tester: tester,
        testName: 'GovtSchemesScreen',
        builder: (ctx, l10n) => const GovtSchemesScreen(),
      );
    });
  });
}
