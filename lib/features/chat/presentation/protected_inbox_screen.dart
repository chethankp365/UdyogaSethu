import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_motion.dart';
import 'package:udyogasethu/core/theme/app_spacing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/features/chat/data/chat_repository.dart';
import 'package:udyogasethu/features/chat/domain/chat_thread.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class _ChatFilterParams {
  final String lifecycle; // 'active', 'completed', 'all'
  final String contextFilter; // 'all', 'job', 'booking', 'order'
  final String role;
  final String query;
  final UserRole userRole;

  const _ChatFilterParams({
    this.lifecycle = 'active',
    this.contextFilter = 'all',
    required this.role,
    required this.query,
    this.userRole = UserRole.seeker,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ChatFilterParams &&
          runtimeType == other.runtimeType &&
          lifecycle == other.lifecycle &&
          contextFilter == other.contextFilter &&
          role == other.role &&
          query == other.query &&
          userRole == other.userRole;

  @override
  int get hashCode => Object.hash(lifecycle, contextFilter, role, query, userRole);
}

final chatThreadsProvider = FutureProvider.family.autoDispose<List<ChatThread>, _ChatFilterParams>((ref, params) async {
  final repo = ref.watch(chatRepositoryProvider);

  try {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      final channel = client
          .channel('realtime_inbox_$uid')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversations',
            callback: (_) => ref.invalidateSelf(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'messages',
            callback: (_) => ref.invalidateSelf(),
          )
          .subscribe();

      ref.onDispose(() {
        client.removeChannel(channel);
      });
    }
  } catch (_) {}

  final allThreads = await repo.getThreads(
    filter: params.lifecycle,
    roleFilter: params.role,
    searchQuery: params.query,
    activeRole: params.userRole,
  );

  List<ChatThread> filtered = allThreads;
  if (params.lifecycle == 'active') {
    filtered = filtered.where((t) => !t.isReadOnly).toList();
  } else if (params.lifecycle == 'completed') {
    filtered = filtered.where((t) => t.isReadOnly).toList();
  }

  if (params.contextFilter != 'all' && ['job', 'booking', 'order'].contains(params.contextFilter)) {
    filtered = filtered.where((t) => t.contextType == params.contextFilter).toList();
  }

  return filtered;
});

final unreadChatCountProvider = Provider.autoDispose<int>((ref) {
  final session = ref.watch(appSessionProvider);
  final defaultParams = _ChatFilterParams(
    lifecycle: 'active',
    contextFilter: 'all',
    role: 'all',
    query: '',
    userRole: session.activeRole,
  );
  final threads = ref.watch(chatThreadsProvider(defaultParams)).asData?.value ?? [];
  return threads.fold<int>(0, (sum, t) => sum + t.unreadCount);
});

class ProtectedInboxScreen extends ConsumerStatefulWidget {
  const ProtectedInboxScreen({super.key});

  @override
  ConsumerState<ProtectedInboxScreen> createState() => _ProtectedInboxScreenState();
}

class _ProtectedInboxScreenState extends ConsumerState<ProtectedInboxScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _lifecycleFilter = 'active'; // 'active' (default) or 'completed'
  String _contextFilter = 'all'; // 'all', 'job', 'booking', 'order'
  final String _roleFilter = 'all'; // 'all', 'worker', 'customer', 'farmer'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeRole = ref.watch(appSessionProvider.select((s) => s.activeRole));
    final filterParams = _ChatFilterParams(
      lifecycle: _lifecycleFilter,
      contextFilter: _contextFilter,
      role: _roleFilter,
      query: _searchQuery,
      userRole: activeRole,
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

                          // Lifecycle Toggle: [Active Chats] | [Completed Jobs]
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildLifecycleToggleItem(
                                    label: l10n?.chatFilterActive ?? 'Active',
                                    icon: Icons.chat_bubble_outline_rounded,
                                    isSelected: _lifecycleFilter == 'active',
                                    onTap: () => setState(() => _lifecycleFilter = 'active'),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildLifecycleToggleItem(
                                    label: l10n?.chatFilterCompleted ?? 'Completed Jobs',
                                    icon: Icons.lock_clock_outlined,
                                    isSelected: _lifecycleFilter == 'completed',
                                    onTap: () => setState(() => _lifecycleFilter = 'completed'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Context Filter Chips (All, Jobs, Bookings, Farm Orders)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: l10n?.chatFilterAll ?? 'All',
                                  isSelected: _contextFilter == 'all',
                                  onTap: () => setState(() => _contextFilter = 'all'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: l10n?.chatFilterJobs ?? 'Jobs',
                                  isSelected: _contextFilter == 'job',
                                  onTap: () => setState(() => _contextFilter = 'job'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: l10n?.chatFilterBookings ?? 'Bookings',
                                  isSelected: _contextFilter == 'booking',
                                  onTap: () => setState(() => _contextFilter = 'booking'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: l10n?.chatFilterOrders ?? 'Farm Orders',
                                  isSelected: _contextFilter == 'order',
                                  onTap: () => setState(() => _contextFilter = 'order'),
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
                            child: FadeSlideEntrance(
                              index: idx,
                              child: _buildThreadCard(context, thread),
                            ),
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

  Widget _buildLifecycleToggleItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.headerGreenDark : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.headerGreenDark : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadCard(BuildContext context, ChatThread thread) {
    final l10n = AppLocalizations.of(context);
    final isReadOnly = thread.isReadOnly;
    final timeStr = _formatTimestamp(thread.lastMessageAt);

    return Dismissible(
      key: ValueKey('thread_${thread.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        await ref.read(chatRepositoryProvider).deleteOrArchiveConversation(thread.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.chatDeletedNotice ?? 'Conversation removed from your inbox.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: BouncingPressable(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
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
                // Top Row: Avatar, Name, Role Tag, Time & Status
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
                              if (thread.id.startsWith('cccccccc-'))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF93C5FD)),
                                  ),
                                  child: const Text(
                                    'Demo mode',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
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
      case 'seeker':
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
      case 'provider':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF5B21B6);
        label = 'Employer';
        break;
      case 'buyer':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        label = 'Buyer';
        break;
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
        border: Border.all(
          color: isReadOnly ? const Color(0xFFCBD5E1) : const Color(0xFF86EFAC),
          width: 0.5,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReadOnly) ...[
              const Icon(Icons.lock_rounded, size: 10, color: Color(0xFF64748B)),
              const SizedBox(width: 3),
            ],
            Text(
              isReadOnly ? 'Ended' : 'Active',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isReadOnly ? const Color(0xFF64748B) : const Color(0xFF15803D),
              ),
            ),
          ],
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
