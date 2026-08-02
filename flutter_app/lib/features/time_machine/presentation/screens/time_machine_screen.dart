import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../mood/domain/mood_entry.dart';
import '../../domain/day_replay.dart';
import '../providers/time_machine_providers.dart';

class TimeMachineScreen extends ConsumerWidget {
  const TimeMachineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedReplayDateProvider);
    final replayAsync = ref.watch(dayReplayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Time Machine')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: TableCalendar(
              focusedDay: selectedDate,
              firstDay: DateTime.now().subtract(const Duration(days: 730)),
              lastDay: DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(day, selectedDate),
              onDaySelected: (selected, focused) =>
                  ref.read(selectedReplayDateProvider.notifier).state = selected,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(DateFormat.yMMMMd().format(selectedDate), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          replayAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Could not load that day: $e'),
            data: (replay) => replay.isEmpty ? const _NoDataState() : _ReplayView(replay: replay),
          ),
        ],
      ),
    );
  }
}

class _ReplayView extends StatelessWidget {
  final DayReplay replay;
  const _ReplayView({required this.replay});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (replay.disciplineScore != null)
              Expanded(
                child: _StatTile(
                  label: 'Discipline',
                  value: '${replay.disciplineScore}',
                  color: AppColors.primary,
                ),
              ),
            if (replay.mood != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(label: 'Mood', value: moodEmojis[replay.mood] ?? '—', color: AppColors.secondary),
              ),
            ],
          ],
        ),
        if (replay.habits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Habits', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final h in replay.habits)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                h.completed ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: h.completed ? AppColors.success : AppColors.textSecondary,
              ),
              title: Text(h.title),
            ),
        ],
        if (replay.journalEntries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Journal', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final j in replay.journalEntries)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(j.content),
            ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NoDataState extends StatelessWidget {
  const _NoDataState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: const [
          Icon(Icons.hourglass_empty_rounded, size: 40, color: AppColors.textSecondary),
          SizedBox(height: AppSpacing.sm),
          Text('No activity recorded for this day', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
