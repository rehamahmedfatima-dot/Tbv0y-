import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/story_report.dart';
import '../providers/my_story_providers.dart';

class MyStoryScreen extends ConsumerWidget {
  const MyStoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final cachedAsync = ref.watch(currentYearReportProvider);
    final generated = ref.watch(storyGenerationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Story')),
      body: generated.when(
        loading: () => const _GeneratingView(),
        error: (e, _) => Center(child: Text('Could not generate your story: $e')),
        data: (generatedReport) {
          if (generatedReport != null) return _ReportView(report: generatedReport);

          return cachedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Could not load: $e')),
            data: (cached) => cached != null
                ? _ReportView(report: cached)
                : _GenerateCta(
                    year: year,
                    onGenerate: () => ref.read(storyGenerationProvider.notifier).generate(year),
                  ),
          );
        },
      ),
    );
  }
}

class _GenerateCta extends StatelessWidget {
  final int year;
  final VoidCallback onGenerate;
  const _GenerateCta({required this.year, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: AppColors.primaryGradient).createShader(b),
              child: const Icon(Icons.auto_stories_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Your $year story is ready to be told', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'TBVOY will look back at your habits, goals, reading, and growth this year and write it as your story.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(onPressed: onGenerate, child: const Text('Generate My Story')),
          ],
        ),
      ),
    );
  }
}

class _GeneratingView extends StatelessWidget {
  const _GeneratingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Writing your story…', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  final StoryReport report;
  const _ReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.title,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              Text(report.openingReflection, style: const TextStyle(color: Colors.white, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _Section(title: 'Highlights', items: report.highlights, icon: Icons.star_rounded, color: AppColors.accent),
        _Section(title: 'Your Strengths', items: report.strengths, icon: Icons.favorite_rounded, color: AppColors.success),
        if (report.suggestedImprovements.isNotEmpty)
          _Section(
            title: 'Room to Grow',
            items: report.suggestedImprovements,
            icon: Icons.trending_up_rounded,
            color: AppColors.secondary,
          ),
        const SizedBox(height: AppSpacing.md),
        Text('Then vs. Now', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(report.beforeAfter, style: const TextStyle(height: 1.5)),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(report.closingMotivation,
              style: const TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;
  const _Section({required this.title, required this.items, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
