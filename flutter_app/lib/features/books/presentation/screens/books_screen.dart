import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/book.dart';
import '../providers/books_providers.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reading Journey')),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load books: $e')),
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.md),
                  Text('No books yet', style: Theme.of(context).textTheme.titleLarge),
                ]),
              ),
            );
          }
          final totalPages = books.fold<int>(0, (sum, b) => sum + b.pagesRead);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, color: Colors.white),
                    const SizedBox(width: AppSpacing.sm),
                    Text('$totalPages pages read across ${books.length} books',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final b in books) _BookCard(book: b),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Book'),
      ),
    );
  }

  void _showAddBookSheet(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final pagesController = TextEditingController();
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
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: authorController, decoration: const InputDecoration(labelText: 'Author (optional)')),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: pagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total pages (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  ref.read(booksProvider.notifier).add(
                        titleController.text.trim(),
                        authorController.text.trim().isEmpty ? null : authorController.text.trim(),
                        int.tryParse(pagesController.text.trim()),
                      );
                  Navigator.pop(context);
                },
                child: const Text('Add Book'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  final Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(book.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (book.author != null) Text(book.author!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          if (book.totalPages != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: book.progress.clamp(0, 1),
                minHeight: 6,
                backgroundColor: AppColors.divider,
                color: book.status == 'completed' ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text('${book.pagesRead}/${book.totalPages} pages',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
          if (book.status != 'completed')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final pages = await showDialog<int>(
                    context: context,
                    builder: (_) => _UpdateProgressDialog(current: book.pagesRead),
                  );
                  if (pages != null) ref.read(booksProvider.notifier).updateProgress(book.id, pages);
                },
                child: const Text('Update progress'),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpdateProgressDialog extends StatefulWidget {
  final int current;
  const _UpdateProgressDialog({required this.current});
  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  late final _controller = TextEditingController(text: widget.current.toString());
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pages read'),
      content: TextField(controller: _controller, keyboardType: TextInputType.number, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, int.tryParse(_controller.text) ?? widget.current),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
