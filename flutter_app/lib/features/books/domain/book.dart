class BookNote {
  final String id;
  final String noteType; // note|quote
  final String content;
  final int? pageNumber;

  const BookNote({required this.id, required this.noteType, required this.content, this.pageNumber});

  factory BookNote.fromJson(Map<String, dynamic> json) => BookNote(
        id: json['id'] as String,
        noteType: json['note_type'] as String? ?? 'note',
        content: json['content'] as String,
        pageNumber: json['page_number'] as int?,
      );
}

class Book {
  final String id;
  final String title;
  final String? author;
  final int? totalPages;
  final int pagesRead;
  final String status; // want_to_read|reading|completed|abandoned
  final int? rating;
  final List<BookNote> notes;

  const Book({
    required this.id,
    required this.title,
    this.author,
    this.totalPages,
    required this.pagesRead,
    required this.status,
    this.rating,
    this.notes = const [],
  });

  double get progress => (totalPages == null || totalPages == 0) ? 0 : pagesRead / totalPages!;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        totalPages: json['total_pages'] as int?,
        pagesRead: json['pages_read'] as int? ?? 0,
        status: json['status'] as String? ?? 'reading',
        rating: json['rating'] as int?,
        notes: (json['book_notes'] as List<dynamic>? ?? [])
            .map((n) => BookNote.fromJson(n as Map<String, dynamic>))
            .toList(),
      );
}
