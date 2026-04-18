import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class HealthDailyProgressScreen extends StatelessWidget {
  const HealthDailyProgressScreen({super.key});

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
              title: 'Daily Progress',
              subtitle: "Track today's health milestones",
            ),
            const Gap(24),

            const SectionHeader("Today's Score"),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'Completed',
                value: '8 / 12',
                subtitle: 'Tasks done',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
                trend: '+2 vs yesterday',
                trendUp: true,
              ),
              StatCard(
                label: 'Daily Score',
                value: '72%',
                icon: Icons.star_rounded,
                iconColor: AppColors.gold,
                trend: 'On track',
                trendUp: true,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Streak'),
            const Gap(12),
            _StreakCard(cardColor: cardColor, borderColor: borderColor, textSecondary: textSecondary),
            const Gap(24),

            const SectionHeader("Today's Checklist"),
            const Gap(12),
            _ChecklistCard(cardColor: cardColor, borderColor: borderColor),
            const Gap(24),

            const SectionHeader('7-Day Progress', action: '30 Days'),
            const Gap(12),
            PlaceholderChart(
              height: 140,
              label: 'Daily completion %',
              data: const [60, 75, 68, 80, 72, 85, 72],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.cardColor,
    required this.borderColor,
    required this.textSecondary,
  });
  final Color cardColor;
  final Color borderColor;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.base),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: AppColors.error, size: 28),
          ),
          const Gap(Spacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5-Day Streak',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Gap(4),
                Text(
                  'Keep going! Best: 21 days',
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
                '5',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.error,
                      fontFamily: 'IBMPlexMono',
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
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard(
      {required this.cardColor, required this.borderColor});
  final Color cardColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    const tasks = [
      ('Morning meditation (10 min)', true),
      ('Drink 8 glasses of water', false),
      ('30 min exercise', true),
      ('No sugar before noon', true),
      ('Take vitamins', true),
      ('Read health content', false),
      ('Evening walk', true),
      ('Sleep by 23:00', false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: tasks.asMap().entries.map((e) {
          final i = e.key;
          final task = e.value;
          return Column(
            children: [
              if (i > 0) Divider(height: 1, color: borderColor),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.base, vertical: 2),
                leading: Icon(
                  task.$2
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: task.$2 ? AppColors.success : AppColors.textMuted,
                  size: 22,
                ),
                title: Text(
                  task.$1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: task.$2
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.$2
                            ? Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                            : null,
                      ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
