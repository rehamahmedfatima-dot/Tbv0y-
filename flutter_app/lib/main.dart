import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  try {
    await dotenv.load(fileName: '.env');
    EnvConfig.load(dotenv.env);

    await SupabaseService.initialize();

    // Firebase (push notifications) needs platform-specific config that
    // isn't set up yet for the web build (no FirebaseOptions / no
    // `flutterfire configure` run). Skip it on web for now so the rest of
    // the app still loads — mobile builds still initialize it normally
    // once google-services.json / GoogleService-Info.plist are in place.
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
      } catch (_) {
        // Don't let a missing/misconfigured Firebase block the whole app.
      }
    }

    runApp(const ProviderScope(child: TbvoyApp()));
  } catch (error, stackTrace) {
    // Show the real error on screen instead of a silent blank page — this
    // is temporary scaffolding for diagnosing deployment issues; remove
    // once the app is verified working end-to-end.
    runApp(_StartupErrorApp(error: error, stackTrace: stackTrace));
  }
}

class _StartupErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;
  const _StartupErrorApp({required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF1F0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TBVOY failed to start',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 12),
                SelectableText('$error', style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                const SizedBox(height: 12),
                SelectableText('$stackTrace', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      if (next.valueOrNull != null && previous?.valueOrNull == null && !kIsWeb) {
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
