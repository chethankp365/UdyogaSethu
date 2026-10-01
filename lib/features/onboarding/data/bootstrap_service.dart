import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    try {
      // Step 1: Package Info & Version (20%)
      state = state.copyWith(progress: 0.20, statusText: 'Checking package version...');
      String version = '1.0.0';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        version = packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';
      } catch (_) {
        // Fallback version if PackageInfo unavailable in test
      }
      state = state.copyWith(versionString: version);

      // Step 2: Load Local Preferences (40%)
      state = state.copyWith(progress: 0.40, statusText: 'Loading preferences...');
      final prefs = await SharedPreferences.getInstance();
      final hasSeenIntro = prefs.getBool(SharedPrefKeys.hasSeenIntro) ?? false;
      final savedRoleStr = prefs.getString(SharedPrefKeys.activeRole);

      UserRole activeRole = UserRole.seeker;
      if (savedRoleStr != null) {
        if (savedRoleStr == 'provider') activeRole = UserRole.provider;
        if (savedRoleStr == 'farmer') activeRole = UserRole.farmer;
      }

      // Step 3: Initialize Supabase Session & Profile (80%)
      state = state.copyWith(progress: 0.80, statusText: 'Restoring session...');
      final supabaseClient = ref.read(supabaseClientProvider);
      final currentSession = supabaseClient.auth.currentSession;
      final currentUser = currentSession?.user;

      AuthSessionStatus finalStatus = AuthSessionStatus.needsOnboarding;

      if (currentUser != null) {
        // User is signed in, check profile completeness
        try {
          final profileRow = await supabaseClient
              .from('profiles')
              .select('onboarding_complete, active_role')
              .eq('id', currentUser.id)
              .maybeSingle();

          if (profileRow != null) {
            final isComplete = profileRow['onboarding_complete'] as bool? ?? false;
            final dbRole = profileRow['active_role'] as String?;
            if (dbRole == 'provider') activeRole = UserRole.provider;
            if (dbRole == 'farmer') activeRole = UserRole.farmer;

            finalStatus = isComplete ? AuthSessionStatus.ready : AuthSessionStatus.needsProfile;
          } else {
            finalStatus = AuthSessionStatus.needsProfile;
          }
        } catch (e, st) {
          AppLogger.e('Failed to fetch profile during bootstrap', e, st);
          finalStatus = AuthSessionStatus.needsProfile;
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
      );

      // Update global AppSessionNotifier
      ref.read(appSessionProvider.notifier).updateSession(
            status: finalStatus,
            role: activeRole,
          );
    } catch (err, stack) {
      AppLogger.e('Bootstrapping error', err, stack);
      state = state.copyWith(
        progress: 1.0,
        isDone: true,
        error: err.toString(),
      );
      // Fallback status
      ref.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.needsOnboarding);
    } finally {
      stopwatch.stop();
    }
  }
}

/// Global provider for [BootstrapNotifier].
final bootstrapProvider = NotifierProvider<BootstrapNotifier, BootstrapState>(BootstrapNotifier.new);
