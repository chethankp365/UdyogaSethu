import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/app_session.dart';
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


