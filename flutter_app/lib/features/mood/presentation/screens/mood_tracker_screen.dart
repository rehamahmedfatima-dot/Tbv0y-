import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/mood_entry.dart';
import '../providers/mood_providers.dart';

class MoodTrackerScreen extends ConsumerWidget {
  const MoodTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(moodHistoryProvider);
    final suggestionsAsync = ref.watch(suggestedActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracker')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load mood history: $e')),
        data: (history) => RefreshIndicator(
          onRefresh: () => ref.read(moodHistoryProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Last 30 days', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 200,
                child: history.length < 2
                    ? const Center(
                        child: Text('Log a few more days to see your trend',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : _MoodChart(history: history),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('AI suggestions for you', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              suggestionsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const SizedBox.shrink(),
                data: (suggestions) => Column(
                  children: [
                    for (final s in suggestions)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.spa_outlined, size: 18, color: AppColors.secondary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(s)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('History', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              for (final log in history.reversed.take(14))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(moodEmojis[log.mood] ?? '😐', style: const TextStyle(fontSize: 24)),
                  title: Text(DateFormat.yMMMd().format(log.logDate)),
                  subtitle: log.note != null ? Text(log.note!) : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodChart extends StatelessWidget {
  final List<MoodLog> history;
  const _MoodChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].moodScore.toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 1,
        maxY: 5,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 1),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.secondary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
