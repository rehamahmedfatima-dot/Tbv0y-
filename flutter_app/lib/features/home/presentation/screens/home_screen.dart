import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../habits/presentation/providers/habit_providers.dart';
import '../../../habits/presentation/widgets/habit_card.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/discipline_score_card.dart';
import '../widgets/growth_tree_card.dart';
import '../widgets/mission_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);
    final pendingHabits = ref.watch(todayPendingHabitsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardProvider.notifier).refresh();
            await ref.read(habitsProvider.notifier).refresh();
          },
          child: dashboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.danger),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Could not load your dashboard.'),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (dashboard) => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back${user?.displayName != null ? ', ${user!.displayName}' : ''}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dashboard.todaysQuote,
                          style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                      child: user?.photoUrl == null
                          ? const Icon(Icons.person_rounded, color: AppColors.primary)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _AiMessageBanner(message: dashboard.motivationalMessage),
                const SizedBox(height: AppSpacing.md),

                DisciplineScoreCard(
                  score: dashboard.disciplineScore,
                  weeklyTrend: dashboard.weeklyDisciplineTrend,
                ),
                const SizedBox(height: AppSpacing.md),

                MissionCard(
                  title: dashboard.todaysMissionTitle,
                  completed: dashboard.missionCompleted,
                  onComplete: () => ref.read(dashboardProvider.notifier).completeMission(),
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    StatChip(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak',
                      value: '${dashboard.longestActiveStreak}d',
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Today',
                      value: '${(dashboard.todayHabitCompletionRate * 100).round()}%',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatChip(
                      icon: Icons.military_tech_outlined,
                      label: 'Level ${dashboard.level}',
                      value: '${dashboard.xp} XP',
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                GrowthTreeCard(
                  stage: dashboard.treeStage,
                  health: dashboard.treeHealth,
                  season: dashboard.treeSeason,
                ),
                const SizedBox(height: AppSpacing.md),

                MoodPicker(
                  selectedMood: dashboard.todaysMood,
                  onSelect: (mood, score) => ref.read(dashboardProvider.notifier).logMood(mood, score),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upcoming Habits', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => context.push('/habits'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (pendingHabits.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const Text(
                      'All habits done for today 🎉',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...pendingHabits.take(4).map(
                        (habit) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: HabitCard(
                            habit: habit,
                            onToggle: () => ref.read(habitsProvider.notifier).toggleToday(habit.id),
                            onTap: () => context.push('/habits/${habit.id}'),
                          ),
                        ),
                      ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/habits/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit'),
      ),
    );
  }
}

class _AiMessageBanner extends StatelessWidget {
  final String message;
  const _AiMessageBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
