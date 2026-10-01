import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: UdyogaSethuApp(),
    ),
  );
}

class UdyogaSethuApp extends StatelessWidget {
  const UdyogaSethuApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Env.isConfigured) {
      return const MissingEnvScreen();
    }

    return MaterialApp.router(
      title: 'UdyogaSethu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D6548),
          primary: const Color(0xFF0D6548),
          secondary: const Color(0xFF00875A),
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
