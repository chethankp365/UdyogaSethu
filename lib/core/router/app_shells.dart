import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/core/widgets/role_bottom_nav_bar.dart';

/// Shell for Job Seeker role (Home, Jobs, Mic, Chat, Profile).
class SeekerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const SeekerShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: RoleBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onTabSelected: (index) => _onTabTapped(context, index),
        role: UserRole.seeker,
      ),
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Shell for Job Provider role (Home, Workers, Mic, Chat, Profile).
class ProviderShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ProviderShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: RoleBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onTabSelected: (index) => _onTabTapped(context, index),
        role: UserRole.provider,
      ),
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Shell for Farmer role (Home, Market, Mic, Chat, Profile).
class FarmerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const FarmerShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: RoleBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onTabSelected: (index) => _onTabTapped(context, index),
        role: UserRole.farmer,
      ),
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Shell for Admin role (NavigationRail on wide screens width >= 600, Drawer + BottomBar on phones).
class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isWideScreen = mediaQuery.size.width >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isWideScreen) {
      // Wide screens: NavigationRail layout
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onTabTapped(context, index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: isDark ? AppColors.navyCard : Colors.white,
              selectedIconTheme: const IconThemeData(color: AppColors.primaryTeal),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircleAvatar(
                  backgroundColor: AppColors.headerGreenDark,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.verified_user_outlined),
                  selectedIcon: Icon(Icons.verified_user_rounded),
                  label: Text('Verification'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.gavel_outlined),
                  selectedIcon: Icon(Icons.gavel_rounded),
                  label: Text('Disputes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: Text('Analytics'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // Phone screens: Drawer + BottomBar layout
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.headerGreenDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, color: AppColors.headerGreenDark),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'UdyogaSethu Admin Console',
                    style: AppTypography.titleMedium(Colors.white),
                  ),
                  Text(
                    'Operations & Governance',
                    style: AppTypography.bodySmall(Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Dashboard'),
              selected: navigationShell.currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                _onTabTapped(context, 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_rounded),
              title: const Text('Verification Queue'),
              selected: navigationShell.currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                _onTabTapped(context, 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: const Text('Disputes'),
              selected: navigationShell.currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                _onTabTapped(context, 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text('Analytics & Impact'),
              selected: navigationShell.currentIndex == 3,
              onTap: () {
                Navigator.pop(context);
                _onTabTapped(context, 3);
              },
            ),
          ],
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: RoleBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onTabSelected: (index) => _onTabTapped(context, index),
        role: UserRole.admin,
      ),
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
