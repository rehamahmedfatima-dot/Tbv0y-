import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'core/network/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  EnvConfig.load(dotenv.env);

  await SupabaseService.initialize();

  runApp(const ProviderScope(child: TbvoyApp()));
}

class TbvoyApp extends StatelessWidget {
  const TbvoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TBVOY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Replaced by go_router (core/router/app_router.dart) once
      // onboarding/home/etc. land in later phases — kept simple here
      // so Phase 2 (auth) is runnable on its own.
      home: const LoginScreen(),
    );
  }
}
