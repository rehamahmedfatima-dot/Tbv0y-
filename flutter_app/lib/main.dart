import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'core/network/supabase_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/security/app_lock_gate.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  EnvConfig.load(dotenv.env);

  await SupabaseService.initialize();

  // Requires platform config files (google-services.json /
  // GoogleService-Info.plist) to already be in place — see README.
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: TbvoyApp()));
}

class TbvoyApp extends ConsumerStatefulWidget {
  const TbvoyApp({super.key});

  @override
  ConsumerState<TbvoyApp> createState() => _TbvoyAppState();
}

class _TbvoyAppState extends ConsumerState<TbvoyApp> {
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final isLoggedIn = ref.watch(authStateProvider).valueOrNull != null;

    // Only load settings once there's a signed-in user — the settings
    // table is scoped per-user and there's nothing to load before login.
    ref.listen(authStateProvider, (previous, next) {
      if (next.valueOrNull != null && previous?.valueOrNull == null) {
        PushNotificationService.initialize();
      }
    });

    final themeMode = isLoggedIn
        ? _themeModeFrom(ref.watch(settingsProvider).valueOrNull?.themeMode)
        : ThemeMode.system;

    return MaterialApp.router(
      title: 'TBVOY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (!isLoggedIn || child == null) return child ?? const SizedBox.shrink();
        return AppLockGate(child: child);
      },
    );
  }

  ThemeMode _themeModeFrom(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
