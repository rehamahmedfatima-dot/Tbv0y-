import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/habits/presentation/providers/habit_providers.dart';
import '../../features/habits/presentation/screens/add_edit_habit_screen.dart';
import '../../features/habits/presentation/screens/habit_detail_screen.dart';
import '../../features/habits/presentation/screens/habits_list_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

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
