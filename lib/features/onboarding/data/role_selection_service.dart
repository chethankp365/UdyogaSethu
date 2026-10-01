import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';

/// Key for storing pending role selection in SharedPreferences.
const String kPendingRoleSelectionKey = 'pending_role_selection';

/// Data model representing local onboarding decision tree state.
class PendingRoleSelection {
  final String? primaryRole; // 'worker' | 'farmer'
  final String? secondaryRole; // 'seeker' | 'provider'
  final String? seekerType; // 'informal' | 'student' | 'part_time'
  final int currentStep; // 1, 2, 3

  const PendingRoleSelection({
    this.primaryRole,
    this.secondaryRole,
    this.seekerType,
    this.currentStep = 1,
  });

  /// Resolves final role name for authentication/profile creation:
  /// - farmer -> 'farmer'
  /// - provider -> 'provider'
  /// - seeker -> 'seeker'
  String? get resolvedRole {
    if (primaryRole == 'farmer') return 'farmer';
    if (primaryRole == 'worker' && secondaryRole == 'provider') return 'provider';
    if (primaryRole == 'worker' && secondaryRole == 'seeker') return 'seeker';
    return null;
  }

  /// Whether current step has a valid selection made.
  bool get hasSelectionForCurrentStep {
    if (currentStep == 1) {
      return primaryRole != null;
    }
    if (currentStep == 2) {
      return secondaryRole != null;
    }
    if (currentStep == 3) {
      return seekerType != null;
    }
    return false;
  }

  /// Whether full tree selection is completed.
  bool get isComplete {
    if (primaryRole == 'farmer') return true;
    if (primaryRole == 'worker' && secondaryRole == 'provider') return true;
    if (primaryRole == 'worker' && secondaryRole == 'seeker' && seekerType != null) return true;
    return false;
  }

  Map<String, dynamic> toJson() => {
        'primaryRole': primaryRole,
        'secondaryRole': secondaryRole,
        'seekerType': seekerType,
        'currentStep': currentStep,
      };

  factory PendingRoleSelection.fromJson(Map<String, dynamic> json) => PendingRoleSelection(
        primaryRole: json['primaryRole'] as String?,
        secondaryRole: json['secondaryRole'] as String?,
        seekerType: json['seekerType'] as String?,
        currentStep: (json['currentStep'] as num?)?.toInt() ?? 1,
      );

  PendingRoleSelection copyWith({
    String? primaryRole,
    String? secondaryRole,
    String? seekerType,
    int? currentStep,
    bool clearSecondary = false,
    bool clearSeekerType = false,
  }) {
    return PendingRoleSelection(
      primaryRole: primaryRole ?? this.primaryRole,
      secondaryRole: clearSecondary ? null : (secondaryRole ?? this.secondaryRole),
      seekerType: clearSeekerType ? null : (seekerType ?? this.seekerType),
      currentStep: currentStep ?? this.currentStep,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingRoleSelection &&
          runtimeType == other.runtimeType &&
          primaryRole == other.primaryRole &&
          secondaryRole == other.secondaryRole &&
          seekerType == other.seekerType &&
          currentStep == other.currentStep;

  @override
  int get hashCode =>
      primaryRole.hashCode ^ secondaryRole.hashCode ^ seekerType.hashCode ^ currentStep.hashCode;
}

/// Notifier that manages the decision tree state and persists it to SharedPreferences.
class RoleSelectionNotifier extends Notifier<PendingRoleSelection> {
  @override
  PendingRoleSelection build() {
    _loadFromPrefs();
    return const PendingRoleSelection();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(kPendingRoleSelectionKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = PendingRoleSelection.fromJson(map);
      }
    } catch (e, st) {
      AppLogger.e('Failed to load pending role selection from prefs', e, st);
    }
  }

  Future<void> _saveToPrefs(PendingRoleSelection newState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(newState.toJson());
      await prefs.setString(kPendingRoleSelectionKey, jsonStr);
    } catch (e, st) {
      AppLogger.e('Failed to save pending role selection to prefs', e, st);
    }
  }

  /// Select primary role in Step 1.
  /// If changed from worker -> farmer or vice versa, clears secondaryRole and seekerType.
  void selectPrimaryRole(String role) {
    if (state.primaryRole == role) return;

    final newState = state.copyWith(
      primaryRole: role,
      clearSecondary: true,
      clearSeekerType: true,
      currentStep: 1,
    );
    state = newState;
    _saveToPrefs(newState);
  }

  /// Select secondary role in Step 2.
  /// If changed from seeker -> provider, clears seekerType.
  void selectSecondaryRole(String role) {
    if (state.secondaryRole == role) return;

    final newState = state.copyWith(
      secondaryRole: role,
      clearSeekerType: true,
      currentStep: 2,
    );
    state = newState;
    _saveToPrefs(newState);
  }

  /// Select seeker type in Step 3.
  void selectSeekerType(String seekerType) {
    final newState = state.copyWith(
      seekerType: seekerType,
      currentStep: 3,
    );
    state = newState;
    _saveToPrefs(newState);
  }

  /// Advance to next step (or complete).
  /// Step 1 Worker -> Step 2.
  /// Step 2 Seeker -> Step 3.
  /// Step 1 Farmer / Step 2 Provider / Step 3 Seeker -> returns true indicating tree is complete.
  bool advanceStep() {
    if (state.primaryRole == 'farmer') {
      return true; // Complete, go to login
    }
    if (state.currentStep == 1 && state.primaryRole == 'worker') {
      final newState = state.copyWith(currentStep: 2);
      state = newState;
      _saveToPrefs(newState);
      return false;
    }
    if (state.currentStep == 2) {
      if (state.secondaryRole == 'provider') {
        return true; // Complete, go to login
      } else if (state.secondaryRole == 'seeker') {
        final newState = state.copyWith(currentStep: 3);
        state = newState;
        _saveToPrefs(newState);
        return false;
      }
    }
    if (state.currentStep == 3 && state.seekerType != null) {
      return true; // Complete, go to login
    }
    return false;
  }

  /// Go back one step in the decision tree.
  void goBackStep() {
    if (state.currentStep > 1) {
      final newStep = state.currentStep - 1;
      final newState = state.copyWith(currentStep: newStep);
      state = newState;
      _saveToPrefs(newState);
    }
  }

  /// Reset/clear pending role selection (e.g. after database persistence in P2.6).
  Future<void> clearPendingSelection() async {
    state = const PendingRoleSelection();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kPendingRoleSelectionKey);
    } catch (e, st) {
      AppLogger.e('Failed to clear pending role selection from prefs', e, st);
    }
  }
}

/// Provider for managing pending role selection tree state.
final roleSelectionProvider =
    NotifierProvider<RoleSelectionNotifier, PendingRoleSelection>(RoleSelectionNotifier.new);
