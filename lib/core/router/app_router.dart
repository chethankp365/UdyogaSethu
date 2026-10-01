import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/widgets/component_gallery_screen.dart';
import 'package:udyogasethu/core/widgets/widgets.dart';

/// Router configuration for UdyogaSethu.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderHomeScreen(),
    ),
    if (kDebugMode)
      GoRoute(
        path: '/dev/gallery',
        builder: (context, state) => const ComponentGalleryScreen(),
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
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.handshake_outlined,
                    size: 72,
                    color: AppColors.primaryTeal,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'UdyogaSethu',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.headerGreenDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bridging Work. Empowering Lives.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const VerifiedBadge(type: VerifiedBadgeType.worker),
                  const SizedBox(height: 24),
                  if (kDebugMode) ...[
                    AppButton(
                      label: '🎨 Open Design System Gallery (/dev/gallery)',
                      onPressed: () {
                        context.push('/dev/gallery');
                      },
                      variant: AppButtonVariant.primary,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const StatusChip(
                    label: 'Phase 0 Step 0.3 - Design System Built',
                    style: StatusChipStyle.success,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
