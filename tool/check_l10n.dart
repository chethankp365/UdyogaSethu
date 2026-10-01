// ignore_for_file: avoid_print
// Dart Tool: tool/check_l10n.dart
// Validates that all ARB files contain every key present in the template app_en.arb file.
// Run via: dart run tool/check_l10n.dart

import 'dart:convert';
import 'dart:io';

void main() {
  final l10nDir = Directory('lib/l10n');
  if (!l10nDir.existsSync()) {
    print('ERROR: lib/l10n directory does not exist!');
    exit(1);
  }

  final templateFile = File('lib/l10n/app_en.arb');
  if (!templateFile.existsSync()) {
    print('ERROR: Template ARB file lib/l10n/app_en.arb not found!');
    exit(1);
  }

  final Map<String, dynamic> templateJson = json.decode(templateFile.readAsStringSync());
  final Set<String> templateKeys = templateJson.keys
      .where((key) => !key.startsWith('@'))
      .toSet();

  print('Loaded template app_en.arb with ${templateKeys.length} localization keys.\n');

  final arbFiles = l10nDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb') && !f.path.endsWith('app_en.arb'))
      .toList();

  bool hasError = false;
  int totalChecked = 0;

  for (final file in arbFiles) {
    totalChecked++;
    final filename = file.path.split(Platform.pathSeparator).last;
    final Map<String, dynamic> arbJson = json.decode(file.readAsStringSync());
    final Set<String> fileKeys = arbJson.keys
        .where((key) => !key.startsWith('@'))
        .toSet();

    final missingKeys = templateKeys.difference(fileKeys);
    if (missingKeys.isNotEmpty) {
      hasError = true;
      print('❌ $filename: MISSING ${missingKeys.length} keys:');
      for (final k in missingKeys) {
        print('   - $k');
      }
    } else {
      print('✅ $filename: ALL ${templateKeys.length} keys present.');
    }
  }

  print('\n----------------------------------------');
  if (hasError) {
    print('FAILED: Missing localization keys found across ARB files.');
    exit(1);
  } else {
    print('SUCCESS: All $totalChecked ARB files passed l10n completeness check!');
    exit(0);
  }
}
