import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/features/auth/presentation/login_screen.dart';
import 'package:udyogasethu/features/auth/presentation/otp_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

Widget createTestWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
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

  group('LoginScreen & OtpScreen Widget Tests', () {
    testWidgets('LoginScreen renders header, title, phone input, terms checkbox and Google button',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Number Login'), findsOneWidget);
      expect(find.byKey(const Key('phoneInputField')), findsOneWidget);
      expect(find.byKey(const Key('termsCheckbox')), findsOneWidget);
      expect(find.byKey(const Key('getOtpButton')), findsOneWidget);
      expect(find.byKey(const Key('googleLoginButton')), findsOneWidget);
    });

    testWidgets('Entering valid 10-digit phone number enables Get OTP button',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Enter valid phone number
      await tester.enterText(find.byKey(const Key('phoneInputField')), '9123456789');
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('getOtpButton')),
          matching: find.byType(ElevatedButton),
        ),
      );

      expect(button.onPressed, isNotNull);
    });

    testWidgets('OtpScreen renders title, subtitle, 6-box field, resend countdown and change number link',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const OtpScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));


      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.byKey(const Key('otpPinputField')), findsOneWidget);
      expect(find.byKey(const Key('verifyOtpButton')), findsOneWidget);
      expect(find.byKey(const Key('resendOtpButton')), findsOneWidget);
      expect(find.byKey(const Key('changeNumberButton')), findsOneWidget);
    });
  });
}
