import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/features/demo/data/demo_repository.dart';

/// Screen displaying seeded test accounts for quick evaluator sign-in (P10.1).
/// Gated strictly to demo builds; never available in release flavour.
class DemoAccountsScreen extends ConsumerStatefulWidget {
  const DemoAccountsScreen({super.key});

  @override
  ConsumerState<DemoAccountsScreen> createState() => _DemoAccountsScreenState();
}

class _DemoAccountsScreenState extends ConsumerState<DemoAccountsScreen> {
  String? _signingInAccountId;
  String? _errorMessage;

  Future<void> _handleSignIn(DemoAccount account) async {
    setState(() {
      _signingInAccountId = account.id;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(demoRepositoryProvider);
      final success = await repo.signInAsDemoAccount(account);
      if (success && mounted) {
        context.go(AppRoutes.splash);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Could not sign in with demo credentials.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Demo sign-in error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _signingInAccountId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = DemoRepository.accounts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Demo Accounts (Evaluator)'),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade400,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'DEMO BUILD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Evaluator Notice: These are seeded Supabase test accounts with preset passwords (Password123!). Tapping sign-in generates genuine authenticated sessions with RLS enforced.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Role Sections
            _buildRoleSection(context, 'WORKERS & SEEKERS', accounts.where((a) => a.role == 'seeker').toList()),
            const SizedBox(height: 16),
            _buildRoleSection(context, 'EMPLOYERS & PROVIDERS', accounts.where((a) => a.role == 'provider').toList()),
            const SizedBox(height: 16),
            _buildRoleSection(context, 'FARMERS & PRODUCERS', accounts.where((a) => a.role == 'farmer').toList()),
            const SizedBox(height: 16),
            _buildRoleSection(context, 'ADMIN & OPERATORS', accounts.where((a) => a.role == 'admin').toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSection(BuildContext context, String title, List<DemoAccount> roleAccounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.label(AppColors.textMuted).copyWith(
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        ...roleAccounts.map((account) {
          final isSigningIn = _signingInAccountId == account.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getRoleColor(account.role).withValues(alpha: 0.15),
                        child: Text(
                          account.name.isNotEmpty ? account.name[0] : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(account.role),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    account.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (account.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: AppColors.primaryTeal, size: 16),
                                ],
                              ],
                            ),
                            Text(
                              account.phone,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getRoleColor(account.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          account.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(account.role),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    account.headline,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.description,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: isSigningIn ? null : () => _handleSignIn(account),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getRoleColor(account.role),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: isSigningIn
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login_rounded, size: 16),
                      label: Text(
                        isSigningIn ? 'Signing in...' : 'Sign in as ${account.name.split(' ').first}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'seeker':
        return const Color(0xFF0F766E);
      case 'provider':
        return const Color(0xFF1D4ED8);
      case 'farmer':
        return const Color(0xFF15803D);
      case 'admin':
        return const Color(0xFFB45309);
      default:
        return AppColors.headerGreenDark;
    }
  }
}
