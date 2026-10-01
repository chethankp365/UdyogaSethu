import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/router/app_router.dart';
import 'package:udyogasethu/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
    );
  }

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
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
