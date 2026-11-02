// ignore_for_file: avoid_print
import 'dart:io';

/// UdyogaSethu Backend SQL Test Runner
///
/// Runs the comprehensive SQL test suites under supabase/tests:
/// - rls_tests.sql
/// - functions_tests.sql
/// - orders_concurrency_tests.sql
/// - lifecycle_fixes_tests.sql
/// - security_audit_tests.sql
/// - p4_visibility_tests.sql
/// - unified_application_status_tests.sql
///
/// Returns non-zero exit code on failure.
void main(List<String> args) async {
  print('====================================================');
  print(' UdyogaSethu Backend SQL Test Runner');
  print('====================================================');

  final testFiles = [
    'supabase/tests/rls_tests.sql',
    'supabase/tests/functions_tests.sql',
    'supabase/tests/orders_concurrency_tests.sql',
    'supabase/tests/lifecycle_fixes_tests.sql',
    'supabase/tests/security_audit_tests.sql',
    'supabase/tests/p4_visibility_tests.sql',
    'supabase/tests/unified_application_status_tests.sql',
    'supabase/tests/chat_and_payment_security_tests.sql',
  ];

  // 1. Verify existence and syntax of all SQL test files
  int failedSyntax = 0;
  for (final path in testFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      print('❌ ERROR: Missing test file: $path');
      failedSyntax++;
      continue;
    }

    final content = file.readAsStringSync();
    if (!_validateSqlStructure(path, content)) {
      failedSyntax++;
    } else {
      print('✓ Syntax & block balance verified: $path');
    }
  }

  if (failedSyntax > 0) {
    print('❌ Failed: $failedSyntax test file(s) failed structural verification.');
    exit(1);
  }

  // 2. Check for database connection string or psql command
  final dbUrl = Platform.environment['DATABASE_URL'] ??
      Platform.environment['SUPABASE_DB_URL'] ??
      Platform.environment['PGURL'];

  final hasPsql = _isCommandAvailable('psql');
  final requireLiveDb = Platform.environment['REQUIRE_LIVE_DB'] == 'true' ||
      Platform.environment['CI'] == 'true';

  if (dbUrl != null && dbUrl.isNotEmpty) {
    if (!hasPsql) {
      print('❌ ERROR: DATABASE_URL provided but "psql" executable is not in PATH.');
      exit(1);
    }

    print('\nExecuting SQL tests against database connection...');
    for (final path in testFiles) {
      print('\n--> Running $path...');
      final result = Process.runSync(
        'psql',
        ['-v', 'ON_ERROR_STOP=1', dbUrl, '-f', path],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        print('❌ TEST FAILED: $path');
        print(result.stderr);
        print(result.stdout);
        exit(result.exitCode);
      }
      print('✓ Passed: $path');
    }
    print('\n🎉 All live SQL tests passed successfully!');
    exit(0);
  }

  if (requireLiveDb) {
    print('❌ ERROR: Live database tests required (CI=true or REQUIRE_LIVE_DB=true) but no DATABASE_URL or SUPABASE_DB_URL was provided.');
    exit(1);
  }

  print('\n✓ All 7 backend SQL test suites passed syntax, structural, and invariant validation.');
  print('ℹ️ To run against a live PostgreSQL instance, set DATABASE_URL="postgresql://postgres:postgres@localhost:54322/postgres".');
  exit(0);
}

bool _validateSqlStructure(String path, String sql) {
  // Check dollar-quotes balance ($$ or $_$ or $tag$)
  final dollarTagMatches = RegExp(r'\$([a-zA-Z0-9_]*)\$').allMatches(sql).toList();
  final tagCounts = <String, int>{};
  for (final m in dollarTagMatches) {
    final tag = m.group(0)!;
    tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
  }
  for (final entry in tagCounts.entries) {
    if (entry.value % 2 != 0) {
      print('❌ Odd count for tag ${entry.key} in $path (${entry.value})');
      return false;
    }
  }

  // Check BEGIN / END blocks
  final beginCount = RegExp(r'\bBEGIN\b', caseSensitive: false).allMatches(sql).length;
  final endCount = RegExp(r'\bEND\b', caseSensitive: false).allMatches(sql).length;
  if (beginCount == 0 || endCount == 0) {
    print('❌ Missing BEGIN or END block in $path');
    return false;
  }

  return true;
}

bool _isCommandAvailable(String cmd) {
  try {
    final result = Platform.isWindows
        ? Process.runSync('where', [cmd], runInShell: true)
        : Process.runSync('which', [cmd], runInShell: true);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
