import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatChip({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

const _moodOptions = [
  ('great', '😄', AppColors.success),
  ('good', '🙂', AppColors.secondary),
  ('neutral', '😐', AppColors.accent),
  ('low', '😕', AppColors.warning),
  ('bad', '😞', AppColors.danger),
];

class MoodPicker extends StatelessWidget {
  final String? selectedMood;
  final void Function(String mood, int score) onSelect;

  const MoodPicker({super.key, required this.selectedMood, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How are you feeling?', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < _moodOptions.length; i++)
                _MoodButton(
                  emoji: _moodOptions[i].$2,
                  selected: selectedMood == _moodOptions[i].$1,
                  onTap: () => onSelect(_moodOptions[i].$1, 10 - (i * 2)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _MoodButton({required this.emoji, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
