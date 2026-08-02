import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/achievement.dart';
import '../providers/achievement_providers.dart';

const _iconMap = {
  'footprints': Icons.directions_walk_rounded,
  'flame': Icons.local_fire_department_rounded,
  'trophy': Icons.emoji_events_rounded,
  'book': Icons.menu_book_outlined,
  'book-open': Icons.auto_stories_outlined,
  'flag': Icons.flag_rounded,
  'star': Icons.star_rounded,
};

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final levelAsync = ref.watch(userLevelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(achievementsProvider);
          ref.invalidate(userLevelProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            levelAsync.when(
              loading: () => const SizedBox(height: 100),
              error: (e, _) => const SizedBox.shrink(),
              data: (level) => _LevelCard(level: level),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Badges', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            achievementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load achievements: $e'),
              data: (achievements) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievements.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, i) => _BadgeCard(achievement: achievements[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final UserLevel level;
  const _LevelCard({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Level ${level.level}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text('${level.xp} XP', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: level.progressToNextLevel,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Achievement achievement;
  const _BadgeCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.accent.withValues(alpha: 0.08) : Theme.of(context).cardColor,
        border: Border.all(color: unlocked ? AppColors.accent.withValues(alpha: 0.3) : AppColors.divider),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconMap[achievement.icon] ?? Icons.star_rounded,
            color: unlocked ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.4),
            size: 28,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(achievement.title,
              style: TextStyle(fontWeight: FontWeight.w700, color: unlocked ? null : AppColors.textSecondary)),
          if (achievement.description != null)
            Text(achievement.description!,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 2),
          const Spacer(),
          Text(
            unlocked && achievement.unlockedAt != null
                ? DateFormat.yMMMd().format(achievement.unlockedAt!)
                : '+${achievement.xpReward} XP',
            style: TextStyle(fontSize: 11, color: unlocked ? AppColors.success : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
