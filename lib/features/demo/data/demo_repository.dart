import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';
import 'package:udyogasethu/features/auth/data/auth_repository.dart';
import 'package:udyogasethu/features/demo/domain/demo_scenario.dart';
import 'package:udyogasethu/features/onboarding/data/bootstrap_service.dart';

/// Seeded demo account model for quick evaluator authentication.
class DemoAccount {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String description;
  final String headline;
  final double rating;
  final bool isVerified;

  const DemoAccount({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.description,
    required this.headline,
    required this.rating,
    required this.isVerified,
  });
}

class DemoState {
  final String? activeScenarioId;
  final int currentStepIndex;
  final Set<String> completedScenarioIds;
  final bool isResetting;

  const DemoState({
    this.activeScenarioId,
    this.currentStepIndex = 0,
    this.completedScenarioIds = const {},
    this.isResetting = false,
  });

  DemoScenario? get activeScenario {
    if (activeScenarioId == null) return null;
    try {
      return DemoScenariosCatalog.scenarios.firstWhere((s) => s.id == activeScenarioId);
    } catch (_) {
      return null;
    }
  }

  DemoStep? get currentStep {
    final scenario = activeScenario;
    if (scenario == null) return null;
    if (currentStepIndex >= 0 && currentStepIndex < scenario.steps.length) {
      return scenario.steps[currentStepIndex];
    }
    return null;
  }

  DemoState copyWith({
    String? activeScenarioId,
    bool clearActiveScenario = false,
    int? currentStepIndex,
    Set<String>? completedScenarioIds,
    bool? isResetting,
  }) {
    return DemoState(
      activeScenarioId: clearActiveScenario ? null : (activeScenarioId ?? this.activeScenarioId),
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedScenarioIds: completedScenarioIds ?? this.completedScenarioIds,
      isResetting: isResetting ?? this.isResetting,
    );
  }
}

class DemoRepository {
  final SupabaseClient _supabase;
  final AuthRepository _authRepo;
  final Ref _ref;

  static const String _completedKey = 'udyoga_demo_completed_scenarios';

  DemoRepository(this._supabase, this._authRepo, this._ref);

  static const List<DemoAccount> accounts = [
    // Seekers
    DemoAccount(
      id: '22222222-2222-4222-8222-222222222201',
      name: 'Ramesh Kumar',
      phone: '+919900000101',
      email: 'ramesh@test.com',
      role: 'seeker',
      headline: 'Skilled Construction & Masonry Helper',
      description: '10+ years experience, DigiLocker Aadhaar eKYC verified, 18 completed jobs.',
      rating: 4.9,
      isVerified: true,
    ),
    DemoAccount(
      id: '22222222-2222-4222-8222-222222222202',
      name: 'Sunita Devi',
      phone: '+919900000102',
      email: 'sunita@test.com',
      role: 'seeker',
      headline: 'Experienced Domestic Help & House Cleaner',
      description: 'Punctual, thorough domestic helper trusted by Jayanagar families.',
      rating: 4.8,
      isVerified: true,
    ),
    DemoAccount(
      id: '22222222-2222-4222-8222-222222222206',
      name: 'Syed Imran',
      phone: '+919900000106',
      email: 'syed@test.com',
      role: 'seeker',
      headline: 'Professional Light Vehicle & Commercial Driver',
      description: 'Aadhaar + Commercial DL verified, available for inter-city & logistics.',
      rating: 4.9,
      isVerified: true,
    ),

    // Providers
    DemoAccount(
      id: '33333333-3333-4333-8333-333333333301',
      name: 'Dr. Anand Sharma',
      phone: '+919900000201',
      email: 'anand@test.com',
      role: 'provider',
      headline: 'Household Employer · Jayanagar 4th Block',
      description: 'Regular household client hiring plumbing, electrical and maintenance workers.',
      rating: 4.9,
      isVerified: true,
    ),
    DemoAccount(
      id: '33333333-3333-4333-8333-333333333302',
      name: 'Meera Reddy',
      phone: '+919900000202',
      email: 'meera@test.com',
      role: 'provider',
      headline: 'Apartment Group Leader · Koramangala 5th Block',
      description: 'Coordinates bulk farm produce group orders for 40 apartment families.',
      rating: 4.8,
      isVerified: true,
    ),
    DemoAccount(
      id: '33333333-3333-4333-8333-333333333303',
      name: 'Suresh Sai',
      phone: '+919900000203',
      email: 'suresh@test.com',
      role: 'provider',
      headline: 'Commercial Contractor · Sai Electricals & Builders',
      description: 'Hires skilled trade workers for commercial and residential construction projects.',
      rating: 4.9,
      isVerified: true,
    ),

    // Farmers
    DemoAccount(
      id: '44444444-4444-4444-8444-444444444401',
      name: 'Gowda Farmer',
      phone: '+919900000301',
      email: 'gowda@test.com',
      role: 'farmer',
      headline: 'Organic Smallholder · Devanahalli Farm Sector',
      description: '8 acres organic farm growing Fresh Tomatoes, Mangoes and Green Vegetables.',
      rating: 4.9,
      isVerified: true,
    ),
    DemoAccount(
      id: '44444444-4444-4444-8444-444444444402',
      name: 'Venkatesh K',
      phone: '+919900000302',
      email: 'venkatesh@test.com',
      role: 'farmer',
      headline: 'Dairy & Orchard Farmer · Yelahanka Dairy Circle',
      description: '5 acres farm supplying pure A2 Desi cow milk and sweet tender coconuts.',
      rating: 4.8,
      isVerified: true,
    ),

    // Admin (Reference / Trust demonstration)
    DemoAccount(
      id: '11111111-1111-4111-8111-111111111111',
      name: 'System Admin',
      phone: '+919900000001',
      email: 'admin@udyogasethu.org',
      role: 'admin',
      headline: 'Platform Safety & Trust Operator',
      description: 'Demonstrates admin-facing review status and governance policies.',
      rating: 5.0,
      isVerified: true,
    ),
  ];

  Future<Set<String>> loadCompletedScenarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_completedKey) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> markScenarioCompleted(String scenarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = (prefs.getStringList(_completedKey) ?? []).toSet();
      set.add(scenarioId);
      await prefs.setStringList(_completedKey, set.toList());
    } catch (_) {}
  }

  /// Authenticate evaluator cleanly as one of the seeded demo accounts.
  Future<bool> signInAsDemoAccount(DemoAccount account) async {
    if (!Env.isDemoBuild) {
      throw const AppException.auth('Demo login is strictly disabled in production release builds.');
    }

    try {
      final response = await _authRepo.signInWithDemoCredentials(
        account.email,
        'Password123!',
      );

      if (response.session != null) {
        try {
          await _ref.read(bootstrapProvider.notifier).runBootstrap();
        } catch (_) {}
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('Demo sign in failed: $e');
      rethrow;
    }
  }

  /// Calls server-authoritative reset_demo RPC with authorized confirmation token.
  Future<bool> resetDemo() async {
    if (!Env.isDemoBuild) {
      throw const AppException.auth('Demo reset is strictly disabled in production release builds.');
    }

    try {
      final res = await _supabase.rpc('reset_demo', params: {
        'p_confirmation_code': 'DEMO_RESET_UDYOGASETHU_2026',
      });
      AppLogger.i('reset_demo RPC succeeded: $res');
      return true;
    } catch (e) {
      AppLogger.w('reset_demo RPC error (falling back to local demo state reset): $e');
      // If RPC is unavailable or offline, still reset local completed tracking
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_completedKey);
      return true;
    }
  }
}

class DemoNotifier extends Notifier<DemoState> {
  @override
  DemoState build() {
    _loadInitial();
    return const DemoState();
  }

  Future<void> _loadInitial() async {
    final repo = ref.read(demoRepositoryProvider);
    final completed = await repo.loadCompletedScenarios();
    state = state.copyWith(completedScenarioIds: completed);
  }

  void startScenario(String scenarioId) {
    state = state.copyWith(
      activeScenarioId: scenarioId,
      currentStepIndex: 0,
    );
  }

  void nextStep() {
    final scenario = state.activeScenario;
    if (scenario == null) return;
    if (state.currentStepIndex < scenario.steps.length - 1) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    } else {
      // Completed all steps
      completeScenario();
    }
  }

  void previousStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex - 1);
    }
  }

  Future<void> completeScenario() async {
    final scenarioId = state.activeScenarioId;
    if (scenarioId == null) return;

    final updated = Set<String>.from(state.completedScenarioIds)..add(scenarioId);
    state = state.copyWith(
      completedScenarioIds: updated,
      clearActiveScenario: true,
      currentStepIndex: 0,
    );

    final repo = ref.read(demoRepositoryProvider);
    await repo.markScenarioCompleted(scenarioId);
  }

  void exitScenario() {
    state = state.copyWith(
      clearActiveScenario: true,
      currentStepIndex: 0,
    );
  }

  Future<bool> resetAllDemoState() async {
    state = state.copyWith(isResetting: true);
    final repo = ref.read(demoRepositoryProvider);
    final success = await repo.resetDemo();

    state = const DemoState();
    return success;
  }
}

final demoRepositoryProvider = Provider<DemoRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return DemoRepository(client, authRepo, ref);
});

final demoNotifierProvider = NotifierProvider<DemoNotifier, DemoState>(DemoNotifier.new);
