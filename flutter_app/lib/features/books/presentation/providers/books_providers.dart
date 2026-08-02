import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_books_repository.dart';
import '../../domain/book.dart';

final booksRepositoryProvider = Provider<BooksRepository>((ref) => SupabaseBooksRepository());

class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  BooksNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }
  final BooksRepository _repo;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.loadBooks());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(String title, String? author, int? pages) async {
    await _repo.addBook(title, author, pages);
    await refresh();
  }

  Future<void> updateProgress(String bookId, int pagesRead) async {
    await _repo.updateProgress(bookId, pagesRead);
    await refresh();
  }

  Future<void> addNote(String bookId, String content, {String type = 'note'}) async {
    await _repo.addNote(bookId, content, type: type);
    await refresh();
  }
}

final booksProvider = StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>(
  (ref) => BooksNotifier(ref.watch(booksRepositoryProvider)),
);
