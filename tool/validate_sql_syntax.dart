// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:io';

void main() {
  final files = [
    'supabase/migrations/0650_jobs_core.sql',
    'supabase/migrations/0651_tickets_qr.sql',
    'supabase/migrations/0652_money_security.sql',
    'supabase/migrations/0653_privacy_and_debug_lockdown.sql',
    'supabase/migrations/0654_earnings_and_farmer.sql',
    'supabase/migrations/0660_real_qr_ticket_flow.sql',
    'supabase/dev/seed_cleanup.sql',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      print('ERROR: $path does not exist!');
      continue;
    }
    final content = file.readAsStringSync();
    validateSql(path, content);
  }
}

void validateSql(String path, String sql) {
  final lines = sql.split('\n');
  print('Validating $path (${sql.length} chars, ${lines.length} lines)...');
  
  // 1. Line count check (must be under 300 lines for migrations)
  if (path.contains('/migrations/') && lines.length > 300) {
    print('  WARNING: File exceeds 300 lines! (${lines.length} lines)');
  } else {
    print('  ✓ Line count: ${lines.length} lines (under 300 lines limit)');
  }

  // 2. Dollar quote balance ($$ or $_$ or $tag$)
  final dollarTagMatches = RegExp(r'\$([a-zA-Z0-9_]*)\$').allMatches(sql).toList();
  final tagCounts = <String, int>{};
  for (final m in dollarTagMatches) {
    final tag = m.group(0)!;
    tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
  }
  bool dollarOk = true;
  for (final entry in tagCounts.entries) {
    if (entry.value % 2 != 0) {
      print('  WARNING: Dollar quote tag ${entry.key} appears ${entry.value} times (odd count)');
      dollarOk = false;
    }
  }
  if (dollarOk) {
    print('  ✓ All dollar quote tags (\$\$ / \\\$tag\\\$) are perfectly balanced.');
  }

  // 3. Parentheses balance outside of single quotes and dollar quotes
  int parenBalance = 0;
  int line = 1;
  bool inSingleQuote = false;
  String? inDollarTag;

  for (int i = 0; i < sql.length; i++) {
    final ch = sql[i];
    if (ch == '\n') line++;

    // Check single line comments
    if (!inSingleQuote && inDollarTag == null && ch == '-' && i + 1 < sql.length && sql[i + 1] == '-') {
      while (i < sql.length && sql[i] != '\n') {
        i++;
      }
      line++;
      continue;
    }

    // Check dollar tag start/end
    if (!inSingleQuote && ch == '\$') {
      final sub = sql.substring(i);
      final tagMatch = RegExp(r'^\$([a-zA-Z0-9_]*)\$').firstMatch(sub);
      if (tagMatch != null) {
        final tag = tagMatch.group(0)!;
        if (inDollarTag == null) {
          inDollarTag = tag;
        } else if (inDollarTag == tag) {
          inDollarTag = null;
        }
        i += tag.length - 1;
        continue;
      }
    }

    if (inDollarTag != null) continue;

    if (ch == "'") {
      if (inSingleQuote && i + 1 < sql.length && sql[i + 1] == "'") {
        i++; // escaped quote
        continue;
      }
      inSingleQuote = !inSingleQuote;
      continue;
    }

    if (inSingleQuote) continue;

    if (ch == '(') parenBalance++;
    if (ch == ')') parenBalance--;

    if (parenBalance < 0) {
      print('  ERROR: Extra closing parenthesis at line $line!');
      parenBalance = 0;
    }
  }

  if (parenBalance == 0) {
    print('  ✓ Parentheses are perfectly balanced.');
  } else {
    print('  WARNING: Unbalanced parentheses: balance = $parenBalance');
  }
}
