import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/features/auth/data/auth_repository.dart';
import 'package:udyogasethu/features/auth/data/phone_auth_notifier.dart';
import 'package:udyogasethu/features/auth/domain/phone_auth_state.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> sendSmsOtp(String rawPhone) async {
    if (rawPhone == '9999999999') {
      throw const AppException.rateLimit(
        'Too many OTP requests. Please wait a moment before trying again.',
      );
    } else if (rawPhone == '8888888888') {
      throw const AppException.network(
        'No internet connection. Please check your network.',
      );
    } else if (rawPhone == '0000000000') {
      throw const AppException.validation(
        'Please enter a valid 10-digit mobile number starting with 6-9',
      );
    }
  }

  @override
  Future<AuthResponse> verifySmsOtp(String rawPhone, String otpToken) async {
    if (otpToken == '000000' || otpToken == '999999') {
      throw const AppException.auth(
        'Invalid or expired verification code. Please check the 6-digit code and try again.',
      );
    }
    return AuthResponse(
      session: Session(
        accessToken: 'mock_access_token',
        tokenType: 'bearer',
        user: const User(
          id: 'mock_user_id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-02T00:00:00Z',
        ),
      ),
    );
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhoneAuthState Domain Validation Tests', () {
    test('Phone number validator enforces 10 digits starting 6-9', () {
      expect(const PhoneAuthState(phone: '9876543210').isPhoneValid, true);
      expect(const PhoneAuthState(phone: '6123456789').isPhoneValid, true);
      expect(const PhoneAuthState(phone: '5123456789').isPhoneValid, false);
      expect(const PhoneAuthState(phone: '987654321').isPhoneValid, false);
      expect(const PhoneAuthState(phone: '98765432100').isPhoneValid, false);
      expect(const PhoneAuthState(phone: 'abc9876543').isPhoneValid, false);
    });

    test('canRequestOtp checks phone validity and terms acceptance', () {
      expect(
        const PhoneAuthState(phone: '9876543210', termsAccepted: true).canRequestOtp,
        true,
      );
      expect(
        const PhoneAuthState(phone: '9876543210', termsAccepted: false).canRequestOtp,
        false,
      );
    });
  });

  group('PhoneAuthNotifier Unit Tests with Mock Repository', () {
    late ProviderContainer container;
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Successful sendOtp updates step to otpSent', () async {
      final notifier = container.read(phoneAuthProvider.notifier);
      notifier.updatePhone('9876543210');

      final result = await notifier.sendOtp();
      expect(result, true);

      final state = container.read(phoneAuthProvider);
      expect(state.step, PhoneAuthStep.otpSent);
      expect(state.errorMessage, null);
    });

    test('Rate limited sendOtp sets error message and rate limit status', () async {
      final notifier = container.read(phoneAuthProvider.notifier);
      notifier.updatePhone('9999999999');

      final result = await notifier.sendOtp();
      expect(result, false);

      final state = container.read(phoneAuthProvider);
      expect(state.isRateLimited, true);
      expect(state.errorMessage, contains('Too many OTP requests'));
    });

    test('Wrong OTP error path sets friendly error message', () async {
      final notifier = container.read(phoneAuthProvider.notifier);
      notifier.updatePhone('9876543210');
      await notifier.sendOtp();

      final result = await notifier.verifyOtp('000000');
      expect(result, false);

      final state = container.read(phoneAuthProvider);
      expect(state.step, PhoneAuthStep.otpSent);
      expect(state.errorMessage, contains('Invalid or expired verification code'));
    });

    test('Expired OTP error path sets friendly error message', () async {
      final notifier = container.read(phoneAuthProvider.notifier);
      notifier.updatePhone('9876543210');
      await notifier.sendOtp();

      final result = await notifier.verifyOtp('999999');
      expect(result, false);

      final state = container.read(phoneAuthProvider);
      expect(state.errorMessage, contains('Invalid or expired verification code'));
    });

    test('Successful OTP verification transitions to success step', () async {
      final notifier = container.read(phoneAuthProvider.notifier);
      notifier.updatePhone('9876543210');
      await notifier.sendOtp();

      final result = await notifier.verifyOtp('123456');
      expect(result, true);

      final state = container.read(phoneAuthProvider);
      expect(state.step, PhoneAuthStep.success);
    });

    test('Resend OTP enforces max 3 resends limit', () async {
      final notifier = container.read(phoneAuthProvider.notifier);
      notifier.updatePhone('9876543210');
      await notifier.sendOtp();

      // Perform 3 resends
      await notifier.resendOtp();
      await notifier.resendOtp();
      await notifier.resendOtp();

      final state = container.read(phoneAuthProvider);
      expect(state.resendsCount, 3);

      // Attempt 4th resend
      final resend4 = await notifier.resendOtp();
      expect(resend4, false);
      expect(container.read(phoneAuthProvider).errorMessage, contains('Maximum 3 resends'));
    });
  });
}
