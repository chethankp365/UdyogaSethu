import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/app_router.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_theme.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

import 'package:udyogasethu/core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // In release builds never show a full-screen red error: show a friendly message
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      return const Material(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 48, color: AppColors.headerGreenDark),
                SizedBox(height: 16),
                Text(
                  'Something went wrong. Please restart or try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ErrorWidget(details.exception);
  };

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

class UdyogaSethuApp extends ConsumerStatefulWidget {
  const UdyogaSethuApp({super.key});

  @override
  ConsumerState<UdyogaSethuApp> createState() => _UdyogaSethuAppState();
}

class _UdyogaSethuAppState extends ConsumerState<UdyogaSethuApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Env.isConfigured) {
        ref.read(notificationServiceProvider).initialize(
          onNavigate: (route) {
            ref.read(appRouterProvider).push(route);
          },
        );
        ref.read(notificationServiceProvider).requestPermissionAndRegister();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.isConfigured) {
      return const MissingEnvScreen();
    }

    final router = ref.watch(appRouterProvider);
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'UdyogaSethu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
