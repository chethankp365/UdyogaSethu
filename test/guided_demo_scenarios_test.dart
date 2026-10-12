import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:udyogasethu/features/demo/data/demo_repository.dart';
import 'package:udyogasethu/features/demo/domain/demo_scenario.dart';
import 'package:udyogasethu/features/demo/presentation/admin_trust_preview_screen.dart';
import 'package:udyogasethu/features/demo/presentation/demo_accounts_screen.dart';
import 'package:udyogasethu/features/demo/presentation/demo_launcher_sheet.dart';
import 'package:udyogasethu/features/demo/presentation/widgets/demo_coach_mark_overlay.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('P10.1 — Demo Scenarios Catalog & Model Tests', () {
    test('Contains exactly 5 canonical guided demo scenarios', () {
      final scenarios = DemoScenariosCatalog.scenarios;
      expect(scenarios.length, 5);

      final ids = scenarios.map((s) => s.id).toList();
      expect(ids, containsAll([
        'worker_day',
        'customer_booking',
        'farmer_sale',
        'community_bulk',
        'admin_trust',
      ]));
    });

    test('Each scenario contains pedagogical steps with non-empty "whyItMatters" explanations', () {
      for (final scenario in DemoScenariosCatalog.scenarios) {
        expect(scenario.steps, isNotEmpty);
        expect(scenario.title, isNotEmpty);
        expect(scenario.subtitle, isNotEmpty);
        expect(scenario.testUserPhone, startsWith('+919900000'));
        expect(scenario.testUserEmail, isNotEmpty);
        expect(scenario.estimatedMinutes, inInclusiveRange(1, 3));

        for (final step in scenario.steps) {
          expect(step.title, isNotEmpty);
          expect(step.whyItMatters, isNotEmpty);
          expect(step.targetRoute, isNotEmpty);
          expect(step.explanation, isNotEmpty);
        }
      }
    });

    test('DemoAccounts catalog contains representative seeded accounts across all roles', () {
      final accounts = DemoRepository.accounts;
      expect(accounts.length, greaterThanOrEqualTo(8));

      final roles = accounts.map((a) => a.role).toSet();
      expect(roles, containsAll(['seeker', 'provider', 'farmer', 'admin']));

      // Worker Ramesh Kumar
      final ramesh = accounts.firstWhere((a) => a.phone == '+919900000101');
      expect(ramesh.name, 'Ramesh Kumar');
      expect(ramesh.role, 'seeker');
      expect(ramesh.isVerified, true);

      // Farmer Gowda
      final gowda = accounts.firstWhere((a) => a.phone == '+919900000301');
      expect(gowda.name, 'Gowda Farmer');
      expect(gowda.role, 'farmer');
    });
  });

  group('P10.1 — Demo State & Progression Tests', () {
    test('DemoNotifier starts, advances, and completes scenario tracking', () async {
      final ref = ProviderContainer();

      final notifier = ref.read(demoNotifierProvider.notifier);
      var state = ref.read(demoNotifierProvider);
      expect(state.activeScenarioId, isNull);
      expect(state.currentStepIndex, 0);

      // 1. Start Worker Day Scenario
      notifier.startScenario('worker_day');
      state = ref.read(demoNotifierProvider);
      expect(state.activeScenarioId, 'worker_day');
      expect(state.currentStepIndex, 0);
      expect(state.currentStep?.title, 'Active Job Assignment');

      // 2. Advance to Step 2
      notifier.nextStep();
      state = ref.read(demoNotifierProvider);
      expect(state.currentStepIndex, 1);
      expect(state.currentStep?.title, 'Dynamic QR Ticket & Two-Step Verification');

      // 3. Advance to Step 3
      notifier.nextStep();
      state = ref.read(demoNotifierProvider);
      expect(state.currentStepIndex, 2);

      // 4. Advance to Step 4 (last step)
      notifier.nextStep();
      state = ref.read(demoNotifierProvider);
      expect(state.currentStepIndex, 3);

      // 5. Next step on last step completes scenario
      notifier.nextStep();
      state = ref.read(demoNotifierProvider);
      expect(state.activeScenarioId, isNull);
      expect(state.completedScenarioIds, contains('worker_day'));
    });

    test('DemoNotifier exitScenario cancels active scenario without completing it', () {
      final ref = ProviderContainer();
      final notifier = ref.read(demoNotifierProvider.notifier);

      notifier.startScenario('farmer_sale');
      var state = ref.read(demoNotifierProvider);
      expect(state.activeScenarioId, 'farmer_sale');

      notifier.exitScenario();
      state = ref.read(demoNotifierProvider);
      expect(state.activeScenarioId, isNull);
      expect(state.completedScenarioIds, isNot(contains('farmer_sale')));
    });
  });

  group('P10.1 — Evaluator Widget Presentation Tests', () {
    testWidgets('DemoAccountsScreen renders accounts and visible DEMO BUILD label',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DemoAccountsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Demo Accounts (Evaluator)'), findsOneWidget);
      expect(find.text('DEMO BUILD'), findsOneWidget);
      expect(find.textContaining('Evaluator Notice'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Dr. Anand Sharma'), findsOneWidget);
      expect(find.text('Gowda Farmer'), findsOneWidget);
      expect(find.text('System Admin'), findsOneWidget);
    });

    testWidgets('DemoLauncherSheet renders 5 scenarios and progress tracker',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: DemoLauncherSheet()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Guided Demo Scenarios'), findsOneWidget);
      expect(find.text('DEMO BUILD'), findsOneWidget);
      expect(find.text('Evaluation Progress'), findsOneWidget);
      expect(find.text('Demo Accounts'), findsOneWidget);
      expect(find.text('Reset Demo'), findsOneWidget);

      expect(find.text('Worker Day Journey'), findsOneWidget);
      expect(find.text('Customer Service Booking'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Farmer Tomato Direct Sale'), 150);
      expect(find.text('Farmer Tomato Direct Sale'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Community Bulk Order'), 150);
      expect(find.text('Community Bulk Order'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Admin Trust Review & Dispute State'), 150);
      expect(find.text('Admin Trust Review & Dispute State'), findsOneWidget);
    });

    testWidgets('AdminTrustPreviewScreen renders architectural boundary and seeded dispute',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdminTrustPreviewScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Admin Trust Review State'), findsOneWidget);
      expect(find.text('DEMO MODE'), findsOneWidget);
      expect(find.text('Separate Admin Console Notice'), findsOneWidget);
      expect(find.textContaining('Admin Console is built in a separate web/desktop project'), findsOneWidget);
      expect(find.text('CASE #DSP-2026-004'), findsOneWidget);
      expect(find.text('ESCROW FROZEN'), findsOneWidget);
      expect(find.text('ITI Electrical Wireman License'), findsOneWidget);
      expect(find.text('Pending Admin Review'), findsNWidgets(2));
    });

    testWidgets('DemoCoachMarkOverlay renders floating banner when scenario is active',
        (tester) async {
      final container = ProviderContainer();
      container.read(demoNotifierProvider.notifier).startScenario('worker_day');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DemoCoachMarkOverlay(
              child: Scaffold(
                body: Center(child: Text('Main Screen Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Main Screen Content'), findsOneWidget);
      expect(find.text('Worker Day Journey'), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Active Job Assignment'), findsOneWidget);
      expect(find.textContaining('Why this matters:'), findsOneWidget);
      expect(find.text('Open Screen'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);
    });
  });

  group('P10.1 & P10.2 — Zero Layout Overflow Safety Matrix (320dp to 600dp, Text Scales 1.0 to 1.6x)', () {
    Future<void> runMatrixCheck({
      required WidgetTester tester,
      required String componentName,
      required Widget Function(BuildContext) builder,
      List<dynamic> overrides = const [],
    }) async {
      final widths = [320.0, 360.0, 412.0, 600.0];
      final scales = [1.0, 1.3, 1.6];
      final locales = [
        const Locale('en'),
        const Locale('kn'),
        const Locale('hi'),
        const Locale('te'),
        const Locale('ta'),
        const Locale('mr'),
        const Locale('bn'),
        const Locale('or'),
      ];

      for (final width in widths) {
        for (final scale in scales) {
          for (final loc in locales) {
            tester.view.physicalSize = Size(width * 2.5, 800 * 2.5);
            tester.view.devicePixelRatio = 2.5;

            String? detectedOverflow;
            final prevOnError = FlutterError.onError;
            FlutterError.onError = (details) {
              final str = details.toString();
              if (str.contains('A RenderFlex overflowed') ||
                  str.contains('overflowed by')) {
                detectedOverflow = str;
              }
            };

            try {
              await tester.pumpWidget(
                ProviderScope(
                  overrides: overrides.cast(),
                  child: MaterialApp(
                    locale: loc,
                    localizationsDelegates: AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: Builder(
                      builder: (ctx) => MediaQuery(
                        data: MediaQuery.of(ctx).copyWith(
                          textScaler: TextScaler.linear(scale),
                        ),
                        child: builder(ctx),
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
              reason: '$componentName OVERFLOWED at width ${width.toInt()}dp, scale $scale, locale ${loc.languageCode}:\n$detectedOverflow',
            );
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    testWidgets('DemoAccountsScreen zero layout overflow matrix check', (tester) async {
      await runMatrixCheck(
        tester: tester,
        componentName: 'DemoAccountsScreen',
        builder: (ctx) => const DemoAccountsScreen(),
      );
    });

    testWidgets('DemoLauncherSheet zero layout overflow matrix check', (tester) async {
      await runMatrixCheck(
        tester: tester,
        componentName: 'DemoLauncherSheet',
        builder: (ctx) => const Scaffold(body: DemoLauncherSheet()),
      );
    });

    testWidgets('AdminTrustPreviewScreen zero layout overflow matrix check', (tester) async {
      await runMatrixCheck(
        tester: tester,
        componentName: 'AdminTrustPreviewScreen',
        builder: (ctx) => const AdminTrustPreviewScreen(),
      );
    });

    testWidgets('DemoCoachMarkOverlay zero layout overflow matrix check', (tester) async {
      final container = ProviderContainer();
      container.read(demoNotifierProvider.notifier).startScenario('worker_day');

      await runMatrixCheck(
        tester: tester,
        componentName: 'DemoCoachMarkOverlay',
        overrides: [
          demoNotifierProvider.overrideWith(() => DemoNotifier()..startScenario('worker_day')),
        ],
        builder: (ctx) => const DemoCoachMarkOverlay(
          child: Scaffold(body: Center(child: Text('Underlying screen'))),
        ),
      );
    });
  });
}
