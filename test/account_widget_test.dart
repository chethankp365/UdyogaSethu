import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/account/presentation/delete_account_dialog.dart';
import 'package:udyogasethu/features/account/presentation/export_data_dialog.dart';
import 'package:udyogasethu/features/account/presentation/role_switcher_bottom_sheet.dart';
import 'package:udyogasethu/features/account/presentation/settings_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';
import 'account_test.dart';

Widget createTestApp(Widget child, {List overrides = const []}) {
  return ProviderScope(
    overrides: List.from(overrides),
    child: MaterialApp(
      locale: const Locale('en'),
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
  testWidgets('SettingsScreen renders accessibility controls and role options', (tester) async {
    final fakeRepo = FakeAccountRepository();

    await tester.pumpWidget(
      createTestApp(
        const SettingsScreen(),
        overrides: [
          accountRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Account & Settings'), findsOneWidget);
    expect(find.text('Language & Accessibility'), findsOneWidget);
    expect(find.text('Simple Mode'), findsOneWidget);
    expect(find.text('Text Scale Size'), findsOneWidget);
    expect(find.text('Voice Hints & TTS'), findsOneWidget);
    expect(find.text('Low-Data Mode'), findsOneWidget);
    expect(find.text('Role Switcher & Add Role'), findsOneWidget);
    expect(find.text('Export My Data'), findsOneWidget);
    expect(find.text('Delete My Account'), findsOneWidget);
  });

  testWidgets('RoleSwitcherBottomSheet displays assigned roles and Add a Role options', (tester) async {
    final fakeRepo = FakeAccountRepository();
    fakeRepo.assignedRoles = [UserRole.seeker];

    await tester.pumpWidget(
      createTestApp(
        const RoleSwitcherBottomSheet(),
        overrides: [
          accountRepositoryProvider.overrideWithValue(fakeRepo),
          appSessionProvider.overrideWith(AppSessionNotifier.new),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Switch Role Shell'), findsOneWidget);
    expect(find.text('Job Seeker'), findsOneWidget);
    expect(find.text('Add a Role to your Account'), findsOneWidget);
    expect(find.text('Add Job Provider'), findsOneWidget);
    expect(find.text('Add Farmer'), findsOneWidget);
  });

  testWidgets('ExportDataDialog fetches and displays user JSON data', (tester) async {
    final fakeRepo = FakeAccountRepository();

    await tester.pumpWidget(
      createTestApp(
        const ExportDataDialog(),
        overrides: [
          accountRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Export My Data'), findsOneWidget);
    expect(find.textContaining('export_timestamp'), findsOneWidget);
    expect(find.text('Copy JSON'), findsOneWidget);
  });

  testWidgets('DeleteAccountDialog renders warning notice and double confirmation step', (tester) async {
    final fakeRepo = FakeAccountRepository();

    await tester.pumpWidget(
      createTestApp(
        const DeleteAccountDialog(),
        overrides: [
          accountRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Delete My Account'), findsOneWidget);
    expect(find.text('Are you sure you want to delete your account?'), findsOneWidget);
    expect(find.textContaining('Legal Retention Notice'), findsOneWidget);

    final proceedBtn = find.text('Proceed to Confirm');
    expect(proceedBtn, findsOneWidget);
    await tester.tap(proceedBtn);
    await tester.pumpAndSettle();

    expect(find.text('Final Confirmation (Step 2 of 2)'), findsOneWidget);
    expect(find.text('Permanently Delete'), findsOneWidget);
  });
}
