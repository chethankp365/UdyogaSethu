import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder router configuration for initial app scaffolding.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderHomeScreen(),
    ),
  ],
);

/// Placeholder home screen shown when environment is properly configured.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UdyogaSethu'),
        backgroundColor: const Color(0xFF0D6548),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 72,
                color: Color(0xFF00875A),
              ),
              SizedBox(height: 16),
              Text(
                'UdyogaSethu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D6548),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Bridging Work. Empowering Lives.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Chip(
                label: Text('Foundation Scaffold Ready'),
                backgroundColor: Color(0xFFE6F4EA),
                side: BorderSide(color: Color(0xFF00875A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
