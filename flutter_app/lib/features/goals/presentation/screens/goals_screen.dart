import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/goal.dart';
import '../providers/goal_providers.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final suggestionsAsync = ref.watch(suggestedGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load goals: $e')),
        data: (goals) {
          final active = goals.where((g) => g.status == GoalStatus.active).toList();
          final completed = goals.where((g) => g.status == GoalStatus.completed).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(goalsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (active.isEmpty && completed.isEmpty) const _EmptyGoalsState(),
                if (active.isNotEmpty) ...[
                  Text('Active Goals', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  for (final g in active) _GoalCard(goal: g),
                  const SizedBox(height: AppSpacing.lg),
                ],
                suggestionsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (suggestions) => suggestions.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI suggests', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final s in suggestions)
                                  ActionChip(
                                    avatar: const Icon(Icons.add_rounded, size: 16),
                                    label: Text(s),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => GoalDetailScreen(goal: null, prefillTitle: s),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                ),
                if (completed.isNotEmpty) ...[
                  Text('Completed', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  for (final g in completed) _GoalCard(goal: g),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GoalDetailScreen(goal: null)),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final isCompleted = goal.status == GoalStatus.completed;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(goal.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: isCompleted ? TextDecoration.lineThrough : null)),
                ),
                Text('${goal.progressPercent.round()}%',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: goal.progressPercent / 100,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                color: isCompleted ? AppColors.success : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  const _EmptyGoalsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text('No goals yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text('Set your first goal and let AI build the roadmap.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
