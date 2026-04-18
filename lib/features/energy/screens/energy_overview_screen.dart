import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/placeholders.dart';

class EnergyOverviewScreen extends StatelessWidget {
  const EnergyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Energy',
              subtitle: 'Focus, goals, and momentum',
            ),
            const Gap(24),

            const SectionHeader('Today'),
            const Gap(12),
            StatsGrid(children: [
              StatCard(
                label: 'Focus Time',
                value: '2.5h',
                subtitle: 'Deep work sessions',
                icon: Icons.timer_rounded,
                trend: '+30m vs yesterday',
                trendUp: true,
              ),
              StatCard(
                label: 'Energy Score',
                value: '72',
                subtitle: 'Out of 100',
                icon: Icons.bolt_rounded,
                iconColor: AppColors.warning,
                trend: '+4 vs avg',
                trendUp: true,
              ),
              StatCard(
                label: 'Goals',
                value: '3 / 8',
                subtitle: 'Completed today',
                icon: Icons.flag_rounded,
                iconColor: AppColors.success,
              ),
              StatCard(
                label: 'Streak',
                value: '12 days',
                subtitle: 'Focus streak',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.error,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Energy Trend', action: '2 Weeks'),
            const Gap(12),
            PlaceholderChart(
              height: 160,
              label: 'Energy score',
              data: const [65, 70, 68, 75, 72, 80, 78, 72, 74, 82, 76, 72, 78, 72],
            ),
            const Gap(24),

            const SectionHeader("Today's Focus Sessions", action: 'Start new'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Morning Deep Work',
                subtitle: '06:00 — 07:30 · Completed',
                value: '90m',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
              ),
              PlaceholderListItem(
                title: 'PMP Study',
                subtitle: '09:00 — 09:45 · Completed',
                value: '45m',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
              ),
              PlaceholderListItem(
                title: 'Afternoon Work',
                subtitle: '14:00 · In progress',
                value: '~35m',
                icon: Icons.radio_button_on_rounded,
                iconColor: AppColors.warning,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Active Goals'),
            const Gap(12),
            _GoalsList(textSecondary: textSecondary),
          ],
        ),
      ),
    );
  }
}

class _GoalsList extends StatelessWidget {
  const _GoalsList({required this.textSecondary});
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    const goals = [
      ('Complete PMP Certification', 0.65, AppColors.pmp),
      ('Read 20 Books', 0.40, AppColors.deen),
      ('Build Emergency Fund', 0.84, AppColors.success),
      ('30-Day Focus Streak', 0.40, AppColors.warning),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: goals.asMap().entries.map((e) {
          final i = e.key;
          final goal = e.value;
          return Column(
            children: [
              if (i > 0) Divider(height: 1, color: borderColor),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.base, vertical: Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            goal.$1,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${(goal.$2 * 100).round()}%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: goal.$3,
                                  fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Gap(8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: goal.$2,
                        backgroundColor: goal.$3.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(goal.$3),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
