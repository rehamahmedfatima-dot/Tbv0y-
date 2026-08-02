import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/challenge.dart';
import '../providers/challenge_providers.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load challenges: $e')),
        data: (challenges) => RefreshIndicator(
          onRefresh: () => ref.read(challengesProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: challenges.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _ChallengeCard(challenge: challenges[i]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Custom'),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    int days = 21;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Custom Challenge', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Text('Duration:'),
                  Expanded(
                    child: Slider(
                      value: days.toDouble(),
                      min: 3, max: 100, divisions: 97,
                      label: '$days days',
                      onChanged: (v) => setState(() => days = v.round()),
                    ),
                  ),
                  Text('$days days'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  ref.read(challengesProvider.notifier).createCustom(titleController.text.trim(), null, days);
                  Navigator.of(context).pop();
                },
                child: const Text('Start Challenge'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  final Challenge challenge;
  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(challengesProvider.notifier);
    final isCompleted = challenge.status == 'completed';

    return Container(
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
              if (challenge.isGlobal)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(Icons.public_rounded, size: 16, color: AppColors.secondary),
                ),
              Expanded(child: Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('${challenge.durationDays} days', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          if (challenge.description != null) ...[
            const SizedBox(height: 4),
            Text(challenge.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (challenge.isJoined) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: challenge.progress,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                color: isCompleted ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('Day ${challenge.currentDay} / ${challenge.durationDays}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                if (!isCompleted)
                  TextButton(
                    onPressed: () => controller.markTodayDone(challenge.id),
                    child: const Text('Mark Today Done'),
                  ),
              ],
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => controller.join(challenge.id),
                child: const Text('Join Challenge'),
              ),
            ),
        ],
      ),
    );
  }
}
