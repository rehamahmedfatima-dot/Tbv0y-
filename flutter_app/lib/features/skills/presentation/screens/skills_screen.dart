import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/skill.dart';
import '../providers/skills_providers.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Skills Learned')),
      body: skillsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load skills: $e')),
        data: (skills) {
          if (skills.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology_outlined, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.md),
                    Text('No skills tracked yet', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: skills.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _SkillCard(skill: skills[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSkillSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Skill'),
      ),
    );
  }

  void _showAddSkillSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Skill name')),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  ref.read(skillsProvider.notifier).add(controller.text.trim(), null);
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _SkillCard extends ConsumerWidget {
  final Skill skill;
  const _SkillCard({required this.skill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${skill.level} · ${skill.hoursLogged.toStringAsFixed(1)}h logged',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Log practice session',
            onPressed: () async {
              final minutes = await showDialog<int>(
                context: context,
                builder: (_) => _LogSessionDialog(),
              );
              if (minutes != null) ref.read(skillsProvider.notifier).logSession(skill.id, minutes);
            },
          ),
        ],
      ),
    );
  }
}

class _LogSessionDialog extends StatefulWidget {
  @override
  State<_LogSessionDialog> createState() => _LogSessionDialogState();
}

class _LogSessionDialogState extends State<_LogSessionDialog> {
  int _minutes = 30;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log practice session'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in [15, 30, 60, 120])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('${m}m'),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, _minutes), child: const Text('Log')),
      ],
    );
  }
}
