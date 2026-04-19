import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart'; // includes SignupScreen + ForgotPasswordScreen
import '../../shared/screens/shell_screen.dart';

// ── Tab 1: Overview ──
import '../../features/overview/screens/overview_screen.dart';

// ── Tab 2: Time ──
import '../../features/time/screens/time_overview_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';

// ── Tab 3: Finance ──
import '../../features/finance/screens/finance_overview_screen.dart';
import '../../features/finance/screens/finance_accounts_screen.dart';
import '../../features/finance/screens/finance_investments_screen.dart';
import '../../features/finance/screens/finance_liabilities_screen.dart';
import '../../features/finance/screens/finance_transactions_screen.dart';

// ── Tab 4: Energy ──
import '../../features/energy/screens/energy_overview_screen.dart';
import '../../features/focus/screens/focus_screen.dart';
import '../../features/goals/screens/goals_screen.dart';
import '../../features/ideas/screens/ideas_screen.dart';

// ── Tab 5: Health ──
import '../../features/health/screens/health_overview_screen.dart';
import '../../features/health/screens/health_daily_progress_screen.dart';
import '../../features/health/screens/health_fasting_screen.dart';
import '../../features/health/screens/health_habits_screen.dart';

// ── Tab 6: Profile ──
import '../../features/profile/screens/profile_settings_screen.dart';
import '../../features/profile/screens/profile_account_screen.dart';
import '../../features/profile/screens/profile_app_settings_screen.dart';

// ══════════════════════════════════════════════════════════════
// ROUTE CONSTANTS
// ══════════════════════════════════════════════════════════════
class Routes {
  // ── Auth ──
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';

  // ── Tab 1: Overview ──
  static const overview = '/overview';

  // ── Tab 2: Time ──
  static const timeOverview = '/time/overview';
  static const timeSchedule = '/time/schedule';
  static const timeCalendar = '/time/calendar';

  // ── Tab 3: Finance ──
  static const financeOverview = '/finance/overview';
  static const financeAccounts = '/finance/accounts';
  static const financeInvestments = '/finance/investments';
  static const financeLiabilities = '/finance/liabilities';
  static const financeTransactions = '/finance/transactions';

  // ── Tab 4: Energy ──
  static const energyOverview = '/energy/overview';
  static const energyFocus = '/energy/focus';
  static const energyGoals = '/energy/goals';
  static const energyIdeas = '/energy/ideas';

  // ── Tab 5: Health ──
  static const healthOverview = '/health/overview';
  static const healthDailyProgress = '/health/daily-progress';
  static const healthFasting = '/health/fasting';
  static const healthHabits = '/health/habits';

  // ── Tab 6: Profile ──
  static const profileSettings = '/profile/settings';
  static const profileAccount = '/profile/account';
  static const profileApp = '/profile/app';

  // ── Legacy aliases (redirect targets exist) ──
  static const schedule = timeSchedule;
  static const calendar = timeCalendar;
  static const focus = energyFocus;
  static const goals = energyGoals;
  static const settings = profileApp;
  static const habits = healthHabits;
}

// ══════════════════════════════════════════════════════════════
// ROUTER PROVIDER
// ══════════════════════════════════════════════════════════════
final routerProvider = Provider<GoRouter>((ref) {
  // authStateProvider is now a plain Provider<bool> (Clerk isSignedIn)
  final isLoggedIn = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.overview,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/login') ||
          loc.startsWith('/signup') ||
          loc.startsWith('/forgot');
      if (!isLoggedIn && !isAuthRoute) return Routes.login;
      if (isLoggedIn && isAuthRoute) return Routes.overview;
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(
          path: Routes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),

      // ── Shell (authenticated) ──────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(location: state.matchedLocation, child: child),
        routes: [
          // ── Tab 1: Overview ──────────────────────────────
          GoRoute(
            path: Routes.overview,
            builder: (_, __) => const OverviewScreen(),
          ),

          // ── Tab 2: Time ──────────────────────────────────
          GoRoute(path: '/time', redirect: (_, __) => Routes.timeOverview),
          GoRoute(
            path: Routes.timeOverview,
            builder: (_, __) => const TimeOverviewScreen(),
          ),
          GoRoute(
            path: Routes.timeSchedule,
            builder: (_, __) => const ScheduleScreen(),
            routes: [
              GoRoute(
                path: 'edit-block',
                builder: (_, state) => EditBlockScreen(
                  blockId: state.uri.queryParameters['id'],
                  scheduleMode:
                      state.uri.queryParameters['mode'] ?? 'normal',
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.timeCalendar,
            builder: (_, __) => const CalendarScreen(),
            routes: [
              GoRoute(
                path: 'event',
                builder: (_, state) => EventDetailScreen(
                  eventId: state.uri.queryParameters['id'],
                  initialDate: state.uri.queryParameters['date'] != null
                      ? DateTime.tryParse(
                          state.uri.queryParameters['date']!)
                      : null,
                ),
              ),
            ],
          ),

          // ── Tab 3: Finance ────────────────────────────────
          GoRoute(
              path: '/finance',
              redirect: (_, __) => Routes.financeOverview),
          GoRoute(
            path: Routes.financeOverview,
            builder: (_, __) => const FinanceOverviewScreen(),
          ),
          GoRoute(
            path: Routes.financeAccounts,
            builder: (_, __) => const FinanceAccountsScreen(),
          ),
          GoRoute(
            path: Routes.financeInvestments,
            builder: (_, __) => const FinanceInvestmentsScreen(),
          ),
          GoRoute(
            path: Routes.financeLiabilities,
            builder: (_, __) => const FinanceLiabilitiesScreen(),
          ),
          GoRoute(
            path: Routes.financeTransactions,
            builder: (_, __) => const FinanceTransactionsScreen(),
          ),

          // ── Tab 4: Energy ─────────────────────────────────
          GoRoute(
              path: '/energy', redirect: (_, __) => Routes.energyOverview),
          GoRoute(
            path: Routes.energyOverview,
            builder: (_, __) => const EnergyOverviewScreen(),
          ),
          GoRoute(
            path: Routes.energyFocus,
            builder: (_, __) => const FocusScreen(),
          ),
          GoRoute(
            path: Routes.energyGoals,
            builder: (_, __) => const GoalsScreen(),
          ),
          GoRoute(
            path: Routes.energyIdeas,
            builder: (_, __) => const IdeasScreen(),
          ),
          // Legacy redirect: habits moved to Health
          GoRoute(
              path: '/energy/habits',
              redirect: (_, __) => Routes.healthHabits),

          // ── Tab 5: Health ─────────────────────────────────
          GoRoute(
              path: '/health', redirect: (_, __) => Routes.healthOverview),
          GoRoute(
            path: Routes.healthOverview,
            builder: (_, __) => const HealthOverviewScreen(),
          ),
          GoRoute(
            path: Routes.healthDailyProgress,
            builder: (_, __) => const HealthDailyProgressScreen(),
          ),
          GoRoute(
            path: Routes.healthFasting,
            builder: (_, __) => const HealthFastingScreen(),
          ),
          GoRoute(
            path: Routes.healthHabits,
            builder: (_, __) => const HealthHabitsScreen(),
          ),

          // ── Tab 6: Profile ────────────────────────────────
          GoRoute(
              path: '/profile',
              redirect: (_, __) => Routes.profileSettings),
          GoRoute(
            path: Routes.profileSettings,
            builder: (_, __) => const ProfileSettingsScreen(),
          ),
          GoRoute(
            path: Routes.profileAccount,
            builder: (_, __) => const ProfileAccountScreen(),
          ),
          GoRoute(
            path: Routes.profileApp,
            builder: (_, __) => const ProfileAppSettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF08070C),
      body: Center(
        child: Text(
          'Not found: ${state.error}',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    ),
  );
});
