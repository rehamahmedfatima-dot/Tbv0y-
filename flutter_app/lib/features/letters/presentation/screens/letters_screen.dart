import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/letter.dart';
import '../providers/letters_providers.dart';

class LettersScreen extends ConsumerWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lettersAsync = ref.watch(lettersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Letters to Myself'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Generate AI letter',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Writing your letter…')));
              await ref.read(lettersProvider.notifier).generateAiLetter();
            },
          ),
        ],
      ),
      body: lettersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load letters: $e')),
        data: (letters) {
          if (letters.isEmpty) return const _EmptyLettersState();
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: letters.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _LetterCard(letter: letters[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComposer(context, ref),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Write Letter'),
      ),
    );
  }

  void _showComposer(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LetterComposerSheet(),
    );
  }
}

class _LetterComposerSheet extends ConsumerStatefulWidget {
  const _LetterComposerSheet();
  @override
  ConsumerState<_LetterComposerSheet> createState() => _LetterComposerSheetState();
}

class _LetterComposerSheetState extends ConsumerState<_LetterComposerSheet> {
  final _controller = TextEditingController();
  Duration _delay = const Duration(days: 30);
  bool _saving = false;

  static const _options = {
    '1 week': Duration(days: 7),
    '1 month': Duration(days: 30),
    '6 months': Duration(days: 182),
    '1 year': Duration(days: 365),
  };

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await ref.read(lettersProvider.notifier).write(_controller.text.trim(), DateTime.now().add(_delay));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Open in', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final e in _options.entries)
                  ChoiceChip(
                    label: Text(e.key),
                    selected: _delay == e.value,
                    onSelected: (_) => setState(() => _delay = e.value),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'Dear future me…'),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Seal Letter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterCard extends ConsumerWidget {
  final Letter letter;
  const _LetterCard({required this.letter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: letter.isLocked
          ? null
          : () {
              if (!letter.opened) ref.read(lettersProvider.notifier).open(letter.id);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(letter.title ?? 'Your Letter'),
                  content: SingleChildScrollView(child: Text(letter.content)),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              letter.isLocked ? Icons.lock_outline_rounded : Icons.mail_outline_rounded,
              color: letter.isLocked ? AppColors.textSecondary : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(letter.title ?? (letter.author == 'ai' ? 'From your future self' : 'Your letter')),
                  Text(
                    letter.isLocked
                        ? 'Opens ${DateFormat.yMMMd().format(letter.openAt)}'
                        : (letter.opened ? 'Opened' : 'Ready to open'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLettersState extends StatelessWidget {
  const _EmptyLettersState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outline_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text('No letters yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text('Write to your future self, or let AI write the first one.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
