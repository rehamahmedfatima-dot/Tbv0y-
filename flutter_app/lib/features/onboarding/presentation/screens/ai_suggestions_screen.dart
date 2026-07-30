import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/onboarding_data.dart';
import '../providers/onboarding_providers.dart';

class AiSuggestionsScreen extends ConsumerStatefulWidget {
  const AiSuggestionsScreen({super.key});

  @override
  ConsumerState<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends ConsumerState<AiSuggestionsScreen> {
  final Set<int> _selectedIndices = {};
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _runAnalysis();
    }
  }

  Future<void> _runAnalysis() async {
    final data = ref.read(onboardingDraftProvider);
    final ok = await ref.read(onboardingControllerProvider.notifier).analyze(data);
    if (ok && mounted) {
      final suggestions = ref.read(onboardingControllerProvider.notifier).suggestions;
      setState(() {
        _selectedIndices.addAll(List.generate(suggestions.length, (i) => i));
      });
    }
  }

  Future<void> _confirm() async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final data = ref.read(onboardingDraftProvider);
    final chosen = [
      for (int i = 0; i < controller.suggestions.length; i++)
        if (_selectedIndices.contains(i)) controller.suggestions[i],
    ];

    final ok = await controller.complete(data, chosen);
    if (!mounted) return;

    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Something went wrong.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    if (status == OnboardingStatus.analyzing) {
      return const _AnalyzingView();
    }

    if (status == OnboardingStatus.error && controller.suggestions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                const SizedBox(height: AppSpacing.md),
                Text(controller.errorMessage ?? 'Something went wrong.'),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(onPressed: _runAnalysis, child: const Text('Try Again')),
              ],
            ),
          ),
        ),
      );
    }

    final suggestions = controller.suggestions;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your path forward', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Based on your answers, here\'s who you\'re on your way to becoming. '
                    'We\'ll turn these into your first habits.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) => _IdentityCard(
                  identity: suggestions[i],
                  selected: _selectedIndices.contains(i),
                  onTap: () => setState(() {
                    _selectedIndices.contains(i) ? _selectedIndices.remove(i) : _selectedIndices.add(i);
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (status == OnboardingStatus.saving || _selectedIndices.isEmpty)
                      ? null
                      : _confirm,
                  child: status == OnboardingStatus.saving
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Start My Journey'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: AppColors.primaryGradient).createShader(bounds),
              child: const Icon(Icons.auto_awesome_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Analyzing your journey…', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'TBVOY is building your personalized path',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final SuggestedIdentity identity;
  final bool selected;
  final VoidCallback onTap;

  const _IdentityCard({required this.identity, required this.selected, required this.onTap});

  static const _iconMap = {
    'star': Icons.star_outline_rounded,
    'book': Icons.menu_book_outlined,
    'dumbbell': Icons.fitness_center_rounded,
    'briefcase': Icons.work_outline_rounded,
    'heart': Icons.favorite_border_rounded,
    'brain': Icons.psychology_outlined,
    'moon': Icons.bedtime_outlined,
    'leaf': Icons.eco_outlined,
    'trending-up': Icons.trending_up_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : Theme.of(context).cardColor,
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: 1.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(_iconMap[identity.icon] ?? Icons.star_outline_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(identity.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(identity.description,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final h in identity.habits)
                        Chip(
                          label: Text(h.title, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ],
        ),
      ),
    );
  }
}
