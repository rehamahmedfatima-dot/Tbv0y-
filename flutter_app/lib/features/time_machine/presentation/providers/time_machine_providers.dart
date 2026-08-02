import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_time_machine_repository.dart';
import '../../domain/day_replay.dart';
import '../../domain/time_machine_repository.dart';

final timeMachineRepositoryProvider =
    Provider<TimeMachineRepository>((ref) => SupabaseTimeMachineRepository());

final selectedReplayDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dayReplayProvider = FutureProvider.autoDispose<DayReplay>((ref) {
  final date = ref.watch(selectedReplayDateProvider);
  return ref.watch(timeMachineRepositoryProvider).loadDay(date);
});
