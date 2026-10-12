import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:udyogasethu/features/chat/data/chat_repository.dart';
import 'package:udyogasethu/features/chat/domain/chat_thread.dart';

class _ChatFilterParams {
  final String status;
  final String role;
  final String query;

  const _ChatFilterParams({
    required this.status,
    required this.role,
    required this.query,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ChatFilterParams &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          role == other.role &&
          query == other.query;

  @override
  int get hashCode => Object.hash(status, role, query);
}

final chatThreadsProvider = FutureProvider.family.autoDispose<List<ChatThread>, _ChatFilterParams>((ref, params) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getThreads(
    filter: params.status,
    roleFilter: params.role,
    searchQuery: params.query,
  );
});

class ProtectedInboxScreen extends ConsumerStatefulWidget {
  const ProtectedInboxScreen({super.key});

  @override
  ConsumerState<ProtectedInboxScreen> createState() => _ProtectedInboxScreenState();
}

class _ProtectedInboxScreenState extends ConsumerState<ProtectedInboxScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'all'; // 'all', 'active', 'completed'
  String _roleFilter = 'all'; // 'all', 'worker', 'customer', 'farmer'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterParams = _ChatFilterParams(
      status: _statusFilter,
      role: _roleFilter,
      query: _searchQuery,
    );
    final threadsAsync = ref.watch(chatThreadsProvider(filterParams));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(chatThreadsProvider(filterParams).future),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              // 1. ESCROW NETWORK HEADER & SEARCH & FILTERS
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInboxHeader(context),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search person, crop, job, booking ID...',
                              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.headerGreenDark),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Privacy Safety Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.privacy_tip_rounded, size: 16, color: Color(0xFFB45309)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Phone and payment handles are masked for your privacy.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Filter Chips (All, Active, Completed)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'All',
                                  isSelected: _statusFilter == 'all',
                                  onTap: () => setState(() => _statusFilter = 'all'),
                                ),
                                const SizedBox(width: 6),
                                _buildFilterChip(
                                  label: 'Active',
                                  isSelected: _statusFilter == 'active',
                                  onTap: () => setState(() => _statusFilter = 'active'),
                                ),
                                const SizedBox(width: 6),
                                _buildFilterChip(
                                  label: 'Completed',
                                  isSelected: _statusFilter == 'completed',
                                  onTap: () => setState(() => _statusFilter = 'completed'),
                                ),
                                const SizedBox(width: 12),
                                Container(width: 1, height: 20, color: Colors.grey.shade300),
                                const SizedBox(width: 12),
                                _buildFilterChip(
                                  label: 'Worker Chats',
                                  isSelected: _roleFilter == 'worker',
                                  onTap: () => setState(() =>
                                      _roleFilter = _roleFilter == 'worker' ? 'all' : 'worker'),
                                ),
                                const SizedBox(width: 6),
                                _buildFilterChip(
                                  label: 'Customer Chats',
                                  isSelected: _roleFilter == 'customer',
                                  onTap: () => setState(() =>
                                      _roleFilter = _roleFilter == 'customer' ? 'all' : 'customer'),
                                ),
                                const SizedBox(width: 6),
                                _buildFilterChip(
                                  label: 'Farmer Chats',
                                  isSelected: _roleFilter == 'farmer',
                                  onTap: () => setState(() =>
                                      _roleFilter = _roleFilter == 'farmer' ? 'all' : 'farmer'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  ],
                ),
              ),

              // 2. THREAD LIST SLIVER
              threadsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.headerGreenDark),
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text('Failed to load conversations: $err', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(chatThreadsProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (threads) {
                  if (threads.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mark_chat_read_outlined, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'No Conversations Found',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Protected chats open automatically when jobs are booked or orders placed.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, AppSpacing.fabBottomPadding),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final thread = threads[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildThreadCard(context, thread),
                          );
                        },
                        childCount: threads.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInboxHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.headerGreenDark, AppColors.headerGreenGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protected Inbox',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Communicating via Secure Escrow Network',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'MASKED',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.headerGreenDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.headerGreenDark : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildThreadCard(BuildContext context, ChatThread thread) {
    final isReadOnly = thread.isReadOnly;
    final timeStr = _formatTimestamp(thread.lastMessageAt);

    return InkWell(
      onTap: () {
        context.push('${AppRoutes.chatDetail}/${thread.id}');
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: thread.unreadCount > 0 ? AppColors.headerGreenDark.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
            width: thread.unreadCount > 0 ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Role Tag, Time
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.paleMint,
                  child: Text(
                    thread.otherPartyName.isNotEmpty ? thread.otherPartyName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            thread.otherPartyName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          _buildRoleTag(thread.otherPartyRole),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        thread.subject,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headerGreenDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusChip(isReadOnly),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Middle Row: Booking Code & Last Message Snippet
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    thread.bookingCode,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thread.lastMessageSnippet ?? 'No messages yet',
                    style: TextStyle(
                      fontSize: 12,
                      color: thread.unreadCount > 0 ? AppColors.textDark : AppColors.textMuted,
                      fontWeight: thread.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (thread.unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.accentOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${thread.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTag(String role) {
    Color bg;
    Color fg;
    String label;

    switch (role.toLowerCase()) {
      case 'worker':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        label = 'Worker';
        break;
      case 'farmer':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Farmer';
        break;
      case 'employer':
      case 'customer':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'Customer';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isReadOnly) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isReadOnly ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          isReadOnly ? 'Read-only' : 'Active',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isReadOnly ? const Color(0xFF64748B) : const Color(0xFF15803D),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }
}
