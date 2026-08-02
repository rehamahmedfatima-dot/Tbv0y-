import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../achievements/presentation/providers/achievement_providers.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../../goals/presentation/providers/goal_providers.dart';
import '../../../goals/domain/goal.dart';
import '../../../habits/presentation/providers/habit_providers.dart';
import '../../../letters/presentation/providers/letters_providers.dart';
import '../../../skills/presentation/providers/skills_providers.dart';

class MyJourneyScreen extends ConsumerWidget {
  const MyJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final booksAsync = ref.watch(booksProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final lettersAsync = ref.watch(lettersProvider);
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Journey')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Every entry here is a piece of who you\'re becoming.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),

          _JourneySection(
            emoji: '🏆',
            title: 'Achievements',
            onSeeAll: () => context.push('/achievements'),
            child: achievementsAsync.when(
              loading: () => const _MiniLoading(),
              error: (e, _) => const SizedBox.shrink(),
              data: (achievements) {
                final unlocked = achievements.where((a) => a.unlocked).toList();
                return unlocked.isEmpty
                    ? const _EmptyLine('No badges unlocked yet — keep going.')
                    : Text('${unlocked.length} of ${achievements.length} badges unlocked',
                        style: const TextStyle(fontWeight: FontWeight.w600));
              },
            ),
          ),

          _JourneySection(
            emoji: '✅',
            title: 'Habits Built',
            onSeeAll: () => context.push('/habits'),
            child: habitsAsync.when(
              loading: () => const _MiniLoading(),
              error: (e, _) => const SizedBox.shrink(),
              data: (habits) {
                if (habits.isEmpty) return const _EmptyLine('No habits yet.');
                final best = habits.reduce((a, b) => a.longestStreak > b.longestStreak ? a : b);
                return Text('${habits.length} active habits • longest streak: ${best.longestStreak} days');
              },
            ),
          ),

          _JourneySection(
            emoji: '📚',
            title: 'Reading Journey',
            onSeeAll: () => context.push('/books'),
            child: booksAsync.when(
              loading: () => const _MiniLoading(),
              error: (e, _) => const SizedBox.shrink(),
              data: (books) {
                final completed = books.where((b) => b.status == 'completed').length;
                final pages = books.fold<int>(0, (sum, b) => sum + b.pagesRead);
                return Text(completed == 0 && pages == 0
                    ? 'Add your first book to start tracking.'
                    : '$completed books completed • $pages pages read');
              },
            ),
          ),

          _JourneySection(
            emoji: '🧠',
            title: 'Skills Learned',
            onSeeAll: () => context.push('/skills'),
            child: skillsAsync.when(
              loading: () => const _MiniLoading(),
              error: (e, _) => const SizedBox.shrink(),
              data: (skills) {
                if (skills.isEmpty) return const _EmptyLine('No skills tracked yet.');
                final hours = skills.fold<double>(0, (sum, s) => sum + s.hoursLogged);
                return Text('${skills.length} skills • ${hours.toStringAsFixed(0)} hours logged');
              },
            ),
          ),

          _JourneySection(
            emoji: '📅',
            title: 'Discipline Calendar',
            onSeeAll: () => context.push('/time-machine'),
            child: const Text('Explore any past day in the Time Machine.'),
          ),

          _JourneySection(
            emoji: '💌',
            title: 'Letters to Myself',
            onSeeAll: () => context.push('/letters'),
            child: lettersAsync.when(
              loading: () => const _MiniLoading(),
              error: (e, _) => const SizedBox.shrink(),
              data: (letters) => letters.isEmpty
                  ? const _EmptyLine('Write your first letter to your future self.')
                  : Text('${letters.length} letters written'),
            ),
          ),

          _JourneySection(
            emoji: '🎯',
            title: 'Goals Achieved',
            onSeeAll: () => context.push('/goals'),
            child: goalsAsync.when(
              loading: () => const _MiniLoading(),
              error: (e, _) => const SizedBox.shrink(),
              data: (goals) {
                final completed = goals.where((g) => g.status == GoalStatus.completed).length;
                final active = goals.where((g) => g.status == GoalStatus.active).length;
                return Text('$completed goals achieved • $active in progress');
              },
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/my-story'),
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: const Text('Read My Story'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/challenges'),
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Challenges'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/legacy'),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('My Legacy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneySection extends StatelessWidget {
  final String emoji;
  final String title;
  final Widget child;
  final VoidCallback onSeeAll;

  const _JourneySection({
    required this.emoji,
    required this.title,
    required this.child,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSeeAll,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  DefaultTextStyle(style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), child: child),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _MiniLoading extends StatelessWidget {
  const _MiniLoading();
  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2));
}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine(this.text);
  @override
  Widget build(BuildContext context) => Text(text);
}
