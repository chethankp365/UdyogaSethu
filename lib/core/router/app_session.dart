import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/router/routes.dart';

/// Enum representing session auth/onboarding lifecycle status.
enum AuthSessionStatus {
  booting,
  needsOnboarding,
  signedOut,
  needsRole,
  needsProfile,
  ready,
  suspended,
  roleConflict,
}

/// Enum representing the active user role shell.
enum UserRole {
  seeker,
  provider,
  farmer,
}

/// Session data snapshot.
class AppSessionData {
  final AuthSessionStatus status;
  final UserRole activeRole;
  final List<UserRole> assignedRoles;
  final String? seekerType;
  final String? deepLinkPending;
  final UserRole? existingRole;
  final UserRole? chosenRole;

  const AppSessionData({
    this.status = AuthSessionStatus.booting,
    this.activeRole = UserRole.seeker,
    this.assignedRoles = const [],
    this.seekerType,
    this.deepLinkPending,
    this.existingRole,
    this.chosenRole,
  });

  AppSessionData copyWith({
    AuthSessionStatus? status,
    UserRole? activeRole,
    List<UserRole>? assignedRoles,
    String? seekerType,
    String? deepLinkPending,
    bool clearDeepLink = false,
    UserRole? existingRole,
    UserRole? chosenRole,
  }) {
    return AppSessionData(
      status: status ?? this.status,
      activeRole: activeRole ?? this.activeRole,
      assignedRoles: assignedRoles ?? this.assignedRoles,
      seekerType: seekerType ?? this.seekerType,
      deepLinkPending: clearDeepLink ? null : (deepLinkPending ?? this.deepLinkPending),
      existingRole: existingRole ?? this.existingRole,
      chosenRole: chosenRole ?? this.chosenRole,
    );
  }
}

/// Riverpod Notifier managing application session lifecycle and active role state.
class AppSessionNotifier extends Notifier<AppSessionData> {
  @override
  AppSessionData build() {
    return const AppSessionData(
      status: AuthSessionStatus.booting,
      activeRole: UserRole.seeker,
      assignedRoles: [],
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

  void setDeepLinkPending(String? uri) {
    state = state.copyWith(deepLinkPending: uri, clearDeepLink: uri == null);
  }

  void updateSession({
    AuthSessionStatus? status,
    UserRole? role,
    List<UserRole>? assignedRoles,
    String? seekerType,
    UserRole? existingRole,
    UserRole? chosenRole,
  }) {
    state = state.copyWith(
      status: status,
      activeRole: role,
      assignedRoles: assignedRoles,
      seekerType: seekerType,
      existingRole: existingRole,
      chosenRole: chosenRole,
    );
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
    }
  }
}

/// Global Riverpod provider for [AppSessionNotifier].
final appSessionProvider =
    NotifierProvider<AppSessionNotifier, AppSessionData>(AppSessionNotifier.new);
