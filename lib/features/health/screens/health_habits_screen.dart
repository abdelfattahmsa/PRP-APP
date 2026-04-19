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
import '../../../shared/widgets/bottom_sheets.dart';
import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

class HealthHabitsScreen extends ConsumerWidget {
  const HealthHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final habitsAsync = ref.watch(habitsProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => ErrorState(
              message: 'Failed to load habits',
              onRetry: () => ref.invalidate(habitsProvider)),
          data: (habits) {
            final active = habits.where((h) => !h.isArchived).toList();
            final done = active.where((h) => h.isDoneToday).length;
            final pct = active.isEmpty ? 0.0 : done / active.length;

            final days7 = List.generate(
                7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
            final completionData = days7.map((day) {
              if (active.isEmpty) return 0.0;
              final dayDone =
                  active.where((h) => h.isDoneOn(day)).length;
              return (dayDone / active.length) * 100;
            }).toList();
            final dayLabels = days7
                .map((d) => DateFormat('EEE').format(d).substring(0, 1))
                .toList();

            final bestStreak = active.isEmpty
                ? 0
                : active
                    .map((h) => h.longestStreak)
                    .reduce((a, b) => a > b ? a : b);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                const ScreenHeader(
                  title: 'Habits',
                  subtitle: 'Build consistency, one day at a time',
                ),
                const Gap(24),

                BentoGrid(
                  children: [
                    BentoCell(
                      child: KpiCard(
                        label: 'Done Today',
                        value: '$done / ${active.length}',
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                        subtitle:
                            '${(pct * 100).toStringAsFixed(0)}% complete',
                      ),
                    ),
                    BentoCell(
                      child: KpiCard(
                        label: 'Best Streak',
                        value: '${bestStreak}d',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.error,
                        subtitle: 'All time',
                      ),
                    ),
                  ],
                ),
                const Gap(20),

                ChartCard(
                  title: '7-Day Completion %',
                  height: 130,
                  child: AppBarChart(
                    data: completionData,
                    labels: dayLabels,
                    maxY: 100,
                  ),
                ),
                const Gap(20),

                BentoSectionHeader(
                  "Today's Habits",
                  action: TextButton.icon(
                    onPressed: () => showAddHabit(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('New', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const Gap(12),

                if (active.isEmpty)
                  EmptyState(
                    message:
                        'No habits yet.\nTap "+ New" to create your first.',
                    icon: Icons.star_outline_rounded,
                    action: FilledButton.icon(
                      onPressed: () => showAddHabit(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Create habit'),
                    ),
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
                          _HabitTile(
                            habit: active[i],
                            dateKey: todayStr,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddHabit(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New habit',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  const _HabitTile({
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.base, vertical: 12),
        child: Row(
          children: [
            Text(habit.icon, style: const TextStyle(fontSize: 22)),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? textSecondary : null,
                        ),
                  ),
                  if (habit.streak > 0)
                    Text(
                      '🔥 ${habit.streak}d streak',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'IBMPlexMono',
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(isDone),
                color: isDone ? AppColors.success : textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
