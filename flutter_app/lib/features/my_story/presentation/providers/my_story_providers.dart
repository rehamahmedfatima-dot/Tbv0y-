import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_my_story_repository.dart';
import '../../domain/my_story_repository.dart';
import '../../domain/story_report.dart';

final myStoryRepositoryProvider = Provider<MyStoryRepository>((ref) => SupabaseMyStoryRepository());

final currentYearReportProvider = FutureProvider.autoDispose<StoryReport?>((ref) {
  return ref.watch(myStoryRepositoryProvider).loadReport(DateTime.now().year);
});

class StoryGenerationController extends StateNotifier<AsyncValue<StoryReport?>> {
  StoryGenerationController(this._repo) : super(const AsyncValue.data(null));
  final MyStoryRepository _repo;

  Future<void> generate(int year) async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.generateReport(year));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final storyGenerationProvider =
    StateNotifierProvider<StoryGenerationController, AsyncValue<StoryReport?>>(
  (ref) => StoryGenerationController(ref.watch(myStoryRepositoryProvider)),
);
