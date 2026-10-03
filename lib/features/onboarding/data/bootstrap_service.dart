import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';

/// State of the bootstrapping process.
class BootstrapState {
  final double progress;
  final String statusText;
  final String versionString;
  final bool isDone;
  final String? error;

  const BootstrapState({
    this.progress = 0.0,
    this.statusText = 'Initializing UdyogaSethu...',
    this.versionString = '1.0.0',
    this.isDone = false,
    this.error,
  });

  BootstrapState copyWith({
    double? progress,
    String? statusText,
    String? versionString,
    bool? isDone,
    String? error,
  }) {
    return BootstrapState(
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      versionString: versionString ?? this.versionString,
      isDone: isDone ?? this.isDone,
      error: error ?? this.error,
    );
  }
}

/// Key constants for SharedPreferences.
class SharedPrefKeys {
  SharedPrefKeys._();
  static const String hasSeenIntro = 'has_seen_intro';
  static const String selectedLanguage = 'selected_language';
  static const String activeRole = 'active_role';
}

/// Notifier executing real bootstrapping logic during splash.
class BootstrapNotifier extends Notifier<BootstrapState> {
  @override
  BootstrapState build() {
    return const BootstrapState();
  }

  /// Runs real initialization tasks with minimum 1.2s display time.
  Future<void> runBootstrap() async {
    final stopwatch = Stopwatch()..start();
    state = const BootstrapState(progress: 0.0, statusText: 'Initializing UdyogaSethu...');

    try {
      // Step 1: Package Info & Version (20%)
      state = state.copyWith(progress: 0.20, statusText: 'Initializing UdyogaSethu...');
      String version = '1.0.0';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        version = packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';
      } catch (_) {
        // Fallback version if PackageInfo unavailable in test
      }
      state = state.copyWith(versionString: version);

      // Step 2: Load Local Preferences (40%)
      state = state.copyWith(progress: 0.40, statusText: 'Initializing UdyogaSethu...');
      final prefs = await SharedPreferences.getInstance();
      final hasSeenIntro = prefs.getBool(SharedPrefKeys.hasSeenIntro) ?? false;
      final savedRoleStr = prefs.getString(SharedPrefKeys.activeRole);

      UserRole activeRole = UserRole.seeker;
      if (savedRoleStr != null) {
        if (savedRoleStr == 'provider') activeRole = UserRole.provider;
        if (savedRoleStr == 'farmer') activeRole = UserRole.farmer;
      }

      // Step 3: Initialize Supabase Session & Profile (80%)
      state = state.copyWith(progress: 0.80, statusText: 'Initializing UdyogaSethu...');
      final supabaseClient = ref.read(supabaseClientProvider);
      final currentSession = supabaseClient.auth.currentSession;
      final currentUser = currentSession?.user;

      AuthSessionStatus finalStatus = AuthSessionStatus.needsOnboarding;
      List<UserRole> assignedRoles = [UserRole.seeker];
      String? seekerTypeStr;

      if (currentUser != null) {
        UserRole? pendingChosenRole;
        UserRole? conflictExistingRole;
        bool hasRoleConflict = false;

        // 1. Check for local pending role selection and apply via RPC apply_role_selection
        final pendingJson = prefs.getString('pending_role_selection');
        if (pendingJson != null && pendingJson.isNotEmpty) {
          try {
            final Map<String, dynamic> data = json.decode(pendingJson);
            final pendingRoleStr = data['role'] as String?;
            final pendingSeekerTypeStr = data['seekerType'] as String?;

            String? apiRole;
            if (pendingRoleStr == 'seeker' || pendingRoleStr == 'UserRole.seeker') {
              apiRole = 'seeker';
              pendingChosenRole = UserRole.seeker;
            }
            if (pendingRoleStr == 'provider' || pendingRoleStr == 'UserRole.provider') {
              apiRole = 'provider';
              pendingChosenRole = UserRole.provider;
            }
            if (pendingRoleStr == 'farmer' || pendingRoleStr == 'UserRole.farmer') {
              apiRole = 'farmer';
              pendingChosenRole = UserRole.farmer;
            }

            if (apiRole != null) {
              AppLogger.i('Applying pending role selection: $apiRole (seekerType: $pendingSeekerTypeStr)');
              await supabaseClient.rpc('apply_role_selection', params: {
                'p_role': apiRole,
                'p_seeker_type': pendingSeekerTypeStr,
              }).timeout(const Duration(seconds: 10));
              await prefs.remove('pending_role_selection');
            }
          } catch (e) {
            final errStr = e.toString();
            AppLogger.w('apply_role_selection RPC result/exception: $e');
            if (errStr.contains('ROLE_CONFLICT') || errStr.contains('P0002')) {
              hasRoleConflict = true;
              if (errStr.contains('seeker')) conflictExistingRole = UserRole.seeker;
              if (errStr.contains('provider')) conflictExistingRole = UserRole.provider;
              if (errStr.contains('farmer')) conflictExistingRole = UserRole.farmer;
            }
          }
        }

        // 2. Sync user profile language & last_active_at
        final selectedLang = prefs.getString(SharedPrefKeys.selectedLanguage) ?? 'en';
        try {
          await supabaseClient.from('profiles').update({
            'language': selectedLang,
            'last_active_at': DateTime.now().toIso8601String(),
          }).eq('id', currentUser.id).timeout(const Duration(seconds: 10));
        } catch (e) {
          AppLogger.w('Could not update profile language/last_active_at: $e');
        }

        // 3. Fetch full bootstrap state via RPC get_bootstrap_state
        try {
          final bootstrapRes = await supabaseClient.rpc('get_bootstrap_state').timeout(const Duration(seconds: 10));
          final Map<String, dynamic> data = (bootstrapRes is String) ? json.decode(bootstrapRes) : (bootstrapRes as Map<String, dynamic>);
          
          final isSuspended = data['is_suspended'] as bool? ?? false;
          final dbRoleStr = data['active_role'] as String? ?? 'seeker';
          final rolesList = (data['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final wizardMap = data['wizard_completion'] as Map<String, dynamic>? ?? {};

          if (dbRoleStr == 'provider') activeRole = UserRole.provider;
          if (dbRoleStr == 'farmer') activeRole = UserRole.farmer;

          assignedRoles = rolesList.map((r) {
            if (r == 'provider') return UserRole.provider;
            if (r == 'farmer') return UserRole.farmer;
            return UserRole.seeker;
          }).toList();

          if (assignedRoles.isNotEmpty) {
            conflictExistingRole ??= assignedRoles.first;
          }

          // Check if user has an existing role differing from pending chosen role
          if (!kAllowMultiRole && pendingChosenRole != null && conflictExistingRole != null && conflictExistingRole != pendingChosenRole) {
            hasRoleConflict = true;
          }

          final isRoleComplete = wizardMap[activeRole.name] == true;

          if (isSuspended) {
            finalStatus = AuthSessionStatus.suspended;
          } else if (hasRoleConflict && !kAllowMultiRole) {
            finalStatus = AuthSessionStatus.roleConflict;
          } else if (rolesList.isEmpty) {
            finalStatus = AuthSessionStatus.needsRole;
          } else if (isRoleComplete) {
            finalStatus = AuthSessionStatus.ready;
          } else {
            finalStatus = AuthSessionStatus.needsProfile;
          }

          ref.read(appSessionProvider.notifier).updateSession(
                status: finalStatus,
                role: activeRole,
                assignedRoles: assignedRoles,
                seekerType: seekerTypeStr,
                existingRole: conflictExistingRole,
                chosenRole: pendingChosenRole,
              );
        } catch (e, st) {
          AppLogger.e('Failed to fetch get_bootstrap_state RPC', e, st);
          rethrow;
        }
      } else {
        // User signed out
        finalStatus = hasSeenIntro ? AuthSessionStatus.signedOut : AuthSessionStatus.needsOnboarding;
      }

      // Step 4: Ensure minimum 1.2s display time (100%)
      const minDisplayMs = 1200;
      final elapsedMs = stopwatch.elapsedMilliseconds;
      if (elapsedMs < minDisplayMs) {
        await Future.delayed(Duration(milliseconds: minDisplayMs - elapsedMs));
      }

      state = state.copyWith(
        progress: 1.0,
        statusText: 'Ready',
        isDone: true,
        error: null,
      );

      // Update global AppSessionNotifier
      ref.read(appSessionProvider.notifier).updateSession(
            status: finalStatus,
            role: activeRole,
            assignedRoles: assignedRoles,
            seekerType: seekerTypeStr,
          );
    } catch (err, stack) {
      AppLogger.e('Bootstrapping error', err, stack);
      state = state.copyWith(
        progress: 1.0,
        isDone: false,
        error: err.toString(),
      );
    } finally {
      stopwatch.stop();
    }
  }
}

/// Global provider for [BootstrapNotifier].
final bootstrapProvider = NotifierProvider<BootstrapNotifier, BootstrapState>(BootstrapNotifier.new);
