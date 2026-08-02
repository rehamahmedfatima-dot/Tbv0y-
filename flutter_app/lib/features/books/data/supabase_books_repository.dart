import '../../../core/network/supabase_service.dart';
import '../domain/book.dart';

abstract class BooksRepository {
  Future<List<Book>> loadBooks();
  Future<void> addBook(String title, String? author, int? totalPages);
  Future<void> updateProgress(String bookId, int pagesRead);
  Future<void> markCompleted(String bookId, {int? rating});
  Future<void> addNote(String bookId, String content, {String type = 'note', int? page});
}

class SupabaseBooksRepository implements BooksRepository {
  final _client = SupabaseService.client;
  String get _userId => SupabaseService.currentUser!.id;

  @override
  Future<List<Book>> loadBooks() async {
    final rows = await _client
        .from('books')
        .select('*, book_notes(*)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Book.fromJson(r)).toList();
  }

  @override
  Future<void> addBook(String title, String? author, int? totalPages) async {
    await _client.from('books').insert({
      'user_id': _userId,
      'title': title,
      'author': author,
      'total_pages': totalPages,
      'status': 'reading',
      'started_at': DateTime.now().toIso8601String().split('T').first,
    });
  }

  @override
  Future<void> updateProgress(String bookId, int pagesRead) async {
    await _client.from('books').update({'pages_read': pagesRead}).eq('id', bookId);
  }

  @override
  Future<void> markCompleted(String bookId, {int? rating}) async {
    await _client.from('books').update({
      'status': 'completed',
      'finished_at': DateTime.now().toIso8601String().split('T').first,
      if (rating != null) 'rating': rating,
    }).eq('id', bookId);
  }

  @override
  Future<void> addNote(String bookId, String content, {String type = 'note', int? page}) async {
    await _client.from('book_notes').insert({
      'book_id': bookId,
      'note_type': type,
      'content': content,
      'page_number': page,
    });
  }
}
