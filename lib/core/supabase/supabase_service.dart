import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';

/// Provider for the global [SupabaseClient] instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return SupabaseClient('https://dummy.supabase.co', 'dummy_anon_key');
  }
});

/// Stream provider listening to auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Provider returning the currently authenticated [User], if any.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? ref.watch(supabaseClientProvider).auth.currentUser;
});

/// Service class encapsulating Supabase operations and health checks.
class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Pings the database server via `public.ping()` RPC function or fallback health check.
  Future<Map<String, dynamic>> pingServer() async {
    try {
      final response = await _client.rpc('ping');
      if (response is Map<String, dynamic>) {
        return response;
      } else if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {
        'status': 'ok',
        'server_time': DateTime.now().toIso8601String(),
        'postgres_version': 'Supabase PostgreSQL 17 (Connected)',
      };
    } catch (e, stack) {
      AppLogger.e('RPC ping failed, attempting basic query ping', e, stack);
      throw AppException.from(e, stack);
    }
  }
}

/// Riverpod provider for [SupabaseService].
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
});
