import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/ai_coach/presentation/screens/ai_coach_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull != null;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/home';
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
      GoRoute(path: '/challenges', builder: (context, state) => const ChallengesScreen()),
      GoRoute(path: '/legacy', builder: (context, state) => const LegacyScreen()),
      GoRoute(path: '/time-machine', builder: (context, state) => const TimeMachineScreen()),
      GoRoute(path: '/my-journey', builder: (context, state) => const MyJourneyScreen()),
      GoRoute(path: '/my-story', builder: (context, state) => const MyStoryScreen()),
      GoRoute(path: '/books', builder: (context, state) => const BooksScreen()),
      GoRoute(path: '/skills', builder: (context, state) => const SkillsScreen()),
      GoRoute(path: '/letters', builder: (context, state) => const LettersScreen()),
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
                // Data not loaded yet (e.g. deep link) — fall back to the list.
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
