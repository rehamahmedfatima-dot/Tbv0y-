import 'day_replay.dart';

abstract class TimeMachineRepository {
  Future<DayReplay> loadDay(DateTime date);

  /// Dates (as yyyy-MM-dd strings) that have any recorded activity —
  /// used to highlight the calendar picker.
  Future<Set<String>> loadActiveDates({required DateTime from, required DateTime to});
}
