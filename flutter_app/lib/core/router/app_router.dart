import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/ai_coach/presentation/screens/ai_coach_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/books/presentation/screens/books_screen.dart';
import '../../features/challenges/presentation/screens/challenges_screen.dart';
import '../../features/focus/presentation/screens/focus_mode_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/habits/presentation/providers/habit_providers.dart';
import '../../features/habits/presentation/screens/add_edit_habit_screen.dart';
import '../../features/habits/presentation/screens/habit_detail_screen.dart';
import '../../features/habits/presentation/screens/habits_list_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/legacy/presentation/screens/legacy_screen.dart';
import '../../features/letters/presentation/screens/letters_screen.dart';
import '../../features/mood/presentation/screens/mood_tracker_screen.dart';
import '../../features/my_journey/presentation/screens/my_journey_screen.dart';
import '../../features/my_story/presentation/screens/my_story_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/skills/presentation/screens/skills_screen.dart';
import '../../features/time_machine/presentation/screens/time_machine_screen.dart';
import '../network/supabase_service.dart';

/// Bridges a Stream to GoRouter's `refreshListenable` so GoRouter can
/// re-run its `redirect` callback whenever auth state changes — WITHOUT
/// the whole GoRouter object being torn down and rebuilt. Rebuilding
/// GoRouter itself (e.g. via `ref.watch` inside the provider) resets its
/// internal navigation stack, which is what was bouncing users back to
/// /login right after a successful sign-in/sign-up.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = GoRouterRefreshStream(SupabaseService.auth.onAuthStateChange);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      // Read auth state fresh from Supabase directly (not from a Riverpod
      // snapshot) so this always reflects the true current session,
      // regardless of provider rebuild timing.
      final loggedIn = SupabaseService.currentUser != null;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';
      final onOnboarding = state.matchedLocation == '/onboarding';

      if (!loggedIn) {
        return loggingIn ? null : '/login';
      }

      // Logged in from here on. Check onboarding completion straight from
      // the database so a fresh sign-up can't land on a Home screen that
      // has no data yet.
      bool onboardingCompleted;
      try {
        final profile = await SupabaseService.client
            .from('user_profiles')
            .select('onboarding_completed')
            .eq('user_id', SupabaseService.currentUser!.id)
            .maybeSingle();
        onboardingCompleted = profile?['onboarding_completed'] == true;
      } catch (_) {
        return null; // fail open rather than stranding the user
      }

      if (!onboardingCompleted) {
        return onOnboarding ? null : '/onboarding';
      }

      if (loggingIn || onOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/coach', builder: (context, state) => const AiCoachScreen()),
      GoRoute(path: '/journal', builder: (context, state) => const JournalScreen()),
      GoRoute(path: '/mood', builder: (context, state) => const MoodTrackerScreen()),
      GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen()),
      GoRoute(path: '/focus', builder: (context, state) => const FocusModeScreen()),
      GoRoute(path: '/achievements', builder: (context, state) => const AchievementsScreen()),
      GoRoute(path: '/books', builder: (context, state) => const BooksScreen()),
      GoRoute(path: '/challenges', builder: (context, state) => const ChallengesScreen()),
      GoRoute(path: '/legacy', builder: (context, state) => const LegacyScreen()),
      GoRoute(path: '/letters', builder: (context, state) => const LettersScreen()),
      GoRoute(path: '/my-journey', builder: (context, state) => const MyJourneyScreen()),
      GoRoute(path: '/my-story', builder: (context, state) => const MyStoryScreen()),
      GoRoute(path: '/skills', builder: (context, state) => const SkillsScreen()),
      GoRoute(path: '/time-machine', builder: (context, state) => const TimeMachineScreen()),
      GoRoute(path: '/habits', builder: (context, state) => const HabitsListScreen()),
      GoRoute(path: '/habits/add', builder: (context, state) => const AddEditHabitScreen()),
      GoRoute(
        path: '/habits/:id',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final habits = ref.watch(habitsProvider).valueOrNull ?? [];
              final habit = habits.where((h) => h.id == state.pathParameters['id']).firstOrNull;
              if (habit == null) {
                return const HabitsListScreen();
              }
              return HabitDetailScreen(habit: habit);
            },
          );
        },
      ),
    ],
  );
});
