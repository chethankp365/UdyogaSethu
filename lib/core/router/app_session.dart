import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/router/routes.dart';

/// Enum representing session auth/onboarding lifecycle status.
enum AuthSessionStatus {
  booting,
  needsOnboarding,
  signedOut,
  needsProfile,
  ready,
}

/// Enum representing the active user role shell.
enum UserRole {
  seeker,
  provider,
  farmer,
  admin,
}

/// Session data snapshot.
class AppSessionData {
  final AuthSessionStatus status;
  final UserRole activeRole;

  const AppSessionData({
    this.status = AuthSessionStatus.ready,
    this.activeRole = UserRole.seeker,
  });

  AppSessionData copyWith({
    AuthSessionStatus? status,
    UserRole? activeRole,
  }) {
    return AppSessionData(
      status: status ?? this.status,
      activeRole: activeRole ?? this.activeRole,
    );
  }
}

/// Riverpod Notifier managing application session lifecycle and active role state.
class AppSessionNotifier extends Notifier<AppSessionData> {
  @override
  AppSessionData build() {
    return const AppSessionData(
      status: AuthSessionStatus.ready,
      activeRole: UserRole.seeker,
    );
  }

  AuthSessionStatus get status => state.status;
  UserRole get activeRole => state.activeRole;

  void setSessionStatus(AuthSessionStatus status) {
    state = state.copyWith(status: status);
  }

  void setRole(UserRole role) {
    state = state.copyWith(activeRole: role);
  }

  void updateSession({AuthSessionStatus? status, UserRole? role}) {
    state = state.copyWith(status: status, activeRole: role);
  }

  /// Calculates the default home route for a given user role.
  static String getHomeForRole(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return AppRoutes.seekerHome;
      case UserRole.provider:
        return AppRoutes.providerHome;
      case UserRole.farmer:
        return AppRoutes.farmerHome;
      case UserRole.admin:
        return AppRoutes.adminDashboard;
    }
  }
}

/// Global Riverpod provider for [AppSessionNotifier].
final appSessionProvider =
    NotifierProvider<AppSessionNotifier, AppSessionData>(AppSessionNotifier.new);
