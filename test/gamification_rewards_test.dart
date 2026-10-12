import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/rewards/data/rewards_repository.dart';
import 'package:udyogasethu/features/rewards/domain/gamification_models.dart';
import 'package:udyogasethu/features/rewards/presentation/rewards_hub_screen.dart';
import 'package:udyogasethu/features/rewards/presentation/rewards_store_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class FakeRewardsRepository implements RewardsRepository {
  UserGamificationProfile mockProfile = const UserGamificationProfile(
    userId: 'user-test-123',
    totalXp: 750,
    spentPoints: 100,
    availablePoints: 650,
    currentLevel: UserLevel(
      levelNumber: 3,
      name: 'Trusted Pro',
      minXp: 600,
      perks: {
        'commission_bps': 300,
        'search_boost': 1.30,
        'priority_support': true,
        'premium_jobs': true,
      },
    ),
    nextLevel: UserLevel(
      levelNumber: 4,
      name: 'Community Hero',
      minXp: 1500,
    ),
    progressPercent: 16.7,
    badges: [
      BadgeItem(
        id: 'b-1',
        slug: 'always_on_time',
        names: {
          'en': 'Always On-Time',
          'kn': 'ಸದಾ ಸಮಯಪಾಲಕ',
          'hi': 'हमेशा समय पर',
          'te': 'ఎల్లప్పుడూ సమయానికి',
          'ta': 'எப்போதும் சரியான நேரத்தில்',
        },
        criteria: {'description': '5+ consecutive on-time job arrivals'},
        isEarned: true,
      ),
      BadgeItem(
        id: 'b-2',
        slug: 'clean_record',
        names: {
          'en': 'Clean Record',
          'kn': 'ಸ್ವಚ್ಛ ದಾಖಲೆ',
          'hi': 'स्वच्छ रिकॉर्ड',
          'te': 'క్లీన్ రికార్డ్',
          'ta': 'சுத்தமான பதிவு',
        },
        criteria: {'description': '10+ completed jobs with zero disputes'},
        isEarned: false,
      ),
    ],
    streaks: [
      StreakItem(
        id: 'strk-1',
        kind: 'on_time_jobs',
        current: 7,
        best: 12,
        isAtRisk: false,
      ),
      StreakItem(
        id: 'strk-2',
        kind: 'daily_activity',
        current: 3,
        best: 15,
        isAtRisk: true,
      ),
    ],
    referralCode: 'SETU9942',
    successfulReferrals: 2,
  );

  List<RewardStoreItem> mockItems = [
    const RewardStoreItem(
      id: 'item-1',
      names: {
        'en': 'UdyogaSethu Official T-Shirt',
        'kn': 'ಉದ್ಯೋಗಸೇತು ಅಧಿಕೃತ ಟೀ-ಶರ್ಟ್',
      },
      pointsCost: 300,
      minLevel: 2,
      stock: 45,
    ),
    const RewardStoreItem(
      id: 'item-2',
      names: {
        'en': 'Heavy-Duty Field Tool Bag',
      },
      pointsCost: 500,
      minLevel: 3,
      stock: 0, // out of stock
    ),
  ];

  List<RewardRedemption> mockRedemptions = [
    RewardRedemption(
      id: 'red-1',
      userId: 'user-test-123',
      itemId: 'item-1',
      pointsSpent: 300,
      status: 'approved',
      shippingAddress: const {'street': '12th Main Indiranagar', 'pincode': '560038'},
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<UserGamificationProfile> getGamificationProfile([String? userId]) async {
    return mockProfile;
  }

  @override
  Future<List<RewardStoreItem>> getRewardItems() async {
    return mockItems;
  }

  @override
  Future<List<RewardRedemption>> getRedemptions() async {
    return mockRedemptions;
  }

  @override
  Future<Map<String, dynamic>> redeemRewardItem({
    required String itemId,
    required Map<String, dynamic> shippingAddress,
  }) async {
    final item = mockItems.firstWhere((i) => i.id == itemId);
    if (item.stock <= 0) {
      throw Exception('Item is out of stock');
    }
    if (mockProfile.availablePoints < item.pointsCost) {
      throw Exception('Insufficient points');
    }
    return {'success': true, 'points_spent': item.pointsCost};
  }

  @override
  Future<String> getOrGenerateReferralCode() async {
    return mockProfile.referralCode ?? 'SETU1234';
  }

  @override
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    if (code.toUpperCase() == mockProfile.referralCode) {
      throw Exception('Cannot use your own referral code');
    }
    return {'success': true, 'code': code};
  }

  @override
  Stream<UserGamificationProfile> watchGamificationProfile() {
    return Stream.value(mockProfile);
  }
}

void main() {
  group('Gamification Domain & Models Unit Tests', () {
    test('UserLevel perks and commission calculation', () {
      const level1 = UserLevel(
        levelNumber: 1,
        name: 'Starter',
        minXp: 0,
        perks: {
          'commission_bps': 500,
          'search_boost': 1.0,
          'priority_support': false,
          'premium_jobs': false,
        },
      );

      const level4 = UserLevel(
        levelNumber: 4,
        name: 'Community Hero',
        minXp: 1500,
        perks: {
          'commission_bps': 200,
          'search_boost': 1.50,
          'priority_support': true,
          'premium_jobs': true,
        },
      );

      expect(level1.commissionBps, 500);
      expect(level1.commissionPercent, 5.0);
      expect(level1.searchBoost, 1.0);
      expect(level1.hasPrioritySupport, false);
      expect(level1.hasPremiumJobs, false);

      expect(level4.commissionBps, 200);
      expect(level4.commissionPercent, 2.0); // 300 bps discount
      expect(level4.searchBoost, 1.50);
      expect(level4.hasPrioritySupport, true);
      expect(level4.hasPremiumJobs, true);
    });

    test('BadgeItem multilingual localization and locked criteria', () {
      const badge = BadgeItem(
        id: 'b-always',
        slug: 'always_on_time',
        names: {
          'en': 'Always On-Time',
          'kn': 'ಸದಾ ಸಮಯಪಾಲಕ',
          'hi': 'हमेशा समय पर',
          'te': 'ఎల్లప్పుಡూ సమయానికి',
          'ta': 'எப்போதும் சரியான நேரத்தில்',
        },
        criteria: {'description': '5+ consecutive on-time job arrivals'},
        isEarned: false,
      );

      expect(badge.getName('en'), 'Always On-Time');
      expect(badge.getName('kn'), 'ಸದಾ ಸಮಯಪಾಲಕ');
      expect(badge.getName('hi'), 'हमेशा समय पर');
      expect(badge.getName('te'), 'ఎల్లప్పుಡూ సమయానికి');
      expect(badge.getName('ta'), 'எப்போதும் சரியான நேரத்தில்');
      expect(badge.criteriaDescription, '5+ consecutive on-time job arrivals');
      expect(badge.isEarned, false);
    });

    test('StreakItem at risk state and values', () {
      const streakSafe = StreakItem(kind: 'on_time_jobs', current: 5, best: 8, isAtRisk: false);
      const streakRisk = StreakItem(kind: 'daily_activity', current: 2, best: 10, isAtRisk: true);

      expect(streakSafe.isAtRisk, false);
      expect(streakSafe.current, 5);
      expect(streakRisk.isAtRisk, true);
      expect(streakRisk.best, 10);
    });

    test('RewardStoreItem state resolution (available, locked, outOfStock)', () {
      const itemStandard = RewardStoreItem(
        id: 'r-1',
        names: {'en': 'Cap'},
        pointsCost: 150,
        minLevel: 1,
        stock: 10,
      );

      const itemHighLevel = RewardStoreItem(
        id: 'r-2',
        names: {'en': 'Bag'},
        pointsCost: 500,
        minLevel: 3,
        stock: 10,
      );

      const itemBadgeRequired = RewardStoreItem(
        id: 'r-3',
        names: {'en': 'Vest'},
        pointsCost: 400,
        minLevel: 2,
        requiredBadgeId: 'badge-safety',
        stock: 5,
      );

      const itemOutOfStock = RewardStoreItem(
        id: 'r-4',
        names: {'en': 'Sold Out Item'},
        pointsCost: 100,
        minLevel: 1,
        stock: 0,
      );

      // Available
      expect(
        itemStandard.getState(userPoints: 200, userLevel: 1, hasRequiredBadge: true),
        RewardItemState.available,
      );

      // Locked due to level
      expect(
        itemHighLevel.getState(userPoints: 600, userLevel: 2, hasRequiredBadge: true),
        RewardItemState.locked,
      );

      // Locked due to missing badge
      expect(
        itemBadgeRequired.getState(userPoints: 500, userLevel: 2, hasRequiredBadge: false),
        RewardItemState.locked,
      );

      // Out of stock overrides other conditions
      expect(
        itemOutOfStock.getState(userPoints: 1000, userLevel: 4, hasRequiredBadge: true),
        RewardItemState.outOfStock,
      );
    });

    test('Referral validation: self-referral and duplicate checks', () async {
      final fakeRepo = FakeRewardsRepository();

      // Self-referral must throw exception
      expect(
        () => fakeRepo.applyReferralCode('SETU9942'),
        throwsA(predicate((e) => e.toString().contains('Cannot use your own referral code'))),
      );

      // Valid other code succeeds
      final res = await fakeRepo.applyReferralCode('SETU8811');
      expect(res['success'], true);
    });

    test('Redemption exact points deduction and out of stock guards', () async {
      final fakeRepo = FakeRewardsRepository();

      // Successful redemption with sufficient points
      final res = await fakeRepo.redeemRewardItem(
        itemId: 'item-1',
        shippingAddress: {'street': 'Main road'},
      );
      expect(res['success'], true);
      expect(res['points_spent'], 300);

      // Out of stock item throws exception
      expect(
        () => fakeRepo.redeemRewardItem(
          itemId: 'item-2',
          shippingAddress: {'street': 'Main road'},
        ),
        throwsA(predicate((e) => e.toString().contains('out of stock'))),
      );
    });
  });

  group('Rewards Screens Widget & Overflow Tests', () {
    testWidgets('RewardsHubScreen renders cleanly with level, streaks, badges and referral', (tester) async {
      tester.view.physicalSize = const Size(360, 800) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeRewardsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rewardsRepositoryProvider.overrideWithValue(fakeRepo),
            gamificationProfileProvider.overrideWith((ref) => Stream.value(fakeRepo.mockProfile)),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: RewardsHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check level card
      expect(find.text('Level 3: Trusted Pro'), findsOneWidget);
      expect(find.text('750 Total XP'), findsOneWidget);

      // Check streaks
      expect(find.text('Active Streaks'), findsOneWidget);
      expect(find.text('7 On-Time Jobs'), findsOneWidget);
      expect(find.text('Streak at risk! Complete an action today.'), findsOneWidget);

      // Check badges
      expect(find.text('Achievement Badges'), findsOneWidget);
      expect(find.text('Always On-Time'), findsOneWidget);
      expect(find.text('Clean Record'), findsOneWidget);

      // Check referral card
      expect(find.text('Invite & Earn'), findsOneWidget);
      expect(find.text('SETU9942'), findsOneWidget);
    });

    testWidgets('RewardsStoreScreen renders catalog and tabs without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeRewardsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rewardsRepositoryProvider.overrideWithValue(fakeRepo),
            gamificationProfileProvider.overrideWith((ref) => Stream.value(fakeRepo.mockProfile)),
            rewardItemsProvider.overrideWith((ref) => Future.value(fakeRepo.mockItems)),
            rewardRedemptionsProvider.overrideWith((ref) => Future.value(fakeRepo.mockRedemptions)),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: RewardsStoreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Catalog'), findsOneWidget);
      expect(find.text('Your Redemptions'), findsOneWidget);
      expect(find.text('UdyogaSethu Official T-Shirt'), findsOneWidget);
      expect(find.text('Heavy-Duty Field Tool Bag'), findsOneWidget);
      expect(find.text('Out of Stock'), findsOneWidget);
    });
  });
}
