import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_letters_repository.dart';
import '../../domain/letter.dart';

final lettersRepositoryProvider = Provider<LettersRepository>((ref) => SupabaseLettersRepository());

class LettersNotifier extends StateNotifier<AsyncValue<List<Letter>>> {
  LettersNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }
  final LettersRepository _repo;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.loadLetters());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> write(String content, DateTime openAt, {String? title}) async {
    await _repo.writeLetter(content: content, openAt: openAt, title: title);
    await refresh();
  }

  Future<void> generateAiLetter() async {
    await _repo.generateAiLetter();
    await refresh();
  }

  Future<void> open(String letterId) async {
    await _repo.markOpened(letterId);
    await refresh();
  }
}

final lettersProvider = StateNotifierProvider<LettersNotifier, AsyncValue<List<Letter>>>(
  (ref) => LettersNotifier(ref.watch(lettersRepositoryProvider)),
);
