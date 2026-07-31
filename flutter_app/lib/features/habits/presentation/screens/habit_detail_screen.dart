import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/habit.dart';
import '../providers/habit_providers.dart';
import '../widgets/habit_visuals.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  List<HabitLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final repo = ref.read(habitRepositoryProvider);
    final logs = await repo.getLogs(
      habitId: widget.habit.id,
      from: DateTime.now().subtract(const Duration(days: 27)),
      to: DateTime.now(),
    );
    if (mounted) setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final color = HabitVisuals.colorFrom(habit.color);
    final last28CompletionRate =
        _logs.isEmpty ? 0.0 : _logs.where((l) => l.completed).length / 28;

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'archive') {
                await ref.read(habitsProvider.notifier).archive(habit.id);
              } else if (value == 'delete') {
                await ref.read(habitsProvider.notifier).delete(habit.id);
              }
              if (mounted) Navigator.of(context).pop();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'archive', child: Text('Archive')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  children: [
                    _StatCard(
                      label: 'Current Streak',
                      value: '${habit.currentStreak}',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StatCard(
                      label: 'Longest Streak',
                      value: '${habit.longestStreak}',
                      icon: Icons.emoji_events_rounded,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _StatCard(
                  label: '28-Day Completion',
                  value: '${(last28CompletionRate * 100).round()}%',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  fullWidth: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Last 4 weeks', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                SizedBox(height: 180, child: _CompletionBarChart(logs: _logs, color: color)),
                if (habit.description != null && habit.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text('Notes', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(habit.description!),
                ],
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: card) : Expanded(child: card);
  }
}

class _CompletionBarChart extends StatelessWidget {
  final List<HabitLog> logs;
  final Color color;
  const _CompletionBarChart({required this.logs, required this.color});

  @override
  Widget build(BuildContext context) {
    final completedDates = logs.where((l) => l.completed).map((l) => l.logDate).toSet();
    final today = DateTime.now();
    final weeks = <List<bool>>[];

    for (int w = 3; w >= 0; w--) {
      final week = <bool>[];
      for (int d = 6; d >= 0; d--) {
        final date = today.subtract(Duration(days: w * 7 + d));
        final normalized = DateTime(date.year, date.month, date.day);
        week.add(completedDates.any((c) => DateTime(c.year, c.month, c.day) == normalized));
      }
      weeks.add(week);
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _weekLabel,
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < weeks.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: weeks[i].where((d) => d).length.toDouble(),
                color: color,
                width: 28,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(show: true, toY: 7, color: color.withValues(alpha: 0.08)),
              ),
            ]),
        ],
        maxY: 7,
      ),
    );
  }

  static Widget _weekLabel(double value, TitleMeta meta) {
    final labels = ['3wk ago', '2wk ago', 'Last wk', 'This wk'];
    final i = value.toInt();
    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(labels[i], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    );
  }
}
