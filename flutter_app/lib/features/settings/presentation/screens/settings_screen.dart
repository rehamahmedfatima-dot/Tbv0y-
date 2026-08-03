import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/app_settings.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load settings: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SectionLabel('Appearance'),
            _SettingsCard(children: [
              _RadioRow<String>(
                title: 'Theme',
                value: settings.themeMode,
                options: const {'system': 'System', 'light': 'Light', 'dark': 'Dark'},
                onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(themeMode: v)),
              ),
              const Divider(height: 1),
              _RadioRow<String>(
                title: 'Language',
                value: settings.preferredLanguage,
                options: const {'en': 'English', 'ar': 'العربية'},
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(preferredLanguage: v)),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('AI Coach'),
            _SettingsCard(children: [
              _RadioRow<String>(
                title: 'Coaching style',
                value: settings.aiPersonality,
                options: const {'gentle': 'Gentle', 'balanced': 'Balanced', 'tough_love': 'Tough Love'},
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(aiPersonality: v)),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Notifications'),
            _SettingsCard(children: [
              SwitchListTile(
                title: const Text('Enable notifications'),
                value: settings.notificationsEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(notificationsEnabled: v)),
              ),
              const Divider(height: 1),
              _TimeRow(
                title: 'Morning mission time',
                time: settings.morningMissionTime,
                onChanged: (t) =>
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(morningMissionTime: t)),
              ),
              const Divider(height: 1),
              _TimeRow(
                title: 'Evening check-in time',
                time: settings.dailyCheckinTime,
                onChanged: (t) =>
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(dailyCheckinTime: t)),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Privacy & Security'),
            _SettingsCard(children: [
              SwitchListTile(
                title: const Text('Biometric lock'),
                subtitle: const Text('Require Face ID / fingerprint to open TBVOY'),
                value: settings.biometricEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(biometricEnabled: v)),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Your Data'),
            _SettingsCard(children: [
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Export habit history (CSV)'),
                onTap: () => _exportCsv(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Export data summary (PDF)'),
                onTap: () => _exportPdf(context, ref),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Account'),
            _SettingsCard(children: [
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign out'),
                onTap: () => _confirmSignOut(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: const Text('Delete account', style: TextStyle(color: AppColors.danger)),
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(settingsRepositoryProvider);
    final data = await repo.exportAllData();
    await ExportService.exportHabitLogsAsCsv(data['habit_logs'] as List<dynamic>? ?? []);
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(settingsRepositoryProvider);
    final data = await repo.exportAllData();
    await ExportService.exportSummaryAsPdf(data);
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your account and all your data — habits, journal, '
          'goals, everything. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(settingsRepositoryProvider).requestAccountDeletion();
        if (context.mounted) context.go('/login');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete account: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _RadioRow<T> extends StatelessWidget {
  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _RadioRow({required this.title, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          for (final entry in options.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String title;
  final String time; // HH:mm
  final ValueChanged<String> onChanged;

  const _TimeRow({required this.title, required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final parts = time.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    return ListTile(
      title: Text(title),
      trailing: Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
    );
  }
}
