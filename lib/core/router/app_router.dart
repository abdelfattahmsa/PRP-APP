import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../shared/screens/shell_screen.dart';
import '../../features/overview/screens/overview_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/finance/screens/finance_screen.dart';
import '../../features/habits/screens/habits_screen.dart';
import '../../features/goals/screens/goals_screen.dart';
import '../../features/focus/screens/focus_screen.dart';
// ForgotPasswordScreen is in signup_screen.dart (exported via forgot_password_screen.dart)
import '../../features/auth/screens/signup_screen.dart' show ForgotPasswordScreen;

class Routes {
  static const login          = '/login';
  static const signup         = '/signup';
  static const forgotPassword = '/forgot-password';
  static const overview       = '/overview';
  static const schedule       = '/schedule';
  static const calendar       = '/calendar';
  static const finance        = '/finance';
  static const habits         = '/habits';
  static const goals          = '/goals';
  static const focus          = '/focus';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: Routes.overview,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/forgot');
      if (!isLoggedIn && !isAuthRoute) return Routes.login;
      if (isLoggedIn && isAuthRoute) return Routes.overview;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login,          builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.signup,         builder: (_, __) => const SignupScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(child: child, location: state.matchedLocation),
        routes: [
          GoRoute(path: Routes.overview,  builder: (_, __) => const OverviewScreen()),
          GoRoute(path: Routes.schedule,  builder: (_, __) => const ScheduleScreen(),
            routes: [
              GoRoute(path: 'edit-block', builder: (_, state) => EditBlockScreen(
                blockId: state.uri.queryParameters['id'],
                scheduleMode: state.uri.queryParameters['mode'] ?? 'normal',
              )),
            ],
          ),
          GoRoute(path: Routes.calendar, builder: (_, __) => const CalendarScreen(),
            routes: [
              GoRoute(path: 'event', builder: (_, state) => EventDetailScreen(
                eventId: state.uri.queryParameters['id'],
                initialDate: state.uri.queryParameters['date'] != null
                    ? DateTime.tryParse(state.uri.queryParameters['date']!)
                    : null,
              )),
            ],
          ),
          GoRoute(path: Routes.finance, builder: (_, __) => const FinanceScreen()),
          GoRoute(path: Routes.habits,  builder: (_, __) => const HabitsScreen()),
          GoRoute(path: Routes.goals,   builder: (_, __) => const GoalsScreen()),
          GoRoute(path: Routes.focus,   builder: (_, __) => const FocusScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF09080D),
      body: Center(child: Text('Not found: ${state.error}', style: const TextStyle(color: Colors.white70))),
    ),
  );
});
