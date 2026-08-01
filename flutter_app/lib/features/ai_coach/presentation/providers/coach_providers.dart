import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_coach_repository.dart';
import '../../domain/coach_message.dart';
import '../../domain/coach_repository.dart';

final coachRepositoryProvider = Provider<CoachRepository>((ref) => SupabaseCoachRepository());

final todayConversationProvider = FutureProvider<CoachConversation>((ref) {
  return ref.watch(coachRepositoryProvider).getOrCreateTodayConversation();
});

class ChatController extends StateNotifier<AsyncValue<List<CoachMessage>>> {
  ChatController(this._repo, this.conversationId) : super(const AsyncValue.loading()) {
    _load();
  }

  final CoachRepository _repo;
  final String conversationId;
  bool sending = false;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _repo.loadMessages(conversationId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty || sending) return;
    sending = true;

    // Optimistic append so the UI feels instant.
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      ...current,
      CoachMessage(
        id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
        conversationId: conversationId,
        isUser: true,
        content: text,
        createdAt: DateTime.now(),
      ),
    ]);

    try {
      final reply = await _repo.sendMessage(conversationId: conversationId, userText: text);
      state = AsyncValue.data([...state.valueOrNull ?? [], reply]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      sending = false;
    }
  }
}

final chatControllerProvider =
    StateNotifierProvider.family<ChatController, AsyncValue<List<CoachMessage>>, String>(
  (ref, conversationId) => ChatController(ref.watch(coachRepositoryProvider), conversationId),
);
