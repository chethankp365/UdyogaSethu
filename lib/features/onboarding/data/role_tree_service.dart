import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/features/onboarding/domain/pending_role_selection.dart';

const String kPendingRolePrefsKey = 'pending_role_selection';

/// State snapshot for the guided role decision tree.
class RoleTreeState {
  final int currentStep;
  final String? selectedCategory; // 'worker' or 'farmer'
  final UserRole? selectedRole; // seeker, provider, farmer
  final SeekerType? selectedSeekerType; // informal, student, partTime
  final PendingRoleSelection? completedSelection;

  const RoleTreeState({
    this.currentStep = 1,
    this.selectedCategory,
    this.selectedRole,
    this.selectedSeekerType,
    this.completedSelection,
  });

  RoleTreeState copyWith({
    int? currentStep,
    String? selectedCategory,
    UserRole? selectedRole,
    SeekerType? selectedSeekerType,
    PendingRoleSelection? completedSelection,
    bool clearCategory = false,
    bool clearRole = false,
    bool clearSeekerType = false,
    bool clearCompletedSelection = false,
  }) {
    return RoleTreeState(
      currentStep: currentStep ?? this.currentStep,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedRole: clearRole ? null : (selectedRole ?? this.selectedRole),
      selectedSeekerType: clearSeekerType
          ? null
          : (selectedSeekerType ?? this.selectedSeekerType),
      completedSelection: clearCompletedSelection
          ? null
          : (completedSelection ?? this.completedSelection),
    );
  }

  bool get canContinue {
    if (currentStep == 1) {
      return selectedCategory != null;
    } else if (currentStep == 2) {
      return selectedRole != null;
    } else if (currentStep == 3) {
      return selectedSeekerType != null;
    }
    return false;
  }
}

/// Riverpod Notifier managing guided role selection tree state and persistence.
class RoleTreeNotifier extends Notifier<RoleTreeState> {
  @override
  RoleTreeState build() {
    _loadFromPrefs();
    return const RoleTreeState();
  }

  RoleTreeState get currentState => state;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(kPendingRolePrefsKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(rawJson);
        final selection = PendingRoleSelection.fromJson(data);
        if (selection.role == UserRole.farmer) {
          state = RoleTreeState(
            currentStep: 1,
            selectedCategory: 'farmer',
            selectedRole: UserRole.farmer,
            completedSelection: selection,
          );
        } else if (selection.role == UserRole.provider) {
          state = RoleTreeState(
            currentStep: 2,
            selectedCategory: 'worker',
            selectedRole: UserRole.provider,
            completedSelection: selection,
          );
        } else if (selection.role == UserRole.seeker) {
          state = RoleTreeState(
            currentStep: selection.seekerType != null ? 3 : 2,
            selectedCategory: 'worker',
            selectedRole: UserRole.seeker,
            selectedSeekerType: selection.seekerType,
            completedSelection: selection.seekerType != null ? selection : null,
          );
        }
      }
    } catch (_) {
      // Ignore prefs read errors
    }
  }

  Future<void> _saveToPrefs(PendingRoleSelection? selection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (selection != null) {
        await prefs.setString(kPendingRolePrefsKey, json.encode(selection.toJson()));
      } else {
        await prefs.remove(kPendingRolePrefsKey);
      }
    } catch (_) {
      // Ignore prefs write errors
    }
  }

  /// Step 1: Select Category ('worker' or 'farmer')
  void selectCategory(String category) {
    if (category == 'farmer') {
      final selection = const PendingRoleSelection(role: UserRole.farmer);
      state = state.copyWith(
        currentStep: 1,
        selectedCategory: 'farmer',
        selectedRole: UserRole.farmer,
        clearSeekerType: true,
        completedSelection: selection,
      );
      _saveToPrefs(selection);
    } else {
      // worker selected
      state = RoleTreeState(
        currentStep: state.selectedCategory == 'worker' ? state.currentStep : 1,
        selectedCategory: 'worker',
        selectedRole: state.selectedCategory == 'worker' ? state.selectedRole : null,
        selectedSeekerType:
            state.selectedCategory == 'worker' ? state.selectedSeekerType : null,
        completedSelection: null,
      );
      _saveToPrefs(null);
    }
  }

  /// Move from Step 1 to Step 2 if Worker is chosen
  void confirmStep1() {
    if (state.selectedCategory == 'worker') {
      state = state.copyWith(currentStep: 2);
    }
  }

  /// Step 2: Select Role ('seeker' or 'provider')
  void selectRole(UserRole role) {
    if (role == UserRole.provider) {
      final selection = const PendingRoleSelection(role: UserRole.provider);
      state = state.copyWith(
        currentStep: 2,
        selectedCategory: 'worker',
        selectedRole: UserRole.provider,
        clearSeekerType: true,
        completedSelection: selection,
      );
      _saveToPrefs(selection);
    } else if (role == UserRole.seeker) {
      state = state.copyWith(
        currentStep: 2,
        selectedCategory: 'worker',
        selectedRole: UserRole.seeker,
        clearCompletedSelection: true,
      );
      _saveToPrefs(null);
    }
  }

  /// Move from Step 2 to Step 3 if Seeker is chosen
  void confirmStep2() {
    if (state.selectedRole == UserRole.seeker) {
      state = state.copyWith(currentStep: 3);
    }
  }

  /// Step 3: Select SeekerType ('informal', 'student', 'partTime')
  void selectSeekerType(SeekerType type) {
    final selection = PendingRoleSelection(role: UserRole.seeker, seekerType: type);
    state = state.copyWith(
      currentStep: 3,
      selectedCategory: 'worker',
      selectedRole: UserRole.seeker,
      selectedSeekerType: type,
      completedSelection: selection,
    );
    _saveToPrefs(selection);
  }

  /// Navigate back 1 step in the decision tree
  bool goBack() {
    if (state.currentStep == 3) {
      state = state.copyWith(
        currentStep: 2,
        clearSeekerType: true,
        clearCompletedSelection: true,
      );
      _saveToPrefs(null);
      return true;
    } else if (state.currentStep == 2) {
      state = state.copyWith(
        currentStep: 1,
        clearRole: true,
        clearSeekerType: true,
        clearCompletedSelection: true,
      );
      _saveToPrefs(null);
      return true;
    }
    return false; // Already at step 1
  }

  /// Resets the decision tree to step 1
  Future<void> reset() async {
    state = const RoleTreeState();
    await _saveToPrefs(null);
  }
}

final roleTreeProvider =
    NotifierProvider<RoleTreeNotifier, RoleTreeState>(RoleTreeNotifier.new);
