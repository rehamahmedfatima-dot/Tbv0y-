import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/goal.dart';
import '../providers/goal_providers.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final Goal? goal; // null = create mode
  final String? prefillTitle;
  const GoalDetailScreen({super.key, required this.goal, this.prefillTitle});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  late final _titleController =
      TextEditingController(text: widget.goal?.title ?? widget.prefillTitle ?? '');
  late final _descController = TextEditingController(text: widget.goal?.description ?? '');
  GoalType _type = GoalType.shortTerm;
  DateTime? _targetDate;
  bool _saving = false;
  bool _generatingRoadmap = false;

  bool get _isCreateMode => widget.goal == null;

  Future<void> _saveNewGoal() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await ref.read(goalsProvider.notifier).create(
          _titleController.text.trim(),
          _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          _type,
          _targetDate,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreateMode) return _buildCreateForm(context);
    return _buildDetail(context, widget.goal!);
  }

  Widget _buildCreateForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Goal')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Goal title'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Details (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Short-term'),
                  selected: _type == GoalType.shortTerm,
                  onSelected: (_) => setState(() => _type = GoalType.shortTerm),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: const Text('Long-term'),
                  selected: _type == GoalType.longTerm,
                  onSelected: (_) => setState(() => _type = GoalType.longTerm),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_targetDate == null ? 'Set target date (optional)' : DateFormat.yMMMd().format(_targetDate!)),
            ),
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveNewGoal,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Create Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Goal goal) {
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (goal.status != GoalStatus.completed)
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded),
              tooltip: 'Mark completed',
              onPressed: () async {
                await ref.read(goalsProvider.notifier).markCompleted(goal.id);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (goal.description != null) ...[
            Text(goal.description!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: goal.progressPercent / 100,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Milestones', style: Theme.of(context).textTheme.titleLarge),
              if (goal.milestones.isEmpty)
                TextButton.icon(
                  onPressed: _generatingRoadmap
                      ? null
                      : () async {
                          setState(() => _generatingRoadmap = true);
                          await ref.read(goalsProvider.notifier).generateRoadmap(goal.id);
                          if (mounted) setState(() => _generatingRoadmap = false);
                        },
                  icon: _generatingRoadmap
                      ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('AI Roadmap'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (goal.milestones.isEmpty)
            const Text('No milestones yet — generate a roadmap with AI, or they\'ll appear here.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            for (final m in goal.milestones)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: m.isCompleted,
                onChanged: (v) => ref.read(goalsProvider.notifier).toggleMilestone(m.id, v ?? false),
                title: Text(m.title,
                    style: TextStyle(decoration: m.isCompleted ? TextDecoration.lineThrough : null)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
        ],
      ),
    );
  }
}
