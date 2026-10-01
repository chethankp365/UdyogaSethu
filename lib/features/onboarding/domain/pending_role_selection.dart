import 'package:udyogasethu/core/router/app_session.dart';

/// Enum representing specific types of Job Seekers.
enum SeekerType {
  informal,
  student,
  partTime,
}

/// Domain model representing a user's role choice before authentication.
/// Persisted locally until account creation / DB sync in P2.6.
class PendingRoleSelection {
  final UserRole role;
  final SeekerType? seekerType;

  const PendingRoleSelection({
    required this.role,
    this.seekerType,
  });

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'seekerType': seekerType?.name,
      };

  factory PendingRoleSelection.fromJson(Map<String, dynamic> json) {
    return PendingRoleSelection(
      role: UserRole.values.byName(json['role'] as String),
      seekerType: json['seekerType'] != null
          ? SeekerType.values.byName(json['seekerType'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingRoleSelection &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          seekerType == other.seekerType;

  @override
  int get hashCode => role.hashCode ^ seekerType.hashCode;

  @override
  String toString() =>
      'PendingRoleSelection(role: ${role.name}, seekerType: ${seekerType?.name})';
}
