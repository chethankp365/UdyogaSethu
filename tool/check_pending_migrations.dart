// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:io';

void main() {
  final migrationsDir = Directory('supabase/migrations');
  final files = migrationsDir.listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  int count = 0;
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final prefix = name.split('_').first;
    final num = int.tryParse(prefix);
    if (num != null && num >= 190) {
      count++;
      print('$prefix: $name (${file.lengthSync()} bytes)');
    }
  }
  print('Total migrations >= 0190: $count');
}

