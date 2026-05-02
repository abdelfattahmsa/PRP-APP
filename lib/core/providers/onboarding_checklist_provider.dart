import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/models/all_providers.dart';
import '../router/app_router.dart';

// ══════════════════════════════════════════════════════════════
// ONBOARDING CHECKLIST
// Auto-detects completion from live providers so items turn green
// the moment the user completes them — no manual tracking needed.
// ══════════════════════════════════════════════════════════════

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.isDone,
  });
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final bool isDone;
}

final checklistProvider = Provider<List<ChecklistItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  final summary = ref.watch(financeSummaryProvider);
  final schedule = ref.watch(scheduleProvider('normal')).value ?? [];
  final goals = ref.watch(goalsProvider).value ?? [];
  final habits = ref.watch(habitsProvider).value ?? [];
  final sessions = ref.watch(focusSessionsProvider).value ?? [];

  // Has an account if any financial balance is tracked
  final hasAccount = summary.totalCurrent != 0.0 ||
      summary.totalSavings != 0.0 ||
      summary.totalDebt != 0.0;

  return [
    ChecklistItem(
      id: 'profile',
      title: 'Complete your profile',
      subtitle: 'Add your name and avatar photo',
      route: Routes.profileSettings,
      icon: Icons.person_outline_rounded,
      isDone: user?.fullName?.isNotEmpty == true,
    ),
    ChecklistItem(
      id: 'account',
      title: 'Add a bank account',
      subtitle: 'Track your balances in Finance',
      route: Routes.financeAccounts,
      icon: Icons.account_balance_outlined,
      isDone: hasAccount,
    ),
    ChecklistItem(
      id: 'schedule',
      title: 'Create your first schedule',
      subtitle: 'Plan a day with time blocks',
      route: Routes.timeSchedule,
      icon: Icons.view_timeline_outlined,
      isDone: schedule.isNotEmpty,
    ),
    ChecklistItem(
      id: 'goal',
      title: 'Set an active goal',
      subtitle: 'Track what you want to achieve',
      route: Routes.energyGoals,
      icon: Icons.flag_outlined,
      isDone: goals.isNotEmpty,
    ),
    ChecklistItem(
      id: 'habit',
      title: 'Track your first habit',
      subtitle: 'Build consistency day by day',
      route: Routes.healthHabits,
      icon: Icons.check_circle_outline_rounded,
      isDone: habits.isNotEmpty,
    ),
    ChecklistItem(
      id: 'focus',
      title: 'Complete a focus session',
      subtitle: 'Try the Pomodoro timer',
      route: Routes.energyFocus,
      icon: Icons.timer_outlined,
      isDone: sessions.any((s) => s.completed),
    ),
  ];
});

// ── Dismissed state ────────────────────────────────────────────

const _prefChecklistDismissed = 'onboarding_checklist_dismissed';

class ChecklistDismissedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefChecklistDismissed) ?? false;
  }

  Future<void> dismiss() async {
    state = const AsyncData(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefChecklistDismissed, true);
  }
}

final checklistDismissedProvider =
    AsyncNotifierProvider<ChecklistDismissedNotifier, bool>(
        ChecklistDismissedNotifier.new);
