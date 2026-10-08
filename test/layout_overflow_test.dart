import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/provider/domain/provider_profile_draft.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_controller.dart';
import 'package:udyogasethu/features/provider/presentation/provider_wizard_screen.dart';
import 'package:udyogasethu/features/seeker/domain/seeker_profile_draft.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_wizard_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

import 'provider_wizard_test.dart';
import 'seeker_wizard_test.dart';

void main() {
  const screenSizes = [
    Size(360, 640),
    Size(412, 840),
  ];

  const textScales = [1.0, 1.3, 1.6];
  const locales = [Locale('en'), Locale('kn'), Locale('hi'), Locale('ta'), Locale('te')];

  group('Layout Overflow Safety Tests', () {
    for (final size in screenSizes) {
      for (final textScale in textScales) {
        for (final loc in locales) {
          testWidgets(
            'ProviderWizardScreen no overflow on ${size.width}x${size.height} at scale $textScale (${loc.languageCode})',
            (tester) async {
              tester.view.physicalSize = size * 2.0;
              tester.view.devicePixelRatio = 2.0;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);

              final fakeRepo = FakeProviderProfileRepository();
              fakeRepo.draft = const ProviderProfileDraft(
                userId: 'p-test',
                fullName: 'Chethan Kumar Test Provider',
                currentStep: 1,
              );

              await tester.pumpWidget(
                ProviderScope(
                  overrides: [
                    providerProfileRepositoryProvider.overrideWithValue(fakeRepo),
                  ],
                  child: MaterialApp(
                    locale: loc,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: MediaQuery(
                      data: MediaQueryData(
                        size: size,
                        textScaler: TextScaler.linear(textScale),
                      ),
                      child: const ProviderWizardScreen(),
                    ),
                  ),
                ),
              );

              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            },
          );

          testWidgets(
            'SeekerWizardScreen no overflow on ${size.width}x${size.height} at scale $textScale (${loc.languageCode})',
            (tester) async {
              tester.view.physicalSize = size * 2.0;
              tester.view.devicePixelRatio = 2.0;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);

              final fakeRepo = FakeSeekerProfileRepository();
              fakeRepo.draft = const SeekerProfileDraft(
                userId: 's-test',
                fullName: 'Chethan Kumar Seeker',
                currentStep: 1,
              );

              await tester.pumpWidget(
                ProviderScope(
                  overrides: [
                    seekerProfileRepositoryProvider.overrideWithValue(fakeRepo),
                  ],
                  child: MaterialApp(
                    locale: loc,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: MediaQuery(
                      data: MediaQueryData(
                        size: size,
                        textScaler: TextScaler.linear(textScale),
                      ),
                      child: const SeekerWizardScreen(),
                    ),
                  ),
                ),
              );

              await tester.pump(const Duration(milliseconds: 500));
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}
