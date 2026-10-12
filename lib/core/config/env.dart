import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Environment configuration class reading values from `--dart-define` or `--dart-define-from-file`.
class Env {
  Env._();

  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl {
    if (_envUrl.trim().isNotEmpty) return _envUrl;
    return 'https://mmzbpeqkfomnywuzoqii.supabase.co';
  }

  static String get supabaseAnonKey {
    if (_envAnonKey.trim().isNotEmpty) return _envAnonKey;
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1temJwZXFrZm9tbnl3dXpvcWlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA4NDUyNTMsImV4cCI6MjEwNjQyMTI1M30.rT_c9tN4QNukP_fewnMC7kzkI6KPXO4UxNAIqXvEHoc';
  }

  static const String _envGoogleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static String get googleWebClientId {
    if (_envGoogleWebClientId.trim().isNotEmpty) return _envGoogleWebClientId;
    return '147218087454-84onmnof89drjjktvenajia8qp3p0g3l.apps.googleusercontent.com';
  }

  /// Razorpay Key ID for client initialization
  static const String _envRazorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');

  static String get razorpayKeyId {
    if (_envRazorpayKeyId.trim().isNotEmpty) return _envRazorpayKeyId;
    return 'rzp_test_5123456789ABCD';
  }

  /// True when using Razorpay test sandbox keys
  static bool get isRazorpayTestMode => razorpayKeyId.startsWith('rzp_test_');

  /// Feature Flag: ONE ACCOUNT = ONE ROLE policy (D4).
  /// Set to false by default. Set to true to re-enable multi-role switching.
  static const bool allowMultiRole = false;

  /// Feature Flag: D-QR Profile permanent QR code visibility.
  /// Set to false by default. In debug builds, can be toggled via Dev Menu.
  static const bool profileQrEnabled = false;

  /// Demo Build Flag: Available in debug/profile builds, or when explicitly enabled
  /// via `--dart-define=DEMO_BUILD=true`. Strictly false in production release builds.
  static const bool _envDemoBuild = bool.fromEnvironment('DEMO_BUILD', defaultValue: false);
  static bool get isDemoBuild => (!kReleaseMode) || _envDemoBuild;

  /// Returns true if valid Supabase configuration is available.
  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}

/// Global demo build flag constant
bool get kIsDemoBuild => Env.isDemoBuild;

/// Global feature flag constant matching Env.allowMultiRole
const bool kAllowMultiRole = Env.allowMultiRole;

/// Global feature flag constant for D-QR profile QR code (default false)
const bool kProfileQrEnabled = Env.profileQrEnabled;

/// Global Razorpay Test Mode flag
bool get kRazorpayTestMode => Env.isRazorpayTestMode;

/// A human-readable error screen shown when required environment variables are missing.
class MissingEnvScreen extends StatelessWidget {
  const MissingEnvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Environment Configuration Missing',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'UdyogaSethu requires valid SUPABASE_URL and SUPABASE_ANON_KEY variables to start.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF334155),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To fix this issue:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Copy env.example.json to env.json\n'
                        '2. Fill in your Supabase credentials\n'
                        '3. Run using command:\n'
                        '   flutter run --dart-define-from-file=env.json',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
