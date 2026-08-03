import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';

/// Wraps the app's authenticated routes. If the user enabled "Biometric
/// lock" in Settings, this blocks the UI behind a lock screen until
/// Face ID / fingerprint succeeds — checked once per cold start.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  bool _unlocked = false;
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      _maybeUnlock();
    }
  }

  Future<void> _maybeUnlock() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null || !settings.biometricEnabled) {
      setState(() => _unlocked = true);
      return;
    }
    await _attemptUnlock();
  }

  Future<void> _attemptUnlock() async {
    final repo = SupabaseAuthRepository();
    final available = await repo.isBiometricAvailable();
    if (!available) {
      setState(() => _unlocked = true); // no biometrics on this device — don't hard-lock the user out
      return;
    }
    final success = await repo.authenticateWithBiometrics();
    if (mounted) setState(() => _unlocked = success);
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fingerprint_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text('TBVOY is locked', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              const Text('Unlock to continue', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: _attemptUnlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
