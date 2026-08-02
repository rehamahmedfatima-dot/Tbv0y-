class DayReplay {
  final DateTime date;
  final int? disciplineScore;
  final String? mood;
  final List<({String title, bool completed})> habits;
  final List<({String type, String content})> journalEntries;

  const DayReplay({
    required this.date,
    this.disciplineScore,
    this.mood,
    this.habits = const [],
    this.journalEntries = const [],
  });

  bool get isEmpty => disciplineScore == null && mood == null && habits.isEmpty && journalEntries.isEmpty;
}
