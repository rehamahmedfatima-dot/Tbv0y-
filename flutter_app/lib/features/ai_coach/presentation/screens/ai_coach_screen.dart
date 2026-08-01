import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/coach_message.dart';
import '../providers/coach_providers.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(todayConversationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              final repo = ref.read(coachRepositoryProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating…')),
              );
              if (value == 'weekly') {
                await repo.generateWeeklyReview();
              } else if (value == 'monthly') {
                await repo.generateMonthlyReport();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Check your reports — it\'s ready.')),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'weekly', child: Text('Generate Weekly Review')),
              PopupMenuItem(value: 'monthly', child: Text('Generate Monthly Report')),
            ],
          ),
        ],
      ),
      body: conversationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not start chat: $e')),
        data: (conversation) => _ChatBody(
          conversationId: conversation.id,
          inputController: _inputController,
          scrollController: _scrollController,
          onSent: _scrollToBottom,
        ),
      ),
    );
  }
}

class _ChatBody extends ConsumerWidget {
  final String conversationId;
  final TextEditingController inputController;
  final ScrollController scrollController;
  final VoidCallback onSent;

  const _ChatBody({
    required this.conversationId,
    required this.inputController,
    required this.scrollController,
    required this.onSent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatControllerProvider(conversationId));
    final controller = ref.read(chatControllerProvider(conversationId).notifier);

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Something went wrong: $e')),
            data: (messages) {
              if (messages.isEmpty) {
                return const _EmptyChatState();
              }
              onSent();
              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: messages.length,
                itemBuilder: (context, i) => _MessageBubble(message: messages[i]),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ask your coach anything…',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _SendButton(
                  onPressed: () {
                    final text = inputController.text;
                    if (text.trim().isEmpty) return;
                    inputController.clear();
                    controller.send(text);
                    onSent();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SendButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.primaryGradient),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final CoachMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isUser ? const LinearGradient(colors: AppColors.primaryGradient) : null,
          color: isUser ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusMd),
            topRight: const Radius.circular(AppSpacing.radiusMd),
            bottomLeft: Radius.circular(isUser ? AppSpacing.radiusMd : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppSpacing.radiusMd),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isUser ? Colors.white : null, height: 1.4),
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

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
              child: const Icon(Icons.auto_awesome_rounded, size: 48, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Your coach is ready', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Ask about your habits, get motivated, or just check in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
