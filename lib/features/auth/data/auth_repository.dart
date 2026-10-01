import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';



abstract class AuthRepository {
  Future<void> sendSmsOtp(String rawPhone);
  Future<AuthResponse> verifySmsOtp(String rawPhone, String otpToken);
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;

  SupabaseAuthRepository(this._supabase);

  @override
  Future<void> sendSmsOtp(String rawPhone) async {
    final cleanPhone = rawPhone.trim();
    if (cleanPhone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
      throw const AppException.validation(
        'Please enter a valid 10-digit mobile number starting with 6-9',
      );
    }

    final formattedPhone = '+91$cleanPhone';

    try {
      AppLogger.i('Sending SMS OTP request'); // Never log actual phone number
      await _supabase.auth.signInWithOtp(
        phone: formattedPhone,
      );
    } on AuthException catch (e) {
      AppLogger.e('Supabase AuthException during signInWithOtp: status=${e.statusCode}, code=${e.code}, msg=${e.message}');
      if (e.statusCode == '429' || e.code == 'over_email_send_rate_limit' || e.message.toLowerCase().contains('rate')) {
        throw const AppException.rateLimit(
          'Too many OTP requests. Please wait a moment before trying again.',
        );
      }
      final detail = kDebugMode ? ' (${e.message})' : '';
      throw AppException.auth(
        'Failed to send SMS code. Please verify your phone number and try again$detail',
        code: e.code,
      );
    } on SocketException catch (e) {
      AppLogger.w('SocketException during signInWithOtp: $e');
      throw const AppException.network(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      AppLogger.e('Unexpected error during signInWithOtp: $e');
      if (e is AppException) rethrow;
      throw AppException.unknown('An unexpected error occurred while sending SMS code: $e');
    }
  }

  @override
  Future<AuthResponse> verifySmsOtp(String rawPhone, String otpToken) async {
    final cleanPhone = rawPhone.trim();
    final formattedPhone = '+91$cleanPhone';

    try {
      AppLogger.i('Verifying SMS OTP token'); // Never log OTP token or phone number
      final response = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: otpToken.trim(),
        type: OtpType.sms,
      );

      if (response.session != null) {
        // Record Terms & Privacy Policy consent for signed in user
        _recordConsent();
      }

      return response;
    } on AuthException catch (e) {
      AppLogger.e('Supabase AuthException during verifyOTP: status=${e.statusCode}, msg=${e.message}');
      if (e.message.toLowerCase().contains('expired') || e.message.toLowerCase().contains('invalid') || e.statusCode == '400') {
        throw const AppException.auth(
          'Invalid or expired verification code. Please check the 6-digit code and try again.',
        );
      }
      final detail = kDebugMode ? ' (${e.message})' : '';
      throw AppException.auth(
        'Verification failed. Please try again$detail',
        code: e.code,
      );
    } on SocketException catch (e) {
      AppLogger.w('SocketException during verifyOTP: $e');
      throw const AppException.network(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      AppLogger.e('Unexpected error during verifyOTP: $e');
      if (e is AppException) rethrow;
      throw AppException.unknown('An unexpected error occurred during OTP verification: $e');
    }
  }

  Future<void> _recordConsent() async {
    try {
      await _supabase.rpc('record_user_consent', params: {
        'p_granted': true,
        'p_version': '1.0',
      });
      AppLogger.i('Logged terms consent via RPC record_user_consent');
    } catch (err) {
      AppLogger.w('Could not record consent via RPC: $err');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client);
});
