import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class HealthHabitsScreen extends StatelessWidget {
  const HealthHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Habits',
              subtitle: 'Build consistency with daily habits',
            ),
            const Gap(24),

            const SectionHeader('Today'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: "Today's Habits",
                value: '6 / 10',
                subtitle: 'Completed',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
                trend: '+1 vs yesterday',
                trendUp: true,
              ),
              StatCard(
                label: 'Completion Rate',
                value: '60%',
                subtitle: 'Today',
                icon: Icons.pie_chart_rounded,
              ),
              StatCard(
                label: 'Best Streak',
                value: '21 days',
                subtitle: 'Morning Prayer',
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.gold,
              ),
              StatCard(
                label: 'Active Habits',
                value: '10',
                subtitle: 'Tracking',
                icon: Icons.list_alt_rounded,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Weekly Completion', action: '4 Weeks'),
            const Gap(12),
            PlaceholderChart(
              height: 140,
              label: 'Completion %',
              data: const [55, 70, 65, 80, 72, 68, 60],
            ),
            const Gap(24),

            const SectionHeader("Today's Habits", action: '+ Add'),
            const Gap(12),
            _HabitList(
              cardColor: cardColor,
              borderColor: borderColor,
              textSecondary: textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitList extends StatelessWidget {
  const _HabitList({
    required this.cardColor,
    required this.borderColor,
    required this.textSecondary,
  });
  final Color cardColor;
  final Color borderColor;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    const habits = [
      ('Morning Prayer (Fajr)', true, Icons.mosque_rounded, AppColors.deen, '12 day streak'),
      ('30-min Exercise', true, Icons.fitness_center_rounded, AppColors.health, '5 day streak'),
      ('Cold Shower', true, Icons.shower_rounded, AppColors.cfi, '3 day streak'),
      ('Read Quran', true, Icons.menu_book_rounded, AppColors.deen, '7 day streak'),
      ('Take Vitamins', true, Icons.medication_rounded, AppColors.success, '14 day streak'),
      ('Drink 8 Glasses', false, Icons.water_drop_rounded, AppColors.cfi, '0 / 8 today'),
      ('No Social Media AM', true, Icons.phone_locked_rounded, AppColors.kyberia, '4 day streak'),
      ('Gratitude Journal', false, Icons.edit_note_rounded, AppColors.pmp, 'Not logged'),
      ('Evening Walk', false, Icons.directions_walk_rounded, AppColors.health, '0 min today'),
      ('Sleep by 23:00', false, Icons.bedtime_rounded, AppColors.rest, 'Pending'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: habits.asMap().entries.map((e) {
          final i = e.key;
          final h = e.value;
          return Column(
            children: [
              if (i > 0) Divider(height: 1, color: borderColor),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.base, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: h.$4.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(h.$3, color: h.$4, size: 18),
                ),
                title: Text(
                  h.$1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration:
                            h.$2 ? TextDecoration.none : null,
                      ),
                ),
                subtitle: Text(
                  h.$5,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: textSecondary),
                ),
                trailing: Icon(
                  h.$2
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: h.$2 ? AppColors.success : AppColors.textMuted,
                  size: 24,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
