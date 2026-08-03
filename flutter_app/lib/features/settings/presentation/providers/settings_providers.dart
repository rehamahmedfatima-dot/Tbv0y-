import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_settings_repository.dart';
import '../../domain/app_settings.dart';
import '../../domain/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SupabaseSettingsRepository());

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }
  final SettingsRepository _repo;

  Future<void> _load() async {
    try {
      state = AsyncValue.data(await _repo.loadSettings());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(AppSettings Function(AppSettings) updater) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = updater(current);
    state = AsyncValue.data(updated); // optimistic
    try {
      await _repo.updateSettings(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st); // revert-ish: surfaces the failure
      await _load();
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>(
  (ref) => SettingsNotifier(ref.watch(settingsRepositoryProvider)),
);
