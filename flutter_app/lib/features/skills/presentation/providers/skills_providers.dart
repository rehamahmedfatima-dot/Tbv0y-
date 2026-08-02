import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_skills_repository.dart';
import '../../domain/skill.dart';

final skillsRepositoryProvider = Provider<SkillsRepository>((ref) => SupabaseSkillsRepository());

class SkillsNotifier extends StateNotifier<AsyncValue<List<Skill>>> {
  SkillsNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }
  final SkillsRepository _repo;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.loadSkills());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(String title, String? category) async {
    await _repo.addSkill(title, category);
    await refresh();
  }

  Future<void> logSession(String skillId, int minutes) async {
    await _repo.logSession(skillId, minutes);
    await refresh();
  }
}

final skillsProvider = StateNotifierProvider<SkillsNotifier, AsyncValue<List<Skill>>>(
  (ref) => SkillsNotifier(ref.watch(skillsRepositoryProvider)),
);
