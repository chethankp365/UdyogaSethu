// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:io';

void main() {
  final files = [
    'supabase/catchup/verify_all.sql',
    'supabase/catchup/apply_all_pending.sql',
    'supabase/migrations/0640_db_contract_sync.sql',
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
  print('Validating $path (${sql.length} chars, ${sql.split('\n').length} lines)...');
  
  // 1. Dollar quote balance ($$ or $_$ or $tag$)
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

  // 2. Parentheses balance outside of single quotes and dollar quotes
  int parenBalance = 0;
  int line = 1;
  bool inSingleQuote = false;
  String? inDollarTag;

  for (int i = 0; i < sql.length; i++) {
    final ch = sql[i];
    if (ch == '\n') line++;

    // Check single line comments
    if (!inSingleQuote && inDollarTag == null && ch == '-' && i + 1 < sql.length && sql[i + 1] == '-') {
      // skip until newline
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
    print('  ✓ Parentheses are perfectly balanced outside string/dollar literals.');
  } else {
    print('  WARNING: Unbalanced parentheses: balance = $parenBalance');
  }

  // 3. Check for dangerous statements
  final lower = sql.toLowerCase();
  if (lower.contains('drop table')) {
    print('  WARNING: Contains DROP TABLE');
  } else {
    print('  ✓ Zero DROP TABLE statements.');
  }
  if (lower.contains('drop column')) {
    print('  WARNING: Contains DROP COLUMN');
  } else {
    print('  ✓ Zero DROP COLUMN statements.');
  }
}

