class Letter {
  final String id;
  final String author; // 'user' | 'ai'
  final String? title;
  final String content;
  final DateTime writtenAt;
  final DateTime openAt;
  final bool opened;

  const Letter({
    required this.id,
    required this.author,
    this.title,
    required this.content,
    required this.writtenAt,
    required this.openAt,
    required this.opened,
  });

  bool get isLocked => !opened && DateTime.now().isBefore(openAt);

  factory Letter.fromJson(Map<String, dynamic> json) => Letter(
        id: json['id'] as String,
        author: json['author'] as String? ?? 'user',
        title: json['title'] as String?,
        content: json['content'] as String,
        writtenAt: DateTime.parse(json['written_at'] as String),
        openAt: DateTime.parse(json['open_at'] as String),
        opened: json['opened'] as bool? ?? false,
      );
}
