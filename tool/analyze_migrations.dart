// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:io';

void main() {
  final dir = Directory('supabase/migrations');
  final files = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    if (name.compareTo('0190') < 0) continue;

    final content = file.readAsStringSync();
    final items = <String>[];

    // Find tables
    for (final m in RegExp(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:public\.)?([a-zA-Z0-9_]+)', caseSensitive: false).allMatches(content)) {
      items.add('table: ${m.group(1)}');
    }

    // Find columns
    for (final m in RegExp(r'ALTER\s+TABLE\s+(?:ONLY\s+)?(?:public\.)?([a-zA-Z0-9_]+)\s+ADD\s+COLUMN\s+(?:IF\s+NOT\s+EXISTS\s+)?([a-zA-Z0-9_]+)', caseSensitive: false).allMatches(content)) {
      items.add('column: ${m.group(1)}.${m.group(2)}');
    }

    // Find functions
    for (final m in RegExp(r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?([a-zA-Z0-9_]+)\s*\(([^)]*)\)', caseSensitive: false).allMatches(content)) {
      final fname = m.group(1);
      final rawParams = m.group(2)?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
      items.add('function: $fname($rawParams)');
    }

    // Find enums / enum values
    for (final m in RegExp(r'ALTER\s+TYPE\s+(?:public\.)?([a-zA-Z0-9_]+)\s+ADD\s+VALUE\s+(?:IF\s+NOT\s+EXISTS\s+)?([^\s;]+)', caseSensitive: false).allMatches(content)) {
      items.add('enum_value: ${m.group(1)}.${m.group(2)}');
    }
    for (final m in RegExp(r'CREATE\s+TYPE\s+(?:public\.)?([a-zA-Z0-9_]+)\s+AS\s+ENUM\s*\(([^)]+)\)', caseSensitive: false).allMatches(content)) {
      items.add('enum: ${m.group(1)}');
    }

    // Find policies
    for (final m in RegExp(r'CREATE\s+POLICY\s+([a-zA-Z0-9_]+)\s+ON\s+(?:public\.)?([a-zA-Z0-9_]+)', caseSensitive: false).allMatches(content)) {
      items.add('policy: ${m.group(2)}.$m.group(1)');
    }

    // Find triggers
    for (final m in RegExp(r'CREATE\s+TRIGGER\s+([a-zA-Z0-9_]+)\s+(?:BEFORE|AFTER)\s+.*?\s+ON\s+(?:public\.)?([a-zA-Z0-9_]+)', caseSensitive: false).allMatches(content)) {
      items.add('trigger: ${m.group(2)}.$m.group(1)');
    }

    // Realtime
    for (final m in RegExp(r'ALTER\s+PUBLICATION\s+supabase_realtime\s+ADD\s+TABLE\s+(?:public\.)?([a-zA-Z0-9_]+)', caseSensitive: false).allMatches(content)) {
      items.add('realtime: ${m.group(1)}');
    }

    print('[$name] (${items.length} items)');
    for (final it in items) {
      print('  $it');
    }
  }
}

