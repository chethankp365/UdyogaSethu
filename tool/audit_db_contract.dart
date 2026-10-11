// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:io';

class RpcCall {
  final String file;
  final int line;
  final String name;
  final List<String> params;

  RpcCall(this.file, this.line, this.name, this.params);
}

class TableCall {
  final String file;
  final int line;
  final String table;
  final String operation;
  final String details;

  TableCall(this.file, this.line, this.table, this.operation, this.details);
}

void main() {
  final rpcCalls = <RpcCall>[];
  final tableCalls = <TableCall>[];

  final libDir = Directory('lib');
  for (final file in libDir.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final lines = file.readAsLinesSync();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // RPC match
      if (line.contains('.rpc(')) {
        final rpcMatch = RegExp(r"""\.rpc\(\s*['"]([a-zA-Z0-9_]+)['"]""").firstMatch(line);
        if (rpcMatch != null) {
          final rpcName = rpcMatch.group(1)!;
          // Look ahead for params
          final params = <String>[];
          final combined = StringBuffer(line);
          int j = i + 1;
          while (j < lines.length && j < i + 35 && !combined.toString().contains(');')) {
            combined.write(' ${lines[j]}');
            j++;
          }
          final text = combined.toString();
          final paramMatches = RegExp(r"""['"]([a-zA-Z0-9_]+)['"]\s*:""").allMatches(text);
          for (final pm in paramMatches) {
            final p = pm.group(1)!;
            if (p != 'params' && !params.contains(p)) {
              params.add(p);
            }
          }
          rpcCalls.add(RpcCall(file.path, i + 1, rpcName, params));
        }
      }

      // from('table') match
      if (line.contains('.from(')) {
        final tableMatch = RegExp(r"""\.from\(\s*['"]([a-zA-Z0-9_]+)['"]""").firstMatch(line);
        if (tableMatch != null) {
          final tableName = tableMatch.group(1)!;
          // Look ahead for select, insert, update, etc.
          final combined = StringBuffer(line);
          int j = i + 1;
          while (j < lines.length && j < i + 15 && !combined.toString().contains(';')) {
            combined.write(' ${lines[j]}');
            j++;
          }
          final text = combined.toString();
          String op = 'unknown';
          if (text.contains('.select(')) op = 'select';
          else if (text.contains('.insert(')) op = 'insert';
          else if (text.contains('.update(')) op = 'update';
          else if (text.contains('.upsert(')) op = 'upsert';
          else if (text.contains('.delete(')) op = 'delete';

          tableCalls.add(TableCall(file.path, i + 1, tableName, op, text.trim()));
        }
      }
    }
  }

  // Also scan supabase/functions
  final funcDir = Directory('supabase/functions');
  for (final file in funcDir.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.ts')) continue;
    final lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('.rpc(')) {
        final rpcMatch = RegExp(r"""\.rpc\(\s*['"]([a-zA-Z0-9_]+)['"]""").firstMatch(line);
        if (rpcMatch != null) {
          rpcCalls.add(RpcCall(file.path, i + 1, rpcMatch.group(1)!, []));
        }
      }
      if (line.contains('.from(')) {
        final tableMatch = RegExp(r"""\.from\(\s*['"]([a-zA-Z0-9_]+)['"]""").firstMatch(line);
        if (tableMatch != null) {
          tableCalls.add(TableCall(file.path, i + 1, tableMatch.group(1)!, 'edge_op', line.trim()));
        }
      }
    }
  }

  print('=== SCANNED RPC CALLS: ${rpcCalls.length} ===');
  final uniqueRpcs = <String, Set<String>>{};
  for (final r in rpcCalls) {
    uniqueRpcs.putIfAbsent(r.name, () => <String>{}).addAll(r.params);
  }
  for (final entry in uniqueRpcs.entries) {
    print('RPC: ${entry.key} -> params: ${entry.value.toList()}');
  }

  print('\n=== SCANNED TABLES: ${tableCalls.length} ===');
  final uniqueTables = tableCalls.map((t) => t.table).toSet().toList()..sort();
  print('Tables referenced: $uniqueTables');

  // Print all detailed calls to a report
  final sink = File('tool/detailed_contract_scan.txt').openWrite();
  sink.writeln('=== RPC CALLS ===');
  for (final r in rpcCalls) {
    sink.writeln('${r.file}:${r.line} -> ${r.name} (${r.params.join(', ')})');
  }
  sink.writeln('\n=== TABLE CALLS ===');
  for (final t in tableCalls) {
    sink.writeln('${t.file}:${t.line} -> table: ${t.table} [${t.operation}]');
  }
  sink.close();
}

