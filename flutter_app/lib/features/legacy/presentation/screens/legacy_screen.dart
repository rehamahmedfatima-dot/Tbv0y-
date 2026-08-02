import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/legacy_profile.dart';
import '../providers/legacy_providers.dart';

class LegacyScreen extends ConsumerStatefulWidget {
  const LegacyScreen({super.key});

  @override
  ConsumerState<LegacyScreen> createState() => _LegacyScreenState();
}

class _LegacyScreenState extends ConsumerState<LegacyScreen> {
  final _missionController = TextEditingController();
  final _visionController = TextEditingController();
  final _purposeController = TextEditingController();
  final _valuesController = TextEditingController();
  final _dreamsController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  void _populate(LegacyProfile p) {
    if (_loaded) return;
    _missionController.text = p.missionStatement ?? '';
    _visionController.text = p.vision ?? '';
    _purposeController.text = p.lifePurpose ?? '';
    _valuesController.text = p.coreValues.join(', ');
    _dreamsController.text = p.dreams.join(', ');
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = LegacyProfile(
      missionStatement: _missionController.text.trim(),
      vision: _visionController.text.trim(),
      lifePurpose: _purposeController.text.trim(),
      coreValues: _valuesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      dreams: _dreamsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    );
    await ref.read(legacyRepositoryProvider).save(profile);
    ref.invalidate(legacyAlignmentProvider);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved.')));
    }
  }

  @override
  void dispose() {
    _missionController.dispose();
    _visionController.dispose();
    _purposeController.dispose();
    _valuesController.dispose();
    _dreamsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(legacyProfileProvider);
    final alignmentAsync = ref.watch(legacyAlignmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Legacy')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (profile) {
          _populate(profile);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              alignmentAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (note) => Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(note, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ),
              TextField(
                controller: _missionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Mission Statement'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _valuesController,
                decoration: const InputDecoration(labelText: 'Core Values (comma-separated)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _visionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Vision'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _purposeController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Life Purpose'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _dreamsController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Dreams (comma-separated)'),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : const Text('Save'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
