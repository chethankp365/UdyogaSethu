import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/mic_fab.dart';
import 'package:udyogasethu/features/chat/presentation/protected_inbox_screen.dart';
import 'package:udyogasethu/features/voice/presentation/voice_assistant_modal.dart';

class RoleBottomNavBar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final UserRole role;

  const RoleBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.role,
  });

  void _showMicBottomSheet(BuildContext context) {
    VoiceAssistantModal.show(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.navyCard : Colors.white;
    final activeColor = isDark ? AppColors.emerald : AppColors.primaryTeal;
    final inactiveColor = AppColors.textMuted;

    final unreadChats = ref.watch(unreadChatCountProvider);
    final tabItems = _getTabItems(role);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab 0
              _NavBarItem(
                icon: tabItems[0].icon,
                label: tabItems[0].label,
                isSelected: selectedIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => onTabSelected(0),
              ),

              // Tab 1
              _NavBarItem(
                icon: tabItems[1].icon,
                label: tabItems[1].label,
                isSelected: selectedIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => onTabSelected(1),
              ),

              // Center Raised Circular Mic Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: MicFab(
                  onTap: () => _showMicBottomSheet(context),
                ),
              ),

              // Tab 2 (Chat) with unread badge
              _NavBarItem(
                icon: tabItems[2].icon,
                label: tabItems[2].label,
                isSelected: selectedIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                badgeCount: unreadChats,
                onTap: () => onTabSelected(2),
              ),

              // Tab 3
              _NavBarItem(
                icon: tabItems[3].icon,
                label: tabItems[3].label,
                isSelected: selectedIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_TabConfig> _getTabItems(UserRole role) {
    switch (role) {
      case UserRole.seeker:
        return const [
          _TabConfig(Icons.home_rounded, 'Home'),
          _TabConfig(Icons.work_rounded, 'Jobs'),
          _TabConfig(Icons.chat_bubble_rounded, 'Chat'),
          _TabConfig(Icons.person_rounded, 'Profile'),
        ];
      case UserRole.provider:
        return const [
          _TabConfig(Icons.home_rounded, 'Home'),
          _TabConfig(Icons.people_alt_rounded, 'Workers'),
          _TabConfig(Icons.chat_bubble_rounded, 'Chat'),
          _TabConfig(Icons.person_rounded, 'Profile'),
        ];
      case UserRole.farmer:
        return const [
          _TabConfig(Icons.home_rounded, 'Home'),
          _TabConfig(Icons.storefront_rounded, 'Market'),
          _TabConfig(Icons.chat_bubble_rounded, 'Chat'),
          _TabConfig(Icons.person_rounded, 'Profile'),
        ];
    }
  }
}

class _TabConfig {
  final IconData icon;
  final String label;

  const _TabConfig(this.icon, this.label);
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
