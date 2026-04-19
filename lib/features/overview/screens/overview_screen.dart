import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

// Ticks every second for the live clock
final _clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final currentUser = ref.watch(currentUserProvider);
    final now = ref.watch(_clockProvider).value ?? DateTime.now();
    final summary = ref.watch(financeSummaryProvider);
    final habitsToday = ref.watch(habitsTodayProvider);
    final sessAsync = ref.watch(focusSessionsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final habitsAsync = ref.watch(habitsProvider);

    // Computed today's focus minutes
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayFocusMin = sessAsync.value
            ?.where((s) =>
                s.completed &&
                DateFormat('yyyy-MM-dd').format(s.date) == todayStr)
            .fold(0, (s, sess) => s + sess.actualMinutes) ??
        0;

    final activeGoals =
        goalsAsync.value?.where((g) => g.status == 'active').length ?? 0;

    final netWorth =
        summary.totalSavings + summary.totalCurrent - summary.totalDebt;
    final fmt = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _GreetingHeader(user: currentUser, now: now, textSecondary: textSecondary),
            const Gap(24),

            // ── KPI Grid ─────────────────────────────────────────
            BentoGrid(
              children: [
                BentoCell(
                  child: KpiCard(
                    label: 'Net Worth',
                    value: 'EGP ${fmt.format(netWorth)}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.success,
                    subtitle: 'Today −${fmt.format(summary.todaySpend)}',
                    onTap: () => context.go(Routes.financeOverview),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Habits Today',
                    value: '${habitsToday.done} / ${habitsToday.total}',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.accent,
                    subtitle:
                        '${(habitsToday.pct * 100).toStringAsFixed(0)}% done',
                    trend: habitsToday.done == habitsToday.total &&
                            habitsToday.total > 0
                        ? 'All done!'
                        : null,
                    trendUp: true,
                    onTap: () => context.go(Routes.healthHabits),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Focus Today',
                    value: '${todayFocusMin}m',
                    icon: Icons.timer_rounded,
                    iconColor: AppColors.warning,
                    subtitle: sessAsync.isLoading ? 'Loading...' : null,
                    onTap: () => context.go(Routes.energyFocus),
                  ),
                ),
                BentoCell(
                  child: KpiCard(
                    label: 'Active Goals',
                    value: '$activeGoals',
                    icon: Icons.flag_rounded,
                    iconColor: AppColors.pmp,
                    subtitle: goalsAsync.isLoading ? 'Loading...' : null,
                    onTap: () => context.go(Routes.energyGoals),
                  ),
                ),
              ],
            ),
            const Gap(24),

            // ── Today's Habits ────────────────────────────────────
            BentoSectionHeader(
              "Today's Habits",
              action: TextButton(
                onPressed: () => context.go(Routes.healthHabits),
                child: const Text('All habits',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            habitsAsync.when(
              loading: () => const LoadingCard(height: 80),
              error: (e, _) => const ErrorState(message: 'Could not load habits'),
              data: (habits) {
                if (habits.isEmpty) {
                  return EmptyState(
                    message: 'No habits yet — add your first habit',
                    icon: Icons.star_outline_rounded,
                    compact: true,
                    action: TextButton(
                      onPressed: () => context.go(Routes.healthHabits),
                      child: const Text('Go to Habits'),
                    ),
                  );
                }
                final visible = habits.take(4).toList();
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < visible.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.border
                                  : AppColors.lightBorder),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.base, vertical: 10),
                          child: Row(children: [
                            Text(visible[i].icon,
                                style: const TextStyle(fontSize: 20)),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                visible[i].name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      decoration: visible[i].isDoneToday
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: visible[i].isDoneToday
                                          ? textSecondary
                                          : null,
                                    ),
                              ),
                            ),
                            Icon(
                              visible[i].isDoneToday
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 20,
                              color: visible[i].isDoneToday
                                  ? AppColors.success
                                  : textSecondary,
                            ),
                          ]),
                        ),
                      ],
                      if (habits.length > 4) ...[
                        Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.border
                                : AppColors.lightBorder),
                        TextButton(
                          onPressed: () => context.go(Routes.healthHabits),
                          child: Text(
                            '+${habits.length - 4} more',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Gap(24),

            // ── Quick Actions ─────────────────────────────────────
            const BentoSectionHeader('Quick Actions'),
            const Gap(12),
            _QuickActions(textSecondary: textSecondary),
            const Gap(24),

            // ── Active Goals ──────────────────────────────────────
            BentoSectionHeader(
              'Active Goals',
              action: TextButton(
                onPressed: () => context.go(Routes.energyGoals),
                child: const Text('All goals', style: TextStyle(fontSize: 12)),
              ),
            ),
            const Gap(12),
            goalsAsync.when(
              loading: () => const LoadingCard(height: 100),
              error: (e, _) =>
                  const ErrorState(message: 'Could not load goals'),
              data: (goals) {
                final active =
                    goals.where((g) => g.status == 'active').take(3).toList();
                if (active.isEmpty) {
                  return EmptyState(
                    message: 'No active goals',
                    icon: Icons.flag_outlined,
                    compact: true,
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < active.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.border
                                  : AppColors.lightBorder),
                        Padding(
                          padding: const EdgeInsets.all(Spacing.base),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      active[i].title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    '${active[i].progress}%',
                                    style: TextStyle(
                                      fontFamily: 'IBMPlexMono',
                                      fontSize: 13,
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: active[i].progress / 100,
                                  minHeight: 4,
                                  backgroundColor: isDark
                                      ? AppColors.border
                                      : AppColors.lightBorder,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppColors.accent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.textSecondary});
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    const actions = [
      ('Log Expense', Icons.add_circle_rounded, AppColors.error,
          Routes.financeTransactions),
      ('Start Focus', Icons.timer_rounded, AppColors.warning,
          Routes.energyFocus),
      ('Log Habit', Icons.check_circle_rounded, AppColors.accent,
          Routes.healthHabits),
      ('Add Event', Icons.event_rounded, AppColors.pmp, Routes.timeCalendar),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: Spacing.sm,
      mainAxisSpacing: Spacing.sm,
      childAspectRatio: 2.8,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () => context.go(a.$4),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.sm),
            decoration: BoxDecoration(
              color: a.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: a.$3.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(a.$2, size: 18, color: a.$3),
                const Gap(8),
                Expanded(
                  child: Text(
                    a.$1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: a.$3,
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Greeting Header with live clock ───────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.user,
    required this.now,
    required this.textSecondary,
  });

  final dynamic user; // AppUser?
  final DateTime now;
  final Color textSecondary;

  String get _greeting {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (user?.fullName as String?)?.split(' ').first ?? 'there';
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('EEEE, d MMM');
    final tz = now.timeZoneName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, $firstName',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Gap(4),
              Text(
                dateFmt.format(now),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeFmt.format(now),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'IBMPlexMono',
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
            ),
            const Gap(2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tz,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontFamily: 'IBMPlexMono',
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
