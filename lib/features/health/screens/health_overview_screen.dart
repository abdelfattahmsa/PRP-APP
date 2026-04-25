import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chart.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

class HealthOverviewScreen extends ConsumerWidget {
  const HealthOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final habitsAsync = ref.watch(habitsProvider);
    final todayStats = ref.watch(habitsTodayProvider);
    final fasting = ref.watch(fastingProvider);
    ref.watch(fastingTickProvider);

    final habits = habitsAsync.value ?? [];
    final activeHabits = habits.where((h) => !h.isArchived).toList();
    final topStreaks = [...activeHabits]
      ..sort((a, b) => b.streak.compareTo(a.streak));

    // 7-day habit completion data
    final days7 =
        List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    final dayLabels = days7
        .map((d) => DateFormat('EEE').format(d).substring(0, 1))
        .toList();
    final habitWeekData = days7.map((day) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      if (activeHabits.isEmpty) return 0.0;
      final done = activeHabits.where((h) => h.history[key] == true).length;
      return (done / activeHabits.length * 100).roundToDouble();
    }).toList();

    // 28-day heatmap (Mon–Sun aligned)
    final today = DateTime.now();
    final weekday = today.weekday; // 1=Mon … 7=Sun
    // Align to the last Monday
    final gridStart = today.subtract(Duration(days: weekday - 1 + 21));
    final heatmapRates = List.generate(28, (i) {
      final day = gridStart.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      if (activeHabits.isEmpty) return 0.0;
      final done = activeHabits.where((h) => h.history[key] == true).length;
      return done / activeHabits.length;
    });

    // Fasting display
    final elapsed = fasting.elapsed;
    final elapsedH = elapsed.inHours;
    final elapsedM = elapsed.inMinutes % 60;
    final goalH = fasting.active?.goalHours ?? fasting.goalHours;
    final fastPct =
        goalH > 0 ? (elapsed.inMinutes / (goalH * 60)).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            const ScreenHeader(
              title: 'Health',
              subtitle: 'Habits, fasting, and wellness',
            ),
            const Gap(24),

            // ── KPI Grid ──────────────────────────────────────────
            BentoGrid(
              children: [
                BentoCell(
                  span: 2,
                  child: KpiCard(
                    label: "Today's Habits",
                    value: '${todayStats.done} / ${todayStats.total}',
                    icon: Icons.checklist_rounded,
                    iconColor: AppColors.health,
                    subtitle: todayStats.total == 0
                        ? 'No habits set'
                        : '${(todayStats.pct * 100).round()}% complete',
                  ),
                ),
                BentoCell(
                  child: GestureDetector(
                    onTap: () => context.go(Routes.healthHabits),
                    child: KpiCard(
                      label: 'Active Habits',
                      value: '${activeHabits.length}',
                      icon: Icons.repeat_rounded,
                      iconColor: AppColors.success,
                    ),
                  ),
                ),
                BentoCell(
                  child: GestureDetector(
                    onTap: () => context.go(Routes.healthFasting),
                    child: KpiCard(
                      label: fasting.isFasting ? 'Fasting' : 'Last Fast',
                      value: fasting.isFasting
                          ? '${elapsedH}h ${elapsedM}m'
                          : fasting.history.isNotEmpty
                              ? '${fasting.history.last.duration.inHours}h'
                              : '—',
                      icon: Icons.timer_rounded,
                      iconColor: fasting.isFasting
                          ? AppColors.warning
                          : textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(20),

            // ── Habit Completion (7 days) ──────────────────────────
            if (activeHabits.isNotEmpty) ...[
              ChartCard(
                title: '7-Day Habit Completion %',
                height: 130,
                child: AppBarChart(
                  data: habitWeekData,
                  labels: dayLabels,
                  colors: List.filled(7, AppColors.health),
                ),
              ),
              const Gap(20),
              ChartCard(
                title: '28-Day Habit Heatmap',
                height: 110,
                child: HabitHeatmap(dailyRates: heatmapRates),
              ),
              const Gap(20),
            ],

            // ── Fasting card ──────────────────────────────────────
            GestureDetector(
              onTap: () => context.go(Routes.healthFasting),
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_rounded,
                              size: 18,
                              color: fasting.isFasting
                                  ? AppColors.warning
                                  : textSecondary),
                          const Gap(8),
                          Text(
                            fasting.isFasting
                                ? 'Fasting — ${elapsedH}h ${elapsedM}m'
                                : 'Intermittent Fasting',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const Spacer(),
                          Text('Manage →',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 12)),
                        ],
                      ),
                      if (fasting.isFasting) ...[
                        const Gap(12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fastPct,
                            minHeight: 6,
                            backgroundColor:
                                AppColors.warning.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(
                                fasting.active?.goalReached == true
                                    ? AppColors.success
                                    : AppColors.warning),
                          ),
                        ),
                        const Gap(6),
                        Text(
                          fasting.active?.goalReached == true
                              ? 'Goal reached! 🎉'
                              : 'Goal: ${goalH}h  ·  ${fasting.remaining.inHours}h ${fasting.remaining.inMinutes % 60}m remaining',
                          style:
                              TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ] else ...[
                        const Gap(8),
                        Text(
                          fasting.history.isNotEmpty
                              ? '${fasting.history.length} fasts recorded  ·  Tap to start a new fast'
                              : 'Tap to start tracking your fast',
                          style:
                              TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Gap(20),

            // ── Top streaks ────────────────────────────────────────
            if (topStreaks.isNotEmpty) ...[
              _SectionLabel('Top Streaks', textSecondary),
              const Gap(12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int i = 0;
                        i < topStreaks.take(5).length;
                        i++) ...[
                      if (i > 0)
                        Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.border
                                : AppColors.lightBorder),
                      _HabitStreakTile(
                          habit: topStreaks[i],
                          textSecondary: textSecondary),
                    ],
                  ],
                ),
              ),
              const Gap(20),
            ],

            // ── Quick nav ─────────────────────────────────────────
            _SectionLabel('Sections', textSecondary),
            const Gap(12),
            Row(children: [
              Expanded(
                child: _NavCard(
                  icon: Icons.repeat_rounded,
                  label: 'Habits',
                  color: AppColors.health,
                  onTap: () => context.go(Routes.healthHabits),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _NavCard(
                  icon: Icons.timer_rounded,
                  label: 'Fasting',
                  color: AppColors.warning,
                  onTap: () => context.go(Routes.healthFasting),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _NavCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Progress',
                  color: AppColors.success,
                  onTap: () => context.go(Routes.healthDailyProgress),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, color: color),
      );
}

class _HabitStreakTile extends StatelessWidget {
  const _HabitStreakTile(
      {required this.habit, required this.textSecondary});
  final dynamic habit;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.health.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (habit.name as String).isNotEmpty
                    ? (habit.name as String)[0].toUpperCase()
                    : '✅',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.health),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              habit.name as String,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.health.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🔥 ${habit.streak}d',
              style: const TextStyle(
                  color: AppColors.health,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const Gap(6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      );
}
