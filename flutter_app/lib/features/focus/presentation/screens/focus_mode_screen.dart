import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/focus_session.dart';
import '../providers/focus_providers.dart';

class FocusModeScreen extends ConsumerWidget {
  const FocusModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(focusTimerProvider);
    final todayMinutesAsync = ref.watch(todayFocusMinutesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Mode')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              if (timer.phase == TimerPhase.idle) ...[
                Text('Choose your mode', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _ModeCard(
                      label: 'Pomodoro',
                      subtitle: '25 min',
                      icon: Icons.timer_outlined,
                      selected: timer.type == FocusSessionType.pomodoro,
                      onTap: () => ref.read(focusTimerProvider.notifier).selectType(FocusSessionType.pomodoro),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ModeCard(
                      label: 'Deep Work',
                      subtitle: '90 min',
                      icon: Icons.psychology_outlined,
                      selected: timer.type == FocusSessionType.deepWork,
                      onTap: () => ref.read(focusTimerProvider.notifier).selectType(FocusSessionType.deepWork),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ModeCard(
                      label: 'Forest',
                      subtitle: '45 min',
                      icon: Icons.park_outlined,
                      selected: timer.type == FocusSessionType.forest,
                      onTap: () => ref.read(focusTimerProvider.notifier).selectType(FocusSessionType.forest),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              Expanded(
                child: Center(
                  child: timer.phase == TimerPhase.finished
                      ? _FinishedView(onReset: () => ref.read(focusTimerProvider.notifier).reset())
                      : _TimerRing(timer: timer),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Controls(timer: timer),
              const SizedBox(height: AppSpacing.xl),
              todayMinutesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (minutes) => _StatRow(minutes: minutes),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.08) : Theme.of(context).cardColor,
            border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: selected ? AppColors.primary : null)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final FocusTimerState timer;
  const _TimerRing({required this.timer});

  @override
  Widget build(BuildContext context) {
    final progress = timer.totalSeconds == 0 ? 0.0 : timer.remainingSeconds / timer.totalSeconds;
    final minutes = (timer.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timer.remainingSeconds % 60).toString().padLeft(2, '0');

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$minutes:$seconds', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700)),
              Text(
                timer.phase == TimerPhase.paused ? 'Paused' : 'Focusing…',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  final FocusTimerState timer;
  const _Controls({required this.timer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(focusTimerProvider.notifier);

    if (timer.phase == TimerPhase.finished) return const SizedBox.shrink();

    if (timer.phase == TimerPhase.idle) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: controller.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Focus Session'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: controller.stopEarly,
            child: const Text('Stop'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: timer.phase == TimerPhase.running ? controller.pause : controller.resume,
            icon: Icon(timer.phase == TimerPhase.running ? Icons.pause_rounded : Icons.play_arrow_rounded),
            label: Text(timer.phase == TimerPhase.running ? 'Pause' : 'Resume'),
          ),
        ),
      ],
    );
  }
}

class _FinishedView extends StatelessWidget {
  final VoidCallback onReset;
  const _FinishedView({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.celebration_rounded, size: 56, color: AppColors.success),
        const SizedBox(height: AppSpacing.md),
        Text('Session complete!', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        const Text('Nice focus. Your discipline score just went up.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(onPressed: onReset, child: const Text('Start Another')),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final int minutes;
  const _StatRow({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('$minutes minutes focused today', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
