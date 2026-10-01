import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/core/l10n/locale_controller.dart';
import 'package:udyogasethu/core/router/app_router.dart';
import 'package:udyogasethu/core/theme/app_theme.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

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

class UdyogaSethuApp extends ConsumerWidget {
  const UdyogaSethuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
