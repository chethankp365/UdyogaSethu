import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  final bool isOffline;
  final bool canOpenOffline;

  const BootstrapState({
    this.progress = 0.0,
    this.statusText = 'Initializing UdyogaSethu...',
    this.versionString = '1.0.0',
    this.isDone = false,
    this.error,
    this.isOffline = false,
    this.canOpenOffline = false,
  });

  BootstrapState copyWith({
    double? progress,
    String? statusText,
    String? versionString,
    bool? isDone,
    String? error,
    bool? isOffline,
    bool? canOpenOffline,
  }) {
    return BootstrapState(
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      versionString: versionString ?? this.versionString,
      isDone: isDone ?? this.isDone,
      error: error ?? this.error,
      isOffline: isOffline ?? this.isOffline,
      canOpenOffline: canOpenOffline ?? this.canOpenOffline,
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

      // Step 2: Load Local Preferences & Offline Check (40%)
      state = state.copyWith(progress: 0.40, statusText: 'Initializing UdyogaSethu...');
      final prefs = await SharedPreferences.getInstance();
      final hasSeenIntro = prefs.getBool(SharedPrefKeys.hasSeenIntro) ?? false;
      final savedRoleStr = prefs.getString(SharedPrefKeys.activeRole);
      final cachedAuthStatusStr = prefs.getString('cached_auth_status');
      final cachedRoleStr = prefs.getString('cached_active_role');
      final cachedSeekerType = prefs.getString('cached_seeker_type');
      final canOpenOffline = (cachedAuthStatusStr == AuthSessionStatus.ready.name || cachedAuthStatusStr == 'ready') && (cachedRoleStr != null || savedRoleStr != null);

      UserRole activeRole = UserRole.seeker;
      if (savedRoleStr != null) {
        if (savedRoleStr == 'provider') activeRole = UserRole.provider;
        if (savedRoleStr == 'farmer') activeRole = UserRole.farmer;
      }

      // Detect connectivity first
      bool isOffline = false;
      try {
        final connList = await Connectivity().checkConnectivity();
        isOffline = connList.every((r) => r == ConnectivityResult.none);
      } catch (_) {
        // Fallback if connectivity plugin is unavailable
      }

      if (isOffline) {
        if (canOpenOffline) {
          final effectiveRole = cachedRoleStr ?? savedRoleStr;
          UserRole recoveredRole = UserRole.seeker;
          if (effectiveRole == 'provider') recoveredRole = UserRole.provider;
          if (effectiveRole == 'farmer') recoveredRole = UserRole.farmer;

          AppLogger.i('Offline startup: opening last cached screen ($recoveredRole)');
          ref.read(appSessionProvider.notifier).updateSession(
            status: AuthSessionStatus.ready,
            role: recoveredRole,
            assignedRoles: [recoveredRole],
            seekerType: cachedSeekerType,
          );

          const minDisplayMs = 1200;
          final elapsedMs = stopwatch.elapsedMilliseconds;
          if (elapsedMs < minDisplayMs) {
            await Future.delayed(Duration(milliseconds: minDisplayMs - elapsedMs));
          }

          state = state.copyWith(
            progress: 1.0,
            statusText: 'Offline Mode',
            isDone: true,
            isOffline: true,
            canOpenOffline: true,
            error: null,
          );
          return;
        } else {
          const minDisplayMs = 600;
          final elapsedMs = stopwatch.elapsedMilliseconds;
          if (elapsedMs < minDisplayMs) {
            await Future.delayed(Duration(milliseconds: minDisplayMs - elapsedMs));
          }

          state = state.copyWith(
            progress: 1.0,
            statusText: 'No Internet Connection',
            isDone: false,
            isOffline: true,
            canOpenOffline: false,
            error: 'No internet connection. Check Wi-Fi or mobile data',
          );
          return;
        }
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

        // 2b. Fetch worker profile seeker_type if exists
        try {
          final wp = await supabaseClient
              .from('worker_profiles')
              .select('seeker_type')
              .eq('user_id', currentUser.id)
              .maybeSingle()
              .timeout(const Duration(seconds: 5));
          if (wp != null) {
            seekerTypeStr = wp['seeker_type'] as String?;
          }
        } catch (e) {
          AppLogger.w('Could not fetch worker_profiles seeker_type: $e');
        }

        // 3. Fetch full bootstrap state via RPC get_bootstrap_state
        try {
          final bootstrapRes = await supabaseClient.rpc('get_bootstrap_state').timeout(const Duration(seconds: 10));
          final Map<String, dynamic> data = (bootstrapRes is String) ? json.decode(bootstrapRes) : (bootstrapRes as Map<String, dynamic>);
          
          final isSuspended = data['is_suspended'] as bool? ?? false;
          final dbRoleStr = data['active_role'] as String? ?? 'seeker';
          final rolesList = (data['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final wizardMap = data['wizard_completion'] as Map<String, dynamic>? ?? {};

          bool faceRequired = data['face_required_at_login'] as bool? ?? false;
          bool hasEnrolledFace = data['has_enrolled_face'] as bool? ?? false;

          // Fallback RPC check if face_required_at_login not present in RPC payload
          if (!data.containsKey('face_required_at_login')) {
            try {
              final reqRes = await supabaseClient.rpc('get_face_login_requirement').timeout(const Duration(seconds: 5));
              faceRequired = (reqRes as bool?) ?? false;
            } catch (e) {
              AppLogger.w('Could not fetch get_face_login_requirement RPC: $e');
            }
          }

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
                faceRequiredAtLogin: faceRequired,
                hasEnrolledFace: hasEnrolledFace,
              );
          if (finalStatus == AuthSessionStatus.ready) {
            await prefs.setString('cached_auth_status', AuthSessionStatus.ready.name);
            await prefs.setString('cached_active_role', activeRole.name);
            if (seekerTypeStr != null) {
              await prefs.setString('cached_seeker_type', seekerTypeStr);
            } else {
              await prefs.remove('cached_seeker_type');
            }
          }
        } catch (e, st) {
          AppLogger.e('Failed to fetch get_bootstrap_state RPC', e, st);
          rethrow;
        }
      } else {
        // User signed out
        finalStatus = hasSeenIntro ? AuthSessionStatus.signedOut : AuthSessionStatus.needsOnboarding;
        await prefs.remove('cached_auth_status');
        await prefs.remove('cached_active_role');
        await prefs.remove('cached_seeker_type');
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
      final errStr = err.toString();
      final isNetwork = err is SocketException ||
          err is TimeoutException ||
          errStr.contains('Failed host lookup') ||
          errStr.contains('SocketException') ||
          errStr.contains('AuthRetryableFetchException') ||
          errStr.contains('ClientException') ||
          errStr.contains('Network') ||
          errStr.contains('Connection') ||
          errStr.contains('timed out');

      final prefs = await SharedPreferences.getInstance();
      final cachedAuthStatusStr = prefs.getString('cached_auth_status');
      final cachedRoleStr = prefs.getString('cached_active_role') ?? prefs.getString(SharedPrefKeys.activeRole);
      final canOpenOffline = (cachedAuthStatusStr == AuthSessionStatus.ready.name || cachedAuthStatusStr == 'ready') && cachedRoleStr != null;

      state = state.copyWith(
        progress: 1.0,
        isDone: false,
        isOffline: isNetwork,
        canOpenOffline: canOpenOffline,
        error: isNetwork
            ? 'No internet connection. Check Wi-Fi or mobile data'
            : errStr,
      );
    } finally {
      stopwatch.stop();
    }
  }

  /// Manually transitions the app into offline mode if a cached session exists.
  Future<void> openOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRoleStr = prefs.getString('cached_active_role') ?? prefs.getString(SharedPrefKeys.activeRole);
    final cachedSeekerType = prefs.getString('cached_seeker_type');

    UserRole recoveredRole = UserRole.seeker;
    if (cachedRoleStr == 'provider') recoveredRole = UserRole.provider;
    if (cachedRoleStr == 'farmer') recoveredRole = UserRole.farmer;

    AppLogger.i('User chose to open offline session ($recoveredRole)');
    ref.read(appSessionProvider.notifier).updateSession(
      status: AuthSessionStatus.ready,
      role: recoveredRole,
      assignedRoles: [recoveredRole],
      seekerType: cachedSeekerType,
    );

    state = state.copyWith(
      progress: 1.0,
      statusText: 'Offline Mode',
      isDone: true,
      isOffline: true,
      canOpenOffline: true,
      error: null,
    );
  }
}

/// Global provider for [BootstrapNotifier].
final bootstrapProvider = NotifierProvider<BootstrapNotifier, BootstrapState>(BootstrapNotifier.new);
