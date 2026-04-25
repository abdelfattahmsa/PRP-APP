import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/health/data/models/health_models.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chart.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader, SectionHeader;

class HealthDailyProgressScreen extends ConsumerWidget {
  const HealthDailyProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final habitsAsync = ref.watch(habitsProvider);
    final todayStats = ref.watch(habitsTodayProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 7-day completion data
    final days7 = List.generate(
        7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    final dayLabels = days7
        .map((d) => DateFormat('EEE').format(d).substring(0, 1))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => ErrorState(
              message: 'Failed to load progress',
              onRetry: () => ref.invalidate(habitsProvider)),
          data: (habits) {
            final active = habits.where((h) => !h.isArchived).toList();

            final completionData = days7.map((day) {
              if (active.isEmpty) return 0.0;
              final done = active.where((h) => h.isDoneOn(day)).length;
              return (done / active.length) * 100;
            }).toList();

            // Best current streak across all habits
            final bestStreak = active.isEmpty
                ? 0
                : active
                    .map((h) => h.calculateStreak())
                    .reduce((a, b) => a > b ? a : b);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                const ScreenHeader(
                  title: 'Daily Progress',
                  subtitle: "Track today's health milestones",
                ),
                const Gap(24),

                // ── Stats ─────────────────────────────────────
                BentoGrid(
                  children: [
                    BentoCell(
                      child: KpiCard(
                        label: 'Completed',
                        value: '${todayStats.done} / ${todayStats.total}',
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                        subtitle: 'Tasks done',
                        trend: todayStats.total > 0
                            ? '+${todayStats.done}'
                            : null,
                        trendUp: true,
                      ),
                    ),
                    BentoCell(
                      child: KpiCard(
                        label: 'Daily Score',
                        value:
                            '${(todayStats.pct * 100).toStringAsFixed(0)}%',
                        icon: Icons.star_rounded,
                        iconColor: AppColors.gold,
                        subtitle: todayStats.pct >= 1.0
                            ? 'Perfect day! 🎉'
                            : todayStats.pct >= 0.5
                                ? 'On track'
                                : 'Keep going',
                      ),
                    ),
                  ],
                ),
                const Gap(20),

                // ── Streak Card ───────────────────────────────
                if (active.isNotEmpty) ...[
                  SectionHeader('Current Streak'),
                  const Gap(12),
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.error,
                              size: 28),
                        ),
                        const Gap(Spacing.base),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$bestStreak-Day Streak',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const Gap(4),
                              Text(
                                'Keep going! Best: ${active.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b)}d',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$bestStreak',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: AppColors.error,
                                    ),
                            ),
                            Text(
                              'days',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),
                ],

                // ── Today's Checklist ─────────────────────────
                SectionHeader("Today's Checklist"),
                const Gap(12),
                if (active.isEmpty)
                  EmptyState(
                    message: 'No habits yet — add them in the Habits tab',
                    icon: Icons.checklist_rounded,
                    compact: true,
                  )
                else
                  AppCard(
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
                          _ChecklistTile(
                            habit: active[i],
                            dateKey: todayStr,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                const Gap(20),

                // ── 7-Day chart ───────────────────────────────
                ChartCard(
                  title: '7-Day Progress',
                  height: 130,
                  child: AppBarChart(
                    data: completionData,
                    labels: dayLabels,
                    maxY: 100,
                    colors: completionData
                        .map((v) =>
                            v >= 80 ? AppColors.success : AppColors.accent)
                        .toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChecklistTile extends ConsumerWidget {
  const _ChecklistTile({
    required this.habit,
    required this.dateKey,
    required this.textSecondary,
  });

  final Habit habit;
  final String dateKey;
  final Color textSecondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = habit.isDoneToday;
    return InkWell(
      onTap: () =>
          ref.read(habitsProvider.notifier).toggle(habit.id, dateKey),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.base, vertical: 2),
        leading: Text(habit.icon, style: const TextStyle(fontSize: 20)),
        title: Text(
          habit.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? textSecondary : null,
              ),
        ),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            key: ValueKey(isDone),
            color: isDone ? AppColors.success : textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
