import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';

abstract class AuthRepository {
  Future<void> sendSmsOtp(String rawPhone);
  Future<AuthResponse> verifySmsOtp(String rawPhone, String otpToken);
  Future<AuthResponse?> signInWithGoogle();
  Future<void> sendPhoneChangeOtp(String rawPhone);
  Future<AuthResponse> verifyPhoneChangeOtp(String rawPhone, String otpToken);
  Future<void> linkGoogleAccount();
  Future<void> copyGoogleProfileDetails();
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  SupabaseAuthRepository(this._supabase, {GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: Env.googleWebClientId,
            );

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
      AppLogger.i('Sending SMS OTP request');
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
      AppLogger.i('Verifying SMS OTP token');
      final response = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: otpToken.trim(),
        type: OtpType.sms,
      );

      if (response.session != null) {
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

  @override
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      AppLogger.i('Initiating Google sign-in with serverClientId');
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (_) {
        // Ignore disconnect/signOut errors if user was not previously signed in
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.i('Google sign-in cancelled by user');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AppException.auth('Could not retrieve ID token from Google authentication.');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session != null) {
        _recordConsent();
        await copyGoogleProfileDetails();
      }

      return response;
    } on AuthException catch (e) {
      AppLogger.e('AuthException during Google signInWithIdToken: code=${e.code}, msg=${e.message}');
      if (e.code == 'email_exists' ||
          e.code == 'identity_already_exists' ||
          e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already linked') ||
          e.message.toLowerCase().contains('already exists')) {
        throw const AppException.auth('This email is already linked to another number.');
      }
      throw AppException.auth('Google sign-in failed. ${e.message}', code: e.code);
    } on PlatformException catch (e) {
      AppLogger.w('PlatformException during Google sign-in: code=${e.code}, msg=${e.message}');
      if (e.code == 'network_error') {
        throw const AppException.network('No internet connection. Please check your network.');
      }
      if (e.code == 'sign_in_failed' || e.code == 'API_NOT_CONNECTED') {
        throw const AppException.auth('Google Play Services is unavailable or outdated on this device.');
      }
      throw AppException.auth('Google sign-in error: ${e.message ?? e.code}');
    } on SocketException catch (e) {
      AppLogger.w('SocketException during Google sign-in: $e');
      throw const AppException.network('No internet connection. Please check your network.');
    } catch (e) {
      AppLogger.e('Unexpected error during Google sign-in: $e');
      if (e is AppException) rethrow;
      throw AppException.unknown('An unexpected error occurred during Google sign-in: $e');
    }
  }

  @override
  Future<void> sendPhoneChangeOtp(String rawPhone) async {
    final cleanPhone = rawPhone.trim().replaceAll(RegExp(r'^\+91'), '');
    if (cleanPhone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
      throw const AppException.validation(
        'Please enter a valid 10-digit mobile number starting with 6-9',
      );
    }

    final formattedPhone = '+91$cleanPhone';

    try {
      AppLogger.i('Sending mobile number update OTP');
      await _supabase.auth.updateUser(
        UserAttributes(phone: formattedPhone),
      );
    } on AuthException catch (e) {
      AppLogger.e('AuthException during updateUser phone: status=${e.statusCode}, code=${e.code}');
      final debugDetail = kDebugMode
          ? ' (${e.code != null ? 'Code: ${e.code}, ' : ''}${e.message})'
          : '';
      if (e.code == 'phone_exists' ||
          e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        throw AppException.auth('This mobile number is already linked to another account.$debugDetail');
      }
      throw AppException.auth('Failed to send verification code: ${e.message}$debugDetail', code: e.code);
    } on SocketException catch (e) {
      AppLogger.w('SocketException during updateUser phone: $e');
      throw const AppException.network('No internet connection. Please check your network.');
    } catch (e) {
      AppLogger.e('Unexpected error during updateUser phone: $e');
      if (e is AppException) rethrow;
      throw AppException.unknown('An unexpected error occurred: $e');
    }
  }

  @override
  Future<AuthResponse> verifyPhoneChangeOtp(String rawPhone, String otpToken) async {
    final cleanPhone = rawPhone.trim().replaceAll(RegExp(r'^\+91'), '');
    final formattedPhone = '+91$cleanPhone';

    try {
      AppLogger.i('Verifying phone change OTP');
      final response = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: otpToken.trim(),
        type: OtpType.phoneChange,
      );

      if (response.session != null) {
        _recordConsent();
      }

      return response;
    } on AuthException catch (e) {
      AppLogger.e('AuthException during verifyPhoneChangeOtp: status=${e.statusCode}, code=${e.code}');
      final debugDetail = kDebugMode
          ? ' (${e.code != null ? 'Code: ${e.code}, ' : ''}${e.message})'
          : '';
      throw AppException.auth('Invalid or expired verification code.$debugDetail', code: e.code);
    } on SocketException catch (e) {
      AppLogger.w('SocketException during verifyPhoneChangeOtp: $e');
      throw const AppException.network('No internet connection. Please check your network.');
    } catch (e) {
      AppLogger.e('Unexpected error during verifyPhoneChangeOtp: $e');
      if (e is AppException) rethrow;
      throw AppException.unknown('An error occurred during verification: $e');
    }
  }

  @override
  Future<void> linkGoogleAccount() async {
    try {
      AppLogger.i('Initiating Google account linking');
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.i('Google link cancelled by user');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AppException.auth('Could not retrieve ID token from Google.');
      }

      await _supabase.auth.linkIdentity(
        OAuthProvider.google,
      );

      await copyGoogleProfileDetails();
    } on AuthException catch (e) {
      AppLogger.e('AuthException during linkIdentity: code=${e.code}, msg=${e.message}');
      if (e.code == 'identity_already_exists' ||
          e.message.toLowerCase().contains('already linked') ||
          e.message.toLowerCase().contains('already exists')) {
        throw const AppException.auth('This email is already linked to another number.');
      }
      throw AppException.auth('Failed to link Google account: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.e('Unexpected error during linkIdentity: $e');
      if (e is AppException) rethrow;
      throw AppException.unknown('An error occurred while linking Google account: $e');
    }
  }

  @override
  Future<void> copyGoogleProfileDetails() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final meta = user.userMetadata ?? {};
    final googleName = (meta['full_name'] ?? meta['name']) as String?;
    final googlePhoto = (meta['avatar_url'] ?? meta['picture']) as String?;

    if (googleName == null && googlePhoto == null) return;

    try {
      final existingProfile = await _supabase
          .from('profiles')
          .select('full_name, avatar_path')
          .eq('id', user.id)
          .maybeSingle();

      final updates = <String, dynamic>{};
      final existingName = existingProfile?['full_name'] as String?;
      final existingPhoto = existingProfile?['avatar_path'] as String?;

      if (googleName != null && (existingName == null || existingName.trim().isEmpty)) {
        updates['full_name'] = googleName;
      }
      if (googlePhoto != null && (existingPhoto == null || existingPhoto.trim().isEmpty)) {
        updates['avatar_path'] = googlePhoto;
      }

      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', user.id);
        AppLogger.i('Copied Google profile details to profiles table');
      }
    } catch (err) {
      AppLogger.w('Could not copy Google profile details: $err');
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
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (e) {
      AppLogger.w('Google sign-out/disconnect error (handled): $e');
    }
    await _supabase.auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client);
});

