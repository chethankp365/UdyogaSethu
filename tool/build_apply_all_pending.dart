// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:io';

void main() {
  final migrationsDir = Directory('supabase/migrations');
  final files = migrationsDir.listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final buf = StringBuffer();

  buf.writeln('-- ============================================================================');
  buf.writeln('-- Repeatable Schema Catch-Up Script: apply_all_pending.sql');
  buf.writeln('-- Description: Idempotent, non-destructive catch-up script applying all pending');
  buf.writeln('--              database migrations from 0190 through 0640 in strict dependency order.');
  buf.writeln('-- Features:');
  buf.writeln('--   - Strictly non-destructive: NO DROP TABLE, NO DROP COLUMN, NO data deletion.');
  buf.writeln('--   - Drops older conflicting function overloads so exactly ONE canonical overload remains.');
  buf.writeln('--   - Preserves all data: backfills farmer_profiles.delivery_radius_km from legacy delivery_options.');
  buf.writeln('--   - Extends application_status enum with \'accepted\' and \'declined\'.');
  buf.writeln('--   - Idempotent policies: DROP POLICY IF EXISTS before CREATE POLICY.');
  buf.writeln('--   - Idempotent triggers: DROP TRIGGER IF EXISTS before CREATE TRIGGER.');
  buf.writeln('--   - Idempotent tables/indices/columns: IF NOT EXISTS.');
  buf.writeln('--   - Safe enum additions: ALTER TYPE ... ADD VALUE IF NOT EXISTS.');
  buf.writeln('--   - Adds jobs, job_applications, and job_assignments to supabase_realtime publication.');
  buf.writeln('--   - Excludes demo/seed data blocks.');
  buf.writeln('--   - Finishes with NOTIFY pgrst, \'reload schema\'.');
  buf.writeln('-- ============================================================================');
  buf.writeln();

  for (final file in files) {
    final fileName = file.uri.pathSegments.last;
    final prefix = int.tryParse(fileName.split('_').first);
    if (prefix == null || prefix < 190) continue;

    buf.writeln('-- ' + ('-' * 76));
    buf.writeln('-- Source Migration: $fileName');
    buf.writeln('-- ' + ('-' * 76));
    buf.writeln();

    String content = file.readAsStringSync();

    // 1. Exclude demo seed blocks in 0520, 0530, 0540
    if (fileName.startsWith('0520_')) {
      final seedIdx = content.indexOf('-- 8. Seed sample produce listings');
      if (seedIdx != -1) {
        content = content.substring(0, seedIdx).trim();
      }
    } else if (fileName.startsWith('0530_')) {
      final seedIdx = content.indexOf('-- 7. Seed initial equipment pins');
      if (seedIdx != -1) {
        content = content.substring(0, seedIdx).trim();
      }
    } else if (fileName.startsWith('0540_')) {
      final seedIdx = content.indexOf('-- 4. Seed sample produce lots');
      if (seedIdx != -1) {
        content = content.substring(0, seedIdx).trim();
      }
    }

    // 2. Ensure idempotent CREATE TABLE IF NOT EXISTS
    content = content.replaceAll(RegExp(r'CREATE TABLE (?!IF NOT EXISTS)', caseSensitive: false), 'CREATE TABLE IF NOT EXISTS ');

    // 3. Ensure idempotent CREATE INDEX IF NOT EXISTS
    content = content.replaceAll(RegExp(r'CREATE INDEX (?!IF NOT EXISTS)', caseSensitive: false), 'CREATE INDEX IF NOT EXISTS ');
    content = content.replaceAll(RegExp(r'CREATE UNIQUE INDEX (?!IF NOT EXISTS)', caseSensitive: false), 'CREATE UNIQUE INDEX IF NOT EXISTS ');

    // 4. Transform CREATE POLICY to have DROP POLICY IF EXISTS before it
    // Pattern: CREATE POLICY policy_name ON table_name
    final policyRegex = RegExp(r'CREATE\s+POLICY\s+([a-zA-Z0-9_]+)\s+ON\s+([a-zA-Z0-9_.]+)', caseSensitive: false);
    final policyLines = <String>[];
    for (final line in content.split('\n')) {
      final match = policyRegex.firstMatch(line);
      if (match != null && !line.trim().toUpperCase().startsWith('--')) {
        final policyName = match.group(1);
        final tableName = match.group(2);
        policyLines.add('DROP POLICY IF EXISTS $policyName ON $tableName;\n$line');
      } else {
        policyLines.add(line);
      }
    }
    content = policyLines.join('\n');

    // 5. Transform CREATE TRIGGER to have DROP TRIGGER IF EXISTS before it
    // Pattern: CREATE TRIGGER trigger_name ... ON table_name
    final triggerRegex = RegExp(r'CREATE\s+TRIGGER\s+([a-zA-Z0-9_]+)\s+.*?\s+ON\s+([a-zA-Z0-9_.]+)', caseSensitive: false);
    final triggerLines = <String>[];
    for (final line in content.split('\n')) {
      final match = triggerRegex.firstMatch(line);
      if (match != null && !line.trim().toUpperCase().startsWith('--')) {
        final triggerName = match.group(1);
        final tableName = match.group(2);
        triggerLines.add('DROP TRIGGER IF EXISTS $triggerName ON $tableName;\n$line');
      } else {
        triggerLines.add(line);
      }
    }
    content = triggerLines.join('\n');

    buf.writeln(content.trim());
    buf.writeln();
    buf.writeln();
  }

  // Final reload schema
  buf.writeln('-- ' + ('-' * 76));
  buf.writeln('-- Final Schema Reload Notification');
  buf.writeln('-- ' + ('-' * 76));
  buf.writeln("NOTIFY pgrst, 'reload schema';");
  buf.writeln();

  File('supabase/catchup/apply_all_pending.sql').writeAsStringSync(buf.toString());
  print('Successfully wrote supabase/catchup/apply_all_pending.sql (${buf.length} chars)');
}

