import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_journal_repository.dart';
import '../../domain/journal_entry.dart';
import '../../domain/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) => SupabaseJournalRepository());

class JournalListNotifier extends StateNotifier<AsyncValue<List<JournalEntry>>> {
  JournalListNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }
  final JournalRepository _repo;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.loadEntries());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(JournalEntryType type, String content, {String? mood}) async {
    final entry = await _repo.createEntry(type: type, content: content, moodAtEntry: mood);
    state = AsyncValue.data([entry, ...state.valueOrNull ?? []]);
    // Summarize in the background — don't block the UI.
    _repo.summarizeEntry(entry.id);
  }

  Future<void> delete(String id) async {
    await _repo.deleteEntry(id);
    state = AsyncValue.data((state.valueOrNull ?? []).where((e) => e.id != id).toList());
  }
}

final journalListProvider = StateNotifierProvider<JournalListNotifier, AsyncValue<List<JournalEntry>>>(
  (ref) => JournalListNotifier(ref.watch(journalRepositoryProvider)),
);

final moodPatternInsightProvider = FutureProvider<String>((ref) {
  return ref.watch(journalRepositoryProvider).analyzeMoodPatterns();
});
