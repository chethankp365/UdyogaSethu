// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final dir = Directory('supabase/migrations');
  final files = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final tables = <String, String>{};
  final rlsEnabled = <String>{};
  final policies = <String, List<String>>{};
  final secDefinerFuncsWithoutSearchPath = <String>[];

  for (final f in files) {
    final content = f.readAsStringSync();
    final fname = f.uri.pathSegments.last;

    // Find tables
    for (final m in RegExp(
      r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:public\.)?([a-zA-Z0-9_]+)',
      caseSensitive: false,
    ).allMatches(content)) {
      tables.putIfAbsent(m.group(1)!, () => fname);
    }

    // Find ENABLE ROW LEVEL SECURITY
    for (final m in RegExp(
      r'ALTER\s+TABLE\s+(?:ONLY\s+)?(?:public\.)?([a-zA-Z0-9_]+)\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY',
      caseSensitive: false,
    ).allMatches(content)) {
      rlsEnabled.add(m.group(1)!);
    }

    // Find POLICIES
    for (final m in RegExp(
      r'CREATE\s+POLICY\s+([a-zA-Z0-9_]+)\s+ON\s+(?:public\.)?([a-zA-Z0-9_]+)',
      caseSensitive: false,
    ).allMatches(content)) {
      policies.putIfAbsent(m.group(2)!, () => []).add(m.group(1)!);
    }

    // Check SECURITY DEFINER without search_path
    final funcMatches = RegExp(
      r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?([a-zA-Z0-9_]+)\s*\([^)]*\)[\s\S]*?\$\$',
      caseSensitive: false,
    ).allMatches(content);

    for (final fm in funcMatches) {
      final block = fm.group(0)!;
      final header = block.substring(0, block.indexOf(r'$$'));
      if (header.toUpperCase().contains('SECURITY DEFINER') &&
          !header.toUpperCase().contains('SET SEARCH_PATH')) {
        final funcName = fm.group(1)!;
        secDefinerFuncsWithoutSearchPath.add('$fname: $funcName');
      }
    }
  }

  print('Total tables created: ${tables.length}');
  final tablesWithoutRls = tables.keys.where((t) => !rlsEnabled.contains(t)).toList();
  print('Tables without explicit ENABLE RLS (${tablesWithoutRls.length}):');
  for (final t in tablesWithoutRls) {
    print('  - $t (created in ${tables[t]})');
  }

  final tablesWithoutPolicies = tables.keys.where((t) => !policies.containsKey(t)).toList();
  print('Tables without policies (${tablesWithoutPolicies.length}):');
  for (final t in tablesWithoutPolicies) {
    print('  - $t (created in ${tables[t]})');
  }

  print('SECURITY DEFINER functions missing SET search_path (${secDefinerFuncsWithoutSearchPath.length}):');
  for (final s in secDefinerFuncsWithoutSearchPath.toSet()) {
    print('  - $s');
  }
}
