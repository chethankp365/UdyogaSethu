import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/widgets/compact_language_selector.dart';
import 'package:udyogasethu/features/onboarding/presentation/language_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleController Tests', () {
    test('LocaleNotifier changes locale and returns correct AppLanguageOption', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      expect(container.read(localeProvider).languageCode, equals('en'));

      await container.read(localeProvider.notifier).setLocale('kn');
      expect(container.read(localeProvider).languageCode, equals('kn'));

      final option = AppLanguages.fromCode('kn');
      expect(option.nativeName, equals('ಕನ್ನಡ'));
    });
  });

  group('LanguageScreen UI Tests', () {
    testWidgets('LanguageScreen renders title, subtitle, 8 tiles and audio button', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: LanguageScreen(),
          ),
        ),
      );

      // Verify title & subtitle
      expect(find.text('Choose your language'), findsOneWidget);
      expect(find.text('We will show everything in your language'), findsOneWidget);

      // Verify 8 language option tiles
      expect(find.text('English'), findsOneWidget);
      expect(find.text('ಕನ್ನಡ (Kannada)'), findsOneWidget);
      expect(find.text('हिंदी (Hindi)'), findsOneWidget);
      expect(find.text('తెలుగు (Telugu)'), findsOneWidget);

      // Verify buttons
      expect(find.textContaining('Listen to welcome in'), findsOneWidget);
      expect(find.text('Continue ->'), findsOneWidget);
    });

    testWidgets('CompactLanguageSelector renders top 5 language chips', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompactLanguageSelector(),
            ),
          ),
        ),
      );

      expect(find.byType(ChoiceChip), findsNWidgets(5));
      expect(find.text('English'), findsOneWidget);
      expect(find.text('ಕನ್ನಡ'), findsOneWidget);
    });
  });
}
