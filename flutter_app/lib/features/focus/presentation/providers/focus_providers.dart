import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_focus_repository.dart';
import '../../domain/focus_repository.dart';
import '../../domain/focus_session.dart';

final focusRepositoryProvider = Provider<FocusRepository>((ref) => SupabaseFocusRepository());

final todayFocusMinutesProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(focusRepositoryProvider).todayFocusMinutes();
});

final recentFocusSessionsProvider = FutureProvider.autoDispose<List<FocusSession>>((ref) {
  return ref.watch(focusRepositoryProvider).loadRecentSessions();
});

enum TimerPhase { idle, running, paused, finished }

class FocusTimerState {
  final TimerPhase phase;
  final FocusSessionType type;
  final int totalSeconds;
  final int remainingSeconds;
  final String? sessionId;

  const FocusTimerState({
    this.phase = TimerPhase.idle,
    this.type = FocusSessionType.pomodoro,
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.sessionId,
  });

  FocusTimerState copyWith({
    TimerPhase? phase,
    FocusSessionType? type,
    int? totalSeconds,
    int? remainingSeconds,
    String? sessionId,
  }) {
    return FocusTimerState(
      phase: phase ?? this.phase,
      type: type ?? this.type,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class FocusTimerController extends StateNotifier<FocusTimerState> {
  FocusTimerController(this._repo) : super(const FocusTimerState());
  final FocusRepository _repo;

  void selectType(FocusSessionType type) {
    if (state.phase != TimerPhase.idle) return;
    final minutes = focusDurationsMinutes[type]!;
    state = FocusTimerState(type: type, totalSeconds: minutes * 60, remainingSeconds: minutes * 60);
  }

  Future<void> start() async {
    final id = await _repo.startSession(state.type, state.totalSeconds ~/ 60);
    state = state.copyWith(phase: TimerPhase.running, sessionId: id);
    _tick();
  }

  void pause() => state = state.copyWith(phase: TimerPhase.paused);
  void resume() {
    state = state.copyWith(phase: TimerPhase.running);
    _tick();
  }

  Future<void> _tick() async {
    while (state.phase == TimerPhase.running && state.remainingSeconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (state.phase != TimerPhase.running) return;
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    }
    if (state.remainingSeconds <= 0 && state.sessionId != null) {
      await _repo.endSession(state.sessionId!, completed: true, interrupted: false);
      state = state.copyWith(phase: TimerPhase.finished);
    }
  }

  Future<void> stopEarly() async {
    if (state.sessionId != null) {
      await _repo.endSession(state.sessionId!, completed: false, interrupted: true);
    }
    final minutes = focusDurationsMinutes[state.type]!;
    state = FocusTimerState(type: state.type, totalSeconds: minutes * 60, remainingSeconds: minutes * 60);
  }

  void reset() {
    final minutes = focusDurationsMinutes[state.type]!;
    state = FocusTimerState(type: state.type, totalSeconds: minutes * 60, remainingSeconds: minutes * 60);
  }
}

final focusTimerProvider = StateNotifierProvider<FocusTimerController, FocusTimerState>(
  (ref) => FocusTimerController(ref.watch(focusRepositoryProvider)),
);
