import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/features/seeker/presentation/my_applications_controller.dart';
import 'package:udyogasethu/features/seeker/presentation/seeker_home_controller.dart';

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
  final bool seekerTypeLoaded;
  final String? deepLinkPending;
  final UserRole? existingRole;
  final UserRole? chosenRole;
  final bool faceLoginPassed;
  final bool faceRequiredAtLogin;
  final bool hasEnrolledFace;

  const AppSessionData({
    this.status = AuthSessionStatus.booting,
    this.activeRole = UserRole.seeker,
    this.assignedRoles = const [],
    this.seekerType,
    this.seekerTypeLoaded = false,
    this.deepLinkPending,
    this.existingRole,
    this.chosenRole,
    this.faceLoginPassed = false,
    this.faceRequiredAtLogin = false,
    this.hasEnrolledFace = false,
  });

  AppSessionData copyWith({
    AuthSessionStatus? status,
    UserRole? activeRole,
    List<UserRole>? assignedRoles,
    String? seekerType,
    bool? seekerTypeLoaded,
    String? deepLinkPending,
    bool clearDeepLink = false,
    UserRole? existingRole,
    UserRole? chosenRole,
    bool? faceLoginPassed,
    bool? faceRequiredAtLogin,
    bool? hasEnrolledFace,
  }) {
    return AppSessionData(
      status: status ?? this.status,
      activeRole: activeRole ?? this.activeRole,
      assignedRoles: assignedRoles ?? this.assignedRoles,
      seekerType: seekerType ?? this.seekerType,
      seekerTypeLoaded: seekerTypeLoaded ?? this.seekerTypeLoaded,
      deepLinkPending: clearDeepLink ? null : (deepLinkPending ?? this.deepLinkPending),
      existingRole: existingRole ?? this.existingRole,
      chosenRole: chosenRole ?? this.chosenRole,
      faceLoginPassed: faceLoginPassed ?? this.faceLoginPassed,
      faceRequiredAtLogin: faceRequiredAtLogin ?? this.faceRequiredAtLogin,
      hasEnrolledFace: hasEnrolledFace ?? this.hasEnrolledFace,
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
    if (status == AuthSessionStatus.signedOut) {
      ref.read(myApplicationsProvider.notifier).clear();
      ref.invalidate(seekerHomeProfileProvider);
      ref.invalidate(seekerRecommendedJobsProvider);
    }
    state = state.copyWith(status: status);
  }

  void setRole(UserRole role) {
    state = state.copyWith(activeRole: role);
    ref.invalidate(seekerHomeProfileProvider);
    ref.invalidate(seekerRecommendedJobsProvider);
  }

  void setSeekerType(String? seekerType) {
    state = state.copyWith(seekerType: seekerType, seekerTypeLoaded: true);
    ref.invalidate(seekerHomeProfileProvider);
    ref.invalidate(seekerRecommendedJobsProvider);
  }

  void setDeepLinkPending(String? uri) {
    state = state.copyWith(deepLinkPending: uri, clearDeepLink: uri == null);
  }

  void setFaceLoginPassed(bool passed) {
    state = state.copyWith(faceLoginPassed: passed);
  }

  void setFaceRequiredAtLogin(bool required) {
    state = state.copyWith(faceRequiredAtLogin: required);
  }

  void setHasEnrolledFace(bool enrolled) {
    state = state.copyWith(hasEnrolledFace: enrolled);
  }

  void updateSession({
    AuthSessionStatus? status,
    UserRole? role,
    List<UserRole>? assignedRoles,
    String? seekerType,
    bool? seekerTypeLoaded,
    UserRole? existingRole,
    UserRole? chosenRole,
    bool? faceRequiredAtLogin,
    bool? hasEnrolledFace,
  }) {
    if (status == AuthSessionStatus.signedOut) {
      ref.read(myApplicationsProvider.notifier).clear();
      ref.invalidate(seekerHomeProfileProvider);
      ref.invalidate(seekerRecommendedJobsProvider);
    } else if ((role != null && role != state.activeRole) || (seekerType != null && seekerType != state.seekerType)) {
      ref.invalidate(seekerHomeProfileProvider);
      ref.invalidate(seekerRecommendedJobsProvider);
    }
    state = state.copyWith(
      status: status,
      activeRole: role,
      assignedRoles: assignedRoles,
      seekerType: seekerType,
      seekerTypeLoaded: seekerTypeLoaded ?? (seekerType != null || state.seekerTypeLoaded),
      existingRole: existingRole,
      chosenRole: chosenRole,
      faceRequiredAtLogin: faceRequiredAtLogin,
      hasEnrolledFace: hasEnrolledFace,
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
