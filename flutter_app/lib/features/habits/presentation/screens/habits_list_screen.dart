import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/habit_providers.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';
import '../widgets/habit_card.dart';

class HabitsListScreen extends ConsumerWidget {
  const HabitsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Habit'),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load habits.\n$e', textAlign: TextAlign.center)),
        data: (habits) {
          if (habits.isEmpty) {
            return const _EmptyState();
          }

          final byCategory = <String, List<dynamic>>{};
          for (final h in habits) {
            byCategory.putIfAbsent(h.categoryKey, () => []).add(h);
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(habitsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
              children: [
                for (final entry in byCategory.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.md),
                    child: Text(
                      entry.key[0].toUpperCase() + entry.key.substring(1),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ),
                  for (final habit in entry.value) ...[
                    HabitCard(
                      habit: habit,
                      onToggle: () => ref.read(habitsProvider.notifier).toggleToday(habit.id),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text('No habits yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Tap "New Habit" to start building your best self.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
