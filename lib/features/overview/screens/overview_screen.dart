import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/placeholders.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

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
              title: 'Overview',
              subtitle: 'Your personal resource planner',
            ),
            const Gap(24),

            const SectionHeader('Resources'),
            const Gap(12),
            StatsGrid(children: [
              _ResourceCard(
                label: 'Time',
                value: '78%',
                subtitle: '6.5h scheduled',
                icon: Icons.schedule_rounded,
                color: AppColors.pmp,
                route: Routes.timeOverview,
              ),
              _ResourceCard(
                label: 'Finance',
                value: '\$45,200',
                subtitle: 'Net worth',
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.success,
                route: Routes.financeOverview,
              ),
              _ResourceCard(
                label: 'Energy',
                value: '72',
                subtitle: 'Focus score',
                icon: Icons.bolt_rounded,
                color: AppColors.warning,
                route: Routes.energyOverview,
              ),
              _ResourceCard(
                label: 'Health',
                value: '72%',
                subtitle: '8 / 12 tasks',
                icon: Icons.favorite_rounded,
                color: AppColors.error,
                route: Routes.healthOverview,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Overall Trend', action: 'Details'),
            const Gap(12),
            PlaceholderChart(
              height: 160,
              label: 'Resource utilization score',
              data: const [68.0, 72.0, 70.0, 75.0, 73.0, 78.0, 75.0],
            ),
            const Gap(24),

            const SectionHeader("Today's Agenda", action: 'Full schedule'),
            const Gap(12),
            PlaceholderList(items: const [
              PlaceholderListItem(
                title: 'Morning Deep Work',
                subtitle: '06:00 — 08:00 · Deen & Quran',
                value: '2h',
                icon: Icons.self_improvement_rounded,
                iconColor: AppColors.deen,
              ),
              PlaceholderListItem(
                title: 'PMP Study Session',
                subtitle: '09:00 — 11:00 · Study',
                value: '2h',
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.pmp,
              ),
              PlaceholderListItem(
                title: 'Work Block',
                subtitle: '12:00 — 17:00 · Work',
                value: '5h',
                icon: Icons.work_rounded,
                iconColor: AppColors.work,
              ),
              PlaceholderListItem(
                title: 'Health & Fitness',
                subtitle: '18:00 — 19:00 · Health',
                value: '1h',
                icon: Icons.fitness_center_rounded,
                iconColor: AppColors.health,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Quick Actions'),
            const Gap(12),
            _QuickActions(textSecondary: textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(Spacing.base),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 10, color: textSecondary),
              ],
            ),
            const Gap(Spacing.sm),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const Gap(2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: textSecondary),
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
      ('Log Expense', Icons.add_circle_rounded, AppColors.success,
          Routes.financeTransactions),
      ('Start Focus', Icons.timer_rounded, AppColors.warning,
          Routes.energyFocus),
      ('Log Habit', Icons.check_circle_rounded, AppColors.pmp,
          Routes.healthHabits),
      ('Add Event', Icons.event_rounded, AppColors.cfi,
          Routes.timeCalendar),
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
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: a.$3.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(a.$2, size: 18, color: a.$3),
                const Gap(8),
                Expanded(
                  child: Text(
                    a.$1,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(
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
