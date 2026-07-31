import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../onboarding/presentation/widgets/onboarding_widgets.dart' show MultiSelectChip;
import '../providers/habit_providers.dart';
import '../widgets/habit_visuals.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  const AddEditHabitScreen({super.key});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _categoryKey;
  String _icon = 'star';
  String _color = '#2563EB';
  String _frequencyType = 'daily';
  int _timesPerWeek = 3;
  String _priority = 'medium';
  final List<TimeOfDay> _reminders = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty && _categoryKey != null;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      await ref.read(habitsProvider.notifier).addHabit(
            title: _titleController.text.trim(),
            description:
                _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            categoryKey: _categoryKey!,
            icon: _icon,
            color: _color,
            frequencyType: _frequencyType,
            frequencyConfig: _frequencyType == 'x_times_per_week' ? {'times_per_week': _timesPerWeek} : {},
            reminderTimes: _reminders
                .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
                .toList(),
            priority: _priority,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
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
    final categoriesAsync = ref.watch(habitCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Habit'),
        actions: [
          TextButton(
            onPressed: (_canSave && !_saving) ? _save : null,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Habit title'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Category', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load categories: $e'),
              data: (categories) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in categories)
                    MultiSelectChip(
                      label: c.label,
                      selected: _categoryKey == c.key,
                      onTap: () => setState(() => _categoryKey = c.key),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Icon', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: HabitVisuals.selectableIcons.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final iconKey = HabitVisuals.selectableIcons[i];
                  final selected = _icon == iconKey;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = iconKey),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? HabitVisuals.colorFrom(_color).withValues(alpha: 0.15) : null,
                        border: Border.all(
                          color: selected ? HabitVisuals.colorFrom(_color) : AppColors.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Icon(HabitVisuals.iconFor(iconKey),
                          color: selected ? HabitVisuals.colorFrom(_color) : AppColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Color', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: HabitVisuals.selectableColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final hex = HabitVisuals.selectableColors[i];
                  final selected = _color == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: HabitVisuals.colorFrom(hex),
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: AppColors.textPrimary, width: 2) : null,
                      ),
                      child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Frequency', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                MultiSelectChip(
                  label: 'Daily',
                  selected: _frequencyType == 'daily',
                  onTap: () => setState(() => _frequencyType = 'daily'),
                ),
                MultiSelectChip(
                  label: 'Weekly',
                  selected: _frequencyType == 'weekly',
                  onTap: () => setState(() => _frequencyType = 'weekly'),
                ),
                MultiSelectChip(
                  label: 'X times/week',
                  selected: _frequencyType == 'x_times_per_week',
                  onTap: () => setState(() => _frequencyType = 'x_times_per_week'),
                ),
              ],
            ),
            if (_frequencyType == 'x_times_per_week') ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Text('Times per week:'),
                  Expanded(
                    child: Slider(
                      value: _timesPerWeek.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: '$_timesPerWeek',
                      onChanged: (v) => setState(() => _timesPerWeek = v.round()),
                    ),
                  ),
                  Text('$_timesPerWeek'),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            Text('Priority', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final p in const ['low', 'medium', 'high'])
                  MultiSelectChip(
                    label: p[0].toUpperCase() + p.substring(1),
                    selected: _priority == p,
                    onTap: () => setState(() => _priority = p),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (picked != null) setState(() => _reminders.add(picked));
                  },
                  icon: const Icon(Icons.add_alarm_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (int i = 0; i < _reminders.length; i++)
                  Chip(
                    label: Text(_reminders[i].format(context)),
                    onDeleted: () => setState(() => _reminders.removeAt(i)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
