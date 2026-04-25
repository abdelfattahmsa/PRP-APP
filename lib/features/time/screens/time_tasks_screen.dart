import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/app_card.dart';

import '../../../shared/widgets/placeholders.dart' show ScreenHeader;

enum _TaskSource { all, goals, habits }

class TimeTasksScreen extends ConsumerStatefulWidget {
  const TimeTasksScreen({super.key});

  @override
  ConsumerState<TimeTasksScreen> createState() => _TimeTasksScreenState();
}

class _TimeTasksScreenState extends ConsumerState<TimeTasksScreen> {
  _TaskSource _filter = _TaskSource.all;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final goalsAsync = ref.watch(goalsProvider);
    final habitsAsync = ref.watch(habitsProvider);

    final goals = goalsAsync.value ?? [];
    final habits = habitsAsync.value ?? [];

    final activeGoals =
        goals.where((g) => g.status == 'active').toList()
          ..sort((a, b) {
            const rank = {'high': 0, 'medium': 1, 'low': 2};
            return (rank[a.priority] ?? 1).compareTo(rank[b.priority] ?? 1);
          });
    final activeHabits =
        habits.where((h) => !h.isArchived).toList();

    final isLoading = goalsAsync.isLoading || habitsAsync.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: ScreenHeader(
                title: 'Tasks',
                subtitle: 'Goals and habits as actionable tasks',
              ),
            ),
            const Gap(16),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    count: activeGoals.length + activeHabits.length,
                    selected: _filter == _TaskSource.all,
                    onTap: () => setState(() => _filter = _TaskSource.all),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Goals',
                    count: activeGoals.length,
                    selected: _filter == _TaskSource.goals,
                    color: AppColors.pmp,
                    onTap: () => setState(() => _filter = _TaskSource.goals),
                  ),
                  const Gap(8),
                  _FilterChip(
                    label: 'Habits',
                    count: activeHabits.length,
                    selected: _filter == _TaskSource.habits,
                    color: AppColors.health,
                    onTap: () => setState(() => _filter = _TaskSource.habits),
                  ),
                ],
              ),
            ),
            const Gap(16),

            if (isLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    // ── Goals ───────────────────────────────────────
                    if (_filter != _TaskSource.habits && activeGoals.isNotEmpty) ...[
                      _SectionLabel(
                          '🎯 Goals (${activeGoals.length})', textSecondary),
                      const Gap(8),
                      ...activeGoals.map((g) => _GoalTaskCard(
                            goal: g,
                            textSecondary: textSecondary,
                            ref: ref,
                          )),
                      const Gap(16),
                    ],

                    // ── Habits ──────────────────────────────────────
                    if (_filter != _TaskSource.goals && activeHabits.isNotEmpty) ...[
                      _SectionLabel(
                          '🔁 Habits (${activeHabits.length})',
                          textSecondary),
                      const Gap(8),
                      ...activeHabits.map((h) => _HabitTaskCard(
                            habit: h,
                            textSecondary: textSecondary,
                            ref: ref,
                          )),
                      const Gap(16),
                    ],

                    if (activeGoals.isEmpty && activeHabits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.task_alt_rounded,
                                  size: 48, color: textSecondary),
                              const Gap(12),
                              Text('No active tasks',
                                  style: TextStyle(color: textSecondary)),
                              const Gap(4),
                              Text(
                                'Add goals or habits to see them here',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final active = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? active.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
              color: selected ? active : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label  $count',
          style: TextStyle(
            color: selected ? active : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, color: color),
      );
}

class _GoalTaskCard extends StatelessWidget {
  const _GoalTaskCard(
      {required this.goal,
      required this.textSecondary,
      required this.ref});
  final dynamic goal;
  final Color textSecondary;
  final WidgetRef ref;

  Color _priorityColor() {
    switch (goal.priority as String) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final daysLeft =
        (goal.targetDate as DateTime).difference(DateTime.now()).inDays;
    final overdue = daysLeft < 0;
    final progress = goal.progress as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (goal.priority as String).toUpperCase(),
                      style: TextStyle(
                          color: _priorityColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      goal.title as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Text(
                    overdue
                        ? '⚠️ ${-daysLeft}d overdue'
                        : fmt.format(goal.targetDate as DateTime),
                    style: TextStyle(
                        color: overdue ? AppColors.error : textSecondary,
                        fontSize: 12,
                        fontWeight:
                            overdue ? FontWeight.w600 : FontWeight.normal),
                  ),
                ],
              ),
              if ((goal.description as String?)?.isNotEmpty == true) ...[
                const Gap(6),
                Text(
                  goal.description as String,
                  style: TextStyle(color: textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Gap(10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 5,
                        backgroundColor:
                            AppColors.pmp.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.pmp),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Text('$progress%',
                      style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontFamily: 'IBMPlexMono')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitTaskCard extends StatelessWidget {
  const _HabitTaskCard(
      {required this.habit,
      required this.textSecondary,
      required this.ref});
  final dynamic habit;
  final Color textSecondary;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDone = habit.isDoneToday as bool;
    final streak = habit.streak as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: isDone
            ? null
            : () => ref.read(habitsProvider.notifier).toggle(
                  habit.id as String,
                  DateFormat('yyyy-MM-dd').format(DateTime.now())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.health.withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border.all(
                      color: isDone
                          ? AppColors.health
                          : AppColors.border,
                      width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: AppColors.health)
                    : null,
              ),
              const Gap(14),
              Expanded(
                child: Text(
                  habit.name as String,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isDone ? textSecondary : null),
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.health.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔥 $streak',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.health,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
