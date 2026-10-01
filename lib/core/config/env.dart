import 'package:flutter/material.dart';

/// Environment configuration class reading values from `--dart-define` or `--dart-define-from-file`.
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Returns true if all required environment variables are set and non-empty.
  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}

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
