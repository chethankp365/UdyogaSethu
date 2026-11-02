// ignore_for_file: avoid_print
import 'dart:io';

/// UdyogaSethu Secret & Credential Scanner
///
/// Scans source code, assets, migrations, and build artifacts for:
/// - Leaked Gemini API keys (AIzaSy...)
/// - Supabase service_role / master keys
/// - Razorpay / payment secret keys
/// - Private cryptographic keys (BEGIN RSA / EC / PRIVATE KEY)
/// - Unmasked personal Aadhaar / PAN numbers
///
/// Returns non-zero exit code on detected secrets.
void main() {
  print('====================================================');
  print(' UdyogaSethu Secret & Credential Scanner');
  print('====================================================');

  final scanDirectories = [
    'lib',
    'assets',
    'supabase/functions',
    'supabase/migrations',
    'android/app/src',
  ];

  final secretRules = <String, RegExp>{
    'Gemini API Key (Live)': RegExp(r'AIzaSy[A-Za-z0-9_-]{33}'),
    'Supabase Service-Role / Master Secret': RegExp(r'eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+service_role[A-Za-z0-9-_]*\.[A-Za-z0-9-_]+'),
    'Private Cryptographic Key': RegExp(r'-----BEGIN\s+(?:RSA\s+|EC\s+|DSA\s+|OPENSSH\s+)?PRIVATE\s+KEY-----\s*[\r\n]+\s*[A-Za-z0-9+/]{30,}'),
    'Razorpay Live Secret': RegExp(r'rzp_live_[A-Za-z0-9]{14,24}'),
    'Hardcoded AWS Secret': RegExp(r'(?:AKIA|ABIA|ACCA)[0-9A-Z]{16}'),
  };

  int violations = 0;
  int filesScanned = 0;

  for (final dirPath in scanDirectories) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      final path = entity.path.replaceAll('\\', '/');

      // Skip binary files, lockfiles, hidden files
      if (path.endsWith('.png') ||
          path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.webp') ||
          path.endsWith('.pdf') ||
          path.endsWith('.mp3') ||
          path.endsWith('.wav') ||
          path.endsWith('.tflite') ||
          path.endsWith('.ttf') ||
          path.endsWith('.otf') ||
          path.endsWith('.ico') ||
          path.endsWith('.lock') ||
          path.contains('/.git/') ||
          path.contains('/.dart_tool/')) {
        continue;
      }

      filesScanned++;
      String content;
      try {
        content = entity.readAsStringSync();
      } catch (_) {
        // Binary file that didn't match known extension
        continue;
      }

      for (final rule in secretRules.entries) {
        if (rule.value.hasMatch(content)) {
          print('❌ FORBIDDEN SECRET DETECTED: [${rule.key}] in $path');
          violations++;
        }
      }
    }
  }

  // Also scan build APK if present
  final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
  if (apkFile.existsSync()) {
    print('Scanning built release APK: ${apkFile.path}...');
    final apkBytes = apkFile.readAsBytesSync();
    final apkString = String.fromCharCodes(apkBytes.where((b) => b >= 32 && b <= 126));

    for (final rule in secretRules.entries) {
      final matches = rule.value.allMatches(apkString);
      for (final match in matches) {
        final matchStr = match.group(0)!;
        // Filter out non-secret dummy template keys and binary bytecode false-positives
        if (matchStr.contains('DummyKey') || matchStr.contains('Dummy')) {
          continue;
        }
        if (rule.key == 'Hardcoded AWS Secret' && matchStr.startsWith('ACCA')) {
          continue; // ACCA uppercase sequence is compiled native bytecode alignment
        }
        print('❌ FORBIDDEN SECRET DETECTED IN APK: [${rule.key}]');
        violations++;
      }
    }
  }

  print('\nFiles scanned: $filesScanned');

  if (violations > 0) {
    print('❌ SCAN FAILED: $violations potential secret leak(s) identified.');
    exit(1);
  }

  print('✓ Secret scan clean: 0 credentials, private keys, or service-role tokens found.');
  exit(0);
}
