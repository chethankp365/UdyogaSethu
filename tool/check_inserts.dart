// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:io';

void main() {
  final migrationsDir = Directory('supabase/migrations');
  final files = migrationsDir.listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final prefix = int.tryParse(name.split('_').first);
    if (prefix == null || prefix < 190) continue;

    final lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.toUpperCase().startsWith('INSERT INTO')) {
        print('$name:${i + 1}: $line');
      }
    }
  }
}

