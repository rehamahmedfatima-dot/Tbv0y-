import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/habit.dart';
import '../providers/habit_providers.dart';

const _kCategoryOptions = [
  ('health', 'Health', Icons.favorite_border_rounded),
  ('fitness', 'Fitness', Icons.fitness_center_rounded),
  ('reading', 'Reading', Icons.menu_book_outlined),
  ('learning', 'Learning', Icons.school_outlined),
  ('work', 'Work', Icons.work_outline_rounded),
  ('prayer', 'Prayer', Icons.self_improvement_rounded),
  ('meditation', 'Meditation', Icons.spa_outlined),
  ('finance', 'Finance', Icons.savings_outlined),
  ('relationships', 'Relationships', Icons.people_outline_rounded),
  ('custom', 'Custom', Icons.star_outline_rounded),
];

const _kColorOptions = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.accent,
  AppColors.success,
  AppColors.danger,
];

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? habit; // null = create mode
  const AddEditHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.habit?.title ?? '');
  late final _descController = TextEditingController(text: widget.habit?.description ?? '');

  // Defensive defaults — always have a valid selection so save can never
  // silently fail on a null value that the form itself doesn't validate.
  late String _categoryKey = widget.habit?.categoryKey ?? _kCategoryOptions.first.$1;
  late Color _color = widget.habit?.color ?? _kColorOptions.first;
  late HabitFrequencyType _frequencyType = widget.habit?.frequencyType ?? HabitFrequencyType.daily;
  late HabitPriority _priority = widget.habit?.priority ?? HabitPriority.medium;
  int _timesPerWeek = 3;

  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final notifier = ref.read(habitsProvider.notifier);
      if (widget.habit == null) {
        await notifier.create(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          categoryKey: _categoryKey,
          color: _color,
          frequencyType: _frequencyType,
          timesPerWeek: _frequencyType == HabitFrequencyType.xTimesPerWeek ? _timesPerWeek : null,
          priority: _priority,
        );
      } else {
        await notifier.update(
          habitId: widget.habit!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          categoryKey: _categoryKey,
          color: _color,
          frequencyType: _frequencyType,
          timesPerWeek: _frequencyType == HabitFrequencyType.xTimesPerWeek ? _timesPerWeek : null,
          priority: _priority,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Never fail silently — show exactly what went wrong so this never
      // needs another round of guessing.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save habit: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.habit == null ? 'New Habit' : 'Edit Habit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Habit title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in _kCategoryOptions)
                  ChoiceChip(
                    label: Text(c.$2),
                    avatar: Icon(c.$3, size: 16),
                    selected: _categoryKey == c.$1,
                    onSelected: (_) => setState(() => _categoryKey = c.$1),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final color in _kColorOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _color == color
                              ? Border.all(color: Colors.black.withValues(alpha: 0.4), width: 2)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Frequency', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Daily'),
                  selected: _frequencyType == HabitFrequencyType.daily,
                  onSelected: (_) => setState(() => _frequencyType = HabitFrequencyType.daily),
                ),
                ChoiceChip(
                  label: const Text('Weekly'),
                  selected: _frequencyType == HabitFrequencyType.weekly,
                  onSelected: (_) => setState(() => _frequencyType = HabitFrequencyType.weekly),
                ),
                ChoiceChip(
                  label: const Text('X times/week'),
                  selected: _frequencyType == HabitFrequencyType.xTimesPerWeek,
                  onSelected: (_) => setState(() => _frequencyType = HabitFrequencyType.xTimesPerWeek),
                ),
              ],
            ),
            if (_frequencyType == HabitFrequencyType.xTimesPerWeek) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Text('Times per week:'),
                  const SizedBox(width: AppSpacing.sm),
                  DropdownButton<int>(
                    value: _timesPerWeek,
                    items: [for (int i = 1; i <= 7; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                    onChanged: (v) {
                      if (v != null) setState(() => _timesPerWeek = v);
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            Text('Priority', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final p in HabitPriority.values)
                  ChoiceChip(
                    label: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(widget.habit == null ? 'Create Habit' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
